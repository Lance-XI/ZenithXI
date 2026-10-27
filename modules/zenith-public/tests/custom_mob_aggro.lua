-- ZenithXI custom mob aggro (modules/zenith-public/lua/3-complete/mobs/customMobAggro.lua).
--
-- In LSB these mobs are passive (their yaml templates have no `aggressive` behaviour). The module's
-- Zone.onInitialize override calls setAggressive(true) on them, so they attack a player who comes
-- close. There is no getter for a mob's aggro flag, so each case walks a level 1 player up to the
-- mob, in front of it, and checks that it engages. Setup follows LSB's scripts/tests/systems/aggro_los.lua:
-- the mob roams past its post-spawn neutral window first.
-- Boulder_Eater (Gustav Tunnel) is not covered: that zone is disabled in the scratch database
-- (zone_settings zoneip 0), so its Zone.onInitialize never runs there.

describe('Zenith custom mob aggro', function()
    local aggressiveMobs =
    {
        { zone = xi.zone.INNER_HORUTOTO_RUINS, name = 'Deathwatch_Beetle' },
        { zone = xi.zone.CRAWLERS_NEST,        name = 'Vespo'             },
        { zone = xi.zone.CRAWLERS_NEST,        name = 'Olid_Funguar'      },
    }

    for _, entry in ipairs(aggressiveMobs) do
        it(string.format('makes %s aggro a player who walks up to it', entry.name), function()
            local player = xi.test.world:spawnPlayer({ zone = entry.zone, job = xi.job.WAR, level = 1 })
            local mob    = player.entities:get(entry.name)

            mob:respawn()

            for _ = 1, 10 do
                xi.test.world:skipTime(5)
                xi.test.world:tickEntity(mob)
            end

            assert(mob:isSpawned() and not mob:isEngaged(), string.format('precondition: %s is not up and idle', entry.name))

            local pos = mob:getPos()
            local x   = pos.x + 2
            local z   = pos.z

            mob:lookAt(x, pos.y, z)
            player.actions:move(x, pos.y, z)

            for _ = 1, 3 do
                if mob:isEngaged() then
                    break
                end

                xi.test.world:skipTime(1)
                xi.test.world:tickEntity(mob)
            end

            assert(mob:isEngaged(), string.format('%s did not aggro a level 1 player standing in front of it', entry.name))
        end)
    end
end)
