-- ZenithXI era magic base damage (modules/zenith-public/git-patches/117-EraMagicBaseDamage.patch).
--
-- Players keep the era V (vNPC) and the old dINT curve, plus 25% of what the 2013 segmented dINT
-- curve adds on top. A negative dINT keeps the old penalty.
-- Stone IV: vNPC 381, vPC 400, old M 2, modern M0 5.

describe('Zenith era magic damage', function()
    ---@type CClientEntityPair
    local player
    ---@type CTestEntity
    local target

    -- Base damage of Stone IV at the given caster minus target INT
    local function stoneIVAt(dINT)
        local caster = GetPlayerByID(player:getID())
        local mob    = GetMobByID(target:getID())

        -- Raise whichever side needs it, so neither INT goes below 0
        local change = dINT - (caster:getStat(xi.mod.INT) - mob:getStat(xi.mod.INT))
        if change >= 0 then
            caster:addMod(xi.mod.INT, change)
        else
            mob:addMod(xi.mod.INT, -change)
        end

        assert(caster:getStat(xi.mod.INT) - mob:getStat(xi.mod.INT) == dINT, 'precondition: dINT not set')

        return xi.spells.damage.calculateBaseDamage(caster, mob, xi.magic.spell.STONE_IV, xi.magic.spellGroup.BLACK, xi.skill.ELEMENTAL_MAGIC, xi.mod.INT)
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.BLM, level = 75 })
        target = player.entities:moveTo('Wild_Rabbit')
        target:respawn() -- clears INT added by an earlier case
        assert(player:getMod(xi.mod.MAGIC_DAMAGE) == 0, 'precondition: no magic damage gear')
    end)

    it('uses vNPC at 0 dINT', function()
        local damage = stoneIVAt(0)

        assert(damage == 381, string.format('expected V 381 (vNPC), got %d', damage))
    end)

    it('blends 25% of the modern dINT bonus on top of the old one', function()
        -- old 20 * 2 = 40, modern 20 * 5 = 100, 40 + 25% of 60 = 55
        local damage = stoneIVAt(20)

        assert(damage == 381 + 55, string.format('expected 436, got %d', damage))
    end)

    it('keeps the old penalty for a negative dINT', function()
        local damage = stoneIVAt(-30)

        assert(damage == 381 - 30, string.format('expected 351, got %d', damage))
    end)
end)
