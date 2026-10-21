-- ZenithXI job ability adjustments (modules/zenith-public/lua/2-base/abilities.lua, and Dodge and
-- Focus from modules/zenith-public/lua/4-additive/jobAbilities/focusDodgeChanges.lua).
--
-- The module changes each effect's power, subPower or duration in onEffectGain. Every entry is
-- checked by giving the effect with known values and reading what is left after the gain.
-- Durations are given in seconds and read back in milliseconds.

describe('Zenith ability adjustments', function()
    local cases =
    {
        -- Warrior
        { name = 'Blood Rage',     effect = xi.effect.BLOOD_RAGE,     job = xi.job.WAR, give = { power = 20 },               expect = { power = 10 } },
        { name = 'Defender',       effect = xi.effect.DEFENDER,       job = xi.job.WAR, give = { power = 50 },               expect = { power = 25 } },
        -- Monk
        { name = 'Impetus',        effect = xi.effect.IMPETUS,        job = xi.job.MNK, give = { duration = 180 },           expect = { duration = 120000 } },
        -- Thief
        { name = 'Conspirator',    effect = xi.effect.CONSPIRATOR,    job = xi.job.THF, give = { power = 20, subPower = 10 }, expect = { power = 10, subPower = 5 } },
        -- Dodge and Focus are set to 90 seconds whatever they are given (focusDodgeChanges.lua)
        { name = 'Dodge',          effect = xi.effect.DODGE,          job = xi.job.MNK, give = { duration = 30 },            expect = { duration = 90000 } },
        { name = 'Focus',          effect = xi.effect.FOCUS,          job = xi.job.MNK, give = { duration = 30 },            expect = { duration = 90000 } },
        { name = 'Sepulcher',      effect = xi.effect.SEPULCHER,      job = xi.job.PLD, give = { duration = 180 },           expect = { duration = 120000 } },
        -- Samurai
        { name = 'Hagakure',       effect = xi.effect.HAGAKURE,       job = xi.job.SAM, give = { power = 100, subPower = 40 }, expect = { power = 25, subPower = 10 } },
        { name = 'Hamanoha',       effect = xi.effect.HAMANOHA,       job = xi.job.SAM, give = { duration = 180 },           expect = { duration = 120000 } },
        { name = 'Sengikori',      effect = xi.effect.SENGIKORI,      job = xi.job.SAM, give = { power = 25 },               expect = { power = 10 } },
        -- Dragoon
        { name = 'Dragon Breaker', effect = xi.effect.DRAGON_BREAKER, job = xi.job.DRG, give = { duration = 180 },           expect = { duration = 120000 } },
        -- Ranger
        { name = 'Double Shot',    effect = xi.effect.DOUBLE_SHOT,    job = xi.job.RNG, give = { power = 40 },               expect = { power = 10 } },
        { name = 'Triple Shot',    effect = xi.effect.TRIPLE_SHOT,    job = xi.job.RNG, give = { power = 40 },               expect = { power = 10 } },
        -- Bard
        { name = 'Marcato',        effect = xi.effect.MARCATO,        job = xi.job.BRD, give = { power = 50 },               expect = { power = 20 } },
        -- Blue Mage
        { name = 'Azure Lore',     effect = xi.effect.AZURE_LORE,     job = xi.job.BLU, give = { duration = 30 },            expect = { duration = 45000 } },
        -- Scholar
        { name = 'Tabula Rasa',    effect = xi.effect.TABULA_RASA,    job = xi.job.SCH, give = { duration = 180 },           expect = { duration = 60000 } },
        -- Puppetmaster
        { name = 'Overdrive',      effect = xi.effect.OVERDRIVE,      job = xi.job.PUP, give = { duration = 180 },           expect = { duration = 60000 } },
    }

    it('gives Dodge guard activation rate, not guard skill', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.MNK, level = 99 })
        local guardRate  = player:getMod(xi.mod.ADDITIVE_GUARD)
        local guardSkill = player:getMod(xi.mod.GUARD)

        player:addStatusEffect(xi.effect.DODGE, { power = 0, duration = 30, origin = player })

        assert(player:getMod(xi.mod.ADDITIVE_GUARD) > guardRate, 'Dodge did not raise the guard activation rate')
        assert(player:getMod(xi.mod.GUARD) == guardSkill, 'Dodge raised guard skill')
    end)

    for _, case in ipairs(cases) do
        it(string.format('adjusts %s', case.name), function()
            local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = case.job, level = 99 })

            player:addStatusEffect(case.effect,
            {
                power    = case.give.power or 1,
                subPower = case.give.subPower or 0,
                duration = case.give.duration or 60,
                origin   = player,
            })

            local effect = player:getStatusEffect(case.effect)
            assert(effect, string.format('%s was not applied', case.name))

            if case.expect.power then
                assert(effect:getPower() == case.expect.power, string.format('%s power: expected %d, got %d', case.name, case.expect.power, effect:getPower()))
            end

            if case.expect.subPower then
                assert(effect:getSubPower() == case.expect.subPower, string.format('%s subPower: expected %d, got %d', case.name, case.expect.subPower, effect:getSubPower()))
            end

            if case.expect.duration then
                assert(effect:getDuration() == case.expect.duration, string.format('%s duration: expected %d ms, got %d', case.name, case.expect.duration, effect:getDuration()))
            end
        end)
    end
end)
