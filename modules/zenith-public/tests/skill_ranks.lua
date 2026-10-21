-- ZenithXI era skill ranks (modules/zenith-public/data/skills.yaml).
--
-- Reverts the October 2014 and June 2015 rank increases. The overlay is loaded because init.txt
-- lists zenith-public; if these fail, it is not being merged into data/skills.yaml.

describe('Zenith skill ranks', function()
    local level = 75

    local function cap(job, skill)
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE })
        return player:getMaxSkillLevel(level, job, skill)
    end

    it('keeps the 2014 A+ ranks at A', function()
        local rankA      = cap(xi.job.WAR, xi.skill.AXE) -- A, unchanged by the updates
        local rankAPlus  = cap(xi.job.WAR, xi.skill.GREAT_AXE)

        assert(rankAPlus > rankA, 'precondition: A+ should cap above A')
        assert(cap(xi.job.THF, xi.skill.DAGGER) == rankA, 'THF dagger should be A')
        assert(cap(xi.job.NIN, xi.skill.KATANA) == rankA, 'NIN katana should be A')
        assert(cap(xi.job.BLU, xi.skill.SWORD) == rankA, 'BLU sword should be A')
        assert(cap(xi.job.BST, xi.skill.AXE) == rankA, 'BST axe should be A')
        assert(cap(xi.job.RNG, xi.skill.ARCHERY) == rankA, 'RNG archery should be A')
    end)

    it('keeps the 2014 A+ ranks of PUP and DNC at B+', function()
        local rankBPlus = cap(xi.job.PUP, xi.skill.HAND_TO_HAND)

        assert(rankBPlus < cap(xi.job.WAR, xi.skill.AXE), 'PUP hand-to-hand should be below A')
        assert(cap(xi.job.DNC, xi.skill.DAGGER) == rankBPlus, 'DNC dagger should be B+, same as PUP hand-to-hand')
    end)
end)
