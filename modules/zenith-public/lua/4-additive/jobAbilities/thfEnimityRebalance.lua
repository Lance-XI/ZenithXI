-----------------------------------
-- Thief Enmity Rebalance
-- Custom modifications for ZenithXI
-----------------------------------
require('modules/module_utils')
-----------------------------------
local m = Module:new('a-j_thf_enmity_rebal')

-----------------------------------
-- Sneak Attack & Trick Attack Recast Reduction
-----------------------------------
-- Reduces the recast time of Sneak Attack and Trick Attack
-- based on the number of merit points spent in Ambush
-- Each merit point reduces recast by 1 second
local adjustRecast = function(player, ability)
    local merits = player:getMerit(xi.merit.AMBUSH)

    if merits > 0 then
        -- Reduce recast timer by 1 second per merit point
        -- Minimum recast is 0 seconds (instant)
        ability:setRecast(math.max(0, ability:getRecast() - merits))
    end
end

-----------------------------------
-- Apply Recast Reduction to Sneak Attack
-----------------------------------
m:addOverride('xi.actions.abilities.sneak_attack.onAbilityCheck', function(player, target, ability)
    adjustRecast(player, ability)

    return super(player, target, ability)
end)

-----------------------------------
-- Apply Recast Reduction to Trick Attack
-----------------------------------
m:addOverride('xi.actions.abilities.trick_attack.onAbilityCheck', function(player, target, ability)
    adjustRecast(player, ability)

    return super(player, target, ability)
end)

-----------------------------------
-- Enhanced Trick Attack Enmity Transfer
-----------------------------------
-- When Trick Attack is consumed by the Thief's attack, transfers a portion of the
-- Thief's enmity (hate) to the designated trick attack partner (tank/trust)
-- The amount transferred scales with Thief level:
-- - At level 75 THF: 50% of enmity is transferred
-- - Lower levels transfer proportionally less (e.g., level 37 = 25%)
--
-- How the engine ends Trick Attack (checked against LSB 8a605b1bd0):
-- - onEffectLose fires ONCE per effect: RemoveStatusEffect marks the effect deleted before
--   calling Lua, and useTrickAttack adds a single effect per use. The only other fire is our own
--   temporary re-apply below (which also fires onEffectGain).
-- - A hit consumes it: the first melee swing that lands (CAttack::ProcessDamage) or the start of a
--   non-ranged weaponskill. Both run BEFORE that hit's damage enmity is routed to the partner,
--   which is fine: the round's damage enmity goes to the partner, not the Thief, so the Thief's
--   share is the same as when the effect was removed after the round. A first swing that does
--   not land (miss, parry, shadows) leaves the effect up until a later hit.
-- - It also ends by expiry, death, party/job change, or being replaced by another use.
--
-- Flag usage (localVars on the Thief):
-- - TA_ARMED: Set when a real TA effect is gained and cleared by the first loss after it, so a TA
--   use gives at most one transfer however often onEffectLose fires
-- - TA_PROCESSING: Prevents recursive re-entry when we temporarily re-add TA
--   (delStatusEffectSilent still triggers onEffectLose, and the re-add triggers onEffectGain)
--
-- Expiry does not transfer, since no Trick Attack hit happened.
m:addOverride('xi.effects.trick_attack.onEffectGain', function(player, effect)
    super(player, effect)

    -- Our own temporary re-apply below lands here too and must not arm a transfer
    if player:getLocalVar('TA_PROCESSING') == 1 then
        return
    end

    player:setLocalVar('TA_ARMED', 1)
end)

m:addOverride('xi.effects.trick_attack.onEffectLose', function(player, effect)
    -- Always call super first for proper effect cleanup
    super(player, effect)

    -- Prevent recursive re-entry during our temp effect manipulation
    -- delStatusEffectSilent still triggers onEffectLose, so we must guard against it
    if player:getLocalVar('TA_PROCESSING') == 1 then
        return
    end

    -- Only the first loss after a real gain may transfer
    if player:getLocalVar('TA_ARMED') == 0 then
        return
    end

    player:setLocalVar('TA_ARMED', 0)

    -- The effect timed out: no Trick Attack hit happened, nothing to transfer
    if effect:getTimeRemaining() == 0 then
        return
    end

    -- Calculate enmity transfer percentage based on Thief level
    -- Main job THF uses main level, subjob THF uses sub level
    -- Formula: 50% * (THF Level / 75)
    -- Example: Level 75 THF = 50% transfer, Level 37 THF = 25% transfer
    local thfLevel = 0
    if player:getMainJob() == xi.job.THF then
        thfLevel = player:getMainLvl()
    elseif player:getSubJob() == xi.job.THF then
        thfLevel = player:getSubLvl()
    end

    -- Exit if THF level is 0 (shouldn't happen, but guard against it)
    if thfLevel == 0 then
        return
    end

    local taEnmityPerc = 0.5 * thfLevel / 75
    local pTarget = player:getTarget()

    if pTarget and pTarget:isMob() then
        -- CE = Cumulative Enmity (permanent hate)
        -- VE = Volatile Enmity (decaying hate)
        local ce = pTarget:getCE(player)
        local ve = pTarget:getVE(player)

        -- Nothing to transfer. Setting enmity would also create empty hate list entries before
        -- the TA hit, costing the partner the first-hit enmity bonus on a fresh mob
        if ce == 0 and ve == 0 then
            return
        end

        -- Set processing flag to prevent recursive calls from delStatusEffectSilent
        player:setLocalVar('TA_PROCESSING', 1)

        -- Temporarily re-apply Trick Attack effect to identify the TA partner
        -- This is needed because getTrickAttackChar requires the effect to be active
        player:addStatusEffect(xi.effect.TRICK_ATTACK, { power = 0, tick = 0, duration = 10, origin = player })
        local taTarget = player:getTrickAttackChar(pTarget)
        player:delStatusEffectSilent(xi.effect.TRICK_ATTACK)

        -- Clear processing flag
        player:setLocalVar('TA_PROCESSING', 0)

        if taTarget then
            -- Transfer calculated percentage of enmity from Thief to TA partner
            -- The partner gains the transferred enmity
            pTarget:setCE(taTarget, pTarget:getCE(taTarget) + ce * taEnmityPerc)
            pTarget:setVE(taTarget, pTarget:getVE(taTarget) + ve * taEnmityPerc)

            -- Reduce Thief's enmity by the transferred amount
            -- Thief keeps the remaining percentage
            pTarget:setCE(player, ce * (1 - taEnmityPerc))
            pTarget:setVE(player, ve * (1 - taEnmityPerc))
        end
    end
end)

return m
