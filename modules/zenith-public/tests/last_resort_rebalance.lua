-- ZenithXI Last Resort rebalance (modules/zenith-public/lua/4-additive/jobAbilities/lastResortRebalance.lua).
--
-- Last Resort lasts 60 seconds instead of 180 and gives +15% attack / ranged attack and -15%
-- defense (plus merits) instead of +25% / -25%. Desperate Blows haste is kept.
--
-- The last case is a pin: it runs LSB's own onEffectGain from underneath the override and passes
-- with or without the module, on purpose. It fails when LSB changes what the effect does.

-- LSB's version, from underneath the override. Follows the chain when several modules override the path.
local function lsbVersionOf(fn)
    while type(fn) == 'function' and rawget(getfenv(fn), 'super') do
        fn = rawget(getfenv(fn), 'super')
    end

    return fn
end

describe('Zenith Last Resort rebalance', function()
    ---@type CClientEntityPair
    local player

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.DRK, level = 75 })
    end)

    it('lasts 60 seconds when used', function()
        player.actions:useAbility(player, xi.jobAbility.LAST_RESORT)
        xi.test.world:tick()

        local effect = player:getStatusEffect(xi.effect.LAST_RESORT)
        assert(effect, 'Last Resort was not applied')
        assert(effect:getDuration() == 60000, string.format('expected 60000 ms, got %d', effect:getDuration()))
    end)

    it('gives +15% attack and ranged attack and -15% defense', function()
        local attack  = player:getMod(xi.mod.ATTP)
        local ranged  = player:getMod(xi.mod.RATTP)
        local defense = player:getMod(xi.mod.DEFP)

        player.actions:useAbility(player, xi.jobAbility.LAST_RESORT)
        xi.test.world:tick()
        assert(player:hasStatusEffect(xi.effect.LAST_RESORT), 'Last Resort was not applied')

        local gainedAttack  = player:getMod(xi.mod.ATTP) - attack
        local gainedRanged  = player:getMod(xi.mod.RATTP) - ranged
        local gainedDefense = player:getMod(xi.mod.DEFP) - defense

        assert(gainedAttack == 15, string.format('ATTP: expected +15, got %+d', gainedAttack))
        assert(gainedRanged == 15, string.format('RATTP: expected +15, got %+d', gainedRanged))
        assert(gainedDefense == -15, string.format('DEFP: expected -15, got %+d', gainedDefense))
    end)

    it('keeps the Desperate Blows ability haste', function()
        player:addMod(xi.mod.DESPERATE_BLOWS, 500)
        local haste    = player:getMod(xi.mod.TWOHAND_HASTE_ABILITY)
        local attack   = player:getMod(xi.mod.ATTP)
        local merit    = player:getMerit(xi.merit.DESPERATE_BLOWS)
        local expected = player:getMod(xi.mod.DESPERATE_BLOWS) + merit

        player:addStatusEffect(xi.effect.LAST_RESORT, { duration = 60, origin = player })
        assert(player:hasStatusEffect(xi.effect.LAST_RESORT), 'Last Resort was not applied')

        local gainedHaste  = player:getMod(xi.mod.TWOHAND_HASTE_ABILITY) - haste
        local gainedAttack = player:getMod(xi.mod.ATTP) - attack
        assert(gainedHaste == expected, string.format('TWOHAND_HASTE_ABILITY: expected %+d (gear %d + merit %d), got %+d', expected, player:getMod(xi.mod.DESPERATE_BLOWS), merit, gainedHaste))
        assert(gainedAttack == 15, string.format('ATTP with Desperate Blows gear: expected +15, got %+d', gainedAttack))
    end)

    -- Pin: passes with or without the module.
    it('LSB Last Resort still gives 25 + merits and the same mods (re-check lastResortRebalance.lua if this fails)', function()
        local effectScripts = xi.effects -- the loaded effect scripts, not the xi.effect enum
        local lsbGain       = lsbVersionOf(effectScripts.last_resort.onEffectGain)
        local mods          = {}
        local target        =
        {
            getMerit = function()
                return 0
            end,

            getJobPointLevel = function()
                return 0
            end,

            getMod = function()
                return 0
            end,
        }

        local effect =
        {
            addMod = function(_, mod, amount)
                mods[mod] = (mods[mod] or 0) + amount
            end,
        }

        lsbGain(target, effect)

        assert(mods[xi.mod.ATTP] == 25, string.format('LSB changed the Last Resort ATTP, re-check lastResortRebalance.lua (got %s)', tostring(mods[xi.mod.ATTP])))
        assert(mods[xi.mod.RATTP] == 25, string.format('LSB changed the Last Resort RATTP, re-check lastResortRebalance.lua (got %s)', tostring(mods[xi.mod.RATTP])))
        assert(mods[xi.mod.DEFP] == -25, string.format('LSB changed the Last Resort DEFP, re-check lastResortRebalance.lua (got %s)', tostring(mods[xi.mod.DEFP])))

        local expected =
        {
            [xi.mod.ATTP]                  = true,
            [xi.mod.RATTP]                 = true,
            [xi.mod.DEFP]                  = true,
            [xi.mod.ATT]                   = true,
            [xi.mod.RATT]                  = true,
            [xi.mod.TWOHAND_HASTE_ABILITY] = true,
        }

        for mod, _ in pairs(mods) do
            assert(expected[mod], string.format('LSB Last Resort now adds mod %d, re-check lastResortRebalance.lua', mod))
        end
    end)
end)
