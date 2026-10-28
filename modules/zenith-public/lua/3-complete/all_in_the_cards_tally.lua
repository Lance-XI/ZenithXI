-----------------------------------
-- All in the Cards once per conquest tally (ZENITHDEV-263)
-- Chululu hands out Tarut Cards (and offers the repeat) once per conquest tally instead of once per Earth day.
-- The quest stores its next allowed time in the quest var 'Date', which base sets to JstMidnight() whenever
-- cards are given or the quest is turned in. Each onEventFinish handler of the quest is wrapped: after base
-- has run, a 'Date' of JstMidnight() becomes NextConquestTally(). Rewards, completion, repeatability and
-- the Collect Tarut Cards quest are unchanged.
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('c_allInTheCardsTally')

m:addOverride('xi.server.onServerStart', function()
    super()

    xi.module.modifyInteractionEntry('scripts/quests/jeuno/All_in_the_Cards', function(quest)
        for _, section in ipairs(quest.sections) do
            for _, zoneHandlers in pairs(section) do
                if
                    type(zoneHandlers) == 'table' and
                    type(zoneHandlers.onEventFinish) == 'table'
                then
                    for csid, baseHandler in pairs(zoneHandlers.onEventFinish) do
                        zoneHandlers.onEventFinish[csid] = function(player, csidArg, option, npc)
                            local result = baseHandler(player, csidArg, option, npc)

                            if quest:getVar(player, 'Date') == JstMidnight() then
                                quest:setVar(player, 'Date', NextConquestTally())
                            end

                            return result
                        end
                    end
                end
            end
        end
    end)
end)

return m
