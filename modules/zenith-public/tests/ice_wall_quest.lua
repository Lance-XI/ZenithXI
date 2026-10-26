-- ZenithXI Ice Wall (modules/zenith-public/lua/3-complete/ice_wall_quest.lua).
--
-- An LQS quest adds an "Ice Wall" NPC to Uleguerand Range (dynamic entity DE_Ice Wall). Trading it
-- one Fire Cluster while the waterfall (_058) is closed opens the waterfall, which LSB only opens
-- when the weather is not snow or blizzards. While the waterfall is open the trade is ignored, and
-- any other item is declined. LSB has no such NPC.

describe('Zenith Ice Wall', function()
    local ID = zones[xi.zone.ULEGUERAND_RANGE]

    ---@type CClientEntityPair
    local player

    local function waterfall()
        return GetNPCByID(ID.npc.WATERFALL)
    end

    -- The module's NPC, or a failure that says it is missing (entities:get would raise instead)
    local function iceWall()
        local found = GetZone(xi.zone.ULEGUERAND_RANGE):queryEntitiesByName('DE_Ice Wall')
        assert(found and #found == 1, 'Uleguerand Range has no Ice Wall NPC to trade the Fire Cluster to')

        return found[1]
    end

    -- The accepted dialog plays before LQS completes the trade
    local function waitForTrade()
        for _ = 1, 3 do
            xi.test.world:skipTime(2)
        end
    end

    -- LQS dialog calls bindings from modules/LQS/cpp, which is built into xi_map but not xi_test.
    -- Stand in for the ones the Ice Wall dialog uses: they turn the NPC and print chat lines.
    setup(function()
        for _, binding in ipairs({ 'ceFace', 'ceReset', 'fmt', 'sys' }) do
            if _G.CBaseEntity[binding] == nil then
                _G.CBaseEntity[binding] = function()
                end
            end
        end
    end)

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.ULEGUERAND_RANGE, job = xi.job.WAR, level = 75 })
        player:addItem(xi.item.FIRE_CLUSTER)
        player:addItem(xi.item.ICE_CLUSTER)

        waterfall():setAnimation(xi.animation.CLOSE_DOOR)
    end)

    it('opens the closed waterfall for a Fire Cluster', function()
        player.actions:tradeNpc(iceWall():getID(), { xi.item.FIRE_CLUSTER })
        waitForTrade()

        assert(waterfall():getAnimation() == xi.animation.OPEN_DOOR, 'trading a Fire Cluster to the Ice Wall did not open the waterfall')
        assert(not player:hasItem(xi.item.FIRE_CLUSTER), 'the Fire Cluster was not taken')
    end)

    it('declines other items and leaves the waterfall closed', function()
        player.actions:tradeNpc(iceWall():getID(), { xi.item.ICE_CLUSTER })
        waitForTrade()

        assert(waterfall():getAnimation() == xi.animation.CLOSE_DOOR, 'an Ice Cluster opened the waterfall')
        assert(player:hasItem(xi.item.ICE_CLUSTER), 'the declined Ice Cluster was taken')
    end)

    it('keeps the Fire Cluster while the waterfall is already open', function()
        local wall = iceWall()
        waterfall():setAnimation(xi.animation.OPEN_DOOR)

        player.actions:tradeNpc(wall:getID(), { xi.item.FIRE_CLUSTER })
        waitForTrade()

        assert(player:hasItem(xi.item.FIRE_CLUSTER), 'the Fire Cluster was taken while the waterfall was open')
    end)
end)
