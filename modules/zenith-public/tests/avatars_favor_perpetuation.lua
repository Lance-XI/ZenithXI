-- ZenithXI Avatar's Favor perpetuation (modules/zenith-public/lua/3-complete/jobAbilities/avatars_favor_perpetuation.lua).
--
-- While Avatar's Favor is up, the avatar's perpetuation cost is 2 lower (the original version).

describe('Zenith Avatar\'s Favor perpetuation', function()
    ---@type CClientEntityPair
    local player

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.SMN, level = 75 })
        player:spawnPet(xi.petId.IFRIT)
        assert(player:getPet(), 'precondition: Ifrit is summoned')
    end)

    it('lowers perpetuation by 2 while Favor is up and restores it after', function()
        local cost = player:getMod(xi.mod.AVATAR_PERPETUATION)
        assert(cost > 2, string.format('precondition: Ifrit costs more than 2 MP, got %d', cost))

        player:addStatusEffect(xi.effect.AVATARS_FAVOR, { power = 1, duration = 7200, origin = player, tick = 10 })
        assert(player:getMod(xi.mod.AVATAR_PERPETUATION) == cost - 2, string.format('with Favor: expected %d, got %d', cost - 2, player:getMod(xi.mod.AVATAR_PERPETUATION)))

        player:delStatusEffect(xi.effect.AVATARS_FAVOR)
        assert(player:getMod(xi.mod.AVATAR_PERPETUATION) == cost, string.format('after Favor: expected %d, got %d', cost, player:getMod(xi.mod.AVATAR_PERPETUATION)))
    end)
end)
