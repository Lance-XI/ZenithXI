-- ZenithXI era stat scaling (modules/zenith-public/git-patches/106-era-level-scaled-stat-multipliers.patch).
--
-- For players the STR->ATT, DEX->ACC and VIT->DEF multipliers follow the era curve instead of the
-- main.*_MULTIPLIER settings: flat start value up to level 36, linear to the end value at 75.
-- Each case adds 200 of a stat and reads how much the derived value moved, so skill, traits
-- and level DEF do not matter. A failure here after an LSB merge means the patch lost a hunk.

local statBonus = 200

-- GetEraScaledMultiplier(level, startValue, endValue) from the patch
local function eraMultiplier(level, startValue, endValue)
    if level < 37 then
        return startValue
    elseif level >= 75 then
        return endValue
    end

    return startValue + (endValue - startValue) * ((level - 37) / 38)
end

describe('Zenith era stat scaling', function()
    ---@type CClientEntityPair
    local player

    -- How much 'derived' grows per point of 'stat', measured over statBonus points.
    local function measureMultiplier(stat, derived)
        local before = player:getStat(derived)
        player:addMod(stat, statBonus)
        local after = player:getStat(derived)
        player:delMod(stat, statBonus)

        return (after - before) / statBonus
    end

    local function setUp(job, level, weaponId)
        player:changeJob(job)
        player:setLevel(level)

        -- percent mods from traits (Attack Bonus, Smite on 2H/H2H) would scale the stat part too
        player:setMod(xi.mod.ATTP, 0)
        player:setMod(xi.mod.DEFP, 0)
        player:setMod(xi.mod.SMITE, 0)

        if weaponId then
            player:addItem(weaponId)
            player:equipItem(weaponId, nil, xi.slot.MAIN)
            assert(player:getEquipID(xi.slot.MAIN) == weaponId, string.format('could not equip weapon %d', weaponId))
        end
    end

    local function assertMultiplier(actual, expected, what)
        -- the engine floors the stat part, so allow one point over statBonus
        assert(math.abs(actual - expected) <= 1 / statBonus, string.format('%s: expected %.4f, got %.4f', what, expected, actual))
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE })
    end)

    -- 36 is the last level on the start value, 56 is halfway along the curve, 75 is the end value
    for _, level in ipairs({ 30, 36, 56, 75 }) do
        describe(string.format('at level %d', level), function()
            it('scales one-handed STR to attack from 0.5 to 0.75', function()
                setUp(xi.job.WAR, level, xi.item.BRONZE_SWORD)
                assertMultiplier(measureMultiplier(xi.mod.STR, xi.mod.ATT), eraMultiplier(level, 0.5, 0.75), 'one-handed STR')
            end)

            it('keeps two-handed STR to attack at 0.75', function()
                setUp(xi.job.WAR, level, xi.item.CLAYMORE)
                assertMultiplier(measureMultiplier(xi.mod.STR, xi.mod.ATT), 0.75, 'two-handed STR')
            end)

            it('scales hand-to-hand STR to attack from 0.5 to 0.625', function()
                setUp(xi.job.MNK, level, xi.item.CESTI)
                assertMultiplier(measureMultiplier(xi.mod.STR, xi.mod.ATT), eraMultiplier(level, 0.5, 0.625), 'hand-to-hand STR')
            end)

            it('scales one-handed DEX to accuracy from 0.5 to 0.75', function()
                setUp(xi.job.WAR, level, xi.item.BRONZE_SWORD)
                assertMultiplier(measureMultiplier(xi.mod.DEX, xi.mod.ACC), eraMultiplier(level, 0.5, 0.75), 'one-handed DEX')
            end)

            it('scales VIT to defence from 0.5 to 1.0', function()
                setUp(xi.job.WAR, level)
                assertMultiplier(measureMultiplier(xi.mod.VIT, xi.mod.DEF), eraMultiplier(level, 0.5, 1.0), 'VIT')
            end)
        end)
    end
end)
