local m = Module:new('c-j_saboteur')

-----------------------------------
-- Saboteur Override
-- Before 2019, Saboteur enhanced only the next enfeebling magic spell and then wore off. Base keeps
-- it for its full 60 seconds and enhances every enfeebling spell cast in that time.
-- The spell is cast by base first, so it still gets the Saboteur bonus, then Saboteur is removed,
-- whether the spell landed or not.
-----------------------------------

m:addOverride('xi.spells.enfeebling.useEnfeeblingSpell', function(caster, target, spell)
    local result = super(caster, target, spell)

    if
        spell:getSkillType() == xi.skill.ENFEEBLING_MAGIC and
        caster:hasStatusEffect(xi.effect.SABOTEUR)
    then
        caster:delStatusEffect(xi.effect.SABOTEUR)
    end

    return result
end)

return m
