-- ZenithXI The Moonlit Path without the Fenrir mount (modules/zenith-public/lua/3-complete/moonlit_path_mount.lua, ZENITHDEV-261).
--
-- Leepe-Hoppe's reward menu (event 846, or 850 on a repeat) takes a hide mask as its fifth parameter:
-- bit n hides option n + 1, bit 7 is the Fenrir mount. With the Trainer's Whistle base would offer the
-- mount; the module hides it. Rewards the player does not own stay on offer.
-- The module changes the quest on server start, which xi_test does not run by itself.

describe('Zenith The Moonlit Path', function()
    ---@type CClientEntityPair
    local player

    local function rewardMask()
        local quest  = require('scripts/quests/windurst/The_Moonlit_Path')
        local action = quest.sections[2][xi.zone.WINDURST_WATERS]['Leepe-Hoppe'].onTrigger(player, player.entities:get('Leepe-Hoppe'))

        assert(action and (action.id == 846 or action.id == 850), 'Leepe-Hoppe did not offer the reward menu')
        return action.options[5]
    end

    setup(function()
        xi.server.onServerStart()
    end)

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WINDURST_WATERS })
        player:addKeyItem(xi.keyItem.WHISPER_OF_THE_MOON)
        player:addKeyItem(xi.keyItem.TRAINERS_WHISTLE)
    end)

    it('hides the Fenrir mount from the reward menu', function()
        assert(utils.mask.getBit(rewardMask(), 7), 'the Fenrir mount is offered')
    end)

    it('still offers the rewards the player does not own', function()
        -- bit 0 is the first reward, Fenrir's Earring
        assert(not utils.mask.getBit(rewardMask(), 0), 'Fenrir\'s Earring is hidden')
    end)
end)
