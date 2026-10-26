-- ZenithXI HELM zone configuration (modules/zenith-public/lua/2-base/helm_config.lua).
--
-- At server start the module rewrites xi.helm.dataTable per zone: break rate, the whole drop table,
-- and drops gated on ENABLE_<EXPANSION>. Base xi.helm.onTrade keeps running and reads those values.
--
-- Zeruhn Mines mining: LSB breakRate 38.32 and no Gold Ore; module breakRate 45, Copper Ore 240 and
--   Gold Ore 5. obtainRate (89.88) is not configured, so it stays LSB's.
-- West Sarutabaruta harvesting: LSB breakRate 6.05, Fresh Mugwort 110; module breakRate 10 and
--   Mugwort 10 from additionalDropsROTZ (ENABLE_ROTZ is 1 in the test settings).

describe('Zenith HELM config', function()
    ---@type CClientEntityPair
    local player

    local function zoneData(helmType, zoneId)
        return xi.helm.dataTable[helmType].zone[zoneId]
    end

    local function weightOf(drops, itemId)
        local weight = 0
        for _, drop in ipairs(drops) do
            if drop[2] == itemId then
                weight = weight + drop[1]
            end
        end

        return weight
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.ZERUHN_MINES, level = 75 })
    end)

    it('breaks pickaxes 45% of the time in Zeruhn Mines', function()
        local breakRate = zoneData(xi.helmType.MINING, xi.zone.ZERUHN_MINES).breakRate

        assert(breakRate == 45, string.format('expected break rate 45, got %s', tostring(breakRate)))
    end)

    it('uses the module drop table in Zeruhn Mines', function()
        local drops = zoneData(xi.helmType.MINING, xi.zone.ZERUHN_MINES).drops

        assert(weightOf(drops, xi.item.CHUNK_OF_GOLD_ORE) == 5, string.format('expected Gold Ore at 5, got %d', weightOf(drops, xi.item.CHUNK_OF_GOLD_ORE)))
        assert(weightOf(drops, xi.item.CHUNK_OF_COPPER_ORE) == 240, string.format('expected Copper Ore at 240, got %d', weightOf(drops, xi.item.CHUNK_OF_COPPER_ORE)))
    end)

    -- Control: passes with or without the module. Zeruhn sets no 'rate', so the retail value stays.
    it('keeps the retail obtain rate where no rate is configured', function()
        local obtainRate = zoneData(xi.helmType.MINING, xi.zone.ZERUHN_MINES).obtainRate

        assert(math.abs(obtainRate - 89.88) < 0.001, string.format('expected the base obtain rate 89.88, got %s', tostring(obtainRate)))
    end)

    it('adds expansion-gated drops when the expansion is enabled', function()
        assert(xi.settings.main.ENABLE_ROTZ == 1, 'precondition: ENABLE_ROTZ must be 1 in the test settings')

        local data  = zoneData(xi.helmType.HARVESTING, xi.zone.WEST_SARUTABARUTA)
        local drops = data.drops

        assert(data.breakRate == 10, string.format('expected break rate 10, got %s', tostring(data.breakRate)))
        assert(weightOf(drops, xi.item.SPRIG_OF_FRESH_MUGWORT) == 10, string.format('expected Fresh Mugwort at 10 (additionalDropsROTZ), got %d', weightOf(drops, xi.item.SPRIG_OF_FRESH_MUGWORT)))
    end)

    -- The real trade at a Mining Point with every float roll at 40: below the 89.88 obtain rate (an item
    -- is found) and between LSB's 38.32 and the module's 45 break rate, so only the module breaks it.
    it('breaks the pickaxe on a roll LSB would let it survive', function()
        stub('math.randomFloat', 40)

        player:addItem(xi.item.PICKAXE)
        assert(player:getItemCount(xi.item.PICKAXE) == 1, 'precondition: the player has no pickaxe')

        player.entities:moveTo('Mining_Point')
        player.actions:tradeNpc('Mining_Point', { xi.item.PICKAXE }, { eventId = 165 })

        local left = player:getItemCount(xi.item.PICKAXE)
        assert(left == 0, string.format('a roll of 40 should break the pickaxe at a 45%% break rate, %d left', left))
    end)
end)
