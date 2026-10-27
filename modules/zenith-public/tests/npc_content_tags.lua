-- ZenithXI NPC content tags (modules/zenith-public/lua/3-complete/npc/npcContentTags.lua).
--
-- With RESTRICT_CONTENT on, the engine hides an NPC whose yaml `content:` tag is disabled (moves it
-- to 0, 0, 0 with status DISAPPEAR) while the zone loads. The module re-tags 29 NPCs from each
-- zone's Zone.onInitialize: Guild Point NPCs (yaml `rotz`) follow ENABLE_COP, Crafter Point NPCs
-- (yaml `rov`) follow ENABLE_SOA, and Trust NPCs and Explorer Moogles are never hidden. A hidden NPC
-- it should show is put back at its yaml `at` position.
--
-- A zone loads once per run (in xi_test when a player first enters it, which may be another
-- file's case), so the cases call the module's applyContentTags on its own table for Southern
-- San d'Oria (read from the zone's onInitialize override chain) after changing the settings,
-- the way the zone load would. Alivatand (17719548) is a Guild Point NPC, Gondebaud
-- (17719985) a Trust NPC. Ore_Guzzler and Luren are the Northern San d'Oria Crafter Point NPCs
-- (yaml `rov`) whose ids LSB shifted in d06897cc4d; they are found by name here, so those cases
-- check that the NPC with that name is gated, whatever its id. The module falls back to the
-- zone's only NPC with an entry's name when the id no longer matches, and one case feeds it a
-- stale id. The last case pins the module's ids, positions and names to the zone data.

describe('Zenith NPC content tags', function()
    local alivatandId = 17719548
    local gondebaudId = 17719985

    -- The value the zones loaded with, before any case overrides it
    local restrictAtLoad = xi.settings.main.RESTRICT_CONTENT

    -- Zone script names the module overrides, as in xi.zones
    local taggedZones =
    {
        'Southern_San_dOria', 'Northern_San_dOria', 'Bastok_Mines', 'Bastok_Markets', 'Port_Bastok', 'Metalworks',
        'Windurst_Waters', 'Port_Windurst', 'Windurst_Woods', 'RuLude_Gardens', 'Selbina', 'Mhaura',
    }

    -- Walks a zone's onInitialize override chain to the module's override and returns its
    -- applyContentTags function and NPC table, or nil when the module is not loaded
    local function moduleOverride(zoneName)
        local fn = xi.zones[zoneName] and xi.zones[zoneName].Zone and xi.zones[zoneName].Zone.onInitialize

        while type(fn) == 'function' do
            local upvalues = {}
            local index    = 1

            while true do
                local name, value = debug.getupvalue(fn, index)
                if name == nil then
                    break
                end

                upvalues[name] = value
                index = index + 1
            end

            if
                type(upvalues.applyContentTags) == 'function' and
                type(upvalues.npcs) == 'table'
            then
                return upvalues.applyContentTags, upvalues.npcs
            end

            fn = rawget(getfenv(fn), 'super')
        end

        return nil
    end

    -- The function at the bottom of the chain, which should be the zone script's own
    local function baseOnInitialize(zoneName)
        local fn = xi.zones[zoneName].Zone.onInitialize

        while rawget(getfenv(fn), 'super') do
            fn = rawget(getfenv(fn), 'super')
        end

        return fn
    end

    local function applySouthernSandoria()
        local apply, npcs = moduleOverride('Southern_San_dOria')
        assert(apply, 'the npcContentTags override is not on Southern San d\'Oria\'s Zone.onInitialize')

        apply(npcs, GetZone(xi.zone.SOUTHERN_SAN_DORIA))
    end

    local function applyNorthernSandoria()
        local apply, npcs = moduleOverride('Northern_San_dOria')
        assert(apply, 'the npcContentTags override is not on Northern San d\'Oria\'s Zone.onInitialize')

        apply(npcs, GetZone(xi.zone.NORTHERN_SAN_DORIA))
    end

    -- What the engine does to an NPC whose content tag is disabled
    local function engineHide(npc)
        npc:setStatus(xi.status.DISAPPEAR)
        npc:setPos(0, 0, 0)
    end

    local function isAt(npc, x, y, z)
        return math.abs(npc:getXPos() - x) < 0.01 and
            math.abs(npc:getYPos() - y) < 0.01 and
            math.abs(npc:getZPos() - z) < 0.01
    end

    -- NPCs are shared by every case and file: put the ones this file moves back where they were
    local saved = {}

    local function track(npc)
        if saved[npc:getID()] == nil then
            saved[npc:getID()] = { x = npc:getXPos(), y = npc:getYPos(), z = npc:getZPos(), status = npc:getStatus() }
        end
    end

    -- The Northern San d'Oria Crafter Point NPCs and their yaml `at` positions
    local crafterPointNpcs =
    {
        { name = 'Ore_Guzzler', x = -180.0,  y = 12.0, z = 143.0 },
        { name = 'Luren',       x = -171.71, y = 12.0, z = 258.7 },
    }

    -- Enters Northern San d'Oria (loading it) and returns the plain NPC with that name, tracked
    local function northernSandoriaNpc(name)
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.NORTHERN_SAN_DORIA })
        local entity = player.entities:get(name)
        local npc    = GetNPCByID(entity:getID())
        assert(npc and npc:getName() == name, string.format('precondition: Northern San d\'Oria has an NPC named %s', name))

        track(npc)

        return npc
    end

    before_each(function()
        -- xi_test loads a zone, running its Zone.onInitialize, when a player first enters it.
        -- Load both San d'Oria zones before the settings change, or the engine and the module
        -- hide NPCs at load and the saved positions are the origin.
        xi.test.world:spawnPlayer({ zone = xi.zone.NORTHERN_SAN_DORIA })
        xi.test.world:spawnPlayer({ zone = xi.zone.SOUTHERN_SAN_DORIA })

        local alivatand = GetNPCByID(alivatandId)
        local gondebaud = GetNPCByID(gondebaudId)
        assert(alivatand and alivatand:getName() == 'Alivatand', 'precondition: 17719548 is Alivatand')
        assert(gondebaud and gondebaud:getName() == 'Gondebaud', 'precondition: 17719985 is Gondebaud')

        track(alivatand)
        track(gondebaud)

        xi.test.world:setSetting('main.RESTRICT_CONTENT', 1)
    end)

    after_each(function()
        for npcId, state in pairs(saved) do
            local npc = GetNPCByID(npcId)
            npc:setPos(state.x, state.y, state.z)
            npc:setStatus(state.status)
        end

        saved = {}
    end)

    it('hides a Guild Point NPC when Chains of Promathia is off', function()
        xi.test.world:setSetting('main.ENABLE_ROTZ', 1)
        xi.test.world:setSetting('main.ENABLE_COP', 0)

        applySouthernSandoria()

        local npc = GetNPCByID(alivatandId)
        assert(npc:getStatus() == xi.status.DISAPPEAR, string.format('expected Alivatand hidden (status %d), got status %d', xi.status.DISAPPEAR, npc:getStatus()))
        assert(isAt(npc, 0, 0, 0), 'Alivatand was not moved to the origin')
    end)

    it('puts a Guild Point NPC back when only Rise of the Zilart is off', function()
        xi.test.world:setSetting('main.ENABLE_ROTZ', 0)
        xi.test.world:setSetting('main.ENABLE_COP', 1)

        -- The engine hid Alivatand for its yaml tag, rotz
        local npc = GetNPCByID(alivatandId)
        engineHide(npc)

        applySouthernSandoria()

        assert(npc:getStatus() == xi.status.NORMAL, string.format('expected Alivatand shown (status %d), got status %d', xi.status.NORMAL, npc:getStatus()))
        assert(isAt(npc, -179.458, -1.0, 15.857), 'Alivatand was not put back at its yaml position')
    end)

    it('puts a Trust NPC back when Trust quests are off', function()
        xi.test.world:setSetting('main.ENABLE_TRUST_QUESTS', 0)

        -- The engine hid Gondebaud for its yaml tag, trust_quests
        local npc = GetNPCByID(gondebaudId)
        engineHide(npc)

        applySouthernSandoria()

        assert(npc:getStatus() == xi.status.NORMAL, string.format('expected Gondebaud shown (status %d), got status %d', xi.status.NORMAL, npc:getStatus()))
        assert(isAt(npc, 123.754, 0.0, 92.125), 'Gondebaud was not put back at its yaml position')
    end)

    it('hides the Northern San d\'Oria Crafter Point NPCs when Seekers of Adoulin is off', function()
        xi.test.world:setSetting('main.ENABLE_ROV', 1)
        xi.test.world:setSetting('main.ENABLE_SOA', 0)

        local npcs = {}
        for _, row in ipairs(crafterPointNpcs) do
            npcs[row.name] = northernSandoriaNpc(row.name)
        end

        applyNorthernSandoria()

        for _, row in ipairs(crafterPointNpcs) do
            local npc = npcs[row.name]
            assert(npc:getStatus() == xi.status.DISAPPEAR, string.format('expected %s (%d) hidden (status %d), got status %d', row.name, npc:getID(), xi.status.DISAPPEAR, npc:getStatus()))
            assert(isAt(npc, 0, 0, 0), string.format('%s (%d) was not moved to the origin', row.name, npc:getID()))
        end
    end)

    it('puts the Northern San d\'Oria Crafter Point NPCs back when only Rhapsodies of Vana\'diel is off', function()
        xi.test.world:setSetting('main.ENABLE_ROV', 0)
        xi.test.world:setSetting('main.ENABLE_SOA', 1)

        -- The engine hid them for their yaml tag, rov
        local npcs = {}
        for _, row in ipairs(crafterPointNpcs) do
            npcs[row.name] = northernSandoriaNpc(row.name)
            engineHide(npcs[row.name])
        end

        applyNorthernSandoria()

        for _, row in ipairs(crafterPointNpcs) do
            local npc = npcs[row.name]
            assert(npc:getStatus() == xi.status.NORMAL, string.format('expected %s (%d) shown (status %d), got status %d', row.name, npc:getID(), xi.status.NORMAL, npc:getStatus()))
            assert(isAt(npc, row.x, row.y, row.z), string.format('%s (%d) was not put back at its yaml position', row.name, npc:getID()))
        end
    end)

    it('finds an NPC by its name when its id has shifted', function()
        xi.test.world:setSetting('main.ENABLE_ROV', 1)
        xi.test.world:setSetting('main.ENABLE_SOA', 0)

        local oreGuzzler = northernSandoriaNpc('Ore_Guzzler')
        local luren      = northernSandoriaNpc('Luren')
        local lurenState = luren:getStatus()

        -- The id the table held for Ore_Guzzler before d06897cc4d, which is Luren's now
        local staleId = luren:getID()
        assert(oreGuzzler:getID() ~= staleId, 'precondition: Ore_Guzzler and Luren have different ids')

        local apply = moduleOverride('Northern_San_dOria')
        assert(apply, 'the npcContentTags override is not on Northern San d\'Oria\'s Zone.onInitialize')

        local staleTable =
        {
            [staleId] = { name = 'Ore_Guzzler', tag = 'SOA', x = -180.0, y = 12.0, z = 143.0, status = xi.status.NORMAL },
        }

        apply(staleTable, GetZone(xi.zone.NORTHERN_SAN_DORIA))

        assert(oreGuzzler:getStatus() == xi.status.DISAPPEAR, string.format('expected Ore_Guzzler (%d) hidden through its stale id %d, got status %d', oreGuzzler:getID(), staleId, oreGuzzler:getStatus()))
        assert(luren:getStatus() == lurenState, string.format('Luren (%d) sits at the stale id and was changed (status %d, was %d)', staleId, luren:getStatus(), lurenState))
    end)

    it('matches every NPC it re-tags to the loaded zone data', function()
        -- With the shipped RESTRICT_CONTENT = 0 nothing was hidden at load, so every NPC still
        -- stands at its yaml position
        assert(restrictAtLoad == 0, 'precondition: the zones loaded with RESTRICT_CONTENT = 0')

        local problems = {}
        local checked  = 0

        for _, zoneName in ipairs(taggedZones) do
            xi.test.world:spawnPlayer({ zone = xi.zone[string.upper(zoneName)] })

            local apply, npcs = moduleOverride(zoneName)

            if not apply then
                table.insert(problems, string.format('%s: no npcContentTags override on Zone.onInitialize', zoneName))
            else
                local source = debug.getinfo(baseOnInitialize(zoneName), 'S').source
                if not source:find('zones/' .. zoneName .. '/Zone.lua', 1, true) then
                    table.insert(problems, string.format('%s: the override is not on the zone script\'s onInitialize (%s)', zoneName, source))
                end

                for npcId, entry in pairs(npcs) do
                    local npc = GetNPCByID(npcId)
                    checked   = checked + 1

                    if npc == nil then
                        table.insert(problems, string.format('%s: NPC %d is gone', zoneName, npcId))
                    elseif npc:getName() ~= entry.name then
                        table.insert(problems, string.format('%s: NPC %d is %s, the module expects %s', zoneName, npcId, npc:getName(), entry.name))
                    elseif not isAt(npc, entry.x, entry.y, entry.z) then
                        table.insert(problems, string.format('%s: %s (%d) is at %.3f, %.3f, %.3f, the module puts it at %.3f, %.3f, %.3f',
                            zoneName, entry.name, npcId, npc:getXPos(), npc:getYPos(), npc:getZPos(), entry.x, entry.y, entry.z))
                    end
                end
            end
        end

        assert(#problems == 0, 'LSB changed the zone data, re-check npcContentTags: ' .. table.concat(problems, '; '))
        assert(checked == 29, string.format('expected the module to re-tag 29 NPCs, found %d', checked))
    end)
end)
