package dragonbox.common.util;
import openfl.filters.ColorMatrixFilter;
import openfl.geom.ColorTransform;


class XColor
{
    
    public static inline var ROYAL_BLUE : Int = 0x006CC1;
    public static inline var BRIGHT_ORANGE : Int = 0xFF9900;
    public static inline var DARK_GREEN : Int = 0x346900;
    
    // Color picking, cannot pick the same index twice in a session
    // The color batch needs to be reset at the start of each level.
    // Do not have red, feedback recieved it would indicate wrong
    private static var CANDIDATE_COLORS : Array<Int> = [
                0xFF6099F5,   // Dark Blue  
                0xFFBB89DD,   // Purple  
                0xFFF05CFD,   // Magenta  
                0xFFEDDB48,   // Gold (Replaced Red)  
                0xFFFDB402,   // Orange  
                0xFF19FD02,   // Green  
                0xFF02E2FD,   // Sky Blue  
                0xFFFFFFFF,   // White  
                0xFFFAFF96,   // Light Yellow  
                0xFFC4C4C4,   // Gray  
                0xFFB39566,   // Light Brown  
                0xFFFDD1FF,   // Light Pink  
                0xFFD1FFDC  //0xFFFFAA99 // Peach    //0xFF99CC99, // Sea Green    // Light Green  
				];
				
	private static var rLum = 0.2225;
	private static var gLum = 0.7169;
	private static var bLum = 0.0606;
	private static var grayscaleFilter : ColorMatrixFilter = new ColorMatrixFilter(
		[rLum, gLum, bLum, 0, 0,
		 rLum, gLum, bLum, 0, 0,
		 rLum, gLum, bLum, 0, 0,
		 0,    0,    0,    1, 0]);
    
    public static function getCandidateColorsForSession() : Array<Int>
    {
        var colorCopy : Array<Int> = new Array<Int>();
        for (color in CANDIDATE_COLORS)
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
    public static function interpolateColors(color1 : Int, color2 : Int, ratio : Float) : Int
    {
        var inv : Float = 1 - ratio;
        var red : Int = Math.round(((color1 >>> 16) & 255) * ratio + ((color2 >>> 16) & 255) * inv);
        var green : Int = Math.round(((color1 >>> 8) & 255) * ratio + ((color2 >>> 8) & 255) * inv);
        var blue : Int = Math.round(((color1) & 255) * ratio + ((color2) & 255) * inv);
        var alpha : Int = Math.round(((color1 >>> 24) & 255) * ratio + ((color2 >>> 24) & 255) * inv);
        return (alpha << 24) | (red << 16) | (green << 8) | blue;
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
    public static function hsvToRgb(h : Float, s : Float, v : Float) : Int
    {
        var colorCase : Int = Math.floor(h * 6);
        var f : Float = h * 6 - colorCase;
        var p : Float = v * (1 - s);
        var q : Float = v * (1 - f * s);
        var t : Float = v * (1 - (1 - f) * s);
        
        var red : Float = 0;
        var green : Float = 0;
        var blue : Float = 0;
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
        
        var r : Int = Math.floor(red * 256);
        var g : Int = Math.floor(green * 256);
        var b : Int = Math.floor(blue * 256);
        return (255 << 24) | (r << 16) | (g << 8) | b;
    }
	
	/**
	 * Takes in an RGB color and returns a color transform used for shading to that color
	 */
	public static function rgbToColorTransform(color : Int) : ColorTransform {
		var colorTransform = new ColorTransform();
		colorTransform.redMultiplier = extractRed(color) / 255.0;
		colorTransform.greenMultiplier = extractGreen(color) / 255.0;
		colorTransform.blueMultiplier = extractBlue(color) / 255.0;
		return colorTransform;
	}
	
	public static function extractRed(color : Int) : Int {
		return (color >> 16) & 0xFF;
	}
	
	public static function extractGreen(color : Int) : Int {
		return (color >> 8) & 0xFF;
	}
	
	public static function extractBlue(color : Int) : Int {
		return color & 0xFF;
	}
	
	public static function getGrayscaleFilter() : ColorMatrixFilter {
		return grayscaleFilter;
	}
    
    /**
     * Use the golden ratio to pick out a nicer looking distribution of colors
     */
    public static function getDistributedHsvColor(hue : Float, sat : Float = 0.99, val : Float = 0.99) : Int
    {
        var goldenRatioConjugate : Float = 0.618033988749895;
        hue = (hue + goldenRatioConjugate) % 1.0;
        return XColor.hsvToRgb(hue, sat, val);
    }
    
    /**
     * @param percent
     *      A value between 1 and -1. Positive values shade the color lighter,
     *      negative will make it darker.
     */
    public static function shadeColor(color : Int, percent : Float) : Int
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
        
        var ratio : Float = 1 + percent;
        var redAmount : Int = clampColor(Std.int((color >> 16 & 0xFF) * ratio));
        var greenAmount : Int = clampColor(Std.int((color >> 8 & 0xFF) * ratio));
        var blueAmount : Int = clampColor(Std.int((color & 0xFF) * ratio));
        
        var shadedColor : Int = (redAmount << 16) | (greenAmount << 8) | blueAmount;
        return shadedColor;
    }
    
    private static function clampColor(value : Int) : Int
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

    public function new()
    {
    }
}
