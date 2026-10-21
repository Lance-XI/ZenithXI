-----------------------------------
-- Avatar base damage before the SoA update (ZENITHDEV-249)
-- Avatar weapon damage is (Level + 2) / 2, instead of base's Level + 2. Base's +2 damage offset
-- (xi.pets.avatar.onPetStatCalculate) still applies on top.
--
-- From LSB's modules/era/lua/globals/pets/avatar.lua, without its SoA condition. That module's
-- current version only sets BASE_DAMAGE_MULTIPLIER to 50 without setting the weapon damage, so it
-- halves the level petutils starts with: Level / 2. Its first version (f95916e166) set the weapon
-- damage to (Level + 2) / 2, which is what this does.
-- https://docs.google.com/spreadsheets/d/1YBoveP-weMdidrirY-vPDzHyxbEI2ryECINlfCnFkLI/edit?pli=1&gid=562618210#gid=562618210
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('c_avatarBaseDamage')

m:addOverride('xi.pets.avatar.calculateAvatarWeaponDamage', function(pet)
    local weaponDamage = math.floor((pet:getMainLvl() + 2) / 2)

    pet:setDamage(weaponDamage, xi.slot.MAIN)
    pet:setDamage(weaponDamage, xi.slot.RANGED)
end)

return m
