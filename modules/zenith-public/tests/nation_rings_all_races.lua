-- ZenithXI nation rings for all races (modules/zenith-public/lua/2-base/nation_rings_all_races.lua).
--
-- LSB's xi.player.charCreate gives the starting nation's ring only when that nation is the race's
-- home nation (Hume and Galka: Bastok, Elvaan: San d'Oria, Tarutaru and Mithra: Windurst). The
-- module gives every new character the ring of the nation they start in, once: a character who
-- already owns any nation ring gets none. Test characters start in San d'Oria.

describe('Zenith nation rings for all races', function()
    local nationRings =
    {
        xi.item.SAN_DORIAN_RING,
        xi.item.BASTOKAN_RING,
        xi.item.WINDURSTIAN_RING,
    }

    local function ringCount(entity)
        local count = 0

        for _, ringId in ipairs(nationRings) do
            count = count + entity:getItemCount(ringId)
        end

        return count
    end

    it('gives a new Hume starting in San d\'Oria the San d\'Orian ring at first login', function()
        -- new = true leaves out the NEW_ADVENTURER title, so the login runs charCreate
        local player = xi.test.world:spawnPlayer({ race = xi.race.HUME_M, new = true })

        assert(player:getRace() == xi.race.HUME_M, 'precondition: a Hume, whose home nation is Bastok')
        assert(player:getNation() == xi.nation.SANDORIA, 'precondition: starts in San d\'Oria')
        assert(player:hasTitle(xi.title.NEW_ADVENTURER), 'precondition: charCreate ran at the first login')

        assert(player:hasItem(xi.item.SAN_DORIAN_RING), 'a Hume starting in San d\'Oria got no San d\'Orian ring')
    end)

    it('gives a Tarutaru starting in Bastok the Bastokan ring', function()
        local player = xi.test.world:spawnPlayer({ race = xi.race.TARU_M })
        player:setNation(xi.nation.BASTOK)
        assert(ringCount(player) == 0, 'precondition: no nation ring yet')

        xi.player.charCreate(GetPlayerByID(player:getID()))

        assert(player:hasItem(xi.item.BASTOKAN_RING), 'a Tarutaru starting in Bastok got no Bastokan ring')
        assert(ringCount(player) == 1, string.format('expected 1 nation ring, got %d', ringCount(player)))
    end)

    -- Control: LSB gives this character no ring either. It guards the one-time rule, since the
    -- engine re-runs charCreate at login for characters without the NEW_ADVENTURER title.
    it('gives no second ring to a character who already owns one', function()
        local player = xi.test.world:spawnPlayer({ race = xi.race.HUME_M })
        player:addItem(xi.item.BASTOKAN_RING)
        assert(player:getNation() == xi.nation.SANDORIA, 'precondition: starts in San d\'Oria')

        xi.player.charCreate(GetPlayerByID(player:getID()))

        assert(not player:hasItem(xi.item.SAN_DORIAN_RING), 'a character who owned a Bastokan ring was given a San d\'Orian ring too')
        assert(ringCount(player) == 1, string.format('expected 1 nation ring, got %d', ringCount(player)))
    end)

    -- Control: LSB already gives the home-nation ring. The module must not add a second one.
    it('gives an Elvaan starting in San d\'Oria exactly one San d\'Orian ring', function()
        local player = xi.test.world:spawnPlayer({ race = xi.race.ELVAAN_M })
        assert(ringCount(player) == 0, 'precondition: no nation ring yet')

        xi.player.charCreate(GetPlayerByID(player:getID()))

        local count = player:getItemCount(xi.item.SAN_DORIAN_RING)
        assert(count == 1, string.format('expected 1 San d\'Orian ring, got %d', count))
    end)
end)
