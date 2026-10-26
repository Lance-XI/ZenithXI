-- ZenithXI mob level and respawn overrides (modules/zenith-public/lua/3-complete/mobs/mobLevelAndRespawn.lua).
--
-- LSB takes a zone mob's level range and respawn time from data/zones/<zone>/mobs.yaml. The module
-- re-rolls the level from its own range on every spawn (SPAWN listener) and sets its own respawn time
-- on mobs that are up at zone init. Spot checks, picked where the yaml and the module do not overlap:
--   level:   Orcish_Beastrider (Batallia Downs)  yaml 30-31,        module 33-36
--            Goblin_Smithy (Sauromugue Champaign) yaml 26-27 / 31-32, module 33-36
--            Young_Quadav (Palborough Mines)    yaml 3-5,          module 14-18
--   respawn: Wild_Rabbit (West Ronfaure)        yaml 60s,          module 300s
--            Ghelsba_Pugil (Ghelsba Outpost)    yaml 300s,         module 480s
-- The respawn cases kill a mob that has been up since zone init. They do not respawn() it first: a
-- mob respawned away from its roam region walks home and is despawned with a fixed 60s timer.

describe('Zenith mob level and respawn', function()
    local levelCases =
    {
        { zone = xi.zone.BATALLIA_DOWNS,       name = 'Orcish_Beastrider', min = 33, max = 36 },
        { zone = xi.zone.SAUROMUGUE_CHAMPAIGN, name = 'Goblin_Smithy',     min = 33, max = 36 },
        { zone = xi.zone.PALBOROUGH_MINES,     name = 'Young_Quadav',      min = 14, max = 18 },
    }

    local respawnCases =
    {
        { zone = xi.zone.WEST_RONFAURE,   name = 'Wild_Rabbit',   respawn = 300 },
        { zone = xi.zone.GHELSBA_OUTPOST, name = 'Ghelsba_Pugil', respawn = 480 },
    }

    for _, case in ipairs(levelCases) do
        it(string.format('spawns %s at level %d-%d', case.name, case.min, case.max), function()
            local player = xi.test.world:spawnPlayer({ zone = case.zone })
            local mob    = player.entities:get(case.name)

            -- several lives, since the level is rolled on every spawn
            for _ = 1, 5 do
                mob:respawn()

                local level = mob:getMainLvl()
                assert(level >= case.min and level <= case.max,
                    string.format('%s spawned at level %d, expected %d-%d', case.name, level, case.min, case.max))
            end
        end)
    end

    for _, case in ipairs(respawnCases) do
        it(string.format('respawns %s after %ds', case.name, case.respawn), function()
            local player = xi.test.world:spawnPlayer({ zone = case.zone })

            local target = nil
            for _, mob in ipairs(player:getZone():queryEntitiesByName(case.name)) do
                if mob:isSpawned() then
                    target = mob
                    break
                end
            end

            assert(target, string.format('precondition: no %s is up', case.name))

            local mob = player.entities:get(target:getID())
            mob:setUnkillable(false) -- other files leave the shared rabbit unkillable
            player:claimAndKillMob(mob, { waitForDespawn = true })
            assert(not mob:isSpawned(), string.format('precondition: %s is still spawned after the kill', case.name))

            local remaining = mob:getRespawnTime()
            assert(remaining <= case.respawn and remaining > case.respawn - 60,
                string.format('%s respawns in %ds, expected about %ds', case.name, remaining, case.respawn))
        end)
    end
end)
