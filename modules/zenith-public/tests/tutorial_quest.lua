-- ZenithXI tutorial NPC quests (modules/zenith-public/lua/3-complete/tutorial_quest.lua).
--
-- Records of Eminence step rewards without the Memorandoll, and the quest line ends with the
-- Raising Earring, as it did before the April 2026 update.

describe('Zenith tutorial quests', function()
    ---@type CClientEntityPair
    local player

    local progVar = 'HQuest[Tutorial]Prog'

    before_each(function()
        player = xi.test.world:spawnPlayer()
        player:gotoZone(xi.zone.BASTOK_MARKETS)

        -- Zoning into Bastok Markets plays event 22 first
        player.events:finish(22)
        player.events:expectNotInEvent()
    end)

    it('rewards the Records of Eminence step without the Memorandoll', function()
        player:setCharVar(progVar, 5)

        player.entities:gotoAndTrigger('Gulldago', { eventId = 705 })

        assert(player:hasItem(xi.item.LIZARD_TAIL), 'no Lizard Tail')
        assert(player:hasItem(xi.item.POT_OF_HONEY), 'no Pot of Honey')
        assert(player:hasItem(xi.item.FIRE_CRYSTAL), 'no Fire Crystal')
        assert(not player:hasKeyItem(xi.keyItem.MEMORANDOLL), 'the Memorandoll was handed out')
        assert(player:getCharVar(progVar) == 6, string.format('expected Prog 6, got %d', player:getCharVar(progVar)))
    end)

    it('ends the quest line with the Raising Earring', function()
        player:setLevel(5)
        player:setCharVar(progVar, 7)

        player.entities:gotoAndTrigger('Gulldago', { eventId = 709 })

        assert(player:hasItem(xi.item.RAISING_EARRING), 'no Raising Earring')
        assert(player:getCharVar(progVar) == 12, string.format('expected the finished Prog 12, got %d', player:getCharVar(progVar)))

        -- Only the finished dialog from here on
        player.entities:gotoAndTrigger('Gulldago', { eventId = 718 })
        assert(not player:hasItem(xi.item.WARP_RING), 'the quest line went on to the Warp Ring')
    end)

    it('gives the finished dialog to a character already past the earring', function()
        player:setCharVar(progVar, 9)

        player.entities:gotoAndTrigger('Gulldago', { eventId = 718 })

        assert(not player:hasItem(xi.item.SALTENA), 'the Saltena step still ran')
    end)
end)
