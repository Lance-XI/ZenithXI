-----------------------------------
-- Feet Armor Effects (companion Lua module for the Feet armor rework)
--
-- Implements the feet-armor effects that CANNOT be expressed in item_mods /
-- item_latents SQL, and that DIFFER from the item's current functionality.
--
-- Source of truth: the routed-effect manifest emitted by the SQL generator,
--   modules/zenith-public/lua/3-complete/items/armor_feet_effects.manifest.json
-- Every manifest item was audited against its existing scripts/items/<name>.lua
-- and DB rows before any code was written here; only genuine deltas are coded.
-- Intentionally NOT implemented because vanilla already covers them:
--   * 4 enchantments (Gargoyle Boots, Mist Pumps, Sneaking Boots, Hydra Spats) -
--     each has a scripts/items/<name>.lua doing exactly what the CSV describes.
--   * Koschei Crackows' "Physical damage: Curse effect on opponent" - already DB
--     rows: ITEM_SUBEFFECT 4 (= ActionReactKind::CurseSpikes) + ITEM_ADDEFFECT_DMG
--     + ITEM_ADDEFFECT_CHANCE, which is the gear-spikes path in battleutils.
--   * 4 set bonuses - Pahluwan Crackows (gear_sets [6]), Yigit Crackows ([10]),
--     Hachiryu Sune-Ate ([25]) and Vampiric Boots ([133]) are all in vanilla
--     scripts/globals/gear_sets.lua with mods matching the CSV.
--   * Every "Campaign:" line (Emissary Boots, Llwyd's Clogs) - campaign is the
--     ALLIED_TAGS status effect, so it is an ordinary STATUS_EFFECT_ACTIVE latent
--     (13, 267) and the generator now writes it straight to item_latents. This
--     file used to carry a hand-written Fast Cast latent for Llwyd's Clogs; do NOT
--     re-add it, the .sql row and this one would both apply.
--   * Every "Avatar:" line (Ebon/Ebur/Furia Galoshes, Koschei Crackows) - petType
--     in item_mods_pet selects the pet CLASS, and PetModType::Avatar (1) is exactly
--     "any avatar" (src/map/modifier.h, matched by petutils::CheckPetModType). The
--     generator emits those rows now; the pet:isAvatar() handler this file used to
--     carry was solving a problem the schema already solves.
--
-- Rebuild/maintain this file with the `zenith-armor-lua-effects` skill.
-----------------------------------
require('modules/module_utils')

local m = Module:new('c-i_armor_feet_eff')

-----------------------------------
-- 1. Earth Greaves (NEW: the item already has an item_usable row but no script at
--    all, so using it currently does nothing. "Enchantment: Wyvern gains effect of
--    Stoneskin" follows scripts/items/gargoyle_boots.lua, the only wyvern-stoneskin
--    precedent in the repo.)
-----------------------------------
-- TUNE: the CSV states no amount or duration. Matched to Gargoyle Boots; Earth
-- Greaves is the Lv68 DRG piece against that item's Lv30, so these may want raising
-- once a retail value is available.
local earthGreavesStoneskinPower = 200
local earthGreavesStoneskinDuration = 60

xi.module.ensureTable('xi.items.earth_greaves')

m:addOverride('xi.items.earth_greaves.onItemCheck', function(target, item, caster)
    local pet = caster:getPet()

    if
        not pet or
        pet:getPetID() ~= xi.petId.WYVERN
    then
        return xi.msg.basic.ITEM_NO_TARGET
    end

    return 0
end)

m:addOverride('xi.items.earth_greaves.onItemUse', function(target, user, item, action)
    local pet = user:getPet()

    if
        pet and
        pet:getPetID() == xi.petId.WYVERN
    then
        -- Item is self target but reports the effect on the wyvern.
        action:ID(user:getID(), pet:getID())

        local stoneskin =
        {
            power = earthGreavesStoneskinPower,
            duration = earthGreavesStoneskinDuration,
            origin = user,
        }

        if pet:addStatusEffect(xi.effect.STONESKIN, stoneskin) then
            action:messageID(pet:getID(), xi.msg.basic.ITEM_RECEIVES_EFFECT)

            return xi.effect.STONESKIN
        end
    end

    action:messageID(target:getID(), xi.msg.basic.ITEM_NO_EFFECT)

    return 0
end)

-----------------------------------
-- 2. Root Sabots (NEW: the CSV note says "This enchantment isn't coded. Bind latent
--    is coded" -- and it is: item_latents gives REGEN+2 while xi.effect.BIND (11) is
--    active. The item also already has an item_usable row, but no script, so the
--    "Enchantment: Bind" that is supposed to trigger that latent does nothing. It
--    self-binds: the point of the item is trading mobility for the Regen.)
-----------------------------------
local rootSabotsBindDuration = 120   -- CSV note: "Bind lasts 2 minutes"

xi.module.ensureTable('xi.items.root_sabots')

m:addOverride('xi.items.root_sabots.onItemCheck', function(target)
    return 0
end)

m:addOverride('xi.items.root_sabots.onItemUse', function(target, user)
    target:delStatusEffect(xi.effect.BIND)
    target:addStatusEffect(xi.effect.BIND, { duration = rootSabotsBindDuration, origin = user })
end)

-----------------------------------
-- FOLLOW-UP: nothing outstanding. The feet manifest is now only set bonuses (all
-- in vanilla gear_sets.lua) plus the two enchantments implemented above.
--
-- Previously listed here and since resolved in SQL: the "Vs. vermin: Pet:" gamashes
-- (a separate pet property), Rasetsu Sune-Ate +1 (NQ trigger reused), Skanda Boots
-- (JUMP_ATT_BONUS), Kyoshu Kyahan (its vanilla Footwork latent was being missed by
-- the generator's SQL reader, and now supplies the trigger for Accuracy/Attack +10)
-- and Caitiff's Socks ("Flee" is deliberately left unchanged -- see the note in
-- armor_overrides_feet.sql).
-----------------------------------

return m
