-- ZenithXI guild vendor shops (modules/zenith-public/lua/3-complete/guildVendorShops.lua).
--
-- The craft guilds' General Vendors open their partner merchant's era guild shop instead of
-- base's static xi.shop.generalGuild list, and Akamafula/Amalasanda (Lower Jeuno) open a guild
-- shop of their own instead of a plain shop, still behind the Tenshodo Member's Card.
-- The stock pools and aliases come from c_eraGuildShops, so this test needs that module too:
--   Mololo -> Kamilah, Celestina -> Yabby Tanmikey (Mhaura), Akamafula -> its own pool.

describe('Zenith guild vendor shops', function()
    ---@type CClientEntityPair
    local player

    -- Mhaura has two Celestina entities; this is the Goldsmiths' Guild vendor
    local celestinaId = 17797132

    local function resetShop(name)
        xi.guildShops.state[name] = nil
    end

    local function setOpenHours()
        -- Windsday is no holiday for Kamilah, Yabby Tanmikey or Akamafula, and 08:00 is inside all their hours
        xi.test.world:setVanaDay(xi.day.WINDSDAY)
        xi.test.world:setVanaTime(8, 0)
    end

    describe('in Mhaura', function()
        before_each(function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.MHAURA })
            player:setGil(1000000)
            resetShop('Kamilah')
            resetShop('Yabby_Tanmikey')
            setOpenHours()
        end)

        it('Mololo opens Kamilah\'s guild shop and sells from the same stock', function()
            local item = xi.item.CHUNK_OF_TIN_ORE

            player.entities:gotoAndTrigger('Mololo')
            local entry = player.actions:guildBuyList()[item]
            assert(entry ~= nil, 'Mololo did not open a guild shop with tin ore: the era guild shop override is not applied')

            player.actions:guildBuy(item, 1)
            assert(player:getItemCount(item) == 1, 'precondition: the tin ore bought from Mololo was granted')

            player.entities:gotoAndTrigger('Kamilah')
            local kamilah = player.actions:guildBuyList()[item]

            assert(kamilah ~= nil and kamilah.count == entry.count - 1,
                string.format('Kamilah did not lose the ore sold by Mololo: Mololo listed %d, Kamilah lists %s',
                entry.count, kamilah and tostring(kamilah.count) or 'nothing'))
        end)

        it('Celestina opens Yabby Tanmikey\'s guild shop', function()
            local base = spy('xi.shop.generalGuild')

            player.entities:gotoAndTrigger(celestinaId)
            local entry = player.actions:guildBuyList()[xi.item.CHUNK_OF_SILVER_ORE]

            assert(#base.calls == 0, 'Celestina opened base\'s static General Vendor shop')
            assert(entry ~= nil, 'Celestina did not open a guild shop offering Yabby Tanmikey\'s silver ore')
        end)
    end)

    describe('in Lower Jeuno', function()
        before_each(function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.LOWER_JEUNO })
            resetShop('Akamafula')
            setOpenHours()
        end)

        it('Akamafula opens a guild shop only for Tenshodo members', function()
            local guild = spy('xi.guildShops.onTrigger')

            -- Without the card nothing opens, as in base (a control, true either way)
            player.entities:gotoAndTrigger('Akamafula')
            assert(#guild.calls == 0, 'Akamafula opened a guild shop without the Tenshodo Member\'s Card')

            player:addKeyItem(xi.keyItem.TENSHODO_MEMBERS_CARD)
            player.entities:gotoAndTrigger('Akamafula')
            local entry = player.actions:guildBuyList()[xi.item.KUNAI]

            assert(#guild.calls == 1, string.format('expected Akamafula to open her guild shop once, got %d', #guild.calls))
            assert(entry ~= nil, 'Akamafula\'s guild shop does not offer Kunai')
        end)
    end)
end)
