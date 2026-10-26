-- ZenithXI item enum additions (modules/zenith-public/lua/1-enum/xi/item.lua).
--
-- Adds xi.item names that LSB's scripts/enum/item.lua does not define, for the vendor, Mog Pell,
-- HELM, casket and armor set modules. Each one must name the item it says in the item database.
-- HANDFUL_OF_STEEL_SCALES, RAPTOR_GLOVES and CHOCOBO_CHAIR are also in LSB's enum with the same
-- IDs, so they are not checked here. The last case checks a consumer sees the additions:
-- c_mogPellRewards lists Poroggo Cassock on page 2 of the Silver Mog Pell menu (reward 6 of 20).

local ffi = require('ffi')

-- ffi.cdef is global to the whole run, so this struct has a name no other test uses
ffi.cdef [[
    // 0x0B6 - tell, which is also how the client answers a custom menu (recipient _CUSTOM_MENU)
    typedef struct {
        uint16_t id : 9;
        uint16_t size : 7;
        uint16_t sync;
        uint8_t  unknown04;
        uint8_t  unknown05;
        uint8_t  sName[15];
        uint8_t  Mes[128];
    } ZENITH_ITEM_ENUM_CHAT_NAME;
]]

describe('Zenith item enum additions', function()
    -- enum name, item ID, item_basic name
    local additions =
    {
        { 'COEURL_WHISKER',           927,   'coeurl_whisker'                 },
        { 'LEATHER_POUCH',            1655,  'leather_pouch'                  },
        { 'TIGER_COD',                4483,  'tiger_cod'                      },
        { 'ADOULINIAN_TOMATOES',      3718,  'handful_of_adoulinian_tomatoes' },
        { 'CRIMSON_CHEST',            3732,  'crimson_chest'                  },
        { 'MANDRAGORA_POT',           3744,  'mandragora_pot'                 },
        { 'POROGGO_CASSOCK',          23803, 'poroggo_cassock'                },
        { 'KNIT_CAP',                 23810, 'knit_cap'                       },
        { 'SCARLET_STONE',            1649,  'scarlet_stone'                  },
        { 'RAFFLESIA_VINE',           2513,  'rafflesia_vine'                 },
        { 'GNAT_WING',                2522,  'gnat_wing'                      },
        { 'HEAD_OF_GRAUBERG_LETTUCE', 5688,  'head_of_grauberg_lettuce'       },
        { 'CARLINE_RIBBON',           16127, 'carline_ribbon'                 },
        { 'CARLINE_EARRING',          15995, 'carline_earring'                },
        { 'BREEDER_MASK',             16125, 'breeder_mask'                   },
        { 'BREEDER_MUFFLERS',         15001, 'breeder_mufflers'               },
        { 'CABALLERO_GAUNTLETS',      15000, 'caballero_gauntlets'            },
        { 'CABALLERO_SHIELD',         16169, 'caballero_shield'               },
    }

    for _, row in ipairs(additions) do
        local enumName, itemId, dbName = row[1], row[2], row[3]

        it(string.format('defines xi.item.%s as %s', enumName, dbName), function()
            local value = xi.item[enumName]
            assert(value == itemId, string.format('expected xi.item.%s = %d, got %s', enumName, itemId, tostring(value)))

            local item = GetItemByID(value)
            assert(item ~= nil and item:getName() == dbName,
                string.format('item %d is %s in the database, not %s', itemId, item and item:getName() or 'missing', dbName))
        end)
    end

    describe('seen by the Mog Pell rewards module', function()
        ---@type CClientEntityPair
        local player

        local function answerMenu(option)
            local result = option and string.format('Result (%s)', option) or 'Result (Canceled.)'
            local packet = ffi.new('ZENITH_ITEM_ENUM_CHAT_NAME')
            packet.unknown04 = 3 -- the server rejects tells without it
            ffi.copy(packet.sName, '_CUSTOM_MENU')
            ffi.copy(packet.Mes, 'GMTELL(_CUSTOM_MENU): Question(menu): ' .. result)
            player.packets:send(0x0B6, packet, ffi.sizeof(packet))
        end

        local function sawText(text)
            for _, pkt in pairs(player.packets:getIncoming()) do
                local bytes = {}
                for i = 0, pkt.size - 1 do
                    bytes[#bytes + 1] = string.char(pkt.data[i] or 0)
                end

                if table.concat(bytes):find(text, 1, true) then
                    return true
                end
            end

            return false
        end

        before_each(function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.PORT_BASTOK })
        end)

        it('lists Poroggo Cassock in the Silver Mog Pell rewards', function()
            player:addItem(xi.item.SILVER_MOG_PELL)
            player.packets:clear()
            player.actions:tradeNpc('Festive_Moogle', { xi.item.SILVER_MOG_PELL })
            assert(sawText('"Silver Mog Pell (Page 1/5)"'), 'precondition: the Silver Mog Pell menu opened')

            -- Page changes reopen the menu on a 100 ms timer. Page 2 cannot be built without the enum.
            player.packets:clear()
            answerMenu('[Next Page]')
            xi.test.world:skipTime(1)

            assert(sawText('"Silver Mog Pell (Page 2/5)"') and sawText('"Poroggo Cassock"'),
                'page 2 of the Silver Mog Pell menu does not list Poroggo Cassock: xi.item.POROGGO_CASSOCK is missing')

            answerMenu(nil)
        end)
    end)
end)
