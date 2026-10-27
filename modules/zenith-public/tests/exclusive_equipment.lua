-- ZenithXI exclusive equipment groups (modules/zenith-public/lua/4-additive/items/exclusive_equipment.lua).
--
-- Kraken Club and Octave Club may not be dual wielded together: equipping the second one strips
-- both main and sub 50 ms later (a timer, so the asserts let time pass first). LSB has no
-- onItemEquip for either club and leaves both equipped. NIN 75 is used for Dual Wield.

describe('Zenith exclusive equipment', function()
    ---@type CClientEntityPair
    local player

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.NIN, level = 75 })

        for _, itemId in ipairs({ xi.item.KRAKEN_CLUB, xi.item.OCTAVE_CLUB, xi.item.ASH_CLUB }) do
            player:addItem(itemId)
            assert(player:hasItem(itemId), string.format('precondition: item %d in inventory', itemId))
        end
    end)

    -- Equip main then sub through charutils::EquipItem (what the equip packet runs), check the
    -- engine accepted both, then let the module's 50 ms timer run.
    local function equipPair(mainId, subId)
        player:equipItem(mainId, xi.inv.INVENTORY, xi.slot.MAIN)
        player:equipItem(subId, xi.inv.INVENTORY, xi.slot.SUB)

        assert(player:getEquipID(xi.slot.MAIN) == mainId, string.format('precondition: main is %d, got %d', mainId, player:getEquipID(xi.slot.MAIN)))
        assert(player:getEquipID(xi.slot.SUB) == subId, string.format('precondition: sub is %d, got %d', subId, player:getEquipID(xi.slot.SUB)))

        xi.test.world:skipTime(1)
    end

    local conflicts =
    {
        { name = 'Kraken Club main, Octave Club sub', main = xi.item.KRAKEN_CLUB, sub = xi.item.OCTAVE_CLUB },
        { name = 'Octave Club main, Kraken Club sub', main = xi.item.OCTAVE_CLUB, sub = xi.item.KRAKEN_CLUB },
    }

    for _, case in ipairs(conflicts) do
        it(string.format('unequips both weapons for %s', case.name), function()
            equipPair(case.main, case.sub)

            assert(player:getEquipID(xi.slot.MAIN) == 0, string.format('main weapon %d stayed equipped next to its exclusive partner', player:getEquipID(xi.slot.MAIN)))
            assert(player:getEquipID(xi.slot.SUB) == 0, string.format('sub weapon %d stayed equipped next to its exclusive partner', player:getEquipID(xi.slot.SUB)))
        end)
    end

    -- Control: passes with and without the module. A group club next to an ordinary club is
    -- allowed, so a module that strips every dual-wielded Kraken Club would fail here.
    it('keeps Kraken Club dual wielded with a club outside the group', function()
        equipPair(xi.item.KRAKEN_CLUB, xi.item.ASH_CLUB)

        assert(player:getEquipID(xi.slot.MAIN) == xi.item.KRAKEN_CLUB, string.format('Kraken Club was unequipped, main is %d', player:getEquipID(xi.slot.MAIN)))
        assert(player:getEquipID(xi.slot.SUB) == xi.item.ASH_CLUB, string.format('Ash Club was unequipped, sub is %d', player:getEquipID(xi.slot.SUB)))
    end)
end)
