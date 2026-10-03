-----------------------------------
-- Custom monster aggro
--
-- Replaces modules/zenith-public/sql/custom_mob_behavior.sql, which stopped
-- doing anything when upstream moved mob data out of `mob_pools` and into
-- data/zones/<zone>/mobs.yaml. That file ran
-- `UPDATE mob_pools SET aggro = 1 WHERE name = ...` for four pools. None of
-- those four names are in `mob_pools` any more (only instanced and dynamic
-- mobs are left there), so it matched zero rows without any error.
--
-- A yaml template sets this with `behaviors: aggressive: true`; the engine
-- copies it into CMobEntity::m_Aggro when the mob is built
-- (mobutils::ApplySpecies). data/ is base, so the module-side route is
-- mob:setAggressive(true) from Zone.onInitialize, which zoneutils::LoadZones()
-- calls after every mob in the zone has been created and initialised.
--
-- One call per mob is enough. Unlike modifiers and mob mods, which
-- CMobEntity::Spawn() restores from a snapshot on every spawn, m_Aggro is only
-- written at build time and by setAggressive, so it survives every respawn.
-- None of the four mob scripts, their families' mixins or the zone mixins touch
-- aggression.
--
-- Names are mob script names (mob:getName(): the spawn's `script`, else its
-- template name). In every case that is also the template name the SQL's pool
-- name matched, and each template has no spawn under another script. All four
-- templates are `content: abyssea`; where that content is gated off the engine
-- never creates them, so there is nothing to change.
--
-- Only zone mobs are covered. The four pools are not in `mob_pools`, so no
-- instance or dynamic spawn could have used them.
--
-- Public module for ZenithXI
-----------------------------------
require('modules/module_utils')

local m = Module:new('c-m_custom_mob_aggro')

-----------------------------------
-- Zone script name -> mob script name
-----------------------------------
local aggressiveMobs =
{
    ['Inner_Horutoto_Ruins'] =
    {
        ['Deathwatch_Beetle'] = true, -- Deprecated Beady Beetles used to aggro
    },

    ['Crawlers_Nest'] =
    {
        ['Vespo']        = true, -- Typical Nest behavior
        ['Olid_Funguar'] = true, -- Typical Nest behavior
    },

    ['Gustav_Tunnel'] =
    {
        ['Boulder_Eater'] = true, -- Balance target's appeal (does not link)
    },
}

for zoneName, names in pairs(aggressiveMobs) do
    m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', zoneName), function(zone)
        super(zone)

        for _, mob in ipairs(zone:getMobs()) do
            if names[mob:getName()] then
                mob:setAggressive(true)
            end
        end
    end)
end

return m
