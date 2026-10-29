-- ZenithXI Lamian Fang Key (modules/zenith-public/lua/3-complete/lamian_fang_key.lua, ZENITHDEV-256).
--
-- The ??? (qm8) in Caedarva Mire gives a free Lamian Fang Key once per conquest tally. Base gives one
-- every Vana'diel day, so a second try a Vana'diel day later must get nothing.
-- Caedarva Mire is disabled (DisableZones.sql), which makes the framework skip the module's override,
-- so the test runs the module's handler directly.

describe('Zenith Lamian Fang Key', function()
    ---@type CClientEntityPair
    local player
    local npc

    local function trigger()
        zxi.lamianFangKey.onTrigger(player, npc)
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.CAEDARVA_MIRE })
        npc    = player.entities:get('qm8')
    end)

    it('gives a key on the first try', function()
        trigger()

        assert(player:hasItem(xi.item.LAMIAN_FANG_KEY), 'no Lamian Fang Key was given')
    end)

    it('gives no second key a Vana\'diel day later', function()
        -- the test needs the tally to be more than an hour away, which is true except on Sunday evenings
        if NextConquestTally() - GetSystemTime() < 2 * 3600 then
            return
        end

        trigger()
        player:delItem(xi.item.LAMIAN_FANG_KEY, 1)

        xi.test.world:skipToNextVanaDay()
        trigger()

        assert(not player:hasItem(xi.item.LAMIAN_FANG_KEY), 'a second key was given before the conquest tally')
    end)
end)
