-- ZenithXI era fame ranks (modules/zenith-public/lua/3-complete/era_fame_rank_points.lua, ZENITHDEV-260).
--
-- Fame ranks use the thresholds from before the February 2014 relaxation. 500 fame points are rank 3
-- (base's relaxed table makes them rank 7); 2450 points are still the top rank.
-- The module sets the table on server start, which xi_test does not run by itself.

describe('Zenith era fame ranks', function()
    ---@type CClientEntityPair
    local player

    setup(function()
        xi.server.onServerStart()
    end)

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.SOUTHERN_SAN_DORIA })
    end)

    local function rankAt(points)
        player:setFame(xi.fameArea.SANDORIA, points)
        return player:getFameLevel(xi.fameArea.SANDORIA)
    end

    it('needs era fame points for each rank', function()
        assert(rankAt(500) == 3, string.format('500 fame points give rank %d, expected 3', rankAt(500)))
        assert(rankAt(499) == 2, string.format('499 fame points give rank %d, expected 2', rankAt(499)))
    end)

    it('still reaches the top rank at 2450 points', function()
        assert(rankAt(2450) == 9, string.format('2450 fame points give rank %d, expected 9', rankAt(2450)))
    end)
end)
