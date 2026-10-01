-- -----------------------------------
-- Mob Reposition Module Template
--
-- This module overrides the default spawn points
-- for the chosen mob groups.
--
-- NOTE: `pos` overrides no longer work for mobs that are placed by a roam
-- region instead of a fixed point. `CMobEntity::Spawn()` re-rolls a random
-- point inside the mob's region on every life and writes it straight into
-- m_SpawnPoint, which discards anything `setSpawn()` put there. Every
-- Bibiki Bay spawn is region placed (310 spawns, 310 `region:` keys, 0
-- `pos:` keys in data/zones/bibiki_bay/mobs.yaml), so the Locus_Camelopard
-- and Locus_Hypnos_Eft position overrides that used to live here were dead
-- and have been removed. There is no Lua binding for roam regions -
-- `setRoamRegions()` is C++ only - so a region placed mob can only be moved
-- by editing its `region:` in the zone YAML.
--
-- `limit` based culling is unaffected: it despawns whole spawn points and
-- never touches m_SpawnPoint.
-- -----------------------------------

require('modules/module_utils')
local m = Module:new('c-m_reposition_template')

local mobList =
{
    ['Locus_Bight_Rarab'] =
    {
        limit = 0,
    },
    ['Locus_Camelopard'] =
    {
        limit = { 4, 7, 11, 13, 17, 18, 22 },
    },
    ['Locus_Ghost_Crab'] =
    {
        limit = 20,
    },
    ['Locus_Hypnos_Eft'] =
    {
        limit = 6,
    },
}

-- override zone init so we can remove or reposition mobs
m:addOverride('xi.zones.Bibiki_Bay.Zone.onInitialize',
function(zone)
    super(zone)
    zxi.mobHelpers.zoneInitReposition(zone, mobList)
end)

return m
