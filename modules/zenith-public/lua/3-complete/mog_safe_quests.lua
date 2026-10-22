-----------------------------------
-- Mog Safe expansion quests with their original waits, for all eras (ZENITHDEV-234)
-- Give a Moogle a Break, The Moogle's Picnic!, Moogles in the Wild:
-- - the quest is offered at the next conquest tally after the bed was placed, not after one minute
-- - the reward is handed over at JST midnight, not after one minute
-- The July 8, 2014 version update shortened both waits to one minute.
--
-- LSB's modules/era/lua/quests/otherareas/{give_a_moogle_a_break,the_moogles_picnic,moogles_in_the_wild}.lua
-- without their xi.pre(xi.expansion.SOA) condition, in one module. The check and handler are copies
-- of base's (scripts/quests/otherAreas) with only the waits changed.
-----------------------------------
-- Source: https://forum.square-enix.com/ffxi/threads/43135-Jul-8-2014-(JST)-Version-Update
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('c_mogSafeQuests')

local quests =
{
    {
        file      = 'scripts/quests/otherAreas/Give_a_Moogle_a_Break',
        fame      = 3,
        tradeCsid = 30007,
    },
    {
        file         = 'scripts/quests/otherAreas/The_Moogles_Picnic',
        prerequisite = xi.quest.id.otherAreas.GIVE_A_MOOGLE_A_BREAK,
        fame         = 5,
        tradeCsid    = 30011,
    },
    {
        file         = 'scripts/quests/otherAreas/Moogles_in_the_Wild',
        prerequisite = xi.quest.id.otherAreas.THE_MOOGLE_PICNIC,
        fame         = 7,
        tradeCsid    = 30015,
    },
}

m:addOverride('xi.server.onServerStart', function()
    super()

    for _, entry in ipairs(quests) do
        xi.module.modifyInteractionEntry(entry.file, function(quest)
            -- Copy of the base check. The quest is offered at the next conquest tally.
            quest.sections[1].check = function(player, status, vars)
                local bedPlacedTime = quest:getVar(player, 'bedPlacedTime')

                return status == xi.questStatus.QUEST_AVAILABLE and
                    (entry.prerequisite == nil or player:hasCompletedQuest(xi.questLog.OTHER_AREAS, entry.prerequisite)) and
                    xi.moghouse.inMogHouseInHomeNation(player) and
                    player:getFameLevel(player:getNation()) >= entry.fame and
                    quest:getLocalVar(player, 'mustZone') == 0 and
                    quest:getLocalVar(player, 'questSeen') == 0 and
                    bedPlacedTime ~= 0 and
                    bedPlacedTime < NextConquestTally() - utils.days(7) -- Module change
            end

            -- Every Mog House zone shares one section table. A wrapper would run the base handler once per zone.
            for _, zoneId in ipairs(xi.moghouse.moghouseZones) do
                local section = quest.sections[2][zoneId]

                -- Copy of the base handler. The reward is handed over at JST midnight.
                section.onEventFinish[entry.tradeCsid] = function(player, csid, option, npc)
                    player:tradeComplete()
                    quest:setVar(player, 'Prog', 1)
                    quest:setVar(player, 'Timer', JstMidnight()) -- Module change
                end
            end
        end)
    end
end)

return m
