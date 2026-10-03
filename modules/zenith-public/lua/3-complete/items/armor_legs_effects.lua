-----------------------------------
-- Legs Armor Effects (companion Lua module for the Legs armor rework)
--
-- Implements the legs-armor effects that CANNOT be expressed in item_mods /
-- item_latents SQL, and that DIFFER from the item's current functionality.
--
-- Source of truth: the routed-effect manifest emitted by the SQL generator,
--   modules/zenith-public/lua/3-complete/items/armor_legs_effects.manifest.json
-- Every manifest item was audited against its existing scripts/items/<name>.lua
-- and DB rows before any code was written here; only genuine deltas are coded.
-- Intentionally NOT implemented because vanilla already covers them:
--   * 5 enchantments (Mist Slacks, Shock Subligar, Ice Trousers, Blaze Hose,
--     Hydra Tights) - each has a scripts/items/<name>.lua doing exactly what the
--     CSV describes.
--   * 8 "Physical damage: <X>" procs (Ogre Trousers +/-1, War Brais +/-1, Rasetsu
--     Hakama +/-1, Igqira/Genie Lappas) - already DB rows: ITEM_SUBEFFECT +
--     ITEM_ADDEFFECT_DMG + ITEM_ADDEFFECT_CHANCE.
--   * 5 set bonuses (Amir, Fourth Division, Pahluwan, Yigit, Hachiryu) - present
--     in vanilla scripts/globals/gear_sets.lua with matching mods.
--   * Malagigi's Trousers "Campaign: Fast Cast+10% Store TP+5" - campaign is the
--     ALLIED_TAGS status effect, so it is an ordinary STATUS_EFFECT_ACTIVE latent
--     (13, 267) and the generator now writes it straight to item_latents, deriving
--     the row from (sheet total - base mod) the same way vanilla does. This file
--     used to carry a -1 Fast Cast correction; do NOT re-add it, the .sql row and
--     that one would both apply.
--   * Bedivere's Hose "Latent effect: Regen+2~3" - the generator now reads the
--     tier table out of the CSV's notes column ("50~26: Regen+2, 25~1: Regen+3")
--     and emits two nesting HpUnderPercent rows (+2 under 50%, +1 more under 25%).
--     This file used to carry exactly that pair; do NOT re-add it. The .sql also
--     replaces the item's obsolete Attack+25 / Accuracy+25 rows, which the Lua
--     version could not do (delLatent only drops latents it added itself).
--
-- The effect below is latent-shaped, but the generator cannot derive it from the
-- sheet: the moon table lives in the CSV's notes column in a form the tier reader
-- does not cover. It lives here rather than in the .sql because that file is
-- regenerated from the sheet on every run and would drop hand-written rows.
--
-- DEPENDS ON: modules/zenith-public/sql/armor_overrides_zz_stale_latent_cleanup.sql
-- Routing an effect to Lua means the generator emits no item_latents rows for the
-- item, and it only emits `DELETE FROM item_latents` alongside rows it generates
-- (generate_armor_overrides.py:2065). So the item's VANILLA latents survive under
-- everything this file adds, and both apply. That cleanup .sql drops them. If another
-- item in this file ever gets a Lua-owned latent, add it there too -- delLatent cannot
-- do it, it only removes latents the same code added.
--
-- Rebuild/maintain this file with the `zenith-armor-lua-effects` skill.
-----------------------------------
require('modules/module_utils')

local m = Module:new('c-i_armor_legs_eff')

-----------------------------------
-- 1. Luna Subligar (NEW: "Bonus varies with the phases of the moon", with the
--    per-phase table in the sheet's notes column. The MoonPhase latent takes one
--    of 8 phase buckets as its condition value (latent_effect_container.cpp):
--    0 New, 1 Waxing Crescent, 2 First Quarter, 3 Waxing Gibbous, 4 Full,
--    5 Waning Gibbous, 6 Last Quarter, 7 Waning Crescent. The CSV groups the
--    waxing/waning pairs, so each pair gets the same mods.)
-----------------------------------
local moonPhase =
{
    new            = 0,
    waxingCrescent = 1,
    firstQuarter   = 2,
    waxingGibbous  = 3,
    full           = 4,
    waningGibbous  = 5,
    lastQuarter    = 6,
    waningCrescent = 7,
}

local lunaSubligarLatents =
{
    -- Full Moon: CHR+7 Accuracy+3
    -- CHR is a DELTA, not the total: armor_overrides_legs.sql already grants CHR+3
    -- unconditionally as an item_mod, so +4 here makes the full-moon total the +7 the
    -- sheet quotes (which is how vanilla modelled it too -- its own latent row carried
    -- the comment "CHR +4 (total +7)"). Accuracy has no base mod, so +3 is both.
    { moonPhase.full, xi.mod.CHR, 4 },
    { moonPhase.full, xi.mod.ACC, 3 },
    -- Wax/Wane Gibbous: Accuracy+2 Evasion+1
    { moonPhase.waxingGibbous, xi.mod.ACC, 2 },
    { moonPhase.waxingGibbous, xi.mod.EVA, 1 },
    { moonPhase.waningGibbous, xi.mod.ACC, 2 },
    { moonPhase.waningGibbous, xi.mod.EVA, 1 },
    -- Half Moon (first/last quarter): Accuracy+2 Evasion+2
    { moonPhase.firstQuarter, xi.mod.ACC, 2 },
    { moonPhase.firstQuarter, xi.mod.EVA, 2 },
    { moonPhase.lastQuarter, xi.mod.ACC, 2 },
    { moonPhase.lastQuarter, xi.mod.EVA, 2 },
    -- Wax/Wane Crescent: Accuracy+1 Evasion+2
    { moonPhase.waxingCrescent, xi.mod.ACC, 1 },
    { moonPhase.waxingCrescent, xi.mod.EVA, 2 },
    { moonPhase.waningCrescent, xi.mod.ACC, 1 },
    { moonPhase.waningCrescent, xi.mod.EVA, 2 },
    -- New Moon: Evasion+3 "Double Attack"+1%
    { moonPhase.new, xi.mod.EVA, 3 },
    { moonPhase.new, xi.mod.DOUBLE_ATTACK, 1 },
}

xi.module.ensureTable('xi.items.luna_subligar')

m:addOverride('xi.items.luna_subligar.onItemEquip', function(user)
    for _, latent in ipairs(lunaSubligarLatents) do
        user:addLatent(xi.latent.MOON_PHASE, latent[1], latent[2], latent[3])
    end
end)

m:addOverride('xi.items.luna_subligar.onItemUnequip', function(user)
    for _, latent in ipairs(lunaSubligarLatents) do
        user:delLatent(xi.latent.MOON_PHASE, latent[1], latent[2], latent[3])
    end
end)

-----------------------------------
-- FOLLOW-UP (blocked, not forgotten -- tracked in the manifest).
-- * Sorcerer's Tonban +/-1 ("Elemental magic +3 depending on day"): retail scales
--   the bonus by the spell's element vs the day, which is per-cast, not a latent.
--   Needs a hook in the elemental-magic damage path.
-- The "Pet:" trousers/kecks and Rasetsu Hakama +1 were listed here once and are now
-- emitted as SQL (a separate pet property, and an NQ trigger reused).
-----------------------------------

return m
