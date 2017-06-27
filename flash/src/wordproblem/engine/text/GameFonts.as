package wordproblem.engine.text
{
    import flash.text.Font;
    import flash.text.FontType;

	public class GameFonts
	{
        // ??? Static initialization ordering problem may occur as fonts are not registered before this call is made
        // List of all registered fonts
        private static var FONTS:Array = Font.enumerateFonts();
        
		public static var DEFAULT_FONT_NAME:String = "Bookworm";
        public static var DEFAULT_INPUT_FONT_NAME:String = "Bookworm";
        public static var SCORE_FONT_NAME:String = "Bookworm";
        
        /**
         * Get whether the given font name is embedded
         * 
         * @param fontName
         *      Name of the font to check
         * @return
         *      True if the font is embedded, flash text fields need to be set to use embedded fonts
         */
        public static function getFontIsEmbedded(fontName:String):Boolean
        {
            var isEmbedded:Boolean = false;
            if (fontName != null)
            {
                var i:int;
                var font:Font;
                for (i = 0; i < FONTS.length; i++)
                {
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
	}
}