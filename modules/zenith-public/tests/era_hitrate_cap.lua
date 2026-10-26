-- ZenithXI era hit rate cap (modules/zenith-public/lua/2-base/era_hitrate_cap.lua).
--
-- Melee hit rate caps at 95% for every weapon, as in the 75 era. LSB caps one-handed main hand
-- and hand-to-hand swings at 99% (and keeps 95% for two-handed, off hand and mobs).
-- The getPhysicalHitRate cases give the player 2000 accuracy, so the hit rate sits on the cap.

describe('Zenith era hit rate cap', function()
    ---@type CClientEntityPair
    local player
    ---@type CTestEntity
    local mob

    local function equipMainHand(itemId)
        player:addItem(itemId)
        player:equipItem(itemId, nil, xi.slot.MAIN)
        assert(player:getEquipID(xi.slot.MAIN) == itemId, string.format('precondition: could not equip weapon %d', itemId))
    end

    local function hitRate()
        return xi.combat.physicalHitRate.getPhysicalHitRate(GetPlayerByID(player:getID()), GetMobByID(mob:getID()), 0, xi.attackAnimation.RIGHT_ATTACK, false)
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 75 })
        mob    = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
    end)

    it('caps a one-handed main hand swing at 95%', function()
        equipMainHand(xi.item.BRONZE_SWORD)
        assert(not player:isUsingH2H(), 'precondition: a sword does not count as hand-to-hand')

        local cap = xi.combat.physicalHitRate.getPhysicalHitRateCap(GetPlayerByID(player:getID()), xi.attackAnimation.RIGHT_ATTACK)
        assert(cap == 0.95, string.format('one-handed main hand cap: expected 0.95, got %.2f', cap))
    end)

    it('caps a hand-to-hand swing at 95%', function()
        player:changeJob(xi.job.MNK)
        equipMainHand(xi.item.CESTI)
        assert(player:isUsingH2H(), 'precondition: cesti count as hand-to-hand')

        local cap = xi.combat.physicalHitRate.getPhysicalHitRateCap(GetPlayerByID(player:getID()), xi.attackAnimation.RIGHT_ATTACK)
        assert(cap == 0.95, string.format('hand-to-hand cap: expected 0.95, got %.2f', cap))
    end)

    -- Through the public caller, so the case notices if LSB stops calling getPhysicalHitRateCap.
    it('holds the melee hit rate of a one-handed main hand at 95% with huge accuracy', function()
        equipMainHand(xi.item.BRONZE_SWORD)
        player:addMod(xi.mod.ACC, 2000)

        local rate = hitRate()
        assert(rate == 0.95, string.format('one-handed hit rate with 2000 accuracy: expected 0.95, got %.4f', rate))
    end)

    it('holds the melee hit rate of hand-to-hand at 95% with huge accuracy', function()
        player:changeJob(xi.job.MNK)
        equipMainHand(xi.item.CESTI)
        player:addMod(xi.mod.ACC, 2000)

        local rate = hitRate()
        assert(rate == 0.95, string.format('hand-to-hand hit rate with 2000 accuracy: expected 0.95, got %.4f', rate))
    end)
end)
