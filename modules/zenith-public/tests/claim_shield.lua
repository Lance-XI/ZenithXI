-- ZenithXI claim shield (modules/zenith-public/lua/3-complete/claim_shield.lua).
--
-- The module hooks each NM's onMobInitialize. Some NMs only exist in mobs.yaml, with no
-- scripts/zones/<zone>/mobs/<name>.lua to hook, so the module builds their script table itself.
-- If these fail, those NMs spawn without a claim shield.

describe('Zenith claim shield', function()
    local scriptlessNms =
    {
        { zone = xi.zone.BEAUCEDINE_GLACIER,  name = 'Nue' },
        { zone = xi.zone.KING_RANPERRES_TOMB, name = 'Crypt_Ghost' },
    }

    for _, nm in ipairs(scriptlessNms) do
        it(string.format('hooks %s, which has no mob script', nm.name), function()
            local player = xi.test.world:spawnPlayer({ zone = nm.zone })
            local mob    = player.entities:get(nm.name)

            mob:respawn()

            -- set by the SPAWN listener the module adds in onMobInitialize
            assert(mob:getLocalVar('CS_SpawnTime') > 0, string.format('%s spawned without the claim shield listeners', nm.name))
        end)
    end
end)
