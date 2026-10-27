-- ZenithXI level sync rework (modules/zenith-public/lua/3-complete/levelSyncRework.lua).
--
-- LSB gives a synced player no EXP adjustment and leaves respawns alone. The module adds, when Level
-- Sync is applied (real party sync here, so the engine's own effect hook runs):
-- - +10% EXP (xi.mod.EXP_BONUS on the effect) while the zone's daily synced EXP total is under 100000
-- - for a player 10+ levels above the sync level, a fatigue penalty from their daily kills in the zone
--   ([SFAT]Kills_<zone>): -10% at 50 kills, another -10% every 25 kills, at most -50%
-- and on kills: over-synced kills add to [SFAT]Kills_<zone>, synced EXP adds to the volatile server var
-- [SFAT]ZoneExp_<zone>, and a synced kill of a mob at least 1 level above the sync level makes a 300 s
-- respawn 270 s (an unsynced kill puts it back). Mob 17186885 is a West Ronfaure Scarab Beetle with a
-- 300 s respawn, no spawn slot and no placeholder list.

describe('Zenith level sync rework', function()
    ---@type CClientEntityPair
    local player
    ---@type CClientEntityPair
    local target

    local zoneId      = xi.zone.WEST_RONFAURE
    local killVar     = string.format('[SFAT]Kills_%d', zoneId)
    local zoneExpVar  = string.format('[SFAT]ZoneExp_%d', zoneId)
    local beetleId    = 17186885
    local beetleSpawn = 300

    local function setZoneExp(value)
        SetVolatileServerVariable(zoneExpVar, value, JstMidnight())
    end

    -- player (trueLevel) syncs the party to target (syncLevel). kills is set before the sync, because the
    -- adjustment is taken when the effect is applied.
    local function syncParty(trueLevel, syncLevel, kills)
        player = xi.test.world:spawnPlayer({ zone = zoneId, job = xi.job.WAR, level = trueLevel })
        target = xi.test.world:spawnPlayer({ zone = zoneId, job = xi.job.WAR, level = syncLevel })
        target:setPos(player:getXPos(), player:getYPos(), player:getZPos())

        if kills then
            player:setCharVar(killVar, kills)
        end

        assert(player:getMod(xi.mod.EXP_BONUS) == 0, 'precondition: the player already has an EXP bonus')

        player.actions:inviteToParty(target)
        target.actions:acceptPartyInvite()
        player.actions:setLevelSync(target)

        local effect = player:getStatusEffect(xi.effect.LEVEL_SYNC)
        assert(effect, 'precondition: Level Sync was not applied')
        assert(effect:getPower() == syncLevel, string.format('precondition: synced to %d, expected %d', effect:getPower(), syncLevel))
    end

    local function expBonus()
        return player:getMod(xi.mod.EXP_BONUS)
    end

    -- Moves the whole party to a fresh beetle at a fixed level.
    local function freshBeetle(level)
        local mob = player.entities:moveTo(beetleId)
        mob:setLevelRange(level, level)
        mob:respawn()
        mob:setMobLevel(level, true) -- the level range alone did not hold for this beetle
        mob:setMod(xi.mod.EXP_LVL_MOD, 0)
        target:setPos(player:getXPos(), player:getYPos(), player:getZPos())

        assert(mob:getMainLvl() == level, string.format('precondition: beetle level %d, expected %d', mob:getMainLvl(), level))
        assert(GetMobRespawnTime(beetleId) == beetleSpawn,
            string.format('precondition: beetle respawn %d s, expected %d', GetMobRespawnTime(beetleId), beetleSpawn))

        return mob
    end

    before_each(function()
        xi.test.world:setSetting('map.LEVEL_SYNC_ENABLE', true)
        setZoneExp(0)
    end)

    after_each(function()
        setZoneExp(0)
        local beetle = GetMobByID(beetleId)
        if beetle then
            beetle:setRespawnTime(beetleSpawn) -- mobs are shared by every case and file
        end
    end)

    it('gives +10% EXP while synced in a zone under its daily EXP total', function()
        syncParty(30, 25)

        assert(expBonus() == 10, string.format('expected +10%% EXP, got %d', expBonus()))

        player:delStatusEffect(xi.effect.LEVEL_SYNC)
        assert(expBonus() == 0, string.format('the EXP adjustment outlived Level Sync: %d', expBonus()))
    end)

    local fatigue =
    {
        { kills = 50,   penalty = -10 },
        { kills = 74,   penalty = -10 },
        { kills = 75,   penalty = -20 },
        { kills = 1000, penalty = -50 },
    }

    for _, row in ipairs(fatigue) do
        it(string.format('takes %d%% EXP from an over-synced player with %d kills in a busy zone', row.penalty, row.kills), function()
            setZoneExp(100000) -- no zone bonus, so the penalty is all that is left
            syncParty(75, 30, row.kills)

            assert(expBonus() == row.penalty, string.format('expected %d%% EXP, got %d', row.penalty, expBonus()))
        end)
    end

    it('adds the zone bonus on top of the fatigue penalty', function()
        syncParty(75, 30, 75)

        assert(expBonus() == -10, string.format('expected -20%% + 10%% = -10%% EXP, got %d', expBonus()))
    end)

    it('does not tire a player synced fewer than 10 levels down', function()
        syncParty(39, 30, 1000)

        assert(expBonus() == 10, string.format('expected only the +10%% zone bonus, got %d', expBonus()))
    end)

    it('counts kills by an over-synced player only', function()
        syncParty(75, 30)
        local mob = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(false) -- other files leave the shared rabbit unkillable, and respawn() keeps it

        player:claimAndKillMob(mob)

        assert(player:getCharVar(killVar) == 1, string.format('expected 1 fatigue kill for the over-synced player, got %d', player:getCharVar(killVar)))
        assert(target:getCharVar(killVar) == 0, 'a player at the sync level was given a fatigue kill')
    end)

    it('adds synced EXP to the zone total', function()
        syncParty(25, 10)
        local mob = freshBeetle(12)

        player:claimAndKillMob(mob)

        local total = GetVolatileServerVariable(zoneExpVar)
        assert(total > 0, string.format('expected the synced kill EXP in the zone total, got %d', total))
    end)

    it('speeds up the respawn after a synced kill of a higher-level mob and restores it after an unsynced one', function()
        syncParty(25, 10)
        local mob = freshBeetle(12)

        player:claimAndKillMob(mob)

        assert(GetMobRespawnTime(beetleId) == 270, string.format('expected a 270 s respawn, got %d', GetMobRespawnTime(beetleId)))

        player:delStatusEffect(xi.effect.LEVEL_SYNC)
        assert(not player:hasStatusEffect(xi.effect.LEVEL_SYNC), 'precondition: Level Sync is still on')
        mob:respawn()
        mob:setMobLevel(12, true)
        mob:setMod(xi.mod.EXP_LVL_MOD, 0)
        player:claimAndKillMob(mob)

        assert(GetMobRespawnTime(beetleId) == beetleSpawn,
            string.format('expected the %d s respawn back after an unsynced kill, got %d', beetleSpawn, GetMobRespawnTime(beetleId)))
    end)
end)
