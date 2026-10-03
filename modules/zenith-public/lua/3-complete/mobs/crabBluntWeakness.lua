-----------------------------------
-- Crab blunt / hand-to-hand weakness
--
-- Replaces modules/zenith-public/sql/crab_blunt_weakness.sql, which stopped
-- reaching zone crabs when upstream moved mob data into data/ecosystems.yaml and
-- data/zones/<zone>/mobs.yaml. That file ran
-- `UPDATE mob_resistances SET impact_sdt = impact_sdt + 2500,
-- h2h_sdt = h2h_sdt + 1250 WHERE name LIKE "Crab%"`, i.e. 25% more blunt and
-- 12.5% more hand-to-hand damage taken for every crab. Zone mobs take their
-- resistances from the species (ecosystems.yaml) and the template, so that
-- table no longer touches them.
--
-- Sign and scale: physical SDT is `damage * (1 + mod / 10000)`
-- (xi.combat.damage.physicalElementSDT, battleutils::TakePhysicalDamage), so
-- +2500 is 25% more damage taken and a negative value is a resistance. The H2H
-- modifier is xi.mod.HTH_SDT. The values are added on top of whatever the
-- template already carries, exactly as the SQL's `+` did: Cancer's yaml has
-- -5000 for both, so it ends at -2500 blunt and -3750 H2H, as before.
--
-- Which mobs: the SQL hit every pool whose resist_id was one of the five crab
-- rows. In the yaml those are 249 zone templates, all species `crab` or
-- `carrier_crab`, i.e. family `crab`. Eight more templates in family `crab`
-- (ghoyus_reverie, everbloom_hollow, walk_of_echoes_p1 / p2) had resist_id 0 and
-- were not touched; they are covered here too, since the SQL header says "ALL
-- crab variants" and none of those zones is active on the current server.
-- Fished crabs (the `*_fished` templates) are ordinary zone entities placed at
-- 1, 1, 1 until fished, so they are covered by the same loop.
--
-- Applied per spawn, not once. CalculateMobStats() starts with
-- restoreModifiers(), which puts every modifier back to the snapshot taken at
-- zone load, so anything set at Zone.onInitialize is gone after the first
-- respawn. The SPAWN listener fires at the end of CMobEntity::Spawn(), after
-- that restore, and adds the bonus once; the next spawn starts from the
-- snapshot again, so it never accumulates. Mobs already up when this runs
-- get the bonus directly, because the listener has missed their spawn.
--
-- The same restore means a setMobLevel() after this listener would undo it
-- (setMobLevel recalculates stats). mobLevelAndRespawn.lua does that from its
-- own SPAWN listener for a handful of crabs. That listener is registered from
-- Zone.onInitialize, and this one from xi.server.onServerStart, which runs after
-- every zone has initialised, so it is registered later and fires later.
-- Do not move this to Zone.onInitialize without keeping that order.
--
-- It matches on family rather than name, so it runs once over every loaded zone
-- (GetZone() is nil for zones this map process does not host).
--
-- Not covered: instanced crabs (Ilrusi_Atoll, Periqia, Nyzul_Isle, ...), dynamic
-- spawns and crab jug pets. They are built from `mob_pools` / `pet_list` and
-- read `mob_resistances` resist_id 77, which this module does not write. That
-- row only holds the old SQL's +2500 / +1250 if the SQL was ever applied to the
-- database; it will not be applied again.
--
-- Public module for ZenithXI
-----------------------------------
require('modules/module_utils')

local m = Module:new('c-m_crab_blunt_weakness')

-----------------------------------
-- Extra damage taken, in 1/10000 (2500 = 25%)
-----------------------------------
local bluntWeakness = 2500
local h2hWeakness   = 1250

local function weakenCrab(mob)
    mob:addMod(xi.mod.IMPACT_SDT, bluntWeakness)
    mob:addMod(xi.mod.HTH_SDT, h2hWeakness)
end

local function weakenZoneCrabs(zone)
    for _, mob in ipairs(zone:getMobs()) do
        if mob:getFamily() == xi.mobFamily.CRAB then
            mob:addListener('SPAWN', 'ZXI_CRAB_BLUNT_WEAKNESS', weakenCrab)

            if mob:isSpawned() then
                weakenCrab(mob)
            end
        end
    end
end

m:addOverride('xi.server.onServerStart', function()
    super()

    for zoneId in pairs(zxi.zoneName) do
        local zone = GetZone(zoneId)

        if zone then
            weakenZoneCrabs(zone)
        end
    end
end)

return m
