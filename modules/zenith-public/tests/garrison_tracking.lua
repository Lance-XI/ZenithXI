-- ZenithXI garrison completion tracking (modules/zenith-public/lua/3-complete/garrisonTracking.lua).
--
-- LSB keeps no record of garrison wins. The module hooks xi.garrison.handleGilPayout (called on a
-- garrison victory) and sets one bit per tracked garrison zone in the char var
-- 'WardrobeGarrison_Group1' (list index 1 = bit 0), and exposes xi.garrisonTracking for
-- wardrobeUnlocks.lua (Wardrobe 4 garrison unlocks).
--
-- Setup: Valkurm Dunes is entry 9 of the 16-zone list (bit 8), West Ronfaure entry 2 (bit 1).

describe('Zenith garrison tracking', function()
    local varName      = 'WardrobeGarrison_Group1'
    local valkurmBit   = 8
    local trackedCount = 16

    ---@type CClientEntityPair
    local player

    local function payout(players)
        local entities = {}
        for _, p in ipairs(players) do
            table.insert(entities, GetPlayerByID(p:getID()))
        end

        xi.garrison.handleGilPayout(30, entities)
    end

    local function requireApi()
        assert(xi.garrisonTracking ~= nil, 'xi.garrisonTracking is missing: garrisonTracking.lua is not loaded')
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.VALKURM_DUNES, job = xi.job.WAR, level = 30 })
        player:setCharVar(varName, 0)
    end)

    it('records a Valkurm Dunes victory in its bit', function()
        payout({ player })

        local mask = player:getCharVar(varName)
        assert(utils.mask.getBit(mask, valkurmBit), string.format('victory not recorded: %s = %d, expected bit %d set', varName, mask, valkurmBit))
        assert(mask == bit.lshift(1, valkurmBit), string.format('victory set other bits: %s = %d', varName, mask))
    end)

    it('records the victory for every participant and keeps earlier wins', function()
        local other = xi.test.world:spawnPlayer({ zone = xi.zone.VALKURM_DUNES, job = xi.job.WAR, level = 30 })
        other:setCharVar(varName, bit.lshift(1, 1)) -- already won West Ronfaure

        payout({ player, other })

        local first  = player:getCharVar(varName)
        local second = other:getCharVar(varName)
        assert(first == bit.lshift(1, valkurmBit), string.format('first participant: expected %d, got %d', bit.lshift(1, valkurmBit), first))
        assert(second == bit.bor(bit.lshift(1, 1), bit.lshift(1, valkurmBit)), string.format('second participant: expected West Ronfaure + Valkurm bits, got %d', second))
    end)

    it('reports the recorded garrison through xi.garrisonTracking', function()
        requireApi()
        assert(not xi.garrisonTracking.hasCompletedGarrison(GetPlayerByID(player:getID()), xi.zone.VALKURM_DUNES), 'precondition: Valkurm Dunes not completed yet')

        payout({ player })

        local entity = GetPlayerByID(player:getID())
        assert(xi.garrisonTracking.hasCompletedGarrison(entity, xi.zone.VALKURM_DUNES), 'hasCompletedGarrison does not see the Valkurm Dunes win')
        assert(not xi.garrisonTracking.hasCompletedGarrison(entity, xi.zone.WEST_RONFAURE), 'hasCompletedGarrison reports West Ronfaure without a win there')

        local count = xi.garrisonTracking.getCompletionCount(entity)
        assert(count == 1, string.format('expected 1 completed garrison, got %d', count))
    end)

    it('reports all garrisons complete only when all 16 bits are set', function()
        requireApi()
        local entity = GetPlayerByID(player:getID())
        local full   = bit.lshift(1, trackedCount) - 1

        player:setCharVar(varName, full - 1) -- every zone but North Gustaberg (bit 0)
        assert(not xi.garrisonTracking.hasCompletedAll(entity), 'hasCompletedAll is true with one garrison missing')

        player:setCharVar(varName, full)
        assert(xi.garrisonTracking.hasCompletedAll(entity), string.format('hasCompletedAll is false with all %d bits set', trackedCount))
        local count = xi.garrisonTracking.getCompletionCount(entity)
        assert(count == trackedCount, string.format('expected %d completed garrisons, got %d', trackedCount, count))
    end)
end)
