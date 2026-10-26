-- ZenithXI wardrobe unlocks (modules/zenith-public/lua/3-complete/wardrobeUnlocks.lua).
--
-- LSB gives every character an 80-slot Mog Case and Mog Wardrobes 1-8. The module empties them at
-- character creation and earns slots back through achievements, checked on login, level up,
-- mission/quest completion, key items and NM kills. This file spot-checks one unlock per kind
-- and per hook, plus the storage migration; it does not walk the whole unlock table.
--
-- Unlocks used: Alchemy 10/20 (Mog Case, 1 each), Bastok 1-1 (Wardrobe 1, 1), Reach Level 5/10/15/20,
-- Shattering Stars WAR, Tenshodo Member's Card, Chocobo's Wounds (Wardrobe 2, 1 each),
-- Garrison: Valkurm Dunes (Wardrobe 4, 1; garrisonTracking.lua bit 8). A new level 1 character
-- qualifies for none of them.

describe('Zenith wardrobe unlocks', function()
    local managedBags =
    {
        { bag = xi.inv.MOGCASE,   name = 'Mog Case' },
        { bag = xi.inv.WARDROBE,  name = 'Mog Wardrobe 1' },
        { bag = xi.inv.WARDROBE2, name = 'Mog Wardrobe 2' },
        { bag = xi.inv.WARDROBE3, name = 'Mog Wardrobe 3' },
        { bag = xi.inv.WARDROBE4, name = 'Mog Wardrobe 4' },
        { bag = xi.inv.WARDROBE5, name = 'Mog Wardrobe 5' },
        { bag = xi.inv.WARDROBE6, name = 'Mog Wardrobe 6' },
        { bag = xi.inv.WARDROBE7, name = 'Mog Wardrobe 7' },
        { bag = xi.inv.WARDROBE8, name = 'Mog Wardrobe 8' },
    }

    ---@type CClientEntityPair
    local player

    local function entity()
        return GetPlayerByID(player:getID())
    end

    -- The login hook: what a relog runs (zoning = false)
    local function relog()
        xi.player.onGameIn(entity(), false, false)
    end

    local function assertSize(bag, name, expected, why)
        local size = player:getContainerSize(bag)
        assert(size == expected, string.format('%s: expected %d slots %s, got %d', name, expected, why, size))
    end

    describe('new character', function()
        before_each(function()
            -- new = true runs the first-login charCreate, as for a real new character
            player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 1, new = true })
        end)

        it('starts with an empty Mog Case and empty wardrobes', function()
            for _, entry in ipairs(managedBags) do
                assertSize(entry.bag, entry.name, 0, 'on a new character (LSB gives 80)')
            end
        end)

        -- Goes in from the side LSB calls: the engine's level-up runs xi.player.onPlayerLevelUp
        it('opens a Wardrobe 2 slot when leveling up to 5', function()
            player:setLevel(4)
            local before = player:getContainerSize(xi.inv.WARDROBE2)

            player:addExp(2000)
            xi.test.world:skipTime(1)

            assert(player:getMainLvl() == 5, string.format('precondition: should have leveled to 5, level %d', player:getMainLvl()))
            assertSize(xi.inv.WARDROBE2, 'Mog Wardrobe 2', before + 1, 'after reaching level 5 (one more than before)')
        end)

        it('opens Mog Case slots for crafting ranks on the login check', function()
            player:setSkillLevel(xi.skill.ALCHEMY, 200) -- Alchemy 20

            relog()
            assertSize(xi.inv.MOGCASE, 'Mog Case', 2, 'for Alchemy 10 and 20')

            -- Unlocks are flagged once awarded, so a second check must not pay them again
            relog()
            assertSize(xi.inv.MOGCASE, 'Mog Case', 2, 'after a second login check')
        end)

        it('opens a Wardrobe 1 slot when Bastok 1-1 is completed', function()
            -- The engine only completes the current mission
            player:setNation(xi.nation.BASTOK)
            player:addMission(xi.mission.log_id.BASTOK, xi.mission.id.bastok.THE_ZERUHN_REPORT)

            local done = npcUtil.completeMission(entity(), xi.mission.log_id.BASTOK, xi.mission.id.bastok.THE_ZERUHN_REPORT)

            assert(done, 'precondition: npcUtil.completeMission should succeed')
            assert(player:hasCompletedMission(xi.mission.log_id.BASTOK, xi.mission.id.bastok.THE_ZERUHN_REPORT), 'precondition: Bastok 1-1 should be complete')
            assertSize(xi.inv.WARDROBE, 'Mog Wardrobe 1', 1, 'for Bastok Mission 1-1')
        end)

        it('opens a Wardrobe 2 slot when Chocobo\'s Wounds is completed', function()
            player:addQuest(xi.questLog.JEUNO, xi.quest.id.jeuno.CHOCOBOS_WOUNDS)

            local done = npcUtil.completeQuest(entity(), xi.questLog.JEUNO, xi.quest.id.jeuno.CHOCOBOS_WOUNDS)

            assert(done, 'precondition: npcUtil.completeQuest should succeed')
            assertSize(xi.inv.WARDROBE2, 'Mog Wardrobe 2', 1, 'for Chocobo\'s Wounds')
        end)

        it('opens a Wardrobe 2 slot when the Tenshodo Member\'s Card is obtained', function()
            local done = npcUtil.giveKeyItem(entity(), xi.keyItem.TENSHODO_MEMBERS_CARD)

            assert(done, 'precondition: npcUtil.giveKeyItem should succeed')
            assertSize(xi.inv.WARDROBE2, 'Mog Wardrobe 2', 1, 'for the Tenshodo Member\'s Card')
        end)

        it('opens a Wardrobe 2 slot for a Shattering Stars job', function()
            player:setCharVar('maatsCap', 1) -- bit 0 = WAR

            relog()
            assertSize(xi.inv.WARDROBE2, 'Mog Wardrobe 2', 1, 'for Shattering Stars: WAR')
        end)

        it('opens a Wardrobe 4 slot for a tracked garrison win', function()
            player:setCharVar('WardrobeGarrison_Group1', bit.lshift(1, 8)) -- Valkurm Dunes

            relog()
            assertSize(xi.inv.WARDROBE4, 'Mog Wardrobe 4', 1, 'for Garrison: Valkurm Dunes')
        end)
    end)

    describe('existing character', function()
        before_each(function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 20 })
        end)

        it('migrates old unlock storage by topping bags up to what was earned', function()
            -- Pretend this character predates storage v2 and only has the slots v1 left it
            player:setCharVar('WardrobeUnlockVer', 0)
            player:changeContainerSize(xi.inv.WARDROBE2, -player:getContainerSize(xi.inv.WARDROBE2))
            assertSize(xi.inv.WARDROBE2, 'Mog Wardrobe 2', 0, 'after emptying it (precondition)')

            relog()

            -- Reach Level 5, 10, 15 and 20. Paying them again after the migration would give 8.
            assertSize(xi.inv.WARDROBE2, 'Mog Wardrobe 2', 4, 'after migrating a level 20 character')
            local version = player:getCharVar('WardrobeUnlockVer')
            assert(version == 2, string.format('expected unlock storage version 2 after migration, got %d', version))
        end)
    end)
end)
