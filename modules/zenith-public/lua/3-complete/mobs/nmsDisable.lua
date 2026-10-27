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
-- How it works, per listed mob, from Zone.onInitialize (which runs after the
-- zone's first spawn pass):
--   * Respawn is switched off. Every automatic spawn path checks the mob's
--     m_AllowRespawn first: SpawnHandler respawns and spawn-slot ("lottery")
--     rolls both go through SpawnHandler::canSpawnNow.
--       - A mob outside a spawn slot gets setRespawnTime(0), which also clears
--         its pending respawn in the SpawnHandler.
--       - A spawn-slot NM (the lottery NMs, data/zones/<zone>/mobs.yaml
--         `slots:`) gets DisallowRespawn(id, true) instead. setRespawnTime(0)
--         would erase the whole slot's pending respawn, which the placeholder
--         shares, and the placeholders must keep popping.
--   * A DESPAWN listener does that again after every despawn. Most of these
--     NMs re-arm their own timer in onMobDespawn (setRespawnTime(7200) and
--     the like), and CMobEntity::OnDespawn calls the DESPAWN listeners right
--     after onMobDespawn, so the listener has the last word. Despawning first
--     and disabling afterwards would not be enough: DespawnMob only starts the
--     despawn, and onMobDespawn runs about 3 seconds later.
--   * The instance that is up at boot is despawned.
--
-- A GM can still pop one with !spawnmob: SpawnMob() calls CMobEntity::Spawn()
-- directly and does not look at m_AllowRespawn. Once it dies or is despawned
-- the listener switches respawn off again, so it does not come back.
--
-- Not covered: a script that calls setRespawnTime(n) on one of these mobs
-- while it is down would re-arm it. Nothing in LSB or zenith-public does that
-- for any mob listed here (checked 2026-10-26).
--
-- 'Becut' was dropped: its mobs.yaml spawn entry has no `template:`, so the
-- engine only reserves its id and never creates the mob.
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

local function disableRespawn(mob)
    if #mob:getSpawnSlotMobs() > 0 then
        DisallowRespawn(mob:getID(), true)
    else
        mob:setRespawnTime(0)
    end
end

local function disableZoneNMs(zone, names)
    for _, mob in ipairs(zone:getMobs()) do
        if names[mob:getName()] then
            -- Before the despawn below: CDespawnState registers the mob for
            -- respawn on entry if respawn is still allowed.
            disableRespawn(mob)
            mob:addListener('DESPAWN', 'ZXI_NM_DISABLE', disableRespawn)

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
