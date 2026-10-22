-- ZenithXI Saboteur (modules/zenith-public/lua/3-complete/jobAbilities/saboteur.lua).
--
-- Saboteur wears off after the next enfeebling magic spell, as before 2019.

describe('Zenith Saboteur', function()
    ---@type CClientEntityPair
    local player
    ---@type CTestEntity
    local mob

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.RDM, level = 99 })
        player:addSpell(xi.magic.spell.PARALYZE)
        player:addSpell(xi.magic.spell.CURE)
        player:setMP(player:getMaxMP())

        mob = player.entities:moveTo('Wild_Rabbit')
        mob:respawn()
        mob:setUnkillable(true)

        player:addStatusEffect(xi.effect.SABOTEUR, { power = 1, duration = 60, origin = player })
        assert(player:hasStatusEffect(xi.effect.SABOTEUR), 'precondition: Saboteur is up')
    end)

    local function cast(target, spellId)
        player.actions:useSpell(target, spellId)
        for _ = 1, 5 do
            xi.test.world:skipTime(2)
        end
    end

    it('wears off after the next enfeebling spell', function()
        cast(mob, xi.magic.spell.PARALYZE)

        assert(not player:hasStatusEffect(xi.effect.SABOTEUR), 'Saboteur is still up after Paralyze')
    end)

    it('stays up after a spell that is not enfeebling magic', function()
        cast(player, xi.magic.spell.CURE)

        assert(player:hasStatusEffect(xi.effect.SABOTEUR), 'Saboteur wore off after Cure')
    end)
end)
