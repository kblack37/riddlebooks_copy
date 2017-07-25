package wordproblem.engine.barmodel;


/**
 * This class manages the creation of text styling information based on the
 * background id that is bound to a level.
 */
class BarModelBackgroundToStyle
{
    private var m_backgroundIdToStyleInfo : Dynamic;
    
    public function new()
    {
        var fantasyStyle : Dynamic = {
            color : "0x3D1E07",
            fontName : "Immortal",
            fontSize : 24,

        };
        var scifiStyle : Dynamic = {
            color : "0xCEFBFE",
            fontName : "Calibri",
            fontSize : 24,

        };
        var mysteryStyle : Dynamic = {
            color : "0x0B0B0A",
            fontName : "Monofonto",
            fontSize : 28,

        };
        var regularStyle : Dynamic = {
            color : "0x0000000",
            fontName : "Calibri",
            fontSize : 24,

        };
        
        // http://www.color-hex.com/color-palette/700
        var metroColors : Dynamic = {
            a : 0xd11141,
            b : 0x00b159,
            c : 0x00aedb,
            d : 0xf37735,
        };
        
        // http://www.color-hex.com/color-palette/7098
        var twilightColors : Dynamic = {
            a : 0xef4f91,
            b : 0xc79dd7,
            c : 0x7bb3ff,
            d : 0xe86af0,
        };
        
        var style_id_to_package : Dynamic = {
            fantasy_a : {
                path : "book_fantasy_v1",
                styles : fantasyStyle,
                highlightColors : metroColors,

            },
            fantasy_b : {
                path : "book_fantasy_v2",
                styles : fantasyStyle,
                highlightColors : metroColors,

            },
            fantasy_c : {
                path : "book_fantasy_v3",
                styles : fantasyStyle,
                highlightColors : metroColors,

            },
            fantasy_d : {
                path : "book_castle_sky",
                styles : fantasyStyle,
                highlightColors : metroColors,

            },
            scifi_a : {
                path : "book_scifi_v1",
                styles : scifiStyle,
                highlightColors : twilightColors,

            },
            scifi_b : {
                path : "book_scifi_v2",
                styles : scifiStyle,
                highlightColors : twilightColors,

            },
            scifi_c : {
                path : "book_scifi_v3",
                styles : scifiStyle,
                highlightColors : twilightColors,

            },
            scifi_d : {
                path : "book_space_moon",
                styles : scifiStyle,
                highlightColors : twilightColors,

            },
            mystery_a : {
                path : "book_detective_v1",
                styles : mysteryStyle,
                highlightColors : metroColors,

            },
            mystery_b : {
                path : "book_detective_v2",
                styles : mysteryStyle,
                highlightColors : metroColors,

            },
            mystery_c : {
                path : "book_detective_v3",
                styles : mysteryStyle,
                highlightColors : metroColors,

            },
            general_a : {
                path : "book_mystery_faded",
                styles : regularStyle,
                highlightColors : metroColors,

            },
            wilderness_a : {
                path : "book_mountain_meadow",
                styles : regularStyle,
                highlightColors : metroColors,

            },
            wilderness_b : {
                path : "book_dead_forest",
                styles : regularStyle,
                highlightColors : metroColors,

            },
            wilderness_c : {
                path : "book_crystal_cave",
                styles : regularStyle,
                highlightColors : metroColors,

            },
            general_b : {
                path : "book_vampire_high",
                styles : regularStyle,
                highlightColors : metroColors,

            },
            general_c : {
                path : "detective_book",
                styles : regularStyle,
                highlightColors : metroColors,

            },
            general_d : {
                path : "book_pastel",
                styles : regularStyle,
                highlightColors : metroColors,

            },

        };
        
        m_backgroundIdToStyleInfo = style_id_to_package;
    }
    
    public function getAllBackgroundIds() : Array<String>
    {
        var backgroundIds : Array<String> = new Array<String>();
        for (backgroundId in Reflect.fields(m_backgroundIdToStyleInfo))
        {
            backgroundIds.push(backgroundId);
        }
        
        return backgroundIds;
    }
    
    public function getBackgroundNameFromId(backgroundId : String) : String
    {
        var backgroundName : String = null;
        if (m_backgroundIdToStyleInfo.exists(backgroundId)) 
        {
            backgroundName = Reflect.field(m_backgroundIdToStyleInfo, backgroundId).path;
        }
        return backgroundName;
    }
    
    public function getTextStyleFromId(backgroundId : String) : Dynamic
    {
        var backgroundStyle : Dynamic = null;
        if (m_backgroundIdToStyleInfo.exists(backgroundId)) 
        {
            backgroundStyle = Reflect.field(m_backgroundIdToStyleInfo, backgroundId).styles;
        }
        
        return backgroundStyle;
    }
    
    public function getHighlightColorsFromId(backgroundId : String) : Dynamic
    {
        var highlightColors : Dynamic = null;
        if (m_backgroundIdToStyleInfo.exists(backgroundId)) 
        {
            highlightColors = Reflect.field(m_backgroundIdToStyleInfo, backgroundId).highlightColors;
        }
        
        return highlightColors;
    }
}
