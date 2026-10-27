-- ZenithXI avatar base damage (modules/zenith-public/lua/3-complete/avatar_base_damage.lua).
--
-- Avatar weapon damage is (Level + 2) / 2, plus base's +2 damage offset.

describe('Zenith avatar base damage', function()
    it('uses (Level + 2) / 2 weapon damage', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.SMN, level = 50 })
        player:spawnPet(xi.petId.CARBUNCLE)

        local pet = player:getPet()
        assert(pet, 'Carbuncle was not summoned')

        local level    = pet:getMainLvl()
        local expected = math.floor((level + 2) / 2) + 2 -- weapon damage + base's damage offset

        assert(pet:getWeaponDmg() == expected, string.format('level %d Carbuncle: expected %d damage, got %d', level, expected, pet:getWeaponDmg()))
    end)
end)
