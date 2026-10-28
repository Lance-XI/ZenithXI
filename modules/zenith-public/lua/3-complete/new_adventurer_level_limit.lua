-----------------------------------
-- New Adventurer status removed at level 6 (ZENITHDEV-244)
-- Copy of LSB's modules/era/lua/globals/new_adventurer_level_limit.lua without its xi.pre(xi.expansion.TVR)
-- condition: the New Adventurer icon is removed again once the main job reaches level 6. Retail stopped
-- doing this in August 2023; the play time limit (NEW_ADVENTURER_PLAYTIME_LIMIT) still applies as well.
-- Source: https://forum.square-enix.com/ffxi/threads/61014-August-9-2023-%28JST%29-Version-Update?p=656247&viewfull=1#post656247
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('c_newAdventurerLevelLimit')

local function checkNewPlayer(player)
    if not player:getNewPlayer() then
        return
    end

    if player:getJobLevel(player:getMainJob()) >= 6 then
        player:setNewPlayer(false)
    end
end

m:addOverride('xi.player.onPlayerLevelUp', function(player)
    super(player)

    checkNewPlayer(player)
end)

return m
