-- ZenithXI Berserk (modules/zenith-public/lua/3-complete/jobAbilities/berserk.lua).
--
-- Flat +25% attack / ranged attack and -25% defense for everything that gains Berserk, plus
-- BERSERK_POTENCY from the target. LSB uses the effect's power (25 + WAR level scaling, +6 at
-- WAR 75, or a mob skill's 45/50/200) and its subPower for the defense penalty.
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

describe('Zenith Berserk', function()
    ---@type CClientEntityPair
    local player

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 75 })
    end)

    local function gained(fn)
        local attack   = player:getMod(xi.mod.ATTP)
        local ranged   = player:getMod(xi.mod.RATTP)
        local defense  = player:getMod(xi.mod.DEFP)

        fn()
        assert(player:hasStatusEffect(xi.effect.BERSERK), 'Berserk was not applied')

        return player:getMod(xi.mod.ATTP) - attack, player:getMod(xi.mod.RATTP) - ranged, player:getMod(xi.mod.DEFP) - defense
    end

    it('gives a WAR 75 using Berserk +25% attack, not the level-scaled +31%', function()
        local attack, ranged, defense = gained(function()
            player.actions:useAbility(player, xi.jobAbility.BERSERK)
            xi.test.world:tick()
        end)

        assert(attack == 25, string.format('ATTP: expected +25, got %+d', attack))
        assert(ranged == 25, string.format('RATTP: expected +25, got %+d', ranged))
        assert(defense == -25, string.format('DEFP: expected -25, got %+d', defense))
    end)

    it('ignores a mob skill power and subPower (45 / 0)', function()
        local attack, ranged, defense = gained(function()
            player:addStatusEffect(xi.effect.BERSERK, { power = 45, subPower = 0, duration = 60, origin = player })
        end)

        assert(attack == 25, string.format('ATTP: expected +25 whatever the power, got %+d', attack))
        assert(ranged == 25, string.format('RATTP: expected +25 whatever the power, got %+d', ranged))
        assert(defense == -25, string.format('DEFP: expected -25 whatever the subPower, got %+d', defense))
    end)

    it('adds the target BERSERK_POTENCY to the flat bonus', function()
        player:addMod(xi.mod.BERSERK_POTENCY, 10)

        local attack = gained(function()
            player:addStatusEffect(xi.effect.BERSERK, { power = 1, subPower = 25, duration = 60, origin = player })
        end)

        assert(attack == 35, string.format('ATTP: expected 25 + 10 potency = +35, got %+d', attack))
    end)

    -- Pin: passes with or without the module.
    it('LSB Berserk still reads power and subPower (re-check berserk.lua if this fails)', function()
        local effectScripts = xi.effects -- the loaded effect scripts, not the xi.effect enum
        local lsbGain       = lsbVersionOf(effectScripts.berserk.onEffectGain)
        local mods          = {}
        local target        =
        {
            getJobPointLevel = function()
                return 0
            end,

            getMod = function()
                return 0
            end,
        }

        local effect =
        {
            getPower = function()
                return 40
            end,

            getSubPower = function()
                return 20
            end,

            addMod = function(_, mod, amount)
                mods[mod] = (mods[mod] or 0) + amount
            end,
        }

        lsbGain(target, effect)

        assert(mods[xi.mod.ATTP] == 40, string.format('LSB changed the Berserk ATTP source, re-check berserk.lua (got %s)', tostring(mods[xi.mod.ATTP])))
        assert(mods[xi.mod.RATTP] == 40, string.format('LSB changed the Berserk RATTP source, re-check berserk.lua (got %s)', tostring(mods[xi.mod.RATTP])))
        assert(mods[xi.mod.DEFP] == -20, string.format('LSB changed the Berserk DEFP source, re-check berserk.lua (got %s)', tostring(mods[xi.mod.DEFP])))

        local expected = { [xi.mod.ATTP] = true, [xi.mod.RATTP] = true, [xi.mod.DEFP] = true, [xi.mod.ATT] = true, [xi.mod.RATT] = true }
        for mod, _ in pairs(mods) do
            assert(expected[mod], string.format('LSB Berserk now adds mod %d, re-check berserk.lua', mod))
        end
    end)
end)
