-- ZenithXI daily Page of Valor lock (modules/zenith-public/lua/2-base/regimes.lua).
--
-- LSB keeps counting kills (and pays page EXP) after the daily gil/tab reward was claimed, and only
-- skips the gil and tabs. The module blocks the whole regime until the next Vana'diel day: no kill
-- credit, plus one system message per zone (local var 'regimeReminder'). It relies on
-- 101-RegimeRestrictions.patch keeping '[regime]lastReward' when the regime vars are cleared.
--
-- Setup: West Ronfaure FoV regime 2 (Forest Hare x6, index 1). checkKillCredit needs the mob to
-- hold the player's level (m_HiPCLvl), so the direct-call cases give the player damage enmity on it first.

describe('Zenith regime daily lock', function()
    local regimeId    = 2
    local regimeIndex = 1

    ---@type CClientEntityPair
    local player
    ---@type CTestEntity
    local mob

    local function startRegime(lastReward)
        player:setCharVar('[regime]type', xi.regime.type.FIELDS)
        player:setCharVar('[regime]zone', xi.zone.WEST_RONFAURE)
        player:setCharVar('[regime]id', regimeId)
        player:setCharVar('[regime]repeat', 0)
        player:setCharVar('[regime]needed1', 6)
        player:setCharVar('[regime]killed1', 0)
        player:setCharVar('[regime]lastReward', lastReward)
    end

    local function creditKill()
        xi.regime.checkRegime(GetPlayerByID(player:getID()), GetMobByID(mob:getID()), regimeId, regimeIndex, xi.regime.type.FIELDS)
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 1 })
        mob    = player.entities:moveTo('Forest_Hare')
        mob:respawn()
        player.entities:moveTo(mob)
        player:setLocalVar('regimeReminder', 0)

        -- Records the player's level on the mob, which checkKillCredit reads
        GetMobByID(mob:getID()):updateEnmityFromDamage(GetPlayerByID(player:getID()), 1)
    end)

    -- Control: passes with and without the module. Guards the setup the other cases rely on.
    it('counts a kill while today\'s page reward is unclaimed', function()
        startRegime(0)

        creditKill()

        local killed = player:getCharVar('[regime]killed1')
        assert(killed == 1, string.format('precondition: an unclaimed day should credit the kill, killed1 = %d', killed))
    end)

    it('gives no kill credit once today\'s page reward was claimed', function()
        startRegime(VanadielUniqueDay())

        creditKill()

        local killed = player:getCharVar('[regime]killed1')
        assert(killed == 0, string.format('kill was credited after the daily reward (LSB behaviour), killed1 = %d', killed))
    end)

    it('warns once per zone when the reward was already claimed', function()
        startRegime(VanadielUniqueDay())

        creditKill()

        local reminder = player:getLocalVar('regimeReminder')
        assert(reminder == 1, string.format('expected the once-per-zone reminder flag to be set, got %d', reminder))

        -- The flag only gates the message. The lock itself must hold on every later kill too.
        creditKill()

        local killed = player:getCharVar('[regime]killed1')
        assert(killed == 0, string.format('second kill was credited after the daily reward, killed1 = %d', killed))
    end)

    it('credits again and clears the reminder on the next Vana\'diel day', function()
        startRegime(VanadielUniqueDay() - 1)
        player:setLocalVar('regimeReminder', 1)

        creditKill()

        local killed   = player:getCharVar('[regime]killed1')
        local reminder = player:getLocalVar('regimeReminder')
        assert(killed == 1, string.format('a new day should credit the kill, killed1 = %d', killed))
        assert(reminder == 0, string.format('a new day should clear the reminder flag, got %d', reminder))
    end)

    -- Control: passes with and without the module. Proves a real kill reaches checkRegime and earns
    -- credit, so the next case cannot pass just because the kill never counted.
    it('credits a real kill while today\'s page reward is unclaimed', function()
        startRegime(0)

        player:claimAndKillMob(mob)

        local killed = player:getCharVar('[regime]killed1')
        assert(killed == 1, string.format('precondition: a real Forest Hare kill should credit regime 2, killed1 = %d', killed))
    end)

    -- Goes in from the side LSB calls: Forest Hare's onMobDeath calls xi.regime.checkRegime.
    it('blocks credit from a real kill after the daily reward', function()
        startRegime(VanadielUniqueDay())

        player:claimAndKillMob(mob)

        assert(mob:isDead(), 'precondition: Forest Hare should be dead')
        local killed = player:getCharVar('[regime]killed1')
        assert(killed == 0, string.format('real kill was credited after the daily reward (LSB behaviour), killed1 = %d', killed))
    end)
end)
