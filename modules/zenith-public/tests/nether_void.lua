-- ZenithXI Nether Void (modules/zenith-public/lua/3-complete/jobAbilities/nether_void.lua).
--
-- +15% to the next Absorb or Drain instead of +50%, with gear still adding on top.

describe('Zenith Nether Void', function()
    ---@type CClientEntityPair
    local player

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.DRK, level = 99 })
    end)

    local function useNetherVoid()
        player.actions:useAbility(player, xi.jobAbility.NETHER_VOID)
        xi.test.world:tick()

        local effect = player:getStatusEffect(xi.effect.NETHER_VOID)
        assert(effect, 'Nether Void was not applied')

        return effect:getPower()
    end

    it('gives +15%', function()
        local power = useNetherVoid()

        assert(power == 15, string.format('expected power 15, got %d', power))
    end)

    it('keeps the gear bonus', function()
        player:addMod(xi.mod.ENHANCES_NETHER_VOID, 10)

        local power = useNetherVoid()

        assert(power == 25, string.format('expected power 25, got %d', power))
    end)
end)
