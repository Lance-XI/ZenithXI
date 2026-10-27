-- ZenithXI garrison outpost warps (modules/zenith-public/lua/2-base/garrison_improvements.lua).
--
-- LSB's xi.garrison.handleGilPayout (called when a garrison is won) only pays gil. The module also
-- gives every participant their own nation's outpost warp for the garrison zone's region
-- (teleport type = nation, bit = region + 5, the layout LSB's conquest overseers use).
--
-- Setup: Valkurm Dunes (Zulkheim region); a fresh character holds no outpost warps.

describe('Zenith garrison outpost warps', function()
    local levelCap = 30

    ---@type CClientEntityPair
    local player

    local function zulkheimBit()
        return xi.region.ZULKHEIM + 5
    end

    local function payout(players)
        local entities = {}
        for _, p in ipairs(players) do
            table.insert(entities, GetPlayerByID(p:getID()))
        end

        xi.garrison.handleGilPayout(levelCap, entities)
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.VALKURM_DUNES, job = xi.job.WAR, level = 30 })
        assert(GetPlayerByID(player:getID()):getZone():getRegionID() == xi.region.ZULKHEIM, 'precondition: Valkurm Dunes is in Zulkheim')
        assert(not player:hasTeleport(player:getNation(), zulkheimBit()), 'precondition: no Zulkheim outpost warp yet')
    end)

    it('grants the outpost warp for the garrison zone\'s region', function()
        payout({ player })

        assert(player:hasTeleport(player:getNation(), zulkheimBit()), 'garrison victory did not grant the Zulkheim outpost warp')
    end)

    it('grants each participant the warp for their own nation', function()
        local other = xi.test.world:spawnPlayer({ zone = xi.zone.VALKURM_DUNES, job = xi.job.WAR, level = 30 })
        player:setNation(xi.nation.SANDORIA)
        other:setNation(xi.nation.BASTOK)
        assert(not player:hasTeleport(xi.nation.SANDORIA, zulkheimBit()), 'precondition: first player has no San d\'Oria Zulkheim warp')
        assert(not other:hasTeleport(xi.nation.BASTOK, zulkheimBit()), 'precondition: second player has no Bastok Zulkheim warp')

        payout({ player, other })

        assert(player:hasTeleport(xi.nation.SANDORIA, zulkheimBit()), 'San d\'Orian participant did not get the San d\'Oria Zulkheim warp')
        assert(other:hasTeleport(xi.nation.BASTOK, zulkheimBit()), 'Bastokan participant did not get the Bastok Zulkheim warp')
        assert(not other:hasTeleport(xi.nation.SANDORIA, zulkheimBit()), 'Bastokan participant got the San d\'Oria warp instead of its own')
    end)

    -- Goes in from the side LSB calls: one tick of LSB's garrison state machine in GRANT_LOOT
    -- (a won garrison) runs handleGilPayout and then moves to ENDED. This notices an override that
    -- went dead (no warp), and an override that raises: the error escapes the tick, the garrison
    -- is left in GRANT_LOOT and never ends (the QUFIMISLAND / TAVNAZIANARCH enum rename did that).
    it('grants the warp from a real garrison win and lets the garrison end', function()
        local zoneData = xi.garrison.zoneData[xi.zone.VALKURM_DUNES]
        local npc      = GetNPCByID(zones[xi.zone.VALKURM_DUNES].npc.OVERSEER_BASE)
        assert(zoneData ~= nil, 'precondition: LSB has no garrison data for Valkurm Dunes')
        assert(npc ~= nil, 'precondition: the Valkurm Dunes overseer NPC is missing')

        -- zoneData is shared by the whole run, so put back what this case changes
        local saved =
        {
            state     = zoneData.state,
            players   = zoneData.players,
            isRunning = zoneData.isRunning,
        }

        zoneData.players   = { player:getID() }
        zoneData.state     = xi.garrison.state.GRANT_LOOT
        zoneData.isRunning = false -- this tick only, no follow-up timer

        local ok, err = pcall(xi.garrison.tick, npc)
        local state   = zoneData.state

        zoneData.state     = saved.state
        zoneData.players   = saved.players
        zoneData.isRunning = saved.isRunning

        assert(ok, string.format('the garrison tick raised while granting the win: %s', tostring(err)))
        assert(state == xi.garrison.state.ENDED, string.format('garrison did not reach ENDED after granting the win: state %s', tostring(state)))
        assert(player:hasTeleport(player:getNation(), zulkheimBit()), 'a won garrison did not grant the Zulkheim outpost warp')
    end)

    -- Control: passes with and without the module. LSB's payout must still run underneath the
    -- override; if LSB renamed handleGilPayout, the loader would install the override on an empty
    -- function and this gil check is what notices.
    it('still pays the LSB garrison gil', function()
        local before = player:getGil()

        payout({ player })

        local expected = xi.settings.main.GIL_RATE * levelCap * 100
        local paid     = player:getGil() - before
        assert(paid == expected, string.format('LSB garrison gil payout changed or no longer runs: expected %d, got %d', expected, paid))
    end)
end)
