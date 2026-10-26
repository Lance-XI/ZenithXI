-----------------------------------
-- HNM Respawn Windows Module
--
-- Replaces LSB's respawn roll for the NMs below with base hours plus one of seven windows,
-- rolled again for every respawn:
-- - 21 hours + 0-6 windows of 5 minutes (75600 to 77400 seconds)
-- - 71 hours + 0-6 windows of 10 minutes (255600 to 259200 seconds)
-- The end of the window is saved in the server var '[Respawn]<name>_<id>'
-- (zxi.mobHelpers.getRespawnVarName) and restored by Zone.onInitialize after a restart.
-----------------------------------

require('modules/module_utils')
local m = Module:new('c-m_hnm_respawn_windows')

-- List of NMs to modify respawn times for
-- Format: { zone_name, mob_name, respawn_hours, spawn_window_minutes }
local nmsToModify = {
    { 'Arrapago_Reef', 'Medusa', 71, 10 },
    { 'Attohwa_Chasm', 'Tiamat', 71, 10 },
    { 'Attohwa_Chasm', 'Xolotl', 21, 5 },
    { 'Bostaunieux_Oubliette', 'Bloodsucker_NM', 21, 5 },
    { 'Caedarva_Mire', 'Khimaira', 71, 10 },
    { 'Cape_Teriggan', 'Kreutzet', 9, 30 },
    { 'Castle_Zvahl_Baileys', 'Duke_Haborym', 21, 5 },
    { 'Castle_Zvahl_Baileys', 'Grand_Duke_Batym', 21, 5 },
    { 'Castle_Zvahl_Baileys', 'Marquis_Allocen', 21, 5 },
    { 'Castle_Zvahl_Baileys', 'Marquis_Amon', 21, 5 },
    { 'FeiYin', 'Capricious_Cassie', 21, 5 },
    { 'Garlaige_Citadel', 'Serket', 21, 5 },
    { 'Garlaige_Citadel', 'Skewer_Sam', 21, 5 },
    { 'Gusgen_Mines', 'Juggler_Hecatomb', 21, 5 },
    { 'Gustav_Tunnel', 'Bune', 21, 5 },
    { 'Halvung', 'Gurfurlur_the_Menacing', 71, 10 },
    { 'Ifrits_Cauldron', 'Ash_Dragon', 21, 5 },
    { 'King_Ranperres_Tomb', 'Vrtra', 71, 10 },
    { 'Mamook', 'Gulool_Ja_Ja', 71, 10 },
    { 'Meriphataud_Mountains', 'Waraxe_Beak', 21, 5 },
    { 'Misareaux_Coast', 'Upyri', 21, 5 },
    { 'Mount_Zhayolm', 'Cerberus', 71, 10 },
    { 'Ordelles_Caves', 'Morbolger', 21, 5 },
    { 'Palborough_Mines', 'NoMho_Crimsonarmor', 21, 5 },
    { 'Qufim_Island', 'Dosetsu_Tree', 21, 5 },
    { 'Quicksand_Caves', 'Antican_Consul', 21, 5 },
    { 'Riverne-Site_B01', 'Boroka', 21, 5 },
    { 'Rolanberry_Fields', 'Simurgh', 21, 5 },
    { 'RoMaeve', 'Shikigami_Weapon', 21, 5 },
    { 'Sauromugue_Champaign', 'Roc', 21, 5 },
    { 'Sea_Serpent_Grotto', 'Ocean_Sahagin', 21, 5 },
    { 'The_Boyahda_Tree', 'Ancient_Goobbue', 21, 5 },
    { 'Toraimarai_Canal', 'Oni_Carcass', 21, 5 },
    { 'Uleguerand_Range', 'Jormungand', 71, 10 },
    { 'Wajaom_Woodlands', 'Hydra', 71, 10 },
    { 'Western_Altepa_Desert', 'King_Vinegarroon', 21, 5 },
    { 'Xarcabard', 'Ereshkigal', 21, 5 },
    { 'Yhoator_Jungle', 'Bright-handed_Kunberry', 21, 5 },
    { 'Yhoator_Jungle', 'Woodland_Sage', 21, 5 },
}

-- Beastmen NQ/HQ NM configuration
local beastmenNMs = {
    {
        zone = 'Monastic_Cavern',
        zoneId = 'MONASTIC_CAVERN',
        nqName = 'Orcish_Overlord',
        nqIdName = 'ORCISH_OVERLORD',
        hqName = 'Overlord_Bakgodek',
        hqOffset = 1,
        phVar = '[PH]Overlord_Bakgodek',
        respawnHours = 21,
        respawnWindowLengthDuration = 5
    },
    {
        zone = 'Castle_Oztroja',
        zoneId = 'CASTLE_OZTROJA',
        nqName = 'Yagudo_Avatar',
        nqIdName = 'YAGUDO_AVATAR',
        hqName = 'Tzee_Xicu_the_Manifest',
        hqOffset = 3, -- Different offset due to elementals
        phVar = '[PH]Tzee_Xicu_the_Manifest',
        respawnHours = 21,
        respawnWindowLengthDuration = 5
    },
    {
        zone = 'Qulun_Dome',
        zoneId = 'QULUN_DOME',
        nqName = 'Diamond_Quadav',
        nqIdName = 'DIAMOND_QUADAV',
        hqName = 'ZaDha_Adamantking',
        hqOffset = 1,
        phVar = '[PH]Za_Dha_Adamantking',
        respawnHours = 21,
        respawnWindowLengthDuration = 5
    }
}

-- NMs that LSB spawns only when its own check allows it: the hours of the night (Xolotl), the
-- zone's weather (Zone.onZoneWeatherChange of Cape Teriggan, Western Altepa Desert and Qufim
-- Island) or a placeholder (Etemmu turns into Ereshkigal). A saved time that has passed never
-- spawns them directly; the window has opened and LSB's check does the rest.
local conditionalNMs = set{ 'Xolotl', 'Kreutzet', 'King_Vinegarroon', 'Dosetsu_Tree', 'Ereshkigal' }

-- Local var on an NM that zone init took back down to keep its saved time (see restoreOrSetRespawnTime)
local restoreDespawnVar = '[HNM]restoreDespawn'

----------------------------------- HELPER FUNCTIONS -----------------------------------

-- Base hours plus one of seven windows, rolled for every respawn
local function windowedRespawn(respawnHours, windowMinutes)
    return math.random(0, 6) * (windowMinutes * 60) + (respawnHours * 3600)
end

-- setRespawnTime always allows a respawn again, so this re-applies the condition of the NMs whose
-- spawn LSB leaves to a weather check or a placeholder. The timer then only marks when the window opens.
local function blockConditionalRespawn(mob, respawnAt)
    local name = mob:getName()

    if
        name == 'Kreutzet' or     -- allowed again in wind weather by Cape Teriggan's onZoneWeatherChange
        name == 'Ereshkigal' or   -- spawned by its placeholder Etemmu, see the Etemmu onMobRoam override
        name == 'Dosetsu_Tree'    -- spawned by Qufim Island's onZoneWeatherChange in thunder weather
    then
        DisallowRespawn(mob:getID(), true)
    end

    if name == 'Dosetsu_Tree' then
        -- Qufim Island spawns it on the next thunder weather after this time
        mob:setLocalVar('respawn', respawnAt)
    end
end

-- Helper function to set respawn time and persist it
local function setAndPersistRespawnTime(mob, respawnTimeCalc)
    if mob then
        local varName = zxi.mobHelpers.getRespawnVarName(mob)

        mob:setRespawnTime(respawnTimeCalc)
        SetServerVariable(varName, GetSystemTime() + respawnTimeCalc)
        blockConditionalRespawn(mob, GetSystemTime() + respawnTimeCalc)
    end
end

-- True for the despawn that restoreOrSetRespawnTime started: the NM keeps its saved time, and
-- LSB's despawn logic (a new respawn roll, a spawned follow-up NM) is skipped because nothing died.
local function isRestoreDespawn(mob)
    if mob:getLocalVar(restoreDespawnVar) ~= 1 then
        return false
    end

    mob:setLocalVar(restoreDespawnVar, 0)

    local savedRespawnTime = GetServerVariable(zxi.mobHelpers.getRespawnVarName(mob))
    mob:setRespawnTime(math.max(savedRespawnTime - GetSystemTime(), 1))
    blockConditionalRespawn(mob, savedRespawnTime)

    return true
end

-- Generic function to restore or set mob respawn time on zone init
local function restoreOrSetRespawnTime(mobId, respawnTimeCalc)
    local mob = GetMobByID(mobId)

    if mob then
        local mobName = mob:getName()
        local varName = zxi.mobHelpers.getRespawnVarName(mob)
        local savedRespawnTime = GetServerVariable(varName)
        local currentTime = GetSystemTime()

        if savedRespawnTime > currentTime then
            mob:setRespawnTime(savedRespawnTime - currentTime)
            blockConditionalRespawn(mob, savedRespawnTime)

            -- The engine spawns NMs with a normal spawn type when the zone loads. Take it back down;
            -- its despawn override sees the local var and keeps the saved time.
            if mob:isSpawned() then
                mob:setLocalVar(restoreDespawnVar, 1)
                DespawnMob(mobId)
            end
        elseif savedRespawnTime > 0 then
            if conditionalNMs[mobName] then
                mob:setRespawnTime(1)
                blockConditionalRespawn(mob, savedRespawnTime)

                if mobName == 'King_Vinegarroon' then
                    -- Western Altepa Desert's onZoneWeatherChange allows it in earth weather
                    DisallowRespawn(mobId, true)
                end
            elseif not mob:isSpawned() then
                -- Drop the timer LSB's onMobInitialize registered first: a timer that comes due
                -- while the NM is up spawns it again where it stands.
                mob:setRespawnTime(0)
                SpawnMob(mobId)
                mob:setRespawnTime(respawnTimeCalc)
            end
        elseif not mob:isSpawned() then
            -- Nothing saved: roll a window. An NM that is already up gets one when it despawns.
            setAndPersistRespawnTime(mob, respawnTimeCalc)
        end
    end
end

-- Restore or set respawn on a contiguous group of mobs
-- startId         = first mob ID
-- count           = how many sequential IDs
-- respawnTimeCalc = respawn calculation in seconds
local function restoreGroup(startId, count, respawnTimeCalc)
    for offset = 0, count - 1 do
        restoreOrSetRespawnTime(startId + offset, respawnTimeCalc)
    end
end

----------------------------------- STANDARD NM LOGIC -----------------------------------

-- Generic function to create standard NM overrides
local function createStandardNMOverrides(nmList)
    for _, entry in pairs(nmList) do
        local zoneName = entry[1]
        local mobName = entry[2]
        local respawnHours = entry[3]
        local respawnWindowLengthDuration = entry[4]

        -- Zone initialization override
        -- Zone and mob overrides defer until their script loads, so multi-mapserver setups
        -- need no ensureTable (see the mob override below)
        local zonePath = fmt('xi.zones.{}.Zone', zoneName)
        m:addOverride(zonePath .. '.onInitialize',
        function(zone)
            super(zone)
            local mob = zone:queryEntitiesByName(mobName)[1]
            if mob then
                restoreOrSetRespawnTime(mob:getID(), windowedRespawn(respawnHours, respawnWindowLengthDuration))
            end
        end)

        -- onMobDespawn override
        -- Never ensureTable a mob path: modules load before zone mobs, and an empty table there
        -- makes the engine discard the real scripts/zones/<Zone>/mobs/<Mob>.lua. The override
        -- defers and is applied once that script loads.
        local mobPath = fmt('xi.zones.{}.mobs.{}', zoneName, mobName)
        m:addOverride(mobPath .. '.onMobDespawn',
        function(mob)
            if isRestoreDespawn(mob) then
                return
            end

            super(mob)

            if
                mobName == 'Xolotl' and
                mob:getLocalVar('killed') ~= 1
            then
                -- Despawned at dawn without being killed: LSB brings him back the next night,
                -- and after a restart his onMobInitialize rolls a new timer.
                SetServerVariable(zxi.mobHelpers.getRespawnVarName(mob), 0)

                return
            end

            setAndPersistRespawnTime(mob, windowedRespawn(respawnHours, respawnWindowLengthDuration))
        end)
    end
end

-- Create overrides for standard NMs
createStandardNMOverrides(nmsToModify)

-- Ereshkigal: its placeholder turns into it only once the module's window has opened
local xarcabardId = zones[xi.zone.XARCABARD]

m:addOverride('xi.zones.Xarcabard.mobs.Etemmu.onMobRoam',
function(mob)
    if
        mob:getID() == xarcabardId.mob.ERESHKIGAL - 1 and
        mob:getLocalVar('phDespawnTime') ~= 0 and
        GetServerVariable(zxi.mobHelpers.getRespawnVarName('Ereshkigal', xarcabardId.mob.ERESHKIGAL)) > GetSystemTime()
    then
        return
    end

    super(mob)
end)

----------------------------------- BEASTMEN NQ/HQ HNM LOGIC -----------------------------------

--- LSB's NQ despawn already rolls NQ or HQ: it raises the [PH] kill count when the NQ comes back
--- and leaves it alone when it schedules the HQ. The module follows that one roll and only replaces
--- the timer of the NM LSB picked. When HQ despawns LSB resets back to NQ for the next cycle.
local function handleBeastmenDespawn(mob, config, killsBefore)
    local ID = zones[xi.zone[config.zoneId]]

    if mob and ID then
        local mobId = mob:getID()
        local nqId  = ID.mob[config.nqIdName]
        local hqId  = nqId + config.hqOffset
        local respawn = windowedRespawn(config.respawnHours, config.respawnWindowLengthDuration)

        if mobId == nqId then
            if GetServerVariable(config.phVar) ~= killsBefore then
                setAndPersistRespawnTime(GetMobByID(nqId), respawn)
            else
                setAndPersistRespawnTime(GetMobByID(hqId), respawn)
            end
        elseif mobId == hqId then
            setAndPersistRespawnTime(GetMobByID(nqId), respawn)
        end
    end
end

-- Create beastmen NM overrides
for _, config in pairs(beastmenNMs) do
    m:addOverride(fmt('xi.zones.{}.Zone.onInitialize', config.zone),
    function(zone)
        local ID = zones[xi.zone[config.zoneId]]
        super(zone)

        local nqId = ID.mob[config.nqIdName]
        local hqId = nqId + config.hqOffset
        local nqSaved = GetServerVariable(zxi.mobHelpers.getRespawnVarName(config.nqName, nqId))
        local hqSaved = GetServerVariable(zxi.mobHelpers.getRespawnVarName(config.hqName, hqId))
        local respawn = windowedRespawn(config.respawnHours, config.respawnWindowLengthDuration)

        -- Whichever of the two was scheduled last is the one that comes next; the other one's
        -- saved time is left over from an earlier cycle. With nothing saved, the NQ comes next.
        if hqSaved > nqSaved then
            DisallowRespawn(nqId, true)
            DisallowRespawn(hqId, false)
            restoreOrSetRespawnTime(hqId, respawn)
        else
            DisallowRespawn(hqId, true)
            DisallowRespawn(nqId, false)
            restoreOrSetRespawnTime(nqId, respawn)
        end
    end)

    -- NQ/HQ despawn override
    for _, phase in ipairs{ config.nqName, config.hqName } do
        m:addOverride(
            fmt('xi.zones.{}.mobs.{}.onMobDespawn', config.zone, phase),
            function(mob)
                local killsBefore = GetServerVariable(config.phVar)

                super(mob)
                handleBeastmenDespawn(mob, config, killsBefore)
            end
        )
    end
end

----------------------------------- SPECIAL CASE NMS -----------------------------------

----------------------------------- Argus/Leech King Logic -----------------------------------
local mazeOfShakhramiId = zones[xi.zone.MAZE_OF_SHAKHRAMI]

-- pick one of the two NMs
local function chooseArgusLK()
    if math.random(1, 100) <= 50 then
        return mazeOfShakhramiId.mob.ARGUS
    else
        return mazeOfShakhramiId.mob.LEECH_KING
    end
end

-- common apply logic (either restoring or freshly setting)
local function applyArgusLK(choice, restoreOnly)
    local other = mazeOfShakhramiId.mob.ARGUS
    if choice ~= mazeOfShakhramiId.mob.LEECH_KING then
        choice = mazeOfShakhramiId.mob.ARGUS
        other = mazeOfShakhramiId.mob.LEECH_KING
    end

    DisallowRespawn(other, true)
    DisallowRespawn(choice, false)
    SetServerVariable('[NextSpawn]Argus/LK', choice)
    local spawnTime = windowedRespawn(21, 5)

    if restoreOnly then
        restoreOrSetRespawnTime(choice, spawnTime)
    else
        setAndPersistRespawnTime(GetMobByID(choice), spawnTime)
    end
end

m:addOverride('xi.zones.Maze_of_Shakhrami.Zone.onInitialize',
function(zone)
    super(zone)

    local nextSpawn = GetServerVariable('[NextSpawn]Argus/LK')
    -- if never set or corrupted, pick one at random
    if
        nextSpawn ~= mazeOfShakhramiId.mob.ARGUS and
        nextSpawn ~= mazeOfShakhramiId.mob.LEECH_KING
    then
        nextSpawn = chooseArgusLK()
    end

    applyArgusLK(nextSpawn, true)
end)

m:addOverride('xi.zones.Maze_of_Shakhrami.mobs.Argus.onMobDespawn',
function(mob)
    super(mob)
    applyArgusLK(chooseArgusLK(), false)
end)

m:addOverride('xi.zones.Maze_of_Shakhrami.mobs.Leech_King.onMobDespawn',
function(mob)
    super(mob)
    applyArgusLK(chooseArgusLK(), false)
end)

----------------------------------- Carmine Dobsonfly Logic -----------------------------------
local riverneSiteA01Id = zones[xi.zone.RIVERNE_SITE_A01]

m:addOverride('xi.zones.Riverne-Site_A01.Zone.onInitialize',
function(zone)
    super(zone)
    -- passing in respawn time calculation in case no server value for next respawn can be found
    restoreGroup(riverneSiteA01Id.mob.CARMINE_DOBSONFLY_OFFSET, 10, windowedRespawn(21, 5))
end)

m:addOverride('xi.zones.Riverne-Site_A01.mobs.Carmine_Dobsonfly.onMobDespawn',
function(mob)
    if isRestoreDespawn(mob) then
        return
    end

    super(mob)

    local respawnTime = windowedRespawn(21, 5)
    -- Check if all flies are dead and a new respawn time was set
    -- If yes, set respawn time for all Carmine Dobsonflies to 21 hours, with 5 minute windows
    for i = riverneSiteA01Id.mob.CARMINE_DOBSONFLY_OFFSET, riverneSiteA01Id.mob.CARMINE_DOBSONFLY_OFFSET + 9 do
        local fly = GetMobByID(i)
        if fly and fly:getRespawnTime() > 0 then
            -- setAndPersistRespawnTime takes a duration, not a timestamp
            setAndPersistRespawnTime(fly, respawnTime)
        end
    end
end)

----------------------------------- King Arthro Logic -----------------------------------
local jugnerForestId = zones[xi.zone.JUGNER_FOREST]

m:addOverride('xi.zones.Jugner_Forest.Zone.onInitialize',
function(zone)
    super(zone)

    -- 10 Knight Crabs
    restoreGroup(jugnerForestId.mob.KING_ARTHRO - 10, 10, windowedRespawn(21, 5))
end)

m:addOverride('xi.zones.Jugner_Forest.mobs.King_Arthro.onMobDespawn',
function(mob)
    super(mob)

    local kingArthroID = jugnerForestId.mob.KING_ARTHRO
    local respawnTime = windowedRespawn(21, 5)
    for offset = 1, 10 do
        -- setAndPersistRespawnTime takes a duration, not a timestamp
        setAndPersistRespawnTime(GetMobByID(kingArthroID - offset), respawnTime)
    end
end)

----------------------------------- Weeping Willow/Lumber Jack Logic -----------------------------------
m:addOverride('xi.zones.Batallia_Downs.Zone.onInitialize',
function(zone)
    super(zone)
    local mob = zone:queryEntitiesByName('Weeping_Willow')[1]
    restoreOrSetRespawnTime(mob:getID(), windowedRespawn(21, 5))
end)

m:addOverride('xi.zones.Batallia_Downs.mobs.Weeping_Willow.onMobDespawn',
function(mob)
    if isRestoreDespawn(mob) then
        return
    end

    super(mob)
    -- Disable respawning logic until Lumber Jack is killed/despawns
    DisallowRespawn(mob:getID(), true)
end)

m:addOverride('xi.zones.Batallia_Downs.mobs.Lumber_Jack.onMobDespawn',
function(mob)
    super(mob)

    local willow = mob:getID() - 6
    DisallowRespawn(willow, false) -- Allow Weeping Willow to respawn
    if mob:getLocalVar('death') == 1 then
        -- Lumber Jack died, Set Weeping Willow's respawn time (21 hours, 5 minute windows)
        setAndPersistRespawnTime(GetMobByID(willow), windowedRespawn(21, 5))
    else
        -- Lumber Jack despawned without dying, reset Weeping Willow's respawn time to 30 minutes
        setAndPersistRespawnTime(GetMobByID(willow), 1800) -- 30 minutes
    end
end)

----------------------------------- Cherry Saplings/Cemetery Cherry Logic -----------------------------------
-- LSB respawns the saplings only through Cemetery Cherry's timer: 30-60 minutes after zone load or
-- after it despawns unkilled, 60-72 hours after it is killed. The module replaces only the
-- killed timer with 71 hours + 0-6 windows of 10 minutes on the saplings themselves.
local kingRanperresTombId = zones[xi.zone.KING_RANPERRES_TOMB]
local cemeteryCherryId    = kingRanperresTombId.mob.CHERRY_SAPLING_OFFSET + 6

local function forEachCherrySapling(func)
    for i = kingRanperresTombId.mob.CHERRY_SAPLING_OFFSET, kingRanperresTombId.mob.CHERRY_SAPLING_OFFSET + 8 do
        local sapling = GetMobByID(i)

        if i ~= cemeteryCherryId and sapling then -- Skip Cemetery Cherry
            func(sapling)
        end
    end
end

m:addOverride('xi.zones.King_Ranperres_Tomb.Zone.onInitialize',
function(zone)
    super(zone)

    -- Restore a saved sapling respawn, and drop the 30-60 minute timer Cemetery Cherry's onMobInitialize started
    local currentTime    = GetSystemTime()
    local cemeteryCherry = GetMobByID(cemeteryCherryId)

    forEachCherrySapling(function(sapling)
        local savedRespawnTime = GetServerVariable(zxi.mobHelpers.getRespawnVarName(sapling))

        if savedRespawnTime > currentTime then
            if cemeteryCherry then
                cemeteryCherry:clearTimerQueue()
            end

            sapling:setRespawnTime(savedRespawnTime - currentTime)
        end
    end)
end)

-- Saplings never respawn one by one: they come back together through Cemetery Cherry
m:addOverride('xi.zones.King_Ranperres_Tomb.mobs.Cherry_Sapling.onMobDeath',
function(mob, player, optParams)
    super(mob, player, optParams)
    DisallowRespawn(mob:getID(), true)
end)

m:addOverride('xi.zones.King_Ranperres_Tomb.mobs.Cemetery_Cherry.onMobDespawn',
function(mob)
    super(mob)

    if mob:getLocalVar('wasKilled') == 1 then
        -- Replace LSB's 60-72 hour sapling timer with the window
        mob:clearTimerQueue()

        local respawnTime = windowedRespawn(71, 10)
        forEachCherrySapling(function(sapling)
            setAndPersistRespawnTime(sapling, respawnTime)
        end)
    end
end)

----------------------------------- Padfoot Logic -----------------------------------
local lufaiseMeadowsId = zones[xi.zone.LUFAISE_MEADOWS]

m:addOverride('xi.zones.Lufaise_Meadows.Zone.onInitialize',
function(zone)
    super(zone)
    local respawnTime = windowedRespawn(21, 5)
    for _, v in pairs(lufaiseMeadowsId.mob.PADFOOT) do
        local padfoot = GetMobByID(v)
        if padfoot then
            restoreOrSetRespawnTime(padfoot:getID(), respawnTime)
        end
    end
end)

m:addOverride('xi.zones.Lufaise_Meadows.mobs.Padfoot.onMobDespawn',
function(mob)
    if isRestoreDespawn(mob) then
        return
    end

    -- The base script re-rolls realPadfoot at the end of onMobDespawn, so read it before super
    local isRealPadfoot = mob:getID() == lufaiseMeadowsId.mob.PADFOOT[GetServerVariable('realPadfoot')]

    super(mob)

    if isRealPadfoot then
        local respawn = windowedRespawn(21, 5)

        for _, v in pairs(lufaiseMeadowsId.mob.PADFOOT) do
            setAndPersistRespawnTime(GetMobByID(v), respawn)
        end
    end
end)

return m
