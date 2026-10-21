local m = Module:new('c-j_consumeMana')

-----------------------------------
-- Consume Mana Override
-- Bonus damage is MP / 20 instead of MP / 10. Halving base's MP / 10 (both floored) is the same
-- as MP / 20, and leaves base in charge of spending the MP and removing the effect.
-----------------------------------

m:addOverride('xi.combat.damage.consumeManaAddition', function(actor)
    return math.floor(super(actor) / 2)
end)

return m
