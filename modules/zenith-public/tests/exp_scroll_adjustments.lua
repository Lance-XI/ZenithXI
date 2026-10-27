-- ZenithXI EXP scroll awards (modules/zenith-public/lua/3-complete/items/exp_scroll_adjustements.lua).
--
-- Raises the two low-level EXP scrolls: Page from the Dragon Chronicles 500-1000 -> 1000-1500
-- and Page from Miratete's Memoirs 750-1500 -> 1250-2000. The module rolls with math.random
-- where LSB uses math.randomInt, so both are stubbed to return the top of whichever scroll
-- range they are asked for, and the scroll is used through the real item action.

describe('Zenith EXP scroll awards', function()
    ---@type CClientEntityPair
    local player

    local scrolls =
    {
        { name = 'Dragon Chronicles', id = xi.item.DRAGON_CHRONICLES, min = 1000, max = 1500, lsbMin = 500, lsbMax = 1000 },
        { name = 'Miratete\'s Memoirs', id = xi.item.MIRATETES_MEMOIRS, min = 1250, max = 2000, lsbMin = 750, lsbMax = 1500 },
    }

    -- Returns the top of the range for either scroll range and records which one was asked for.
    local function stubRolls(scroll)
        local rolled    = {}
        local random    = math.random
        local randomInt = math.randomInt

        local function roll(original)
            return function(low, high)
                if
                    (low == scroll.min and high == scroll.max) or
                    (low == scroll.lsbMin and high == scroll.lsbMax)
                then
                    table.insert(rolled, string.format('%d-%d', low, high))
                    return high
                end

                return original(low, high)
            end
        end

        stub('math.random', roll(random))
        stub('math.randomInt', roll(randomInt))

        return rolled
    end

    local function useScroll(scroll)
        player:addItem(scroll.id)
        local item = player:findItem(scroll.id)
        assert(item, 'precondition: the scroll was not added')

        player.packets:clear()
        player.actions:useItem(player, item:getSlotID())
        xi.test.world:tickEntity(player)
        xi.test.world:skipTime(10)
    end

    local function awardedExp(scroll)
        for _, action in ipairs(player.packets:actionPackets()) do
            if
                action.cmd_no == xi.action.category.ITEM_FINISH and
                action.cmd_arg == scroll.id
            then
                return action.target[1].result[1].value
            end
        end

        return nil
    end

    before_each(function()
        xi.test.world:setSetting('main.EXP_RATE', 1)
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 30 })
        player:setLevelCap(99)
    end)

    for _, scroll in ipairs(scrolls) do
        it(string.format('awards up to %d EXP from %s', scroll.max, scroll.name), function()
            local rolled = stubRolls(scroll)

            useScroll(scroll)

            local exp = awardedExp(scroll)
            assert(exp, 'precondition: the scroll use did not finish')
            assert(rolled[1] == string.format('%d-%d', scroll.min, scroll.max),
                string.format('expected a %d-%d roll, got %s', scroll.min, scroll.max, tostring(rolled[1])))
            assert(exp == scroll.max, string.format('expected %d EXP, got %d', scroll.max, exp))
            player.assert.no:hasItem(scroll.id)
        end)
    end
end)
