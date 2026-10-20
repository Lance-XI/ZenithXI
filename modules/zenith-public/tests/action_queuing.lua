-- ZenithXI spell and ranged attack queuing (modules/zenith-public/git-patches/103-SpelllAndRangeAttackQueuing.patch).
--
-- A spell or shot sent while the previous one is in its animation phase (state completed,
-- not yet left) is held and fired once the player can act again, instead of being dropped.
-- One sent while still casting or aiming is still refused.
--
-- skipTime() puts a 400ms tick on top of each call, so skipTime(1) moves 1.4s.

describe('Zenith action queuing', function()
    ---@type CClientEntityPair
    local player

    describe('spells', function()
        before_each(function()
            player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.WHM, level = 75 })
            player:addSpell(xi.magic.spell.PROTECT)
            player:addSpell(xi.magic.spell.BLINK)
            player:setMP(player:getMaxMP())
        end)

        it('casts a spell sent during the previous spell animation', function()
            -- Protect: 1s cast, then 2s animation
            player.actions:useSpell(player, xi.magic.spell.PROTECT)
            xi.test.world:tickEntity(player)
            xi.test.world:skipTime(1)
            assert(player:hasStatusEffect(xi.effect.PROTECT), 'precondition: Protect should have landed')

            player.actions:useSpell(player, xi.magic.spell.BLINK)
            xi.test.world:skipTime(3) -- animation ends, the queued Blink starts
            xi.test.world:skipTime(8) -- Blink: 6s cast

            assert(player:hasStatusEffect(xi.effect.BLINK), 'the spell queued during the animation was not cast')
        end)

        it('drops a queued spell that could not fire within 4 seconds', function()
            player.actions:useSpell(player, xi.magic.spell.PROTECT)
            xi.test.world:tickEntity(player)
            xi.test.world:skipTime(1)
            assert(player:hasStatusEffect(xi.effect.PROTECT), 'precondition: Protect should have landed')

            player.actions:useSpell(player, xi.magic.spell.BLINK)
            xi.test.world:skipTime(5) -- first tick after queuing is past the 4s timeout
            xi.test.world:skipTime(8)

            assert(not player:hasStatusEffect(xi.effect.BLINK), 'a stale queued spell was cast')
        end)

        it('drops a queued spell when the player dies', function()
            player.actions:useSpell(player, xi.magic.spell.PROTECT)
            xi.test.world:tickEntity(player)
            xi.test.world:skipTime(1)
            assert(player:hasStatusEffect(xi.effect.PROTECT), 'precondition: Protect should have landed')

            player.actions:useSpell(player, xi.magic.spell.BLINK)
            player:setHP(0)
            xi.test.world:tickEntity(player)
            assert(player:isDead(), 'precondition: the player should be dead')

            -- raise inside the 4s timeout, so only the death clears the queue
            player:sendReraise(4)
            player.actions:acceptRaise()
            player:setMP(player:getMaxMP())
            xi.test.world:skipTime(1)
            xi.test.world:skipTime(8)

            assert(not player:hasStatusEffect(xi.effect.BLINK), 'the spell queued before death was cast after the raise')
        end)

        it('refuses a spell sent while still casting', function()
            player.actions:useSpell(player, xi.magic.spell.PROTECT)
            xi.test.world:tickEntity(player)
            player.actions:useSpell(player, xi.magic.spell.BLINK)
            xi.test.world:skipTime(10)

            assert(player:hasStatusEffect(xi.effect.PROTECT), 'Protect should have landed')
            assert(not player:hasStatusEffect(xi.effect.BLINK), 'a spell sent mid-cast was queued')
        end)
    end)

    describe('ranged attacks', function()
        ---@type CTestEntity
        local target

        local function bulletCount()
            local ammo = player:getEquippedItem(xi.slot.AMMO)
            if ammo == nil then
                return 0
            end

            return ammo:getQuantity()
        end

        -- step until the bullet count drops to 'count', up to 'steps' calls of skipTime(1)
        local function waitForBullets(count, steps)
            for _ = 1, steps do
                if bulletCount() <= count then
                    return
                end

                xi.test.world:skipTime(1)
            end
        end

        before_each(function()
            -- same setup as systems/combat/ranged_free_phase.lua, THF has no Recycle
            player = xi.test.world:spawnPlayer({ zone = xi.zone.WEST_RONFAURE, job = xi.job.THF, level = 75 })
            target = player.entities:moveTo('Wild_Rabbit')
            target:respawn()
            target:setUnkillable(true)
            target:setBaseSpeed(0)

            local pos = target:getPos()
            player:setPos(pos.x - 5, pos.y, pos.z, 0)
            player:lookAt(target:getPos())

            player:addItem(xi.item.PLATOON_GUN)
            player:addItem(xi.item.BULLET, 99)
            player:equipItem(xi.item.PLATOON_GUN)
            player:equipItem(xi.item.BULLET)
        end)

        it('fires a shot sent while the gun is being lowered', function()
            player.actions:rangedAttack(target)
            waitForBullets(98, 6)
            assert(bulletCount() == 98, 'precondition: the first shot should fire')

            -- the shot just fired: the range state is completed but still lowering the weapon
            player.actions:rangedAttack(target)
            waitForBullets(97, 8)

            assert(bulletCount() == 97, 'the shot queued while lowering the gun did not fire')
        end)

        it('refuses a shot sent while still aiming', function()
            player.actions:rangedAttack(target)
            xi.test.world:tickEntity(player)
            player.actions:rangedAttack(target)
            waitForBullets(97, 8)

            assert(bulletCount() == 98, string.format('expected one shot, %d bullets used', 99 - bulletCount()))
        end)
    end)
end)
