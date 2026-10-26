-- ZenithXI Mog Pell rewards (modules/zenith-public/lua/3-complete/mogPellRewards.lua).
--
-- Trading a Green, Red, Marble, Rainbow or Silver Mog Pell to a Festive Moogle opens a paged
-- custom menu (four rewards a page) of Zenith's reward list instead of base's reward event, and
-- the pell is only used up once a reward is handed over. Rare rewards the player already owns
-- and the level-50 ciphers are refused. Gold and Ochre pells are ignored: no event, no menu.
-- Festive Moogle in Port Bastok. Green pell: 37 rewards, 10 pages, Goblin Suit first (Rare).
-- Red pell: Cipher of a Moogle's Alter Ego is reward 20, so the last row of page 5, shown as
-- "Ciph. A Moogles Al.." (names are title-cased, "Cipher Of" shortened, cut to 20 characters).

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
    } ZENITH_MOG_PELL_CHAT_NAME;
]]

describe('Zenith Mog Pell rewards', function()
    ---@type CClientEntityPair
    local player

    local moogle = 'Festive_Moogle'

    -- Answer the open custom menu with one of its options, or cancel it when option is nil
    local function answerMenu(option)
        local result = option and string.format('Result (%s)', option) or 'Result (Canceled.)'
        local packet = ffi.new('ZENITH_MOG_PELL_CHAT_NAME')
        packet.unknown04 = 3 -- the server rejects tells without it
        ffi.copy(packet.sName, '_CUSTOM_MENU')
        ffi.copy(packet.Mes, 'GMTELL(_CUSTOM_MENU): Question(menu): ' .. result)
        player.packets:send(0x0B6, packet, ffi.sizeof(packet))
    end

    -- True when a packet sent since the last clear carries this text (the menu is sent as a GM prompt)
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

    -- Fails when the server started an event (0x032-0x034) since the last packet clear
    local function assertNoEvent(message)
        for _, pkt in pairs(player.packets:getIncoming()) do
            assert(pkt.type < 0x032 or pkt.type > 0x034, message)
        end
    end

    local function tradePell(pellId)
        player:addItem(pellId)
        player.packets:clear()
        player.actions:tradeNpc(moogle, { pellId })
    end

    -- Page changes reopen the menu on a 100 ms timer
    local function nextPage()
        player.packets:clear()
        answerMenu('[Next Page]')
        xi.test.world:skipTime(1)
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.PORT_BASTOK })
    end)

    it('opens the Zenith reward menu for a Green Mog Pell instead of the reward event', function()
        tradePell(xi.item.GREEN_MOG_PELL)

        assertNoEvent('trading a Green Mog Pell started the base reward event')
        assert(sawText('"Green Mog Pell (Page 1/10)"'), 'no Green Mog Pell reward menu (page 1 of 10) was sent')

        answerMenu(nil)
        assert(player:getItemCount(xi.item.GREEN_MOG_PELL) == 1, 'cancelling the menu used up the pell')
    end)

    it('hands over the chosen reward and uses up the pell', function()
        tradePell(xi.item.GREEN_MOG_PELL)
        answerMenu('Goblin Suit')

        assert(player:hasItem(xi.item.GOBLIN_SUIT), 'choosing Goblin Suit from the menu did not grant it')
        assert(player:getItemCount(xi.item.GREEN_MOG_PELL) == 0, 'the pell was not used up after the reward was granted')
    end)

    it('refuses a Rare reward the player already owns and keeps the pell', function()
        player:addItem(xi.item.GOBLIN_SUIT)
        tradePell(xi.item.GREEN_MOG_PELL)
        assert(sawText('"Green Mog Pell (Page 1/10)"'), 'no Green Mog Pell reward menu was sent')

        answerMenu('Goblin Suit')

        assert(player:getItemCount(xi.item.GOBLIN_SUIT) == 1, string.format('expected one Goblin Suit, got %d', player:getItemCount(xi.item.GOBLIN_SUIT)))
        assert(player:getItemCount(xi.item.GREEN_MOG_PELL) == 1, 'the pell was used up although nothing was granted')
    end)

    it('gives the alter ego ciphers only from level 50', function()
        local cipher     = xi.item.CIPHER_OF_A_MOOGLES_ALTER_EGO
        local cipherName = 'Ciph. A Moogles Al..'

        local function openCipherPage()
            tradePell(xi.item.RED_MOG_PELL)
            for _ = 1, 4 do
                nextPage()
            end

            assert(sawText('"Red Mog Pell (Page 5/7)"'), 'the Red Mog Pell reward menu did not reach page 5 of 7')
        end

        player:setLevel(49)
        openCipherPage()
        answerMenu(cipherName)
        assert(not player:hasItem(cipher), 'a level 49 player received the Cipher of a Moogle\'s Alter Ego')
        assert(player:getItemCount(xi.item.RED_MOG_PELL) == 1, 'the pell was used up although nothing was granted')

        player:setLevel(50)
        player:delItem(xi.item.RED_MOG_PELL, 1)
        openCipherPage()
        answerMenu(cipherName)
        assert(player:hasItem(cipher), 'a level 50 player did not receive the Cipher of a Moogle\'s Alter Ego')
    end)

    it('ignores a Gold Mog Pell', function()
        tradePell(xi.item.GOLD_MOG_PELL)

        assertNoEvent('trading a Gold Mog Pell started the base reward event')
        assert(not sawText('Mog Pell (Page'), 'a reward menu opened for a Gold Mog Pell')
        assert(player:getItemCount(xi.item.GOLD_MOG_PELL) == 1, 'the Gold Mog Pell was taken')
    end)
end)
