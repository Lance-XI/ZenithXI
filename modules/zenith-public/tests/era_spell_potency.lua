-- ZenithXI era spell potency (modules/zenith-public/lua/3-complete/eraSpellPotency.lua).
--
-- Undoes the post-era potency raises:
--   Dia / Diaga / Dia II / Dia III lower DEF by 5 / 5 / 10 / 15 (LSB 10 / 10 / 15 / 20), and the
--   module's Dia gets Saboteur, merit and gear duration bonuses (LSB's Dia has none).
--   Bio / Bio II / Bio III lower ATT by 5 / 10 / 15 (LSB 10 / 15 / 20).
--   Blind: floor((dINT - MND + 60) / 4), Blind II: floor((dINT - MND + 100) / 4)
--   (LSB 0.225 * diff + 23 and 0.375 * diff + 49). Poison / Poisonga / Poison II follow the
--   pre-2015 enfeebling skill tables (Poison at skill 100: 2 HP/tick, LSB 4).
-- Every other enfeeble goes to LSB's calculatePotency (the Paralyze case is a control).
-- Potency cases set the caster's INT equal to the target's MND, so the stat difference is 0.

local diaBioCases =
{
    { name = 'Dia',     spell = xi.magic.spell.DIA,     effect = xi.effect.DIA, script = 'white', file = 'dia',     subPower = 5  },
    { name = 'Diaga',   spell = xi.magic.spell.DIAGA,   effect = xi.effect.DIA, script = 'white', file = 'diaga',   subPower = 5  },
    { name = 'Dia II',  spell = xi.magic.spell.DIA_II,  effect = xi.effect.DIA, script = 'white', file = 'dia_ii',  subPower = 10 },
    { name = 'Dia III', spell = xi.magic.spell.DIA_III, effect = xi.effect.DIA, script = 'white', file = 'dia_iii', subPower = 15 },
    { name = 'Bio',     spell = xi.magic.spell.BIO,     effect = xi.effect.BIO, script = 'black', file = 'bio',     subPower = 5  },
    { name = 'Bio II',  spell = xi.magic.spell.BIO_II,  effect = xi.effect.BIO, script = 'black', file = 'bio_ii',  subPower = 10 },
    { name = 'Bio III', spell = xi.magic.spell.BIO_III, effect = xi.effect.BIO, script = 'black', file = 'bio_iii', subPower = 15 },
}

local potencyCases =
{
    { name = 'Blind',     spell = xi.magic.spell.BLIND,     effect = xi.effect.BLINDNESS, skill = 200, potency = 15 },
    { name = 'Blind II',  spell = xi.magic.spell.BLIND_II,  effect = xi.effect.BLINDNESS, skill = 200, potency = 25 },
    { name = 'Poison',    spell = xi.magic.spell.POISON,    effect = xi.effect.POISON,    skill = 100, potency = 2  },
    { name = 'Poisonga',  spell = xi.magic.spell.POISONGA,  effect = xi.effect.POISON,    skill = 200, potency = 3  },
    { name = 'Poison II', spell = xi.magic.spell.POISON_II, effect = xi.effect.POISON,    skill = 130, potency = 5  },
}

describe('Zenith era spell potency', function()
    ---@type CClientEntityPair
    local player
    ---@type CTestEntity
    local mob

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WHM, level = 75 })
        mob    = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)
    end)

    describe('Dia and Bio', function()
        for _, case in ipairs(diaBioCases) do
            it(string.format('%s lowers the target by %d', case.name, case.subPower), function()
                local caster = GetPlayerByID(player:getID())
                local target = GetMobByID(mob:getID())
                assert(not target:hasStatusEffect(xi.effect.DIA) and not target:hasStatusEffect(xi.effect.BIO), 'precondition: the target already has Dia or Bio')

                xi.actions.spells[case.script][case.file].onSpellCast(caster, target, GetSpell(case.spell))

                local effect = target:getStatusEffect(case.effect)
                assert(effect, string.format('%s gave no effect', case.name))
                assert(effect:getSubPower() == case.subPower, string.format('%s down: expected %d, got %d', case.name, case.subPower, effect:getSubPower()))
            end)
        end

        it('doubles the Dia duration on a normal mob under Saboteur', function()
            player:changeJob(xi.job.RDM)
            player:setLevel(75)
            player:addStatusEffect(xi.effect.SABOTEUR, { power = 1, duration = 60, origin = player })
            local caster = GetPlayerByID(player:getID())
            local target = GetMobByID(mob:getID())
            assert(not target:isNM(), 'precondition: the target should not be an NM')
            assert(caster:getMerit(xi.merit.ENFEEBLING_MAGIC_DURATION) == 0, 'precondition: the caster has enfeebling duration merits')
            assert(caster:getMod(xi.mod.ENF_MAG_DURATION) == 0, 'precondition: the caster has enfeebling duration gear')

            xi.actions.spells.white.dia.onSpellCast(caster, target, GetSpell(xi.magic.spell.DIA))

            local effect = target:getStatusEffect(xi.effect.DIA)
            assert(effect, 'Dia gave no effect')
            assert(effect:getDuration() == 120000, string.format('Dia under Saboteur: expected 120000 ms, got %d ms', effect:getDuration()))
        end)

        -- A real cast, so the case notices if LSB moves the Dia script away from the overridden path.
        it('lowers DEF by 5 when Dia is cast', function()
            player:addSpell(xi.magic.spell.DIA)
            player:setMP(player:getMaxMP())

            player.actions:useSpell(mob, xi.magic.spell.DIA)
            for _ = 1, 5 do
                xi.test.world:skipTime(2)
            end

            local effect = mob:getStatusEffect(xi.effect.DIA)
            assert(effect, 'casting Dia gave the target no Dia')
            assert(effect:getSubPower() == 5, string.format('cast Dia defense down: expected 5, got %d', effect:getSubPower()))
        end)
    end)

    describe('enfeebling potency', function()
        local function setUpCaster(skill)
            local caster = GetPlayerByID(player:getID())
            local target = GetMobByID(mob:getID())

            player:changeJob(xi.job.RDM)
            player:setLevel(75)
            player:setSkillLevel(xi.skill.ENFEEBLING_MAGIC, skill * 10) -- stored in tenths of a level
            player:addMod(xi.mod.INT, target:getStat(xi.mod.MND) - caster:getStat(xi.mod.INT))

            assert(caster:getSkillLevel(xi.skill.ENFEEBLING_MAGIC) == skill, string.format('precondition: enfeebling skill should be %d, got %d', skill, caster:getSkillLevel(xi.skill.ENFEEBLING_MAGIC)))
            assert(caster:getStat(xi.mod.INT) == target:getStat(xi.mod.MND), 'precondition: caster INT should equal target MND')
            assert(not caster:hasStatusEffect(xi.effect.SABOTEUR), 'precondition: the caster has Saboteur')
            assert(caster:getMod(xi.mod.ENF_MAG_POTENCY) == 0, 'precondition: the caster has enfeebling potency gear')

            return caster, target
        end

        for _, case in ipairs(potencyCases) do
            it(string.format('gives %s a potency of %d at skill %d', case.name, case.potency, case.skill), function()
                local caster, target = setUpCaster(case.skill)
                local potency        = xi.spells.enfeebling.calculatePotency(caster, target, case.spell, case.effect, xi.skill.ENFEEBLING_MAGIC, xi.mod.INT)

                assert(potency == case.potency, string.format('%s potency: expected %d, got %s', case.name, case.potency, tostring(potency)))
            end)
        end

        -- Control: passes with or without the module. Paralyze is left to LSB: floor(0 / 4 + 15).
        it('leaves Paralyze to the LSB formula', function()
            local caster, target = setUpCaster(200)
            local potency        = xi.spells.enfeebling.calculatePotency(caster, target, xi.magic.spell.PARALYZE, xi.effect.PARALYSIS, xi.skill.ENFEEBLING_MAGIC, xi.mod.MND)
            local expected       = math.floor(utils.clamp((caster:getStat(xi.mod.MND) - target:getStat(xi.mod.MND)) / 4 + 15, 5, 25))

            assert(potency == expected, string.format('Paralyze potency: expected %d, got %s', expected, tostring(potency)))
        end)

        -- Through useEnfeeblingSpell, the way LSB's spell scripts call it, with resists stubbed out.
        it('puts a 15 potency Blind on the target through the enfeebling spell path', function()
            local caster, target = setUpCaster(200)
            local function never()
                return false
            end

            local function always()
                return true
            end

            stub('xi.data.statusEffect.isTargetImmune', never)
            stub('xi.data.statusEffect.isTargetResistant', never)
            stub('xi.data.statusEffect.isResistRateSuccessfull', always)
            target:delStatusEffect(xi.effect.BLINDNESS)

            xi.spells.enfeebling.useEnfeeblingSpell(caster, target, GetSpell(xi.magic.spell.BLIND))

            local effect = target:getStatusEffect(xi.effect.BLINDNESS)
            assert(effect, 'Blind gave the target no Blindness')
            assert(effect:getPower() == 15, string.format('Blind potency on the target: expected 15, got %d', effect:getPower()))
        end)
    end)
end)
