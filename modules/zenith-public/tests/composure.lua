-- ZenithXI Composure (modules/zenith-public/lua/3-complete/jobAbilities/composure.lua).
--
-- Era accuracy bonus floor(level / 5), +15 at RDM 75. LSB gives floor((24 * level + 74) / 49)
-- plus job points, +38 at RDM 75.
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

describe('Zenith Composure', function()
    it('gives a RDM 75 +15 accuracy, not +38', function()
        local player   = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.RDM, level = 75 })
        local accuracy = player:getMod(xi.mod.ACC)

        player.actions:useAbility(player, xi.jobAbility.COMPOSURE)
        xi.test.world:tick()
        assert(player:hasStatusEffect(xi.effect.COMPOSURE), 'Composure was not applied')

        local gained = player:getMod(xi.mod.ACC) - accuracy
        assert(gained == 15, string.format('expected +15 accuracy (floor(75 / 5)), got %+d', gained))
    end)

    it('scales with level: a RDM 50 gets +10', function()
        local player   = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.RDM, level = 50 })
        local accuracy = player:getMod(xi.mod.ACC)

        player:addStatusEffect(xi.effect.COMPOSURE, { power = 1, duration = 60, origin = player })
        assert(player:hasStatusEffect(xi.effect.COMPOSURE), 'Composure was not applied')

        local gained = player:getMod(xi.mod.ACC) - accuracy
        assert(gained == 10, string.format('expected +10 accuracy (floor(50 / 5)), got %+d', gained))
    end)

    -- Pin: passes with or without the module.
    it('LSB Composure still gives floor((24 * level + 74) / 49) accuracy (re-check composure.lua if this fails)', function()
        local effectScripts = xi.effects -- the loaded effect scripts, not the xi.effect enum
        local lsbGain       = lsbVersionOf(effectScripts.composure.onEffectGain)
        local mods          = {}
        local target        =
        {
            getMainLvl = function()
                return 75
            end,

            getJobPointLevel = function()
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

        assert(mods[xi.mod.ACC] == 38, string.format('LSB changed the Composure accuracy formula, re-check composure.lua (got %s at 75)', tostring(mods[xi.mod.ACC])))

        for mod, _ in pairs(mods) do
            assert(mod == xi.mod.ACC, string.format('LSB Composure now adds mod %d, re-check composure.lua', mod))
        end
    end)
end)
