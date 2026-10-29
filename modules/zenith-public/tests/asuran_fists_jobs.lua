-- ZenithXI Asuran Fists jobs (modules/zenith-public/data/weapon_skills.yaml, ZENITHDEV-264).
--
-- Puppetmaster no longer has Asuran Fists; Monk keeps it. Both fight bare-handed here, so the
-- weapon skill uses Hand-to-Hand either way. A refused weapon skill leaves the TP untouched.

describe('Zenith Asuran Fists jobs', function()
    local function tryAsuranFists(job)
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = job, level = 99 })
        local mob    = player.entities:moveTo('Wild_Rabbit')

        -- a rabbit claimed by an earlier case's player would refuse the weapon skill for another reason
        mob:respawn()
        mob:setUnkillable(true)

        -- in tenths: 424 Hand-to-Hand, above Asuran Fists' 250
        player:setSkillLevel(xi.skill.HAND_TO_HAND, 4240)
        player:addLearnedWeaponskill(xi.wsUnlock.ASURAN_FISTS)
        -- the usable weapon skills are worked out on a job change
        player:changeJob(job)
        player:setLevel(99)
        player:setTP(3000)

        player.actions:engage(mob)
        player.actions:useWeaponskill(mob, xi.weaponskill.ASURAN_FISTS)
        xi.test.world:skipTime(2)

        return player:getTP()
    end

    it('refuses Asuran Fists to a Puppetmaster', function()
        local tp = tryAsuranFists(xi.job.PUP)
        assert(tp >= 1000, string.format('a PUP used Asuran Fists (TP %d)', tp))
    end)

    it('still lets a Monk use Asuran Fists', function()
        local tp = tryAsuranFists(xi.job.MNK)
        assert(tp < 1000, string.format('a MNK could not use Asuran Fists (TP %d)', tp))
    end)
end)
