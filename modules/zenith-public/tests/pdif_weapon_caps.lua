-- ZenithXI pDIF weapon caps (modules/zenith-public/lua/2-base/pdif_weapon_caps.lua).
--
-- Player pDIF caps go back to the post August 2007 values: 1H melee 2.0, 2H melee 2.25,
-- ranged 3.0 (LSB: 3.25 to 4 by skill). The module only rewrites
-- xi.combat.physical.pDifWeaponCapTable, so the table cases read it and the
-- calculateMeleePDIF cases check the cap actually limits a swing.
-- Melee setup: target DEF forced to 1, so the attack ratio is far over every cap, and
-- math.randomInt returns the top of its range, so pDIF is cap * 1.05 (top melee random factor).

local capCases =
{
    { name = 'hand-to-hand',  skill = xi.skill.HAND_TO_HAND,  cap = 2    },
    { name = 'dagger',        skill = xi.skill.DAGGER,        cap = 2    },
    { name = 'sword',         skill = xi.skill.SWORD,         cap = 2    },
    { name = 'great sword',   skill = xi.skill.GREAT_SWORD,   cap = 2.25 },
    { name = 'axe',           skill = xi.skill.AXE,           cap = 2    },
    { name = 'great axe',     skill = xi.skill.GREAT_AXE,     cap = 2.25 },
    { name = 'scythe',        skill = xi.skill.SCYTHE,        cap = 2.25 },
    { name = 'polearm',       skill = xi.skill.POLEARM,       cap = 2.25 },
    { name = 'katana',        skill = xi.skill.KATANA,        cap = 2    },
    { name = 'great katana',  skill = xi.skill.GREAT_KATANA,  cap = 2.25 },
    { name = 'club',          skill = xi.skill.CLUB,          cap = 2    },
    { name = 'staff',         skill = xi.skill.STAFF,         cap = 2.25 },
    { name = 'archery',       skill = xi.skill.ARCHERY,       cap = 3    },
    { name = 'marksmanship',  skill = xi.skill.MARKSMANSHIP,  cap = 3    },
    { name = 'throwing',      skill = xi.skill.THROWING,      cap = 3    },
}

describe('Zenith pDIF weapon caps', function()
    for _, case in ipairs(capCases) do
        it(string.format('caps %s pDIF at %.2f', case.name, case.cap), function()
            local cap = xi.combat.physical.pDifWeaponCapTable[case.skill]
            assert(cap == case.cap, string.format('%s pDIF cap: expected %.2f, got %s', case.name, case.cap, tostring(cap)))
        end)
    end

    describe('on a melee swing', function()
        ---@type CClientEntityPair
        local player
        ---@type CTestEntity
        local mob

        before_each(function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 75 })
            mob    = player.entities:moveTo('Wild_Rabbit')
            mob:respawn()
            mob:setMod(xi.mod.DEF, -10000)
            mob:setMod(xi.mod.DEFP, 0)

            -- Damage limit mods raise the cap on top of the table value (a fresh level 75 WAR has some).
            player:setMod(xi.mod.DAMAGE_LIMIT, 0)
            player:setMod(xi.mod.DAMAGE_LIMITP, 0)
        end)

        local function meleePDif(skill)
            local actor  = GetPlayerByID(player:getID())
            local target = GetMobByID(mob:getID())

            assert(target:getStat(xi.mod.DEF) <= 1, string.format('precondition: target DEF should be 1 or less, got %d', target:getStat(xi.mod.DEF)))
            assert(actor:getStat(xi.mod.ATT) >= 10, string.format('precondition: player attack should be at least 10, got %d', actor:getStat(xi.mod.ATT)))

            -- Every roll returns its maximum: no pDIF spike, upper bound picked, +5% melee random.
            stub('math.randomInt', function(low, high)
                return high
            end)

            return xi.combat.physical.calculateMeleePDIF(actor, target, skill, 1.0, false, false, false, 0, false, xi.slot.MAIN, false)
        end

        it('limits a one-handed sword swing to pDIF 2.0', function()
            local pDif     = meleePDif(xi.skill.SWORD)
            local expected = 2 * 1.05

            assert(math.abs(pDif - expected) < 0.001, string.format('sword pDIF: expected %.3f, got %.3f', expected, pDif))
        end)

        it('limits a two-handed great sword swing to pDIF 2.25', function()
            local pDif     = meleePDif(xi.skill.GREAT_SWORD)
            local expected = 2.25 * 1.05

            assert(math.abs(pDif - expected) < 0.001, string.format('great sword pDIF: expected %.3f, got %.3f', expected, pDif))
        end)
    end)
end)
