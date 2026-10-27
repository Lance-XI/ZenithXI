-- ZenithXI HNM respawn windows (modules/zenith-public/lua/3-complete/mobs/hnm_respawn_windows.lua).
--
-- LSB rolls a plain random respawn in each HNM's onMobDespawn (Simurgh 1-2h, Serket 21-24h,
-- Vrtra 3-5 days) and forgets it on a reboot. The module replaces it with base hours plus one of
-- seven windows, rolled for every respawn (Simurgh and Serket 21h + 0-6 x 5 min, Vrtra 71h + 0-6 x
-- 10 min), saves the end time in the server var zxi.mobHelpers.getRespawnVarName(mob)
-- ('[Respawn]<name>_<id>'), and on Zone.onInitialize restores a saved time, spawns the NM if it has
-- passed, or rolls a fresh one.
-- The special cases checked here:
-- - Beastmen kings (Qulun Dome: Diamond Quadav / Za'Dha Adamantking): LSB's NQ despawn already rolls
--   NQ or HQ and keeps the [PH] kill count. The module follows that roll, so exactly one of the two
--   gets a timer, and on a reboot the one scheduled last comes back. Both rolls are stubbed.
-- - Kreutzet (wind), King Vinegarroon (earth), Dosetsu Tree (thunder) and Ereshkigal (placeholder
--   Etemmu): a timer never spawns them; the window only opens LSB's own check.
-- - Xolotl keeps LSB's next-night respawn when he despawns at dawn without being killed.
-- - Lumber Jack despawning unkilled gives Weeping Willow LSB's 30 minutes, not a full window.
-- - NMs the engine spawns at zone load (Ocean Sahagin, Carmine Dobsonfly, Padfoot) are taken back
--   down on zone init while their saved time is still ahead.
-- - Cemetery Cherry killed: the saplings get 71h + 0-6 x 10 min instead of LSB's 60-72h timer.
-- A reboot is simulated by calling a zone's onInitialize again. Only zones whose LSB onInitialize is
-- harmless to repeat are used: Rolanberry Fields' places Voidwalker NMs and never returns on a
-- second call. Every server var a case touches is cleared in after_each.

describe('Zenith HNM respawn windows', function()
    local hnms =
    {
        { zone = xi.zone.ROLANBERRY_FIELDS,   zoneName = 'Rolanberry_Fields',   id = zones[xi.zone.ROLANBERRY_FIELDS].mob.SIMURGH,  name = 'Simurgh', hours = 21, window = 5  },
        { zone = xi.zone.GARLAIGE_CITADEL,    zoneName = 'Garlaige_Citadel',    id = zones[xi.zone.GARLAIGE_CITADEL].mob.SERKET,    name = 'Serket',  hours = 21, window = 5  },
        { zone = xi.zone.KING_RANPERRES_TOMB, zoneName = 'King_Ranperres_Tomb', id = zones[xi.zone.KING_RANPERRES_TOMB].mob.VRTRA, name = 'Vrtra',   hours = 71, window = 10 },
        { zone = xi.zone.ATTOHWA_CHASM,       zoneName = 'Attohwa_Chasm',       id = zones[xi.zone.ATTOHWA_CHASM].mob.XOLOTL,       name = 'Xolotl',  hours = 21, window = 5  },
    }

    local serket = hnms[2]

    ---@type CClientEntityPair
    local player
    local touchedVars = {}

    local function track(varName)
        touchedVars[varName] = true

        return varName
    end

    local function varNameOf(id)
        return track(zxi.mobHelpers.getRespawnVarName(GetMobByID(id)))
    end

    local function savedIn(id)
        return GetServerVariable(varNameOf(id)) - GetSystemTime()
    end

    -- Asserts that seconds is base hours plus a whole number of windows (0-6), give or take drift.
    local function assertWindowed(hnm, seconds, what)
        local base   = hnm.hours * 3600
        local window = hnm.window * 60
        local slot   = math.floor((seconds - base) / window + 0.5)
        local drift  = seconds - base - slot * window

        assert(slot >= 0 and slot <= 6 and drift >= -30 and drift <= 30,
            string.format('%s %s is %ds, expected %dh plus 0-6 windows of %d min', hnm.name, what, seconds, hnm.hours, hnm.window))
    end

    -- A live NM, with its server var cleared afterwards (respawn() itself runs onMobDespawn)
    local function freshNm(hnm)
        player = xi.test.world:spawnPlayer({ zone = hnm.zone })
        local nm = player.entities:get(hnm.id)

        nm:respawn()
        SetServerVariable(varNameOf(hnm.id), 0)

        return nm
    end

    local function rebootZone(zoneName, zoneId)
        xi.zones[zoneName].Zone.onInitialize(GetZone(zoneId))
    end

    -- Lets a despawn started by DespawnMob (3 s fade) finish
    local function settle()
        for _ = 1, 3 do
            xi.test.world:skipTime(2)
        end
    end

    -- Stand-ins for math.random / math.randomInt that always roll the lowest or highest value.
    -- math.random() with no bounds still gets a number.
    local function lowestRoll(lo, hi)
        return lo or 0
    end

    local function highestRoll(lo, hi)
        return hi or lo or 0
    end

    -- Moves past a timer and lets the spawn handler run
    local function skipAndSpawn(seconds)
        xi.test.world:skipTime(seconds)
        xi.test.world:tick(xi.tick.SPAWN)
    end

    after_each(function()
        for varName in pairs(touchedVars) do
            SetServerVariable(varName, 0)
        end
    end)

    for _, hnm in ipairs(hnms) do
        it(string.format('gives %s a windowed respawn and saves it when it despawns', hnm.name), function()
            local nm = freshNm(hnm)

            nm:despawn()

            local saved = savedIn(hnm.id)
            assert(saved > 0, string.format('%s despawned without saving its respawn time', hnm.name))
            assertWindowed(hnm, saved, 'saved respawn')
            assertWindowed(hnm, nm:getRespawnTime(), 'respawn timer')
        end)
    end

    it('rolls a new window for every respawn', function()
        local nm   = freshNm(serket)
        local roll = stub('math.random', 0)

        nm:despawn()
        local first = savedIn(serket.id)

        nm:respawn()
        roll:returnValue(6)
        nm:despawn()
        local last = savedIn(serket.id)

        assert(math.abs(first - 21 * 3600) <= 30, string.format('with the lowest roll Serket saved %ds, expected 21h (the window is not rolled per respawn)', first))
        assert(math.abs(last - (21 * 3600 + 30 * 60)) <= 30, string.format('with the highest roll Serket saved %ds, expected 21h30m (the window is not rolled per respawn)', last))
    end)

    it('restores a saved respawn time on zone init', function()
        local nm = freshNm(serket)
        nm:despawn()

        -- outside both LSB's 21-24h and the module's own 21h roll
        SetServerVariable(varNameOf(serket.id), GetSystemTime() + 50000)
        rebootZone(serket.zoneName, serket.zone)

        local remaining = nm:getRespawnTime()
        assert(remaining > 49900 and remaining <= 50000, string.format('Serket respawns in %ds after a reboot, expected the saved 50000s', remaining))
    end)

    it('spawns the NM on zone init once its saved time has passed, with no timer left to spawn it again', function()
        local nm = freshNm(serket)
        nm:despawn()
        assert(not nm:isSpawned(), 'precondition: Serket is still up after despawn()')
        assert(nm:getRespawnTime() > 0, 'precondition: Serket has no pending respawn timer after despawn()')

        SetServerVariable(varNameOf(serket.id), GetSystemTime() - 60)
        rebootZone(serket.zoneName, serket.zone)

        assert(nm:isSpawned(), 'Serket did not spawn on a reboot after its saved respawn time passed')
        assert(nm:getRespawnTime() == 0, string.format('Serket is up with a respawn timer still pending (%ds); it would be spawned again where it stands', nm:getRespawnTime()))
        nm:despawn()
    end)

    it('rolls and saves a fresh window on zone init when nothing is saved', function()
        local nm = freshNm(serket)
        nm:despawn()
        SetServerVariable(varNameOf(serket.id), 0)

        rebootZone(serket.zoneName, serket.zone)

        local saved = savedIn(serket.id)
        assert(saved > 0, 'zone init with no saved time did not save a new one')
        assertWindowed(serket, saved, 'saved respawn after zone init')
        assertWindowed(serket, nm:getRespawnTime(), 'respawn timer after zone init')
    end)

    describe('NMs the engine spawns at zone load', function()
        it('takes Ocean Sahagin back down on zone init while its saved time is ahead', function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.SEA_SERPENT_GROTTO })
            local id = GetZone(xi.zone.SEA_SERPENT_GROTTO):queryEntitiesByName('Ocean_Sahagin')[1]:getID()
            local nm = player.entities:get(id)

            nm:respawn()
            SetServerVariable(varNameOf(id), GetSystemTime() + 50000)
            rebootZone('Sea_Serpent_Grotto', xi.zone.SEA_SERPENT_GROTTO)
            settle()

            assert(not nm:isSpawned(), 'Ocean Sahagin is still up after a reboot with 50000s left on its saved respawn')
            local remaining = nm:getRespawnTime()
            assert(remaining > 49900 and remaining <= 50000, string.format('Ocean Sahagin respawns in %ds after a reboot, expected the saved 50000s', remaining))
            assert(savedIn(id) > 49900, 'taking Ocean Sahagin down on zone init changed its saved respawn')
        end)

        it('takes one Carmine Dobsonfly back down without re-timing the others', function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.RIVERNE_SITE_A01 })
            local firstId = zones[xi.zone.RIVERNE_SITE_A01].mob.CARMINE_DOBSONFLY_OFFSET
            local flies   = {}

            for i = 0, 9 do
                flies[i] = player.entities:get(firstId + i)
                if not flies[i]:isSpawned() then
                    SpawnMob(firstId + i)
                end

                SetServerVariable(varNameOf(firstId + i), 0)
            end

            SetServerVariable(varNameOf(firstId), GetSystemTime() + 50000)
            rebootZone('Riverne-Site_A01', xi.zone.RIVERNE_SITE_A01)
            settle()

            assert(not flies[0]:isSpawned(), 'Carmine Dobsonfly is still up after a reboot with 50000s left on its saved respawn')
            local remaining = flies[0]:getRespawnTime()
            assert(remaining > 49900 and remaining <= 50000, string.format('Carmine Dobsonfly respawns in %ds after a reboot, expected the saved 50000s', remaining))

            for i = 1, 9 do
                assert(flies[i]:isSpawned(), string.format('Carmine Dobsonfly %d went down on a reboot with nothing saved', i))
                assert(GetServerVariable(varNameOf(firstId + i)) == 0, string.format('taking one fly down re-timed Carmine Dobsonfly %d', i))
            end
        end)

        it('takes the Padfoots LSB spawns on zone init back down while their saved time is ahead', function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.LUFAISE_MEADOWS })
            local ids = zones[xi.zone.LUFAISE_MEADOWS].mob.PADFOOT

            for _, id in ipairs(ids) do
                SetServerVariable(varNameOf(id), GetSystemTime() + 50000)
            end

            rebootZone('Lufaise_Meadows', xi.zone.LUFAISE_MEADOWS)
            settle()

            for i, id in ipairs(ids) do
                local padfoot = GetMobByID(id)
                assert(not padfoot:isSpawned(), string.format('Padfoot %d is up after a reboot with 50000s left on its saved respawn', i))
                local remaining = padfoot:getRespawnTime()
                assert(remaining > 49900 and remaining <= 50000, string.format('Padfoot %d respawns in %ds after a reboot, expected the saved 50000s', i, remaining))
            end
        end)
    end)

    describe('beastmen NQ/HQ', function()
        local ID    = zones[xi.zone.QULUN_DOME]
        local nqId  = ID.mob.DIAMOND_QUADAV
        local hqId  = nqId + 1
        local phVar = '[PH]Za_Dha_Adamantking'

        ---@type CTestEntity
        local nq
        ---@type CTestEntity
        local hq

        before_each(function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.QULUN_DOME })
            nq     = player.entities:get(nqId)
            hq     = player.entities:get(hqId)
            assert(hq:getName() == 'ZaDha_Adamantking', string.format('precondition: %d is %s, not ZaDha_Adamantking', hqId, hq:getName()))

            -- Both down with no timer and nothing saved
            for _, nm in ipairs({ nq, hq }) do
                if nm:isSpawned() then
                    nm:despawn()
                end

                nm:setRespawnTime(0)
            end

            SetServerVariable(track(phVar), 0)
            SetServerVariable(track('[POP]Za_Dha_Adamantking'), 0)
            SetServerVariable(varNameOf(nqId), 0)
            SetServerVariable(varNameOf(hqId), 0)
        end)

        -- NQ up with two kills counted; LSB's despawn then counts the third
        local function killNq(lsbRoll, moduleRoll)
            SpawnMob(nqId)
            SetServerVariable(phVar, 2)

            local despawns = 0
            nq:addListener('DESPAWN', 'ZENITH_TEST_DESPAWNS', function()
                despawns = despawns + 1
            end)

            stub('math.randomInt', lsbRoll)
            stub('math.random', moduleRoll)
            DespawnMob(nqId)
            settle()
            nq:removeListener('ZENITH_TEST_DESPAWNS')
            assert(despawns == 1, string.format('precondition: Diamond Quadav despawned %d times, expected once', despawns))
        end

        it('schedules only the NQ when LSB brings the NQ back', function()
            -- LSB: 3 kills and a 100 roll do not pop the HQ. A roll of its own (1) would pop it.
            killNq(highestRoll, lowestRoll)

            assert(GetServerVariable(phVar) == 3, string.format('the [PH] kill count is %d after the third kill, expected 3', GetServerVariable(phVar)))
            assert(GetServerVariable(varNameOf(hqId)) == 0, 'Za\'Dha Adamantking got a respawn timer although LSB brought the NQ back (a second roll)')
            assertWindowed({ name = 'Diamond Quadav', hours = 21, window = 5 }, savedIn(nqId), 'saved respawn')

            skipAndSpawn(21 * 3600 + 40 * 60)
            assert(nq:isSpawned(), 'Diamond Quadav did not respawn after its window')
            assert(not hq:isSpawned(), 'Za\'Dha Adamantking spawned as well: both NQ and HQ were scheduled')
        end)

        it('schedules only the HQ when LSB pops the HQ', function()
            -- LSB: 3 kills and a 1 roll pop the HQ. A roll of its own (100) would not.
            killNq(lowestRoll, highestRoll)

            assert(GetServerVariable(phVar) == 2, string.format('the [PH] kill count is %d after the HQ popped, expected LSB to leave it at 2', GetServerVariable(phVar)))
            assert(GetServerVariable(varNameOf(nqId)) == 0, 'Diamond Quadav got a respawn timer although LSB popped the HQ (a second roll)')
            assertWindowed({ name = 'Za\'Dha Adamantking', hours = 21, window = 5 }, savedIn(hqId), 'saved respawn')

            skipAndSpawn(21 * 3600 + 40 * 60)
            assert(hq:isSpawned(), 'Za\'Dha Adamantking did not spawn after its window')
            assert(not nq:isSpawned(), 'Diamond Quadav spawned as well: both NQ and HQ were scheduled')
        end)

        it('restores the HQ on zone init when it was scheduled after the NQ', function()
            -- The NQ's saved time is left over from the kill that popped the HQ
            SetServerVariable(varNameOf(nqId), GetSystemTime() - 3600)
            SetServerVariable(varNameOf(hqId), GetSystemTime() + 50000)

            rebootZone('Qulun_Dome', xi.zone.QULUN_DOME)

            assert(not nq:isSpawned(), 'Diamond Quadav spawned on a reboot while Za\'Dha Adamantking was the one scheduled')
            local remaining = hq:getRespawnTime()
            assert(remaining > 49900 and remaining <= 50000, string.format('Za\'Dha Adamantking respawns in %ds after a reboot, expected the saved 50000s', remaining))
        end)
    end)

    describe('weather and placeholder NMs', function()
        it('keeps Kreutzet down after its window until wind weather', function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.CAPE_TERIGGAN })
            local id = zones[xi.zone.CAPE_TERIGGAN].mob.KREUTZET
            local nm = player.entities:get(id)

            nm:respawn()
            nm:despawn()
            assertWindowed({ name = 'Kreutzet', hours = 9, window = 30 }, savedIn(id), 'saved respawn')

            skipAndSpawn(12 * 3600 + 60)
            assert(not nm:isSpawned(), 'Kreutzet spawned on its timer without wind weather')

            player:setWeather(xi.weather.WIND)
            skipAndSpawn(160)
            assert(nm:isSpawned(), 'Kreutzet did not spawn in wind weather after its window')
        end)

        it('leaves King Vinegarroon to earth weather on zone init once its saved time has passed', function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.WESTERN_ALTEPA_DESERT })
            local id = zones[xi.zone.WESTERN_ALTEPA_DESERT].mob.KING_VINEGARROON
            local nm = player.entities:get(id)

            nm:respawn()
            nm:despawn()
            SetServerVariable(varNameOf(id), GetSystemTime() - 60)
            rebootZone('Western_Altepa_Desert', xi.zone.WESTERN_ALTEPA_DESERT)

            skipAndSpawn(60)
            assert(not nm:isSpawned(), 'King Vinegarroon spawned on a reboot without earth weather')

            player:setWeather(xi.weather.SAND_STORM)
            skipAndSpawn(60)
            assert(nm:isSpawned(), 'King Vinegarroon did not spawn in a sand storm after its window')
        end)

        it('spawns Dosetsu Tree only in thunder weather after its window', function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.QUFIM_ISLAND })
            local id = zones[xi.zone.QUFIM_ISLAND].mob.DOSETSU_TREE
            local nm = player.entities:get(id)

            nm:respawn()
            nm:despawn()
            local saved = savedIn(id)
            assertWindowed({ name = 'Dosetsu Tree', hours = 21, window = 5 }, saved, 'saved respawn')
            assert(nm:getLocalVar('respawn') == GetServerVariable(varNameOf(id)), string.format('Dosetsu Tree may spawn in thunder weather %ds from now, expected its window, %ds', nm:getLocalVar('respawn') - GetSystemTime(), saved))

            -- Qufim Island's thunder check reads GetSystemTime, which skipTime does not move. LSB's own gate is 1-2 hours.
            local clock = stub('GetSystemTime', GetSystemTime() + 3 * 3600)
            player:setWeather(xi.weather.THUNDER)
            assert(not nm:isSpawned(), 'Dosetsu Tree spawned in thunder weather before its window opened')

            player:setWeather(xi.weather.SUNSHINE)
            skipAndSpawn(22 * 3600)
            assert(not nm:isSpawned(), 'Dosetsu Tree spawned on its timer without thunder weather')

            clock:returnValue(nm:getLocalVar('respawn') + 60)
            player:setWeather(xi.weather.THUNDER)
            assert(nm:isSpawned(), 'Dosetsu Tree did not spawn in thunder weather after its window')
        end)

        it('never spawns Ereshkigal on its own timer', function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.XARCABARD })
            local id = zones[xi.zone.XARCABARD].mob.ERESHKIGAL
            local nm = player.entities:get(id)

            nm:respawn()
            nm:despawn()
            assertWindowed({ name = 'Ereshkigal', hours = 21, window = 5 }, savedIn(id), 'saved respawn')

            skipAndSpawn(21 * 3600 + 40 * 60)
            assert(not nm:isSpawned(), 'Ereshkigal spawned on its own timer instead of through its placeholder')
        end)

        it('keeps Etemmu from turning into Ereshkigal until the window opens', function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.XARCABARD })
            local id = zones[xi.zone.XARCABARD].mob.ERESHKIGAL
            local nm = player.entities:get(id)
            local ph = player.entities:get(id - 1)

            if nm:isSpawned() then
                nm:despawn()
            end

            ph:respawn()
            SetServerVariable(varNameOf(id), GetSystemTime() + 3600)

            -- The weather listener's go-ahead, already due
            ph:setLocalVar('phDespawnTime', GetSystemTime() - 1)
            xi.zones.Xarcabard.mobs.Etemmu.onMobRoam(GetMobByID(ph:getID()))
            settle()
            assert(ph:isSpawned() and not nm:isSpawned(), 'Etemmu turned into Ereshkigal before the window opened')

            SetServerVariable(varNameOf(id), GetSystemTime() - 1)
            xi.zones.Xarcabard.mobs.Etemmu.onMobRoam(GetMobByID(ph:getID()))
            settle()
            assert(nm:isSpawned(), 'Etemmu did not turn into Ereshkigal once the window opened')
            nm:despawn()
        end)
    end)

    describe('kill-dependent respawns', function()
        it('gives Xolotl LSB\'s next-night respawn when he despawns at dawn unkilled, and a window when killed', function()
            local xolotl = hnms[4]
            local nm     = freshNm(xolotl)

            -- a saved time from an earlier kill, which the dawn despawn must drop
            SetServerVariable(varNameOf(xolotl.id), GetSystemTime() + 99999)
            DespawnMob(xolotl.id)
            settle()

            assert(GetServerVariable(varNameOf(xolotl.id)) == 0, string.format('Xolotl saved a respawn %ds ahead after despawning unkilled', savedIn(xolotl.id)))
            assert(nm:isSpawned() or nm:getRespawnTime() < 3600, string.format('Xolotl respawns in %ds after despawning unkilled, expected LSB\'s next-night respawn', nm:getRespawnTime()))

            nm:respawn()
            nm:despawn()
            assertWindowed(xolotl, savedIn(xolotl.id), 'saved respawn after he was killed')
        end)

        it('gives Weeping Willow 30 minutes when Lumber Jack despawns unkilled, and a window when killed', function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.BATALLIA_DOWNS })
            local willowId   = GetZone(xi.zone.BATALLIA_DOWNS):queryEntitiesByName('Weeping_Willow')[1]:getID()
            local lumberJack = player.entities:get(willowId + 6)
            assert(lumberJack:getName() == 'Lumber_Jack', 'precondition: Lumber Jack is not Weeping Willow + 6')

            if not lumberJack:isSpawned() then
                SpawnMob(willowId + 6)
            end

            DespawnMob(willowId + 6)
            settle()
            local unkilled = savedIn(willowId)
            assert(math.abs(unkilled - 1800) <= 30, string.format('Weeping Willow respawns in %ds after Lumber Jack despawned unkilled, expected 1800s', unkilled))

            SpawnMob(willowId + 6)
            lumberJack:despawn()
            assertWindowed({ name = 'Weeping Willow', hours = 21, window = 5 }, savedIn(willowId), 'saved respawn after Lumber Jack was killed')
        end)

        it('gives the Cherry Saplings 71h + 0-6 x 10 min, not LSB\'s 60-72h timer, when Cemetery Cherry is killed', function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.KING_RANPERRES_TOMB })
            local offset   = zones[xi.zone.KING_RANPERRES_TOMB].mob.CHERRY_SAPLING_OFFSET
            local cherry   = player.entities:get(offset + 6)
            local saplings = {}

            for i = 0, 8 do
                if i ~= 6 then
                    local sapling = player.entities:get(offset + i)
                    if sapling:isSpawned() then
                        sapling:despawn()
                    end

                    sapling:setRespawnTime(0)
                    SetServerVariable(varNameOf(offset + i), 0)
                    saplings[#saplings + 1] = sapling
                end
            end

            if not cherry:isSpawned() then
                SpawnMob(offset + 6)
            end

            -- LSB's killed timer at its earliest, 60 hours
            stub('math.randomInt', lowestRoll)
            cherry:despawn()

            for i, sapling in ipairs(saplings) do
                assertWindowed({ name = string.format('Cherry Sapling %d', i), hours = 71, window = 10 }, savedIn(sapling:getID()), 'saved respawn')
            end

            skipAndSpawn(60 * 3600 + 120)
            for i, sapling in ipairs(saplings) do
                assert(not sapling:isSpawned(), string.format('Cherry Sapling %d spawned 60 hours after Cemetery Cherry was killed (LSB\'s timer)', i))
            end

            skipAndSpawn(12 * 3600)
            for i, sapling in ipairs(saplings) do
                assert(sapling:isSpawned(), string.format('Cherry Sapling %d did not spawn after its window', i))
            end
        end)
    end)
end)
