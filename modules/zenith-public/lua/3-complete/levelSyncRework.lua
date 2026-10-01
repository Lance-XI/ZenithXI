-----------------------------------
-- Level Sync Rework Module
--
-- Three mechanics aimed at level-synced EXP parties:
--
-- 1. Sync fatigue penalty: players syncing far below their true level
--    accumulate a per-zone daily kill counter; once past a threshold, that
--    player alone receives a tiered EXP penalty. The penalty is snapshotted
--    at every sync application (sync start, resync, zone-in) and never
--    changes mid-sync, so a party is never punished collectively -- the
--    player can always sync tighter or pick another zone that day.
-- 2. Zone rotation bonus: extra EXP while synced in a zone whose daily
--    synced-EXP total is still under a threshold, passively encouraging
--    parties to rotate camps.
-- 3. Accelerated respawns: mobs killed by a synced player at a meaningful
--    level (mob level >= sync level + minLevelDelta) respawn faster. Any
--    non-qualifying kill (unsynced killer, or sync too close to the mob's
--    level) restores the default timer. NMs, lottery placeholders (both the
--    Lua phList kind and the engine's spawn slots), and
--    battlefield/event/called/fished mobs are untouched.
--
-- Daily counters reset at JST midnight via charvar/servervar expiry.
-----------------------------------
local m = Module:new('c_levelSyncRework')

local config =
{
    enabled = true,

    -- Sync fatigue EXP penalty
    fatigue =
    {
        enabled           = true,
        overSyncDelta     = 10,    -- True main job level >= sync level + this => "over-synced"
        killThreshold     = 50,    -- Daily kills in a zone before the penalty arms
        killsPerExtraTier = 25,    -- Each additional N kills past the threshold adds a tier
        penaltyPerTier    = 10,    -- Percent EXP reduction per tier
        penaltyCap        = 50,    -- Maximum percent EXP reduction
        countNmKills      = false, -- When false, NM kills do not add fatigue
    },

    -- Zone rotation EXP bonus
    zoneBonus =
    {
        enabled          = true,
        bonusPercent     = 10,
        zoneExpThreshold = 100000, -- Daily synced EXP in a zone below this => bonus
    },

    -- Accelerated respawns for synced parties
    respawn =
    {
        enabled       = true,
        minLevelDelta = 1, -- Mob level >= sync level + this qualifies
        -- Default respawn seconds -> accelerated respawn seconds
        bands =
        {
            [300] = 270,
            [480] = 420,
            [600] = 420,
            [720] = 420,
            [840] = 420,
            [960] = 420,
        },
    },

    messages =
    {
        enabled = true, -- Notify the player when a snapshot applies an EXP adjustment
    },
}

local expListenerId = 'ZENITH_SFAT_EXP'

-- Reverse lookup of accelerated values, used to detect a poisoned "default"
-- after a lua-only reload dropped the cache mid-acceleration
local bandOutputs = {}
for _, fastSeconds in pairs(config.respawn.bands) do
    bandOutputs[fastSeconds] = true
end

local defaultRespawns = {} -- [mobId] = configured respawn seconds, cached before first modification
local phExcludedIds   = {} -- [zoneName] = { [mobId] = true } for every id referenced by a phList

local function killVarName(zoneId)
    return fmt('[SFAT]Kills_{}', zoneId)
end

local function zoneExpVarName(zoneId)
    return fmt('[SFAT]ZoneExp_{}', zoneId)
end

local function getTrueLevel(player)
    return player:getJobLevel(player:getMainJob())
end

local function isExcludedMobType(mob)
    return mob:isMobType(xi.mobType.BATTLEFIELD) or
        mob:isMobType(xi.mobType.EVENT) or
        mob:isMobType(xi.mobType.CALLED) or
        mob:isMobType(xi.mobType.FISHED)
end

-- Accumulates EXP earned by synced players into the zone's daily total.
-- Registered per player while Level Sync is active, removed on effect loss.
local function onExperienceGain(playerObj, mobObj, exp)
    if
        not playerObj:hasStatusEffect(xi.effect.LEVEL_SYNC) or
        mobObj == nil or
        mobObj:getObjType() ~= xi.objType.MOB
    then
        return
    end

    local varName = zoneExpVarName(playerObj:getZoneID())

    SetVolatileServerVariable(varName, GetVolatileServerVariable(varName) + exp, JstMidnight())
end

-- True when the mob belongs to an engine spawn slot -- the data-driven half of
-- the lottery machinery, declared as `slots:` in data/zones/<zone>/mobs.yaml
-- (94 zones do). Only one member of a slot is alive at a time and the whole
-- slot shares a single pending respawn, so these are placeholders in every
-- sense that matters even though no Lua phList mentions them.
--
-- getSpawnSlotMobs() returns the ids of every member of this mob's slot, or an
-- empty table when it has none.
local function isSpawnSlotMember(mob)
    local slotMobs = mob:getSpawnSlotMobs()

    return type(slotMobs) == 'table' and #slotMobs > 0
end

-- Union of every phList key (the placeholders) and value (the NMs they pop)
-- declared by the zone's mob scripts. Values may be a single id or a table.
local function buildPhIndex(zoneName)
    local index     = {}
    local zoneTable = xi.zones[zoneName]

    if zoneTable and zoneTable.mobs then
        for _, mobObject in pairs(zoneTable.mobs) do
            if type(mobObject) == 'table' and type(mobObject.phList) == 'table' then
                for phId, nmIds in pairs(mobObject.phList) do
                    index[phId] = true

                    if type(nmIds) == 'table' then
                        for _, nmId in pairs(nmIds) do
                            index[nmId] = true
                        end
                    else
                        index[nmIds] = true
                    end
                end
            end
        end
    end

    return index
end

-- Runs once per kill (killer-gated). A qualifying kill sets the accelerated
-- timer for the imminent respawn; any non-qualifying kill restores the default.
local function evaluateRespawn(mob, killer)
    if
        mob:isNM() or
        isExcludedMobType(mob) or
        isSpawnSlotMember(mob)
    then
        return
    end

    local zoneName = mob:getZoneName()
    if phExcludedIds[zoneName] == nil then
        phExcludedIds[zoneName] = buildPhIndex(zoneName)
    end

    local mobId = mob:getID()
    if phExcludedIds[zoneName][mobId] then
        return
    end

    local defaultSeconds = defaultRespawns[mobId]
    if defaultSeconds == nil then
        local configured = GetMobRespawnTime(mobId)

        -- If a lua reload dropped the cache while this mob was accelerated, the
        -- configured value is a band output rather than the true default; skip
        -- caching so the accelerated value can never stick as the "default".
        if bandOutputs[configured] and config.respawn.bands[configured] == nil then
            return
        end

        defaultSeconds = configured
        defaultRespawns[mobId] = defaultSeconds
    end

    local fastSeconds = config.respawn.bands[defaultSeconds]
    if
        fastSeconds == nil or
        fastSeconds <= 0 or
        defaultSeconds <= 0 -- setRespawnTime(0) would disable respawning entirely
    then
        return
    end

    local qualifies  = false
    local syncEffect = killer:getStatusEffect(xi.effect.LEVEL_SYNC)
    if syncEffect then
        qualifies = mob:getMainLvl() - syncEffect:getPower() >= config.respawn.minLevelDelta
    end

    local desiredSeconds = qualifies and fastSeconds or defaultSeconds
    if GetMobRespawnTime(mobId) ~= desiredSeconds then
        mob:setRespawnTime(desiredSeconds)
    end
end

-- Snapshot point: fires on sync start, resync, party join, and zone-in.
-- The EXP mod is attached to the effect itself, so the core removes it on
-- every removal path and each new application recomputes a fresh snapshot.
-- NOTE: CParty::RefreshSync updates the effect power in place when the sync
-- designee levels up without re-firing this hook -- the snapshot keeps the
-- values from sync start by design.
m:addOverride('xi.effects.level_sync.onEffectGain', function(target, effect)
    super(target, effect)

    if
        not config.enabled or
        target:getObjType() ~= xi.objType.PC
    then
        return
    end

    local zoneId    = target:getZoneID()
    local syncLevel = effect:getPower()
    local netExpPct = 0

    if
        config.fatigue.enabled and
        getTrueLevel(target) - syncLevel >= config.fatigue.overSyncDelta
    then
        local kills = target:getCharVar(killVarName(zoneId))
        if kills >= config.fatigue.killThreshold then
            local tiers = 1 + math.floor((kills - config.fatigue.killThreshold) / config.fatigue.killsPerExtraTier)

            netExpPct = netExpPct - math.min(tiers * config.fatigue.penaltyPerTier, config.fatigue.penaltyCap)
        end
    end

    if config.zoneBonus.enabled then
        if GetVolatileServerVariable(zoneExpVarName(zoneId)) < config.zoneBonus.zoneExpThreshold then
            netExpPct = netExpPct + config.zoneBonus.bonusPercent
        end

        target:addListener('EXPERIENCE_POINTS', expListenerId, onExperienceGain)
    end

    if netExpPct ~= 0 then
        effect:addMod(xi.mod.EXP_BONUS, netExpPct)

        if config.messages.enabled then
            target:printToPlayer(fmt('Level sync: {}{}% EXP adjustment in this zone.', netExpPct > 0 and '+' or '', netExpPct))
        end
    end
end)

-- Fires on every removal path, including the silent removal on zone-out.
-- The EXP mod detaches with the effect; only the listener needs cleanup.
m:addOverride('xi.effects.level_sync.onEffectLose', function(target, effect)
    super(target, effect)

    if target:getObjType() == xi.objType.PC then
        target:removeListener(expListenerId)
    end
end)

-- Called once per in-zone alliance member for every mob kill; isKiller marks
-- the member who landed the kill.
m:addOverride('xi.mob.onMobDeathEx', function(mob, player, isKiller, isWeaponSkillKill)
    super(mob, player, isKiller, isWeaponSkillKill)

    if not config.enabled then
        return
    end

    if config.fatigue.enabled then
        local syncEffect = player:getStatusEffect(xi.effect.LEVEL_SYNC)
        if
            syncEffect and
            getTrueLevel(player) - syncEffect:getPower() >= config.fatigue.overSyncDelta and
            (config.fatigue.countNmKills or not mob:isNM()) and
            not isExcludedMobType(mob)
        then
            local varName = killVarName(player:getZoneID())

            player:setVolatileCharVar(varName, player:getCharVar(varName) + 1, JstMidnight())
        end
    end

    if
        config.respawn.enabled and
        isKiller
    then
        evaluateRespawn(mob, player)
    end
end)

return m
