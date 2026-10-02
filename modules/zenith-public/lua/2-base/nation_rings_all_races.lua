-----------------------------------
-- Module: Nation Rings for All Races
-- Ensures all new characters receive the nation ring for their
-- chosen starting nation, regardless of race selection.
--
-- Base behavior only gives the ring if the race's "home nation"
-- matches the chosen nation. This module removes that restriction.
--
-- The engine re-runs charCreate at login for any character without the
-- NEW_ADVENTURER title, not only brand-new ones (luautils.cpp OnGameIn), so the
-- ring is a one-time grant: it is skipped when the character already owns any
-- nation ring.
-----------------------------------
local m = Module:new('b_nation_rings_all_races')

-- Map nations to their corresponding rings
local nationRings =
{
    [xi.nation.SANDORIA] = xi.item.SAN_DORIAN_RING,
    [xi.nation.BASTOK]   = xi.item.BASTOKAN_RING,
    [xi.nation.WINDURST] = xi.item.WINDURSTIAN_RING,
}

m:addOverride('xi.player.charCreate', function(player)
    -- Call the original charCreate function
    super(player)

    -- Ensure player has their nation's ring regardless of race
    local nation = player:getNation()
    local ringId = nationRings[nation]

    if not ringId then
        return
    end

    -- Checking only the current nation's ring would hand a second ring to a
    -- character who has since changed nations. This also covers the case where
    -- super() already granted the home-nation ring.
    for _, ownedRingId in pairs(nationRings) do
        if player:hasItem(ownedRingId) then
            return
        end
    end

    player:addItem(ringId)
end)

return m
