-- -----------------------------------
-- Map Vendor Module
--
-- This module overrides the default behaviour of map vendors.
-- A vendor only shows, and only sells, maps that are for sale in its region and that the
-- player does not own yet. Purchases are checked again on the server, so a crafted event
-- update cannot buy a hidden map.
-- -----------------------------------

require('modules/module_utils')

local m = Module:new('c_map_vendor')

-- True when the region is in the map entry's list of regions that sell it
local function isSoldInRegion(mapEntry, region)
    if mapEntry[3] == nil then
        return false
    end

    for _, soldRegion in ipairs(mapEntry[3]) do
        if soldRegion == region then
            return true
        end
    end

    return false
end

-- True when this vendor offers the map to the player: it exists, is for sale (cost above 0),
-- is sold in the vendor's region and the player does not already have its key item.
local function isMapOffered(player, mapEntry, region)
    return mapEntry ~= nil and
        mapEntry[2] > 0 and
        isSoldInRegion(mapEntry, region) and
        not player:hasKeyItem(mapEntry[1])
end

local function getMapEventParams(player)
    local paramTable = { 0, 0, 0 }
    local currentRegion = player:getZone():getRegionID()

    for mapId = 0, #xi.maps.mapInfo do
        local paramPos = math.floor((mapId) / 32) + 1

        -- A set bit hides the map from the vendor menu
        if not isMapOffered(player, xi.maps.mapInfo[mapId], currentRegion) then
            paramTable[paramPos] = bit.bor(paramTable[paramPos], bit.lshift(1, mapId))
        end
    end

    return paramTable
end

m:addOverride('xi.maps.onTrigger', function(player, npc)
    local eventParams = getMapEventParams(player)

    player:startEvent(xi.maps.mapVendors[npc:getName()], eventParams[1], eventParams[2], eventParams[3])
end)

m:addOverride('xi.maps.onEventUpdate', function(player, csid, option, npc)
    if csid ~= xi.maps.mapVendors[npc:getName()] then
        return
    end

    local mapId = bit.rshift(option, 16)

    if bit.band(option, 0xF) == 1 then
        local mapEntry = xi.maps.mapInfo[mapId]

        -- Anything the menu would not offer is ignored: no gil taken, no key item given
        if isMapOffered(player, mapEntry, player:getZone():getRegionID()) then
            local mapCost = mapEntry[2]

            if player:getGil() < mapCost then
                player:messageSpecial(zones[player:getZoneID()].text.NOT_HAVE_ENOUGH_GIL)
            elseif player:delGil(mapCost) then
                npcUtil.giveKeyItem(player, mapEntry[1])
            end
        end
    end

    player:updateEvent(unpack(getMapEventParams(player)))
end)

return m
