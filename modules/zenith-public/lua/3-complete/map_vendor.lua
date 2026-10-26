-- -----------------------------------
-- Map Vendor Module
--
-- This module overrides the default behaviour of map vendors.
-- -----------------------------------

require('modules/module_utils')

local m = Module:new('map_vendor')

-- A map is for sale here when it has a price (-1 means not sold), the player does not own it yet,
-- and the vendor's region is in its region list. The menu and the purchase both use this, so a
-- client cannot buy a map the menu would not show.
local function isMapForSale(player, mapId)
    local mapEntry = xi.maps.mapInfo[mapId]
    if
        not mapEntry or
        type(mapEntry[2]) ~= 'number' or
        mapEntry[2] <= 0 or
        player:hasKeyItem(mapEntry[1])
    then
        return false
    end

    local currentRegion = player:getZone():getRegionID()
    for _, region in ipairs(mapEntry[3] or {}) do
        if region == currentRegion then
            return true
        end
    end

    return false
end

local function getMapEventParams(player)
    local paramTable = { 0, 0, 0 }

    for mapId = 0, #xi.maps.mapInfo do
        local paramPos = math.floor((mapId) / 32) + 1

        -- a set bit hides the map from the vendor's menu
        if not isMapForSale(player, mapId) then
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

    -- The option comes from the client, so check it again before taking any gil
    if
        bit.band(option, 0xF) == 1 and
        isMapForSale(player, mapId)
    then
        local mapCost = xi.maps.mapInfo[mapId][2]

        if mapCost <= player:getGil() then
            player:delGil(mapCost)
            npcUtil.giveKeyItem(player, xi.maps.mapInfo[mapId][1])
        else
            player:messageSpecial(zones[player:getZoneID()].text.NOT_HAVE_ENOUGH_GIL)
        end
    end

    player:updateEvent(unpack(getMapEventParams(player)))
end)

return m
