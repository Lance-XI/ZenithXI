-- ZenithXI Thief enmity rebalance (modules/zenith-public/lua/4-additive/jobAbilities/thfEnimityRebalance.lua).
--
-- 1. Each Ambush merit upgrade takes 1 second off the Sneak Attack and Trick Attack recasts.
--    player:getMerit(xi.merit.AMBUSH) is upgrades x the merit's per-upgrade value, so the module
--    divides it by that value. LSB does not touch either recast.
-- 2. When Trick Attack ends before it expires (a hit consumed it), 50% x (THF level / 75) of the
--    Thief's CE and VE on its target move to the Trick Attack partner. LSB moves nothing.
--
-- The recast cases raise 1 or 5 Ambush upgrades through the real merit packet (0x0BE) in a Mog
-- House, and read the recast from the ABILITY_USE listener, which gets the ability after
-- onAbilityCheck. Every upgrade is checked to have raised getMerit by the same step, so the
-- upgrade count is known without the test hard-coding the merit's value.
-- The transfer case puts the partner between the Thief and the mob, with the Thief engaged.

local ffi = require('ffi')

ffi.cdef [[
    // 0x0BE - merit menu: Kind 3 = edit, Param1 1 = raise, Param2 = merit id >> 1
    typedef struct {
        uint16_t id : 9;
        uint16_t size : 7;
        uint16_t sync;
        uint8_t  Kind;
        uint8_t  Param1;
        uint16_t Param2;
        uint32_t Param3;
    } ZENITH_GP_CLI_COMMAND_MERITS;
]]

describe('Zenith Thief enmity rebalance', function()
    ---@type CClientEntityPair
    local player

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.THF, level = 75 })
    end)

    -- Raises Ambush by `upgrades` in a Mog House and comes back to West Ronfaure.
    local function raiseAmbush(upgrades)
        player:setMerits(30) -- 5 Ambush upgrades cost 3 + 4 + 5 + 5 + 5 = 22
        player:gotoMogHouse(xi.zone.SOUTHERN_SAN_DORIA)
        if player:isInEvent() then
            player.events:finish()
        end

        local packet  = ffi.new('ZENITH_GP_CLI_COMMAND_MERITS')
        packet.Kind   = 3
        packet.Param1 = 1
        packet.Param2 = bit.rshift(xi.merit.AMBUSH, 1)

        local step = nil
        for upgrade = 1, upgrades do
            player.packets:send(0x0BE, packet, ffi.sizeof(packet))

            local merit = player:getMerit(xi.merit.AMBUSH)
            step        = step or merit
            assert(step > 0 and merit == upgrade * step, string.format('precondition: Ambush upgrade %d was not raised (getMerit %d)', upgrade, merit))
        end

        player:gotoZone(xi.zone.WEST_RONFAURE)
        if player:isInEvent() then
            player.events:finish()
        end

        assert(player:getMerit(xi.merit.AMBUSH) == upgrades * step, string.format('precondition: %d Ambush upgrades did not survive zoning', upgrades))
    end

    -- Uses the ability on the player itself and returns the recast the ability was used with.
    local function recastOf(abilityId)
        local recast = nil
        player:addListener('ABILITY_USE', 'ZENITH_TEST_THF_RECAST', function(entity, target, ability, action)
            if ability:getID() == abilityId then
                recast = ability:getRecast()
            end
        end)

        player.actions:useAbility(player, abilityId)
        xi.test.world:tick()
        player:removeListener('ZENITH_TEST_THF_RECAST')

        assert(recast, string.format('precondition: ability %d was not used', abilityId))

        return recast
    end

    local recastCases =
    {
        { name = 'Sneak Attack', id = xi.jobAbility.SNEAK_ATTACK, upgrades = 1 },
        { name = 'Trick Attack', id = xi.jobAbility.TRICK_ATTACK, upgrades = 1 },
        { name = 'Sneak Attack', id = xi.jobAbility.SNEAK_ATTACK, upgrades = 5 },
        { name = 'Trick Attack', id = xi.jobAbility.TRICK_ATTACK, upgrades = 5 },
    }

    for _, case in ipairs(recastCases) do
        it(string.format('takes %d second(s) off the %s recast for %d Ambush upgrade(s)', case.upgrades, case.name, case.upgrades), function()
            raiseAmbush(case.upgrades)

            local base     = GetAbility(case.id):getRecast()
            local expected = base - case.upgrades
            assert(expected > 0, string.format('precondition: base recast %d is not above %d', base, case.upgrades))

            local recast = recastOf(case.id)

            assert(recast == expected, string.format('%s recast: expected %d (%d - 1 s per upgrade x %d), got %d', case.name, expected, base, case.upgrades, recast))
        end)
    end

    it('moves half the Thief enmity to the Trick Attack partner at THF 75', function()
        local partner = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.PLD, level = 75 })
        local mob     = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)

        player.actions:inviteToParty(partner)
        partner.actions:acceptPartyInvite()

        player.actions:engage(mob)
        xi.test.world:tick()
        assert(player:getTarget() and player:getTarget():getID() == mob:getID(), 'precondition: the Thief is not engaged on the rabbit')

        -- Partner 2 yalms from the rabbit, Thief 4 yalms away on the same line, so the partner is in front.
        local pos = mob:getPos()
        partner:setPos(pos.x + 2, pos.y, pos.z, 0)
        player:setPos(pos.x + 4, pos.y, pos.z, 0)

        local rabbit = GetMobByID(mob:getID())
        local thief  = GetPlayerByID(player:getID())
        local tank   = GetPlayerByID(partner:getID())

        player:addStatusEffect(xi.effect.TRICK_ATTACK, { power = 0, duration = 60, origin = player })
        assert(player:getTrickAttackChar(rabbit) and player:getTrickAttackChar(rabbit):getID() == partner:getID(), 'precondition: the partner is not the Trick Attack target')

        rabbit:setCE(thief, 1000)
        rabbit:setVE(thief, 2000)
        rabbit:setCE(tank, 0)
        rabbit:setVE(tank, 0)

        -- Ending Trick Attack with time left on it, as a landed hit does
        player:delStatusEffect(xi.effect.TRICK_ATTACK)

        local thiefCE = rabbit:getCE(thief)
        local thiefVE = rabbit:getVE(thief)
        local tankCE  = rabbit:getCE(tank)
        local tankVE  = rabbit:getVE(tank)

        assert(tankCE == 500, string.format('partner CE: expected 500 (50%% of 1000), got %d', tankCE))
        assert(tankVE == 1000, string.format('partner VE: expected 1000 (50%% of 2000), got %d', tankVE))
        assert(thiefCE == 500, string.format('Thief CE: expected 500 left, got %d', thiefCE))
        assert(thiefVE == 1000, string.format('Thief VE: expected 1000 left, got %d', thiefVE))
    end)
end)
