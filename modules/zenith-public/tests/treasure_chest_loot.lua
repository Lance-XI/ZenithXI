-- ZenithXI treasure chest loot (modules/zenith-public/lua/2-base/treasure_chest_loot.lua, through the
-- xi.treasure.getItemTable accessor added by git-patches/113-TreasureChestLootHook.patch).
--
-- The module replaces the key-traded chest and coffer tables with a flattened set: the zone's unique
-- item at 200/1000, gil at 720 (920 when there is no unique item) and eight gems at 10 each. LSB
-- varies these per zone, e.g. Gusgen Mines chest: Frost Shield 400, Replica Maul 100, gil 430.
--
-- Entries are { itemId, weight } and xi.treasure.onTrade rolls them against 1..1000.

describe('Zenith treasure chest loot', function()
    local chest  = 1 -- treasureType.CHEST in scripts/globals/treasure.lua
    local coffer = 2 -- treasureType.COFFER

    ---@type CClientEntityPair
    local player

    local function weightOf(itemTable, itemId)
        for _, entry in ipairs(itemTable) do
            if entry[1] == itemId then
                return entry[2]
            end
        end

        return 0
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.GUSGEN_MINES, job = xi.job.THF, level = 75 })
    end)

    it('drops Replica Maul and no Frost Shield from Gusgen Mines chests', function()
        local itemTable = xi.treasure.getItemTable(xi.zone.GUSGEN_MINES, chest)

        assert(weightOf(itemTable, xi.item.FROST_SHIELD) == 0, string.format('expected no Frost Shield, got weight %d', weightOf(itemTable, xi.item.FROST_SHIELD)))
        assert(weightOf(itemTable, xi.item.REPLICA_MAUL) == 200, string.format('expected Replica Maul at 200, got %d', weightOf(itemTable, xi.item.REPLICA_MAUL)))
        assert(weightOf(itemTable, xi.item.NONE) == 720, string.format('expected gil at 720, got %d', weightOf(itemTable, xi.item.NONE)))
    end)

    it('gives Davoi chests the flat 200 unique-item weight', function()
        local itemTable = xi.treasure.getItemTable(xi.zone.DAVOI, chest)

        assert(weightOf(itemTable, xi.item.ELECTRUM_RING) == 200, string.format('expected Electrum Ring at 200, got %d', weightOf(itemTable, xi.item.ELECTRUM_RING)))
        assert(weightOf(itemTable, xi.item.NONE) == 720, string.format('expected gil at 720, got %d', weightOf(itemTable, xi.item.NONE)))
    end)

    it('gives Den of Rancor coffers all eight gems at 10 each', function()
        local itemTable = xi.treasure.getItemTable(xi.zone.DEN_OF_RANCOR, coffer)
        local gems      =
        {
            xi.item.AQUAMARINE, xi.item.CHRYSOBERYL, xi.item.FLUORITE, xi.item.JADEITE,
            xi.item.MOONSTONE, xi.item.PAINITE, xi.item.SUNSTONE, xi.item.ZIRCON,
        }

        for _, gem in ipairs(gems) do
            assert(weightOf(itemTable, gem) == 10, string.format('expected gem %d at 10, got %d', gem, weightOf(itemTable, gem)))
        end

        assert(weightOf(itemTable, xi.item.NONE) == 920, string.format('expected gil at 920, got %d', weightOf(itemTable, xi.item.NONE)))
    end)

    -- The real trade: xi.treasure.onTrade fetches its table through the accessor. A loot roll of 800
    -- is Replica Maul in the module's table (721..920) and Frost Shield in LSB's (431..830).
    it('awards the module table on a real key trade', function()
        stub('math.randomInt', function(low, high)
            if low == 1 and high == 1000 then
                return 800
            end

            return low
        end)

        local tradeSpy = spy('xi.treasure.onTrade')

        player:addItem(xi.item.GUSGEN_CHEST_KEY)
        assert(player:hasItem(xi.item.GUSGEN_CHEST_KEY), 'precondition: the player has no Gusgen Chest Key')

        -- xi.treasure.initZone opens, hides and moves the chest when the zone starts (about 12 s)
        local chestNpc = player.entities:get('Treasure_Chest')
        for _ = 1, 6 do
            xi.test.world:skipTime(3)
        end

        assert(chestNpc:getLocalVar('opened') == 0 and chestNpc:getLocalVar('traded') == 0, 'precondition: the chest is still mid-respawn')
        assert(chestNpc:getLocalVar('illusionCooldown') <= GetSystemTime(), 'precondition: the chest is on its illusion cooldown')

        player.entities:moveTo('Treasure_Chest')
        player.actions:tradeNpc('Treasure_Chest', { xi.item.GUSGEN_CHEST_KEY })

        assert(#tradeSpy.calls == 1, string.format('precondition: expected one xi.treasure.onTrade call, got %d', #tradeSpy.calls))

        local reward = tradeSpy.calls[1].returned
        assert(reward == xi.item.REPLICA_MAUL, string.format('expected Replica Maul (%d) from a roll of 800, got %s', xi.item.REPLICA_MAUL, tostring(reward)))
    end)
end)
