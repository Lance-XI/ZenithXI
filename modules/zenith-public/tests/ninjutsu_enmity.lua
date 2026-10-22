-- ZenithXI Gekka: Ichi and Yain: Ichi (modules/zenith-public/lua/3-complete/jobAbilities/ninjutsu_enmity.lua).
--
-- Gekka: Ichi gives +10 enmity and Yain: Ichi -7.

describe('Zenith ninjutsu enmity', function()
    ---@type CClientEntityPair
    local player

    local function powerOf(spellId, effectId)
        local caster = GetPlayerByID(player:getID())
        return xi.spells.enhancing.calculateNinjutsuPower(caster, caster, nil, spellId, 1, effectId)
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.NIN, level = 99 })
    end)

    it('gives Gekka: Ichi +10 enmity', function()
        local power = powerOf(xi.magic.spell.GEKKA_ICHI, xi.effect.ENMITY_BOOST)
        assert(power == 10, string.format('expected 10, got %d', power))

        local enmity = player:getMod(xi.mod.ENMITY)
        player:addStatusEffect(xi.effect.ENMITY_BOOST, { power = power, duration = 300, origin = player })

        assert(player:getMod(xi.mod.ENMITY) == enmity + 10, 'Gekka did not add 10 enmity')
    end)

    it('gives Yain: Ichi -7 enmity', function()
        local power = powerOf(xi.magic.spell.YAIN_ICHI, xi.effect.PAX)
        assert(power == -7, string.format('expected -7, got %d', power))

        local enmity = player:getMod(xi.mod.ENMITY)
        player:addStatusEffect(xi.effect.PAX, { power = power, duration = 300, origin = player })

        assert(player:getMod(xi.mod.ENMITY) == enmity - 7, string.format('Yain changed enmity by %d instead of -7', player:getMod(xi.mod.ENMITY) - enmity))
    end)
end)
