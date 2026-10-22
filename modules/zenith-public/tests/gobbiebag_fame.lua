-- ZenithXI Gobbiebag fame requirements (modules/zenith-public/lua/3-complete/gobbiebag_fame.lua).
--
-- The Gobbiebag quests need the 75 era Jeuno fame again (Part I: 3 instead of 1). Without it,
-- Bluffnix says so (event 42) instead of offering the quest (event 43).

describe('Zenith Gobbiebag fame', function()
    ---@type CClientEntityPair
    local player

    before_each(function()
        player = xi.test.world:spawnPlayer()
        player:gotoZone(xi.zone.LOWER_JEUNO)
        player.events:expectNotInEvent()

        -- Part I is offered with the starting 30 slots
        player:changeContainerSize(xi.inv.INVENTORY, 30 - player:getContainerSize(xi.inv.INVENTORY))
        assert(player:getContainerSize(xi.inv.INVENTORY) == 30, 'precondition: 30 inventory slots')
    end)

    it('does not offer Part I below Jeuno fame 3', function()
        player:setFame(xi.fameArea.JEUNO, 0)
        assert(player:getFameLevel(xi.fameArea.JEUNO) < 3, 'precondition: Jeuno fame below 3')

        player.entities:gotoAndTrigger('Bluffnix', { eventId = 42 })

        assert(player:getQuestStatus(xi.questLog.JEUNO, xi.quest.id.jeuno.THE_GOBBIEBAG_PART_I) == xi.questStatus.QUEST_AVAILABLE, 'Part I was offered')
    end)

    it('offers Part I at Jeuno fame 3', function()
        -- Jeuno fame level also counts the three nations' fame
        for _, area in ipairs({ xi.fameArea.JEUNO, xi.fameArea.SANDORIA, xi.fameArea.BASTOK, xi.fameArea.WINDURST }) do
            player:setFame(area, 1000)
        end

        assert(player:getFameLevel(xi.fameArea.JEUNO) >= 3, 'precondition: Jeuno fame 3')

        player.entities:gotoAndTrigger('Bluffnix', { eventId = 43 })
    end)
end)
