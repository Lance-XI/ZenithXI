-- ZenithXI era guild shops (modules/zenith-public/lua/3-complete/eraGuildShops.lua).
--
-- The module edits xi.data.guildShops when it loads: it adds era stock lines, changes opening
-- stock, re-times shops and registers the craft guilds' General Vendors as sharedStock aliases
-- of their partner merchant. Checked through the guild shop packets of real merchants:
--   Kamilah (Mhaura): copper ore added (initial 120, targetStock 110, so 110 at open); base has none.
--   Yabby Tanmikey (Mhaura): silver ore opens at 70 (base 90), Red Rock at 2 (base 4).
--   Mololo (Mhaura): an alias of Kamilah's pool; base has no guild shop entry for Mololo.
--   Beugungel (Carpenters' Landing): closes at 21 (base 22).
-- Every case drops the shop's in-memory state first, so it opens from the configured initial stock.

describe('Zenith era guild shops', function()
    ---@type CClientEntityPair
    local player

    -- Forget a shop's rolled day, so its next open starts from cfg.initial
    local function resetShop(name)
        xi.guildShops.state[name] = nil
    end

    -- Windsday is no holiday for any shop used here
    local function openShop(npcName, hour)
        resetShop(npcName)
        xi.test.world:setVanaDay(xi.day.WINDSDAY)
        xi.test.world:setVanaTime(hour or 8, 0)
        player.entities:gotoAndTrigger(npcName)
    end

    -- Buy through the client packet and decode the 0x082 reply
    local function buy(itemId, quantity)
        player.packets:clear()
        player.actions:guildBuy(itemId, quantity)
        for _, pkt in pairs(player.packets:getIncoming()) do
            if pkt.type == 0x082 then
                return { itemNo = pkt.data[4] + pkt.data[5] * 256, trade = pkt.data[7] }
            end
        end
    end

    describe('in Mhaura', function()
        before_each(function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.MHAURA })
        end)

        it('Kamilah sells copper ore, opening at its target stock of 110', function()
            openShop('Kamilah')

            local entry = player.actions:guildBuyList()[xi.item.CHUNK_OF_COPPER_ORE]

            assert(entry ~= nil, 'Kamilah does not offer copper ore: the era stock line was not added')
            assert(entry.count == 110, string.format('expected 110 copper ore at open, got %d', entry.count))
        end)

        it('Yabby Tanmikey opens with 70 silver ore and 2 Red Rocks', function()
            openShop('Yabby_Tanmikey')

            local list   = player.actions:guildBuyList()
            local silver = list[xi.item.CHUNK_OF_SILVER_ORE]
            local rock   = list[xi.item.RED_ROCK]

            assert(silver ~= nil and rock ~= nil, 'precondition: Yabby Tanmikey offers silver ore and Red Rock')
            assert(silver.count == 70, string.format('expected 70 silver ore at open (base 90), got %d', silver.count))
            assert(rock.count == 2, string.format('expected 2 Red Rocks at open (base 4), got %d', rock.count))
        end)

        it('Mololo resolves to Kamilah\'s stock pool', function()
            resetShop('Kamilah')
            xi.test.world:setVanaDay(xi.day.WINDSDAY)
            xi.test.world:setVanaTime(8, 0)

            -- Base canonicalShop, not the NPC script, so this holds with c_guildVendorShops off too
            local mololo = player.entities:get('Mololo')
            local list   = xi.guildShops.onBuyList(GetPlayerByID(player:getID()), GetNPCByID(mololo:getID()))

            local copper = nil
            for _, entry in ipairs(list) do
                if entry.id == xi.item.CHUNK_OF_COPPER_ORE then
                    copper = entry
                end
            end

            assert(#list > 0, 'Mololo has no guild shop stock: the sharedStock alias onto Kamilah is missing')
            assert(copper ~= nil and copper.count == 110, 'Mololo does not list Kamilah\'s 110 copper ore')
        end)
    end)

    describe('in Carpenters\' Landing', function()
        before_each(function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.CARPENTERS_LANDING })
            player:setGil(1000000)
        end)

        it('Beugungel stops selling at 21:00', function()
            openShop('Beugungel', 20)

            local open = buy(xi.item.ASH_LOG, 1)
            assert(open ~= nil and open.trade == 1, 'precondition: Beugungel sells an Ash Log at 20:00')

            -- Guild buys are rate limited, so let a little time pass before the second one
            xi.test.world:skipTime(2)
            xi.test.world:setVanaTime(21, 0)
            local closed = buy(xi.item.ASH_LOG, 1)

            assert(closed == nil or closed.trade ~= 1, 'Beugungel sold an Ash Log at 21:00: the era close hour is not applied')
            assert(player:getItemCount(xi.item.ASH_LOG) == 1, string.format('expected 1 Ash Log, got %d', player:getItemCount(xi.item.ASH_LOG)))
        end)
    end)
end)
