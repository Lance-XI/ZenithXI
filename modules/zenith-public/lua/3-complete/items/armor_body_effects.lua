-----------------------------------
-- Body Armor Effects (companion Lua module for the Body armor rework)
--
-- Implements the body-armor effects that CANNOT be expressed in item_mods /
-- item_latents SQL, and that DIFFER from the item's current functionality.
--
-- Source of truth: the routed-effect manifest emitted by the SQL generator,
--   modules/zenith-public/lua/3-complete/items/armor_body_effects.manifest.json
-- Every manifest item was audited against its existing scripts/items/<name>.lua
-- and DB rows before any code was written here; only genuine deltas are coded.
-- Intentionally NOT implemented because vanilla already covers them:
--   * 12 enchantments (Mana Tunic, Healing Harness/Vest/Justaucorps, High Mana
--     Cloak, Mist Tunic, Hydra Doublet/Harness, Regen Cuirass, ...) - each has a
--     scripts/items/<name>.lua doing exactly what the CSV describes.
--   * 6 "Physical damage: <X> Spikes" procs (Ogre Jerkin +/-1, War Aketon +/-1,
--     Rasetsu Samue +/-1) - already DB rows: ITEM_SUBEFFECT + ITEM_ADDEFFECT_DMG
--     + ITEM_ADDEFFECT_CHANCE, which is the gear-spikes path in battleutils.
--   * 6 set bonuses (Cobra Unit, Fourth Division, Amir, Pahluwan, Yigit) - all
--     present in vanilla scripts/globals/gear_sets.lua with matching mods.
--   * Yinyang Robe's "Avatar: Enmity+5" - petType in item_mods_pet selects the pet
--     CLASS, and PetModType::Avatar (1) is exactly "any avatar" (src/map/modifier.h,
--     matched by petutils::CheckPetModType), so the generator emits a single row.
--     This file used to fan the clause out into 14 PET_ID latents; do NOT re-add
--     them. Besides double-applying, they were also aimed at the wrong entity - a
--     PET_ID latent puts the mod on the OWNER while that pet is out, whereas the
--     sheet gives the Enmity to the avatar.
--
-- Rebuild/maintain this file with the `zenith-armor-lua-effects` skill.
-----------------------------------
require('modules/module_utils')

local m = Module:new('c-i_armor_body_eff')

-----------------------------------
-- 1. Healing Mail (NEW: the item has an item_usable row but no script at all, so
--    using it currently does nothing. "Enchantment: Recover Wyvern HP" restores
--    the pet's HP, following scripts/items/tube_of_healing_salve_i.lua.)
-----------------------------------
-- TUNE: the CSV states no amount, so this is a house value, not a retail one.
-- The healing-body family runs: healing_harness Lv16 = 50-75, healing_vest Lv30 and
-- high_healing_harness Lv45 = 90-105, healing_justaucorps Lv58 = 150-175 (all to the
-- PLAYER). 90-105 is taken from high_healing_harness (Lv45) -- the middle of that
-- family, not the top. Healing Mail is Lv70, so if this is ever revisited against a
-- retail capture, note that straight level-matching would argue for the 150-175 tier
-- or higher; it is held low deliberately because the heal lands on a pet.
local healingMailPetHeal = { 90, 105 }

xi.module.ensureTable('xi.items.healing_mail')

m:addOverride('xi.items.healing_mail.onItemCheck', function(target)
    if not target:hasPet() then
        return xi.msg.basic.REQUIRES_A_PET
    end

    return 0
end)

m:addOverride('xi.items.healing_mail.onItemUse', function(target)
    local pet = target:getPet()
    if not pet then
        return
    end

    local hpHeal = math.random(healingMailPetHeal[1], healingMailPetHeal[2])
    local deficit = pet:getMaxHP() - pet:getHP()
    if hpHeal > deficit then
        hpHeal = deficit
    end

    pet:addHP(hpHeal)
    pet:messageBasic(xi.msg.basic.RECOVERS_HP, 0, hpHeal)
end)

-----------------------------------
-- FOLLOW-UP (blocked, not forgotten -- tracked in the manifest).
-- * Blessed Bliaut +/-1 "Enhancing magic casting time -7/-8%": scripts/enum/mod.lua
--   has no enhancing-magic CAST-time mod (ENHANCING_MAGIC_RECAST is recast). Needs
--   a new mod plus C++ support in the cast-time calculation.
-----------------------------------

return m
