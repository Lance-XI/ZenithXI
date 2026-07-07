-- -----------------------------------
-- Treasure Chest Loot Module
--
-- Overrides the per-zone drop tables for key-traded treasure chests/coffers
-- (scripts/globals/treasure.lua) via the xi.treasure.getItemTable accessor
-- added by 113-TreasureChestLootHook.patch.
--
-- lootOverrides below is a full copy of every zone/drop from the base
-- lootTable. Prune or edit entries to customize; any zone removed from this
-- table falls back to the base table via super().
--
-- Each entry is { itemId, weight }; weights are rolled against 1-1000, and
-- xi.item.NONE represents the gil reward.
-- -----------------------------------

require('modules/module_utils')

local m = Module:new('b_treasureChestLoot')

-- treasureType is a file-local enum in treasure.lua; redefine it here so the
-- copied [treasureType.CHEST] / [treasureType.COFFER] keys resolve.
local treasureType =
{
    CHEST  = 1,
    COFFER = 2,
}

local lootOverrides =
{
    [xi.zone.PSOXJA] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,       920 }, -- Gil
            { xi.item.AMETRINE,    10 },
            { xi.item.GARNET,      10 },
            { xi.item.GOSHENITE,   10 },
            { xi.item.LIGHT_OPAL,  10 },
            { xi.item.ONYX,        10 },
            { xi.item.PERIDOT,     10 },
            { xi.item.SPHENE,      10 },
            { xi.item.TURQUOISE,   10 },
        },
    },

    [xi.zone.OLDTON_MOVALPOLOS] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,       920 }, -- Gil
            { xi.item.AMETRINE,    10 },
            { xi.item.GARNET,      10 },
            { xi.item.GOSHENITE,   10 },
            { xi.item.LIGHT_OPAL,  10 },
            { xi.item.ONYX,        10 },
            { xi.item.PERIDOT,     10 },
            { xi.item.SPHENE,      10 },
            { xi.item.TURQUOISE,   10 },
        },
    },

    [xi.zone.NEWTON_MOVALPOLOS] =
    {
        [treasureType.COFFER] =
        {
            { xi.item.NONE,        920 }, -- Gil
            { xi.item.AQUAMARINE,   10 },
            { xi.item.CHRYSOBERYL,  10 },
            { xi.item.FLUORITE,     10 },
            { xi.item.JADEITE,      10 },
            { xi.item.MOONSTONE,    10 },
            { xi.item.PAINITE,      10 },
            { xi.item.SUNSTONE,     10 },
            { xi.item.ZIRCON,       10 },
        },
    },

    [xi.zone.SACRARIUM] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,       920 }, -- Gil
            { xi.item.AMETRINE,    10 },
            { xi.item.GARNET,      10 },
            { xi.item.GOSHENITE,   10 },
            { xi.item.LIGHT_OPAL,  10 },
            { xi.item.ONYX,        10 },
            { xi.item.PERIDOT,     10 },
            { xi.item.SPHENE,      10 },
            { xi.item.TURQUOISE,   10 },
        },
    },

    [xi.zone.RUAUN_GARDENS] =
    {
        [treasureType.COFFER] =
        {
            { xi.item.NONE,        920 }, -- Gil
            { xi.item.AQUAMARINE,   10 },
            { xi.item.CHRYSOBERYL,  10 },
            { xi.item.FLUORITE,     10 },
            { xi.item.JADEITE,      10 },
            { xi.item.MOONSTONE,    10 },
            { xi.item.PAINITE,      10 },
            { xi.item.SUNSTONE,     10 },
            { xi.item.ZIRCON,       10 },
        },
    },

    [xi.zone.FORT_GHELSBA] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,             720 }, -- Gil
            { xi.item.COUGAR_BAGHNAKHS, 200 }, -- Item
            { xi.item.AMBER_STONE,       10 },
            { xi.item.AMETHYST,          10 },
            { xi.item.CLEAR_TOPAZ,       10 },
            { xi.item.LAPIS_LAZULI,      10 },
            { xi.item.LIGHT_OPAL,        10 },
            { xi.item.ONYX,              10 },
            { xi.item.SARDONYX,          10 },
            { xi.item.TOURMALINE,        10 },
        },
    },

    [xi.zone.YUGHOTT_GROTTO] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,             720 }, -- Gil
            { xi.item.COUGAR_BAGHNAKHS, 200 }, -- Item
            { xi.item.AMBER_STONE,       10 },
            { xi.item.AMETHYST,          10 },
            { xi.item.CLEAR_TOPAZ,       10 },
            { xi.item.LAPIS_LAZULI,      10 },
            { xi.item.LIGHT_OPAL,        10 },
            { xi.item.ONYX,              10 },
            { xi.item.SARDONYX,          10 },
            { xi.item.TOURMALINE,        10 },
        },
    },

    [xi.zone.PALBOROUGH_MINES] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,            720 }, -- Gil
            { xi.item.FLAME_BOOMERANG, 200 }, -- Item
            { xi.item.AMBER_STONE,      10 },
            { xi.item.AMETHYST,         10 },
            { xi.item.CLEAR_TOPAZ,      10 },
            { xi.item.LAPIS_LAZULI,     10 },
            { xi.item.LIGHT_OPAL,       10 },
            { xi.item.ONYX,             10 },
            { xi.item.SARDONYX,         10 },
            { xi.item.TOURMALINE,       10 },
        },
    },

    [xi.zone.GIDDEUS] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,           720 }, -- Gil
            { xi.item.SHIELD_EARRING, 200 }, -- Item
            { xi.item.AMBER_STONE,     10 },
            { xi.item.AMETHYST,        10 },
            { xi.item.CLEAR_TOPAZ,     10 },
            { xi.item.LAPIS_LAZULI,    10 },
            { xi.item.LIGHT_OPAL,      10 },
            { xi.item.ONYX,            10 },
            { xi.item.SARDONYX,        10 },
            { xi.item.TOURMALINE,      10 },
        },
    },

    [xi.zone.BEADEAUX] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,        720 }, -- Gil
            { xi.item.ADEPTS_ROPE, 200 }, -- Item
            { xi.item.AMETRINE,     10 },
            { xi.item.GARNET,       10 },
            { xi.item.GOSHENITE,    10 },
            { xi.item.LIGHT_OPAL,   10 },
            { xi.item.ONYX,         10 },
            { xi.item.PERIDOT,      10 },
            { xi.item.SPHENE,       10 },
            { xi.item.TURQUOISE,    10 },
        },
        [treasureType.COFFER] =
        {
            { xi.item.NONE,            720 }, -- Gil
            { xi.item.SCROLL_OF_BURST, 200 }, -- Item
            { xi.item.AQUAMARINE,       10 },
            { xi.item.CHRYSOBERYL,      10 },
            { xi.item.FLUORITE,         10 },
            { xi.item.JADEITE,          10 },
            { xi.item.MOONSTONE,        10 },
            { xi.item.PAINITE,          10 },
            { xi.item.SUNSTONE,         10 },
            { xi.item.ZIRCON,           10 },
        },
    },

    [xi.zone.DAVOI] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,          720 }, -- Gil
            { xi.item.ELECTRUM_RING, 200 }, -- Item
            { xi.item.AMETRINE,       10 },
            { xi.item.GARNET,         10 },
            { xi.item.GOSHENITE,      10 },
            { xi.item.LIGHT_OPAL,     10 },
            { xi.item.ONYX,           10 },
            { xi.item.PERIDOT,        10 },
            { xi.item.SPHENE,         10 },
            { xi.item.TURQUOISE,      10 },
        },
    },

    [xi.zone.MONASTIC_CAVERN] =
    {
        [treasureType.COFFER] =
        {
            { xi.item.NONE,             720 }, -- Gil
            { xi.item.PHYSICAL_EARRING, 200 }, -- Item
            { xi.item.AQUAMARINE,        10 },
            { xi.item.CHRYSOBERYL,       10 },
            { xi.item.FLUORITE,          10 },
            { xi.item.JADEITE,           10 },
            { xi.item.MOONSTONE,         10 },
            { xi.item.PAINITE,           10 },
            { xi.item.SUNSTONE,          10 },
            { xi.item.ZIRCON,            10 },
        },
    },

    [xi.zone.CASTLE_OZTROJA] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,             720 }, -- Gil
            { xi.item.ELECTRUM_HAIRPIN, 200 }, -- Item
            { xi.item.AMETRINE,          10 },
            { xi.item.GARNET,            10 },
            { xi.item.GOSHENITE,         10 },
            { xi.item.LIGHT_OPAL,        10 },
            { xi.item.PERIDOT,           10 },
            { xi.item.SARDONYX,          10 },
            { xi.item.SPHENE,            10 },
            { xi.item.TURQUOISE,         10 },
        },
        [treasureType.COFFER] =
        {
            { xi.item.NONE,           720 }, -- Gil
            { xi.item.SAFEGUARD_RING, 200 }, -- Item
            { xi.item.AQUAMARINE,      10 },
            { xi.item.CHRYSOBERYL,     10 },
            { xi.item.FLUORITE,        10 },
            { xi.item.JADEITE,         10 },
            { xi.item.MOONSTONE,       10 },
            { xi.item.PAINITE,         10 },
            { xi.item.SUNSTONE,        10 },
            { xi.item.ZIRCON,          10 },
        },
    },

    [xi.zone.THE_BOYAHDA_TREE] =
    {
        [treasureType.COFFER] =
        {
            { xi.item.NONE,          720 }, -- Gil
            { xi.item.SCREAM_FUNGUS, 200 }, -- Item
            { xi.item.AQUAMARINE,     10 },
            { xi.item.CHRYSOBERYL,    10 },
            { xi.item.FLUORITE,       10 },
            { xi.item.JADEITE,        10 },
            { xi.item.MOONSTONE,      10 },
            { xi.item.PAINITE,        10 },
            { xi.item.SUNSTONE,       10 },
            { xi.item.ZIRCON,         10 },
        },
    },

    [xi.zone.MIDDLE_DELKFUTTS_TOWER] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,         720 }, -- Gil
            { xi.item.EMETH_PICK,   200 }, -- Item
            { xi.item.AMBER_STONE,   10 },
            { xi.item.AMETHYST,      10 },
            { xi.item.CLEAR_TOPAZ,   10 },
            { xi.item.LAPIS_LAZULI,  10 },
            { xi.item.LIGHT_OPAL,    10 },
            { xi.item.ONYX,          10 },
            { xi.item.SARDONYX,      10 },
            { xi.item.TOURMALINE,    10 },
        },
    },

    [xi.zone.UPPER_DELKFUTTS_TOWER] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,         720 }, -- Gil
            { xi.item.EMETH_PICK,   200 }, -- Item
            { xi.item.AMBER_STONE,   10 },
            { xi.item.AMETHYST,      10 },
            { xi.item.CLEAR_TOPAZ,   10 },
            { xi.item.LAPIS_LAZULI,  10 },
            { xi.item.LIGHT_OPAL,    10 },
            { xi.item.ONYX,          10 },
            { xi.item.SARDONYX,      10 },
            { xi.item.TOURMALINE,    10 },
        },
    },

    [xi.zone.TEMPLE_OF_UGGALEPIH] =
    {
        [treasureType.COFFER] =
        {
            { xi.item.NONE,        920 }, -- Gil
            { xi.item.AQUAMARINE,   10 },
            { xi.item.CHRYSOBERYL,  10 },
            { xi.item.FLUORITE,     10 },
            { xi.item.JADEITE,      10 },
            { xi.item.MOONSTONE,    10 },
            { xi.item.PAINITE,      10 },
            { xi.item.SUNSTONE,     10 },
            { xi.item.ZIRCON,       10 },
        },
    },

    [xi.zone.DEN_OF_RANCOR] =
    {
        [treasureType.COFFER] =
        {
            { xi.item.NONE,        960 }, -- Gil
            { xi.item.AQUAMARINE,   10 },
            { xi.item.CHRYSOBERYL,  10 },
            { xi.item.FLUORITE,     10 },
            { xi.item.JADEITE,      10 },
            { xi.item.MOONSTONE,    10 },
            { xi.item.PAINITE,      10 },
            { xi.item.SUNSTONE,     10 },
            { xi.item.ZIRCON,       10 },
        },
    },

    [xi.zone.CASTLE_ZVAHL_BAILEYS] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,         720 }, -- Gil
            { xi.item.PHALANX_RING, 200 }, -- Item
            { xi.item.AMETRINE,      10 },
            { xi.item.GARNET,        10 },
            { xi.item.GOSHENITE,     10 },
            { xi.item.LIGHT_OPAL,    10 },
            { xi.item.PERIDOT,       10 },
            { xi.item.SARDONYX,      10 },
            { xi.item.SPHENE,        10 },
            { xi.item.TURQUOISE,     10 },
        },
        [treasureType.COFFER] =
        {
            { xi.item.NONE,                      720 }, -- Gil
            { xi.item.SCROLL_OF_MAGES_BALLAD_II, 200 }, -- Item
            { xi.item.AQUAMARINE,                 10 },
            { xi.item.CHRYSOBERYL,                10 },
            { xi.item.FLUORITE,                   10 },
            { xi.item.JADEITE,                    10 },
            { xi.item.MOONSTONE,                  10 },
            { xi.item.PAINITE,                    10 },
            { xi.item.SUNSTONE,                   10 },
            { xi.item.ZIRCON,                     10 },
        },
    },

    [xi.zone.CASTLE_ZVAHL_KEEP] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,         720 }, -- Gil
            { xi.item.PHALANX_RING, 200 }, -- Item
            { xi.item.AMETRINE,      10 },
            { xi.item.GARNET,        10 },
            { xi.item.GOSHENITE,     10 },
            { xi.item.LIGHT_OPAL,    10 },
            { xi.item.PERIDOT,       10 },
            { xi.item.SARDONYX,      10 },
            { xi.item.SPHENE,        10 },
            { xi.item.TURQUOISE,     10 },
        },
    },

    [xi.zone.TORAIMARAI_CANAL] =
    {
        [treasureType.COFFER] =
        {
            { xi.item.NONE,        920 }, -- Gil
            { xi.item.AQUAMARINE,   10 },
            { xi.item.CHRYSOBERYL,  10 },
            { xi.item.FLUORITE,     10 },
            { xi.item.JADEITE,      10 },
            { xi.item.MOONSTONE,    10 },
            { xi.item.PAINITE,      10 },
            { xi.item.SUNSTONE,     10 },
            { xi.item.ZIRCON,       10 },
        },
    },

    [xi.zone.KUFTAL_TUNNEL] =
    {
        [treasureType.COFFER] =
        {
            { xi.item.NONE,        920 }, -- Gil
            { xi.item.AQUAMARINE,   10 },
            { xi.item.CHRYSOBERYL,  10 },
            { xi.item.FLUORITE,     10 },
            { xi.item.JADEITE,      10 },
            { xi.item.MOONSTONE,    10 },
            { xi.item.PAINITE,      10 },
            { xi.item.SUNSTONE,     10 },
            { xi.item.ZIRCON,       10 },
        },
    },

    [xi.zone.SEA_SERPENT_GROTTO] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,       920 }, -- Gil
            { xi.item.AMETRINE,    10 },
            { xi.item.GARNET,      10 },
            { xi.item.GOSHENITE,   10 },
            { xi.item.LIGHT_OPAL,  10 },
            { xi.item.ONYX,        10 },
            { xi.item.PERIDOT,     10 },
            { xi.item.SPHENE,      10 },
            { xi.item.TURQUOISE,   10 },
        },
        [treasureType.COFFER] =
        {
            { xi.item.NONE,        920 }, -- Gil
            { xi.item.AQUAMARINE,   10 },
            { xi.item.CHRYSOBERYL,  10 },
            { xi.item.FLUORITE,     10 },
            { xi.item.JADEITE,      10 },
            { xi.item.MOONSTONE,    10 },
            { xi.item.PAINITE,      10 },
            { xi.item.SUNSTONE,     10 },
            { xi.item.ZIRCON,       10 },
        },
    },

    [xi.zone.VELUGANNON_PALACE] =
    {
        [treasureType.COFFER] =
        {
            { xi.item.NONE,        920 }, -- Gil
            { xi.item.AQUAMARINE,   10 },
            { xi.item.CHRYSOBERYL,  10 },
            { xi.item.FLUORITE,     10 },
            { xi.item.JADEITE,      10 },
            { xi.item.MOONSTONE,    10 },
            { xi.item.PAINITE,      10 },
            { xi.item.SUNSTONE,     10 },
            { xi.item.ZIRCON,       10 },
        },
    },

    [xi.zone.KING_RANPERRES_TOMB] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,          720 }, -- Gil
            { xi.item.BATTLE_GLOVES, 200 }, -- Item
            { xi.item.AMBER_STONE,    10 },
            { xi.item.AMETHYST,       10 },
            { xi.item.CLEAR_TOPAZ,    10 },
            { xi.item.LAPIS_LAZULI,   10 },
            { xi.item.LIGHT_OPAL,     10 },
            { xi.item.ONYX,           10 },
            { xi.item.SARDONYX,       10 },
            { xi.item.TOURMALINE,     10 },
        },
    },

    [xi.zone.DANGRUF_WADI] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,            720 }, -- Gil
            { xi.item.TROPICAL_SHIELD, 200 }, -- Item
            { xi.item.AMBER_STONE,      10 },
            { xi.item.AMETHYST,         10 },
            { xi.item.CLEAR_TOPAZ,      10 },
            { xi.item.LAPIS_LAZULI,     10 },
            { xi.item.LIGHT_OPAL,       10 },
            { xi.item.ONYX,             10 },
            { xi.item.SARDONYX,         10 },
            { xi.item.TOURMALINE,       10 },
        },
    },

    [xi.zone.INNER_HORUTOTO_RUINS] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,         720 }, -- Gil
            { xi.item.MOTH_AXE,     200 }, -- Item
            { xi.item.AMBER_STONE,   10 },
            { xi.item.AMETHYST,      10 },
            { xi.item.CLEAR_TOPAZ,   10 },
            { xi.item.LAPIS_LAZULI,  10 },
            { xi.item.LIGHT_OPAL,    10 },
            { xi.item.ONYX,          10 },
            { xi.item.SARDONYX,      10 },
            { xi.item.TOURMALINE,    10 },
        },
    },

    [xi.zone.ORDELLES_CAVES] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,         720 }, -- Gil
            { xi.item.FORCE_BELT,   200 }, -- Item
            { xi.item.AMBER_STONE,   10 },
            { xi.item.AMETHYST,      10 },
            { xi.item.CLEAR_TOPAZ,   10 },
            { xi.item.LAPIS_LAZULI,  10 },
            { xi.item.LIGHT_OPAL,    10 },
            { xi.item.ONYX,          10 },
            { xi.item.SARDONYX,      10 },
            { xi.item.TOURMALINE,    10 },
        },
    },

    [xi.zone.OUTER_HORUTOTO_RUINS] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,         720 }, -- Gil
            { xi.item.MOTH_AXE,     200 }, -- Item
            { xi.item.AMBER_STONE,   10 },
            { xi.item.AMETHYST,      10 },
            { xi.item.CLEAR_TOPAZ,   10 },
            { xi.item.LAPIS_LAZULI,  10 },
            { xi.item.LIGHT_OPAL,    10 },
            { xi.item.ONYX,          10 },
            { xi.item.SARDONYX,      10 },
            { xi.item.TOURMALINE,    10 },
        },
    },

    [xi.zone.THE_ELDIEME_NECROPOLIS] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,       720 }, -- Gil
            { xi.item.FALCASTRA,  200 }, -- Item
            { xi.item.AMETRINE,    10 },
            { xi.item.GARNET,      10 },
            { xi.item.GOSHENITE,   10 },
            { xi.item.LIGHT_OPAL,  10 },
            { xi.item.PERIDOT,     10 },
            { xi.item.SARDONYX,    10 },
            { xi.item.SPHENE,      10 },
            { xi.item.TURQUOISE,   10 },
        },
        [treasureType.COFFER] =
        {
            { xi.item.NONE,           720 }, -- Gil
            { xi.item.VILE_ELIXIR_P1, 200 }, -- Item
            { xi.item.AQUAMARINE,      10 },
            { xi.item.CHRYSOBERYL,     10 },
            { xi.item.FLUORITE,        10 },
            { xi.item.JADEITE,         10 },
            { xi.item.MOONSTONE,       10 },
            { xi.item.PAINITE,         10 },
            { xi.item.SUNSTONE,        10 },
            { xi.item.ZIRCON,          10 },
        },
    },

    [xi.zone.GUSGEN_MINES] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,         720 }, -- Gil
            { xi.item.REPLICA_MAUL, 200 }, -- Item
            { xi.item.AMBER_STONE,   10 },
            { xi.item.AMETHYST,      10 },
            { xi.item.CLEAR_TOPAZ,   10 },
            { xi.item.LAPIS_LAZULI,  10 },
            { xi.item.LIGHT_OPAL,    10 },
            { xi.item.ONYX,          10 },
            { xi.item.SARDONYX,      10 },
            { xi.item.TOURMALINE,    10 },
        },
    },

    [xi.zone.CRAWLERS_NEST] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,       720 }, -- Gil
            { xi.item.GIGANT_AXE, 200 }, -- Item
            { xi.item.AMETRINE,    10 },
            { xi.item.GARNET,      10 },
            { xi.item.GOSHENITE,   10 },
            { xi.item.LIGHT_OPAL,  10 },
            { xi.item.ONYX,        10 },
            { xi.item.PERIDOT,     10 },
            { xi.item.SPHENE,      10 },
            { xi.item.TURQUOISE,   10 },
        },
        [treasureType.COFFER] =
        {
            { xi.item.NONE,        720 }, -- Gil
            { xi.item.HI_RERAISER, 200 }, -- Item
            { xi.item.AQUAMARINE,   10 },
            { xi.item.CHRYSOBERYL,  10 },
            { xi.item.FLUORITE,     10 },
            { xi.item.JADEITE,      10 },
            { xi.item.MOONSTONE,    10 },
            { xi.item.PAINITE,      10 },
            { xi.item.SUNSTONE,     10 },
            { xi.item.ZIRCON,       10 },
        },
    },

    [xi.zone.MAZE_OF_SHAKHRAMI] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,         720 }, -- Gil
            { xi.item.HEAT_ROD,     200 }, -- Item
            { xi.item.AMBER_STONE,   10 },
            { xi.item.AMETHYST,      10 },
            { xi.item.CLEAR_TOPAZ,   10 },
            { xi.item.LAPIS_LAZULI,  10 },
            { xi.item.LIGHT_OPAL,    10 },
            { xi.item.ONYX,          10 },
            { xi.item.SARDONYX,      10 },
            { xi.item.TOURMALINE,    10 },
        },
    },

    [xi.zone.GARLAIGE_CITADEL] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,       720 }, -- Gil
            { xi.item.PYRO_ROBE,  200 }, -- Item
            { xi.item.AMETRINE,    10 },
            { xi.item.GARNET,      10 },
            { xi.item.GOSHENITE,   10 },
            { xi.item.LIGHT_OPAL,  10 },
            { xi.item.ONYX,        10 },
            { xi.item.PERIDOT,     10 },
            { xi.item.SPHENE,      10 },
            { xi.item.TURQUOISE,   10 },
        },
        [treasureType.COFFER] =
        {
            { xi.item.NONE,            720 }, -- Gil
            { xi.item.LIGHT_GAUNTLETS, 220 }, -- Item
            { xi.item.AQUAMARINE,       10 },
            { xi.item.CHRYSOBERYL,      10 },
            { xi.item.FLUORITE,         10 },
            { xi.item.JADEITE,          10 },
            { xi.item.MOONSTONE,        10 },
            { xi.item.PAINITE,          10 },
            { xi.item.SUNSTONE,         10 },
            { xi.item.ZIRCON,           10 },
        },
    },

    [xi.zone.FEIYIN] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,       720 }, -- Gil
            { xi.item.LIFE_BELT,  200 }, -- Item
            { xi.item.AMETRINE,    10 },
            { xi.item.GARNET,      10 },
            { xi.item.GOSHENITE,   10 },
            { xi.item.LIGHT_OPAL,  10 },
            { xi.item.ONYX,        10 },
            { xi.item.PERIDOT,     10 },
            { xi.item.SPHENE,      10 },
            { xi.item.TURQUOISE,   10 },
        },
    },

    [xi.zone.IFRITS_CAULDRON] =
    {
        [treasureType.COFFER] =
        {
            { xi.item.NONE,        920 }, -- Gil
            { xi.item.AQUAMARINE,   10 },
            { xi.item.CHRYSOBERYL,  10 },
            { xi.item.FLUORITE,     10 },
            { xi.item.JADEITE,      10 },
            { xi.item.MOONSTONE,    10 },
            { xi.item.PAINITE,      10 },
            { xi.item.SUNSTONE,     10 },
            { xi.item.ZIRCON,       10 },
        },
    },

    [xi.zone.QUICKSAND_CAVES] =
    {
        [treasureType.COFFER] =
        {
            { xi.item.NONE,        920 }, -- Gil
            { xi.item.AQUAMARINE,   10 },
            { xi.item.CHRYSOBERYL,  10 },
            { xi.item.FLUORITE,     10 },
            { xi.item.JADEITE,      10 },
            { xi.item.MOONSTONE,    10 },
            { xi.item.PAINITE,      10 },
            { xi.item.SUNSTONE,     10 },
            { xi.item.ZIRCON,       10 },
        },
    },

    [xi.zone.LABYRINTH_OF_ONZOZO] =
    {
        [treasureType.CHEST] =
        {
            { xi.item.NONE,       920 }, -- Gil
            { xi.item.AMETRINE,    10 },
            { xi.item.GARNET,      10 },
            { xi.item.GOSHENITE,   10 },
            { xi.item.LIGHT_OPAL,  10 },
            { xi.item.ONYX,        10 },
            { xi.item.PERIDOT,     10 },
            { xi.item.SPHENE,      10 },
            { xi.item.TURQUOISE,   10 },
        },
    },
}

-- Return the module's table for a zone/type when present; otherwise fall back
-- to the base (patched) table so unlisted zones are unaffected.
m:addOverride('xi.treasure.getItemTable', function(zoneId, containerType)
    local zoneOverride = lootOverrides[zoneId]
    if zoneOverride and zoneOverride[containerType] then
        return zoneOverride[containerType]
    end

    return super(zoneId, containerType)
end)

return m
