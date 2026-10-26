-- ZenithXI map vendors (modules/zenith-public/lua/3-complete/map_vendor.lua).
--
-- Base's map vendor menu hides only the maps the player owns. The module also hides every map that
-- xi.maps.mapInfo (1-enum/xi/maps.lua) marks not for sale (cost -1) or does not sell in the
-- vendor's region, both when the menu opens and in every update after a purchase. A purchase
-- request is checked the same way, so a crafted event update cannot buy a map the menu hides,
-- a map the player owns, or a map the player cannot pay for.
-- Ludwig (Mhaura, Kolshushu, event 500):
--   map 0 San d'Oria Area: sold in Kolshushu, so shown;
--   map 4 Ordelle's Caves: sold in San d'Oria only, so hidden;
--   map 20 Northlands Area: not for sale, so hidden.
-- A set bit in the event parameters hides map N (parameter N // 32, bit N % 32).

describe('Zenith map vendors', function()
    ---@type CClientEntityPair
    local player

    local ludwigEvent = 500

    local sandoriaArea = 0  -- xi.keyItem.MAP_OF_THE_SAN_DORIA_AREA
    local ordellesCaves = 4 -- xi.keyItem.MAP_OF_ORDELLES_CAVES
    local northlands    = 20 -- xi.keyItem.MAP_OF_THE_NORTHLANDS_AREA

    local function readParams(data, offset)
        local params = {}
        for i = 0, 7 do
            local at  = offset + i * 4
            params[i] = data[at] + data[at + 1] * 256 + data[at + 2] * 65536 + data[at + 3] * 16777216
        end

        return params
    end

    -- Parameters of the event the server started (0x034) or last updated (0x05C)
    local function lastParams(packetType, offset)
        local params = nil
        for _, pkt in pairs(player.packets:getIncoming()) do
            if pkt.type == packetType then
                params = readParams(pkt.data, offset)
                if packetType == 0x034 then
                    params.eventId = pkt.data[0x2C] + pkt.data[0x2D] * 256
                end
            end
        end

        return params
    end

    local function isHidden(params, mapId)
        return bit.band(params[math.floor(mapId / 32)], bit.lshift(1, mapId % 32)) ~= 0
    end

    local function openLudwig()
        player.packets:clear()
        player.entities:gotoAndTrigger('Ludwig')

        local params = lastParams(0x034, 0x08)
        assert(params ~= nil and params.eventId == ludwigEvent, 'precondition: Ludwig opens his map menu (event 500)')

        return params
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.MHAURA })
        assert(GetPlayerByID(player:getID()):getZone():getRegionID() == xi.region.KOLSHUSHU, 'precondition: Mhaura is in Kolshushu')
    end)

    after_each(function()
        player.events:finish(ludwigEvent, utils.EVENT_CANCELLED_OPTION)
    end)

    it('hides maps that are not sold in the vendor\'s region or not sold at all', function()
        local params = openLudwig()

        assert(not isHidden(params, sandoriaArea), 'Ludwig hides the San d\'Oria Area map, which Kolshushu sells')
        assert(isHidden(params, ordellesCaves), 'Ludwig shows the Ordelle\'s Caves map, which only San d\'Oria sells')
        assert(isHidden(params, northlands), 'Ludwig shows the Northlands Area map, which is not for sale')
    end)

    it('keeps the region filter in the menu update after a purchase', function()
        player:setGil(1000)
        openLudwig()

        player.packets:clear()
        player.events:update(ludwigEvent, bit.bor(bit.lshift(sandoriaArea, 16), 1))

        -- The sale itself is the same as base (a control): 200 gil for the map
        assert(player:hasKeyItem(xi.keyItem.MAP_OF_THE_SAN_DORIA_AREA), 'precondition: the San d\'Oria Area map was bought')
        assert(player:getGil() == 800, string.format('expected 800 gil left after a 200 gil map, got %d', player:getGil()))

        local params = lastParams(0x05C, 0x04)
        assert(params ~= nil, 'precondition: Ludwig updated the menu after the sale')
        assert(isHidden(params, sandoriaArea), 'the updated menu still shows the map just bought')
        assert(isHidden(params, ordellesCaves), 'the updated menu shows the Ordelle\'s Caves map, which only San d\'Oria sells')
    end)

    -- Crafted purchase requests for maps the menu does not offer, sent as the client's event update.
    -- Each must leave the player without the map and with every gil.
    describe('rejects a crafted purchase', function()
        local function requestMap(mapId)
            player.events:update(ludwigEvent, bit.bor(bit.lshift(mapId, 16), 1))
        end

        local function assertRejected(keyItem, gil, what)
            assert(not player:hasKeyItem(keyItem), string.format('Ludwig handed over %s', what))
            assert(player:getGil() == gil, string.format('expected %d gil after the rejected request for %s, got %d', gil, what, player:getGil()))
        end

        it('of a map that is not for sale', function()
            player:setGil(10000)
            openLudwig()

            requestMap(northlands)

            assertRejected(xi.keyItem.MAP_OF_THE_NORTHLANDS_AREA, 10000, 'the Northlands Area map, which is not for sale')
        end)

        it('of a map another region sells', function()
            player:setGil(10000)
            openLudwig()

            requestMap(ordellesCaves)

            assertRejected(xi.keyItem.MAP_OF_ORDELLES_CAVES, 10000, 'the Ordelle\'s Caves map, which only San d\'Oria sells')
        end)

        it('of a map the player already owns', function()
            player:addKeyItem(xi.keyItem.MAP_OF_THE_SAN_DORIA_AREA)
            player:setGil(10000)
            openLudwig()

            requestMap(sandoriaArea)

            assert(player:getGil() == 10000, string.format('Ludwig charged %d gil again for the San d\'Oria Area map the player owns', 10000 - player:getGil()))
        end)

        -- A control: the old handler already refused this, so it passes with or without the fix
        it('of a map the player cannot afford', function()
            player:setGil(199)
            openLudwig()

            requestMap(sandoriaArea)

            assertRejected(xi.keyItem.MAP_OF_THE_SAN_DORIA_AREA, 199, 'the 200 gil San d\'Oria Area map to a player with 199 gil')
        end)
    end)
end)
