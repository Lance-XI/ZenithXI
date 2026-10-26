-- ZenithXI Yara Ma Yha Who watering cooldown (modules/zenith-public/lua/2-base/qm2_water_trade.lua).
--
-- Tahrongi Canyon's qm2 (the sprout) takes a Flask of Distilled Water once per cooldown, and pops
-- Yara Ma Yha Who on a 50% roll after three waterings. LSB's cooldown is 50 minutes (3000 s); the
-- module cuts it to 20 minutes (1200 s) after an accepted watering and after the pop.
-- The cooldown is the sprout's tradeCooldown local var, a UTC timestamp. skipTime does not move
-- GetSystemTime, so the cases read the timestamp instead of waiting it out.

describe('Zenith Yara Ma Yha Who watering cooldown', function()
    local ID       = zones[xi.zone.TAHRONGI_CANYON]
    local cooldown = 20 * 60

    ---@type CClientEntityPair
    local player
    ---@type CTestEntity
    local sprout

    local function cooldownLeft()
        return sprout:getLocalVar('tradeCooldown') - GetSystemTime()
    end

    before_each(function()
        DespawnMob(ID.mob.YARA_MA_YHA_WHO)

        player = xi.test.world:spawnPlayer({ zone = xi.zone.TAHRONGI_CANYON, job = xi.job.WAR, level = 75 })
        player:addItem(xi.item.FLASK_OF_DISTILLED_WATER)

        -- The sprout is shared by every case: start each one from a fresh, watered-out state
        sprout = player.entities:get('qm2')
        sprout:setLocalVar('trades', 0)
        sprout:setLocalVar('tradeCooldown', 0)
    end)

    after_each(function()
        DespawnMob(ID.mob.YARA_MA_YHA_WHO)
    end)

    it('waits 20 minutes after a watering', function()
        player.actions:tradeNpc(sprout, { xi.item.FLASK_OF_DISTILLED_WATER })

        assert(sprout:getLocalVar('trades') == 1, 'precondition: the watering was accepted')
        local left = cooldownLeft()
        assert(left > cooldown - 30 and left <= cooldown, string.format('expected a cooldown of %d s, got %d s', cooldown, left))
    end)

    it('waits 20 minutes after a fourth watering that does not pop Yara Ma Yha Who', function()
        sprout:setLocalVar('trades', 3)
        stub('math.randomInt', 100) -- loses the 50% pop roll

        player.actions:tradeNpc(sprout, { xi.item.FLASK_OF_DISTILLED_WATER })

        assert(sprout:getLocalVar('trades') == 4, 'precondition: the watering was accepted without a pop')
        local left = cooldownLeft()
        assert(left > cooldown - 30 and left <= cooldown, string.format('expected a cooldown of %d s, got %d s', cooldown, left))
    end)

    it('waits 20 minutes after Yara Ma Yha Who pops', function()
        sprout:setLocalVar('trades', 3)
        stub('math.randomInt', 1) -- wins the 50% pop roll

        player.actions:tradeNpc(sprout, { xi.item.FLASK_OF_DISTILLED_WATER })

        local yara = GetMobByID(ID.mob.YARA_MA_YHA_WHO)
        assert(yara and yara:isSpawned(), 'precondition: Yara Ma Yha Who popped')
        local left = cooldownLeft()
        assert(left > cooldown - 30 and left <= cooldown, string.format('expected a cooldown of %d s, got %d s', cooldown, left))
    end)
end)
