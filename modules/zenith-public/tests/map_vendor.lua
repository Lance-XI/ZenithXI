-- ZenithXI map vendor (modules/zenith-public/lua/3-complete/map_vendor.lua, ZENITHDEV-254).
--
-- A purchase is checked on the server: the map must be sold by this vendor's region, have a price
-- and not be owned yet, whatever the client sends. Map of Beadeaux costs its era price of 3000 gil.
-- Karine in Bastok Markets (event 210) sells the Bastok maps.

describe('Zenith map vendor', function()
    ---@type CClientEntityPair
    local player

    local beadeaux   = 10 -- Bastok region
    local palborough = 9  -- Bastok region
    local giddeus    = 11 -- Windurst region only

    local function buy(mapId)
        -- what the client sends when a map is picked from the menu
        player.events:update(210, bit.bor(bit.lshift(mapId, 16), 1))
    end

    before_each(function()
        player = xi.test.world:spawnPlayer()
        player:gotoZone(xi.zone.BASTOK_MARKETS)

        -- Zoning into Bastok Markets plays event 22 first
        player.events:finish(22)
        -- opens Karine's menu (event 210); buy() fails the case if it is not open
        player.entities:gotoAndTrigger('Karine')
    end)

    it('sells Map of Beadeaux for 3000 gil', function()
        player:setGil(5000)
        buy(beadeaux)

        assert(player:hasKeyItem(xi.keyItem.MAP_OF_BEADEAUX), 'the map was not given')
        assert(player:getGil() == 2000, string.format('expected 2000 gil left, got %d', player:getGil()))
    end)

    it('does not sell a map the player already owns', function()
        player:addKeyItem(xi.keyItem.MAP_OF_BEADEAUX)
        player:setGil(5000)
        buy(beadeaux)

        assert(player:getGil() == 5000, 'gil was taken for a map the player already owns')
    end)

    it('does not sell a map from another region', function()
        player:setGil(5000)
        buy(giddeus)

        assert(not player:hasKeyItem(xi.keyItem.MAP_OF_GIDDEUS), 'a Windurst-only map was sold in Bastok')
        assert(player:getGil() == 5000, 'gil was taken for a map from another region')
    end)

    it('does not sell a map that is not for sale', function()
        local price = xi.maps.mapInfo[palborough][2]
        xi.maps.mapInfo[palborough][2] = -1
        player:setGil(5000)
        buy(palborough)
        xi.maps.mapInfo[palborough][2] = price

        assert(not player:hasKeyItem(xi.keyItem.MAP_OF_THE_PALBOROUGH_MINES), 'a map priced -1 was sold')
        assert(player:getGil() == 5000, 'gil was taken for a map that is not for sale')
    end)

    it('does not sell without enough gil', function()
        player:setGil(100)
        buy(beadeaux)

        assert(not player:hasKeyItem(xi.keyItem.MAP_OF_BEADEAUX), 'the map was given without enough gil')
        assert(player:getGil() == 100, 'gil changed on a refused purchase')
    end)
end)
