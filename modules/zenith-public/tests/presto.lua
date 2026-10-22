-- ZenithXI Presto step accuracy (modules/zenith-public/lua/3-complete/jobAbilities/presto.lua).

describe('Zenith Presto', function()
    it('gives step accuracy while Presto is up', function()
        local player   = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.DNC, level = 99 })
        local accuracy = player:getMod(xi.mod.STEP_ACCURACY)

        player:addStatusEffect(xi.effect.PRESTO, { power = 19, duration = 30, origin = player, tick = 3 })
        assert(player:getMod(xi.mod.STEP_ACCURACY) == accuracy + 50, 'Presto did not add 50 step accuracy')

        player:delStatusEffect(xi.effect.PRESTO)
        assert(player:getMod(xi.mod.STEP_ACCURACY) == accuracy, 'the step accuracy stayed after Presto')
    end)
end)
