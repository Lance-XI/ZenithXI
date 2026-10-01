-- -----------------------------------
-- Maps Tables Module
--
-- This module adjusts the maps table for vendors and maps to adjust costs/availability.
-- -----------------------------------

require('modules/module_utils')

local m = Module:new('e-x_maps')
m:addOverride('xi.dummyFunc', function()
end)

-- Map vendors by region
xi.maps.mapVendors = {
    ['Ashu_Bolkhomo']   = 1006,
    ['Elesca']          = 567,
    ['Karine']          = 210,
    ['Lombaria']        = 500,
    ['Ludwig']          = 500,
    ['Mhoji_Roccoruh']  = 10000,
    ['Pehki_Machumaht'] = 10000,
    ['Promurouve']      = 10000,
    ['Rex']             = 115,
    ['Riyadahf']        = 563,
    ['Rusese']          = 10000,
    ['Violitte']        = 595,
}

-- Maps information by area, cost and region(s) sold
xi.maps.mapInfo = {
    [0] = {
        xi.keyItem.MAP_OF_THE_SAN_DORIA_AREA,
        200,
        {
            xi.region.SANDORIA,
            xi.region.BASTOK,
            xi.region.WINDURST,
            xi.region.KOLSHUSHU,
            xi.region.ZULKHEIM,
        },
    },
    [1] = {
        xi.keyItem.MAP_OF_THE_BASTOK_AREA,
        200,
        {
            xi.region.SANDORIA,
            xi.region.BASTOK,
            xi.region.WINDURST,
            xi.region.KOLSHUSHU,
            xi.region.ZULKHEIM,
        },
    },
    [2] = {
        xi.keyItem.MAP_OF_THE_WINDURST_AREA,
        200,
        {
            xi.region.SANDORIA,
            xi.region.BASTOK,
            xi.region.WINDURST,
            xi.region.KOLSHUSHU,
            xi.region.ZULKHEIM,
        },
    },
    [3] = {
        xi.keyItem.MAP_OF_THE_JEUNO_AREA,
        600,
        {
            xi.region.SANDORIA,
            xi.region.BASTOK,
            xi.region.WINDURST,
            xi.region.KOLSHUSHU,
            xi.region.ZULKHEIM,
            xi.region.JEUNO,
        },
    },
    [4] = {
        xi.keyItem.MAP_OF_ORDELLES_CAVES,
        600,
        {
            xi.region.SANDORIA,
        },
    },
    [5] = {
        xi.keyItem.MAP_OF_GHELSBA,
        600,
        {
            xi.region.SANDORIA,
        },
    },
    [6] = {
        xi.keyItem.MAP_OF_DAVOI,
        3000,
        {
            xi.region.SANDORIA,
        },
    },
    -- Chains of Promathia
    [7] = {
        xi.keyItem.MAP_OF_CARPENTERS_LANDING,
        xi.settings.main.ENABLE_COP == 1 and 3000 or -1,
        {
            xi.region.SANDORIA,
        },
    },
    [8] = {
        xi.keyItem.MAP_OF_THE_ZERUHN_MINES,
        200,
        {
            xi.region.BASTOK,
        },
    },
    [9] = {
        xi.keyItem.MAP_OF_THE_PALBOROUGH_MINES,
        600,
        {
            xi.region.BASTOK,
        },
    },
    [10] = {
        xi.keyItem.MAP_OF_BEADEAUX,
        600,
        {
            xi.region.BASTOK,
        },
    },
    [11] = {
        xi.keyItem.MAP_OF_GIDDEUS,
        600,
        {
            xi.region.WINDURST,
        },
    },
    [12] = {
        xi.keyItem.MAP_OF_CASTLE_OZTROJA,
        3000,
        {
            xi.region.WINDURST,
        },
    },
    [13] = {
        xi.keyItem.MAP_OF_THE_MAZE_OF_SHAKHRAMI,
        600,
        {
            xi.region.WINDURST,
        },
    },
    -- Rise of the Zilart
    [14] = {
        xi.keyItem.MAP_OF_THE_LITELOR_REGION,
        xi.settings.main.ENABLE_ROTZ == 1 and 3000 or -1,
        {
            xi.region.KOLSHUSHU,
        },
    },
    -- Chains of Promathia
    [15] = {
        xi.keyItem.MAP_OF_BIBIKI_BAY,
        xi.settings.main.ENABLE_COP == 1 and 3000 or -1,
        {
            xi.region.KOLSHUSHU,
        },
    },
    [16] = {
        xi.keyItem.MAP_OF_QUFIM_ISLAND,
        3000,
        {
            xi.region.JEUNO,
        },
    },
    [17] = {
        xi.keyItem.MAP_OF_THE_ELDIEME_NECROPOLIS,
        3000,
        {
            xi.region.JEUNO,
        },
    },
    [18] = {
        xi.keyItem.MAP_OF_THE_GARLAIGE_CITADEL,
        3000,
        {
            xi.region.JEUNO,
        },
    },
    -- Rise of the Zilart
    [19] = {
        xi.keyItem.MAP_OF_THE_ELSHIMO_REGIONS,
        xi.settings.main.ENABLE_ROTZ == 1 and 3000 or -1,
        {
            xi.region.JEUNO,
        },
    },
    [20] = {
        xi.keyItem.MAP_OF_THE_NORTHLANDS_AREA,
        -1,
    },
    [21] = {
        xi.keyItem.MAP_OF_KING_RANPERRES_TOMB,
        -1,
    },
    [22] = {
        xi.keyItem.MAP_OF_THE_DANGRUF_WADI,
        -1,
    },
    [23] = {
        xi.keyItem.MAP_OF_THE_HORUTOTO_RUINS,
        -1,
    },
    [24] = {
        xi.keyItem.MAP_OF_BOSTAUNIEUX_OUBLIETTE,
        -1,
    },
    [25] = {
        xi.keyItem.MAP_OF_THE_TORAIMARAI_CANAL,
        -1,
    },
    [26] = {
        xi.keyItem.MAP_OF_THE_GUSGEN_MINES,
        -1,
    },
    [27] = {
        xi.keyItem.MAP_OF_THE_CRAWLERS_NEST,
        -1,
    },
    [28] = {
        xi.keyItem.MAP_OF_THE_RANGUEMONT_PASS,
        -1,
    },
    [29] = {
        xi.keyItem.MAP_OF_DELKFUTTS_TOWER,
        -1,
    },
    [30] = {
        xi.keyItem.MAP_OF_FEIYIN,
        -1,
    },
    [31] = {
        xi.keyItem.MAP_OF_CASTLE_ZVAHL,
        -1,
    },
    -- Rise of the Zilart
    [32] = {
        xi.keyItem.MAP_OF_THE_KUZOTZ_REGION,
        xi.settings.main.ENABLE_ROTZ == 1 and 3000 or -1,
        {
            xi.region.KUZOTZ,
        },
    },
    [33] = {
        xi.keyItem.MAP_OF_THE_RUAUN_GARDENS,
        -1,
    },
    [34] = {
        xi.keyItem.MAP_OF_NORG,
        -1,
    },
    [35] = {
        xi.keyItem.MAP_OF_TEMPLE_OF_UGGALEPIH,
        -1,
    },
    [36] = {
        xi.keyItem.MAP_OF_THE_DEN_OF_RANCOR,
        -1,
    },
    -- Rise of the Zilart
    [37] = {
        xi.keyItem.MAP_OF_THE_KORROLOKA_TUNNEL,
        xi.settings.main.ENABLE_ROTZ == 1 and 3000 or -1,
        {
            xi.region.KUZOTZ,
        },
    },
    [38] = {
        xi.keyItem.MAP_OF_THE_KUFTAL_TUNNEL,
        -1,
    },
    [39] = {
        xi.keyItem.MAP_OF_THE_BOYAHDA_TREE,
        -1,
    },
    [40] = {
        xi.keyItem.MAP_OF_VELUGANNON_PALACE,
        -1,
    },
    [41] = {
        xi.keyItem.MAP_OF_IFRITS_CAULDRON,
        -1,
    },
    [42] = {
        xi.keyItem.MAP_OF_THE_QUICKSAND_CAVES,
        -1,
    },
    [43] = {
        xi.keyItem.MAP_OF_SEA_SERPENT_GROTTO,
        -1,
    },
    -- Rise of the Zilart
    [44] = {
        xi.keyItem.MAP_OF_THE_VOLLBOW_REGION,
        xi.settings.main.ENABLE_ROTZ == 1 and 3000 or -1,
        {
            xi.region.KUZOTZ,
        },
    },
    [45] = {
        xi.keyItem.MAP_OF_LABYRINTH_OF_ONZOZO,
        -1,
    },
    [46] = {
        xi.keyItem.MAP_OF_THE_ULEGUERAND_RANGE,
        -1,
    },
    [47] = {
        xi.keyItem.MAP_OF_THE_ATTOHWA_CHASM,
        -1,
    },
    [48] = {
        xi.keyItem.MAP_OF_PSOXJA,
        -1,
    },
    [49] = {
        xi.keyItem.MAP_OF_OLDTON_MOVALPOLOS,
        -1,
    },
    [50] = {
        xi.keyItem.MAP_OF_NEWTON_MOVALPOLOS,
        -1,
    },
    [51] = {
        xi.keyItem.MAP_OF_TAVNAZIA,
        -1,
    },
    [52] = {
        xi.keyItem.MAP_OF_THE_AQUEDUCTS,
        -1,
    },
    [53] = {
        xi.keyItem.MAP_OF_THE_SACRARIUM,
        -1,
    },
    [54] = {
        xi.keyItem.MAP_OF_CAPE_RIVERNE,
        -1,
    },
    [55] = {
        xi.keyItem.MAP_OF_ALTAIEU,
        -1,
    },
    [56] = {
        xi.keyItem.MAP_OF_HUXZOI,
        -1,
    },
    [57] = {
        xi.keyItem.MAP_OF_RUHMET,
        -1,
    },
    -- Treasures of Aht Urhgan
    [58] = {
        xi.keyItem.MAP_OF_AL_ZAHBI,
        xi.settings.main.ENABLE_TOAU == 1 and 600 or -1,
        {
            xi.region.WEST_AHT_URHGAN,
        },
    },
    -- Treasures of Aht Urhgan
    [59] = {
        xi.keyItem.MAP_OF_NASHMAU,
        xi.settings.main.ENABLE_TOAU == 1 and 3000 or -1,
        {
            xi.region.WEST_AHT_URHGAN,
        },
    },
    -- Treasures of Aht Urhgan
    [60] = {
        xi.keyItem.MAP_OF_WAJAOM_WOODLANDS,
        xi.settings.main.ENABLE_TOAU == 1 and 3000 or -1,
        {
            xi.region.WEST_AHT_URHGAN,
        },
    },
    [61] = {
        xi.keyItem.MAP_OF_CAEDARVA_MIRE,
        -1,
    },
    [62] = {
        xi.keyItem.MAP_OF_MOUNT_ZHAYOLM,
        -1,
    },
    [63] = {
        xi.keyItem.MAP_OF_AYDEEWA_SUBTERRANE,
        -1,
    },
    [64] = {
        xi.keyItem.MAP_OF_MAMOOK,
        -1,
    },
    [65] = {
        xi.keyItem.MAP_OF_HALVUNG,
        -1,
    },
    [66] = {
        xi.keyItem.MAP_OF_ARRAPAGO_REEF,
        -1,
    },
    [67] = {
        xi.keyItem.MAP_OF_ALZADAAL_RUINS,
        -1,
    },
    -- Treasures of Aht Urhgan
    [68] = {
        xi.keyItem.MAP_OF_BHAFLAU_THICKETS,
        xi.settings.main.ENABLE_TOAU == 1 and 3000 or -1,
        {
            xi.region.WEST_AHT_URHGAN,
        },
    },
    [69] = {
        xi.keyItem.MAP_OF_VUNKERL_INLET,
        -1,
    },
    [70] = {
        xi.keyItem.MAP_OF_GRAUBERG,
        -1,
    },
    [71] = {
        xi.keyItem.MAP_OF_FORT_KARUGO_NARUGO,
        -1,
    },
}

return m
