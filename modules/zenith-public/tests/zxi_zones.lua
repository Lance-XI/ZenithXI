-- ZenithXI zone name enum (modules/zenith-public/lua/1-enum/zxi/zones.lua).
--
-- zxi.zone maps a zone's script folder name to its ID and zxi.zoneName maps it back. Modules build
-- xi.zones.<name> paths and scripts/zones/<name>/ file names from it (vendorOverrides,
-- claim_shield, npcDisable, crabBluntWeakness), so every name must match the zone's real name.
-- LSB has no such table. A zone LSB renames or adds shows up here as a mismatch.

describe('Zenith zone name enum', function()
    -- Residential areas have no zone of their own, so the enum leaves them out on purpose
    local residential = set{ 199, 214, 219 }

    local function assertLoaded()
        assert(zxi ~= nil and type(zxi.zone) == 'table' and type(zxi.zoneName) == 'table', 'zxi.zone / zxi.zoneName are not defined: the zone name enum module did not load')
    end

    it('names every running zone by its real name, in both directions', function()
        assertLoaded()

        -- xi_test starts a zone when a player enters it: one of each naming style
        -- (plain, [S], hyphen, apostrophe dropped)
        for _, zoneId in ipairs({ xi.zone.WEST_RONFAURE, xi.zone.SOUTHERN_SAN_DORIA_S, xi.zone.RIVERNE_SITE_B01, xi.zone.RULUDE_GARDENS }) do
            xi.test.world:spawnPlayer({ zone = zoneId })
            assert(GetZone(zoneId) ~= nil, string.format('precondition: zone %d is running', zoneId))
        end

        local checked    = 0
        local mismatches = {}

        -- Zone 0 is the engine's placeholder for "no zone", not a real zone
        for zoneId = 1, 299 do
            local zone = GetZone(zoneId)

            if zone then
                checked = checked + 1
                local name = zone:getName()

                if zxi.zoneName[zoneId] ~= name or zxi.zone[name] ~= zoneId then
                    table.insert(mismatches, string.format('%d is %s, enum says %s / %s', zoneId, name, tostring(zxi.zoneName[zoneId]), tostring(zxi.zone[name])))
                end
            end
        end

        assert(checked > 0, 'precondition: no zones are running')
        assert(#mismatches == 0, string.format('%d of %d zones disagree with zxi.zone: %s', #mismatches, checked, table.concat(mismatches, '; ')))
    end)

    it('covers every LSB zone ID and names its xi.zones script table', function()
        assertLoaded()

        local missing = {}

        for enumName, zoneId in pairs(xi.zone) do
            if zoneId > 0 and zoneId < 300 and not residential[zoneId] then
                local name = zxi.zoneName[zoneId]

                if name == nil then
                    table.insert(missing, string.format('%s (%d) has no name', enumName, zoneId))
                elseif xi.zones[name] == nil and GetZone(zoneId) ~= nil then
                    table.insert(missing, string.format('%s (%d) is %s, but xi.zones.%s does not exist', enumName, zoneId, name, name))
                end
            end
        end

        assert(#missing == 0, string.format('zxi.zoneName is out of date: %s', table.concat(missing, '; ')))
    end)

    -- xi_test only starts the zones its players visit, so the first case sees a handful. LSB's
    -- xi.zone keys are the zone names upper-cased ('Southern_San_dOria_[S]' is SOUTHERN_SAN_DORIA_S),
    -- which checks every entry, running or not.
    it('spells every name the way LSB spells the zone', function()
        assertLoaded()

        local enumNameOf = {}
        for enumName, zoneId in pairs(xi.zone) do
            enumNameOf[zoneId] = enumName
        end

        local wrong = {}

        for name, zoneId in pairs(zxi.zone) do
            local expected = enumNameOf[zoneId]
            local actual   = string.upper(name):gsub('%-', '_'):gsub('_%[(%w+)%]$', '_%1')

            -- '49' and '286' are placeholders for IDs with no zone (LSB: NONE, UNUSED_286)
            if expected ~= nil and name ~= tostring(zoneId) and actual ~= expected then
                table.insert(wrong, string.format('%d: %s reads as %s, LSB calls it %s', zoneId, name, actual, expected))
            end
        end

        table.sort(wrong)
        assert(#wrong == 0, string.format('%d zxi.zone names differ from LSB: %s', #wrong, table.concat(wrong, '; ')))
    end)
end)
