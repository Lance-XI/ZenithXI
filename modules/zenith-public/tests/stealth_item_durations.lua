-- ZenithXI era durations for stealth items (modules/zenith-public/lua/3-complete/stealth_item_durations.lua, ZENITHDEV-255).
--
-- Prism Powder, Silent Oil and Deodorizer last a random 1:30 to 6:00 and Rainbow Powder a fixed 3:00,
-- whatever expansions are enabled. Base gives all four 10 minutes.

describe('Zenith stealth item durations', function()
    ---@type CClientEntityPair
    local player

    local multiplier = xi.settings.main.SNEAK_INVIS_DURATION_MULTIPLIER

    local function use(item, effect)
        xi.items[item].onItemUse(player, player)

        local status = player:getStatusEffect(effect)
        assert(status, string.format('%s gave no effect', item))

        return status:getDuration() / 1000
    end

    local function assertBetween(seconds, low, high, item)
        assert(seconds >= low and seconds <= high, string.format('%s lasts %d seconds, expected %d to %d', item, seconds, low, high))
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE })
    end)

    it('gives Prism Powder a random 90 to 360 second Invisible', function()
        assertBetween(use('pinch_of_prism_powder', xi.effect.INVISIBLE), math.floor(90 * multiplier), math.floor(360 * multiplier), 'Prism Powder')
    end)

    it('gives Silent Oil a random 90 to 360 second Sneak', function()
        assertBetween(use('pot_of_silent_oil', xi.effect.SNEAK), math.floor(90 * multiplier), math.floor(360 * multiplier), 'Silent Oil')
    end)

    it('gives Deodorizer a random 90 to 360 second Deodorize', function()
        assertBetween(use('flask_of_deodorizer', xi.effect.DEODORIZE), 90, 360, 'Deodorizer')
    end)

    it('gives Rainbow Powder a fixed 180 second Invisible', function()
        local seconds = use('pinch_of_rainbow_powder', xi.effect.INVISIBLE)
        assert(seconds == math.floor(180 * multiplier), string.format('Rainbow Powder lasts %d seconds, expected %d', seconds, math.floor(180 * multiplier)))
    end)
end)
