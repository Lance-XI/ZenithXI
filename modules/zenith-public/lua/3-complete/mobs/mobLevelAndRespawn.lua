-----------------------------------
-- Mob level and respawn overrides
--
-- Replaces modules/zenith-public/sql/mob_level_and_respawn.sql, which stopped
-- doing anything when upstream moved mob data out of `mob_groups` /
-- `mob_spawn_points` and into data/zones/<zone>/mobs.yaml. Those two tables now
-- only carry instanced content (30 zones), so every `UPDATE ... WHERE
-- mg.zoneid = N` in that file matched zero rows -- which MySQL does not treat
-- as an error, so every custom level and respawn time vanished silently.
--
-- There is no module overlay for per-zone YAML: xi::data::loadZoneFile (see
-- src/map/data/loader.h) reads data/zones/<zone>/<name>.yaml straight off disk,
-- unlike xi::data::loadDataset which merges modules/<mod>/data/<name>.yaml.
-- data/ is base, so the only module-side route is Lua, and the hook that runs
-- after a zone's mobs are loaded is Zone.onInitialize (zoneutils::LoadZones
-- calls luautils::OnZoneInitialize after LoadMOBList).
--
-- Level ranges are re-applied per spawn on purpose: CMobEntity::Spawn() rolls a
-- fresh level from the YAML's own m_minLevel/m_maxLevel every single time, and
-- no Lua binding writes those two fields. The SPAWN listener fires at the end of
-- that same Spawn() call (luautils::OnMobSpawn), so setMobLevel there is the
-- only thing that survives a respawn.
--
-- Respawn times are only applied to mobs that are already up. setRespawnTime on
-- an idle mob re-registers it with the zone's SpawnHandler, which would reset
-- pending lottery / windowed / spawn-slot timers.
--
-- Caveat: the SPAWN listener fires after the mob's own onMobSpawn, and
-- setMobLevel recalculates stats with recover = true. An NM script that lowers
-- its own HP inside onMobSpawn would have that undone.
-- This was not audited across all 156 NM entries; it is the one behaviour the
-- old mob_spawn_points columns had that this cannot reproduce exactly.
--
-- Every value below comes verbatim from the retired SQL. Where that file set the
-- same mob twice, the later statement wins, matching MySQL execution order.
-- Mobs the SQL named that no longer exist in the new YAML were dropped, not
-- guessed; so were mobs whose script name is shared with a template the SQL did
-- not target. See the migration notes in the retired SQL file.
--
-- Public module for ZenithXI
-----------------------------------
require('modules/module_utils')

local m = Module:new('c-m_mob_lvl_respawn')

-----------------------------------
-- Zone script name -> mob script name -> overrides
--   lvl = { min, max } -- was mob_spawn_points.minLevel / maxLevel
--   rsp = seconds      -- was mob_groups.respawntime
-----------------------------------
local mobOverrides =
{
    -- carpenters_landing (zone 2)
    ['Carpenters_Landing'] =
    {
        ['Hercules_Beetle']     = { lvl = { 34, 36 } },
        ['Orcish_Cursemaker']   = { lvl = { 22, 25 } },
        ['Orcish_Fighter']      = { lvl = { 22, 25 } },
        ['Orcish_Grunt']        = { lvl = { 17, 20 } },
        ['Orcish_Neckchopper']  = { lvl = { 17, 20 } },
        ['Orcish_Serjeant']     = { lvl = { 22, 25 } },
        ['Orcish_Stonechucker'] = { lvl = { 17, 20 } },
        ['Tempest_Tigon']       = { lvl = { 43, 45 } },
    },

    -- bibiki_bay (zone 4)
    ['Bibiki_Bay'] =
    {
        ['Catoblepas']        = { lvl = { 78, 80 } },
        ['Island_Rarab']      = { lvl = { 35, 38 } },
        ['Locus_Bight_Rarab'] = { lvl = { 81, 83 }, rsp = 330 },
        ['Locus_Camelopard']  = { lvl = { 83, 85 }, rsp = 330 },
        ['Locus_Ghost_Crab']  = { lvl = { 66, 69 }, rsp = 330 },
        ['Locus_Hypnos_Eft']  = { lvl = { 81, 84 }, rsp = 330 },
        ['Marine_Dhalmel']    = { lvl = { 35, 37 } },
        ['Splacknuck']        = { lvl = { 75, 77 } },
    },

    -- uleguerand_range (zone 5)
    ['Uleguerand_Range'] =
    {
        ['Doom_Soldier']  = { lvl = { 67, 70 } },
        ['Glacier_Eater'] = { lvl = { 59, 62 } },
        ['Mountain_Worm'] = { lvl = { 67, 70 } },
        ['Polar_Hare']    = { lvl = { 67, 69 } },
        ['Scowlenkos']    = { lvl = { 83, 85 } },
    },

    -- attohwa_chasm (zone 7)
    ['Attohwa_Chasm'] =
    {
        ['Arch_Corse']      = { lvl = { 78, 81 } },
        ['Hecteyes']        = { lvl = { 36, 39 } },
        ['Tulwar_Scorpion'] = { lvl = { 66, 68 } },
    },

    -- psoxja (zone 9)
    ['PsoXja'] =
    {
        ['Blubber_Eyes']         = { lvl = { 55, 58 } },
        ['Cryptonberry_Cutter']  = { lvl = { 56, 59 } },
        ['Cryptonberry_Harrier'] = { lvl = { 57, 60 } },
        ['Cryptonberry_Plaguer'] = { lvl = { 56, 59 } },
        ['Cryptonberry_Stalker'] = { lvl = { 57, 60 } },
        ['Diremite']             = { lvl = { 43, 46 }, rsp = 840 },
        ['Diremite_Assaulter']   = { lvl = { 65, 68 }, rsp = 960 },
        ['Diremite_Dominator']   = { rsp = 960 },
        ['Diremite_Stalker']     = { rsp = 960 },
        ['Frost_Lizard']         = { lvl = { 74, 77 } },
        ['Gazer']                = { rsp = 840 },
        ['Goblin_Alchemist']     = { lvl = { 65, 68 } },
        ['Goblin_Bandit']        = { lvl = { 64, 67 } },
        ['Goblin_Mercenary']     = { lvl = { 65, 68 } },
        ['Goblin_Veterinarian']  = { lvl = { 65, 68 } },
        ['Goblins_Bat']          = { lvl = { 59, 61 } },
        ['Labyrinth_Lizard']     = { lvl = { 55, 58 } },
        ['Maze_Lizard']          = { lvl = { 44, 47 }, rsp = 840 },
        ['Purgatory_Bat']        = { lvl = { 73, 76 } },
        ['Snowball']             = { rsp = 840 },
        ['Thousand_Eyes']        = { lvl = { 65, 68 } },
        ['Vampire_Bat']          = { rsp = 840 },
    },

    -- oldton_movalpolos (zone 11)
    ['Oldton_Movalpolos'] =
    {
        ['Ancient_Bomb']      = { lvl = { 42, 45 }, rsp = 840 },
        ['Dark_Bats']         = { lvl = { 32, 35 } },
        ['Earth_Elemental']   = { rsp = 840 },
        ['Goblin_Wolfman']    = { lvl = { 53, 55 } },
        ['Thunder_Elemental'] = { rsp = 840 },
    },

    -- newton_movalpolos (zone 12)
    ['Newton_Movalpolos'] =
    {
        ['Bugbear_Matman']   = { lvl = { 76, 79 } },
        ['Bugbear_Watchman'] = { lvl = { 73, 76 } },
        ['Goblin_Hangman']   = { lvl = { 76, 79 } },
        ['Goblin_Headman']   = { lvl = { 76, 79 } },
        ['Goblin_Junkman']   = { lvl = { 76, 79 } },
        ['Goblin_Marksman']  = { lvl = { 76, 79 } },
        ['Moblin_Roadman']   = { lvl = { 76, 79 } },
    },

    -- lufaise_meadows (zone 24)
    ['Lufaise_Meadows'] =
    {
        ['Flockbock']   = { lvl = { 85, 85 } },
        ['Leshachikha'] = { lvl = { 50, 53 } },
    },

    -- misareaux_coast (zone 25)
    ['Misareaux_Coast'] =
    {
        ['Diatryma'] = { lvl = { 48, 51 } },
        ['Gration']  = { lvl = { 80, 80 } },
        ['Upyri']    = { lvl = { 50, 52 } },
    },

    -- phomiuna_aqueducts (zone 27)
    ['Phomiuna_Aqueducts'] =
    {
        ['Air_Elemental']     = { rsp = 840 },
        ['Aqueduct_Spider']   = { lvl = { 46, 48 }, rsp = 840 },
        ['Dark_Elemental']    = { rsp = 840 },
        ['Diremite']          = { lvl = { 45, 48 } },
        ['Thunder_Elemental'] = { rsp = 840 },
    },

    -- sacrarium (zone 28)
    ['Sacrarium'] =
    {
        ['Aqueduct_Spider'] = { lvl = { 57, 59 } },
    },

    -- riverne_site_b01 (zone 29)
    ['Riverne-Site_B01'] =
    {
        ['Blazedrake'] = { lvl = { 58, 60 } },
        ['Lesser_Roc'] = { lvl = { 49, 51 } },
        ['Pyrodrake']  = { lvl = { 52, 55 } },
    },

    -- riverne_site_a01 (zone 30)
    ['Riverne-Site_A01'] =
    {
        ['Darner'] = { lvl = { 46, 49 } },
    },

    -- dynamis_valkurm (zone 39)
    ['Dynamis-Valkurm'] =
    {
        ['Vanguards_Avatar']   = { lvl = { 88, 90 } },
        ['Vanguards_Crow']     = { lvl = { 88, 90 } },
        ['Vanguards_Hecteyes'] = { lvl = { 88, 90 } },
        ['Vanguards_Scorpion'] = { lvl = { 88, 90 } },
        ['Vanguards_Slime']    = { lvl = { 88, 90 } },
        ['Vanguards_Wyvern']   = { lvl = { 88, 90 } },
    },

    -- dynamis_buburimu (zone 40)
    ['Dynamis-Buburimu'] =
    {
        ['Vanguards_Crow']     = { lvl = { 88, 90 } },
        ['Vanguards_Hecteyes'] = { lvl = { 88, 90 } },
        ['Vanguards_Scorpion'] = { lvl = { 88, 90 } },
        ['Vanguards_Slime']    = { lvl = { 88, 90 } },
        ['Vanguards_Wyvern']   = { lvl = { 88, 90 } },
    },

    -- dynamis_qufim (zone 41)
    ['Dynamis-Qufim'] =
    {
        ['Vanguards_Avatar']   = { lvl = { 88, 90 } },
        ['Vanguards_Crow']     = { lvl = { 88, 90 } },
        ['Vanguards_Hecteyes'] = { lvl = { 88, 90 } },
        ['Vanguards_Scorpion'] = { lvl = { 88, 90 } },
        ['Vanguards_Slime']    = { lvl = { 88, 90 } },
        ['Vanguards_Wyvern']   = { lvl = { 88, 90 } },
    },

    -- dynamis_tavnazia (zone 42)
    ['Dynamis-Tavnazia'] =
    {
        ['Kindred_Bard']        = { lvl = { 90, 92 } },
        ['Kindred_Beastmaster'] = { lvl = { 90, 92 } },
        ['Kindred_Black_Mage']  = { lvl = { 90, 92 } },
        ['Kindred_Dark_Knight'] = { lvl = { 90, 92 } },
        ['Kindred_Dragoon']     = { lvl = { 90, 92 } },
        ['Kindred_Monk']        = { lvl = { 90, 92 } },
        ['Kindred_Ninja']       = { lvl = { 90, 92 } },
        ['Kindred_Paladin']     = { lvl = { 90, 92 } },
        ['Kindred_Ranger']      = { lvl = { 90, 92 } },
        ['Kindred_Red_Mage']    = { lvl = { 90, 92 } },
        ['Kindred_Samurai']     = { lvl = { 90, 92 } },
        ['Kindred_Summoner']    = { lvl = { 90, 92 } },
        ['Kindred_Thief']       = { lvl = { 90, 92 } },
        ['Kindred_Warrior']     = { lvl = { 90, 92 } },
        ['Kindred_White_Mage']  = { lvl = { 90, 92 } },
        ['Kindreds_Avatar']     = { lvl = { 90, 92 } },
        ['Kindreds_Vouivre']    = { lvl = { 90, 92 } },
        ['Kindreds_Wyvern']     = { lvl = { 90, 92 } },
        ['Nightmare_Cluster']   = { lvl = { 90, 92 } },
        ['Nightmare_Leech']     = { lvl = { 90, 92 } },
    },

    -- wajaom_woodlands (zone 51)
    ['Wajaom_Woodlands'] =
    {
        ['Aht_Urhgan_Attercop']   = { rsp = 330 },
        ['Carmine_Eruca']         = { lvl = { 70, 72 } },
        ['Colorful_Treant']       = { rsp = 330 },
        ['Great_Ameretat']        = { lvl = { 73, 75 } },
        ['Hydra']                 = { lvl = { 85, 87 } },
        ['Mamool_Ja_Bounder']     = { rsp = 330 },
        ['Mamool_Ja_Mimicker']    = { rsp = 330 },
        ['Mamool_Ja_Savant']      = { rsp = 330 },
        ['Mamool_Ja_Sophist']     = { rsp = 330 },
        ['Mamool_Ja_Zenist']      = { rsp = 330 },
        ['Woodtroll_Dark_Knight'] = { rsp = 330 },
    },

    -- bhaflau_thickets (zone 52)
    ['Bhaflau_Thickets'] =
    {
        ['Aht_Urhgan_Attercop']   = { rsp = 330 },
        ['Colorful_Treant']       = { rsp = 330 },
        ['Locus_Colibri']         = { lvl = { 81, 82 } },
        ['Locus_Wivre']           = { lvl = { 82, 83 } },
        ['Mamool_Ja_Blusterer']   = { rsp = 330 },
        ['Mamool_Ja_Infiltrator'] = { rsp = 330 },
        ['Mamool_Ja_Lurker']      = { rsp = 330 },
        ['Mamool_Ja_Philosopher'] = { rsp = 330 },
        ['Mamool_Ja_Pikeman']     = { rsp = 330 },
        ['Mamool_Ja_Stabler']     = { rsp = 330 },
    },

    -- arrapago_reef (zone 54)
    ['Arrapago_Reef'] =
    {
        ['Arrapago_Apkallu'] = { rsp = 330 },
        ['Dweomershell']     = { lvl = { 83, 85 } },
        ['Euryale']          = { lvl = { 87, 89 } },
        ['Heraldic_Imp']     = { rsp = 330 },
        ['Lamia_No19']       = { lvl = { 78, 80 } },
        ['Lamie_No9']        = { lvl = { 85, 87 } },
        ['Medusa']           = { lvl = { 88, 90 } },
        ['Naraka_Bat']       = { lvl = { 82, 84 } },
        ['Nipper']           = { rsp = 330 },
        ['Nirgali']          = { lvl = { 81, 83 } },
        ['Nostokulshedra']   = { lvl = { 84, 86 } },
        ['Purgatory_Bat']    = { rsp = 330 },
    },

    -- mount_zhayolm (zone 61)
    ['Mount_Zhayolm'] =
    {
        ['Cerberus']          = { lvl = { 85, 87 } },
        ['Magmatic_Eruca']    = { lvl = { 71, 74 } },
        ['Orichalcumshell']   = { lvl = { 84, 86 } },
        ['Scoriaceous_Eruca'] = { lvl = { 80, 82 } },
        ['Sulphuric_Jagil']   = { lvl = { 81, 83 } },
        ['Sweeping_Cluster']  = { lvl = { 75, 78 } },
        ['Wootzshell']        = { lvl = { 70, 72 } },
        ['Zhayolm_Apkallu']   = { lvl = { 71, 74 } },
    },

    -- halvung (zone 62)
    ['Halvung'] =
    {
        ['Black_Pudding']          = { rsp = 330 },
        ['Dahak']                  = { lvl = { 79, 81 } },
        ['Ebony_Pudding']          = { rsp = 330 },
        ['Gurfurlur_the_Menacing'] = { lvl = { 88, 90 } },
        ['Magmatic_Eruca']         = { lvl = { 72, 75 }, rsp = 330 },
        ['Purgatory_Bat']          = { rsp = 330 },
        ['Troll_Artilleryman']     = { lvl = { 80, 83 } },
        ['Troll_Cameist']          = { lvl = { 73, 75 } },
        ['Troll_Combatant']        = { lvl = { 80, 83 } },
        ['Troll_Cuirasser']        = { lvl = { 80, 83 } },
        ['Troll_Engraver']         = { lvl = { 73, 75 } },
        ['Troll_Gemologist']       = { lvl = { 73, 75 } },
        ['Troll_Grenadier']        = { lvl = { 80, 83 } },
        ['Troll_Ironworker']       = { lvl = { 73, 75 } },
        ['Troll_Lapidarist']       = { lvl = { 73, 75 } },
        ['Troll_Machinist']        = { lvl = { 80, 83 } },
        ['Troll_Scrimer']          = { lvl = { 80, 83 } },
        ['Troll_Smelter']          = { lvl = { 73, 75 } },
        ['Troll_Stoneworker']      = { lvl = { 73, 75 } },
        ['Troll_Targeteer']        = { lvl = { 80, 83 } },
        ['Volcanic_Bats']          = { rsp = 330 },
    },

    -- mamook (zone 65)
    ['Mamook'] =
    {
        ['Carriage_Lizard']       = { rsp = 330 },
        ['Colibri']               = { lvl = { 70, 73 }, rsp = 330 },
        ['Gulool_Ja_Ja']          = { lvl = { 88, 90 } },
        ['Mamool_Ja_Blusterer']   = { rsp = 960 },
        ['Mamool_Ja_Bounder']     = { rsp = 960 },
        ['Mamool_Ja_Frogman']     = { rsp = 960 },
        ['Mamool_Ja_Infiltrator'] = { rsp = 960 },
        ['Mamool_Ja_Lurker']      = { rsp = 960 },
        ['Mamool_Ja_Mimicker']    = { rsp = 960 },
        ['Mamool_Ja_Philosopher'] = { rsp = 960 },
        ['Mamool_Ja_Pikeman']     = { rsp = 960 },
        ['Mamool_Ja_Savant']      = { rsp = 960 },
        ['Mamool_Ja_Sophist']     = { rsp = 960 },
        ['Mamool_Ja_Spearman']    = { rsp = 960 },
        ['Mamool_Ja_Stabler']     = { rsp = 960 },
        ['Mamool_Ja_Strapper']    = { rsp = 960 },
        ['Mamool_Ja_Zenist']      = { rsp = 960 },
        ['Nipper']                = { rsp = 330 },
        ['Puk']                   = { rsp = 330 },
        ['Sea_Puk']               = { rsp = 330 },
    },

    -- aydeewa_subterrane (zone 68)
    ['Aydeewa_Subterrane'] =
    {
        ['Aydeewa_Diremite']     = { lvl = { 71, 74 } },
        ['Defoliator']           = { lvl = { 70, 73 }, rsp = 330 },
        ['Deforester']           = { lvl = { 85, 87 } },
        ['Mold_Eater']           = { rsp = 330 },
        ['Mycoskulker']          = { lvl = { 81, 82 } },
        ['Puktrap']              = { rsp = 330 },
        ['Qiqirn_Archaeologist'] = { rsp = 330 },
        ['Qiqirn_Enterpriser']   = { rsp = 330 },
        ['Qiqirn_Lieuter']       = { rsp = 330 },
        ['Qiqirn_Mosstrooper']   = { rsp = 330 },
        ['Slime_Eater']          = { lvl = { 80, 83 } },
        ['Treant_Sapling']       = { rsp = 330 },
    },

    -- caedarva_mire (zone 79)
    ['Caedarva_Mire'] =
    {
        ['Heraldic_Imp']      = { lvl = { 80, 82 } },
        ['Jnun']              = { lvl = { 75, 77 } },
        ['Khimaira']          = { lvl = { 85, 87 } },
        ['Marsh_Murre']       = { lvl = { 66, 68 } },
        ['Orderly_Imp']       = { lvl = { 66, 68 } },
        ['Qiqirn_Mireguide']  = { rsp = 330 },
        ['Qiqirn_Rock_Hound'] = { rsp = 330 },
        ['Slough_Skua']       = { lvl = { 86, 88 } },
        ['Spongilla_Fly']     = { lvl = { 78, 80 } },
        ['Vauxia_Fly']        = { lvl = { 82, 84 } },
    },

    -- west_ronfaure (zone 100)
    ['West_Ronfaure'] =
    {
        ['Carrion_Worm']      = { lvl = { 3, 6 } },
        ['Ding_Bats']         = { lvl = { 2, 5 } },
        ['Forest_Hare']       = { lvl = { 3, 6 } },
        ['Goblin_Thug']       = { lvl = { 5, 8 } },
        ['Goblin_Weaver']     = { lvl = { 5, 8 } },
        ['Orcish_Fodder']     = { lvl = { 5, 8 } },
        ['Orcish_Grappler']   = { lvl = { 5, 8 } },
        ['Orcish_Mesmerizer'] = { lvl = { 5, 8 } },
        ['Scarab_Beetle']     = { lvl = { 4, 7 } },
        ['Tunnel_Worm']       = { rsp = 300 },
        ['Wild_Rabbit']       = { rsp = 300 },
    },

    -- east_ronfaure (zone 101)
    ['East_Ronfaure'] =
    {
        ['Carrion_Worm']      = { lvl = { 3, 6 } },
        ['Ding_Bats']         = { lvl = { 2, 5 } },
        ['Forest_Hare']       = { lvl = { 3, 6 } },
        ['Goblin_Thug']       = { lvl = { 5, 8 } },
        ['Goblin_Weaver']     = { lvl = { 5, 8 } },
        ['Orcish_Fodder']     = { lvl = { 5, 8 } },
        ['Orcish_Grappler']   = { lvl = { 5, 8 } },
        ['Orcish_Mesmerizer'] = { lvl = { 5, 8 } },
        ['Scarab_Beetle']     = { lvl = { 4, 7 } },
        ['Tunnel_Worm']       = { rsp = 300 },
        ['Wild_Rabbit']       = { rsp = 300 },
    },

    -- la_theine_plateau (zone 102)
    ['La_Theine_Plateau'] =
    {
        ['Akbaba']              = { lvl = { 10, 13 } },
        ['Goblin_Ambusher']     = { lvl = { 13, 16 } },
        ['Goblin_Butcher']      = { lvl = { 13, 16 } },
        ['Goblin_Tinkerer']     = { lvl = { 13, 16 } },
        ['Huge_Wasp']           = { lvl = { 9, 12 } },
        ['Orcish_Grunt']        = { lvl = { 13, 16 } },
        ['Orcish_Neckchopper']  = { lvl = { 13, 16 } },
        ['Orcish_Stonechucker'] = { lvl = { 13, 16 } },
        ['Rock_Eater']          = { lvl = { 8, 11 } },
    },

    -- valkurm_dunes (zone 103)
    ['Valkurm_Dunes'] =
    {
        ['Ghoul']                = { lvl = { 20, 22 } },
        ['Goblin_Bounty_Hunter'] = { lvl = { 20, 22 } },
        ['Hill_Lizard']          = { lvl = { 16, 19 } },
        ['Thread_Leech']         = { lvl = { 22, 25 } },
    },

    -- jugner_forest (zone 104)
    ['Jugner_Forest'] =
    {
        ['Goblin_Ambusher']     = { lvl = { 17, 20 } },
        ['Goblin_Butcher']      = { lvl = { 17, 20 } },
        ['Goblin_Gambler']      = { lvl = { 22, 25 } },
        ['Goblin_Leecher']      = { lvl = { 22, 25 } },
        ['Goblin_Mugger']       = { lvl = { 22, 25 } },
        ['Goblin_Tinkerer']     = { lvl = { 17, 20 } },
        ['Jugner_Funguar']      = { lvl = { 22, 25 } },
        ['Orcish_Grunt']        = { lvl = { 17, 20 } },
        ['Orcish_Neckchopper']  = { lvl = { 17, 20 } },
        ['Orcish_Stonechucker'] = { lvl = { 17, 20 } },
        ['Screamer']            = { lvl = { 16, 18 } },
    },

    -- batallia_downs (zone 105)
    ['Batallia_Downs'] =
    {
        ['Goblin_Bounty_Hunter'] = { lvl = { 24, 26 } },
        ['Goblin_Furrier']       = { lvl = { 31, 34 } },
        ['Goblin_Gambler']       = { lvl = { 27, 30 } },
        ['Goblin_Leecher']       = { lvl = { 27, 30 } },
        ['Goblin_Mugger']        = { lvl = { 27, 30 } },
        ['Goblin_Pathfinder']    = { lvl = { 31, 34 } },
        ['Goblin_Shaman']        = { lvl = { 31, 34 } },
        ['Goblin_Smithy']        = { lvl = { 31, 34 } },
        ['Mauthe_Doog']          = { lvl = { 30, 32 } },
        ['May_Fly']              = { lvl = { 23, 26 } },
        ['Orcish_Beastrider']    = { lvl = { 33, 36 } },
        ['Orcish_Brawler']       = { lvl = { 33, 36 } },
        ['Orcish_Cursemaker']    = { lvl = { 27, 30 } },
        ['Orcish_Fighter']       = { lvl = { 27, 30 } },
        ['Orcish_Impaler']       = { lvl = { 33, 36 } },
        ['Orcish_Nightraider']   = { lvl = { 33, 36 } },
        ['Orcish_Serjeant']      = { lvl = { 27, 30 } },
        ['Sabertooth_Tiger']     = { lvl = { 29, 32 } },
        ['Stalking_Sapling']     = { lvl = { 22, 24 } },
    },

    -- north_gustaberg (zone 106)
    ['North_Gustaberg'] =
    {
        ['Amber_Quadav']     = { lvl = { 5, 8 } },
        ['Amethyst_Quadav']  = { lvl = { 5, 8 } },
        ['Ding_Bats']        = { lvl = { 2, 4 } },
        ['Goblin_Gambler']   = { rsp = 330 },
        ['Goblin_Leecher']   = { rsp = 330 },
        ['Goblin_Mugger']    = { rsp = 330 },
        ['Goblin_Thug']      = { lvl = { 5, 8 } },
        ['Goblin_Weaver']    = { lvl = { 5, 8 } },
        ['Huge_Hornet']      = { rsp = 300 },
        ['Maneating_Hornet'] = { lvl = { 4, 6 } },
        ['River_Crab']       = { lvl = { 3, 5 } },
        ['Rock_Lizard']      = { lvl = { 5, 8 } },
        ['Stone_Eater']      = { lvl = { 3, 6 } },
        ['Tunnel_Worm']      = { rsp = 300 },
        ['Vulture']          = { lvl = { 4, 7 } },
        ['Walking_Sapling']  = { lvl = { 3, 6 } },
        ['Young_Quadav']     = { lvl = { 5, 8 } },
    },

    -- south_gustaberg (zone 107)
    ['South_Gustaberg'] =
    {
        ['Amber_Quadav']     = { lvl = { 5, 8 } },
        ['Amethyst_Quadav']  = { lvl = { 5, 8 } },
        ['Ding_Bats']        = { lvl = { 2, 4 } },
        ['Goblin_Thug']      = { lvl = { 5, 8 } },
        ['Goblin_Weaver']    = { lvl = { 5, 8 } },
        ['Huge_Hornet']      = { rsp = 300 },
        ['Maneating_Hornet'] = { lvl = { 4, 6 } },
        ['Rock_Lizard']      = { lvl = { 5, 8 } },
        ['Stone_Eater']      = { lvl = { 3, 6 } },
        ['Tunnel_Worm']      = { rsp = 300 },
        ['Vulture']          = { lvl = { 4, 7 } },
        ['Walking_Sapling']  = { lvl = { 3, 6 } },
        ['Young_Quadav']     = { lvl = { 5, 8 } },
    },

    -- konschtat_highlands (zone 108)
    ['Konschtat_Highlands'] =
    {
        ['Goblin_Ambusher']   = { lvl = { 13, 16 } },
        ['Goblin_Butcher']    = { lvl = { 13, 16 } },
        ['Goblin_Tinkerer']   = { lvl = { 13, 16 } },
        ['Greater_Quadav']    = { lvl = { 13, 16 } },
        ['Huge_Wasp']         = { lvl = { 8, 11 } },
        ['Onyx_Quadav']       = { lvl = { 13, 16 } },
        ['Rock_Eater']        = { lvl = { 8, 11 } },
        ['Strolling_Sapling'] = { lvl = { 8, 11 } },
        ['Veteran_Quadav']    = { lvl = { 13, 16 } },
    },

    -- pashhow_marshlands (zone 109)
    ['Pashhow_Marshlands'] =
    {
        ['Bog_Dog']         = { lvl = { 20, 23 } },
        ['Copper_Quadav']   = { lvl = { 23, 26 } },
        ['Ghoul']           = { lvl = { 20, 23 } },
        ['Goblin_Ambusher'] = { lvl = { 17, 20 } },
        ['Goblin_Butcher']  = { lvl = { 17, 20 } },
        ['Goblin_Gambler']  = { lvl = { 22, 25 } },
        ['Goblin_Leecher']  = { lvl = { 22, 25 } },
        ['Goblin_Mugger']   = { lvl = { 22, 25 } },
        ['Goblin_Tinkerer'] = { lvl = { 17, 20 } },
        ['Greater_Quadav']  = { lvl = { 17, 20 } },
        ['Land_Pugil']      = { lvl = { 18, 20 } },
        ['Marsh_Funguar']   = { lvl = { 22, 25 } },
        ['Onyx_Quadav']     = { lvl = { 17, 20 } },
        ['Snipper']         = { lvl = { 18, 20 } },
        ['Veteran_Quadav']  = { lvl = { 17, 20 } },
        ['Water_Wasp']      = { lvl = { 16, 18 } },
        ['Zombie']          = { lvl = { 20, 23 } },
    },

    -- rolanberry_fields (zone 110)
    ['Rolanberry_Fields'] =
    {
        ['Berry_Grub']        = { lvl = { 26, 28 } },
        ['Brass_Quadav']      = { lvl = { 27, 30 } },
        ['Bronze_Quadav']     = { lvl = { 31, 34 } },
        ['Copper_Quadav']     = { lvl = { 27, 30 } },
        ['Death_Wasp']        = { lvl = { 23, 26 } },
        ['Garnet_Quadav']     = { lvl = { 31, 34 } },
        ['Goblin_Furrier']    = { lvl = { 31, 34 } },
        ['Goblin_Gambler']    = { lvl = { 27, 30 } },
        ['Goblin_Leecher']    = { lvl = { 27, 30 } },
        ['Goblin_Mugger']     = { lvl = { 27, 30 } },
        ['Goblin_Pathfinder'] = { lvl = { 31, 34 } },
        ['Goblin_Shaman']     = { lvl = { 31, 34 } },
        ['Goblin_Smithy']     = { lvl = { 31, 34 } },
        ['Old_Quadav']        = { lvl = { 27, 30 } },
        ['Silver_Quadav']     = { lvl = { 31, 34 } },
        ['Wight']             = { lvl = { 31, 34 } },
        ['Zircon_Quadav']     = { lvl = { 31, 34 } },
    },

    -- xarcabard (zone 112)
    ['Xarcabard'] =
    {
        ['Boreal_Coeurl'] = { lvl = { 58, 58 } },
        ['Boreal_Hound']  = { lvl = { 58, 58 } },
        ['Boreal_Tiger']  = { lvl = { 58, 58 } },
        ['Demon_Pawn']    = { lvl = { 49, 52 } },
    },

    -- cape_teriggan (zone 113)
    ['Cape_Teriggan'] =
    {
        ['Beach_Bunny']     = { lvl = { 63, 65 } },
        ['Doom_Mage']       = { lvl = { 67, 70 } },
        ['Doom_Soldier']    = { lvl = { 67, 70 } },
        ['Sand_Cockatrice'] = { lvl = { 71, 73 } },
        ['Sand_Lizard']     = { lvl = { 63, 66 } },
        ['Terror_Pugil']    = { lvl = { 66, 69 } },
    },

    -- eastern_altepa_desert (zone 114)
    ['Eastern_Altepa_Desert'] =
    {
        ['Antican_Auxiliarius'] = { lvl = { 36, 39 } },
        ['Antican_Faber']       = { lvl = { 36, 39 } },
        ['Antican_Funditor']    = { lvl = { 36, 39 } },
        ['Antican_Sagittarius'] = { lvl = { 46, 49 } },
        ['Desert_Dhalmel']      = { lvl = { 41, 44 } },
        ['Flesh_Eater']         = { lvl = { 39, 42 } },
        ['Giant_Spider']        = { lvl = { 31, 34 } },
        ['Goblin_Digger']       = { lvl = { 46, 49 } },
        ['Goblin_Poacher']      = { lvl = { 46, 49 } },
        ['Goblin_Reaper']       = { lvl = { 46, 49 } },
        ['Goblin_Robber']       = { lvl = { 46, 49 } },
        ['Goblin_Trader']       = { lvl = { 46, 49 } },
        ['Lost_Soul']           = { lvl = { 44, 46 } },
        ['Sand_Beetle']         = { lvl = { 37, 40 } },
    },

    -- west_sarutabaruta (zone 115)
    ['West_Sarutabaruta'] =
    {
        ['Bumblebee']       = { rsp = 300 },
        ['Carrion_Crow']    = { lvl = { 3, 6 } },
        ['Goblin_Fisher']   = { lvl = { 3, 6 } },
        ['River_Crab']      = { lvl = { 2, 5 } },
        ['Savanna_Rarab']   = { lvl = { 2, 5 } },
        ['Tiny_Mandragora'] = { rsp = 300 },
        ['Yagudo_Acolyte']  = { lvl = { 5, 8 } },
        ['Yagudo_Initiate'] = { lvl = { 5, 8 } },
        ['Yagudo_Scribe']   = { lvl = { 5, 8 } },
    },

    -- east_sarutabaruta (zone 116)
    ['East_Sarutabaruta'] =
    {
        ['Bumblebee']       = { rsp = 300 },
        ['Duke_Decapod']    = { lvl = { 10, 12 } },
        ['Goblin_Fisher']   = { lvl = { 6, 8 } },
        ['Goblin_Thug']     = { lvl = { 5, 8 } },
        ['Goblin_Weaver']   = { lvl = { 5, 8 } },
        ['Mad_Fox']         = { lvl = { 5, 8 } },
        ['River_Crab']      = { lvl = { 3, 6 } },
        ['Savanna_Rarab']   = { lvl = { 2, 5 } },
        ['Tiny_Mandragora'] = { rsp = 300 },
        ['Yagudo_Acolyte']  = { lvl = { 5, 8 } },
        ['Yagudo_Initiate'] = { lvl = { 5, 8 } },
        ['Yagudo_Scribe']   = { lvl = { 5, 8 } },
    },

    -- tahrongi_canyon (zone 117)
    ['Tahrongi_Canyon'] =
    {
        ['Akbaba']            = { lvl = { 10, 13 } },
        ['Canyon_Rarab']      = { lvl = { 8, 11 } },
        ['Goblin_Ambusher']   = { lvl = { 13, 16 } },
        ['Goblin_Butcher']    = { lvl = { 13, 16 } },
        ['Goblin_Tinkerer']   = { lvl = { 13, 16 } },
        ['Herbage_Hunter']    = { lvl = { 29, 31 } },
        ['Pygmaioi']          = { lvl = { 9, 11 } },
        ['Strolling_Sapling'] = { lvl = { 8, 11 } },
        ['Yagudo_Mendicant']  = { lvl = { 13, 16 } },
        ['Yagudo_Persecutor'] = { lvl = { 13, 16 } },
        ['Yagudo_Piper']      = { lvl = { 13, 16 } },
    },

    -- buburimu_peninsula (zone 118)
    ['Buburimu_Peninsula'] =
    {
        ['Bull_Dhalmel']         = { lvl = { 22, 24 } },
        ['Ghoul']                = { lvl = { 22, 24 } },
        ['Goblin_Ambusher']      = { lvl = { 18, 20 } },
        ['Goblin_Bounty_Hunter'] = { lvl = { 21, 23 } },
        ['Goblin_Butcher']       = { lvl = { 18, 20 } },
        ['Goblin_Tinkerer']      = { lvl = { 18, 20 } },
        ['Poison_Leech']         = { lvl = { 22, 25 } },
        ['Shoal_Pugil']          = { lvl = { 24, 26 } },
        ['Sylvestre']            = { lvl = { 16, 19 } },
        ['Zombie']               = { lvl = { 20, 22 } },
        ['Zu']                   = { lvl = { 21, 24 } },
    },

    -- meriphataud_mountains (zone 119)
    ['Meriphataud_Mountains'] =
    {
        ['Chonchon']          = { lvl = { 53, 55 } },
        ['Coeurl']            = { lvl = { 23, 26 } },
        ['Goblin_Ambusher']   = { lvl = { 17, 20 } },
        ['Goblin_Butcher']    = { lvl = { 17, 20 } },
        ['Goblin_Gambler']    = { lvl = { 22, 25 } },
        ['Goblin_Leecher']    = { lvl = { 22, 25 } },
        ['Goblin_Mugger']     = { lvl = { 22, 25 } },
        ['Goblin_Tinkerer']   = { lvl = { 17, 20 } },
        ['Raptor']            = { lvl = { 22, 25 } },
        ['Scavenging_Hound']  = { lvl = { 20, 22 } },
        ['Wandering_Sapling'] = { lvl = { 14, 16 } },
        ['Yagudo_Mendicant']  = { lvl = { 17, 20 } },
        ['Yagudo_Persecutor'] = { lvl = { 17, 20 } },
        ['Yagudo_Piper']      = { lvl = { 17, 20 } },
        ['Zombie']            = { lvl = { 19, 21 } },
    },

    -- sauromugue_champaign (zone 120)
    ['Sauromugue_Champaign'] =
    {
        ['Champaign_Coeurl']    = { lvl = { 31, 34 } },
        ['Diving_Beetle']       = { lvl = { 26, 28 } },
        ['Goblin_Digger']       = { lvl = { 30, 32 } },
        ['Goblin_Furrier']      = { lvl = { 33, 36 } },
        ['Goblin_Gambler']      = { lvl = { 27, 30 } },
        ['Goblin_Leecher']      = { lvl = { 27, 30 } },
        ['Goblin_Mugger']       = { lvl = { 27, 30 } },
        ['Goblin_Pathfinder']   = { lvl = { 33, 36 } },
        ['Goblin_Shaman']       = { lvl = { 33, 36 } },
        ['Goblin_Smithy']       = { lvl = { 33, 36 } },
        ['Hill_Lizard']         = { lvl = { 23, 26 } },
        ['Midnight_Wings']      = { lvl = { 22, 24 } },
        ['Sauromugue_Skink']    = { lvl = { 29, 32 } },
        ['Yagudo_Drummer']      = { lvl = { 33, 36 } },
        ['Yagudo_Herald']       = { lvl = { 33, 36 } },
        ['Yagudo_Interrogator'] = { lvl = { 33, 36 } },
        ['Yagudo_Oracle']       = { lvl = { 33, 36 } },
        ['Yagudo_Priest']       = { lvl = { 27, 30 } },
        ['Yagudo_Theologist']   = { lvl = { 27, 30 } },
        ['Yagudo_Votary']       = { lvl = { 27, 30 } },
    },

    -- the_sanctuary_of_zitah (zone 121)
    ['The_Sanctuary_of_ZiTah'] =
    {
        ['Goblin_Gambler']   = { lvl = { 27, 29 } },
        ['Goblin_Leecher']   = { lvl = { 27, 29 } },
        ['Goblin_Mugger']    = { lvl = { 27, 29 } },
        ['Goblin_Robber']    = { lvl = { 43, 46 } },
        ['Goblin_Trader']    = { lvl = { 43, 46 } },
        ['Goobbue_Gardener'] = { lvl = { 41, 43 } },
        ['Hell_Hound']       = { lvl = { 46, 48 } },
        ['Lost_Soul']        = { lvl = { 47, 49 } },
        ['Master_Coeurl']    = { lvl = { 45, 47 } },
        ['Myxomycete']       = { lvl = { 43, 46 } },
        ['Ogrefly']          = { lvl = { 42, 44 } },
        ['Rot_Prowler']      = { lvl = { 46, 49 } },
    },

    -- romaeve (zone 122)
    ['RoMaeve'] =
    {
        ['Cursed_Puppet']    = { lvl = { 66, 69 } },
        ['Killing_Weapon']   = { lvl = { 62, 64 } },
        ['Magic_Flagon']     = { lvl = { 65, 68 } },
        ['Ominous_Weapon']   = { lvl = { 62, 65 } },
        ['Shikigami_Weapon'] = { lvl = { 80, 82 } },
    },

    -- yuhtunga_jungle (zone 123)
    ['Yuhtunga_Jungle'] =
    {
        ['Goblin_Furrier']  = { lvl = { 35, 37 } },
        ['Goblin_Poacher']  = { lvl = { 39, 42 } },
        ['Goblin_Reaper']   = { lvl = { 38, 41 } },
        ['Goblin_Robber']   = { lvl = { 39, 42 } },
        ['Goblin_Smithy']   = { lvl = { 32, 35 } },
        ['Makara']          = { lvl = { 36, 38 } },
        ['River_Sahagin']   = { lvl = { 35, 38 } },
        ['Soldier_Crawler'] = { lvl = { 38, 41 } },
    },

    -- yhoator_jungle (zone 124)
    ['Yhoator_Jungle'] =
    {
        ['Big_Jaw']           = { lvl = { 44, 47 } },
        ['Goblin_Bouncer']    = { lvl = { 52, 55 } },
        ['Goblin_Hunter']     = { lvl = { 52, 55 } },
        ['Goblin_Pathfinder'] = { lvl = { 36, 38 } },
        ['Goblin_Poacher']    = { lvl = { 45, 48 } },
        ['Goblin_Reaper']     = { lvl = { 38, 41 } },
        ['Goblin_Robber']     = { lvl = { 45, 48 } },
        ['Goblin_Shaman']     = { lvl = { 36, 38 } },
        ['Goblin_Smithy']     = { lvl = { 36, 38 } },
        ['Goblin_Trader']     = { lvl = { 45, 48 } },
        ['Young_Opo-opo']     = { lvl = { 42, 44 } },
    },

    -- western_altepa_desert (zone 125)
    ['Western_Altepa_Desert'] =
    {
        ['Antican_Eques']       = { lvl = { 46, 49 } },
        ['Antican_Essedarius']  = { lvl = { 42, 45 } },
        ['Antican_Hoplomachus'] = { lvl = { 54, 57 } },
        ['Antican_Lanista']     = { lvl = { 54, 57 } },
        ['Antican_Retiarius']   = { lvl = { 46, 49 } },
        ['Antican_Secutor']     = { lvl = { 54, 57 } },
        ['Cactuar']             = { lvl = { 50, 53 } },
        ['Dahu']                = { lvl = { 61, 63 } },
        ['Desert_Beetle']       = { lvl = { 48, 51 } },
        ['Desert_Dhalmel']      = { lvl = { 45, 48 } },
        ['Desert_Manticore']    = { lvl = { 54, 57 } },
        ['Desert_Spider']       = { lvl = { 41, 44 } },
        ['Desert_Worm']         = { lvl = { 43, 46 } },
        ['Goblin_Bouncer']      = { lvl = { 52, 55 } },
        ['Goblin_Digger']       = { lvl = { 52, 55 } },
        ['Goblin_Enchanter']    = { lvl = { 52, 55 } },
        ['Goblin_Hunter']       = { lvl = { 52, 55 } },
        ['Goblin_Welldigger']   = { lvl = { 52, 55 } },
        ['King_Vinegarroon']    = { lvl = { 85, 85 } },
    },

    -- qufim_island (zone 126)
    ['Qufim_Island'] =
    {
        ['Clipper']      = { lvl = { 26, 29 } },
        ['Gigass_Leech'] = { lvl = { 21, 23 } },
    },

    -- behemoths_dominion (zone 127)
    ['Behemoths_Dominion'] =
    {
        ['Behemoth']       = { lvl = { 70, 75 } },
        ['Demonic_Weapon'] = { lvl = { 44, 46 } },
        ['King_Behemoth']  = { lvl = { 85, 87 } },
        ['Lost_Soul']      = { lvl = { 44, 47 } },
        ['Master_Coeurl']  = { lvl = { 45, 47 }, rsp = 300 },
    },

    -- valley_of_sorrows (zone 128)
    ['Valley_of_Sorrows'] =
    {
        ['Adamantoise']  = { lvl = { 70, 75 } },
        ['Velociraptor'] = { lvl = { 68, 70 } },
    },

    -- ruaun_gardens (zone 130)
    ['RuAun_Gardens'] =
    {
        ['Byakko'] = { lvl = { 90, 92 } },
        ['Despot'] = { lvl = { 82, 84 } },
        ['Genbu']  = { lvl = { 90, 92 } },
        ['Seiryu'] = { lvl = { 90, 92 } },
        ['Suzaku'] = { lvl = { 90, 92 } },
    },

    -- dynamis_beaucedine (zone 134)
    ['Dynamis-Beaucedine'] =
    {
        ['Hydras_Avatar'] = { lvl = { 87, 90 } },
        ['Hydras_Hound']  = { lvl = { 87, 90 } },
        ['Hydras_Wyvern'] = { lvl = { 87, 90 } },
    },

    -- dynamis_xarcabard (zone 135)
    ['Dynamis-Xarcabard'] =
    {
        ['Kindreds_Avatar']      = { lvl = { 90, 92 } },
        ['Kindreds_Vouivre']     = { lvl = { 90, 92 } },
        ['Kindreds_Wyvern']      = { lvl = { 90, 92 } },
        ['Satellite_Claymores']  = { lvl = { 77, 80 } },
        ['Satellite_Daggers']    = { lvl = { 77, 80 } },
        ['Satellite_Great_Axes'] = { lvl = { 77, 80 } },
        ['Satellite_Guns']       = { lvl = { 77, 80 } },
        ['Satellite_Hammers']    = { lvl = { 77, 80 } },
        ['Satellite_Horns']      = { lvl = { 77, 80 } },
        ['Satellite_Knuckles']   = { lvl = { 77, 80 } },
        ['Satellite_Kunai']      = { lvl = { 77, 80 } },
        ['Satellite_Longbows']   = { lvl = { 77, 80 } },
        ['Satellite_Longswords'] = { lvl = { 77, 80 } },
        ['Satellite_Scythes']    = { lvl = { 77, 80 } },
        ['Satellite_Shield']     = { lvl = { 77, 80 } },
        ['Satellite_Spears']     = { lvl = { 77, 80 } },
        ['Satellite_Staves']     = { lvl = { 77, 80 } },
        ['Satellite_Tabars']     = { lvl = { 77, 80 } },
        ['Satellite_Tachi']      = { lvl = { 77, 80 } },
    },

    -- ghelsba_outpost (zone 140)
    ['Ghelsba_Outpost'] =
    {
        ['Cheiroptera']          = { rsp = 480 },
        ['Ghelsba_Pugil']        = { rsp = 480 },
        ['Orcish_Fodder']        = { lvl = { 7, 9 }, rsp = 480 },
        ['Orcish_Grappler']      = { rsp = 480 },
        ['Orcish_Grunt']         = { lvl = { 12, 15 }, rsp = 480 },
        ['Orcish_Mesmerizer']    = { rsp = 480 },
        ['Orcish_Neckchopper']   = { lvl = { 12, 15 }, rsp = 480 },
        ['Orcish_Stonechucker']  = { lvl = { 12, 15 }, rsp = 480 },
        ['Orcish_Stonelauncher'] = { rsp = 480 },
        ['Spectacled_Bats']      = { rsp = 480 },
        ['Toadstool']            = { rsp = 480 },
        ['Watch_Lizard']         = { rsp = 480 },
    },

    -- fort_ghelsba (zone 141)
    ['Fort_Ghelsba'] =
    {
        ['Orcish_Grunt']        = { lvl = { 14, 17 } },
        ['Orcish_Neckchopper']  = { lvl = { 14, 17 } },
        ['Orcish_Stonechucker'] = { lvl = { 14, 17 } },
    },

    -- yughott_grotto (zone 142)
    ['Yughott_Grotto'] =
    {
        ['Orcish_Grunt']        = { lvl = { 15, 18 } },
        ['Orcish_Neckchopper']  = { lvl = { 15, 18 } },
        ['Orcish_Stonechucker'] = { lvl = { 15, 18 } },
    },

    -- palborough_mines (zone 143)
    ['Palborough_Mines'] =
    {
        ['Amber_Quadav']    = { lvl = { 14, 18 } },
        ['Amethyst_Quadav'] = { lvl = { 14, 18 } },
        ['Copper_Beetle']   = { lvl = { 10, 12 } },
        ['Pit_Hare']        = { lvl = { 4, 6 } },
        ['Young_Quadav']    = { lvl = { 14, 18 } },
    },

    -- giddeus (zone 145)
    ['Giddeus'] =
    {
        ['Digger_Wasp']             = { lvl = { 12, 14 } },
        ['Eyy_Mon_the_Ironbreaker'] = { rsp = 600 },
        ['Giant_Pugil']             = { lvl = { 12, 14 } },
        ['Yagudo_Acolyte']          = { lvl = { 7, 10 } },
        ['Yagudo_Initiate']         = { lvl = { 7, 10 } },
        ['Yagudo_Mendicant']        = { lvl = { 15, 18 } },
        ['Yagudo_Persecutor']       = { lvl = { 15, 18 } },
        ['Yagudo_Piper']            = { lvl = { 15, 18 } },
        ['Yagudo_Scribe']           = { lvl = { 7, 10 } },
        ['Zhuu_Buxu_the_Silent']    = { rsp = 600 },
    },

    -- beadeaux (zone 147)
    ['Beadeaux'] =
    {
        ['Ancient_Quadav']    = { lvl = { 65, 69 } },
        ['Brass_Quadav']      = { lvl = { 25, 28 } },
        ['Bronze_Quadav']     = { lvl = { 45, 49 } },
        ['Broo']              = { rsp = 720 },
        ['Charging_Sheep']    = { rsp = 840 },
        ['Copper_Quadav']     = { lvl = { 25, 28 } },
        ['Darksteel_Quadav']  = { lvl = { 65, 69 } },
        ['DeVyu_Headhunter']  = { rsp = 600 },
        ['Garnet_Quadav']     = { lvl = { 45, 49 } },
        ['GoBhu_Gascon']      = { rsp = 600 },
        ['Gold_Quadav']       = { lvl = { 55, 59 } },
        ['Mythril_Quadav']    = { lvl = { 55, 59 } },
        ['Old_Quadav']        = { lvl = { 25, 28 } },
        ['Platinum_Quadav']   = { lvl = { 65, 69 } },
        ['Silver_Quadav']     = { lvl = { 45, 49 } },
        ['Steel_Quadav']      = { lvl = { 55, 59 } },
        ['Thunder_Elemental'] = { rsp = 840 },
        ['Water_Elemental']   = { rsp = 840 },
        ['Zircon_Quadav']     = { lvl = { 45, 49 } },
    },

    -- qulun_dome (zone 148)
    ['Qulun_Dome'] =
    {
        ['Diamond_Quadav']    = { lvl = { 75, 77 } },
        ['ZaDha_Adamantking'] = { lvl = { 85, 87 } },
    },

    -- davoi (zone 149)
    ['Davoi'] =
    {
        ['Dirtyhanded_Gochakzuk'] = { rsp = 600 },
        ['Orcish_Beastrider']     = { lvl = { 35, 39 } },
        ['Orcish_Bowshooter']     = { lvl = { 45, 49 } },
        ['Orcish_Champion']       = { lvl = { 65, 69 } },
        ['Orcish_Cursemaker']     = { lvl = { 25, 28 } },
        ['Orcish_Dreadnought']    = { lvl = { 65, 69 } },
        ['Orcish_Farkiller']      = { lvl = { 65, 69 } },
        ['Orcish_Fighter']        = { lvl = { 25, 28 } },
        ['Orcish_Footsoldier']    = { lvl = { 45, 49 } },
        ['Orcish_Gladiator']      = { lvl = { 45, 49 } },
        ['Orcish_Impaler']        = { lvl = { 35, 39 } },
        ['Orcish_Nightraider']    = { lvl = { 35, 39 } },
        ['Orcish_Predator']       = { lvl = { 55, 59 } },
        ['Orcish_Serjeant']       = { lvl = { 25, 28 } },
        ['Orcish_Trooper']        = { lvl = { 45, 49 } },
        ['Orcish_Veteran']        = { lvl = { 55, 59 } },
        ['Orcish_Zerker']         = { lvl = { 55, 59 } },
        ['Thunder_Elemental']     = { rsp = 840 },
        ['Water_Elemental']       = { rsp = 840 },
        ['Wolf_Bat']              = { rsp = 600 },
    },

    -- monastic_cavern (zone 150)
    ['Monastic_Cavern'] =
    {
        ['Orcish_Bowshooter']  = { lvl = { 45, 49 } },
        ['Orcish_Champion']    = { lvl = { 69, 72 } },
        ['Orcish_Dragoon']     = { lvl = { 69, 72 } },
        ['Orcish_Dreadnought'] = { lvl = { 69, 72 } },
        ['Orcish_Farkiller']   = { lvl = { 69, 72 } },
        ['Orcish_Footsoldier'] = { lvl = { 45, 49 } },
        ['Orcish_Gladiator']   = { lvl = { 45, 49 } },
        ['Orcish_Overlord']    = { lvl = { 75, 77 } },
        ['Orcish_Predator']    = { lvl = { 55, 59 } },
        ['Orcish_Veteran']     = { lvl = { 55, 59 } },
        ['Orcish_Zerker']      = { lvl = { 55, 59 } },
        ['Overlord_Bakgodek']  = { lvl = { 85, 87 } },
    },

    -- castle_oztroja (zone 151)
    ['Castle_Oztroja'] =
    {
        ['Bastion_Bats']           = { rsp = 600 },
        ['Bulwark_Bat']            = { rsp = 720 },
        ['Cutter']                 = { rsp = 720 },
        ['Earth_Elemental']        = { rsp = 840 },
        ['Fire_Elemental']         = { rsp = 840 },
        ['Meat_Maggot']            = { rsp = 720 },
        ['Ooze']                   = { rsp = 720 },
        ['Tzee_Xicu_the_Manifest'] = { lvl = { 85, 87 } },
        ['Yagudo_Assassin']        = { lvl = { 68, 72 } },
        ['Yagudo_Avatar']          = { lvl = { 75, 77 } },
        ['Yagudo_Chanter']         = { lvl = { 55, 59 } },
        ['Yagudo_Conductor']       = { lvl = { 68, 72 } },
        ['Yagudo_Conquistador']    = { lvl = { 45, 49 }, rsp = 840 },
        ['Yagudo_Drummer']         = { lvl = { 35, 39 }, rsp = 720 },
        ['Yagudo_Flagellant']      = { lvl = { 68, 72 } },
        ['Yagudo_Herald']          = { lvl = { 35, 39 }, rsp = 720 },
        ['Yagudo_Inquisitor']      = { lvl = { 55, 59 } },
        ['Yagudo_Interrogator']    = { rsp = 720 },
        ['Yagudo_Lutenist']        = { lvl = { 45, 49 }, rsp = 840 },
        ['Yagudo_Oracle']          = { lvl = { 35, 39 }, rsp = 720 },
        ['Yagudo_Parasite']        = { rsp = 840 },
        ['Yagudo_Prelate']         = { lvl = { 68, 72 } },
        ['Yagudo_Priest']          = { lvl = { 25, 28 }, rsp = 600 },
        ['Yagudo_Prior']           = { rsp = 840 },
        ['Yagudo_Sentinel']        = { lvl = { 55, 59 } },
        ['Yagudo_Theologist']      = { lvl = { 25, 28 }, rsp = 600 },
        ['Yagudo_Votary']          = { lvl = { 25, 28 }, rsp = 600 },
        ['Yagudo_Zealot']          = { lvl = { 45, 49 }, rsp = 840 },
    },

    -- the_boyahda_tree (zone 153)
    ['The_Boyahda_Tree'] =
    {
        ['Bark_Spider']         = { rsp = 960 },
        ['Bark_Tarantula']      = { lvl = { 76, 79 }, rsp = 960 },
        ['Blood_Ball']          = { rsp = 960 },
        ['Boyahda_Sapling']     = { rsp = 960 },
        ['Darter']              = { rsp = 960 },
        ['Death_Cap']           = { rsp = 960 },
        ['Demonic_Rose']        = { rsp = 960 },
        ['Elder_Goobbue']       = { rsp = 960 },
        ['Knight_Crawler']      = { lvl = { 64, 67 } },
        ['Korrigan']            = { rsp = 960 },
        ['Morbol_Menace']       = { rsp = 960 },
        ['Moss_Eater']          = { lvl = { 63, 66 }, rsp = 960 },
        ['Mourioche']           = { lvl = { 65, 68 }, rsp = 960 },
        ['Mourning_Crawler']    = { lvl = { 83, 85 }, rsp = 330 },
        ['Old_Goobbue']         = { rsp = 960 },
        ['Processionaire']      = { rsp = 960 },
        ['Robber_Crab']         = { lvl = { 62, 65 }, rsp = 960 },
        ['Skimmer']             = { rsp = 960 },
        ['Snaggletooth_Peapuk'] = { lvl = { 82, 85 }, rsp = 330 },
        ['Unut']                = { lvl = { 72, 74 } },
        ['Viseclaw']            = { lvl = { 82, 85 }, rsp = 330 },
        ['Voluptuous_Vivian']   = { lvl = { 85, 87 } },
    },

    -- dragons_aery (zone 154)
    ['Dragons_Aery'] =
    {
        ['Fafnir']  = { lvl = { 90, 92 } },
        ['Nidhogg'] = { lvl = { 92, 94 } },
    },

    -- middle_delkfutts_tower (zone 157)
    ['Middle_Delkfutts_Tower'] =
    {
        ['Banshee']            = { rsp = 720 },
        ['Big_Bat']            = { lvl = { 30, 32 }, rsp = 720 },
        ['Evil_Spirit']        = { rsp = 720 },
        ['Giant_Gatekeeper']   = { lvl = { 31, 34 }, rsp = 720 },
        ['Giant_Guard']        = { lvl = { 31, 34 }, rsp = 720 },
        ['Giant_Lobber']       = { lvl = { 31, 34 }, rsp = 720 },
        ['Giant_Sentry']       = { lvl = { 31, 34 }, rsp = 720 },
        ['Gigas_Jailer']       = { rsp = 720 },
        ['Gigas_Kettlemaster'] = { rsp = 720 },
        ['Gigas_Quarrier']     = { rsp = 720 },
        ['Gigas_Wallwatcher']  = { rsp = 720 },
        ['Goblin_Furrier']     = { lvl = { 31, 34 }, rsp = 720 },
        ['Goblin_Pathfinder']  = { lvl = { 31, 34 }, rsp = 720 },
        ['Goblin_Shaman']      = { lvl = { 31, 34 }, rsp = 720 },
        ['Goblin_Smithy']      = { lvl = { 31, 34 }, rsp = 720 },
        ['Jagd_Doll']          = { rsp = 720 },
        ['Light_Elemental']    = { rsp = 720 },
        ['Magic_Jar']          = { rsp = 720 },
        ['Magic_Pot']          = { rsp = 600 },
        ['Mold_Bats']          = { lvl = { 26, 29 }, rsp = 600 },
        ['Panzer_Doll']        = { rsp = 720 },
        ['Stirge']             = { lvl = { 28, 30 }, rsp = 600 },
        ['Thunder_Elemental']  = { rsp = 720 },
        ['Tower_Bats']         = { lvl = { 28, 30 }, rsp = 600 },
    },

    -- upper_delkfutts_tower (zone 158)
    ['Upper_Delkfutts_Tower'] =
    {
        ['Alkyoneus']         = { lvl = { 80, 82 } },
        ['Demonic_Doll']      = { rsp = 960 },
        ['Dire_Bat']          = { rsp = 960 },
        ['Gigas_Bonecutter']  = { lvl = { 34, 36 }, rsp = 720 },
        ['Gigas_Spirekeeper'] = { lvl = { 34, 36 }, rsp = 720 },
        ['Gigas_Stonemason']  = { lvl = { 34, 36 }, rsp = 720 },
        ['Gigas_Torturer']    = { lvl = { 34, 36 }, rsp = 720 },
        ['Incubus_Bats']      = { rsp = 960 },
        ['Jotunn_Gatekeeper'] = { rsp = 960 },
        ['Jotunn_Hallkeeper'] = { rsp = 960 },
        ['Jotunn_Wallkeeper'] = { rsp = 960 },
        ['Light_Elemental']   = { rsp = 720 },
        ['Magic_Pot']         = { rsp = 960 },
        ['Magic_Urn']         = { lvl = { 34, 36 }, rsp = 720 },
        ['Mimas']             = { lvl = { 36, 38 } },
        ['Pallas']            = { lvl = { 73, 75 } },
        ['Phasma']            = { rsp = 960 },
        ['Porphyrion']        = { lvl = { 36, 38 } },
        ['Thunder_Elemental'] = { rsp = 720 },
    },

    -- temple_of_uggalepih (zone 159)
    ['Temple_of_Uggalepih'] =
    {
        ['Iron_Maiden']         = { lvl = { 65, 68 } },
        ['Temple_Guardian']     = { lvl = { 65, 67 } },
        ['Tonberry_Cutter']     = { lvl = { 55, 59 } },
        ['Tonberry_Dismayer']   = { lvl = { 65, 69 } },
        ['Tonberry_Harrier']    = { lvl = { 55, 59 } },
        ['Tonberry_Maledictor'] = { lvl = { 65, 69 } },
        ['Tonberry_Pursuer']    = { lvl = { 65, 69 } },
        ['Tonberry_Stabber']    = { lvl = { 65, 69 } },
        ['Tonberry_Stalker']    = { lvl = { 55, 59 } },
    },

    -- den_of_rancor (zone 160)
    ['Den_of_Rancor'] =
    {
        ['Bifrons']              = { rsp = 960 },
        ['Bullbeggar']           = { rsp = 960 },
        ['Cave_Worm']            = { rsp = 960 },
        ['Cutlass_Scorpion']     = { rsp = 960 },
        ['Demonic_Pugil']        = { rsp = 330 },
        ['Den_Scorpion']         = { rsp = 960 },
        ['Dire_Bat']             = { rsp = 960 },
        ['Doom_Toad']            = { rsp = 330 },
        ['Fire_Elemental']       = { rsp = 960 },
        ['Friar_Rush']           = { lvl = { 70, 73 } },
        ['Hakutaku']             = { lvl = { 85, 87 } },
        ['Million_Eyes']         = { rsp = 960 },
        ['Mousse']               = { rsp = 960 },
        ['Puck']                 = { rsp = 960 },
        ['Succubus_Bats']        = { lvl = { 66, 69 }, rsp = 960 },
        ['Tonberry_Beleaguerer'] = { rsp = 960 },
        ['Tonberry_Imprecator']  = { rsp = 960 },
        ['Tonberry_Slasher']     = { rsp = 960 },
        ['Tonberry_Trailer']     = { rsp = 960 },
        ['Tormentor']            = { lvl = { 76, 79 }, rsp = 960 },
        ['Water_Elemental']      = { rsp = 960 },
    },

    -- castle_zvahl_baileys (zone 161)
    ['Castle_Zvahl_Baileys'] =
    {
        ['Dark_Elemental']      = { rsp = 840 },
        ['Demon_Pawn']          = { lvl = { 49, 52 }, rsp = 840 },
        ['Elder_Quadav']        = { rsp = 840 },
        ['Emerald_Quadav']      = { rsp = 840 },
        ['Evil_Eye']            = { lvl = { 48, 50 }, rsp = 840 },
        ['Goblin_Poacher']      = { rsp = 840 },
        ['Goblin_Reaper']       = { rsp = 840 },
        ['Goblin_Robber']       = { rsp = 840 },
        ['Goblin_Trader']       = { rsp = 840 },
        ['Ice_Elemental']       = { rsp = 840 },
        ['Iron_Quadav']         = { rsp = 840 },
        ['Orcish_Bowshooter']   = { rsp = 840 },
        ['Orcish_Footsoldier']  = { rsp = 840 },
        ['Orcish_Gladiator']    = { rsp = 840 },
        ['Orcish_Trooper']      = { rsp = 840 },
        ['Spinel_Quadav']       = { rsp = 840 },
        ['Yagudo_Conquistador'] = { rsp = 840 },
        ['Yagudo_Lutenist']     = { rsp = 840 },
        ['Yagudo_Prior']        = { rsp = 840 },
        ['Yagudo_Zealot']       = { rsp = 840 },
    },

    -- castle_zvahl_keep (zone 162)
    ['Castle_Zvahl_Keep'] =
    {
        ['Elder_Quadav']        = { rsp = 840 },
        ['Emerald_Quadav']      = { rsp = 840 },
        ['Evil_Eye']            = { lvl = { 50, 52 } },
        ['Goblin_Poacher']      = { rsp = 840 },
        ['Goblin_Reaper']       = { rsp = 840 },
        ['Goblin_Robber']       = { rsp = 840 },
        ['Goblin_Trader']       = { rsp = 840 },
        ['Iron_Quadav']         = { rsp = 840 },
        ['Morbid_Eye']          = { lvl = { 52, 55 } },
        ['Orcish_Bowshooter']   = { rsp = 840 },
        ['Orcish_Footsoldier']  = { rsp = 840 },
        ['Orcish_Gladiator']    = { rsp = 840 },
        ['Orcish_Trooper']      = { rsp = 840 },
        ['Spinel_Quadav']       = { rsp = 840 },
        ['Yagudo_Conquistador'] = { rsp = 840 },
        ['Yagudo_Lutenist']     = { rsp = 840 },
        ['Yagudo_Prior']        = { rsp = 840 },
        ['Yagudo_Zealot']       = { rsp = 840 },
    },

    -- ranguemont_pass (zone 166)
    ['Ranguemont_Pass'] =
    {
        ['Bilesucker']       = { lvl = { 40, 43 }, rsp = 330 },
        ['Blade_Bat']        = { lvl = { 5, 8 }, rsp = 480 },
        ['Cave_Scorpion']    = { rsp = 720 },
        ['Goblin_Artificer'] = { lvl = { 41, 44 }, rsp = 840 },
        ['Goblin_Chaser']    = { lvl = { 41, 44 }, rsp = 840 },
        ['Goblin_Gambler']   = { lvl = { 27, 30 }, rsp = 600 },
        ['Goblin_Hoodoo']    = { lvl = { 41, 44 }, rsp = 840 },
        ['Goblin_Leecher']   = { lvl = { 27, 30 }, rsp = 600 },
        ['Goblin_Mugger']    = { lvl = { 27, 30 }, rsp = 600 },
        ['Goblin_Tanner']    = { lvl = { 41, 44 }, rsp = 840 },
        ['Goblin_Thug']      = { lvl = { 6, 8 }, rsp = 480 },
        ['Goblin_Weaver']    = { lvl = { 6, 8 }, rsp = 480 },
        ['Goblins_Bats']     = { lvl = { 36, 38 } },
        ['Hecteyes']         = { rsp = 720 },
        ['Hovering_Oculus']  = { lvl = { 43, 45 }, rsp = 840 },
        ['Oil_Slick']        = { rsp = 480 },
        ['Ooze']             = { rsp = 600 },
        ['Seeker_Bats']      = { lvl = { 26, 29 }, rsp = 720 },
        ['Stirge']           = { rsp = 720 },
        ['Wind_Bats']        = { lvl = { 5, 7 }, rsp = 480 },
    },

    -- bostaunieux_oubliette (zone 167)
    ['Bostaunieux_Oubliette'] =
    {
        ['Arioch']         = { lvl = { 60, 62 } },
        ['Blind_Bat']      = { lvl = { 78, 80 }, rsp = 330 },
        ['Bloodsucker']    = { rsp = 330 },
        ['Dabilla']        = { lvl = { 75, 77 }, rsp = 330 },
        ['Dark_Aspic']     = { rsp = 960 },
        ['Funnel_Bats']    = { lvl = { 53, 56 }, rsp = 330 },
        ['Garm']           = { rsp = 960 },
        ['Haunt']          = { rsp = 960 },
        ['Hecatomb_Hound'] = { rsp = 960 },
        ['Mousse']         = { lvl = { 60, 62 }, rsp = 960 },
        ['Nachtmahr']      = { lvl = { 76, 78 }, rsp = 960 },
        ['Panna_Cotta']    = { lvl = { 78, 80 }, rsp = 330 },
        ['Werebat']        = { lvl = { 56, 59 }, rsp = 330 },
        ['Wurdalak']       = { lvl = { 80, 83 }, rsp = 960 },
    },

    -- toraimarai_canal (zone 169)
    ['Toraimarai_Canal'] =
    {
        ['Bigclaw']           = { rsp = 960 },
        ['Blackwater_Pugil']  = { lvl = { 67, 69 }, rsp = 330 },
        ['Bloodsucker']       = { rsp = 960 },
        ['Bouncing_Ball']     = { rsp = 960 },
        ['Canal_Bats']        = { rsp = 840 },
        ['Dark_Aspic']        = { rsp = 960 },
        ['Deviling_Bats']     = { lvl = { 68, 70 }, rsp = 330 },
        ['Dire_Bat']          = { rsp = 330 },
        ['Doom_Mage']         = { rsp = 960 },
        ['Doom_Soldier']      = { rsp = 960 },
        ['Drowned_Bones']     = { lvl = { 70, 72 }, rsp = 960 },
        ['Fallen_Knight']     = { rsp = 960 },
        ['Fleshcraver']       = { rsp = 960 },
        ['Flume_Toad']        = { lvl = { 70, 73 } },
        ['Girtab']            = { rsp = 960 },
        ['Hell_Bat']          = { rsp = 840 },
        ['Hinge_Oil']         = { rsp = 960 },
        ['Impish_Bats']       = { rsp = 330 },
        ['Lich']              = { rsp = 960 },
        ['Makara']            = { rsp = 330 },
        ['Mindcraver']        = { rsp = 960 },
        ['Mousse']            = { rsp = 960 },
        ['Plunderer_Crab']    = { lvl = { 66, 69 }, rsp = 330 },
        ['Poroggo_Excavator'] = { lvl = { 71, 73 }, rsp = 960 },
        ['Rapier_Scorpion']   = { lvl = { 68, 70 }, rsp = 960 },
        ['Rotten_Sod']        = { rsp = 960 },
        ['Scavenger_Crab']    = { rsp = 330 },
        ['Sodden_Bones']      = { lvl = { 70, 72 }, rsp = 960 },
        ['Starborer']         = { lvl = { 68, 70 }, rsp = 330 },
        ['Starmite']          = { rsp = 960 },
        ['Stygian_Pugil']     = { rsp = 330 },
    },

    -- zeruhn_mines (zone 172)
    ['Zeruhn_Mines'] =
    {
        ['Burrower_Worm']    = { lvl = { 21, 24 }, rsp = 600 },
        ['Colliery_Bat']     = { lvl = { 22, 25 }, rsp = 600 },
        ['Ding_Bats']        = { rsp = 480 },
        ['River_Crab']       = { rsp = 480 },
        ['Soot_Crab']        = { lvl = { 20, 23 }, rsp = 600 },
        ['Veindigger_Leech'] = { lvl = { 22, 25 }, rsp = 600 },
    },

    -- korroloka_tunnel (zone 173)
    ['Korroloka_Tunnel'] =
    {
        ['Bogy']               = { rsp = 720 },
        ['Clipper']            = { rsp = 720 },
        ['Combat']             = { rsp = 600 },
        ['Gigas_Foreman']      = { rsp = 720 },
        ['Gigas_Stonecarrier'] = { rsp = 720 },
        ['Gigas_Stonegrinder'] = { rsp = 720 },
        ['Gigas_Stonemason']   = { rsp = 720 },
        ['Greater_Pugil']      = { lvl = { 29, 32 }, rsp = 720 },
        ['Huge_Spider']        = { rsp = 600 },
        ['Jammer_Leech']       = { rsp = 1200 },
        ['Jelly']              = { rsp = 600 },
        ['Korroloka_Leech']    = { lvl = { 32, 33 } },
        ['Lacerator']          = { lvl = { 35, 37 }, rsp = 330 },
        ['Land_Worm']          = { lvl = { 22, 25 }, rsp = 600 },
        ['Sea_Monk']           = { rsp = 720 },
        ['Seeker_Bats']        = { lvl = { 23, 26 }, rsp = 600 },
        ['Spool_Leech']        = { lvl = { 35, 37 }, rsp = 330 },
        ['Thread_Leech']       = { rsp = 600 },
        ['Thunder_Elemental']  = { rsp = 720 },
        ['Water_Elemental']    = { rsp = 720 },
    },

    -- kuftal_tunnel (zone 174)
    ['Kuftal_Tunnel'] =
    {
        ['Air_Elemental']       = { rsp = 960 },
        ['Amemet']              = { lvl = { 66, 68 } },
        ['Cave_Worm']           = { rsp = 960 },
        ['Deinonychus']         = { rsp = 960 },
        ['Devil_Manta']         = { lvl = { 70, 72 } },
        ['Fire_Elemental']      = { rsp = 960 },
        ['Goblin_Alchemist']    = { rsp = 960 },
        ['Goblin_Bandit']       = { rsp = 960 },
        ['Goblin_Mercenary']    = { rsp = 960 },
        ['Goblin_Tamer']        = { rsp = 960 },
        ['Greater_Cockatrice']  = { rsp = 960 },
        ['Haunt']               = { rsp = 960 },
        ['Kuftal_Delver']       = { lvl = { 79, 81 }, rsp = 330 },
        ['Kuftal_Digger']       = { rsp = 960 },
        ['Ladon']               = { rsp = 960 },
        ['Machairodus']         = { lvl = { 80, 82 }, rsp = 330 },
        ['Ovinnik']             = { rsp = 960 },
        ['Pelican']             = { lvl = { 82, 83 } },
        ['Recluse_Spider']      = { rsp = 960 },
        ['Sabotender_Sediendo'] = { rsp = 960 },
        ['Sand_Lizard']         = { rsp = 960 },
    },

    -- sea_serpent_grotto (zone 176)
    ['Sea_Serpent_Grotto'] =
    {
        ['Bigclaw']              = { lvl = { 45, 48 }, rsp = 330 },
        ['Blubber_Eyes']         = { lvl = { 56, 58 } },
        ['Bog_Sahagin']          = { lvl = { 56, 59 } },
        ['Brook_Sahagin']        = { lvl = { 44, 47 }, rsp = 840 },
        ['Charybdis']            = { lvl = { 83, 84 } },
        ['Coastal_Sahagin']      = { lvl = { 69, 72 } },
        ['Delta_Sahagin']        = { lvl = { 69, 72 } },
        ['Devil_Manta']          = { lvl = { 68, 70 }, rsp = 960 },
        ['Dire_Bat']             = { lvl = { 66, 69 }, rsp = 330 },
        ['Ghast']                = { rsp = 720 },
        ['Greatclaw']            = { lvl = { 69, 71 } },
        ['Grotto_Pugil']         = { rsp = 330 },
        ['Ironshell']            = { rsp = 720 },
        ['Lagoon_Sahagin']       = { lvl = { 69, 72 } },
        ['Lake_Sahagin']         = { rsp = 720 },
        ['Marsh_Sahagin']        = { lvl = { 56, 59 } },
        ['Masan']                = { lvl = { 39, 41 } },
        ['Mindgazer']            = { lvl = { 69, 71 } },
        ['Mousse']               = { lvl = { 66, 68 } },
        ['Nightmare_Bats']       = { lvl = { 69, 71 } },
        ['Ocean_Sahagin']        = { lvl = { 75, 77 } },
        ['Ooze']                 = { rsp = 840 },
        ['Pahh_the_Gullcaller']  = { lvl = { 57, 59 } },
        ['Pond_Sahagin']         = { rsp = 720 },
        ['Riparian_Sahagin']     = { rsp = 840 },
        ['Rivulet_Sahagin']      = { lvl = { 44, 47 }, rsp = 840 },
        ['Robber_Crab']          = { lvl = { 67, 70 }, rsp = 330 },
        ['Royal_Leech']          = { rsp = 720 },
        ['Sahagin_Parasite']     = { lvl = { 53, 56 } },
        ['Sea_Bonze']            = { rsp = 840 },
        ['Sea_Hog']              = { lvl = { 62, 64 } },
        ['Seww_the_Squidlimbed'] = { lvl = { 48, 50 } },
        ['Shore_Sahagin']        = { lvl = { 69, 72 } },
        ['Spring_Sahagin']       = { rsp = 720 },
        ['Swamp_Sahagin']        = { lvl = { 56, 59 } },
        ['Undead_Bats']          = { rsp = 720 },
        ['Vampire_Bat']          = { lvl = { 43, 45 }, rsp = 840 },
        ['Water_Leaper']         = { lvl = { 80, 82 } },
        ['Zuug_the_Shoreleaper'] = { lvl = { 70, 72 } },
    },

    -- velugannon_palace (zone 177)
    ['VeLugannon_Palace'] =
    {
        ['Air_Elemental']     = { rsp = 960 },
        ['Brigandish_Blade']  = { lvl = { 84, 86 } },
        ['Detector']          = { rsp = 960 },
        ['Dustbuster']        = { rsp = 960 },
        ['Earth_Elemental']   = { rsp = 960 },
        ['Enkidu']            = { rsp = 960 },
        ['Fire_Elemental']    = { rsp = 960 },
        ['Ice_Elemental']     = { rsp = 960 },
        ['Mystic_Weapon']     = { lvl = { 75, 78 }, rsp = 960 },
        ['Ornamental_Weapon'] = { rsp = 960 },
        ['Steam_Cleaner']     = { lvl = { 83, 85 } },
        ['Thunder_Elemental'] = { rsp = 960 },
        ['Water_Elemental']   = { rsp = 960 },
        ['Zipacna']           = { lvl = { 85, 87 } },
    },

    -- the_shrine_of_ruavitau (zone 178)
    ['The_Shrine_of_RuAvitau'] =
    {
        ['Air_Elemental']     = { rsp = 960 },
        ['Aura_Butler']       = { lvl = { 80, 82 }, rsp = 960 },
        ['Aura_Gear']         = { lvl = { 79, 81 } },
        ['Aura_Pot']          = { lvl = { 78, 80 }, rsp = 960 },
        ['Aura_Sculpture']    = { lvl = { 83, 85 }, rsp = 330 },
        ['Aura_Statue']       = { rsp = 960 },
        ['Aura_Weapon']       = { rsp = 960 },
        ['Baelfyr']           = { lvl = { 83, 85 }, rsp = 330 },
        ['Byakko']            = { lvl = { 84, 85 } },
        ['Byrgen']            = { lvl = { 83, 85 }, rsp = 330 },
        ['Dark_Elemental']    = { rsp = 960 },
        ['Decorative_Weapon'] = { rsp = 960 },
        ['Defender']          = { lvl = { 74, 76 }, rsp = 960 },
        ['Earth_Elemental']   = { rsp = 960 },
        ['Faust']             = { lvl = { 85, 87 } },
        ['Fire_Elemental']    = { rsp = 960 },
        ['Gefyrst']           = { lvl = { 83, 85 }, rsp = 330 },
        ['Genbu']             = { lvl = { 84, 85 } },
        ['Ice_Elemental']     = { rsp = 960 },
        ['Kirin']             = { lvl = { 94, 94 } },
        ['Mother_Globe']      = { lvl = { 85, 87 } },
        ['Seiryu']            = { lvl = { 84, 85 } },
        ['Suzaku']            = { lvl = { 84, 85 } },
        ['Thunder_Elemental'] = { rsp = 960 },
        ['Ullikummi']         = { lvl = { 86, 88 } },
        ['Ungeweder']         = { lvl = { 83, 85 }, rsp = 330 },
        ['Water_Elemental']   = { rsp = 960 },
    },

    -- lower_delkfutts_tower (zone 184)
    ['Lower_Delkfutts_Tower'] =
    {
        ['Ancient_Bat']       = { lvl = { 28, 30 }, rsp = 330 },
        ['Bogy']              = { rsp = 720 },
        ['Chaos_Idol']        = { rsp = 600 },
        ['Giant_Gatekeeper']  = { rsp = 600 },
        ['Giant_Guard']       = { rsp = 600 },
        ['Giant_Lobber']      = { rsp = 600 },
        ['Giant_Sentry']      = { rsp = 600 },
        ['Gigas_Butcher']     = { rsp = 720 },
        ['Gigas_Hallwatcher'] = { rsp = 720 },
        ['Gigas_Punisher']    = { rsp = 720 },
        ['Gigas_Sculptor']    = { rsp = 720 },
        ['Goblin_Gambler']    = { rsp = 600 },
        ['Goblin_Leecher']    = { rsp = 600 },
        ['Goblin_Mugger']     = { rsp = 600 },
        ['Light_Elemental']   = { rsp = 720 },
        ['Magic_Pot']         = { rsp = 600 },
        ['Magic_Urn']         = { rsp = 720 },
        ['Seeker_Bats']       = { lvl = { 26, 28 }, rsp = 330 },
        ['Thunder_Elemental'] = { rsp = 720 },
    },

    -- dynamis_san_doria (zone 185)
    ['Dynamis-San_dOria'] =
    {
        ['Vanguards_Avatar']   = { lvl = { 85, 87 } },
        ['Vanguards_Hecteyes'] = { lvl = { 85, 87 } },
        ['Vanguards_Wyvern']   = { lvl = { 85, 87 } },
    },

    -- dynamis_bastok (zone 186)
    ['Dynamis-Bastok'] =
    {
        ['Vanguards_Avatar']   = { lvl = { 85, 87 } },
        ['Vanguards_Scorpion'] = { lvl = { 85, 87 } },
        ['Vanguards_Wyvern']   = { lvl = { 85, 87 } },
    },

    -- dynamis_windurst (zone 187)
    ['Dynamis-Windurst'] =
    {
        ['Vanguards_Avatar'] = { lvl = { 85, 87 } },
        ['Vanguards_Crow']   = { lvl = { 85, 87 } },
        ['Vanguards_Wyvern'] = { lvl = { 85, 87 } },
    },

    -- dynamis_jeuno (zone 188)
    ['Dynamis-Jeuno'] =
    {
        ['Anvilix_Sootwrists']    = { lvl = { 83, 84 } },
        ['Bandrix_Rockjaw']       = { lvl = { 83, 84 } },
        ['Blazox_Boneybod']       = { lvl = { 83, 84 } },
        ['Bootrix_Jaggedelbow']   = { lvl = { 83, 84 } },
        ['Buffrix_Eargone']       = { lvl = { 83, 84 } },
        ['Cloktix_Longnail']      = { lvl = { 83, 84 } },
        ['Distilix_Stickytoes']   = { lvl = { 83, 84 } },
        ['Elixmix_Hooknose']      = { lvl = { 83, 84 } },
        ['Eremix_Snottynostril']  = { lvl = { 87, 89 } },
        ['Gabblox_Magpietongue']  = { lvl = { 83, 84 } },
        ['Hermitrix_Toothrot']    = { lvl = { 83, 84 } },
        ['Humnox_Drumbelly']      = { lvl = { 83, 84 } },
        ['Jabbrox_Grannyguise']   = { lvl = { 83, 84 } },
        ['Jabkix_Pigeonpecs']     = { lvl = { 83, 84 } },
        ['Karashix_Swollenskull'] = { lvl = { 87, 89 } },
        ['Kikklix_Longlegs']      = { lvl = { 87, 89 } },
        ['Lurklox_Dhalmelneck']   = { lvl = { 83, 84 } },
        ['Mobpix_Mucousmouth']    = { lvl = { 83, 84 } },
        ['Morgmox_Moldnoggin']    = { lvl = { 83, 84 } },
        ['Mortilox_Wartpaws']     = { lvl = { 87, 89 } },
        ['Prowlox_Barrelbelly']   = { lvl = { 87, 89 } },
        ['Rutrix_Hamgams']        = { lvl = { 83, 84 } },
        ['Scruffix_Shaggychest']  = { lvl = { 83, 84 } },
        ['Slystix_Megapeepers']   = { lvl = { 83, 84 } },
        ['Smeltix_Thickhide']     = { lvl = { 83, 84 } },
        ['Snypestix_Eaglebeak']   = { lvl = { 87, 89 } },
        ['Sparkspox_Sweatbrow']   = { lvl = { 83, 84 } },
        ['Ticktox_Beadyeyes']     = { lvl = { 83, 84 } },
        ['Trailblix_Goatmug']     = { lvl = { 83, 84 } },
        ['Tufflix_Loglimbs']      = { lvl = { 83, 84 } },
        ['Tymexox_Ninefingers']   = { lvl = { 87, 89 } },
        ['Vanguards_Avatar']      = { lvl = { 85, 87 } },
        ['Vanguards_Slime']       = { lvl = { 85, 87 } },
        ['Vanguards_Wyvern']      = { lvl = { 85, 87 } },
        ['Wasabix_Callusdigit']   = { lvl = { 83, 84 } },
        ['Wyrmwix_Snakespecs']    = { lvl = { 83, 84 } },
    },

    -- king_ranperres_tomb (zone 190)
    ['King_Ranperres_Tomb'] =
    {
        ['Carrion_Worm']           = { lvl = { 3, 5 }, rsp = 480 },
        ['Ding_Bats']              = { lvl = { 3, 5 }, rsp = 480 },
        ['Enchanted_Bones']        = { lvl = { 5, 8 }, rsp = 480 },
        ['Goblin_Ambusher']        = { lvl = { 12, 14 }, rsp = 480 },
        ['Goblin_Butcher']         = { lvl = { 12, 14 }, rsp = 480 },
        ['Goblin_Gambler']         = { rsp = 600 },
        ['Goblin_Leecher']         = { rsp = 600 },
        ['Goblin_Mugger']          = { rsp = 600 },
        ['Goblin_Thug']            = { lvl = { 5, 8 }, rsp = 480 },
        ['Goblin_Tinkerer']        = { lvl = { 12, 14 }, rsp = 480 },
        ['Goblin_Weaver']          = { lvl = { 5, 8 }, rsp = 480 },
        ['Grave_Bat']              = { rsp = 480 },
        ['Hati']                   = { lvl = { 10, 12 }, rsp = 960 },
        ['Locus_Armet_Beetle']     = { lvl = { 64, 66 }, rsp = 330 },
        ['Locus_Cutlass_Scorpion'] = { lvl = { 63, 65 }, rsp = 960 },
        ['Locus_Dire_Bat']         = { lvl = { 62, 64 }, rsp = 330 },
        ['Locus_Hati']             = { lvl = { 79, 81 }, rsp = 330 },
        ['Locus_Lemures']          = { lvl = { 80, 82 }, rsp = 960 },
        ['Locus_Spartoi_Sorcerer'] = { lvl = { 81, 83 }, rsp = 330 },
        ['Locus_Spartoi_Warrior']  = { lvl = { 81, 83 }, rsp = 330 },
        ['Locus_Thousand_Eyes']    = { lvl = { 60, 62 }, rsp = 960 },
        ['Locus_Tomb_Worm']        = { lvl = { 58, 60 }, rsp = 330 },
        ['Mouse_Bat']              = { lvl = { 4, 7 }, rsp = 480 },
        ['Nachzehrer']             = { rsp = 480 },
        ['Plague_Bats']            = { rsp = 480 },
        ['Rock_Eater']             = { rsp = 480 },
        ['Spartoi_Sorcerer']       = { rsp = 960 },
        ['Spartoi_Warrior']        = { rsp = 960 },
        ['Spook']                  = { rsp = 480 },
        ['Stone_Eater']            = { rsp = 480 },
        ['Tomb_Bat']               = { rsp = 480 },
        ['Wind_Bats']              = { lvl = { 10, 12 }, rsp = 480 },
    },

    -- dangruf_wadi (zone 191)
    ['Dangruf_Wadi'] =
    {
        ['Couloir_Leech']      = { lvl = { 22, 25 }, rsp = 600 },
        ['Fume_Lizard']        = { lvl = { 26, 29 }, rsp = 600 },
        ['Goblin_Ambusher']    = { lvl = { 13, 16 }, rsp = 480 },
        ['Goblin_Bladesmith']  = { lvl = { 26, 29 }, rsp = 600 },
        ['Goblin_Brigand']     = { lvl = { 21, 24 }, rsp = 600 },
        ['Goblin_Bushwhacker'] = { lvl = { 26, 29 }, rsp = 600 },
        ['Goblin_Butcher']     = { lvl = { 13, 16 }, rsp = 480 },
        ['Goblin_Conjurer']    = { lvl = { 26, 29 } },
        ['Goblin_Fisher']      = { rsp = 480 },
        ['Goblin_Headsman']    = { lvl = { 21, 24 }, rsp = 600 },
        ['Goblin_Healer']      = { lvl = { 21, 24 }, rsp = 600 },
        ['Goblin_Thug']        = { lvl = { 6, 8 }, rsp = 480 },
        ['Goblin_Tinkerer']    = { lvl = { 13, 16 }, rsp = 480 },
        ['Goblin_Weaver']      = { lvl = { 6, 8 }, rsp = 480 },
        ['Hoarder_Hare']       = { rsp = 480 },
        ['Natty_Gibbon']       = { lvl = { 27, 30 }, rsp = 600 },
        ['Prim_Pika']          = { lvl = { 20, 23 }, rsp = 600 },
        ['Rock_Lizard']        = { rsp = 480 },
        ['Steam_Lizard']       = { lvl = { 15, 18 }, rsp = 480 },
        ['Stone_Eater']        = { lvl = { 4, 7 }, rsp = 480 },
        ['Trimmer']            = { lvl = { 26, 29 }, rsp = 600 },
        ['Wadi_Crab']          = { rsp = 480 },
        ['Wadi_Hare']          = { rsp = 480 },
        ['Witchetty_Grub']     = { lvl = { 20, 23 }, rsp = 600 },
    },

    -- inner_horutoto_ruins (zone 192)
    ['Inner_Horutoto_Ruins'] =
    {
        ['Balloon']             = { rsp = 480 },
        ['Battle_Bat']          = { lvl = { 19, 22 }, rsp = 600 },
        ['Battue_Bats']         = { lvl = { 3, 5 }, rsp = 480 },
        ['Blade_Bat']           = { rsp = 480 },
        ['Blob']                = { lvl = { 16, 18 }, rsp = 480 },
        ['Boggart']             = { lvl = { 23, 26 }, rsp = 600 },
        ['Covin_Bat']           = { lvl = { 13, 16 }, rsp = 480 },
        ['Deathwatch_Beetle']   = { lvl = { 12, 15 }, rsp = 480 },
        ['Goblin_Flesher']      = { lvl = { 14, 17 }, rsp = 480 },
        ['Goblin_Gambler']      = { rsp = 600 },
        ['Goblin_Leecher']      = { rsp = 600 },
        ['Goblin_Lurcher']      = { lvl = { 14, 17 }, rsp = 480 },
        ['Goblin_Metallurgist'] = { lvl = { 14, 17 }, rsp = 480 },
        ['Goblin_Mugger']       = { rsp = 600 },
        ['Goblin_Thug']         = { lvl = { 4, 7 }, rsp = 480 },
        ['Goblin_Trailblazer']  = { lvl = { 14, 17 }, rsp = 480 },
        ['Goblin_Weaver']       = { lvl = { 4, 7 }, rsp = 480 },
        ['Skinnymajinx']        = { lvl = { 14, 16 }, rsp = 480 },
        ['Skinnymalinks']       = { lvl = { 14, 16 }, rsp = 480 },
        ['Troika_Bats']         = { lvl = { 11, 14 }, rsp = 480 },
        ['Wendigo']             = { rsp = 600 },
        ['Will-o-the-Wisp']     = { rsp = 600 },
    },

    -- ordelles_caves (zone 193)
    ['Ordelles_Caves'] =
    {
        ['Ancient_Bat']      = { lvl = { 28, 30 }, rsp = 600 },
        ['Bilis_Leech']      = { lvl = { 37, 39 }, rsp = 330 },
        ['Blood_Bunny']      = { lvl = { 18, 20 }, rsp = 480 },
        ['Buds_Bunny']       = { lvl = { 25, 28 }, rsp = 720 },
        ['Clipper']          = { rsp = 600 },
        ['Dung_Beetle']      = { rsp = 600 },
        ['Fly_Agaric']       = { rsp = 600 },
        ['Goblin_Ambusher']  = { rsp = 480 },
        ['Goblin_Butcher']   = { rsp = 480 },
        ['Goblin_Gambler']   = { lvl = { 23, 26 } },
        ['Goblin_Leecher']   = { lvl = { 23, 26 } },
        ['Goblin_Mugger']    = { lvl = { 23, 26 } },
        ['Goblin_Tinkerer']  = { rsp = 480 },
        ['Hognosed_Bat']     = { lvl = { 18, 21 }, rsp = 480 },
        ['Napalm']           = { rsp = 720 },
        ['Seeker_Bats']      = { lvl = { 27, 30 }, rsp = 600 },
        ['Slash_Pine']       = { lvl = { 30, 32 }, rsp = 720 },
        ['Snipper']          = { rsp = 480 },
        ['Stalking_Sapling'] = { lvl = { 19, 22 }, rsp = 600 },
        ['Stink_Bats']       = { lvl = { 17, 19 }, rsp = 480 },
        ['Stroper']          = { lvl = { 32, 34 }, rsp = 720 },
        ['Stroper_Chyme']    = { rsp = 720 },
        ['Swagger_Spruce']   = { lvl = { 26, 29 }, rsp = 600 },
        ['Targe_Beetle']     = { lvl = { 35, 37 }, rsp = 720 },
        ['Vorpal_Bunny']     = { rsp = 600 },
        ['Will-o-the-Wisp']  = { rsp = 600 },
    },

    -- outer_horutoto_ruins (zone 194)
    ['Outer_Horutoto_Ruins'] =
    {
        ['Balloon']           = { rsp = 480 },
        ['Battue_Bats']       = { lvl = { 3, 5 }, rsp = 480 },
        ['Black_Slime']       = { rsp = 600 },
        ['Blade_Bat']         = { lvl = { 5, 7 }, rsp = 480 },
        ['Combat']            = { rsp = 600 },
        ['Dancing_Weapon']    = { rsp = 600 },
        ['Eight_of_Batons']   = { lvl = { 31, 34 }, rsp = 720 },
        ['Eight_of_Coins']    = { lvl = { 31, 34 }, rsp = 720 },
        ['Eight_of_Cups']     = { lvl = { 31, 34 }, rsp = 720 },
        ['Eight_of_Swords']   = { lvl = { 31, 34 }, rsp = 720 },
        ['Fetor_Bats']        = { lvl = { 25, 29 }, rsp = 330 },
        ['Five_of_Batons']    = { lvl = { 16, 19 }, rsp = 480 },
        ['Five_of_Coins']     = { lvl = { 16, 19 }, rsp = 480 },
        ['Five_of_Cups']      = { lvl = { 16, 19 }, rsp = 480 },
        ['Five_of_Swords']    = { lvl = { 16, 19 }, rsp = 480 },
        ['Four_of_Batons']    = { lvl = { 11, 14 }, rsp = 480 },
        ['Four_of_Coins']     = { lvl = { 11, 14 }, rsp = 480 },
        ['Four_of_Cups']      = { lvl = { 11, 14 }, rsp = 480 },
        ['Four_of_Swords']    = { lvl = { 11, 14 }, rsp = 480 },
        ['Fuligo']            = { lvl = { 22, 25 }, rsp = 330 },
        ['Ghoul']             = { rsp = 600 },
        ['Goblin_Ambusher']   = { lvl = { 14, 17 }, rsp = 480 },
        ['Goblin_Butcher']    = { lvl = { 14, 17 }, rsp = 480 },
        ['Goblin_Thug']       = { rsp = 480 },
        ['Goblin_Tinkerer']   = { lvl = { 14, 17 }, rsp = 480 },
        ['Goblin_Weaver']     = { rsp = 480 },
        ['Legalox_Heftyhind'] = { rsp = 4200 },
        ['Nine_of_Batons']    = { lvl = { 36, 39 }, rsp = 720 },
        ['Nine_of_Coins']     = { lvl = { 36, 39 }, rsp = 720 },
        ['Nine_of_Cups']      = { lvl = { 36, 39 }, rsp = 720 },
        ['Nine_of_Swords']    = { lvl = { 36, 39 }, rsp = 720 },
        ['Rotten_Jam']        = { rsp = 480 },
        ['Seven_of_Batons']   = { lvl = { 26, 29 }, rsp = 600 },
        ['Seven_of_Coins']    = { lvl = { 26, 29 }, rsp = 600 },
        ['Seven_of_Cups']     = { lvl = { 26, 29 }, rsp = 600 },
        ['Seven_of_Swords']   = { lvl = { 26, 29 }, rsp = 600 },
        ['Six_of_Batons']     = { lvl = { 21, 24 }, rsp = 600 },
        ['Six_of_Coins']      = { lvl = { 21, 24 }, rsp = 600 },
        ['Six_of_Cups']       = { lvl = { 21, 24 }, rsp = 600 },
        ['Six_of_Swords']     = { lvl = { 21, 24 }, rsp = 600 },
        ['Stink_Bats']        = { rsp = 480 },
        ['Ten_of_Batons']     = { lvl = { 41, 44 }, rsp = 840 },
        ['Ten_of_Coins']      = { lvl = { 41, 44 }, rsp = 840 },
        ['Ten_of_Cups']       = { lvl = { 41, 44 }, rsp = 840 },
        ['Ten_of_Swords']     = { lvl = { 41, 44 }, rsp = 840 },
        ['Thorn_Bat']         = { lvl = { 23, 26 }, rsp = 330 },
        ['Three_of_Batons']   = { lvl = { 6, 9 }, rsp = 480 },
        ['Three_of_Coins']    = { lvl = { 6, 9 }, rsp = 480 },
        ['Three_of_Cups']     = { lvl = { 6, 9 }, rsp = 480 },
        ['Three_of_Swords']   = { lvl = { 6, 9 }, rsp = 480 },
        ['Two_of_Batons']     = { lvl = { 5, 8 }, rsp = 480 },
        ['Two_of_Coins']      = { lvl = { 5, 8 }, rsp = 480 },
        ['Two_of_Cups']       = { lvl = { 5, 8 }, rsp = 480 },
        ['Two_of_Swords']     = { lvl = { 5, 8 }, rsp = 480 },
    },

    -- the_eldieme_necropolis (zone 195)
    ['The_Eldieme_Necropolis'] =
    {
        ['Anemone']           = { rsp = 840 },
        ['Azer']              = { rsp = 960 },
        ['Blood_Soul']        = { rsp = 960 },
        ['Cwn_Cyrff']         = { lvl = { 68, 70 } },
        ['Dark_Stalker']      = { rsp = 960 },
        ['Fallen_Knight']     = { rsp = 960 },
        ['Gazer']             = { rsp = 840 },
        ['Haunt']             = { rsp = 960 },
        ['Hell_Hound']        = { rsp = 840 },
        ['Hellbound_Warlock'] = { lvl = { 57, 60 }, rsp = 330 },
        ['Hellbound_Warrior'] = { lvl = { 57, 60 }, rsp = 330 },
        ['Ka']                = { rsp = 960 },
        ['Lich']              = { lvl = { 52, 55 }, rsp = 960 },
        ['Marchosias']        = { rsp = 840 },
        ['Mummy']             = { rsp = 960 },
        ['Nekros_Hound']      = { lvl = { 57, 60 }, rsp = 330 },
        ['Puroboros']         = { rsp = 840 },
        ['Revenant']          = { rsp = 840 },
        ['Shade']             = { rsp = 840 },
        ['Skull_of_Envy']     = { lvl = { 60, 62 } },
        ['Skull_of_Gluttony'] = { lvl = { 60, 62 } },
        ['Skull_of_Greed']    = { lvl = { 60, 62 } },
        ['Skull_of_Lust']     = { lvl = { 60, 62 } },
        ['Skull_of_Pride']    = { lvl = { 60, 62 } },
        ['Skull_of_Sloth']    = { lvl = { 60, 62 } },
        ['Skull_of_Wrath']    = { lvl = { 60, 62 } },
        ['Spriggan']          = { rsp = 960 },
        ['Tomb_Mage']         = { rsp = 960 },
        ['Tomb_Warrior']      = { rsp = 960 },
        ['Tomb_Wolf']         = { rsp = 960 },
        ['Utukku']            = { rsp = 960 },
    },

    -- gusgen_mines (zone 196)
    ['Gusgen_Mines'] =
    {
        ['Accursed_Soldier']  = { lvl = { 42, 45 }, rsp = 840 },
        ['Accursed_Sorcerer'] = { lvl = { 42, 45 }, rsp = 840 },
        ['Amphisbaena']       = { rsp = 600 },
        ['Bandersnatch']      = { rsp = 600 },
        ['Banshee']           = { rsp = 720 },
        ['Bogy']              = { rsp = 600 },
        ['Feu_Follet']        = { rsp = 720 },
        ['Fly_Agaric']        = { rsp = 600 },
        ['Gallinipper']       = { rsp = 720 },
        ['Greater_Pugil']     = { rsp = 330 },
        ['Jelly']             = { rsp = 600 },
        ['Madfly']            = { lvl = { 41, 44 }, rsp = 840 },
        ['Mauthe_Doog']       = { rsp = 600 },
        ['Myconid']           = { rsp = 720 },
        ['Ore_Eater']         = { rsp = 600 },
        ['Rancid_Ooze']       = { rsp = 720 },
        ['Rockmill']          = { lvl = { 40, 43 }, rsp = 840 },
        ['Sadfly']            = { rsp = 600 },
        ['Skeleton_Warrior']  = { rsp = 480 },
        ['Spunkie']           = { rsp = 600 },
        ['Thunder_Elemental'] = { rsp = 720 },
        ['Wendigo']           = { lvl = { 27, 30 }, rsp = 600 },
    },

    -- crawlers_nest (zone 197)
    ['Crawlers_Nest'] =
    {
        ['Blazer_Beetle']    = { rsp = 960 },
        ['Caveberry']        = { rsp = 840 },
        ['Crawler_Hunter']   = { rsp = 960 },
        ['Dancing_Jewel']    = { lvl = { 64, 67 }, rsp = 960 },
        ['Death_Jacket']     = { rsp = 840 },
        ['Demonic_Tiphia']   = { lvl = { 60, 62 } },
        ['Doom_Scorpion']    = { lvl = { 47, 49 }, rsp = 840 },
        ['Dragonfly']        = { rsp = 960 },
        ['Drone_Crawler']    = { lvl = { 55, 55 } },
        ['Dynast_Beetle']    = { lvl = { 60, 62 }, rsp = 960 },
        ['Exoray']           = { rsp = 960 },
        ['Fire_Elemental']   = { rsp = 960 },
        ['Guardian_Crawler'] = { lvl = { 50, 50 } },
        ['Helm_Beetle']      = { rsp = 960 },
        ['Hornfly']          = { rsp = 960 },
        ['Killer_Mushroom']  = { rsp = 840 },
        ['King_Crawler']     = { lvl = { 65, 68 }, rsp = 960 },
        ['Knight_Crawler']   = { rsp = 960 },
        ['Labyrinth_Lizard'] = { rsp = 960 },
        ['Maze_Lizard']      = { rsp = 840 },
        ['Mushussu']         = { rsp = 960 },
        ['Nest_Beetle']      = { rsp = 840 },
        ['Olid_Funguar']     = { lvl = { 62, 65 }, rsp = 960 },
        ['Rumble_Crawler']   = { rsp = 330 },
        ['Soldier_Crawler']  = { rsp = 330 },
        ['Soul_Stinger']     = { rsp = 960 },
        ['Vespo']            = { lvl = { 61, 64 }, rsp = 960 },
        ['Witch_Hazel']      = { rsp = 960 },
        ['Worker_Crawler']   = { lvl = { 41, 44 }, rsp = 840 },
    },

    -- maze_of_shakhrami (zone 198)
    ['Maze_of_Shakhrami'] =
    {
        ['Abyss_Worm']          = { rsp = 600 },
        ['Air_Elemental']       = { rsp = 720 },
        ['Ancient_Bat']         = { rsp = 600 },
        ['Bleeder_Leech']       = { lvl = { 36, 39 }, rsp = 720 },
        ['Carnivorous_Crawler'] = { rsp = 600 },
        ['Caterchipillar']      = { rsp = 720 },
        ['Chaser_Bats']         = { lvl = { 35, 38 }, rsp = 720 },
        ['Combat']              = { rsp = 600 },
        ['Crypterpillar']       = { lvl = { 39, 42 }, rsp = 720 },
        ['Earth_Elemental']     = { rsp = 720 },
        ['Gloombound_Lurker']   = { lvl = { 58, 60 } },
        ['Goblin_Ambusher']     = { lvl = { 17, 20 }, rsp = 480 },
        ['Goblin_Butcher']      = { lvl = { 17, 20 }, rsp = 480 },
        ['Goblin_Furrier']      = { rsp = 720 },
        ['Goblin_Gambler']      = { lvl = { 23, 26 }, rsp = 600 },
        ['Goblin_Leecher']      = { lvl = { 23, 26 }, rsp = 600 },
        ['Goblin_Mugger']       = { lvl = { 23, 26 }, rsp = 600 },
        ['Goblin_Pathfinder']   = { rsp = 720 },
        ['Goblin_Shaman']       = { rsp = 720 },
        ['Goblin_Smithy']       = { rsp = 720 },
        ['Goblin_Tinkerer']     = { lvl = { 17, 20 }, rsp = 480 },
        ['Goblins_Bat']         = { rsp = 600 },
        ['Jelly']               = { rsp = 600 },
        ['Labyrinth_Scorpion']  = { rsp = 720 },
        ['Lesath']              = { lvl = { 36, 38 } },
        ['Maze_Maker']          = { rsp = 480 },
        ['Maze_Scorpion']       = { lvl = { 24, 27 }, rsp = 600 },
        ['Poison_Leech']        = { lvl = { 25, 28 }, rsp = 600 },
        ['Protozoan']           = { rsp = 720 },
        ['Seeker_Bats']         = { rsp = 600 },
        ['Stink_Bats']          = { lvl = { 16, 19 }, rsp = 480 },
        ['Trembler_Tabitha']    = { lvl = { 55, 57 } },
        ['Warren_Bat']          = { lvl = { 38, 41 }, rsp = 720 },
        ['Wight']               = { rsp = 720 },
    },

    -- garlaige_citadel (zone 200)
    ['Garlaige_Citadel'] =
    {
        ['Acid_Grease']       = { rsp = 960 },
        ['Bhuta']             = { rsp = 840 },
        ['Borer_Beetle']      = { rsp = 840 },
        ['Chamber_Beetle']    = { rsp = 330 },
        ['Citadel_Bats']      = { rsp = 840 },
        ['Clockwork_Pod']     = { rsp = 840 },
        ['Demonic_Weapon']    = { rsp = 840 },
        ['Donjon_Bat']        = { lvl = { 60, 63 }, rsp = 960 },
        ['Droma']             = { rsp = 960 },
        ['Earth_Elemental']   = { rsp = 960 },
        ['Explosure']         = { rsp = 960 },
        ['Fallen_Evacuee']    = { rsp = 840 },
        ['Fallen_Mage']       = { rsp = 960 },
        ['Fallen_Major']      = { rsp = 960 },
        ['Fallen_Officer']    = { rsp = 960 },
        ['Fallen_Soldier']    = { rsp = 840 },
        ['Fetid_Flesh']       = { rsp = 960 },
        ['Fortalice_Bats']    = { lvl = { 58, 61 }, rsp = 960 },
        ['Funnel_Bats']       = { lvl = { 52, 55 }, rsp = 330 },
        ['Hellmine']          = { rsp = 960 },
        ['Kaboom']            = { lvl = { 62, 65 }, rsp = 960 },
        ['Magic_Jug']         = { rsp = 960 },
        ['Oil_Spill']         = { rsp = 840 },
        ['Old_Two-Wings']     = { lvl = { 52, 54 } },
        ['Over_Weapon']       = { rsp = 960 },
        ['Puroboros']         = { rsp = 840 },
        ['Revenant']          = { rsp = 840 },
        ['Serket']            = { lvl = { 70, 75 } },
        ['Siege_Bat']         = { rsp = 840 },
        ['Skewer_Sam']        = { lvl = { 54, 56 } },
        ['Tainted_Flesh']     = { rsp = 960 },
        ['Thunder_Elemental'] = { rsp = 960 },
        ['Vault_Weapon']      = { rsp = 960 },
        ['Warden_Beetle']     = { lvl = { 61, 64 }, rsp = 960 },
        ['Wingrats']          = { rsp = 840 },
        ['Wraith']            = { rsp = 960 },
    },

    -- feiyin (zone 204)
    ['FeiYin'] =
    {
        ['Balayang']          = { lvl = { 59, 62 }, rsp = 960 },
        ['Camazotz']          = { lvl = { 52, 55 }, rsp = 960 },
        ['Capricious_Cassie'] = { lvl = { 70, 75 } },
        ['Clockwork_Pod']     = { rsp = 840 },
        ['Colossus']          = { rsp = 960 },
        ['Dark_Elemental']    = { rsp = 960 },
        ['Droma']             = { rsp = 960 },
        ['Drone']             = { rsp = 840 },
        ['Hellish_Weapon']    = { rsp = 960 },
        ['Ice_Elemental']     = { rsp = 960 },
        ['Jenglot']           = { lvl = { 73, 75 } },
        ['Killing_Weapon']    = { rsp = 960 },
        ['Mind_Hoarder']      = { lvl = { 61, 63 } },
        ['Ore_Golem']         = { rsp = 840 },
        ['Revenant']          = { rsp = 840 },
        ['Sentient_Carafe']   = { lvl = { 60, 62 }, rsp = 960 },
        ['Shadow']            = { rsp = 840 },
        ['Specter']           = { rsp = 960 },
        ['Talos']             = { rsp = 960 },
        ['Undead_Bats']       = { lvl = { 39, 41 }, rsp = 840 },
        ['Underworld_Bats']   = { lvl = { 51, 54 }, rsp = 960 },
        ['Utukku']            = { rsp = 960 },
        ['Vampire_Bat']       = { rsp = 840 },
        ['Wekufe']            = { lvl = { 45, 47 }, rsp = 960 },
    },

    -- ifrits_cauldron (zone 205)
    ['Ifrits_Cauldron'] =
    {
        ['Ash_Dragon']       = { lvl = { 85, 87 } },
        ['Ash_Lizard']       = { rsp = 960 },
        ['Dire_Bat']         = { lvl = { 63, 66 }, rsp = 960 },
        ['Dodomeki']         = { lvl = { 66, 69 }, rsp = 960 },
        ['Eotyrannus']       = { rsp = 960 },
        ['Goblin_Alchemist'] = { lvl = { 67, 70 }, rsp = 960 },
        ['Goblin_Bandit']    = { lvl = { 67, 70 }, rsp = 960 },
        ['Goblin_Mercenary'] = { lvl = { 67, 70 }, rsp = 960 },
        ['Goblin_Shepherd']  = { lvl = { 67, 70 }, rsp = 960 },
        ['Hurricane_Wyvern'] = { rsp = 960 },
        ['Nightmare_Bats']   = { lvl = { 72, 75 }, rsp = 960 },
        ['Old_Opo-opo']      = { lvl = { 64, 67 }, rsp = 960 },
        ['Sulfur_Scorpion']  = { rsp = 960 },
        ['Volcanic_Bomb']    = { lvl = { 74, 77 }, rsp = 960 },
        ['Volcanic_Gas']     = { lvl = { 65, 68 }, rsp = 960 },
        ['Volcano_Wasp']     = { lvl = { 64, 67 }, rsp = 960 },
    },

    -- quicksand_caves (zone 208)
    ['Quicksand_Caves'] =
    {
        ['Ancient_Vessel']       = { lvl = { 75, 75 } },
        ['Antican_Consul']       = { lvl = { 75, 77 } },
        ['Antican_Hastatus']     = { lvl = { 68, 72 } },
        ['Antican_Princeps']     = { lvl = { 68, 72 } },
        ['Antican_Signifer']     = { lvl = { 68, 72 } },
        ['Diamond_Daig']         = { lvl = { 70, 72 } },
        ['Girtab']               = { lvl = { 67, 70 } },
        ['Helm_Beetle']          = { lvl = { 55, 58 } },
        ['Sabotender_Bailaor']   = { lvl = { 68, 72 } },
        ['Sabotender_Bailarina'] = { lvl = { 83, 84 } },
        ['Sand_Digger']          = { lvl = { 65, 68 } },
        ['Sand_Eater']           = { lvl = { 56, 59 } },
        ['Sand_Spider']          = { lvl = { 53, 56 } },
    },

    -- gustav_tunnel (zone 212)
    ['Gustav_Tunnel'] =
    {
        ['Boulder_Eater']          = { lvl = { 81, 83 }, rsp = 330 },
        ['Demonic_Pugil']          = { rsp = 960 },
        ['Doom_Guard']             = { rsp = 960 },
        ['Doom_Mage']              = { rsp = 960 },
        ['Doom_Soldier']           = { rsp = 960 },
        ['Doom_Warlock']           = { rsp = 960 },
        ['Earth_Elemental']        = { rsp = 960 },
        ['Erlik']                  = { rsp = 960 },
        ['Fire_Elemental']         = { rsp = 960 },
        ['Goblin_Alchemist']       = { rsp = 960 },
        ['Goblin_Mercenary']       = { rsp = 960 },
        ['Goblin_Poacher']         = { rsp = 840 },
        ['Goblin_Reaper']          = { rsp = 840 },
        ['Goblin_Robber']          = { rsp = 840 },
        ['Goblin_Shepherd']        = { rsp = 960 },
        ['Greater_Gaylas']         = { rsp = 840 },
        ['Hawker']                 = { rsp = 840 },
        ['Hell_Bat']               = { lvl = { 45, 48 }, rsp = 840 },
        ['Labyrinth_Leech']        = { rsp = 840 },
        ['Labyrinth_Lizard']       = { rsp = 840 },
        ['Makara']                 = { rsp = 840 },
        ['Pygmytoise']             = { lvl = { 82, 84 }, rsp = 330 },
        ['Robber_Crab']            = { rsp = 960 },
        ['Typhoon_Wyvern']         = { rsp = 960 },
        ['Wyvernpoacher_Drachlox'] = { lvl = { 73, 75 } },
    },

    -- labyrinth_of_onzozo (zone 213)
    ['Labyrinth_of_Onzozo'] =
    {
        ['Babaulas']            = { lvl = { 83, 85 }, rsp = 330 },
        ['Boribaba']            = { lvl = { 83, 85 }, rsp = 330 },
        ['Cockatrice']          = { rsp = 960 },
        ['Flying_Manta']        = { lvl = { 56, 59 }, rsp = 960 },
        ['Goblin_Alchemist']    = { lvl = { 69, 72 }, rsp = 960 },
        ['Goblin_Bandit']       = { lvl = { 69, 72 }, rsp = 960 },
        ['Goblin_Bouncer']      = { lvl = { 55, 58 }, rsp = 960 },
        ['Goblin_Enchanter']    = { lvl = { 55, 58 }, rsp = 960 },
        ['Goblin_Hunter']       = { lvl = { 55, 58 }, rsp = 960 },
        ['Goblin_Mercenary']    = { lvl = { 69, 72 }, rsp = 960 },
        ['Goblin_Miner']        = { lvl = { 55, 58 }, rsp = 960 },
        ['Goblin_Poacher']      = { lvl = { 49, 52 }, rsp = 960 },
        ['Goblin_Reaper']       = { lvl = { 49, 52 }, rsp = 960 },
        ['Goblin_Robber']       = { lvl = { 49, 52 }, rsp = 960 },
        ['Goblin_Shepherd']     = { lvl = { 69, 72 }, rsp = 960 },
        ['Goblin_Trader']       = { lvl = { 49, 52 }, rsp = 960 },
        ['Labyrinth_Leech']     = { lvl = { 48, 51 }, rsp = 840 },
        ['Labyrinth_Manticore'] = { rsp = 960 },
        ['Lord_of_Onzozo']      = { lvl = { 77, 79 } },
        ['Mushussu']            = { lvl = { 53, 56 }, rsp = 960 },
        ['Peg_Powler']          = { lvl = { 61, 63 } },
        ['Tainted_Flesh']       = { rsp = 960 },
        ['Torama']              = { rsp = 960 },
        ['Ubume']               = { lvl = { 63, 65 } },
        ['Wyvern']              = { rsp = 960 },
    },
}

-- Applied once per zone, after every mob in it has been created and initialised.
local function applyZoneMobOverrides(zone, entries)
    for _, mob in ipairs(zone:getMobs()) do
        local entry = entries[mob:getName()]

        if entry then
            if entry.lvl then
                local minLevel = entry.lvl[1]
                local maxLevel = entry.lvl[2]

                mob:addListener('SPAWN', 'ZXI_MOB_LEVEL_RANGE', function(spawnedMob)
                    spawnedMob:setMobLevel(math.randomInt(minLevel, maxLevel))
                end)

                -- Zone.onInitialize runs after the zone's first spawn pass, so the
                -- listener has already missed this life.
                if mob:isSpawned() then
                    mob:setMobLevel(math.randomInt(minLevel, maxLevel))
                end
            end

            if entry.rsp and mob:isSpawned() then
                mob:setRespawnTime(entry.rsp)
            end
        end
    end
end

for zoneName, entries in pairs(mobOverrides) do
    m:addOverride(string.format('xi.zones.%s.Zone.onInitialize', zoneName), function(zone)
        super(zone)

        applyZoneMobOverrides(zone, entries)
    end)
end
