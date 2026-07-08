-----------------------------------
-- Last Resort Rebalance
-- Reduces Last Resort potency to +15% Attack / -15% Defense (base, before merits)
-- and shortens its duration to 60 seconds. Merit scaling, DRK job-point flat
-- attack, and Desperate Blows ability haste are preserved.
-- Custom modifications for ZenithXI
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('a-j_last_resort_rebal')

-----------------------------------
-- Shorten duration: 180s -> 60s
-- (full replacement of the trivial base useLastResort -- smallest targeted change)
-----------------------------------
m:addOverride('xi.job_utils.dark_knight.useLastResort', function(player, target, ability)
    player:addStatusEffect(xi.effect.LAST_RESORT, { duration = 60, origin = player })

    return xi.effect.LAST_RESORT
end)

-----------------------------------
-- Reduce potency: ATTP/RATTP 25 -> 15, DEFP -25 -> -15 (merit scaling retained).
-- Job-point flat attack and Desperate Blows haste are re-applied unchanged, since
-- a full onEffectGain replacement must re-add every mod it wants to keep.
-----------------------------------
m:addOverride('xi.effects.last_resort.onEffectGain', function(target, effect)
    local targetMerit     = target:getMerit(xi.merit.LAST_RESORT_EFFECT)
    local targetJobPoints = target:getJobPointLevel(xi.jp.LAST_RESORT_EFFECT)

    -- Job point effect (unchanged)
    effect:addMod(xi.mod.ATT, 2 * targetJobPoints)
    effect:addMod(xi.mod.RATT, 2 * targetJobPoints)

    -- Reduced potency (base 15, still +2% Atk -2% Def per Last Resort Effect merit level)
    effect:addMod(xi.mod.ATTP, 15 + targetMerit)
    effect:addMod(xi.mod.RATTP, 15 + targetMerit)
    effect:addMod(xi.mod.DEFP, -15 - targetMerit)

    -- Desperate Blows ability haste (unchanged)
    effect:addMod(xi.mod.TWOHAND_HASTE_ABILITY, target:getMod(xi.mod.DESPERATE_BLOWS) + target:getMerit(xi.merit.DESPERATE_BLOWS))
end)

return m
