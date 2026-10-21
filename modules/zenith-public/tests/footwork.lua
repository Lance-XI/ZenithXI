-- ZenithXI Footwork (modules/zenith-public/lua/3-complete/jobAbilities/footwork.lua).
--
-- +12 kick attack damage (plus weapon damage) and +5% kick attack rate, instead of +20 and +20%.

describe('Zenith Footwork', function()
    it('gives +12 kick damage and +5% kick attack rate', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.MNK, level = 99 })
        local weaponDmg = player:getWeaponDmg()
        local kickRate  = player:getMod(xi.mod.KICK_ATTACK_RATE)
        local kickDmg   = player:getMod(xi.mod.KICK_DMG)

        player.actions:useAbility(player, xi.jobAbility.FOOTWORK)
        xi.test.world:tick()
        assert(player:hasStatusEffect(xi.effect.FOOTWORK), 'Footwork was not applied')

        local gainedRate = player:getMod(xi.mod.KICK_ATTACK_RATE) - kickRate
        local gainedDmg  = player:getMod(xi.mod.KICK_DMG) - kickDmg

        assert(gainedRate == 5, string.format('expected +5 kick attack rate, got +%d', gainedRate))
        assert(gainedDmg == 12 + weaponDmg, string.format('expected +%d kick damage, got +%d', 12 + weaponDmg, gainedDmg))
    end)
end)
