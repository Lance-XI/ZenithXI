local m = Module:new('c-j_ninjutsuEnmity')

-----------------------------------
-- Gekka: Ichi and Yain: Ichi potency
-- Gekka: Ichi (Enmity Boost) +10 enmity instead of +30, Yain: Ichi (Pax) -7 enmity.
-- NIN already has enmity stances these stack with; they become available with Abyssea.
--
-- Base gives Yain +15, so it raised enmity. Pax applies its power as the enmity change, and a
-- negative power reads back as negative through addMod's int16 (Bottle of Gnostic's Drink
-- already gives Pax -10 this way).
-----------------------------------

local enmity =
{
    [xi.magic.spell.GEKKA_ICHI] = 10,
    [xi.magic.spell.YAIN_ICHI]  = -7,
}

m:addOverride('xi.spells.enhancing.calculateNinjutsuPower', function(caster, target, spell, spellId, tier, spellEffect)
    local power, subPower = super(caster, target, spell, spellId, tier, spellEffect)

    return enmity[spellId] or power, subPower
end)

return m
