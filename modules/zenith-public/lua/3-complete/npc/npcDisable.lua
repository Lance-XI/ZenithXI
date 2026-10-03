-----------------------------------
-- Disabled NPCs
--
-- Replaces modules/zenith-public/sql/disable_npc.sql, which stopped doing
-- anything when upstream moved zone NPCs out of `npc_list` and into
-- data/zones/<zone>/npcs.yaml (3b73f021e4). That file ran
-- `UPDATE npc_list SET status = 3, widescan = 0 WHERE BINARY name IN (...)`
-- plus the same update for the Treasure Coffer at npcid + 1 of each Gobbie
-- Mystery NPC. `npc_list` is now only read for instanced zones, and none of
-- these names exist there, so it matched nothing.
--
-- Status 3 is xi.status.INVISIBLE, which is what the SQL wrote. The widescan
-- column needs no counterpart: CNpcEntity::isWideScannable() requires
-- status NORMAL, so an invisible NPC never shows on widescan (and Lua has no
-- widescan binding to write anyway).
--
-- Names are NPC script names (entity:getName(), the yaml `script` key, the old
-- `name` column) and are compared case-sensitively, like BINARY was. The rule
-- is name-based across every zone (Survival_Guide alone is in 98), so it runs
-- from xi.server.onServerStart over every loaded zone. That is after every
-- Zone.onInitialize has finished, so nothing re-shows them afterwards.
-- GetZone() is nil for zones this map process does not host.
--
-- Every name below was checked against the current data/zones/*/npcs.yaml and
-- all of them still exist. Each of the 11 Gobbie Mystery NPCs still has its
-- Treasure_Coffer at npcid + 1.
--
-- Public module for ZenithXI
-----------------------------------
require('modules/module_utils')

local m = Module:new('c-n_npc_disable')

-----------------------------------
-- NPC script names to hide in every zone
-----------------------------------
local disabledNpcs =
{
    ['Arbitrix']             = true,
    ['Bountibox']            = true,
    ['Delivery_Crate']       = true,
    ['Falgima']              = true,
    ['Funtrox']              = true,
    ['Habitox']              = true,
    ['Hunt_Registry']        = true,
    ['Magian_Moogle']        = true,
    ['Magian_Moogle_Blue']   = true,
    ['Magian_Moogle_Green']  = true,
    ['Magian_Moogle_Orange'] = true,
    ['MandragoraAssi']       = true,
    ['Mapitoto']             = true,
    ['Mystrix']              = true,
    ['Priztrix']             = true,
    ['Rewardox']             = true,
    ['Specilox']             = true,
    ['Splintery_Chest']      = true,
    ['Survival_Guide']       = true,
    ['Sweepstox']            = true,
    ['Symphonic_Curator']    = true,
    ['Syrillia']             = true,
    ['Theraisie']            = true,
    ['Winrix']               = true,
    ['Wondrix']              = true,
}

-----------------------------------
-- Gobbie Mystery NPCs: the Treasure Coffer one npcid up is hidden with them
-----------------------------------
local gobbieBoxes =
{
    ['Arbitrix']  = true,
    ['Bountibox'] = true,
    ['Funtrox']   = true,
    ['Habitox']   = true,
    ['Mystrix']   = true,
    ['Priztrix']  = true,
    ['Rewardox']  = true,
    ['Specilox']  = true,
    ['Sweepstox'] = true,
    ['Winrix']    = true,
    ['Wondrix']   = true,
}

local function disableZoneNpcs(zone)
    for _, npc in ipairs(zone:getNPCs()) do
        local name = npc:getName()

        if disabledNpcs[name] then
            npc:setStatus(xi.status.INVISIBLE)
        end

        if gobbieBoxes[name] then
            local coffer = GetNPCByID(npc:getID() + 1)

            if coffer then
                coffer:setStatus(xi.status.INVISIBLE)
            end
        end
    end
end

m:addOverride('xi.server.onServerStart', function()
    super()

    for zoneId in pairs(zxi.zoneName) do
        local zone = GetZone(zoneId)

        if zone then
            disableZoneNpcs(zone)
        end
    end
end)

return m
