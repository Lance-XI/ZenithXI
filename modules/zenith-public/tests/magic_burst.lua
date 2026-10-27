-- ZenithXI magic burst multiplier (modules/zenith-public/lua/3-complete/magic_burst.lua).
--
-- 1.25 + 0.05 per skillchain step (capped at 5 steps), plus Sengikori, instead of base's formula
-- with resistance ranks.

describe('Zenith magic burst', function()
    local caster
    local target

    local function multiplier(element, tier)
        return xi.spells.damage.calculateIfMagicBurst(GetPlayerByID(caster:getID()), GetMobByID(target:getID()), element, tier)
    end

    local function near(a, b)
        return math.abs(a - b) < 0.0001
    end

    before_each(function()
        caster = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.BLM, level = 75 })
        target = caster.entities:moveTo('Wild_Rabbit')
    end)

    it('is 1.25 + 0.05 per step', function()
        assert(near(multiplier(xi.element.FIRE, 1), 1.30), string.format('step 1: got %f', multiplier(xi.element.FIRE, 1)))
        assert(near(multiplier(xi.element.FIRE, 3), 1.40), string.format('step 3: got %f', multiplier(xi.element.FIRE, 3)))
        assert(near(multiplier(xi.element.FIRE, 9), 1.50), string.format('capped at 5 steps: got %f', multiplier(xi.element.FIRE, 9)))
    end)

    it('does not burst non-elemental spells', function()
        assert(multiplier(xi.element.NONE, 3) == 1, 'a non-elemental spell burst')
    end)

    it('adds Sengikori once', function()
        target:setMod(xi.mod.SENGIKORI_MB_DMG_DEBUFF, 10)

        assert(near(multiplier(xi.element.FIRE, 1), 1.40), string.format('with Sengikori: got %f', multiplier(xi.element.FIRE, 1)))
        assert(target:getMod(xi.mod.SENGIKORI_MB_DMG_DEBUFF) == 0, 'Sengikori was not used up')
        assert(near(multiplier(xi.element.FIRE, 1), 1.30), 'Sengikori applied twice')
    end)
end)
