package wordproblem.achievements
{
    public class PlayerAchievementData
    {
        public static const GREEN:String = "Green";
        public static const BLUE:String = "Blue";
        public static const ORANGE:String = "Orange";
        
        private static var COLOR_DATA:Object;
        
        public static function getLightHexColorFromString(colorString:String):uint
        {
            if (COLOR_DATA == null)
            {
                createColorData();
            }
            return COLOR_DATA[colorString].light;
        }
        
        public static function getDarkHexColorFromString(colorString:String):uint
        {
            if (COLOR_DATA == null)
            {
                createColorData();
            }
            return COLOR_DATA[colorString].dark;
        }
        
        private static function createColorData():void
        {
            COLOR_DATA = {};
            COLOR_DATA[GREEN] = {light: 0xBAFFDA, dark: 0x006838};
            COLOR_DATA[BLUE] = {light: 0xC9EEFF, dark: 0x1B75BB};
            COLOR_DATA[ORANGE] = {light: 0xFAD8B9, dark: 0xBA322B}
        }
    }
}