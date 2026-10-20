local m = Module:new('c-j_impetus')

-----------------------------------
-- Impetus Override
-- Half of base's bonus per landed hit, reset on a miss, up to 50 stacks:
--   attack           +1 per stack instead of +2   (max +50)
--   critical rate    +1% every second stack instead of every stack (max +25%)
-- The augment bonuses (Bhikku/Tantra body: accuracy and critical damage) are unchanged.
-- super runs first so the duration change in 2-base/abilities.lua still applies; base's hit and
-- miss listeners it adds are then replaced. onEffectLose is base's, which removes both listeners.
-- A miss takes the bonus back with negative addMod calls: status effects have no delMod binding,
-- so base's miss listener errors and never resets the bonus.
-----------------------------------

local maxStacks = 50

local critForStacks = function(stacks)
    return math.floor(stacks / 2)
end

m:addOverride('xi.effects.impetus.onEffectGain', function(target, effect)
    super(target, effect)

    target:removeListener('IMPETUS_HIT')
    target:removeListener('IMPETUS_MISS')

    target:addListener('MELEE_SWING_HIT', 'IMPETUS_HIT', function(actorArg, targetArg, attack)
        local effectArg = actorArg:getStatusEffect(xi.effect.IMPETUS)
        if not effectArg then
            return
        end

        local stacks = effectArg:getPower() + 1
        if stacks > maxStacks then
            return
        end

        effectArg:setPower(stacks)
        effectArg:addMod(xi.mod.ATT, 1)
        effectArg:addMod(xi.mod.CRITHITRATE, critForStacks(stacks) - critForStacks(stacks - 1))

        local subPower = effectArg:getSubPower()
        if subPower ~= 0 then
            effectArg:addMod(xi.mod.ACC, 2)
            effectArg:addMod(xi.mod.CRIT_DMG_INCREASE, math.floor(subPower / 2))
        end
    end)

    target:addListener('MELEE_SWING_MISS', 'IMPETUS_MISS', function(actorArg, targetArg, attack)
        local effectArg = actorArg:getStatusEffect(xi.effect.IMPETUS)
        if not effectArg then
            return
        end

        local stacks = effectArg:getPower()
        effectArg:setPower(0)
        effectArg:addMod(xi.mod.ATT, -stacks)
        effectArg:addMod(xi.mod.CRITHITRATE, -critForStacks(stacks))

        local subPower = effectArg:getSubPower()
        if subPower ~= 0 then
            effectArg:addMod(xi.mod.ACC, -2 * stacks)
            effectArg:addMod(xi.mod.CRIT_DMG_INCREASE, -math.floor(subPower / 2) * stacks)
        end
    end)
end)

return m
