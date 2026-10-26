-----------------------------------
-- Era durations for stealth items (ZENITHDEV-255)
-- Copy of LSB's modules/era/lua/items/{pinch_of_prism_powder,pot_of_silent_oil,flask_of_deodorizer,pinch_of_rainbow_powder}.lua
-- without their xi.pre(xi.expansion.ABYSSEA) condition, in one module. The durations and the
-- SNEAK_INVIS_DURATION_MULTIPLIER setting are unchanged from those modules:
--   Prism Powder, Silent Oil, Deodorizer: random 1 minute 30 seconds to 6 minutes (base: 10 minutes)
--   Rainbow Powder: fixed 3 minutes (base: 10 minutes)
-- Changed December 7th, 2010 : https://www.playonline.com/pcd/verup/ff11/detail/6024/detail.html
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('c_stealthItemDurations')

m:addOverride('xi.items.pinch_of_prism_powder.onItemUse', function(target, user)
    if target:hasStatusEffect(xi.effect.INVISIBLE) then
        target:delStatusEffect(xi.effect.INVISIBLE)
    end

    target:addStatusEffect(xi.effect.INVISIBLE, { power = 1, duration = math.floor(math.random(90, 360) * xi.settings.main.SNEAK_INVIS_DURATION_MULTIPLIER), origin = user, tick = 10 })
end)

m:addOverride('xi.items.pot_of_silent_oil.onItemUse', function(target, user)
    if not target:hasStatusEffect(xi.effect.SNEAK) then
        target:addStatusEffect(xi.effect.SNEAK, { power = 1, duration = math.floor(math.random(90, 360) * xi.settings.main.SNEAK_INVIS_DURATION_MULTIPLIER), origin = user, tick = 10 })
    end
end)

m:addOverride('xi.items.flask_of_deodorizer.onItemUse', function(target, user)
    if not target:hasStatusEffect(xi.effect.DEODORIZE) then
        target:addStatusEffect(xi.effect.DEODORIZE, { power = 1, duration = math.random(90, 360), origin = user, tick = 10 })
    else
        target:messageBasic(xi.msg.basic.NO_EFFECT)
    end
end)

m:addOverride('xi.items.pinch_of_rainbow_powder.onItemUse', function(target, user)
    if target:hasStatusEffect(xi.effect.INVISIBLE) then
        target:delStatusEffect(xi.effect.INVISIBLE)
    end

    target:addStatusEffect(xi.effect.INVISIBLE, { power = 1, duration = math.floor(180 * xi.settings.main.SNEAK_INVIS_DURATION_MULTIPLIER), origin = user, tick = 10 })
end)

return m
