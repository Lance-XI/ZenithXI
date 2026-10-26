-- ZenithXI disabled NPCs (modules/zenith-public/lua/3-complete/npc/npcDisable.lua).
--
-- From xi.server.onServerStart, after every zone loaded, the module sets every NPC whose script
-- name is on its list to xi.status.INVISIBLE in every zone this process hosts (Magian Moogles,
-- Survival Guides, Gobbie Mystery NPCs, Symphonic Curators and the like), plus the Treasure_Coffer
-- one id above each Gobbie Mystery NPC. LSB leaves them visible.
--
-- xi_test loads a zone only when a player first enters it, after onServerStart, so the server
-- start pass sees no zones here. The cases load Southern San d'Oria and call the module's own
-- per-zone function, read from the onServerStart override chain. In that zone Symphonic_Curator
-- (17719442) and Mystrix (17719641) are on the list, 17719642 is Mystrix's Treasure_Coffer and
-- Alivatand (17719548) is not on the list.

describe('Zenith disabled NPCs', function()
    local curatorId   = 17719442
    local mystrixId   = 17719641
    local cofferId    = 17719642
    local alivatandId = 17719548

    -- Walks the xi.server.onServerStart override chain to the module's per-zone function,
    -- or nil when the module is not loaded
    local function moduleDisableZoneNpcs()
        local fn = xi.server.onServerStart

        while type(fn) == 'function' do
            local index = 1

            while true do
                local name, value = debug.getupvalue(fn, index)
                if name == nil then
                    break
                end

                if name == 'disableZoneNpcs' and type(value) == 'function' then
                    return value
                end

                index = index + 1
            end

            fn = rawget(getfenv(fn), 'super')
        end

        return nil
    end

    local function disableSouthernSandoria()
        local disableZoneNpcs = moduleDisableZoneNpcs()
        assert(disableZoneNpcs, 'the npcDisable pass is not hooked into xi.server.onServerStart')

        disableZoneNpcs(GetZone(xi.zone.SOUTHERN_SAN_DORIA))
    end

    local function status(npcId)
        local npc = GetNPCByID(npcId)

        return npc and npc:getStatus()
    end

    -- NPCs are shared by every case and file: put the statuses this file changes back
    local saved = {}

    before_each(function()
        -- Loads the zone, which also runs its Zone.onInitialize
        xi.test.world:spawnPlayer({ zone = xi.zone.SOUTHERN_SAN_DORIA })

        local expected =
        {
            [curatorId]   = 'Symphonic_Curator',
            [mystrixId]   = 'Mystrix',
            [cofferId]    = 'Treasure_Coffer',
            [alivatandId] = 'Alivatand',
        }

        for npcId, name in pairs(expected) do
            local npc = GetNPCByID(npcId)
            assert(npc and npc:getName() == name, string.format('precondition: %d is %s', npcId, name))

            saved[npcId] = npc:getStatus()
            npc:setStatus(xi.status.NORMAL) -- as the zone data loads them
        end
    end)

    after_each(function()
        for npcId, savedStatus in pairs(saved) do
            local npc = GetNPCByID(npcId)

            if npc then
                npc:setStatus(savedStatus)
            end
        end
    end)

    it('hides the listed NPCs', function()
        disableSouthernSandoria()

        assert(status(curatorId) == xi.status.INVISIBLE, string.format('expected Symphonic_Curator invisible (status %d), got status %d', xi.status.INVISIBLE, status(curatorId)))
        assert(status(mystrixId) == xi.status.INVISIBLE, string.format('expected Mystrix invisible (status %d), got status %d', xi.status.INVISIBLE, status(mystrixId)))
    end)

    it('hides the Treasure Coffer next to a Gobbie Mystery NPC', function()
        disableSouthernSandoria()

        assert(status(cofferId) == xi.status.INVISIBLE, string.format('expected Mystrix\'s Treasure_Coffer invisible (status %d), got status %d', xi.status.INVISIBLE, status(cofferId)))
    end)

    it('leaves NPCs that are not on the list alone', function()
        disableSouthernSandoria()

        assert(status(alivatandId) == xi.status.NORMAL, string.format('expected Alivatand visible (status %d), got status %d', xi.status.NORMAL, status(alivatandId)))
    end)
end)
