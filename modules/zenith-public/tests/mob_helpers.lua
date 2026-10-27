-- ZenithXI mob helpers (modules/zenith-public/lua/1-enum/zxi/mobHelpers.lua).
--
-- zxi.mobHelpers has no LSB counterpart. getRespawnVarName builds the server var key that
-- hnm_respawn_windows.lua and nm_lottery_cooldown.lua save respawn times under, so changing its format
-- orphans every saved timer. zoneInitReposition culls or moves spawns from a mob list
-- (mob_reposition_template.lua). The reposition cases use a stand-in zone and stub DespawnMob and
-- DisallowRespawn, so no real spawn is touched.

describe('Zenith mob helpers', function()
    local despawned
    local disallowed

    local function helpers()
        assert(zxi and zxi.mobHelpers, 'zxi.mobHelpers is not loaded (mobHelpers.lua)')

        return zxi.mobHelpers
    end

    -- Stand-in for a CBaseEntity: records where it was moved to
    local function fakeMob(id)
        local mob = { id = id }

        function mob:getID()
            return self.id
        end

        function mob:setPos(x, y, z, rot)
            self.pos = { x = x, y = y, z = z, rot = rot }
        end

        function mob:setSpawn(x, y, z, rot)
            self.spawn = { x = x, y = y, z = z, rot = rot }
        end

        return mob
    end

    local function fakeZone(name, count)
        local mobs = {}
        for i = 1, count do
            mobs[i] = fakeMob(1000 + i)
        end

        local zone = {}
        function zone:queryEntitiesByName(query)
            if query == name then
                return mobs
            end

            return {}
        end

        return zone, mobs
    end

    local function idSet(ids)
        local set = {}
        for _, id in ipairs(ids) do
            set[id] = true
        end

        return set
    end

    before_each(function()
        despawned  = {}
        disallowed = {}

        stub('DespawnMob', function(id)
            table.insert(despawned, id)
        end)

        stub('DisallowRespawn', function(id, disallow)
            if disallow then
                table.insert(disallowed, id)
            end
        end)
    end)

    it('names the respawn var after the mob name and ID', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE })
        local mob    = player.entities:get('Wild_Rabbit')

        local expected = string.format('[Respawn]Wild_Rabbit_%d', mob:getID())
        local actual   = helpers().getRespawnVarName(mob)

        assert(actual == expected, string.format('expected %s, got %s', expected, tostring(actual)))
    end)

    it('builds the same key from a name and an ID', function()
        local actual = helpers().getRespawnVarName('Orcish_Overlord', 17391805)

        assert(actual == '[Respawn]Orcish_Overlord_17391805', string.format('expected [Respawn]Orcish_Overlord_17391805, got %s', tostring(actual)))
    end)

    it('returns nil for a missing mob', function()
        local actual = helpers().getRespawnVarName(nil)

        assert(actual == nil, string.format('expected nil, got %s', tostring(actual)))
    end)

    it('culls every spawn when the limit is 0', function()
        local zone, mobs = fakeZone('Test_Mob', 3)

        helpers().zoneInitReposition(zone, { ['Test_Mob'] = { limit = 0 } })

        assert(#despawned == 3, string.format('expected 3 spawns despawned, got %d', #despawned))
        assert(#disallowed == 3, string.format('expected 3 spawns kept from respawning, got %d', #disallowed))

        local culled = idSet(disallowed)
        for _, mob in ipairs(mobs) do
            assert(culled[mob:getID()], string.format('spawn %d can still respawn', mob:getID()))
        end
    end)

    it('keeps the first n spawns when the limit is a number', function()
        local zone, mobs = fakeZone('Test_Mob', 5)

        helpers().zoneInitReposition(zone, { ['Test_Mob'] = { limit = 2 } })

        local culled = idSet(disallowed)
        for idx, mob in ipairs(mobs) do
            if idx <= 2 then
                assert(not culled[mob:getID()], string.format('spawn %d is within the limit but was culled', idx))
            else
                assert(culled[mob:getID()], string.format('spawn %d is past the limit but can still respawn', idx))
            end
        end

        assert(#despawned == 3, string.format('expected 3 spawns despawned, got %d', #despawned))
    end)

    it('keeps only the listed spawns when the limit is a list', function()
        local zone, mobs = fakeZone('Test_Mob', 5)

        -- 9 is out of range and must be ignored
        helpers().zoneInitReposition(zone, { ['Test_Mob'] = { limit = { 2, 4, 9 } } })

        local culled = idSet(disallowed)
        for idx, mob in ipairs(mobs) do
            local kept = idx == 2 or idx == 4
            assert(kept == not culled[mob:getID()], string.format('spawn %d: expected kept = %s', idx, tostring(kept)))
        end

        assert(#disallowed == 3, string.format('expected 3 spawns culled, got %d', #disallowed))
    end)

    it('moves a spawn that has a position override', function()
        local zone, mobs = fakeZone('Test_Mob', 2)

        helpers().zoneInitReposition(zone,
        {
            ['Test_Mob'] =
            {
                limit = 2,
                pos   = { [2] = { x = 10, y = -2, z = 30, rot = 64 } },
            },
        })

        local moved = mobs[2]
        assert(moved.pos and moved.spawn, 'spawn 2 has a position override but was not moved')
        assert(moved.spawn.x == 10 and moved.spawn.y == -2 and moved.spawn.z == 30 and moved.spawn.rot == 64,
            string.format('spawn 2 moved to %s, %s, %s rot %s', tostring(moved.spawn.x), tostring(moved.spawn.y), tostring(moved.spawn.z), tostring(moved.spawn.rot)))
        assert(mobs[1].spawn == nil, 'spawn 1 has no override but was moved')
        assert(#despawned == 0, string.format('expected nothing despawned, got %d', #despawned))
    end)

    it('does nothing when the mob list is not a table', function()
        local zone = fakeZone('Test_Mob', 2)

        helpers().zoneInitReposition(zone, nil)

        assert(#despawned == 0 and #disallowed == 0, 'an invalid mob list still culled spawns')
    end)
end)
