-- ZenithXI Mog Safe expansion quests (modules/zenith-public/lua/3-complete/mog_safe_quests.lua).
--
-- Each quest is offered at the next conquest tally after the bed was placed, and its reward is
-- handed over at JST midnight, instead of one minute later.

describe('Zenith Mog Safe quests', function()
    local quests =
    {
        { name = 'Give a Moogle a Break', file = 'scripts/quests/otherAreas/Give_a_Moogle_a_Break', tradeCsid = 30007 },
        { name = 'The Moogle\'s Picnic',  file = 'scripts/quests/otherAreas/The_Moogles_Picnic',    tradeCsid = 30011 },
        { name = 'Moogles in the Wild',   file = 'scripts/quests/otherAreas/Moogles_in_the_Wild',   tradeCsid = 30015 },
    }

    ---@type CClientEntityPair
    local player

    before_each(function()
        player = xi.test.world:spawnPlayer()

        -- Everything else the offer needs: in the home nation Mog House, enough fame, quests before done
        stub('xi.moghouse.inMogHouseInHomeNation', true)
        player:setFame(player:getNation(), 1000)
        assert(player:getFameLevel(player:getNation()) >= 7, 'precondition: fame level 7 for Moogles in the Wild')
        player:completeQuest(xi.questLog.OTHER_AREAS, xi.quest.id.otherAreas.GIVE_A_MOOGLE_A_BREAK)
        player:completeQuest(xi.questLog.OTHER_AREAS, xi.quest.id.otherAreas.THE_MOOGLE_PICNIC)
    end)

    for _, entry in ipairs(quests) do
        describe(entry.name, function()
            -- The module replaces the loaded quest, so this is the modified one
            local function quest()
                return utils.prequire(entry.file)
            end

            local function offered()
                return quest().sections[1].check(GetPlayerByID(player:getID()), xi.questStatus.QUEST_AVAILABLE, {})
            end

            it('is not offered one minute after the bed was placed', function()
                quest():setVar(GetPlayerByID(player:getID()), 'bedPlacedTime', GetSystemTime() - 120)

                assert(not offered(), 'offered one minute after the bed was placed')
            end)

            it('is offered once a conquest tally passed since the bed was placed', function()
                quest():setVar(GetPlayerByID(player:getID()), 'bedPlacedTime', NextConquestTally() - utils.days(8))

                assert(offered(), 'not offered after a conquest tally')
            end)

            it('hands the reward over at JST midnight', function()
                local section = quest().sections[2][xi.moghouse.moghouseZones[1]]

                section.onEventFinish[entry.tradeCsid](GetPlayerByID(player:getID()), entry.tradeCsid, 0, nil)

                assert(quest():getVar(GetPlayerByID(player:getID()), 'Timer') == JstMidnight(), 'the reward timer is not JST midnight')
            end)
        end)
    end
end)
