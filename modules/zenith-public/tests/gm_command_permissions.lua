-- ZenithXI GM command permissions (modules/zenith-public/lua/2-base/gm_command_permissions.lua).
--
-- The module rewrites cmdprops.permission of every command already in xi.commands (LSB's
-- scripts/commands and LQS/commands) from its own table, and makes every command missing from
-- that table admin only (level 5). Deltas used here, LSB -> Zenith:
--   geteffects 1 -> 0, checkinteraction 5 -> 1, gettp / getfamily / return 1 -> 5 (not listed).
-- The end-to-end cases type the command the way a client does (0x0B5 chat starting with '!'),
-- so CCommandHandler::call does the permission check against the player's GM level.

local ffi = require('ffi')

-- ffi.cdef is global to the run and other Zenith command tests declare the same struct
if not pcall(ffi.typeof, 'ZENITH_GP_CLI_COMMAND_CHAT_STD') then
    ffi.cdef [[
        // 0x0B5 - say/shout/party chat; a message starting with '!' is a command
        typedef struct {
            uint16_t id : 9;
            uint16_t size : 7;
            uint16_t sync;
            uint8_t  Kind;
            uint8_t  unknown00;
            uint8_t  Str[128];
        } ZENITH_GP_CLI_COMMAND_CHAT_STD;
    ]]
end

describe('Zenith GM command permissions', function()
    ---@type CClientEntityPair
    local player

    -- Text of every 0x017 chat line (printToPlayer) the server sent since the last clear
    local function chatLines(who)
        local lines = {}
        for _, pkt in ipairs(who.packets:getIncoming()) do
            if pkt.type == 0x017 then
                local chars = {}
                for i = 23, pkt.size - 1 do
                    local byte = pkt.data[i]
                    if byte == nil or byte == 0 then
                        break
                    end

                    table.insert(chars, string.char(byte))
                end

                table.insert(lines, table.concat(chars))
            end
        end

        return lines
    end

    -- Type a chat line as the client would, and return what came back to the player
    local function say(who, text)
        who.packets:clear()

        local packet = ffi.new('ZENITH_GP_CLI_COMMAND_CHAT_STD')
        packet.Kind  = 0 -- say
        ffi.copy(packet.Str, text)
        who.packets:send(0x0B5, packet, ffi.sizeof(packet))

        return chatLines(who)
    end

    local function hasLine(lines, wanted)
        for _, line in ipairs(lines) do
            if line == wanted then
                return true
            end
        end

        return false
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE })
    end)

    -- What the module's table says, compared with LSB's own cmdprops for the same command
    local expectedLevels =
    {
        { name = 'geteffects',       level = 0, lsb = 1 },
        { name = 'checkinteraction', level = 1, lsb = 5 },
        { name = 'gettp',            level = 5, lsb = 1 },
        { name = 'getfamily',        level = 5, lsb = 1 },
        { name = 'return',           level = 5, lsb = 1 },
    }

    for _, row in ipairs(expectedLevels) do
        it(string.format('sets !%s to GM level %d (LSB: %d)', row.name, row.level, row.lsb), function()
            local cmd = xi.commands[row.name]
            assert(cmd and cmd.cmdprops, string.format('precondition: !%s is not a loaded command', row.name))

            local actual = cmd.cmdprops.permission
            assert(actual == row.level, string.format('!%s permission: expected %d, got %s', row.name, row.level, tostring(actual)))
        end)
    end

    it('lets a level 0 player use !geteffects', function()
        player:setGMLevel(0)
        assert(#player:getStatusEffects() == 0, 'precondition: the new player already has status effects')

        local lines = say(player, '!geteffects')
        local reply = string.format('%s has no active effects.', player:getName())
        assert(hasLine(lines, reply), string.format('a level 0 player got no !geteffects reply (lines: %s)', table.concat(lines, ' / ')))
    end)

    it('lets a level 1 GM use !checkinteraction', function()
        player:setGMLevel(1)

        local lines = say(player, '!checkinteraction')
        assert(hasLine(lines, 'No valid handler targeted or handler name given.'), string.format('a level 1 GM got no !checkinteraction reply (lines: %s)', table.concat(lines, ' / ')))
    end)

    it('keeps an unlisted command (!gettp) from a level 4 GM', function()
        player:setGMLevel(4)
        local lines = say(player, '!gettp')
        assert(not hasLine(lines, 'Player TP: 0'), 'a level 4 GM ran !gettp, which the module leaves admin only')

        -- the same command does answer at level 5, so the silence above is the permission check
        player:setGMLevel(5)
        lines = say(player, '!gettp')
        assert(hasLine(lines, 'Player TP: 0'), string.format('precondition: !gettp did not answer a level 5 GM (lines: %s)', table.concat(lines, ' / ')))
    end)
end)
