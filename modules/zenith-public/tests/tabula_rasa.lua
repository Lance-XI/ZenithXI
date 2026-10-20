-- ZenithXI Tabula Rasa (modules/zenith-public/lua/2-base/abilities.lua).
--
-- Lasts 60 seconds, the original value, instead of 180.

describe('Zenith Tabula Rasa', function()
    it('lasts 60 seconds', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.SCH, level = 99 })

        player.actions:useAbility(player, xi.jobAbility.TABULA_RASA)
        xi.test.world:tick()

        local effect = player:getStatusEffect(xi.effect.TABULA_RASA)
        assert(effect, 'Tabula Rasa was not applied')
        assert(effect:getDuration() == 60000, string.format('expected 60000 ms, got %d', effect:getDuration()))
    end)
end)
