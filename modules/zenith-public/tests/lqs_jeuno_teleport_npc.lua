-- ZenithXI Jeuno Outpost Warper (modules/zenith-public/lua/4-additive/npc/jeuno/[LQS]jeunoTeleportNpc.lua).
--
-- An LQS NPC in Lower Jeuno (dynamic entity "DE_Outpost Warper"; LSB has no such NPC) warps to
-- unlocked outposts for the standard fee (Ronfaure: 100 gil or 10 CP) and applies Signet first,
-- lasting (rank + nation's conquest rank + 3) hours. The destination menu and the payment menu
-- are custom menus, answered with the 0x0B6 tell the client sends.

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
    } ZENITH_OUTPOST_WARPER_MENU_REPLY;
]]

describe('Zenith Jeuno Outpost Warper', function()
    ---@type CClientEntityPair
    local player

    local npcName = 'DE_Outpost Warper'
    local rank    = 5

    local function answerMenu(choice)
        local packet = ffi.new('ZENITH_OUTPOST_WARPER_MENU_REPLY')
        packet.unknown04 = 3 -- the server rejects tells without it
        ffi.copy(packet.sName, '_CUSTOM_MENU')
        ffi.copy(packet.Mes, string.format('GMTELL(_CUSTOM_MENU): Question(menu): Result (%s)', choice))
        player.packets:send(0x0B6, packet, ffi.sizeof(packet))
        xi.test.world:tick() -- one zone tick: the menu answer, not yet the 1.25 s teleport timer
    end

    -- Signet as the module sets it: LQS.signetEffect() duration, in seconds
    local function expectedSignetSeconds()
        return (rank + GetNationRank(xi.nation.SANDORIA) + 3) * 3600
    end

    local function assertSignet()
        local signet = player:getStatusEffect(xi.effect.SIGNET)
        assert(signet ~= nil, 'Signet was not applied before the warp')

        local expectedMs = expectedSignetSeconds() * 1000
        local actualMs   = signet:getDuration()
        assert(math.abs(actualMs - expectedMs) <= 5000, string.format('expected a %d ms Signet, got %d ms', expectedMs, actualMs))
    end

    -- Open the warper and pick Ronfaure from the destination menu
    local function pickRonfaure()
        player.entities:gotoAndTrigger(npcName)
        xi.test.world:tick()
        answerMenu('Ronfaure')
        xi.test.world:tick() -- the payment menu opens on a 100 ms timer
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.LOWER_JEUNO, level = 75 })
        player.events:expectNotInEvent()

        local found = GetZone(xi.zone.LOWER_JEUNO):queryEntitiesByName(npcName)
        assert(found ~= nil and #found > 0, 'the Outpost Warper (DE_Outpost Warper) is not in Lower Jeuno: the LQS warper module did not load')

        player:setNation(xi.nation.SANDORIA)
        player:setRank(rank)
        player:addTeleport(xi.teleport.type.OUTPOST_SANDORIA, xi.region.RONFAURE + 5)
        assert(player:hasTeleport(xi.teleport.type.OUTPOST_SANDORIA, xi.region.RONFAURE + 5), 'precondition: Ronfaure outpost unlocked')
        assert(not player:hasStatusEffect(xi.effect.SIGNET), 'precondition: no Signet yet')
    end)

    it('charges 100 gil for Ronfaure, applies Signet and warps to the outpost', function()
        player:setGil(1000)

        pickRonfaure()
        answerMenu('Pay 100 Gil')

        assert(player:getGil() == 900, string.format('expected 100 gil to be taken, %d left of 1000', player:getGil()))
        assertSignet()

        -- After the 1.25 s animation delay the outpost warp effect carries the region
        xi.test.world:skipTime(1)
        local teleport = player:getStatusEffect(xi.effect.TELEPORT)
        assert(teleport ~= nil, 'no outpost warp started after paying')
        assert(teleport:getPower() == xi.teleport.id.OUTPOST, string.format('expected warp type %d, got %d', xi.teleport.id.OUTPOST, teleport:getPower()))
        assert(teleport:getSubPower() == xi.region.RONFAURE, string.format('expected region %d, got %d', xi.region.RONFAURE, teleport:getSubPower()))
    end)

    it('charges 10 conquest points for Ronfaure and applies Signet', function()
        player:setGil(1000)
        player:addCP(1000)
        local cpBefore = player:getCP()
        assert(cpBefore >= 10, string.format('precondition: at least 10 CP, have %d', cpBefore))

        pickRonfaure()
        answerMenu('Pay 10 CP')

        assert(cpBefore - player:getCP() == 10, string.format('expected 10 CP to be taken, took %d', cpBefore - player:getCP()))
        assert(player:getGil() == 1000, string.format('gil changed on a CP payment: %d', player:getGil()))
        assertSignet()
    end)
end)
