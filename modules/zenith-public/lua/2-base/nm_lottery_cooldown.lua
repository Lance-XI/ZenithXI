-----------------------------------
-- Zenith NM lottery cooldown persistence
-- Base keeps a placeholder (PH) lottery NM's cooldown in the NM's 'pop' localvar (xi.mob.phOnDespawn),
-- so a reboot or crash resets it and the first PH kill after a restart can pop the NM again.
-- This keeps that state in a server var ([Respawn]<name>_<id>, see zxi.mobHelpers.getRespawnVarName):
-- - when a PH primes the NM, the var is set to 1, so a reboot before the NM dies keeps the NM primed
-- - when the primed NM despawns, the var is set to its cooldown end time
-- - the first PH kill after a reboot puts the var back into 'pop'
-- Chance and cooldown are base's own.
--
-- Only covers the Lua lottery. NMs rolled from the `slots:` section of data/zones/<zone>/mobs.yaml
-- (C++ SpawnSlot::TrySpawn) never go through xi.mob.phOnDespawn.
-----------------------------------

local m = Module:new('b_nmLotteryCooldown')

-- Values of the 'pop' localvar and the server var besides a cooldown end time
local popState =
{
    UNSET  = 0, -- not read from the server var since the NM was loaded
    PRIMED = 1, -- a PH primed the NM and it has not died yet
    READY  = 2, -- no cooldown saved
}

local getMobLuaPathObject = function(mob)
    if not mob then
        return nil
    end

    return xi.zones[mob:getZoneName()].mobs[mob:getName()]
end

-- NM ids in phLists and ID tables are either a single id or a table of ids (GetTableOfIDs), same as in base
local toIdList = function(ids)
    if type(ids) == 'number' then
        return { ids }
    elseif type(ids) == 'table' then
        return ids
    end

    return {}
end

m:addOverride('xi.mob.phOnDespawn', function(ph, phNmId, chance, cooldown, params)
    local phId = ph:getID()
    local nms  = {}

    -- every id in a table belongs to the same NM name, so any of them finds the NM's script
    local firstNmId    = toIdList(phNmId)[1]
    local mobEntityObj = firstNmId and getMobLuaPathObject(GetMobByID(firstNmId))
    local phList       = mobEntityObj and mobEntityObj.phList
    for _, nmId in ipairs(toIdList(phList and phList[phId])) do
        local nm = GetMobByID(nmId)
        if nm then
            table.insert(nms, nm)
        end
    end

    -- base picks one of the NM's ids at random, so the state is kept on all of them
    for _, nm in ipairs(nms) do
        if nm:getLocalVar('pop') == popState.UNSET then
            local savedPop = GetServerVariable(zxi.mobHelpers.getRespawnVarName(nm))
            nm:setLocalVar('pop', savedPop > 0 and savedPop or popState.READY)

            -- primed before the reboot: the first PH kill after it pops the NM
            if savedPop == popState.PRIMED then
                chance = 100
            end
        end
    end

    local superResults = super(ph, phNmId, chance, cooldown, params)

    for _, nm in ipairs(nms) do
        local primed = nm:isAlive() or nm:getRespawnTime() > 0

        if superResults and primed then
            local respawnVarName = zxi.mobHelpers.getRespawnVarName(nm)

            SetServerVariable(respawnVarName, popState.PRIMED)
            nm:setLocalVar('pop', popState.PRIMED)

            -- base sets 'pop' to the cooldown end time in its own DESPAWN listener, added before this one
            nm:addListener('DESPAWN', 'ZENITH_SAVE_LOTTERY_COOLDOWN', function(mobArg)
                SetServerVariable(respawnVarName, mobArg:getLocalVar('pop'))
                mobArg:removeListener('ZENITH_SAVE_LOTTERY_COOLDOWN')
            end)
        end
    end

    return superResults
end)

return m
