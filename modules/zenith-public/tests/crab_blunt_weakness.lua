-- ZenithXI crab blunt weakness (modules/zenith-public/lua/3-complete/mobs/crabBluntWeakness.lua).
--
-- LSB gives zone crabs only what their species and template carry. The module adds +2500 IMPACT_SDT
-- (25% more blunt damage taken) and +1250 HTH_SDT (12.5% more H2H) to every family CRAB mob, from a
-- SPAWN listener so it survives respawns without stacking. Snipper (Valkurm Dunes) and River_Crab
-- (North Gustaberg) have no physical resists in their yaml (0 -> 2500 / 1250); Cancer's yaml has
-- -5000 for both (-> -2500 / -3750). River_Crab's level is re-rolled by mobLevelAndRespawn.lua's own
-- SPAWN listener, which recalculates stats, so it checks the weakness lands after that one.
--
-- The module walks every zone from xi.server.onServerStart. xi_test loads zones lazily, after that
-- has run, so each case loads the zone, then runs the module's per-zone pass (weakenZoneCrabs, found
-- as an upvalue of its onServerStart override) on it, as onServerStart does on a full server.

describe('Zenith crab blunt weakness', function()
    local crabs =
    {
        { zone = xi.zone.VALKURM_DUNES,   name = 'Snipper',    blunt = 2500,  h2h = 1250  },
        { zone = xi.zone.KUFTAL_TUNNEL,   name = 'Cancer',     blunt = -2500, h2h = -3750 },
        { zone = xi.zone.NORTH_GUSTABERG, name = 'River_Crab', blunt = 2500,  h2h = 1250  },
    }

    -- The module's per-zone pass, from its xi.server.onServerStart override in the override chain
    local function crabZonePass()
        local fn = xi.server.onServerStart
        while type(fn) == 'function' do
            for i = 1, 60 do
                local name, value = debug.getupvalue(fn, i)
                if name == nil then
                    break
                end

                if name == 'weakenZoneCrabs' then
                    return value
                end
            end

            fn = rawget(getfenv(fn), 'super')
        end

        return nil
    end

    local function weakenedCrab(crab)
        local player = xi.test.world:spawnPlayer({ zone = crab.zone })
        local mob    = player.entities:get(crab.name)
        assert(mob:getFamily() == xi.mobFamily.CRAB, string.format('precondition: %s is not family CRAB', crab.name))

        local pass = crabZonePass()
        assert(pass, 'crabBluntWeakness.lua has no override on xi.server.onServerStart')
        pass(GetZone(crab.zone))

        return mob
    end

    local function checkWeakness(mob, crab)
        local blunt = mob:getMod(xi.mod.IMPACT_SDT)
        local h2h   = mob:getMod(xi.mod.HTH_SDT)

        assert(blunt == crab.blunt, string.format('%s: expected IMPACT_SDT %d, got %d', crab.name, crab.blunt, blunt))
        assert(h2h == crab.h2h, string.format('%s: expected HTH_SDT %d, got %d', crab.name, crab.h2h, h2h))
    end

    for _, crab in ipairs(crabs) do
        it(string.format('makes %s take more blunt and hand-to-hand damage', crab.name), function()
            local mob = weakenedCrab(crab)

            mob:respawn()

            checkWeakness(mob, crab)
        end)
    end

    it('does not stack the weakness over several respawns', function()
        local crab = crabs[1]
        local mob  = weakenedCrab(crab)

        for _ = 1, 3 do
            mob:respawn()
        end

        checkWeakness(mob, crab)
    end)
end)
