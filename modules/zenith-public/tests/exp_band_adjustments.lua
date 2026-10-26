-- ZenithXI EXP band and ring caps (modules/zenith-public/lua/3-complete/items/exp_band_adjustments.lua).
--
-- The module keeps each item's Dedication power and duration but lowers the EXP cap (subPower)
-- far below LSB's 10000-30000: Chariot Band 750, Empress Band 1000, Emperor Band 2000,
-- Anniversary Ring 3000, Decennial Ring 4000, Kupofried's Ring 6000, Caliber Ring 750,
-- Allied Ring 9000. The last case uses a real Chariot Band so the engine's own item hook is
-- what runs.

describe('Zenith EXP band caps', function()
    ---@type CClientEntityPair
    local player

    local itemScripts = xi.items -- the loaded item scripts, not the xi.item enum

    local function dedicationOf()
        local effect = player:getStatusEffect(xi.effect.DEDICATION)
        assert(effect, 'the item did not give Dedication')

        return effect
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 75 })
        assert(not player:hasStatusEffect(xi.effect.DEDICATION), 'precondition: new player already has Dedication')
    end)

    local items =
    {
        { script = 'chariot_band',     power =  75, duration = 43200, cap =  750 }, -- LSB cap 10000
        { script = 'empress_band',     power =  50, duration = 43200, cap = 1000 }, -- LSB cap 15000
        { script = 'emperor_band',     power =  50, duration = 43200, cap = 2000 }, -- LSB cap 30000
        { script = 'anniversary_ring', power = 100, duration = 43200, cap = 3000 }, -- LSB cap 10000
        { script = 'decennial_ring',   power = 100, duration = 43200, cap = 4000 }, -- LSB cap 10000
        { script = 'kupofrieds_ring',  power = 100, duration = 86400, cap = 6000 }, -- LSB cap 30000
        { script = 'caliber_ring',     power = 150, duration = 43200, cap =  750 }, -- LSB cap 30000
        { script = 'allied_ring',      power = 150, duration = 43200, cap = 9000 }, -- LSB cap 30000
    }

    for _, row in ipairs(items) do
        it(string.format('caps %s Dedication at %d EXP', row.script, row.cap), function()
            assert(itemScripts[row.script], string.format('precondition: no item script %s', row.script))

            itemScripts[row.script].onItemUse(GetPlayerByID(player:getID()))

            local effect = dedicationOf()
            assert(effect:getSubPower() == row.cap, string.format('expected an EXP cap of %d, got %d', row.cap, effect:getSubPower()))
            assert(effect:getPower() == row.power, string.format('expected +%d%% EXP, got %d', row.power, effect:getPower()))
            assert(effect:getDuration() == row.duration * 1000,
                string.format('expected %d s, got %d ms', row.duration, effect:getDuration()))
        end)
    end

    it('caps a worn and used Chariot Band at 750 EXP', function()
        player:addItem(xi.item.CHARIOT_BAND)
        player:equipItem(xi.item.CHARIOT_BAND, nil, xi.slot.RING1)
        assert(player:getEquippedItem(xi.slot.RING1), 'precondition: the Chariot Band is not equipped')
        xi.test.world:skipTime(6) -- item_usable.useDelay: usable 5 s after it is equipped

        local band = player:findItem(xi.item.CHARIOT_BAND)
        player.actions:useItem(player, band:getSlotID(), xi.inventoryLocation.INVENTORY)
        for _ = 1, 5 do
            xi.test.world:skipTime(2)
        end

        local effect = dedicationOf()
        assert(effect:getSubPower() == 750, string.format('expected an EXP cap of 750, got %d', effect:getSubPower()))
    end)
end)
