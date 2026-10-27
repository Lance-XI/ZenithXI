-- ZenithXI FoV/GoV regime restrictions (modules/zenith-public/lua/2-base/regime_restrictions.lua
-- and modules/zenith-public/git-patches/101-RegimeRestrictions.patch).
--
-- Module: the Field Manual / Grounds Tome services for food, Circumspection (GoV) and Haste (GoV)
-- are refused. LSB sells them for tabs and applies the effect; the module charges nothing and
-- applies nothing. Every other service is sold as in LSB.
--
-- Patch (Lua only, it edits scripts/globals/regimes.lua): page tabs are 1/3 of LSB's, GoV pages no
-- longer grant Prowess, and '[regime]lastReward' survives clearRegimeVars. The patch cannot be
-- switched off without rebuilding the tree, so the 'patch' cases pass with or without the module
-- file; they fail only if the patch stops applying or LSB changes the code under it.

describe('Zenith regime restrictions', function()
    local startTabs = 100

    ---@type CClientEntityPair
    local player

    local function buy(option, regimeType)
        xi.regime.bookOnEventFinish(GetPlayerByID(player:getID()), option, regimeType)
    end

    local function assertRefused(option, regimeType, effects)
        buy(option, regimeType)

        local tabs = player:getCurrency('valor_point')
        assert(tabs == startTabs, string.format('option %d: tabs were deducted (LSB behaviour), expected %d, got %d', option, startTabs, tabs))

        for _, effect in ipairs(effects) do
            assert(not player:hasStatusEffect(effect), string.format('option %d: blocked service still applied effect %d', option, effect))
        end
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 75 })
        player:setCurrency('valor_point', startTabs)
        assert(player:getCurrency('valor_point') == startTabs, 'precondition: 100 tabs')
        assert(not player:hasStatusEffect(xi.effect.FOOD), 'precondition: no food effect')
    end)

    local refusedCases =
    {
        { name = 'FoV Dried Meat',       option = 117, regimeType = xi.regime.type.FIELDS,  effects = { xi.effect.FOOD } },
        { name = 'FoV Salted Fish',      option = 133, regimeType = xi.regime.type.FIELDS,  effects = { xi.effect.FOOD } },
        { name = 'FoV Hard Cookie',      option = 149, regimeType = xi.regime.type.FIELDS,  effects = { xi.effect.FOOD } },
        { name = 'FoV Instant Noodles',  option = 165, regimeType = xi.regime.type.FIELDS,  effects = { xi.effect.FOOD } },
        { name = 'GoV Circumspection',   option =  36, regimeType = xi.regime.type.GROUNDS, effects = { xi.effect.SNEAK, xi.effect.INVISIBLE } },
        { name = 'GoV Haste',            option = 180, regimeType = xi.regime.type.GROUNDS, effects = { xi.effect.HASTE } },
        { name = 'GoV Dried Meat',       option = 196, regimeType = xi.regime.type.GROUNDS, effects = { xi.effect.FOOD } },
        { name = 'GoV Salted Fish',      option = 212, regimeType = xi.regime.type.GROUNDS, effects = { xi.effect.FOOD } },
        { name = 'GoV Hard Cookie',      option = 228, regimeType = xi.regime.type.GROUNDS, effects = { xi.effect.FOOD } },
        { name = 'GoV Instant Noodles',  option = 244, regimeType = xi.regime.type.GROUNDS, effects = { xi.effect.FOOD } },
        { name = 'GoV Dried Agaricus',   option = 260, regimeType = xi.regime.type.GROUNDS, effects = { xi.effect.FOOD } },
        { name = 'GoV Instant Rice',     option = 276, regimeType = xi.regime.type.GROUNDS, effects = { xi.effect.FOOD } },
    }

    for _, case in ipairs(refusedCases) do
        it(string.format('refuses %s and keeps the tabs', case.name), function()
            assertRefused(case.option, case.regimeType, case.effects)
        end)
    end

    it('refuses a blocked option sent with the repeat flag', function()
        -- The client sets bit 31 on repeat requests; the module masks it off before the lookup
        assertRefused(bit.bor(117, 0x80000000), xi.regime.type.FIELDS, { xi.effect.FOOD })
    end)

    -- Control: passes with and without the module. Proves the purchase path works in this setup
    -- (so the refusals above are the module's doing) and that other services stay on sale.
    it('still sells FoV Regen for 20 tabs', function()
        buy(53, xi.regime.type.FIELDS)

        local tabs = player:getCurrency('valor_point')
        assert(tabs == startTabs - 20, string.format('precondition: Regen should cost 20 tabs, expected %d, got %d', startTabs - 20, tabs))
        assert(player:hasStatusEffect(xi.effect.REGEN), 'precondition: Regen service should apply Regen')
    end)

    -- Control: passes with and without the module. Same as the FoV Regen control, for a Grounds service.
    it('still sells GoV Refresh for 20 tabs', function()
        buy(132, xi.regime.type.GROUNDS)

        local tabs = player:getCurrency('valor_point')
        assert(tabs == startTabs - 20, string.format('precondition: Refresh should cost 20 tabs, expected %d, got %d', startTabs - 20, tabs))
        assert(player:hasStatusEffect(xi.effect.REFRESH), 'precondition: Refresh service should apply Refresh')
    end)

    -- Goes in from the side LSB calls: the Field Manual NPC's onEventFinish calls
    -- xi.regime.bookOnEventFinish with the menu option the client picked.
    it('refuses Dried Meat bought from the West Ronfaure Field Manual', function()
        player.entities:gotoAndTrigger('Field_Manual', { eventId = 61, finishOption = 117 })

        local tabs = player:getCurrency('valor_point')
        assert(tabs == startTabs, string.format('Field Manual charged for Dried Meat (LSB behaviour), expected %d, got %d', startTabs, tabs))
        assert(not player:hasStatusEffect(xi.effect.FOOD), 'Field Manual applied Dried Meat')
    end)

    describe('patch', function()
        ---@type CTestEntity
        local mob

        -- Puts the player one kill short of finishing a page (index 1 is the last open target)
        local function almostFinish(regimeType, zoneId, regimeId, needed)
            player:setCharVar('[regime]type', regimeType)
            player:setCharVar('[regime]zone', zoneId)
            player:setCharVar('[regime]id', regimeId)
            player:setCharVar('[regime]repeat', 0)
            player:setCharVar('[regime]lastReward', 0)

            for i = 1, 4 do
                player:setCharVar('[regime]needed' .. i, needed[i])
                player:setCharVar('[regime]killed' .. i, needed[i])
            end

            player:setCharVar('[regime]killed1', needed[1] - 1)
        end

        local function finishPage(regimeId, regimeType)
            xi.regime.checkRegime(GetPlayerByID(player:getID()), GetMobByID(mob:getID()), regimeId, 1, regimeType)
        end

        before_each(function()
            player:setLevel(1)
            player:setCurrency('valor_point', 0)
            mob = player.entities:moveTo('Forest_Hare')
            mob:respawn()
            player.entities:moveTo(mob)

            -- Records the player's level on the mob, which checkKillCredit reads
            GetMobByID(mob:getID()):updateEnmityFromDamage(GetPlayerByID(player:getID()), 1)
        end)

        -- Patch case: passes with and without the module file.
        it('pays a third of the page tabs', function()
            -- West Ronfaure page 1: regime 1, six of target 1, reward 270 gil -> LSB 27 tabs, patch 9
            almostFinish(xi.regime.type.FIELDS, xi.zone.WEST_RONFAURE, 1, { 6, 0, 0, 0 })

            finishPage(1, xi.regime.type.FIELDS)

            local expected = math.floor(math.floor(270 / 10) * xi.settings.main.TABS_RATE / 3)
            local tabs     = player:getCurrency('valor_point')
            assert(tabs == expected, string.format('101-RegimeRestrictions.patch tab cut is gone: expected %d tabs, got %d', expected, tabs))
        end)

        -- Patch case: passes with and without the module file. regimes.lua's daily lock reads this var.
        it('keeps the daily reward stamp after the page clears its vars', function()
            almostFinish(xi.regime.type.FIELDS, xi.zone.WEST_RONFAURE, 1, { 6, 0, 0, 0 })

            finishPage(1, xi.regime.type.FIELDS)

            assert(player:getCharVar('[regime]id') == 0, 'precondition: a non-repeating page should clear the regime vars')
            local stamp = player:getCharVar('[regime]lastReward')
            assert(stamp == VanadielUniqueDay(), string.format('101-RegimeRestrictions.patch: lastReward was wiped by clearRegimeVars, got %d', stamp))
        end)

        -- Patch case: passes with and without the module file.
        it('grants no Prowess for a Grounds page', function()
            -- The Boyahda Tree page 1: regime 719, targets 3 + 3
            almostFinish(xi.regime.type.GROUNDS, xi.zone.THE_BOYAHDA_TREE, 719, { 3, 3, 0, 0 })

            finishPage(719, xi.regime.type.GROUNDS)

            assert(player:getCurrency('valor_point') > 0, 'precondition: the Grounds page should have paid out')
            assert(not player:hasStatusEffect(xi.effect.PROWESS), '101-RegimeRestrictions.patch: a Grounds page granted Prowess')
        end)
    end)
end)
