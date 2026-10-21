-----------------------------------
-- Tutorial NPC quests as they were before the April 2026 update (ZENITHDEV-212)
-- Gulldago (Bastok Markets), Alaune (Southern San d'Oria), Selele (Windurst Woods).
--
-- The quest line was added in 2008 and ended with the Raising Earring. The April 2026 update
-- added Records of Eminence to it and five more steps after the earring. Base
-- (scripts/quests/hiddenQuests/Tutorial_Quest.lua) numbers its steps by the Prog var:
--   Prog 5  "Records of Eminence": the reward needed the Memorandoll key item. It is given without
--           it, so RoE does not have to be enabled, and the key item is never handed out.
--   Prog 7  Raising Earring: the quest line now ends here (Prog 12, base's finished dialog).
--   Prog 8 to 11 (Warp Ring, Saltena, A.M.A.N. voucher, Echad Ring) never run. A character
--           already on one of them gets the finished dialog.
-- The earring cutscene still tells the player to get a trust permit; cutscene text is client side.
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('c_tutorialQuest')

local progRecordsOfEminence = 5
local progRaisingEarring    = 7
local progFinished          = 12

-- Event ids per zone, from base
local npcs =
{
    [xi.zone.BASTOK_MARKETS]     = { name = 'Gulldago', roeReward = 705,  earring = 709  },
    [xi.zone.SOUTHERN_SAN_DORIA] = { name = 'Alaune',   roeReward = 3648, earring = 3652 },
    [xi.zone.WINDURST_WOODS]     = { name = 'Selele',   roeReward = 996,  earring = 1000 },
}

-- Base's sections are matched on the Prog value their check accepts, not on their position
local findSection = function(quest, prog)
    for _, section in ipairs(quest.sections) do
        if section.check(nil, { Prog = prog }, {}) then
            return section
        end
    end

    return nil
end

m:addOverride('xi.server.onServerStart', function()
    super()

    xi.module.modifyInteractionEntry('scripts/quests/hiddenQuests/Tutorial_Quest', function(quest)
        local roeSection      = findSection(quest, progRecordsOfEminence)
        local earringSection  = findSection(quest, progRaisingEarring)
        local finishedSection = findSection(quest, progFinished)

        if not roeSection or not earringSection or not finishedSection then
            print('[tutorial_quest] Error: Tutorial_Quest steps changed upstream, module not applied')
            return
        end

        for zoneId, npc in pairs(npcs) do
            -- Records of Eminence: reward without the Memorandoll
            roeSection[zoneId][npc.name] = quest:progressEvent(npc.roeReward)

            -- Raising Earring: last step
            earringSection[zoneId].onEventFinish[npc.earring] = function(player, csid, option, npcEntity)
                if npcUtil.giveItem(player, xi.item.RAISING_EARRING) then
                    quest:setVar(player, 'Prog', progFinished)
                end
            end
        end

        -- Steps after the earring: anyone already on them is treated as finished
        for _, section in ipairs(quest.sections) do
            if section ~= finishedSection then
                local check = section.check
                section.check = function(player, questVars, vars)
                    local prog = questVars.Prog or 0
                    return prog <= progRaisingEarring and check(player, questVars, vars)
                end
            end
        end

        finishedSection.check = function(player, questVars, vars)
            return (questVars.Prog or 0) > progRaisingEarring
        end
    end)
end)

return m
