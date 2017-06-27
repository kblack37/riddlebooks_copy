package dragonbox.common.util
{
    public class XColor
    {

        public static const ROYAL_BLUE:uint = 0x006CC1;
        public static const BRIGHT_ORANGE:uint = 0xFF9900;
        public static const DARK_GREEN:uint = 0x346900;
        
        // Color picking, cannot pick the same index twice in a session
        // The color batch needs to be reset at the start of each level.
        // Do not have red, feedback recieved it would indicate wrong
        private static var CANDIDATE_COLORS:Vector.<uint> = Vector.<uint>([
            0xFF6099F5, // Dark Blue
            0xFFBB89DD, // Purple
            0xFFF05CFD, // Magenta
            0xFFEDDB48, // Gold (Replaced Red)
            0xFFFDB402, // Orange
            0xFF19FD02, // Green
            0xFF02E2FD, // Sky Blue
            0xFFFFFFFF, // White
            0xFFFAFF96, // Light Yellow
            0xFFC4C4C4, // Gray
            0xFFB39566, // Light Brown
            0xFFFDD1FF, // Light Pink
            0xFFD1FFDC  // Light Green
            //0xFF99CC99, // Sea Green
            //0xFFFFAA99 // Peach
        ]);
        
        public static function getCandidateColorsForSession():Vector.<uint>
        {
            var colorCopy:Vector.<uint> = new Vector.<uint>();
            for each (var color:uint in CANDIDATE_COLORS)
            {
                colorCopy.push(color);
            }
            
            return colorCopy;
        }
        
        /**
         * This function is used to find a color between two other colors.
         * 
         * @param color1 The first color.
         * @param color2 The second color.
         * @param ratio The proportion of the first color to use. The rest of the color 
         * is made from the second color.
         * @return The color created.
         */
        public static function interpolateColors( color1:uint, color2:uint, ratio:Number ):uint
        {
            var inv:Number = 1 - ratio;
            var red:uint = Math.round( ( ( color1 >>> 16 ) & 255 ) * ratio + ( ( color2 >>> 16 ) & 255 ) * inv );
            var green:uint = Math.round( ( ( color1 >>> 8 ) & 255 ) * ratio + ( ( color2 >>> 8 ) & 255 ) * inv );
            var blue:uint = Math.round( ( ( color1 ) & 255 ) * ratio + ( ( color2 ) & 255 ) * inv );
            var alpha:uint = Math.round( ( ( color1 >>> 24 ) & 255 ) * ratio + ( ( color2 >>> 24 ) & 255 ) * inv );
            return ( alpha << 24 ) | ( red << 16 ) | ( green << 8 ) | blue;
        }
        
        /**
         * @param h
         *      hue between 0 and 1
         * @param s
         *      saturation between 0 and 1
         * @param v
         *      value between 0 and 1
         * @return
         *      An rgb representation of the given hsv value.
         */
        public static function hsvToRgb(h:Number, s:Number, v:Number):uint
        {
            var colorCase:int = Math.floor(h * 6);
            var f:Number = h * 6 - colorCase;
            var p:Number = v * (1 - s);
            var q:Number = v * (1 - f * s);
            var t:Number = v * (1 - (1 - f) * s);
            
            var red:Number = 0;
            var green:Number = 0;
            var blue:Number = 0;
            if (colorCase == 0)
            {
                red = v;
                green = t;
                blue = p;
            }
            else if (colorCase == 1)
            {
                red = q;
                green = v;
                blue = p;
            }
            else if (colorCase == 2)
            {
                red = p;
                green = v;
                blue = t;
            }
            else if (colorCase == 3)
            {
                red = p;
                green = q;
                blue = v;
            }
            else if (colorCase == 4)
            {
                red = t;
                green = p;
                blue = v;
            }
            else if (colorCase == 5)
            {
                red = v;
                green = p;
                blue = q;
            }
            
            var r:uint = Math.floor(red * 256);
            var g:uint = Math.floor(green * 256);
            var b:uint = Math.floor(blue * 256);
            return (255 << 24 ) | ( r << 16 ) | ( g << 8 ) | b;
        }
        
        /**
         * Use the golden ratio to pick out a nicer looking distribution of colors
         */
        public static function getDistributedHsvColor(hue:Number, sat:Number=0.99, val:Number=0.99):uint
        {
            var goldenRatioConjugate:Number = 0.618033988749895;
            hue = (hue + goldenRatioConjugate) % 1.0;
            return XColor.hsvToRgb(hue, sat, val);
        }
        
        /**
         * @param percent
         *      A value between 1 and -1. Positive values shade the color lighter,
         *      negative will make it darker.
         */
        public static function shadeColor(color:uint, percent:Number):uint
        {
            // Clamp percent to between -1 and 1
            if (percent < -1)
            {
                percent = -1;
            }
            else if (percent > 1)
            {
                percent = 1;
            }
            
            var ratio:Number = 1 + percent;
            var redAmount:int = clampColor((color >> 16 & 0xFF) * ratio);
            var greenAmount:int = clampColor((color >> 8 & 0xFF) * ratio);
            var blueAmount:int = clampColor((color & 0xFF) * ratio);
            
            var shadedColor:uint = (redAmount << 16) | (greenAmount << 8) | blueAmount;
            return shadedColor;
        }
        
        private static function clampColor(value:int):int
        {
            if (value > 255)
            {
                value = 255;
            }
            else if (value < 0)
            {
                value = 0;
            }
            
            return value;
        }
    }
}