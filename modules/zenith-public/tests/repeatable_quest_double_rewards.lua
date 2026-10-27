-- ZenithXI repeatable quest double gil (modules/zenith-public/lua/4-additive/quests/repeatableQuestDoubleRewards.lua).
--
-- Whitelisted repeatable quests pay their gil reward twice, for the first 3 completions of each
-- quest per real day (char var DailyGilBonus_<log>_<quest>, expiring at JST midnight, not at
-- Vana'diel midnight). The module marks the quest in
-- npcUtil.completeQuest and InteractionGlobal.onEventFinish, and adds the bonus from the
-- xi.player.onPlayerAddGil hook that 108-addGil-module-hook.patch puts into player:addGil. LSB
-- pays the reward once. Rewards scale with GIL_RATE, so expected amounts read it.

describe('Zenith repeatable quest double gil', function()
    ---@type CClientEntityPair
    local player

    local function gil(amount)
        return amount * xi.settings.main.GIL_RATE
    end

    describe('in Bastok', function()
        before_each(function()
            player = xi.test.world:spawnPlayer()
            player:gotoZone(xi.zone.BASTOK_MARKETS)

            -- Zoning into Bastok Markets plays event 22 first
            player.events:finish(22)
            player:setGil(0)
        end)

        it('doubles the Breaking Stones reward traded to Horatius', function()
            -- 400 gil reward, quest:complete() from the event 101 finish
            player:addQuest(xi.questLog.BASTOK, xi.quest.id.bastok.BREAKING_STONES)
            player:addItem(xi.item.DANGRUF_STONE)
            assert(player:hasItem(xi.item.DANGRUF_STONE), 'precondition: Dangruf Stone in inventory')

            player.actions:tradeNpc('Horatius', { xi.item.DANGRUF_STONE }, { eventId = 101 })

            assert(player:hasCompletedQuest(xi.questLog.BASTOK, xi.quest.id.bastok.BREAKING_STONES), 'precondition: Breaking Stones completed')
            assert(player:getGil() == gil(800), string.format('expected %d gil (400 doubled), got %d', gil(800), player:getGil()))

            local count = player:getCharVar(string.format('DailyGilBonus_%d_%d', xi.questLog.BASTOK, xi.quest.id.bastok.BREAKING_STONES))
            assert(count == 1, string.format('expected 1 daily bonus used, got %d', count))
        end)

        it('stops doubling after 3 completions of the same quest', function()
            local raw = GetPlayerByID(player:getID())

            -- Bonus on completions 1-3, plain reward on the 4th: 3 * 200 + 100
            for _ = 1, 4 do
                npcUtil.completeQuest(raw, xi.questLog.BASTOK, xi.quest.id.bastok.BREAKING_STONES, { gil = 100 })
            end

            assert(player:getGil() == gil(700), string.format('expected %d gil from 3 doubled and 1 plain reward, got %d', gil(700), player:getGil()))
        end)

        -- Control: passes with and without the module. The Darksmith was taken off the whitelist,
        -- so a module that doubled every quest would fail here.
        it('does not double a quest that is not on the whitelist', function()
            local raw = GetPlayerByID(player:getID())

            npcUtil.completeQuest(raw, xi.questLog.BASTOK, xi.quest.id.bastok.THE_DARKSMITH, { gil = 100 })

            assert(player:getGil() == gil(100), string.format('expected %d gil, got %d', gil(100), player:getGil()))
        end)

        describe('daily cap', function()
            local capVar = string.format('DailyGilBonus_%d_%d', xi.questLog.BASTOK, xi.quest.id.bastok.BREAKING_STONES)

            -- Complete Breaking Stones `times` times for a 100 gil reward each
            local function complete(times)
                local raw = GetPlayerByID(player:getID())
                for _ = 1, times do
                    npcUtil.completeQuest(raw, xi.questLog.BASTOK, xi.quest.id.bastok.BREAKING_STONES, { gil = 100 })
                end
            end

            -- Start just after a JST midnight, so a whole real day lies ahead of the case
            local function startOfJstDay()
                xi.test.world:tick(xi.tick.JST_DAY)
                assert(JstMidnight() - GetSystemTime() > 23 * 3600, string.format('precondition: a full JST day ahead, %d s left', JstMidnight() - GetSystemTime()))
            end

            it('expires the cap at the next JST midnight', function()
                local setVar = spy('CBaseEntity.setCharVar')

                complete(1)

                local expiry = nil
                for _, call in ipairs(setVar.calls) do
                    for i, arg in ipairs(call.args) do
                        if arg == capVar then
                            expiry = call.args[i + 2]
                        end
                    end
                end

                assert(expiry ~= nil, string.format('the module never set %s', capVar))
                assert(expiry == JstMidnight(), string.format('expected %s to expire at JST midnight %d, it expires at %d (%d s away)', capVar, JstMidnight(), expiry, expiry - GetSystemTime()))
            end)

            it('keeps the cap after a Vana\'diel day passes', function()
                startOfJstDay()
                complete(3)
                assert(player:getCharVar(capVar) == 3, string.format('precondition: cap reached, count is %d', player:getCharVar(capVar)))

                -- skipVanaDays moves the earth clock (GetSystemTime, char var expiry) by 57.6 minutes;
                -- skipTime only moves the server's tick clock, so it cannot expire a char var
                local vanaMidnight = getVanaMidnight(0)
                local jstMidnight  = JstMidnight()
                xi.test.world:skipVanaDays(1)
                xi.test.world:skipTime(1)
                -- JST midnight is also a Vana'diel midnight (25 Vana'diel days per Earth day), so this
                -- lands exactly on the next one, where a var expiring then already reads as 0
                assert(GetSystemTime() >= vanaMidnight, string.format('precondition: a Vana\'diel midnight passed (midnight %d, now %d)', vanaMidnight, GetSystemTime()))
                assert(GetSystemTime() < jstMidnight, 'precondition: still the same JST day')

                complete(1)

                assert(player:getCharVar(capVar) == 3, string.format('the cap reset after a Vana\'diel day: count is %d', player:getCharVar(capVar)))
                assert(player:getGil() == gil(700), string.format('expected %d gil (3 doubled, then 1 plain on the same JST day), got %d', gil(700), player:getGil()))
            end)

            -- The pre-fix module also resets here (a JST midnight is a Vana'diel midnight too), so this
            -- case guards the reset itself; the case above guards that it waits for JST midnight.
            it('resets the cap at JST midnight', function()
                startOfJstDay()
                complete(3)
                assert(player:getCharVar(capVar) == 3, string.format('precondition: cap reached, count is %d', player:getCharVar(capVar)))

                xi.test.world:tick(xi.tick.JST_DAY)
                xi.test.world:skipTime(1)

                complete(1)

                assert(player:getCharVar(capVar) == 1, string.format('expected a fresh count of 1 after JST midnight, got %d', player:getCharVar(capVar)))
                assert(player:getGil() == gil(800), string.format('expected %d gil (3 doubled, then doubled again on the new day), got %d', gil(800), player:getGil()))
            end)
        end)
    end)

    describe('in Port Windurst', function()
        before_each(function()
            player = xi.test.world:spawnPlayer()
            player:gotoZone(xi.zone.PORT_WINDURST)
            player.events:expectNotInEvent()
            player:setGil(0)
        end)

        -- Tokaka pays with a plain player:addGil() in his own event 210 finish, so only the
        -- InteractionGlobal.onEventFinish override can mark the quest here.
        it('doubles the Something Fishy reward from Tokaka', function()
            player:addQuest(xi.questLog.WINDURST, xi.quest.id.windurst.SOMETHING_FISHY)
            player:setCharVar('TokakaSpokenTo', 1)
            player:addItem(xi.item.BASTORE_SARDINE_1)
            assert(player:hasItem(xi.item.BASTORE_SARDINE_1), 'precondition: Bastore Sardine in inventory')

            player.actions:tradeNpc('Tokaka', { xi.item.BASTORE_SARDINE_1 }, { eventId = 210 })

            assert(not player:hasItem(xi.item.BASTORE_SARDINE_1), 'precondition: the sardine was taken')
            assert(player:getGil() == gil(140), string.format('expected %d gil (70 doubled), got %d', gil(140), player:getGil()))
        end)
    end)
end)
