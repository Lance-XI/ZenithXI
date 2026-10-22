-- ZenithXI Home Point menu (modules/zenith-public/lua/3-complete/homepoint_menu.lua).
--
-- A Home Point opens a "set your home point" menu instead of base's teleport menu cutscene, and
-- does not register the Home Point as a teleport destination.

local ffi = require('ffi')

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
    } ZENITH_GP_CLI_COMMAND_CHAT_NAME;
]]

describe('Zenith Home Point menu', function()
    ---@type CClientEntityPair
    local player

    -- Answer the open custom menu the way the client does when it is closed
    local function cancelMenu()
        local packet = ffi.new('ZENITH_GP_CLI_COMMAND_CHAT_NAME')
        packet.unknown04 = 3 -- the server rejects tells without it
        ffi.copy(packet.sName, '_CUSTOM_MENU')
        ffi.copy(packet.Mes, 'GMTELL(_CUSTOM_MENU): Question(menu): Result (Canceled.)')
        player.packets:send(0x0B6, packet, ffi.sizeof(packet))
    end

    before_each(function()
        player = xi.test.world:spawnPlayer()
        player:gotoZone(xi.zone.BASTOK_MARKETS)

        -- Zoning into Bastok Markets plays event 22 first
        player.events:finish(22)
    end)

    it('opens the plain menu instead of the teleport menu', function()
        player.entities:gotoAndTrigger('HomePoint#1')

        player.events:expectNotInEvent()
        -- HomePoint#1 is Home Point index 11; base registers it on first use
        assert(not player:hasTeleport(xi.teleport.type.HOMEPOINT, 11, 0), 'the Home Point was registered as a teleport')

        -- The menu freezes the player until it is answered
        cancelMenu()
    end)
end)
