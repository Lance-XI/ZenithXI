-----------------------------------
-- BCNM/KSNM Loot Override Module
--
-- This module allows server administrators to override loot tables for
-- BSNM (Burning Circle Seal Notorious Monster) and KSNM (Kindred Seal
-- Notorious Monster) battlefields without modifying core scripts.
--
-- =========================================================================
-- HOW TO USE THIS MODULE
-- =========================================================================
--
-- 1. Find the battlefield ID you want to modify in scripts/globals/battlefield.lua
--    Example: xi.battlefield.id.CHARMING_TRIO, xi.battlefield.id.DOUBLE_DRAGONIAN
--
-- 2. To change only a few drop rates, add an entry to the lootAdjustments table below
--    (see its comments). It edits LSB's own table, so later LSB loot changes still apply.
--    To replace a battlefield's whole table, add an entry to lootOverrides instead,
--    using the battlefield ID as the key.
--
-- 3. Define a full replacement table using the format described below
--
-- 4. Restart the server for changes to take effect
--
-- =========================================================================
-- LOOT TABLE FORMAT
-- =========================================================================
--
-- Each battlefield's loot is defined as an array of "loot groups".
-- When a player wins and opens the Armoury Crate, ONE item is selected
-- from EACH loot group based on weighted random selection.
--
-- BASIC STRUCTURE:
-- {
--     { group1 },  -- One item selected from this group
--     { group2 },  -- One item selected from this group
--     { group3 },  -- etc.
-- }
--
-- LOOT GROUP OPTIONS:
--
-- 1. Single guaranteed item:
--    { { itemId = xi.item.ITEM_NAME, weight = 1000 } }
--
-- 2. Multiple items with different drop rates (weights are relative):
--    {
--        { itemId = xi.item.COMMON_ITEM, weight = 700 },   -- 70% chance
--        { itemId = xi.item.UNCOMMON_ITEM, weight = 200 }, -- 20% chance
--        { itemId = xi.item.RARE_ITEM, weight = 100 },     -- 10% chance
--    }
--
-- 3. Chance of dropping nothing (use xi.item.NONE):
--    {
--        { itemId = xi.item.NONE, weight = 800 },      -- 80% nothing
--        { itemId = xi.item.RARE_DROP, weight = 200 }, -- 20% rare item
--    }
--
-- 4. Multiple items from same pool (use quantity field):
--    {
--        quantity = 2,  -- Select 2 items from this group
--        { itemId = xi.item.ITEM_A, weight = 100 },
--        { itemId = xi.item.ITEM_B, weight = 100 },
--        { itemId = xi.item.ITEM_C, weight = 100 },
--    }
--
-- 5. Gil reward (use amount field):
--    { { itemId = xi.item.GIL, weight = 1000, amount = 5000 } }
--    Note: Gil is split evenly among all party members.
--
-- WEIGHT SYSTEM:
-- - Higher weight = higher chance to drop
-- - The probability is: item_weight / total_group_weight
-- - Use xi.loot.weight constants for consistency:
--   xi.loot.weight.EXTREMELY_LOW  = 2
--   xi.loot.weight.VERY_LOW       = 10
--   xi.loot.weight.LOW            = 30
--   xi.loot.weight.NORMAL         = 50
--   xi.loot.weight.HIGH           = 70
--   xi.loot.weight.VERY_HIGH      = 100
--   xi.loot.weight.EXTREMELY_HIGH = 140
--
-- =========================================================================
-- EXAMPLE CONFIGURATIONS (Commented Out)
-- =========================================================================
--
-- Example 1: Override Charming Trio (BCNM20) to give guaranteed Mannequin Head
-- [xi.battlefield.id.CHARMING_TRIO] =
-- {
--     -- Group 1: Gil reward
--     {
--         { itemId = xi.item.GIL, weight = 1000, amount = 3000 },
--     },
--
--     -- Group 2: Choose 2 platoon weapons
--     {
--         quantity = 2,
--         { itemId = xi.item.PLATOON_EDGE, weight = xi.loot.weight.NORMAL },
--         { itemId = xi.item.PLATOON_SPATHA, weight = xi.loot.weight.NORMAL },
--         { itemId = xi.item.PLATOON_DISC, weight = xi.loot.weight.NORMAL },
--         { itemId = xi.item.PLATOON_CUTTER, weight = xi.loot.weight.NORMAL },
--     },
--
--     -- Group 3: Guaranteed Mannequin Head (normally 5% chance)
--     {
--         { itemId = xi.item.MANNEQUIN_HEAD, weight = 1000 },
--     },
-- },
--
-- Example 2: Override Double Dragonian (KSNM) with custom drops
-- [xi.battlefield.id.DOUBLE_DRAGONIAN] =
-- {
--     -- Group 1: Gil
--     {
--         { itemId = xi.item.GIL, weight = 1000, amount = 20000 },
--     },
--
--     -- Group 2: Rare weapon pool
--     {
--         { itemId = xi.item.NONE, weight = 500 },                    -- 50% nothing
--         { itemId = xi.item.SPEED_BELT, weight = 100 },              -- 10% Speed Belt
--         { itemId = xi.item.PEACOCK_CHARM, weight = 50 },            -- 5% Peacock Charm
--         { itemId = xi.item.SNIPERS_RING, weight = xi.loot.weight.VERY_HIGH },
--     },
--
--     -- Group 3: Crafting materials
--     {
--         quantity = 3,
--         { itemId = xi.item.WYVERN_SKIN, weight = xi.loot.weight.HIGH },
--         { itemId = xi.item.DRAGON_HEART, weight = xi.loot.weight.LOW },
--         { itemId = xi.item.DRAGON_BLOOD, weight = xi.loot.weight.NORMAL },
--     },
-- },
--
-- Example 3: Override Divine Punishers (BCNM60) with boosted rare drop rates
-- [xi.battlefield.id.DIVINE_PUNISHERS] =
-- {
--     -- Group 1: Gil
--     {
--         { itemId = xi.item.GIL, weight = 1000, amount = 10000 },
--     },
--
--     -- Group 2: Weapon drops with improved rates
--     {
--         { itemId = xi.item.NONE, weight = 200 },
--         { itemId = xi.item.BALANCE_BUCKLER, weight = xi.loot.weight.NORMAL },
--         { itemId = xi.item.FENCING_DEGEN, weight = xi.loot.weight.NORMAL },
--         { itemId = xi.item.RAIFU, weight = xi.loot.weight.NORMAL },
--         { itemId = xi.item.PALMERIN_SHIELD, weight = xi.loot.weight.NORMAL },
--         { itemId = xi.item.KOSETSUSAMONJI, weight = xi.loot.weight.LOW },
--     },
--
--     -- Group 3: Accessory pool
--     {
--         { itemId = xi.item.NONE, weight = 850 },
--         { itemId = xi.item.ASSAULT_EARRING, weight = xi.loot.weight.NORMAL },
--         { itemId = xi.item.ASSAULT_EARRING, weight = xi.loot.weight.VERY_HIGH },
--     },
-- },
--
-----------------------------------

require('modules/module_utils')

local m = Module:new('b_bcnm_loot_overrides')

-----------------------------------
-- LOOT ADJUSTMENTS (targeted edits to LSB's table)
-----------------------------------
-- Lowers the drop rate of single items inside LSB's current loot table and gives the
-- weight taken away to other items in the same group. Everything else in LSB's table
-- (new items, removed items, re-weighting) still reaches the crate.
--
--   group  = an item only the target loot group holds, used to find that group
--   itemId = the item whose drop rate changes
--   share  = its new share of the group (0.25 = 25%); a rate is only ever lowered
--   giveTo = items in the same group that split the weight taken away
--
-- The group's total weight does not change. An adjustment whose group or items are no
-- longer in LSB's table is skipped with a warning at server start.
-----------------------------------

local lootAdjustments =
{
    -----------------------------------
    -- Under Observation (BCNM40, Horlais Peak)
    -- Utsusemi: Ni 20% -> 10% (scroll group), Erase and Phalanx 20% -> 10% each,
    -- Tilt Belt and Mantra Belt 40% -> 25% each. The weight taken away goes to junk.
    -- LSB's mixed (Mantra Belt) group no longer holds Utsusemi: Ni, so there is nothing to cut there.
    -----------------------------------
    [xi.battlefield.id.UNDER_OBSERVATION] =
    {
        {
            group  = xi.item.TILT_BELT,
            itemId = xi.item.TILT_BELT,
            share  = 0.25,
            giveTo = { xi.item.MYTHRIL_BEASTCOIN, xi.item.OAK_LOG },
        },
        {
            group  = xi.item.MANTRA_BELT,
            itemId = xi.item.MANTRA_BELT,
            share  = 0.25,
            giveTo = { xi.item.MYTHRIL_BEASTCOIN, xi.item.OAK_LOG },
        },
        {
            group  = xi.item.SCROLL_OF_ICE_SPIKES,
            itemId = xi.item.SCROLL_OF_UTSUSEMI_NI,
            share  = 0.10,
            giveTo = { xi.item.GOLD_BEASTCOIN },
        },
        {
            group  = xi.item.FIRE_SPIRIT_PACT,
            itemId = xi.item.SCROLL_OF_ERASE,
            share  = 0.10,
            giveTo = { xi.item.SCROLL_OF_ABSORB_STR },
        },
        {
            group  = xi.item.FIRE_SPIRIT_PACT,
            itemId = xi.item.SCROLL_OF_PHALANX,
            share  = 0.10,
            giveTo = { xi.item.SCROLL_OF_ABSORB_STR },
        },
    },
}

-----------------------------------
-- LOOT OVERRIDE CONFIGURATION (full replacements)
-----------------------------------
-- Use the battlefield ID as the key and a complete loot table as the value.
-- A full table does not follow later LSB loot changes, so prefer lootAdjustments.
-- See examples in the header comments for guidance.
-----------------------------------

local lootOverrides =
{
}

-----------------------------------
-- HELPERS
-----------------------------------

-- The entry for itemId in a loot group, or nil
local function findEntry(group, itemId)
    for _, entry in ipairs(group) do
        if entry.itemId == itemId then
            return entry
        end
    end

    return nil
end

-- The first loot group holding itemId, or nil
local function findGroup(lootTable, itemId)
    for _, group in ipairs(lootTable) do
        if findEntry(group, itemId) then
            return group
        end
    end

    return nil
end

local function applyAdjustment(battlefieldId, lootTable, adjustment)
    local group = findGroup(lootTable, adjustment.group)
    local entry = group and findEntry(group, adjustment.itemId)
    if not entry then
        printf('[bcnm_loot_overrides] Warning: battlefield %d has no item %d in the group holding item %d, skipping.', battlefieldId, adjustment.itemId, adjustment.group)
        return
    end

    local receivers = {}
    for _, itemId in ipairs(adjustment.giveTo) do
        local receiver = findEntry(group, itemId)
        if not receiver then
            printf('[bcnm_loot_overrides] Warning: battlefield %d has no item %d next to item %d, skipping.', battlefieldId, itemId, adjustment.itemId)
            return
        end

        table.insert(receivers, receiver)
    end

    local total = 0
    for _, groupEntry in ipairs(group) do
        total = total + groupEntry.weight
    end

    local newWeight = math.floor(total * adjustment.share + 0.5)
    local freed     = entry.weight - newWeight
    if freed <= 0 then
        return
    end

    -- Split the freed weight evenly; the first receiver takes any remainder
    entry.weight = newWeight
    for i, receiver in ipairs(receivers) do
        local portion = math.floor(freed / #receivers)
        if i == 1 then
            portion = portion + freed % #receivers
        end

        receiver.weight = receiver.weight + portion
    end
end

-----------------------------------
-- MODULE INITIALIZATION
-----------------------------------

-- Apply loot changes after server initialization when all battlefields are loaded
m:addOverride('xi.server.onServerStart', function()
    super()

    local overrideCount = 0
    for battlefieldId, lootTable in pairs(lootOverrides) do
        local battlefield = xi.battlefield.contents[battlefieldId]
        if battlefield then
            battlefield.loot = lootTable
            overrideCount = overrideCount + 1
        else
            printf('[bcnm_loot_overrides] Warning: Battlefield ID %d not found, skipping loot override.', battlefieldId)
        end
    end

    -- Adjustments edit LSB's table in place. Running them again changes nothing, as each
    -- item is already at its share and the group total is unchanged.
    for battlefieldId, adjustments in pairs(lootAdjustments) do
        local battlefield = xi.battlefield.contents[battlefieldId]
        if battlefield then
            for _, adjustment in ipairs(adjustments) do
                applyAdjustment(battlefieldId, battlefield.loot, adjustment)
            end

            overrideCount = overrideCount + 1
        else
            printf('[bcnm_loot_overrides] Warning: Battlefield ID %d not found, skipping loot adjustments.', battlefieldId)
        end
    end

    if overrideCount > 0 then
        printf('[bcnm_loot_overrides] Applied %d battlefield loot override(s).', overrideCount)
    end
end)

return m
