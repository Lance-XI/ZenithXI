-----------------------------------
-- Pre-SoA magic burst multiplier, for all eras (ZENITHDEV-238)
-- Restores the pre-2015 magic burst multiplier: 1.25 + 0.05 per skillchain step.
-- https://forum.square-enix.com/ffxi/threads/46531
--
-- From LSB's modules/era/lua/combat/magic_burst.lua without its xi.pre(xi.expansion.SOA) condition.
-- That module also drops base's Sengikori bonus; it is kept here, since Sengikori predates the
-- 2015 change (copy of base's handling in xi.spells.damage.calculateIfMagicBurst).
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('c_magicBurst')

m:addOverride('xi.spells.damage.calculateIfMagicBurst', function(caster, target, spellElement, magicBurstTier)
    if spellElement <= xi.element.NONE then
        return 1
    end

    local magicBurst = 1.25 + 0.05 * utils.clamp(magicBurstTier, 1, 5)

    -- Sengikori adds to the magic burst multiplier and is used up by the burst
    if target:getMod(xi.mod.SENGIKORI_MB_DMG_DEBUFF) > 0 then
        magicBurst = magicBurst + target:getMod(xi.mod.SENGIKORI_MB_DMG_DEBUFF) / 100
        target:setMod(xi.mod.SENGIKORI_MB_DMG_DEBUFF, 0)
    end

    return magicBurst
end)

return m
