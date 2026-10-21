local m = Module:new('c-j_netherVoid')

-----------------------------------
-- Nether Void Override
-- Base potency +15% instead of +50% to the next Absorb or Drain spell.
-- Its own module like Berserk: abilities.lua only replaces the whole power, which would drop
-- xi.mod.ENHANCES_NETHER_VOID (gear) and the Nether Void job point bonus. Lowering the power
-- base sets keeps both.
-----------------------------------

local basePower   = 50 -- xi.job_utils.dark_knight.useNetherVoid
local zenithPower = 15

m:addOverride('xi.job_utils.dark_knight.useNetherVoid', function(player, target, ability)
    local effectId = super(player, target, ability)

    local effect = player:getStatusEffect(xi.effect.NETHER_VOID)
    if effect then
        effect:setPower(effect:getPower() - (basePower - zenithPower))
    end

    return effectId
end)

return m
