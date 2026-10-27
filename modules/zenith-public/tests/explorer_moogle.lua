-- ZenithXI Explorer Moogle rank requirement (modules/zenith-public/lua/3-complete/explorer_moogle.lua).
--
-- LSB lets any adventurer at or above EXPLORER_MOOGLE_LV (10) use the Explorer Moogle teleports.
-- The module also requires rank 3 in at least one nation: below it the moogle plays its
-- "cannot teleport" event (the teleport event + 1, as for a low level), and finishing the
-- teleport event anyway neither charges the 300 gil nor teleports.
-- Bastok Mines' Explorer Moogle uses event 585, so 586 is the refusal.

describe('Zenith Explorer Moogle rank requirement', function()
    local teleportEvent = 585
    local refusalEvent  = teleportEvent + 1

    ---@type CClientEntityPair
    local player

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.BASTOK_MINES, job = xi.job.WAR, level = 75 })
        player.events:expectNotInEvent()
        player:setGil(1000)

        assert(player:getMainLvl() >= xi.settings.main.EXPLORER_MOOGLE_LV, 'precondition: above the Explorer Moogle level')
    end)

    it('refuses a teleport to an adventurer below rank 3 in every nation', function()
        player:setRank(2)
        for _, nation in ipairs({ xi.nation.SANDORIA, xi.nation.BASTOK, xi.nation.WINDURST }) do
            assert(player:getRank(nation) < 3, 'precondition: below rank 3 in every nation')
        end

        player.entities:gotoAndTrigger('Explorer_Moogle', { eventId = refusalEvent, finishOption = 0 })
    end)

    -- Control: LSB offers the teleport at rank 3 as well.
    it('offers the teleport to an adventurer at rank 3', function()
        player:setRank(3)
        assert(player:getRank(player:getNation()) == 3, 'precondition: rank 3 in the home nation')

        player.entities:gotoAndTrigger('Explorer_Moogle', { eventId = teleportEvent, finishOption = 0 })
    end)

    it('does not teleport or charge an adventurer below rank 3 who finishes the teleport event', function()
        player:setRank(2)
        local teleport = stub('xi.teleport.toExplorerMoogle', true) -- records the call, does not zone

        -- Option 1 picks the first destination, as a client would from the teleport event
        xi.teleport.explorerMoogleOnEventFinish(GetPlayerByID(player:getID()), teleportEvent, 1, teleportEvent)

        assert(#teleport.calls == 0, 'an adventurer below rank 3 was teleported')
        assert(player:getGil() == 1000, string.format('expected 1000 gil, got %d', player:getGil()))
    end)

    -- Control: LSB charges and teleports a rank 3 adventurer too.
    it('teleports and charges an adventurer at rank 3', function()
        player:setRank(3)
        local teleport = stub('xi.teleport.toExplorerMoogle', true) -- records the call, does not zone

        xi.teleport.explorerMoogleOnEventFinish(GetPlayerByID(player:getID()), teleportEvent, 1, teleportEvent)

        assert(#teleport.calls == 1, string.format('expected 1 teleport, got %d', #teleport.calls))
        assert(player:getGil() == 700, string.format('expected 700 gil, got %d', player:getGil()))
    end)
end)
