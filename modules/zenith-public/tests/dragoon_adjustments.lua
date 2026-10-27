-- ZenithXI Dragoon adjustments (modules/zenith-public/lua/2-base/dragoon_adjustments.lua).
--
-- Each wyvern level-up gives less than LSB's numbers:
--   wyvern ACC +5 / HPP +3 / ATTP +4 per level (LSB +6 / +6 / +5),
--   master ATTP +2 / DEFP +2 / HASTE_ABILITY +100 / ALL_WSDMG_ALL_HITS +0 per level (LSB +4 / +4 / +200 / +2).
-- removeWyvernLevels then takes back only those trimmed amounts.
-- Setup: level 50 DRG, wyvern from Call Wyvern, one level-up from 200 wyvern EXP.

local masterMods =
{
    { name = 'ATTP',               mod = xi.mod.ATTP,               perLevel = 2   },
    { name = 'DEFP',               mod = xi.mod.DEFP,               perLevel = 2   },
    { name = 'HASTE_ABILITY',      mod = xi.mod.HASTE_ABILITY,      perLevel = 100 },
    { name = 'ALL_WSDMG_ALL_HITS', mod = xi.mod.ALL_WSDMG_ALL_HITS, perLevel = 0   },
}

local wyvernMods =
{
    { name = 'ACC',  mod = xi.mod.ACC,  perLevel = 5 },
    { name = 'HPP',  mod = xi.mod.HPP,  perLevel = 3 },
    { name = 'ATTP', mod = xi.mod.ATTP, perLevel = 4 },
}

describe('Zenith Dragoon adjustments', function()
    ---@type CClientEntityPair
    local player

    local function readMods(entity, mods)
        local values = {}
        for _, entry in ipairs(mods) do
            values[entry.name] = entity:getMod(entry.mod)
        end

        return values
    end

    local function assertDeltas(entity, mods, before, levels, what)
        for _, entry in ipairs(mods) do
            local expected = entry.perLevel * levels
            local actual   = entity:getMod(entry.mod) - before[entry.name]
            assert(actual == expected, string.format('%s %s: expected %+d, got %+d', what, entry.name, expected, actual))
        end
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.DRG, level = 50 })
        player.actions:useAbility(player, xi.jobAbility.CALL_WYVERN)
        xi.test.world:tickEntity(player)
        xi.test.world:skipTime(2)

        local wyvern = player:getPet()
        assert(wyvern, 'precondition: Call Wyvern gave no wyvern')
        assert(wyvern:getLocalVar('level_Ups') == 0, 'precondition: the new wyvern already has level-ups')
    end)

    it('gives the master and wyvern the trimmed buffs on a wyvern level-up', function()
        local master       = GetPlayerByID(player:getID())
        local wyvern       = player:getPet()
        local masterBefore = readMods(master, masterMods)
        local wyvernBefore = readMods(wyvern, wyvernMods)

        local levels = xi.job_utils.dragoon.addWyvernExp(master, 200)
        assert(levels == 1, string.format('precondition: 200 wyvern EXP should give 1 level-up, got %d', levels))

        assertDeltas(master, masterMods, masterBefore, 1, 'master')
        assertDeltas(wyvern, wyvernMods, wyvernBefore, 1, 'wyvern')
    end)

    -- Through the EXPERIENCE_POINTS listener the wyvern sets on its master, the way LSB calls it.
    it('gives the master the trimmed buffs when the master gains EXP', function()
        local master       = GetPlayerByID(player:getID())
        local masterBefore = readMods(master, masterMods)

        player:addExp(200)

        assert(player:getPet():getLocalVar('level_Ups') == 1, 'precondition: 200 EXP should level the wyvern once')
        assertDeltas(master, masterMods, masterBefore, 1, 'master after EXP')
    end)

    it('takes back only the trimmed master buffs when wyvern levels are removed', function()
        local master = GetPlayerByID(player:getID())
        local wyvern = player:getPet()

        -- One recorded level-up, without the buffs: the change in the master's mods is exactly
        -- what removeWyvernLevels takes away.
        wyvern:setLocalVar('level_Ups', 1)
        local before = readMods(master, masterMods)

        xi.pets.wyvern.removeWyvernLevels(wyvern)

        for _, entry in ipairs(masterMods) do
            local expected = -entry.perLevel
            local actual   = master:getMod(entry.mod) - before[entry.name]
            assert(actual == expected, string.format('removed master %s: expected %+d, got %+d', entry.name, expected, actual))
        end
    end)

    -- Control: passes with or without the module (LSB adds and removes the same full amounts).
    -- It catches the module's re-added delta no longer matching what LSB removes.
    it('returns the master to their old mods when the wyvern dies after a level-up', function()
        local master = GetPlayerByID(player:getID())
        local wyvern = player:getPet()
        local before = readMods(master, masterMods)

        xi.job_utils.dragoon.addWyvernExp(master, 200)
        assert(wyvern:getLocalVar('level_Ups') == 1, 'precondition: the wyvern should have one level-up')

        -- The engine calls onMobDeath for pets with no killer.
        xi.pets.wyvern.onMobDeath(wyvern, nil)

        assertDeltas(master, masterMods, before, 0, 'master after wyvern death')
    end)
end)
