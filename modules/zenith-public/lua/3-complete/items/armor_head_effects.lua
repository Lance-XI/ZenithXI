-----------------------------------
-- Head Armor Effects (companion Lua module for the Head armor rework)
--
-- Implements the head-armor effects that CANNOT be expressed in item_mods /
-- item_latents SQL, and that DIFFER from the item's current functionality.
--
-- Source of truth: the routed-effect manifest emitted by the SQL generator,
--   modules/zenith-public/lua/3-complete/items/armor_head_effects.manifest.json
-- Each item below was audited against its existing scripts/items/<name>.lua and
-- DB rows; only genuine deltas (NEW or CHANGED) are implemented here. Items whose
-- current behaviour already matches the CSV are intentionally NOT touched
-- (eldritch_bone_hairpin, mist_crown, fenrirs_crown, hydra_tiara, kawahori_kabuto,
-- blissful_chapeau, jesters_hat).
--
-- Intentionally NOT implemented because vanilla already covers them:
--   * 3 "Physical damage: Blaze Spikes" procs (Rasetsu Jinpachi +/-1, Breeder Mask)
--     - already DB rows: ITEM_SUBEFFECT 1 (= ActionReactKind::BlazeSpikes) +
--     ITEM_ADDEFFECT_DMG + ITEM_ADDEFFECT_CHANCE, the gear-spikes path in
--     battleutils. Do NOT re-add these as xi.mod.SPIKES: HandleSpikesDamage takes
--     the Mod::SPIKES branch and returns before the gear branch, so setting it
--     drops the chance roll AND suppresses every other spikes item the player has
--     equipped (Mod::SPIKES is entity-wide). Matches how body/hands/legs/feet
--     leave their 17 proc items to the DB.
--   * The BST warbonnets' "Vs. beasts: Charm+N" - the generator emits it as a
--     real item_latents row (VS_ECOSYSTEM 59, param = ecosystem id). Adding the
--     same latent here again would simply double the Charm bonus.
--   * Those warbonnets' "Pet: Magic Atk. Bonus+N" - the sheet lists it as a
--     SEPARATE property, not gated by the "Vs. beasts" clause in front of it, so
--     it is an ordinary unconditional pet mod and the generator emits it to
--     item_mods_pet.
--   * The beastman helms' "Pet:" mods (Lamia Garland, Mamool Ja Helm, Troll Coif,
--     Qiqirn Hood) - same reading, so they are item_mods_pet rows now rather than
--     the zone-gated Lua handler this file used to carry. Their PLAYER stats are
--     still gated to Arrapago Reef / Halvung / Mamook by the vanilla ZONE latents
--     (latentId 23, params 54/62/65), which the generator reuses untouched.
--   * Kawahori Kabuto's "Enchantment: Blindness" - the sheet states it as prose
--     with NO power or duration, so the generator matched it to the vanilla
--     scripts/items/kawahori_kabuto.lua and routed nothing to the manifest (16071
--     does not appear in armor_head_effects.manifest.json at all). Whatever the
--     base script does IS the sheet's intent, so the enchantment's numbers are
--     deliberately inherited rather than pinned here. Re-audited after the
--     upstream sync, which reworked exactly those numbers (Blindness power
--     25 -> 200, duration 180 -> 60*10) and gave the use a visual animation
--     (sql/item_usable.sql column `animation` 0 -> 70). Nothing in our data
--     touches item_usable, so all three land untouched - do NOT add an override
--     to restore the old values; the sheet never asked for them.
--   * Karura Hachigane's "Perpetuation cost -2" - sql/item_latents.sql has
--     (16154,346,2,9,13) = PERPETUATION_REDUCTION 2 on a PET_ID latent gated to
--     Garuda. A PET_ID latent applies its mod to the OWNER, which is exactly where
--     perpetuation reduction belongs (status_effect_container reads it off the char),
--     so the DB row alone is already correct. This file used to add a flat equipped
--     mod on top; do NOT re-add it - the module SQL only ever deletes item_mods, so
--     the latent survives and the two stack (and the flat mod also escapes the Lv73
--     scaling that battle_entity applies to real item mods/latents).
--
-- !! NEVER call xi.module.ensureTable on a path that HAS a scripts/items/<name>.lua.
--    Modules load before itemutils::Initialize, and the item-script loader caches with
--    sol::update_if_empty - which skips the assignment when the key is already non-nil.
--    An ensureTable'd empty table therefore makes the engine silently DISCARD the whole
--    vanilla item script, and super() then resolves to moduleutils' empty stub with no
--    warning. Overriding without ensureTable is the correct path: the override defers
--    and is applied against the real table once it loads. ensureTable is only for items
--    with NO base script (breeder_mask/breeder_mufflers below).
--
-- Rebuild/maintain this file with the `zenith-armor-lua-effects` skill.
-----------------------------------
require('modules/module_utils')

local m = Module:new('c-i_armor_head_eff')

-----------------------------------
-- 1. Exp-bonus Berets (DIFFERS: current gives +150% / max 30000; CSV wants +25% / 500)
--    Effect TYPE is preserved (Guide Beret = Capacity Points / COMMITMENT,
--    Sprout Beret = Experience / DEDICATION); only the values change.
-----------------------------------
local expBerets =
{
    guide_beret  = { effect = xi.effect.COMMITMENT, power = 25, duration = 43200, subpower = 500 },
    sprout_beret = { effect = xi.effect.DEDICATION, power = 25, duration = 43200, subpower = 500 },
}

for itemName, data in pairs(expBerets) do
    m:addOverride(string.format('xi.items.%s.onItemUse', itemName), function(target)
        xi.itemUtils.addItemExpEffect(target, data.effect, data.power, data.duration, data.subpower)
    end)
end

-----------------------------------
-- 2. Zoolater Hat (DIFFERS: base script grants pet Regain power 15 only; CSV wants
--    "Pet gains effect of Meditate + Restores Pet HP" ~ 200 TP/tick x 5 ticks, +750 HP.)
--    NOTE: xi.effect.REGAIN power is decitp -- scripts/effects/regain.lua multiplies it
--    by 10 before setting xi.mod.REGAIN -- so 200 TP/tick is power 20, not power 200.
--    The effect's own `tick` is inert here: the TP is granted by the container's regen
--    tick (status_effect_container.cpp), so a 15s duration already yields the 5 ticks
--    the manifest asks for.
-----------------------------------
m:addOverride('xi.items.zoolater_hat.onItemUse', function(target, user)
    local pet = target:getPet()
    if pet then
        pet:delStatusEffect(xi.effect.REGAIN)
        pet:addStatusEffect(xi.effect.REGAIN, { power = 20, duration = 15, origin = user })
        pet:addHP(750)
    else
        target:messageBasic(xi.msg.basic.NO_EFFECT)
    end
end)

-----------------------------------
-- 3. Breeder set (head + hands) -- "Pet: DEF+10 Enmity+5". This is a SET bonus, but
--    vanilla gear_sets.lua applies PLAYER mods only, so the pet portion needs a small
--    custom handler.
-----------------------------------
local breederPieces = { xi.item.BREEDER_MASK, xi.item.BREEDER_MUFFLERS }
local breederPetMods = { { xi.mod.DEF, 10 }, { xi.mod.ENMITY, 5 } }
local breederPetVar = 'breederPetSet'
local breederMagicListener = 'armor_breeder_set_magic'
local breederAbilityListener = 'armor_breeder_set_ability'

-- Counted the same way vanilla counts a gear set (gear_sets.lua:2478-2492): walk the
-- equipped slots and skip any piece the player is currently too low to benefit from,
-- so level sync suppresses this set exactly like every vanilla one. hasEquipped() alone
-- cannot do that -- it answers "is it on", not "does it count", and left the bonus live
-- on a character synced below the pieces' Lv70.
local function breederActive(player, excludeId)
    local playerCurrentLevel = player:getMainLvl()
    local count = 0

    for equipmentSlot = 0, xi.MAX_SLOTID do
        local equip = player:getEquippedItem(equipmentSlot)

        if equip then
            local equipId = equip:getID()

            if
                equipId ~= excludeId and
                playerCurrentLevel >= equip:getReqLvl() -- Player may be under Level Sync/Cap
            then
                for _, itemId in ipairs(breederPieces) do
                    if equipId == itemId then
                        count = count + 1
                    end
                end
            end
        end
    end

    return count >= 2
end

-- Reconcile the CURRENT pet against the 2-piece threshold.
--
-- The applied flag lives on the PET, not the owner. The mods are the pet's, and a pet
-- outlives no gear change while an owner-side flag outlives every pet: with the flag on
-- the player, equipping both pieces with no pet out latched "applied" while nothing was
-- applied, and the next unequip then subtracted mods from a pet that never received
-- them. CBattleEntity::delModifier just does `m_modStat[type] -= amount` with no floor
-- at zero, so that pet ended up at DEF-10 / Enmity-5 versus wearing no Breeder gear.
-- Keying on the pet makes both halves refer to the same entity, and makes this
-- idempotent so it is safe to call from a hot listener.
local function syncBreederPet(player, excludeId)
    local pet = player:getPet()
    if not pet then
        return
    end

    local shouldHave = breederActive(player, excludeId)
    local hasMods    = pet:getLocalVar(breederPetVar) == 1

    if shouldHave and not hasMods then
        for _, petMod in ipairs(breederPetMods) do
            pet:addMod(petMod[1], petMod[2])
        end

        pet:setLocalVar(breederPetVar, 1)
    elseif not shouldHave and hasMods then
        for _, petMod in ipairs(breederPetMods) do
            pet:delMod(petMod[1], petMod[2])
        end

        pet:setLocalVar(breederPetVar, 0)
    end
end

-- Both pet-summoning paths must be covered. This set is BST/DRG/SMN/PUP, and only SMN
-- summons with a spell (MAGIC_STATE_EXIT) -- Call Beast/Bestial Loyalty, Call Wyvern and
-- Activate/Deploy are job abilities (ABILITY_STATE_EXIT), so a summon-spell-only listener
-- left three of the four jobs with a pet that never got the bonus. Neither event is
-- filtered by spell/ability id on purpose: syncBreederPet early-outs with no pet and is
-- guarded by the pet's own flag, so re-running it costs two local-var reads and it also
-- covers pets that appear by any other route.
local function setBreederListeners(player)
    player:removeListener(breederMagicListener)
    player:removeListener(breederAbilityListener)

    player:addListener('MAGIC_STATE_EXIT', breederMagicListener, function(owner)
        syncBreederPet(owner, nil)
    end)

    player:addListener('ABILITY_STATE_EXIT', breederAbilityListener, function(owner)
        syncBreederPet(owner, nil)
    end)
end

local function onBreederEquip(user)
    setBreederListeners(user)
    syncBreederPet(user, nil)
end

local function onBreederUnequip(user, item)
    local excludeId = item:getID()

    syncBreederPet(user, excludeId)

    if not breederActive(user, excludeId) then
        user:removeListener(breederMagicListener)
        user:removeListener(breederAbilityListener)
    end
end

-- Neither piece has a scripts/items file, so ensureTable is correct here (see the
-- warning in this file's header for when it is NOT).
xi.module.ensureTable('xi.items.breeder_mask')
m:addOverride('xi.items.breeder_mask.onItemEquip', onBreederEquip)
m:addOverride('xi.items.breeder_mask.onItemUnequip', onBreederUnequip)

xi.module.ensureTable('xi.items.breeder_mufflers')
m:addOverride('xi.items.breeder_mufflers.onItemEquip', onBreederEquip)
m:addOverride('xi.items.breeder_mufflers.onItemUnequip', onBreederUnequip)

-----------------------------------
-- FOLLOW-UP (deferred: need a precedent or a design decision; tracked in the manifest).
-- * Set bonuses: vanilla scripts/globals/gear_sets.lua already implements Amir,
--   Pahluwan, Yigit, Fourth Division and Skadi; Carline (new) and the Bowman's +12
--   value are in armor_set_bonuses.lua; Breeder (pet) is handled above.
-- * Reikyo Hairpin - Enchantment "Slightly Bad Breath": a multi-status mob-TP-move
--   analogue; needs the exact status list/values before coding. It is the only
--   head enchantment with no base script left.
-- (Reviler's Helm "Provoke" was listed here as blocked on a missing precedent;
--  scripts/items/revilers_helm.lua now implements it as addEnmity(user, 1, 1800),
--  so vanilla covers it and nothing is owed.)
-----------------------------------

return m
