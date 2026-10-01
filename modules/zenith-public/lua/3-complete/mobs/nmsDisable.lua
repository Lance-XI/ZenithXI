-----------------------------------
-- Disabled notorious monsters
--
-- Replaces modules/zenith-public/sql/NMsDisable.sql, which stopped doing
-- anything when upstream moved mob data out of `mob_spawn_points` and into
-- data/zones/<zone>/mobs.yaml. That file ran
-- `UPDATE mob_spawn_points SET pos_x = 0, pos_y = 0, pos_z = 0 WHERE mobname IN (...)`,
-- and none of those 34 names are in sql/mob_spawn_points.sql any more, so it
-- matched zero rows and failed silently.
--
-- The old trick has no direct equivalent: 42 of the 45 surviving spawn points
-- are now `region:` spawns, and CMobEntity::Spawn() picks a fresh random point
-- inside the region every time, overwriting anything setSpawn() wrote. So these
-- NMs are taken out of circulation instead of being parked at the origin.
--
-- What this module does, and does not do:
--   * Normal-spawn NMs (marked "auto-respawn" below) are fully disabled:
--     setRespawnTime(0) clears m_AllowRespawn and unregisters them from the
--     zone's SpawnHandler, and the live instance is despawned.
--   * Lottery and scripted NMs are NOT reliably disabled. Their placeholders
--     call SpawnMob(), which runs CMobEntity::Spawn() directly and ignores
--     m_AllowRespawn. They are listed here so the set stays in one place, but
--     the only airtight fix is to drop `template:` from their spawn entries in
--     data/zones/<zone>/mobs.yaml -- which is base data, so it needs a git
--     patch. The exact spawn ids are in the retired SQL file's migration note.
--
-- 'Becut' was dropped: it no longer exists in any zone's mobs.yaml.
--
-- Public module for ZenithXI
-----------------------------------
require('modules/module_utils')

local m = Module:new('c-m_nm_disable')

-----------------------------------
-- Zone script name -> mob script name
-- ASA  = A Shantotto Ascension NMs
-- aptant = Ebon / Ebur / Furia synergy-set NMs (November 2009 version update)
-----------------------------------
local disabledNMs =
{
    ['Attohwa_Chasm'] =
    {
        ['Sargas'] = true, -- aptant; auto-respawn; content: wotg
    },

    ['Beaucedine_Glacier_[S]'] =
    {
        ['Came-cruse'] = true, -- aptant; scripted
    },

    ['Bhaflau_Thickets'] =
    {
        ['Harvestman'] = true, -- aptant; auto-respawn; content: wotg
    },

    ['Cape_Teriggan'] =
    {
        ['Tegmine']       = true, -- aptant; auto-respawn; content: wotg
        ['Zmey_Gorynych'] = true, -- aptant; auto-respawn; content: wotg
    },

    ['Crawlers_Nest'] =
    {
        ['Aqrabuamelu'] = true, -- aptant; auto-respawn; content: wotg
    },

    ['Crawlers_Nest_[S]'] =
    {
        ['Abatwa'] = true, -- aptant; scripted
    },

    ['Eastern_Altepa_Desert'] =
    {
        ['Sabotender_Corrido'] = true, -- aptant; auto-respawn; content: wotg
    },

    ['FeiYin'] =
    {
        ['Jenglot'] = true, -- aptant; auto-respawn; content: wotg
    },

    ['Fort_Karugo-Narugo_[S]'] =
    {
        ['Demoiselle_Desolee'] = true, -- aptant; lottery
    },

    ['Garlaige_Citadel_[S]'] =
    {
        ['Citadel_Pipistrelles'] = true, -- aptant; scripted
    },

    ['Jugner_Forest_[S]'] =
    {
        ['Drumskull_Zogdregg'] = true, -- aptant; lottery
    },

    ['Mamook'] =
    {
        ['Venomfang'] = true, -- aptant; scripted; content: wotg
    },

    ['Meriphataud_Mountains_[S]'] =
    {
        ['Muq_Shabeel'] = true, -- aptant; auto-respawn
    },

    ['Mount_Zhayolm'] =
    {
        ['Chary_Apkallu'] = true, -- aptant; auto-respawn; content: wotg
    },

    ['Pashhow_Marshlands_[S]'] =
    {
        ['Croque-mitaine'] = true, -- aptant; scripted
    },

    ['Qufim_Island'] =
    {
        ['Atkorkamuy'] = true, -- aptant; auto-respawn; content: wotg
    },

    ['RoMaeve'] =
    {
        ['Fired_Urn']     = true, -- asa; scripted; content: asa
        ['Lode_Golem']    = true, -- asa; scripted; content: asa
        ['Martinet']      = true, -- aptant; auto-respawn; content: wotg
        ['Nargun']        = true, -- aptant; auto-respawn; content: wotg
        ['Steely_Weapon'] = true, -- asa; scripted; content: asa
    },

    ['The_Eldieme_Necropolis_[S]'] =
    {
        ['Laelaps'] = true, -- aptant; auto-respawn
    },

    ['The_Sanctuary_of_ZiTah'] =
    {
        ['Blest_Bones']       = true, -- asa; scripted; content: asa
        ['Holey_Horror']      = true, -- asa; scripted; content: asa
        ['Skeleton_Scuffler'] = true, -- asa; scripted; content: asa
    },

    ['Toraimarai_Canal'] =
    {
        ['Canal_Moocher'] = true, -- aptant; lottery; content: abyssea
        ['Konjac']        = true, -- aptant; lottery; content: abyssea
    },

    ['Uleguerand_Range'] =
    {
        ['Frost_Flambeau'] = true, -- aptant; auto-respawn; content: wotg
        ['Skvader']        = true, -- aptant; lottery; content: wotg
    },

    ['Vunkerl_Inlet_[S]'] =
    {
        ['Big_Bang'] = true, -- aptant; lottery
        ['Warabouc'] = true, -- aptant; auto-respawn
    },

    ['Wajaom_Woodlands'] =
    {
        ['Chelicerata'] = true, -- aptant; scripted; content: wotg
    },
}

local function disableZoneNMs(zone, names)
    for _, mob in ipairs(zone:getMobs()) do
        if names[mob:getName()] then
            -- Order matters: a despawn re-registers the mob with the SpawnHandler
            -- while m_AllowRespawn is still set, so clear it first.
            mob:setRespawnTime(0)

            if mob:isSpawned() then
                DespawnMob(mob:getID())
            end
        end
    end
end

for zoneName, names in pairs(disabledNMs) do
    m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', zoneName), function(zone)
        super(zone)

        disableZoneNMs(zone, names)
    end)
end
