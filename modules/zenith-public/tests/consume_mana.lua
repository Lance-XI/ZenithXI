-- ZenithXI Consume Mana (modules/zenith-public/lua/3-complete/jobAbilities/consume_mana.lua).
--
-- The next hit deals MP / 20 bonus damage instead of MP / 10, and still uses up all MP.

describe('Zenith Consume Mana', function()
    it('adds MP / 20 damage and spends all MP', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.DRK, level = 99 })
        player:setMP(player:getMaxMP())
        player:addStatusEffect(xi.effect.CONSUME_MANA, { duration = 60, origin = player })

        local mp    = player:getMP()
        local bonus = xi.combat.damage.consumeManaAddition(GetPlayerByID(player:getID()))

        assert(mp >= 20, 'precondition: the DRK needs MP')
        assert(bonus == math.floor(mp / 20), string.format('expected %d bonus damage for %d MP, got %d', math.floor(mp / 20), mp, bonus))
        assert(player:getMP() == 0, 'Consume Mana did not use up the MP')
        assert(not player:hasStatusEffect(xi.effect.CONSUME_MANA), 'Consume Mana was not removed')
    end)

    it('adds nothing without the effect', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.DRK, level = 99 })
        player:setMP(player:getMaxMP())
        local mp = player:getMP()

        assert(xi.combat.damage.consumeManaAddition(GetPlayerByID(player:getID())) == 0, 'bonus damage without Consume Mana')
        assert(player:getMP() == mp, 'MP was spent without Consume Mana')
    end)
end)
