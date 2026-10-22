-- ZenithXI Avatar's Favor perpetuation (modules/zenith-public/lua/3-complete/jobAbilities/avatars_favor_perpetuation.lua).
--
-- While Avatar's Favor is up, the avatar's perpetuation cost is 3 higher, 2 for Carbuncle.

describe('Zenith Avatar\'s Favor perpetuation', function()
    ---@type CClientEntityPair
    local player

    -- Summons the avatar, then checks the cost with and after Favor
    local function checkFavor(petId, increase)
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.SMN, level = 75 })
        player:spawnPet(petId)
        assert(player:getPet(), 'precondition: the avatar is summoned')

        local cost = player:getMod(xi.mod.AVATAR_PERPETUATION)

        player:addStatusEffect(xi.effect.AVATARS_FAVOR, { power = 1, duration = 7200, origin = player, tick = 10 })
        assert(player:getMod(xi.mod.AVATAR_PERPETUATION) == cost + increase, string.format('with Favor: expected %d, got %d', cost + increase, player:getMod(xi.mod.AVATAR_PERPETUATION)))

        player:delStatusEffect(xi.effect.AVATARS_FAVOR)
        assert(player:getMod(xi.mod.AVATAR_PERPETUATION) == cost, string.format('after Favor: expected %d, got %d', cost, player:getMod(xi.mod.AVATAR_PERPETUATION)))
    end

    it('raises the perpetuation of Ifrit by 3 while Favor is up', function()
        checkFavor(xi.petId.IFRIT, 3)
    end)

    it('raises the perpetuation of Carbuncle by 2 while Favor is up', function()
        checkFavor(xi.petId.CARBUNCLE, 2)
    end)

    it('keeps the surcharge of other summoners when one Favor wears off', function()
        local first  = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.SMN, level = 75 })
        local second = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.SMN, level = 75 })
        first:spawnPet(xi.petId.IFRIT)
        second:spawnPet(xi.petId.IFRIT)

        local cost = second:getMod(xi.mod.AVATAR_PERPETUATION)

        for _, summoner in ipairs({ first, second }) do
            summoner:addStatusEffect(xi.effect.AVATARS_FAVOR, { power = 1, duration = 7200, origin = summoner, tick = 10 })
        end

        first:delStatusEffect(xi.effect.AVATARS_FAVOR)

        -- A later recalculation for the second summoner still adds the surcharge
        xi.job_utils.summoner.applyPerpetuationCost(GetPlayerByID(second:getID()), second:getPet())
        assert(second:getMod(xi.mod.AVATAR_PERPETUATION) == cost + 3, 'the second summoner lost the Favor surcharge')
    end)
end)
