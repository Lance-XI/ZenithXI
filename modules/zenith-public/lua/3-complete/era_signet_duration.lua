-----------------------------------
-- Era Signet duration (ZENITHDEV-262)
-- Copy of LSB's modules/era/lua/effects/era_signet_duration.lua without its xi.pre(xi.expansion.ABYSSEA)
-- condition: Signet lasts 3 hours less than in base. Its combat, defence and resting bonuses are unchanged.
-- Changed May 10th, 2011 : https://wiki.ffo.jp/html/564.html
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('c_eraSignetDuration')

m:addOverride('xi.conquest.bestowSignet', function(player, pNation, pRank, mOffset)
    super(player, pNation, pRank, mOffset)

    local signet = player:getStatusEffect(xi.effect.SIGNET)

    if signet then
        signet:setDuration(signet:getDuration() - 3 * 3600 * 1000)
    end
end)

return m
