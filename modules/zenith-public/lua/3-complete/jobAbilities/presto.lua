local m = Module:new('c-j_presto')

-----------------------------------
-- Presto step accuracy (ZENITHDEV-18)
-- Presto also gives the next step +50 accuracy (https://www.bg-wiki.com/ffxi/Presto). Base has no
-- such bonus: the step's hit rate reads xi.mod.STEP_ACCURACY, which nothing sets for Presto.
-- The effect carries the mod, so it goes away when the step uses Presto up.
-- ZENITHDEV-221 lists the 2010 value as +20; change stepAccuracy if that ticket goes ahead.
-----------------------------------

local stepAccuracy = 50

m:addOverride('xi.effects.presto.onEffectGain', function(target, effect)
    super(target, effect)

    effect:addMod(xi.mod.STEP_ACCURACY, stepAccuracy)
end)

return m
