-- ZenithXI Reward scaling (modules/zenith-public/lua/3-complete/jobAbilities/rewardScaling.lua,
-- with modules/zenith-public/git-patches/111-RewardRegenDuration.patch reading regenTime).
--
-- The module replaces xi.job_utils.beastmaster.petFoodData with smaller heals and regen and a
-- 90 second regen. Zeta Biscuit: minHealing 350, regen 6, MND x3 over 45, 90 s. LSB: 900, 14, x3
-- over 45, 180 s. The healing asserts work the amount out from the player's MND at run time.

describe('Zenith Reward scaling', function()
    ---@type CClientEntityPair
    local player

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.BST, level = 75 })
        player:spawnPet(xi.petId.SHEEP_FAMILIAR)
        assert(player:getPet(), 'precondition: the jug pet did not spawn')

        player:addItem(xi.item.PET_FOOD_ZETA_BISCUIT, 12)
        player:equipItem(xi.item.PET_FOOD_ZETA_BISCUIT)
        assert(xi.equipment.getUsableEquipID(player, xi.slot.AMMO) == xi.item.PET_FOOD_ZETA_BISCUIT, 'precondition: Zeta Biscuit is not in the ammo slot')
    end)

    it('has the Zenith Zeta Biscuit row', function()
        local food = xi.job_utils.beastmaster.petFoodData[xi.item.PET_FOOD_ZETA_BISCUIT]

        assert(food, 'no petFoodData row for Zeta Biscuit')
        assert(food.minHealing == 350, string.format('minHealing: expected 350, got %s', tostring(food.minHealing)))
        assert(food.regen == 6, string.format('regen: expected 6, got %s', tostring(food.regen)))
        assert(food.regenTime == 90, string.format('regenTime: expected 90, got %s', tostring(food.regenTime)))
    end)

    it('heals the pet by the scaled amount and gives a 90 second regen 6', function()
        local pet      = player:getPet()
        local mnd      = player:getStat(xi.mod.MND)
        local expected = math.floor(350 + 3 * (mnd - 45))

        assert(expected > 0, string.format('precondition: expected healing is %d at MND %d', expected, mnd))
        assert(pet:getMaxHP() > expected + 1, string.format('precondition: pet max HP %d would cap the %d heal', pet:getMaxHP(), expected))

        pet:setHP(1)
        player.actions:useAbility(pet, xi.jobAbility.REWARD)
        xi.test.world:tick()

        local healed = pet:getHP() - 1
        assert(healed == expected, string.format('heal: expected %d (350 + 3 x (MND %d - 45)), got %d', expected, mnd, healed))

        local regen = pet:getStatusEffect(xi.effect.REGEN)
        assert(regen, 'Reward gave the pet no Regen')
        assert(regen:getPower() == 6, string.format('regen power: expected 6, got %d', regen:getPower()))
        assert(regen:getDuration() == 90000, string.format('regen duration: expected 90000 ms, got %d', regen:getDuration()))
    end)
end)
