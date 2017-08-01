package dragonbox.common.util;


class TextToNumber
{
    private inline static var ONES : String = "onesValue";
    private var onesValues : Dynamic = {
            zero : 0,
            one : 1,
            two : 2,
            three : 3,
            four : 4,
            five : 5,
            six : 6,
            seven : 7,
            eight : 8,
            nine : 9,
    };
	
	private inline static var ONE_OFF_TENS : String = "oneOffTens";
    private var oneOffTens : Dynamic = {
            ten : 10,
            eleven : 11,
            twelve : 12,
            thirteen : 13,
            fourteen : 14,
            fifteen : 15,
            sixteen : 16,
            seventeen : 17,
            eighteen : 18,
            nineteen : 19,
    };
	
	private inline static var TENS : String = "tens";
    private var tensValues : Dynamic = {
            twenty : 20,
            thirty : 30,
            forty : 40,
            fifty : 50,
            sixty : 60,
            seventy : 70,
            eighty : 80,
            ninety : 90,
    };
	
	private inline static var MAGNITUDE : String = "magnitude";
    private var magnitudeValues : Dynamic = {
            hundred : 100,
            thousand : 1000,
            million : 1000000,
            billion : 1000000000,
    };
    
    public function new()
    {
    }
    
    /**
     *
     * @return
     *      NaN if no number could be parsed from the string.
     */
    public function textToNumber(text : String) : Float
    {
        // The grammer rules for a textual representation, ALL caps are tokens
        // COMPOUND = tensValues + (optional) onesValues
        // NUMBER = (onesValues | oneOffTens | COMPOUND) + (optional) magnitudeValues + (optional) NUMBER with smaller magnitude
        var numberToReturn : Float = Math.NaN;
        var words : Array<Dynamic> = (new EReg('\\s+', "")).split(text);
        var i : Int = 0;
        var numWords : Int = words.length;
        
        // First pass is to just try to use the built-in parse method and see if a number
        // can be extracted by one of the words
        for (i in 0...numWords){
            var word : String = words[i];
            
            // Remove commas, otherwise parseFloat will treat something like 1,000 as just 1
            word = (new EReg('[,\\$]', "g")).replace(word, "");
            var attemptToParseNumberDirectly : Float = Std.parseFloat(word);
            if (!Math.isNaN(attemptToParseNumberDirectly)) 
            {
                // Found a number that can be parsed, return that one immediately
                numberToReturn = attemptToParseNumberDirectly;
                break;
            }
        }
        
        if (Math.isNaN(numberToReturn)) 
        {
            // If no number can be parsed directly then we must try to build it from the words.
            // Return the first sequence of words that form a number.
            // The target number should attempt to match the grammer defined above
            var tokenTypes : Array<String> = new Array<String>();
            var numbers : Array<Int> = new Array<Int>();
            for (i in 0...numWords){
                // Strip out puncuation
                var word = words[i];
                words[i] = (new EReg('[.,-\\/#!$%\\^&\\*;:{}=\\-_`~()]', "g")).replace(word, "");
                
                // First attempt to match each word into some type so it is easier to check if it
                // fits the grammer rule.
				var wordValue = Std.parseInt(word);
                if (onesValues.exists(word)) 
                {
                    tokenTypes.push(ONES);
                    numbers.push(onesValues[wordValue]);
                }
                else if (oneOffTens.exists(word)) 
                {
                    tokenTypes.push(ONE_OFF_TENS);
                    numbers.push(oneOffTens[wordValue]);
                }
                else if (tensValues.exists(word)) 
                {
                    tokenTypes.push(TENS);
                    numbers.push(tensValues[wordValue]);
                }
                else if (magnitudeValues.exists(word)) 
                {
                    tokenTypes.push(MAGNITUDE);
                    numbers.push(magnitudeValues[wordValue]);
                }
                else 
                {
                    // If we have already accumulated a list of number word, a non-matching
                    // word will cause us to exit. Just analyze
                    if (tokenTypes.length > 0) 
                    {
                        break;
                    }
                }
            }
            
            var runningTotal : Int = 0;  // Keeping track of the current NUMBER in the rules  
            var lastBuiltNumberChunk : Int = 0;
            var buildingCompound : Bool = false;
            var buildingMagnitude : Bool = false;
            for (i in 0...tokenTypes.length){
                var currentType : String = tokenTypes[i];
                var currentNumber : Int = numbers[i];
                var prevType : String = ((i > 0)) ? tokenTypes[i - 1] : null;
                if (currentType == ONES) 
                {
                    if (buildingCompound) 
                    {
                        lastBuiltNumberChunk += currentNumber;
                        buildingCompound = false;
                    }
                    else 
                    {
                        lastBuiltNumberChunk = currentNumber;
                    }
                }
                else if (currentType == ONE_OFF_TENS) 
                {
                    lastBuiltNumberChunk = currentNumber;
                }
                else if (currentType == TENS) 
                {
                    buildingCompound = true;
                    lastBuiltNumberChunk = currentNumber;
                }
                // Magnitude type
                else 
                {
                    // The last built chunk should be multiplied by the magnitude modifier
                    runningTotal = lastBuiltNumberChunk * currentNumber;
                    
                    // Reset the last chunk
                    lastBuiltNumberChunk = 0;
                }
            }
            
            if (tokenTypes.length > 0) 
            {
                runningTotal += lastBuiltNumberChunk;
                numberToReturn = runningTotal;
            }
        }
        
        return numberToReturn;
    }
}
