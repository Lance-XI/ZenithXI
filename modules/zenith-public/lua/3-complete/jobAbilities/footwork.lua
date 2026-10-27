local m = Module:new('c-j_footwork')

-----------------------------------
-- Footwork Override
-- Zenith keeps the modern Footwork (no weapon delay change, MNK can still punch), so its
-- power is cut instead:
--   kick attack damage  +12 instead of +20 (still plus the weapon's damage)
--   kick attack rate    +5% instead of +20%
-- Duration (60s) and the kick attack bonus (subPower) are unchanged.
-----------------------------------

local kickDamage     = 12
local kickAttackRate = 5

m:addOverride('xi.job_utils.monk.useFootwork', function(player, target, ability)
    local pTable =
    {
        power    = kickDamage + player:getWeaponDmg(),
        duration = 60,
        subPower = 25 + player:getMod(xi.mod.FOOTWORK_ATT_BONUS),
        origin   = player,
    }

    player:addStatusEffect(xi.effect.FOOTWORK, pTable)

    return xi.effect.FOOTWORK
end)

m:addOverride('xi.effects.footwork.onEffectGain', function(target, effect)
    local jpLevel = target:getJobPointLevel(xi.jp.FOOTWORK_EFFECT)

    effect:addMod(xi.mod.KICK_ATTACK_RATE, kickAttackRate)
    effect:addMod(xi.mod.KICK_DMG, effect:getPower() + jpLevel)
end)

return m
