package wordproblem.achievements;


class PlayerAchievementData
{
    public static inline var GREEN : String = "Green";
    public static inline var BLUE : String = "Blue";
    public static inline var ORANGE : String = "Orange";
    
    private static var COLOR_DATA : Dynamic;
    
    public static function getLightHexColorFromString(colorString : String) : Int
    {
        if (COLOR_DATA == null) 
        {
            createColorData();
        }
        return Reflect.field(COLOR_DATA, colorString).light;
    }
    
    public static function getDarkHexColorFromString(colorString : String) : Int
    {
        if (COLOR_DATA == null) 
        {
            createColorData();
        }
        return Reflect.field(COLOR_DATA, colorString).dark;
    }
    
    private static function createColorData() : Void
    {
        COLOR_DATA = { };
        Reflect.setField(COLOR_DATA, GREEN, {
            light : 0xBAFFDA,
            dark : 0x006838,

        });
        Reflect.setField(COLOR_DATA, BLUE, {
            light : 0xC9EEFF,
            dark : 0x1B75BB,

        });
        Reflect.setField(COLOR_DATA, ORANGE, {
            light : 0xFAD8B9,
            dark : 0xBA322B,

        });
    }

    public function new()
    {
    }
}
