package dragonbox.common.util
{
    public class TextToNumber
    {
        private const ONES:String = "onesValue";
        private var onesValues:Object = {
            'zero': 0,
            'one': 1,
            'two': 2,
            'three': 3,
            'four': 4,
            'five': 5,
            'six': 6,
            'seven': 7,
            'eight': 8,
            'nine': 9
        };
        private const ONE_OFF_TENS:String = "oneOffTens";
        private var oneOffTens:Object = {
            'ten': 10,
            'eleven': 11,
            'twelve': 12,
            'thirteen': 13,
            'fourteen': 14,
            'fifteen': 15,
            'sixteen': 16,
            'seventeen': 17,
            'eighteen': 18,
            'nineteen': 19
        };
        private const TENS:String = "tens";
        private var tensValues:Object = {
            'twenty': 20,
            'thirty': 30,
            'forty': 40,
            'fifty': 50,
            'sixty': 60,
            'seventy': 70,
            'eighty': 80,
            'ninety': 90
        };
        private const MAGNITUDE:String = "magnitude";        
        private var magnitudeValues:Object = {
            'hundred': 100,
            'thousand': 1000,
            'million': 1000000,
            'billion': 1000000000
        };
        
        public function TextToNumber()
        {
        }
        
        /**
         *
         * @return
         *      NaN if no number could be parsed from the string.
         */
        public function textToNumber(text:String):Number
        {
            // The grammer rules for a textual representation, ALL caps are tokens
            // COMPOUND = tensValues + (optional) onesValues
            // NUMBER = (onesValues | oneOffTens | COMPOUND) + (optional) magnitudeValues + (optional) NUMBER with smaller magnitude
            var numberToReturn:Number = NaN;
            var words:Array = text.split(/\s+/);
            var i:int;
            var numWords:int = words.length;
            
            // First pass is to just try to use the built-in parse method and see if a number
            // can be extracted by one of the words
            for (i = 0; i < numWords; i++)
            {
                var word:String = words[i];
                
                // Remove commas, otherwise parseFloat will treat something like 1,000 as just 1
                word = word.replace(/[,\$]/g, "");
                var attemptToParseNumberDirectly:Number = parseFloat(word);
                if (!isNaN(attemptToParseNumberDirectly))
                {
                    // Found a number that can be parsed, return that one immediately
                    numberToReturn = attemptToParseNumberDirectly;
                    break;
                }
            }
            
            if (isNaN(numberToReturn))
            {
                // If no number can be parsed directly then we must try to build it from the words.
                // Return the first sequence of words that form a number.
                // The target number should attempt to match the grammer defined above
                var tokenTypes:Vector.<String> = new Vector.<String>();
                var numbers:Vector.<int> = new Vector.<int>();
                for (i = 0; i < numWords; i++)
                {
                    // Strip out puncuation
                    word = words[i];
                    words[i] = word.replace(/[.,-\/#!$%\^&\*;:{}=\-_`~()]/g, "");
                    
                    // First attempt to match each word into some type so it is easier to check if it
                    // fits the grammer rule.
                    if (onesValues.hasOwnProperty(word))
                    {
                        tokenTypes.push(ONES);
                        numbers.push(onesValues[word]);
                    }
                    else if (oneOffTens.hasOwnProperty(word))
                    {
                        tokenTypes.push(ONE_OFF_TENS);
                        numbers.push(oneOffTens[word]);
                    }
                    else if (tensValues.hasOwnProperty(word))
                    {
                        tokenTypes.push(TENS);
                        numbers.push(tensValues[word]);
                    }
                    else if (magnitudeValues.hasOwnProperty(word))
                    {
                        tokenTypes.push(MAGNITUDE);
                        numbers.push(magnitudeValues[word]);
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
                
                var runningTotal:int = 0;   // Keeping track of the current NUMBER in the rules
                var lastBuiltNumberChunk:int = 0;
                var buildingCompound:Boolean = false;
                var buildingMagnitude:Boolean = false;
                for (i = 0; i < tokenTypes.length; i++)
                {
                    var currentType:String = tokenTypes[i];
                    var currentNumber:int = numbers[i];
                    var prevType:String = (i > 0) ? tokenTypes[i - 1] : null;
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
                    else // Magnitude type
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
}