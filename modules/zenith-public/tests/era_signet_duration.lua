-- ZenithXI era Signet duration (modules/zenith-public/lua/3-complete/era_signet_duration.lua, ZENITHDEV-262).
--
-- Base gives (player rank + nation rank + 3) hours of Signet; the era duration is 3 hours less.

describe('Zenith era Signet duration', function()
    it('gives Signet 3 hours less than base', function()
        local player = xi.test.world:spawnPlayer({ zone = xi.zone.BASTOK_MINES })
        local rank   = 3

        xi.conquest.bestowSignet(player, xi.nation.BASTOK, rank, 0)

        local signet = player:getStatusEffect(xi.effect.SIGNET)
        assert(signet, 'no Signet was given')

        local expected = (rank + GetNationRank(xi.nation.BASTOK)) * 3600 * 1000
        assert(signet:getDuration() == expected, string.format('Signet lasts %d ms, expected %d', signet:getDuration(), expected))
    end)
end)
