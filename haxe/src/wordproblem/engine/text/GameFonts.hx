package wordproblem.engine.text;


import flash.text.Font;
import flash.text.FontType;

class GameFonts
{
    // ??? Static initialization ordering problem may occur as fonts are not registered before this call is made
    // List of all registered fonts
    private static var FONTS : Array<Dynamic> = Font.enumerateFonts();
    
    public static var DEFAULT_FONT_NAME : String = "Bookworm";
    public static var DEFAULT_INPUT_FONT_NAME : String = "Bookworm";
    public static var SCORE_FONT_NAME : String = "Bookworm";
    
    /**
     * Get whether the given font name is embedded
     * 
     * @param fontName
     *      Name of the font to check
     * @return
     *      True if the font is embedded, flash text fields need to be set to use embedded fonts
     */
    public static function getFontIsEmbedded(fontName : String) : Bool
    {
        var isEmbedded : Bool = false;
        if (fontName != null) 
        {
            var i : Int;
            var font : Font;
            for (i in 0...FONTS.length){
                font = FONTS[i];
                if (font.fontType == FontType.EMBEDDED && fontName == font.fontName) 
                {
                    isEmbedded = true;
                    break;
                }
            }
        }
        
        return isEmbedded;
    }

    public function new()
    {
    }
}
