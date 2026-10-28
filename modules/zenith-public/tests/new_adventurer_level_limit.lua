-- ZenithXI New Adventurer status (modules/zenith-public/lua/3-complete/new_adventurer_level_limit.lua, ZENITHDEV-244).
--
-- A level up that brings the main job to level 6 removes the New Adventurer status; below 6 it stays.
-- Base only removes it after the play time limit.

describe('Zenith New Adventurer status', function()
    local function levelUpTo(level)
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = level })
        player:setNewPlayer(true)

        -- the engine's level-up calls this
        xi.player.onPlayerLevelUp(player)

        return player:getNewPlayer()
    end

    it('removes the status at level 6', function()
        assert(not levelUpTo(6), 'a level 6 player is still a New Adventurer')
    end)

    it('keeps the status below level 6', function()
        assert(levelUpTo(5), 'a level 5 player lost the New Adventurer status')
    end)
end)
