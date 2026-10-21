-- ZenithXI party level gap (modules/zenith-public/lua/3-complete/exp_level_gap.lua).
--
-- Nobody gets EXP when a member near the mob is 10 or more levels above the lowest one.
-- Calls xi.experiencePoints.calculate the way charutils::DistributeExperiencePoints does.

describe('Zenith EXP level gap', function()
    ---@type CClientEntityPair
    local low
    ---@type CClientEntityPair
    local high
    ---@type CTestEntity
    local mob

    local function resultFor(member)
        return xi.experiencePoints.calculate(GetPlayerByID(member:getID()), GetMobByID(mob:getID()),
        {
            baseExp            = 200,
            mobDifficulty      = xi.mobDifficulty.EVEN_MATCH,
            memberLevel        = member:getMainLvl(),
            highestMemberLevel = high:getMainLvl(),
            partySize          = 2,
            memberTNL          = 1000,
            highestMemberTNL   = 1000,
            regionId           = member:getCurrentRegion(),
            chainNumber        = 0,
            chainActive        = false,
        })
    end

    local function expFor(member)
        return resultFor(member).exp
    end

    local function party(lowLevel, highLevel)
        low  = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = lowLevel })
        high = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = highLevel })
        mob  = low.entities:moveTo('Wild_Rabbit')

        local pos = low:getPos()
        high:setPos(pos.x, pos.y, pos.z, 0)

        low.actions:inviteToParty(high)
        high.actions:acceptPartyInvite()
        xi.test.world:tick()
    end

    it('gives EXP with a 9 level gap', function()
        party(10, 19)

        assert(expFor(low) > 0, 'the low member got no EXP')
        assert(expFor(high) > 0, 'the high member got no EXP')
    end)

    it('gives nobody EXP with a 10 level gap', function()
        party(10, 20)

        assert(expFor(low) == 0, 'the low member got EXP')
        assert(expFor(high) == 0, 'the high member got EXP')
    end)

    it('does not spend Dedication or start an EXP chain with a 10 level gap', function()
        party(10, 20)
        low:addStatusEffect(xi.effect.DEDICATION, { power = 50, subPower = 1000, duration = 3600, origin = low })

        local result = resultFor(low)

        assert(result.exp == 0, 'the low member got EXP')
        assert(result.chainWindow == 0, 'a level gap kill opened an EXP chain window')
        assert(low:getStatusEffect(xi.effect.DEDICATION):getSubPower() == 1000, 'a level gap kill used up Dedication')
    end)

    it('ignores a member far from the mob', function()
        party(10, 20)
        local pos = low:getPos()
        high:setPos(pos.x + 150, pos.y, pos.z, 0)

        assert(expFor(low) > 0, 'a member out of range still blocked EXP')
    end)
end)
