-- ZenithXI jug pet Ready TP requirement (modules/zenith-public/lua/4-additive/jobAbilities/jugPetReadyTPRequirement.lua).
--
-- A Beastmaster jug pet needs 1000 TP before it can use a Ready move. LSB lets it use them at any
-- TP. The module also creates an onAbilityCheck gate for Ready moves that have no script upstream
-- (Spider Web here, scripts/actions/abilities/pets/spider_web.lua does not exist).
--
-- Setup: BST 75 with a Sheep Familiar (a jug pet) engaged on a Wild Rabbit, using Lamb Chop.
-- The case with the pet at 1000 TP is a control and passes with or without the module, on purpose.

describe('Zenith jug pet Ready TP requirement', function()
    ---@type CClientEntityPair
    local player
    ---@type CTestEntity
    local mob

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.BST, level = 75 })
        mob    = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)

        player:spawnPet(xi.petId.SHEEP_FAMILIAR)
        assert(player:getPet(), 'precondition: the jug pet did not spawn')
        assert(player:hasJugPet(), 'precondition: the Sheep Familiar is not a jug pet')
    end)

    -- Has the pet use Lamb Chop through the real Ready path. Returns whether the move went off and
    -- whether the player was told the pet lacks TP.
    local function useLambChop(petTP)
        local pet = player:getPet()
        pet:setAutoAttackEnabled(false)
        pet:engage(mob:getTargID())
        xi.test.world:tickEntity(pet)
        xi.test.world:skipTime(2)

        -- The rabbit roams, so put the pet back beside it right before the move
        local pos = mob:getPos()
        pet:setPos(pos.x + 1, pos.y, pos.z, 0)
        player:setPos(pos.x + 2, pos.y, pos.z, 0)

        pet:setTP(petTP)
        player.packets:clear()
        player.actions:useAbility(player, xi.jobAbility.LAMB_CHOP) -- the Ready packet targets the master, as in LSB 0x028 beastmaster.lua
        for _ = 1, 3 do
            xi.test.world:skipTime(2)
        end

        local used   = false
        local toldTP = false
        for _, action in ipairs(player.packets:actionPackets()) do
            if
                action.cmd_no == xi.action.category.JOBABILITY_FINISH and
                action.cmd_arg == xi.jobAbility.LAMB_CHOP
            then
                used = true
            end
        end

        for _, packet in pairs(player.packets:getIncoming()) do
            if
                packet.type == 0x029 and
                bit.band(packet.data[0x18] + packet.data[0x19] * 256, 0x7FFF) == xi.msg.basic.PET_NOT_ENOUGH_TP
            then
                toldTP = true
            end
        end

        return used, toldTP
    end

    it('blocks Lamb Chop when the jug pet is under 1000 TP', function()
        local used, toldTP = useLambChop(500)

        assert(not used, 'the jug pet used Lamb Chop at 500 TP')
        assert(toldTP, 'the player was not told the pet lacks TP (PET_NOT_ENOUGH_TP)')
    end)

    -- Control: passes with or without the module.
    it('allows Lamb Chop when the jug pet has 1000 TP', function()
        local used = useLambChop(1000)

        assert(used, 'the jug pet did not use Lamb Chop at 1000 TP')
    end)

    it('rejects the check with PET_NOT_ENOUGH_TP under 1000 TP', function()
        player:getPet():setTP(999)

        local result = xi.actions.abilities.pets.lamb_chop.onAbilityCheck(GetPlayerByID(player:getID()), GetMobByID(mob:getID()), nil)

        assert(result == xi.msg.basic.PET_NOT_ENOUGH_TP, string.format('expected PET_NOT_ENOUGH_TP (%d) at 999 TP, got %s', xi.msg.basic.PET_NOT_ENOUGH_TP, tostring(result)))
    end)

    it('gates a Ready move that has no script upstream', function()
        local moveScript = xi.actions.abilities.pets.spider_web

        assert(moveScript and moveScript.onAbilityCheck, 'Spider Web has no onAbilityCheck gate')

        player:getPet():setTP(0)
        local result = moveScript.onAbilityCheck(GetPlayerByID(player:getID()), GetMobByID(mob:getID()), nil)

        assert(result == xi.msg.basic.PET_NOT_ENOUGH_TP, string.format('expected PET_NOT_ENOUGH_TP (%d) at 0 TP, got %s', xi.msg.basic.PET_NOT_ENOUGH_TP, tostring(result)))
    end)
end)
