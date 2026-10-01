-----------------------------------
-- EXP Scroll Adjustments
-- Public Module for ZenithXI
-----------------------------------
-- Raises the experience point award of the two low-level EXP scrolls.
--
-- The override mirrors the base scripts' (target, user, item, action)
-- contract exactly:
--   addExp(exp, false) -- scrolls must never award limit points
--   action:messageID(...) -- the engine suppresses its own gain message
--                            when allowLimitPoints is false
--   return exp -- becomes actionResult.param, so the full amount is
--                 shown even when EXP is capped
-----------------------------------

local m = Module:new('c-i_exp_scroll_adj')

-- Page from the Dragon Chronicles: 500-1000 -> 1000-1500 EXP
m:addOverride('xi.items.page_from_the_dragon_chronicles.onItemUse', function(target, user, item, action)
    local exp = xi.settings.main.EXP_RATE * math.random(1000, 1500)

    target:addExp(exp, false)
    action:messageID(target:getID(), xi.msg.basic.ITEM_EXP_GAINED)

    return exp
end)

-- Page from Miratete's Memoirs: 750-1500 -> 1250-2000 EXP
m:addOverride('xi.items.page_from_miratetes_memoirs.onItemUse', function(target, user, item, action)
    local exp = xi.settings.main.EXP_RATE * math.random(1250, 2000)

    target:addExp(exp, false)
    action:messageID(target:getID(), xi.msg.basic.ITEM_EXP_GAINED)

    return exp
end)

return m
