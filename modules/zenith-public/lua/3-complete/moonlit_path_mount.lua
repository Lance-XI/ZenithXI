-----------------------------------
-- The Moonlit Path without the Fenrir mount (ZENITHDEV-261)
-- Copy of LSB's modules/era/lua/quests/windurst/the_moonlit_path.lua without its xi.pre(xi.expansion.ROV)
-- condition: Leepe-Hoppe's reward menu no longer offers the Fenrir mount, which the September 6, 2016
-- version update added. The Fenrir pact and the other rewards are unchanged.
-- Source: https://forum.square-enix.com/ffxi/threads/51345-Sep.-6-2016-(JST)-Version-Update
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('c_moonlitPathMount')

m:addOverride('xi.server.onServerStart', function()
    super()

    xi.module.modifyInteractionEntry('scripts/quests/windurst/The_Moonlit_Path', function(quest)
        local waters        = quest.sections[2][xi.zone.WINDURST_WATERS]
        local baseOnTrigger = waters['Leepe-Hoppe'].onTrigger

        -- The fifth event param is the reward menu's hide mask. Bit 7 is the mount.
        waters['Leepe-Hoppe'].onTrigger = function(player, npc)
            local action = baseOnTrigger(player, npc)

            if action and (action.id == 846 or action.id == 850) then
                action.options[5] = utils.mask.setBit(action.options[5], 7, true) -- Module change
            end

            return action
        end
    end)
end)

return m
