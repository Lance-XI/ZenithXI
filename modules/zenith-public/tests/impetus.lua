-- ZenithXI Impetus (modules/zenith-public/lua/3-complete/jobAbilities/impetus.lua).
--
-- Each landed hit adds +1 attack, and every second one +1% critical rate (half of base).
-- A miss removes everything.

describe('Zenith Impetus', function()
    it('stacks half the bonus per hit and resets on a miss', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.MNK, level = 99 })
        local mob    = player.entities:moveTo('Wild_Rabbit')
        local att    = player:getMod(xi.mod.ATT)
        local crit   = player:getMod(xi.mod.CRITHITRATE)

        player.actions:useAbility(player, xi.jobAbility.IMPETUS)
        xi.test.world:tick()
        assert(player:hasStatusEffect(xi.effect.IMPETUS), 'Impetus was not applied')

        for _ = 1, 3 do
            player:triggerListener('MELEE_SWING_HIT', player, mob, nil)
        end

        assert(player:getMod(xi.mod.ATT) - att == 3, string.format('expected +3 attack after 3 hits, got +%d', player:getMod(xi.mod.ATT) - att))
        assert(player:getMod(xi.mod.CRITHITRATE) - crit == 1, string.format('expected +1 crit after 3 hits, got +%d', player:getMod(xi.mod.CRITHITRATE) - crit))

        player:triggerListener('MELEE_SWING_MISS', player, mob, nil)

        assert(player:getMod(xi.mod.ATT) == att, 'a miss did not remove the attack bonus')
        assert(player:getMod(xi.mod.CRITHITRATE) == crit, 'a miss did not remove the crit bonus')
    end)
end)
