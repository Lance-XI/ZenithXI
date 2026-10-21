-----------------------------------
-- Focus and Dodge Job Ability Changes
-- Custom modifications for ZenithXI
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('focusDodgeChanges')

local getAddedBonus = function(player)
    local level = utils.getActiveJobLevel(player, xi.job.MNK)
    local first = math.floor(level / 5) + 10
    local second = math.floor((level / 3) * 0.2)

    return first, second
end

-- Both last 90 seconds
local duration = 90000

-- Effects restored on zone-in keep their remaining time (ZoneInTime is 0 until onGameIn runs)
local isFreshEffect = function(target)
    return not target:isPC() or target:getLocalVar('ZoneInTime') ~= 0
end

-- These modify the bonuses applied by the effects, while recast times are handled via SQL.
-- They replace base's onEffectGain, so the duration is set here too.

-- Override the Focus status effect to apply the custom bonuses
m:addOverride('xi.effects.focus.onEffectGain', function(target, effect)
    local baseAcc, baseCrit = getAddedBonus(target)
    local jpModBonus = effect:getPower()

    effect:addMod(xi.mod.ACC, baseAcc + jpModBonus)
    effect:addMod(xi.mod.CRITHITRATE, baseCrit)

    if isFreshEffect(target) then
        effect:setDuration(duration)
    end
end)

-- Override the Dodge status effect to apply the custom bonuses
m:addOverride('xi.effects.dodge.onEffectGain', function(target, effect)
    local baseEva, baseGuard = getAddedBonus(target)
    local jpModBonus = effect:getPower()

    effect:addMod(xi.mod.EVA, baseEva + jpModBonus)
    effect:addMod(xi.mod.ADDITIVE_GUARD, baseGuard)

    if isFreshEffect(target) then
        effect:setDuration(duration)
    end
end)

return m
