-- ZenithXI era EXP curve (modules/zenith-public/lua/2-base/zxi_exp_curve.lua).
--
-- Restores the 2011 base EXP matrix (even match = 100 instead of LSB's 200), the matching /check
-- thresholds (Even Match at 100, Very Tough at 200, nothing under 15 EXP, no Incredibly Easy Prey)
-- and the era per-monster caps (200/250/300 instead of 400/500/600). The tables are pushed into
-- C++ from xi.server.onServerStart, so /check (player:checkDifficulty) and a real kill are what
-- show them. Numbers used: level 10 vs 14 is 200 base EXP (module, Very Tough) against 310 (LSB,
-- Tough); level 75 vs 55 is 0 (module, Too Weak) against 60 (LSB, Easy Prey).

describe('Zenith era EXP curve', function()
    ---@type CClientEntityPair
    local player
    ---@type CTestEntity
    local mob

    local function pinMob(level)
        mob:setLevelRange(level, level)
        mob:respawn()
        mob:setUnkillable(false) -- other files leave the shared rabbit unkillable, and respawn() keeps it
        mob:setMod(xi.mod.EXP_LVL_MOD, 0) -- Wild Rabbit checks 2 levels low on spawn; keep the level difference exact
        assert(mob:getMainLvl() == level, string.format('precondition: mob level %d, got %d', level, mob:getMainLvl()))
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 10 })
        mob    = player.entities:moveTo('Wild_Rabbit')
    end)

    it('checks a mob 4 levels up as Very Tough', function()
        player:setLevel(10)
        pinMob(14)

        local difficulty = player:checkDifficulty(GetMobByID(mob:getID()))

        assert(difficulty == xi.mobDifficulty.VERY_TOUGH,
            string.format('expected Very Tough (%d), got %d (LSB curve says Tough)', xi.mobDifficulty.VERY_TOUGH, difficulty))
    end)

    it('checks a mob 20 levels down at 75 as Too Weak', function()
        player:setLevel(75)
        pinMob(55)

        local difficulty = player:checkDifficulty(GetMobByID(mob:getID()))

        assert(difficulty == xi.mobDifficulty.TOO_WEAK,
            string.format('expected Too Weak (%d), got %d (LSB table gives 60 EXP, Easy Prey)', xi.mobDifficulty.TOO_WEAK, difficulty))
    end)

    it('grades a real even-match kill against 100 base EXP', function()
        player:setLevel(5)
        pinMob(5)

        local calc = spy('xi.experiencePoints.calculate')
        player:claimAndKillMob(mob)

        assert(#calc.calls >= 1, 'precondition: the kill did not reach xi.experiencePoints.calculate')

        local data = calc.calls[1].args[3]
        assert(data.baseExp == 100, string.format('expected 100 base EXP, got %d (LSB table says 200)', data.baseExp))
        assert(data.mobDifficulty == xi.mobDifficulty.EVEN_MATCH,
            string.format('expected Even Match (%d), got %d', xi.mobDifficulty.EVEN_MATCH, data.mobDifficulty))
        assert(calc.calls[1].returned.exp == 100,
            string.format('expected the solo kill to give 100 EXP, got %d', calc.calls[1].returned.exp))
    end)

    local caps =
    {
        { level = 40, cap = 200 }, -- LSB 400
        { level = 55, cap = 250 }, -- LSB 500
        { level = 70, cap = 300 }, -- LSB 600
    }

    for _, row in ipairs(caps) do
        it(string.format('caps a single mob at %d EXP for level %d', row.cap, row.level), function()
            player:setLevel(row.level)

            local result = xi.experiencePoints.calculate(GetPlayerByID(player:getID()), GetMobByID(mob:getID()),
            {
                baseExp            = 1000,
                mobDifficulty      = xi.mobDifficulty.EVEN_MATCH,
                memberLevel        = row.level,
                highestMemberLevel = row.level,
                partySize          = 1,
                memberTNL          = 1000,
                highestMemberTNL   = 1000,
                regionId           = player:getCurrentRegion(),
                chainNumber        = 0,
                chainActive        = false,
            })

            assert(result.exp == row.cap, string.format('expected the per-monster cap %d, got %d', row.cap, result.exp))
        end)
    end
end)
