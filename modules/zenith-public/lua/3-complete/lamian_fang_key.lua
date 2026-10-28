-----------------------------------
-- Lamian Fang Key once per conquest tally (ZENITHDEV-256)
-- LSB's modules/era/lua/zones/caedarva_mire/npcs/qm8.lua without its xi.pre(xi.expansion.ABYSSEA) condition:
-- the ??? in Caedarva Mire gives a free Lamian Fang Key once per conquest tally instead of once per
-- Vana'diel day. The other ways to get the key are unchanged.
-- Source: https://www.bg-wiki.com/ffxi/Version_Update_(03/26/2012)
--
-- The handler is a function of its own so the test can run it while Caedarva Mire is disabled:
-- the framework skips this override for a disabled zone and applies it once the zone is enabled.
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('c_lamianFangKeyTally')

zxi = zxi or {}
zxi.lamianFangKey = zxi.lamianFangKey or {}

zxi.lamianFangKey.onTrigger = function(player, npc)
    local ID = zones[xi.zone.CAEDARVA_MIRE]

    if player:getCharVar('[TIMER]Lamian_Fang_Key') == 0 then
        if npcUtil.giveItem(player, xi.item.LAMIAN_FANG_KEY) then
            player:setCharVar('[TIMER]Lamian_Fang_Key', 1, NextConquestTally()) -- Can obtain key once per conquest tally
        end
    else
        player:messageSpecial(ID.text.NOTHING_OUT_OF_ORDINARY)
    end
end

m:addOverride('xi.zones.Caedarva_Mire.npcs.qm8.onTrigger', function(player, npc)
    return zxi.lamianFangKey.onTrigger(player, npc)
end)

return m
