-----------------------------------
-- No EXP for a party with a 10+ level gap
-- Restores the old main.lua setting lost in the LSB EXP rewrite (LandSandBoat/server#10865):
-- if any member counted for the kill is 10 or more levels above the lowest one, nobody gets EXP.
--
-- Members are counted like charutils::DistributeExperiencePoints does: alliance members in the
-- mob's zone within 100 yalms of it, at their EXP level (synced level unless the level
-- restriction grants EXP at true level). A level sync brings everyone to the same level, so a
-- synced party is never affected.
-----------------------------------
local m = Module:new('c_expLevelGap')

local maxLevelGap = 9

-- Same as charutils::GetExpLevel
local getExpLevel = function(member)
    local restriction = member:getStatusEffect(xi.effect.LEVEL_RESTRICTION)
    if restriction and restriction:getSubPower() == 1 then
        return member:getJobLevel(member:getMainJob())
    end

    return member:getMainLvl()
end

local hasLevelGap = function(member, mob)
    local lowest  = nil
    local highest = nil

    for _, partyMember in ipairs(member:getAlliance()) do
        if
            partyMember:getZoneID() == mob:getZoneID() and
            partyMember:checkDistance(mob) < 100
        then
            local level = getExpLevel(partyMember)
            lowest      = math.min(lowest or level, level)
            highest     = math.max(highest or level, level)
        end
    end

    return lowest ~= nil and highest - lowest > maxLevelGap
end

m:addOverride('xi.experiencePoints.calculate', function(member, mob, data)
    local result = super(member, mob, data)

    if result and hasLevelGap(member, mob) then
        result.exp = 0
    end

    return result
end)

return m
