-- ZenithXI mob reposition template (modules/zenith-public/lua/3-complete/mobs/mob_reposition_template.lua).
--
-- LSB spawns every Locus mob in Bibiki Bay. The module's Bibiki_Bay Zone.onInitialize override runs
-- zxi.mobHelpers.zoneInitReposition, which despawns and disallows respawn for the spawns outside each
-- name's limit: every Locus_Bight_Rarab (limit 0), all Locus_Camelopard but spawns 4, 7, 11, 13, 17,
-- 18 and 22, Locus_Ghost_Crab past the first 20 and Locus_Hypnos_Eft past the first 6. Spawn numbers
-- are positions in zone:queryEntitiesByName, as in the module. The module's old position overrides
-- are gone (region-placed spawns re-roll their point every life), so only the culling is checked.
--
-- Needs Bibiki_Bay enabled in zone_settings (zoneip not 0), as in sql/zone_settings.sql; a disabled
-- zone never runs Zone.onInitialize.

describe('Zenith mob reposition template', function()
    local culls =
    {
        { name = 'Locus_Bight_Rarab', keep = {}                                                 },
        { name = 'Locus_Camelopard',  keep = { [4] = true, [7] = true, [11] = true, [13] = true, [17] = true, [18] = true, [22] = true } },
        { name = 'Locus_Ghost_Crab',  keepFirst = 20                                            },
        { name = 'Locus_Hypnos_Eft',  keepFirst = 6                                             },
    }

    local function isKept(cull, idx)
        if cull.keepFirst then
            return idx <= cull.keepFirst
        end

        return cull.keep[idx] == true
    end

    for _, cull in ipairs(culls) do
        it(string.format('keeps culled %s spawns from coming back', cull.name), function()
            local player = xi.test.world:spawnPlayer({ zone = xi.zone.BIBIKI_BAY })
            local mobs   = player:getZone():queryEntitiesByName(cull.name)
            assert(#mobs > 0, string.format('precondition: no %s in Bibiki Bay', cull.name))

            local zoneScript = xi.zones.Bibiki_Bay and xi.zones.Bibiki_Bay.Zone
            assert(zoneScript and zoneScript.onInitialize, 'precondition: Bibiki_Bay Zone.lua never loaded (zone disabled in zone_settings?)')

            -- past every respawn timer the culled spawns could still have pending (Locus mobs: 60s / 330s)
            for _ = 1, 4 do
                xi.test.world:skipTime(120)
            end

            local keptUp = 0
            for idx, mob in ipairs(mobs) do
                if isKept(cull, idx) then
                    if mob:isSpawned() then
                        keptUp = keptUp + 1
                    end
                else
                    assert(not mob:isSpawned(), string.format('%s spawn %d (%d) is up, it should be culled', cull.name, idx, mob:getID()))
                end
            end

            -- the kept spawns still come up, so the culled ones being down is not just an empty zone
            if cull.keepFirst or next(cull.keep) then
                assert(keptUp > 0, string.format('precondition: none of the kept %s spawns is up', cull.name))
            end
        end)
    end
end)
