local m = Module:new('c-j_berserk')

-----------------------------------
-- Berserk Effect Override
-- Flat Berserk for everything that gains it (players and mobs): +25% ATT/RATT, -25% DEF,
-- no WAR level scaling. The effect's own power is ignored on purpose, which also flattens
-- the per-skill power mobs pass (45/50/200).
--
-- Mods that still change the effective numbers:
--   xi.mod.BERSERK_POTENCY    added to the attack bonus (read from the target when the effect is gained)
--   xi.mod.DEFP latents       Warrior's Calligae and Conqueror reduce the penalty; they are separate
--                             mods, so they stack with the effect's own -DEFP entry below
--   xi.mod.BERSERK_DURATION   applied by xi.job_utils.warrior.useBerserk, outside this override
--
-- Upstream 5bb6496f5c (2026-09-23) made the base effect read its DEFP penalty from
-- effect:getSubPower() so mob skills can pass their own (0 for the Dynamis bomb, 50 for the
-- Dynamis dhalmel). We deliberately keep the flat values; do not "fix" this on an LSB sync.
-----------------------------------

local attackBonus    = 25 -- ATTP/RATTP percent before BERSERK_POTENCY
local defensePenalty = 25 -- DEFP percent penalty before gear DEFP latents

m:addOverride('xi.effects.berserk.onEffectGain', function(target, effect)
    local power    = attackBonus + target:getMod(xi.mod.BERSERK_POTENCY)
    local jpEffect = target:getJobPointLevel(xi.jp.BERSERK_EFFECT) * 2

    effect:addMod(xi.mod.ATTP, power)
    effect:addMod(xi.mod.RATTP, power)
    effect:addMod(xi.mod.DEFP, -defensePenalty)

    -- Job Point Bonuses
    effect:addMod(xi.mod.ATT, jpEffect)
    effect:addMod(xi.mod.RATT, jpEffect)
end)

return m
