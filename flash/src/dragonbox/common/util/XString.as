package dragonbox.common.util 
{
	public final class XString 
	{
		import flash.geom.Point;
		
		/**
		 * Converts a string into a boolean by looking at the contents of the string.
		 * @param s String to convert to Boolean: "false" (any case or combination upper/lowercase), "0", "f", "F", "null" (any case) or empty string ("") return false, everything else returns true
		 * @return The bool represented by the string. Default to true, although "null" and empty string return false
		 */		
		public static function stringToBool(st:String):Boolean
		{
			if (!st) {
				return false;
			}
			
			var lcst:String = st.toLowerCase();
			switch (lcst) {
				case "true":
				case "1":
				case "yes":
				case "t":
					return true;
				break;
			}
			
			return false;
		}
		
        /**
         * Get whether the given value can be completely parsed into a decimal number.
         * The built-in as3 functions only check whether the starting characters are number
         */
        public static function isNumber(value:String):Boolean
        {
            var numericRegex:RegExp = /([0-9])/;
            
            // Strip whitespace
            value = value.replace(" ", "");
            
            // Simply iterate through every character and check if each one is a digit
            // Also allow for decimal
            var containsDecimal:Boolean = false;
            var isNumber:Boolean = true;
            var numCharacters:int = value.length;
            var i:int;
            for (i = 0; i < numCharacters; i++)
            {
                var char:String = value.charAt(i);
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
		
		public static function arrayToString(arr:Array):String {
			var str:String = "[";
			for (var i:int = 0; i < arr.length; i++) {
				str = str + String(arr[i]);
				if (i < arr.length - 1) {
					str = str + ",";
				}
			}
			str = str + "]";
			return str;
		}
		
		public static function intVectorToString(vec:Vector.<int>):String
		{
			var str:String = "[";
			for (var i:int = 0; i < vec.length; i++) {
				str = str + String(vec[i]);
				if (i < vec.length - 1) {
					str = str + ",";
				}
			}
			str = str + "]";
			return str;
		}
		
		public static function stringToIntVector(str:String):Vector.<int>
		{
			var ret:Vector.<int> = new Vector.<int>();
			var strArray:Array = stripParens(str).split(",");
			for each (var substr:String in strArray) {
				ret.push(int(substr));
			}
			return ret;
		}
		
		private static function stripParens(a:String):String
		{
			if ( (a.charAt(0)=="(") || (a.charAt(0)=="[") )
				a = a.slice(1, a.length);
			if ( (a.charAt(a.length - 1)==")") || (a.charAt(a.length - 1)=="]") )
				a = a.slice(0, a.length - 1);
			return a;
		}
		
		public static function stringToPointVector(str:String):Vector.<Point>
		{
			var fullString:String = str;
			
			// array of points
			var vec:Vector.<Point> = new Vector.<Point>();
			var pointsArray:Array = stripParens(str).split("),(");
			for (var j:int = 0; j < pointsArray.length; j++) {
				var coords:Array = pointsArray[j].split(",");
				if (isNaN(coords[0]) || isNaN(coords[1]))
					continue;
				vec.push(new Point(coords[0], coords[1]));
			}
			return vec;
		}
		
		public static function pointVectorToString(vec:Vector.<Point>):String
		{
			var new_string:String = "";
			var i:uint = 0;
			for each (var pt:Point in vec) {
				new_string += "(" + pt.x.toFixed(1).toString() + "," + pt.y.toFixed(1).toString() + ")";
				if (i + 1 < vec.length)
					new_string += ",";
				i++;
			}
			return new_string;
		}
	}

}