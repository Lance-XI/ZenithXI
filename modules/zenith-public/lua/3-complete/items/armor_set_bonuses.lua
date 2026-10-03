-----------------------------------
-- Armor Set Bonuses (custom additions to vanilla gear_sets)
--
-- Vanilla LSB ALREADY implements gear set bonuses in scripts/globals/gear_sets.lua
-- (a data-driven, level-aware, tiered system applied in C++ via addGearSetMod /
-- clearGearSetMods, recomputed on every gear change). DO NOT duplicate a set that
-- already lives there -- Amir, Pahluwan, Yigit, Bowman's, Fourth Division and Skadi
-- are all vanilla. This module only adds sets the rework needs that vanilla LACKS,
-- by wrapping xi.gear_sets.checkForGearSet: super() runs vanilla first (which clears
-- and re-applies every set mod), then we layer ours on with addGearSetMod so they
-- are tracked and cleared/recomputed together with the vanilla batch.
--
-- gear_sets applies PLAYER modifiers only; pet-mod sets are not handled here.
-----------------------------------
require('modules/module_utils')

local m = Module:new('c-i_armor_set_bonus')

-- Sets missing from vanilla gear_sets.lua, plus value tweaks to vanilla sets applied
-- as a DELTA on top of vanilla (super() runs the vanilla value, we add the
-- difference).
--
-- Custom setIds MUST fit in a uint8: CLuaBaseEntity::addGearSetMod takes
-- `uint8 setId` (src/map/lua/lua_base_entity.cpp), so anything over 255 wraps
-- silently. The 900-series these used to use truncated to 133/134/135, and 133 is a
-- real vanilla set (gearSets[133] in gear_sets.lua, AF3 BLU). That is currently
-- harmless only because setId is write-only -- GearSetMod_t stores it but
-- CLuaBaseEntity::clearGearSetMods removes by modId/modValue and never reads it
-- back -- so the collision is a landmine, not a live bug. Vanilla ids run 1..133, so
-- the 200-series below is clear of them with room to spare on both sides.
local customSets =
{
    [200] = -- Carline set: CHR+15 (Carline Ribbon + Carline Earring) -- not in vanilla
    {
        items       = { xi.item.CARLINE_RIBBON, xi.item.CARLINE_EARRING },
        minEquipped = 2,
        mods        = { { xi.mod.CHR, 15 } },
    },

    [201] = -- Bowman's set: rework wants Ranged Attack +12; vanilla gear_sets[17] = +15.
    {       -- Apply the -3 delta so the net is +12 (matches min/level gating of the vanilla set).
            -- The negative rides a uint16 param and unwraps correctly to int16 on the way
            -- into addModifier; it is symmetric with clearGearSetMods, so it nets out, but
            -- do not extend this pattern without checking that round trip.
        items       = { xi.item.BOWMANS_MASK, xi.item.BOWMANS_LEDELSENS },
        minEquipped = 2,
        mods        = { { xi.mod.RATT, -3 } },
    },

    [202] = -- Caballero set: "Increases VIT" (Caballero Gauntlets + Caballero Shield)
    {       -- not in vanilla. TUNE: the CSV states no value; +5 matches the scale of
            -- comparable vanilla 2-piece stat sets.
        items       = { xi.item.CABALLERO_GAUNTLETS, xi.item.CABALLERO_SHIELD },
        minEquipped = 2,
        mods        = { { xi.mod.VIT, 5 } },
    },
}

-- Mirror vanilla checkForGearSet's counting (slot scan + level-sync guard) for the
-- custom sets, then layer their mods on via addGearSetMod.
m:addOverride('xi.gear_sets.checkForGearSet', function(player)
    super(player)

    local level = player:getMainLvl()
    for setId, setData in pairs(customSets) do
        local count = 0
        for slot = 0, xi.MAX_SLOTID do
            local equip = player:getEquippedItem(slot)
            if
                equip and
                level >= equip:getReqLvl()
            then
                for _, itemId in ipairs(setData.items) do
                    if equip:getID() == itemId then
                        count = count + 1
                    end
                end
            end
        end

        if count >= setData.minEquipped then
            for _, modData in ipairs(setData.mods) do
                player:addGearSetMod(setId, modData[1], modData[2])
            end
        end
    end
end)

-- NOTE: the Breeder set ("Pet: DEF+10 Enmity+5") is a PET-mod set, which gear_sets
-- cannot express (it applies player modifiers). It is handled in armor_head_effects.lua
-- with a small custom pet handler, alongside breeder_mask's Blaze Spikes.

return m
