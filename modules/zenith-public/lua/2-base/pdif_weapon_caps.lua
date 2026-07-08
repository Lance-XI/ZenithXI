-----------------------------------
-- Post August 2007 pDIF weapon caps
-- Overrides xi.combat.physical.pDifWeaponCapTable (PC melee/ranged pDIF caps):
--   1H melee = 2.0, 2H melee = 2.25, ranged 3.0. Automaton are included for completeness, not active behavior.
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('b_pdif_weapon_caps')

-- Data-only module: dummy override so the loader does not report
-- "No overrides found" (enforced in src/map/utils/moduleutils.cpp).
m:addOverride('xi.dummyFunc', function()
end)

xi.combat.physical.pDifWeaponCapTable[xi.skill.HAND_TO_HAND    ] = 2
xi.combat.physical.pDifWeaponCapTable[xi.skill.DAGGER          ] = 2
xi.combat.physical.pDifWeaponCapTable[xi.skill.SWORD           ] = 2
xi.combat.physical.pDifWeaponCapTable[xi.skill.GREAT_SWORD     ] = 2.25
xi.combat.physical.pDifWeaponCapTable[xi.skill.AXE             ] = 2
xi.combat.physical.pDifWeaponCapTable[xi.skill.GREAT_AXE       ] = 2.25
xi.combat.physical.pDifWeaponCapTable[xi.skill.SCYTHE          ] = 2.25
xi.combat.physical.pDifWeaponCapTable[xi.skill.POLEARM         ] = 2.25
xi.combat.physical.pDifWeaponCapTable[xi.skill.KATANA          ] = 2
xi.combat.physical.pDifWeaponCapTable[xi.skill.GREAT_KATANA    ] = 2.25
xi.combat.physical.pDifWeaponCapTable[xi.skill.CLUB            ] = 2
xi.combat.physical.pDifWeaponCapTable[xi.skill.STAFF           ] = 2.25
xi.combat.physical.pDifWeaponCapTable[xi.skill.AUTOMATON_MELEE ] = 3
xi.combat.physical.pDifWeaponCapTable[xi.skill.AUTOMATON_RANGED] = 3
xi.combat.physical.pDifWeaponCapTable[xi.skill.AUTOMATON_MAGIC ] = 3
xi.combat.physical.pDifWeaponCapTable[xi.skill.ARCHERY         ] = 3
xi.combat.physical.pDifWeaponCapTable[xi.skill.MARKSMANSHIP    ] = 3
xi.combat.physical.pDifWeaponCapTable[xi.skill.THROWING        ] = 3

return m
