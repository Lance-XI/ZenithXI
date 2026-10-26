-- ZenithXI BCNM loot overrides (modules/zenith-public/lua/2-base/bcnm_loot_overrides.lua).
--
-- At server start the module edits LSB's own Under Observation (Horlais Peak BCNM40) crate table.
-- It is the only battlefield the module changes. LSB drops Utsusemi: Ni from the scroll group 20% of
-- the time, Erase and Phalanx 20% each, and Tilt Belt / Mantra Belt 40% each. The module cuts those
-- to 10%, 10% and 25%, and gives the weight it takes away to junk (Gold Beastcoin, Scroll of
-- Absorb-STR, Mythril Beastcoin and Oak Log). Everything else must stay exactly as LSB has it.
--
-- Weights are relative within a group (utils.selectFromLootGroups rolls 1..sum), so the cases compare
-- each item's share of its group. Groups are found by an item only they hold, not by position.
--
-- The "matches LSB" cases read LSB's table straight from the battlefield script (lsbLootTable) and
-- pass with or without the module, on purpose: they fail when the crate drifts from LSB's current
-- table (an LSB loot change the module copied over, or an item LSB added or removed).

describe('Zenith BCNM loot overrides', function()
    ---@type CClientEntityPair
    local player

    local lsbScript = 'scripts/battlefields/Horlais_Peak/under_observation.lua'

    -- What the module changes, written out independently of the module. group is an item only that
    -- loot group holds; giveTo are the items that split the weight taken away.
    local deltas =
    {
        { label = 'Tilt Belt',      group = xi.item.TILT_BELT,            itemId = xi.item.TILT_BELT,             share = 0.25, giveTo = { xi.item.MYTHRIL_BEASTCOIN, xi.item.OAK_LOG } },
        { label = 'Mantra Belt',    group = xi.item.MANTRA_BELT,          itemId = xi.item.MANTRA_BELT,           share = 0.25, giveTo = { xi.item.MYTHRIL_BEASTCOIN, xi.item.OAK_LOG } },
        { label = 'Utsusemi: Ni',   group = xi.item.SCROLL_OF_ICE_SPIKES, itemId = xi.item.SCROLL_OF_UTSUSEMI_NI, share = 0.10, giveTo = { xi.item.GOLD_BEASTCOIN } },
        { label = 'Erase',          group = xi.item.FIRE_SPIRIT_PACT,     itemId = xi.item.SCROLL_OF_ERASE,       share = 0.10, giveTo = { xi.item.SCROLL_OF_ABSORB_STR } },
        { label = 'Phalanx',        group = xi.item.FIRE_SPIRIT_PACT,     itemId = xi.item.SCROLL_OF_PHALANX,     share = 0.10, giveTo = { xi.item.SCROLL_OF_ABSORB_STR } },
    }

    -- The table the Armoury Crate rolls on
    local function lootTable()
        return xi.battlefield.contents[xi.battlefield.id.UNDER_OBSERVATION].loot
    end

    -- LSB's table, read fresh from the battlefield script with a stand-in Battlefield, so nothing is
    -- registered and the module's edits are not in it
    local function lsbLootTable()
        local chunk, err = loadfile(lsbScript)
        assert(chunk, string.format('precondition: cannot load %s (%s)', lsbScript, tostring(err)))

        -- Any method LSB calls on the content (addEssentialMobs, register, ...) does nothing
        local content = setmetatable({}, {
            __index = function()
                return function(self)
                    return self
                end
            end,
        })

        local fakeBattlefield = {}
        function fakeBattlefield.new()
            return content
        end

        setfenv(chunk, setmetatable({ Battlefield = fakeBattlefield }, { __index = _G }))
        chunk()

        local loot = rawget(content, 'loot')
        assert(type(loot) == 'table' and #loot > 0, string.format('precondition: %s set no loot table', lsbScript))

        return loot
    end

    -- The first loot group holding markerItem, and its position
    local function findGroup(loot, markerItem)
        for index, group in ipairs(loot) do
            for _, entry in ipairs(group) do
                if entry.itemId == markerItem then
                    return group, index
                end
            end
        end

        return nil, nil
    end

    local function groupTotal(group)
        local total = 0
        for _, entry in ipairs(group) do
            total = total + entry.weight
        end

        return total
    end

    -- itemId's share of its group's total weight
    local function share(group, itemId)
        local mine = 0
        for _, entry in ipairs(group) do
            if entry.itemId == itemId then
                mine = mine + entry.weight
            end
        end

        return mine / groupTotal(group)
    end

    local function assertShare(markerItem, itemId, expected, label)
        local group = findGroup(lootTable(), markerItem)
        assert(group ~= nil, string.format('precondition: no Under Observation loot group holds item %d', markerItem))

        local actual = share(group, itemId)
        assert(math.abs(actual - expected) < 0.0001, string.format('%s: expected %.2f%% of its group, got %.2f%%', label, expected * 100, actual * 100))
    end

    -- The share every item of every group should have: LSB's, except the module's deltas.
    -- Returns expected[groupIndex][itemId] = share, and touched[groupIndex][itemId] = true for the
    -- items a delta changes (the cut item and the items that take its weight).
    local function expectedShares()
        local lsb      = lsbLootTable()
        local expected = {}
        local touched  = {}

        for index, group in ipairs(lsb) do
            expected[index] = {}
            touched[index]  = {}
            for _, entry in ipairs(group) do
                expected[index][entry.itemId] = share(group, entry.itemId)
            end
        end

        for _, delta in ipairs(deltas) do
            local group, index = findGroup(lsb, delta.group)
            assert(group ~= nil, string.format('precondition: LSB has no loot group holding item %d, re-check bcnm_loot_overrides (%s)', delta.group, delta.label))

            local lsbShare = expected[index][delta.itemId]
            assert(lsbShare ~= nil, string.format('precondition: LSB dropped %s from its group, re-check bcnm_loot_overrides', delta.label))

            touched[index][delta.itemId] = true
            for _, receiver in ipairs(delta.giveTo) do
                assert(expected[index][receiver] ~= nil, string.format('precondition: LSB dropped item %d from the %s group, re-check bcnm_loot_overrides', receiver, delta.label))
                touched[index][receiver] = true
            end

            if lsbShare > delta.share then
                local freed = lsbShare - delta.share

                expected[index][delta.itemId] = delta.share
                for _, receiver in ipairs(delta.giveTo) do
                    expected[index][receiver] = expected[index][receiver] + freed / #delta.giveTo
                end
            end
        end

        return expected, touched
    end

    before_each(function()
        player = xi.test.world:spawnPlayer()
    end)

    it('drops Utsusemi: Ni from the scroll group 10% of the time', function()
        assertShare(xi.item.SCROLL_OF_ICE_SPIKES, xi.item.SCROLL_OF_UTSUSEMI_NI, 0.10, 'Utsusemi: Ni')
    end)

    it('drops Erase and Phalanx 10% of the time each', function()
        assertShare(xi.item.FIRE_SPIRIT_PACT, xi.item.SCROLL_OF_ERASE, 0.10, 'Erase')
        assertShare(xi.item.FIRE_SPIRIT_PACT, xi.item.SCROLL_OF_PHALANX, 0.10, 'Phalanx')
    end)

    it('drops Tilt Belt and Mantra Belt 25% of the time each', function()
        assertShare(xi.item.TILT_BELT, xi.item.TILT_BELT, 0.25, 'Tilt Belt')
        assertShare(xi.item.MANTRA_BELT, xi.item.MANTRA_BELT, 0.25, 'Mantra Belt')
    end)

    it('gives the weight it takes away to the junk items', function()
        local expected = expectedShares()

        for _, delta in ipairs(deltas) do
            local _, index = findGroup(lootTable(), delta.group)
            for _, receiver in ipairs(delta.giveTo) do
                assertShare(delta.group, receiver, expected[index][receiver], string.format('item %d (takes the %s weight)', receiver, delta.label))
            end
        end
    end)

    -- Goes through the selector the Armoury Crate uses, with every group rolling 65% of its weight.
    -- LSB's scroll group gives Utsusemi: Ni from 50% to 70%, the module's only from 50% to 60%.
    it('rolls Gold Beastcoin, not Utsusemi: Ni, 65% into the scroll group', function()
        stub('math.randomInt', function(_, max)
            return math.floor(max * 0.65)
        end)

        local selected = utils.selectFromLootGroups(GetPlayerByID(player:getID()), lootTable())

        local gotNi   = false
        local gotCoin = false
        for _, entry in ipairs(selected) do
            gotNi   = gotNi or entry.itemId == xi.item.SCROLL_OF_UTSUSEMI_NI
            gotCoin = gotCoin or entry.itemId == xi.item.GOLD_BEASTCOIN
        end

        assert(not gotNi, 'a 65% roll still landed on Utsusemi: Ni, the crate uses the LSB table')
        assert(gotCoin, 'a 65% roll in the scroll group did not give Gold Beastcoin')
    end)

    -- Matches LSB: these pass with or without the module (see the header)

    it('has the same loot groups and items as LSB', function()
        local lsb   = lsbLootTable()
        local crate = lootTable()

        assert(#crate == #lsb, string.format('LSB has %d loot groups, the crate %d; re-check bcnm_loot_overrides', #lsb, #crate))

        for index, lsbGroup in ipairs(lsb) do
            local group = crate[index]

            assert(#group == #lsbGroup, string.format('group %d: LSB has %d items, the crate %d; re-check bcnm_loot_overrides', index, #lsbGroup, #group))
            assert(group.quantity == lsbGroup.quantity, string.format('group %d: LSB rolls it %s time(s), the crate %s', index, tostring(lsbGroup.quantity or 1), tostring(group.quantity or 1)))

            for _, lsbEntry in ipairs(lsbGroup) do
                local entry = nil
                for _, crateEntry in ipairs(group) do
                    if crateEntry.itemId == lsbEntry.itemId then
                        entry = crateEntry
                    end
                end

                assert(entry ~= nil, string.format('group %d: LSB has item %d, the crate does not; re-check bcnm_loot_overrides', index, lsbEntry.itemId))
                assert(entry.amount == lsbEntry.amount, string.format('group %d item %d: LSB amount %s, crate %s', index, lsbEntry.itemId, tostring(lsbEntry.amount), tostring(entry.amount)))
            end
        end
    end)

    it('keeps LSB\'s drop rate for every item it does not change', function()
        local lsb        = lsbLootTable()
        local _, touched = expectedShares()

        for index, group in ipairs(lootTable()) do
            for _, entry in ipairs(group) do
                assert(lsb[index] ~= nil, string.format('the crate has a loot group %d, LSB does not; re-check bcnm_loot_overrides', index))

                local wanted = share(lsb[index], entry.itemId)
                assert(wanted > 0, string.format('group %d: the crate has item %d, LSB does not; re-check bcnm_loot_overrides', index, entry.itemId))

                if not touched[index][entry.itemId] then
                    local actual = share(group, entry.itemId)
                    assert(math.abs(actual - wanted) < 0.0001, string.format('group %d item %d: LSB drops it %.2f%% of the time, the crate %.2f%%; re-check bcnm_loot_overrides', index, entry.itemId, wanted * 100, actual * 100))
                end
            end
        end
    end)

    it('has Himmel Stock and Rosewood Log, and no Utsusemi: Ni in the mixed group', function()
        local mixed = findGroup(lootTable(), xi.item.MANTRA_BELT)
        assert(mixed ~= nil, 'precondition: no Under Observation loot group holds Mantra Belt')

        local weapons = findGroup(lootTable(), xi.item.TILT_BELT)
        assert(weapons ~= nil, 'precondition: no Under Observation loot group holds Tilt Belt')

        assert(share(mixed, xi.item.HIMMEL_STOCK) > 0, 'the mixed group has no Himmel Stock, which LSB drops there')
        assert(share(mixed, xi.item.ROSEWOOD_LOG) > 0, 'the mixed group has no Rosewood Log, which LSB drops there')
        assert(share(weapons, xi.item.ROSEWOOD_LOG) > 0, 'the Tilt Belt group has no Rosewood Log, which LSB drops there')

        local niShare = share(mixed, xi.item.SCROLL_OF_UTSUSEMI_NI)
        assert(niShare == 0, string.format('the mixed group drops Utsusemi: Ni %.2f%% of the time; LSB has none there', niShare * 100))
    end)
end)
