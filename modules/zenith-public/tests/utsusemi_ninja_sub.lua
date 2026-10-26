-- ZenithXI Utsusemi with Ninja subjob (modules/zenith-public/lua/2-base/utsusemi_ninja_sub.lua).
--
-- When Ninja is not the main job, Utsusemi: Ichi gives 2 shadows instead of 3 (icon COPY_IMAGE_2),
-- and Utsusemi: Ichi and Ni take 1 s longer to cast. LSB gives Ichi 3 shadows on any job and adds
-- no cast time. Main job Ninja is unchanged (the NIN cases pass with or without the module on purpose).
-- xi.mod.UTSUSEMI_BONUS adds shadows before the module takes one away, so the icon has to follow the
-- reduced count: +1 gives 3 shadows and COPY_IMAGE_3 (LSB's icon for 4 shadows is COPY_IMAGE_4), +2 gives
-- 4 and +3 gives 5, both COPY_IMAGE_4 (4 or more share one icon, as in utils.shadowAbsorb). Every item
-- carrying the mod in LSB's item_mods (Iga Kyahan +2, Hattori Kyahan, Andartia's Mantle) is NIN-only
-- gear, which a Ninja subjob cannot wear, so these cases set the mod directly.
-- The casting cases read the spell's cast time from the MAGIC_START listener, which fires on the
-- cast's own copy of the spell after onMagicCastingCheck has run.

describe('Zenith Utsusemi with Ninja subjob', function()
    ---@type CClientEntityPair
    local player

    local function setJobs(mainJob, subJob)
        player:changeJob(mainJob)
        player:setLevel(75)
        player:changesJob(subJob)
        player:setsLevel(37)
        assert(player:getMainJob() == mainJob and player:getSubJob() == subJob, 'precondition: jobs did not change')
    end

    before_each(function()
        player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WAR, level = 75 })
    end)

    describe('shadow count', function()
        local function ichiPower()
            local caster = GetPlayerByID(player:getID())
            local spell  = GetSpell(xi.magic.spell.UTSUSEMI_ICHI)

            return xi.spells.enhancing.calculateNinjutsuPower(caster, caster, spell, xi.magic.spell.UTSUSEMI_ICHI, 1, xi.effect.COPY_IMAGE)
        end

        it('gives 2 shadows and the 2 shadow icon from Utsusemi: Ichi with Ninja subjob', function()
            setJobs(xi.job.WAR, xi.job.NIN)
            local power, icon = ichiPower()

            assert(power == 2, string.format('WAR/NIN Ichi shadows: expected 2, got %d', power))
            assert(icon == xi.effect.COPY_IMAGE_2, string.format('WAR/NIN Ichi icon: expected COPY_IMAGE_2 (%d), got %d', xi.effect.COPY_IMAGE_2, icon))
        end)

        -- Control: passes with or without the module.
        it('keeps 3 shadows from Utsusemi: Ichi on main job Ninja', function()
            setJobs(xi.job.NIN, xi.job.WAR)
            local power, icon = ichiPower()

            assert(power == 3, string.format('NIN/WAR Ichi shadows: expected 3, got %d', power))
            assert(icon == xi.effect.COPY_IMAGE_3, string.format('NIN/WAR Ichi icon: expected COPY_IMAGE_3 (%d), got %d', xi.effect.COPY_IMAGE_3, icon))
        end)

        -- Through the spell script, so the case notices if LSB stops calling calculateNinjutsuPower.
        it('puts 2 shadows on a Ninja subjob caster through the Utsusemi: Ichi spell script', function()
            setJobs(xi.job.WAR, xi.job.NIN)
            local caster = GetPlayerByID(player:getID())
            player:delStatusEffect(xi.effect.COPY_IMAGE)

            xi.actions.spells.ninjutsu.utsusemi_ichi.onSpellCast(caster, caster, GetSpell(xi.magic.spell.UTSUSEMI_ICHI))

            assert(player:hasStatusEffect(xi.effect.COPY_IMAGE), 'Utsusemi: Ichi gave no Copy Image')
            local shadows = player:getMod(xi.mod.UTSUSEMI)
            assert(shadows == 2, string.format('WAR/NIN Ichi shadows after the spell: expected 2, got %d', shadows))
        end)

        local bonusCases =
        {
            { bonus = 1, shadows = 3, icon = xi.effect.COPY_IMAGE_3, iconName = 'COPY_IMAGE_3' },
            { bonus = 2, shadows = 4, icon = xi.effect.COPY_IMAGE_4, iconName = 'COPY_IMAGE_4' },
            { bonus = 3, shadows = 5, icon = xi.effect.COPY_IMAGE_4, iconName = 'COPY_IMAGE_4' },
        }

        for _, case in ipairs(bonusCases) do
            it(string.format('gives %d shadows and the %s icon from Utsusemi: Ichi with Ninja subjob and +%d Utsusemi bonus', case.shadows, case.iconName, case.bonus), function()
                setJobs(xi.job.WAR, xi.job.NIN)
                player:addMod(xi.mod.UTSUSEMI_BONUS, case.bonus)
                assert(player:getMod(xi.mod.UTSUSEMI_BONUS) == case.bonus, 'precondition: Utsusemi bonus was not applied')

                local power, icon = ichiPower()
                assert(power == case.shadows, string.format('WAR/NIN +%d Ichi shadows: expected %d, got %d', case.bonus, case.shadows, power))
                assert(icon == case.icon, string.format('WAR/NIN +%d Ichi icon: expected %s (%d), got %d', case.bonus, case.iconName, case.icon, icon))

                -- The effect the spell script really applies, so the icon is checked where the client sees it.
                local caster = GetPlayerByID(player:getID())
                player:delStatusEffect(xi.effect.COPY_IMAGE)
                xi.actions.spells.ninjutsu.utsusemi_ichi.onSpellCast(caster, caster, GetSpell(xi.magic.spell.UTSUSEMI_ICHI))

                local effect = player:getStatusEffect(xi.effect.COPY_IMAGE)
                assert(effect ~= nil, 'Utsusemi: Ichi gave no Copy Image')
                local shadows = player:getMod(xi.mod.UTSUSEMI)
                assert(shadows == case.shadows, string.format('WAR/NIN +%d shadows after the spell: expected %d, got %d', case.bonus, case.shadows, shadows))
                assert(effect:getIcon() == case.icon, string.format('WAR/NIN +%d Copy Image icon: expected %s (%d), got %d', case.bonus, case.iconName, case.icon, effect:getIcon()))
            end)
        end

        -- Control: passes with or without the module.
        it('keeps 4 shadows and the 4 shadow icon from Utsusemi: Ichi on main job Ninja with +1 Utsusemi bonus', function()
            setJobs(xi.job.NIN, xi.job.WAR)
            player:addMod(xi.mod.UTSUSEMI_BONUS, 1)
            local power, icon = ichiPower()

            assert(power == 4, string.format('NIN/WAR +1 Ichi shadows: expected 4, got %d', power))
            assert(icon == xi.effect.COPY_IMAGE_4, string.format('NIN/WAR +1 Ichi icon: expected COPY_IMAGE_4 (%d), got %d', xi.effect.COPY_IMAGE_4, icon))
        end)
    end)

    describe('cast time', function()
        local castTime

        local function castOnSelf(spellId)
            castTime = nil
            player:addSpell(spellId)
            player:addItem(xi.item.SHIHEI, 12)
            player:setMP(player:getMaxMP())
            player:addListener('MAGIC_START', 'ZENITH_TEST_UTSUSEMI', function(caster, target, spell)
                castTime = spell:getCastTime()
            end)

            player.actions:useSpell(player, spellId)
            for _ = 1, 5 do
                xi.test.world:skipTime(2)
            end

            player:removeListener('ZENITH_TEST_UTSUSEMI')
            assert(castTime ~= nil, string.format('precondition: spell %d never started casting', spellId))

            return castTime
        end

        local castCases =
        {
            { name = 'Utsusemi: Ichi', spellId = xi.magic.spell.UTSUSEMI_ICHI },
            { name = 'Utsusemi: Ni',   spellId = xi.magic.spell.UTSUSEMI_NI   },
        }

        for _, case in ipairs(castCases) do
            it(string.format('adds 1 s to the %s cast time with Ninja subjob', case.name), function()
                setJobs(xi.job.WAR, xi.job.NIN)
                local base   = GetSpell(case.spellId):getCastTime()
                local actual = castOnSelf(case.spellId)

                assert(actual == base + 1000, string.format('WAR/NIN %s cast time: expected %d ms, got %d ms', case.name, base + 1000, actual))
            end)

            -- Control: passes with or without the module.
            it(string.format('keeps the %s cast time on main job Ninja', case.name), function()
                setJobs(xi.job.NIN, xi.job.WAR)
                local base   = GetSpell(case.spellId):getCastTime()
                local actual = castOnSelf(case.spellId)

                assert(actual == base, string.format('NIN/WAR %s cast time: expected %d ms, got %d ms', case.name, base, actual))
            end)
        end

        it('leaves a Ninja subjob caster with 2 shadows after casting Utsusemi: Ichi', function()
            setJobs(xi.job.WAR, xi.job.NIN)
            castOnSelf(xi.magic.spell.UTSUSEMI_ICHI)

            assert(player:hasStatusEffect(xi.effect.COPY_IMAGE), 'casting Utsusemi: Ichi gave no Copy Image')
            local shadows = player:getMod(xi.mod.UTSUSEMI)
            assert(shadows == 2, string.format('WAR/NIN shadows after casting Ichi: expected 2, got %d', shadows))
        end)
    end)
end)
