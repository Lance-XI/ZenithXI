-- ZenithXI Unlocking a Myth WS points (modules/zenith-public/lua/3-complete/unlocking_a_myth.lua, ZENITHDEV-259).
--
-- The weapon skill points a Vigil weapon needs depend on Nyzul Isle floor progress again:
-- 16,000 at floor 0 down to 250 at floor 100. Base always needs 250.

describe('Zenith Unlocking a Myth', function()
    ---@type CClientEntityPair
    local player

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.PLD, level = 75 })
    end)

    local function pointsAtFloor(floor)
        player:setCharVar('NyzulFloorProgress', floor)
        return xi.equipment.vigilWeaponRequiredWsPoints(player)
    end

    it('scales the points with Nyzul Isle floor progress', function()
        local expected = { [0] = 16000, [19] = 8000, [50] = 2720, [99] = 500 }

        for floor, points in pairs(expected) do
            local actual = pointsAtFloor(floor)
            assert(actual == points, string.format('floor %d needs %d points, expected %d', floor, actual, points))
        end
    end)

    it('still needs 250 points after floor 100', function()
        assert(pointsAtFloor(100) == 250, string.format('floor 100 needs %d points, expected 250', pointsAtFloor(100)))
    end)

    it('sets the points on a Vigil weapon when it is equipped', function()
        player:setCharVar('NyzulFloorProgress', 0)
        player:addItem(xi.item.BRAVE_BLADE)
        player:equipItem(xi.item.BRAVE_BLADE, nil, xi.slot.MAIN)

        local blade = player:getEquippedItem(xi.slot.MAIN)
        assert(blade and blade:getID() == xi.item.BRAVE_BLADE, 'precondition: Brave Blade is equipped')
        assert(blade:getWeaponskillPointsNeeded() == 16000, string.format('Brave Blade needs %d points, expected 16000', blade:getWeaponskillPointsNeeded()))
    end)
end)
