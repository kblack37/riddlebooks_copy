package dragonbox.common.util;

import flash.geom.Point;


@:final class XString
{
    
    
    /**
		 * Converts a string into a boolean by looking at the contents of the string.
		 * @param s String to convert to Boolean: "false" (any case or combination upper/lowercase), "0", "f", "F", "null" (any case) or empty string ("") return false, everything else returns true
		 * @return The bool represented by the string. Default to true, although "null" and empty string return false
		 */
    public static function stringToBool(st : String) : Bool
    {
        if (st == null) {
            return false;
        }
        
        var lcst : String = st.toLowerCase();
        switch (lcst)
        {
            case "true", "1", "yes", "t":
                return true;
        }
        
        return false;
    }
    
    /**
     * Get whether the given value can be completely parsed into a decimal number.
     * The built-in as3 functions only check whether the starting characters are number
     */
    public static function isNumber(value : String) : Bool
    {
        var numericRegex : EReg = new EReg('([0-9])', "");
        
        // Strip whitespace
        value = value.replace(" ", "");
        
        // Simply iterate through every character and check if each one is a digit
        // Also allow for decimal
        var containsDecimal : Bool = false;
        var isNumber : Bool = true;
        var numCharacters : Int = value.length;
        var i : Int;
        for (i in 0...numCharacters){
            var char : String = value.charAt(i);
            if (char == ".") 
            {
                // Cannot have multiple decimals
                if (containsDecimal) 
                {
                    isNumber = false;
                    break;
                }
                else 
                {
                    containsDecimal = true;
                }
            }
            // Found a character that is not a number
            else if (!numericRegex.test(char)) 
            {
                isNumber = false;
                break;
            }
        }
        
        return isNumber;
    }
    
    public static function arrayToString(arr : Array<Dynamic>) : String{
        var str : String = "[";
        for (i in 0...arr.length){
            str = str + Std.string(arr[i]);
            if (i < arr.length - 1) {
                str = str + ",";
            }
        }
        str = str + "]";
        return str;
    }
    
    public static function intVectorToString(vec : Array<Int>) : String
    {
        var str : String = "[";
        for (i in 0...vec.length){
            str = str + Std.string(vec[i]);
            if (i < vec.length - 1) {
                str = str + ",";
            }
        }
        str = str + "]";
        return str;
    }
    
    public static function stringToIntVector(str : String) : Array<Int>
    {
        var ret : Array<Int> = new Array<Int>();
        var strArray : Array<Dynamic> = stripParens(str).split(",");
        for (substr in strArray){
            ret.push(as3hx.Compat.parseInt(substr));
        }
        return ret;
    }
    
    private static function stripParens(a : String) : String
    {
        if ((a.charAt(0) == "(") || (a.charAt(0) == "[")) 
            a = a.substring(1, a.length);
        if ((a.charAt(a.length - 1) == ")") || (a.charAt(a.length - 1) == "]")) 
            a = a.substring(0, a.length - 1);
        return a;
    }
    
    public static function stringToPointVector(str : String) : Array<Point>
    {
        var fullString : String = str;
        
        // array of points
        var vec : Array<Point> = new Array<Point>();
        var pointsArray : Array<Dynamic> = stripParens(str).split("),(");
        for (j in 0...pointsArray.length){
            var coords : Array<Dynamic> = pointsArray[j].split(",");
            if (Math.isNaN(coords[0]) || Math.isNaN(coords[1])) 
                continue;
            vec.push(new Point(coords[0], coords[1]));
        }
        return vec;
    }
    
    public static function pointVectorToString(vec : Array<Point>) : String
    {
        var new_string : String = "";
        var i : Int = 0;
        for (pt in vec){
            new_string += "(" + Std.string(pt.x.toFixed(1)) + "," + Std.string(pt.y.toFixed(1)) + ")";
            if (i + 1 < vec.length) 
                new_string += ",";
            i++;
        }
        return new_string;
    }

    public function new()
    {
    }
}

