package wordproblem.hints.selector
{
    public class HintXMLStorage
    {
        // The hint information is formatted as xml
        private var m_hintData:XML;
        
        /**
         * Map from step id to list of hint xml elements.
         * On step can have multiple hints
         */
        private var m_stepIdToHintElementList:Object;
        
        public function HintXMLStorage(hintData:XML)
        {
            m_hintData = hintData;
            
            m_stepIdToHintElementList = {};
            var childHints:XMLList = hintData.children();
            var numChildren:int = childHints.length();
            var i:int;
            for (i = 0; i < numChildren; i++)
            {
                var childHint:XML = childHints[i];
                var stepId:int = parseInt(childHint.attribute("step"));
                if (!m_stepIdToHintElementList.hasOwnProperty(stepId))
                {
                    m_stepIdToHintElementList[stepId] = new Vector.<XML>();
                }
                
                (m_stepIdToHintElementList[stepId] as Vector.<XML>).push(childHint);
            }
        }
        
        /**
         * @param params
         *      List of extra data parts to configure the hint.
         * @param filterData
         *      Extra blob to specify rules to select a given hint when a step contains many.
         *      An example is a step may be for hints when a part of a sum is missing. A sum can
         *      contain many parts and a step would contain hints for each part, need to determine
         *      which one by having the game specify the missing one to focus on.
         *      Can be null to we want to just randomly pick a hint
         */
        public function getHintFromStepId(stepId:int, params:Array, filterData:Object):Object
        {
            var hintData:Object = null;
            
            if (m_stepIdToHintElementList.hasOwnProperty(stepId))
            {
                // If possible, look at the params act as a filter.
                // For example a param, might include the bar model pattern name 'a1', 'b1', 'unk'
                // used to indicate which element is missing
                var hintElementsForStep:Vector.<XML> = m_stepIdToHintElementList[stepId];
                if (hintElementsForStep.length > 0)
                {
                    
                    var indexForStep:int = -1;
                    
                    // Try to use the filter to pick out a hint from the step
                    if (filterData != null)
                    {
                        // This filter checks if a step has a 'existingBar' attribute.
                        // This means this step is valid if the user has included the part with that
                        // name in their current bar model.
                        // For example.) existingBar=a mean that part id 'a' has been placed as a part
                        if (filterData.hasOwnProperty("existingLabelParts"))
                        {
                            var existingLabelParts:Array = filterData["existingLabelParts"];
                            for (var i:int = 0; i < hintElementsForStep.length; i++)
                            {
                                var candidateHint:XML = hintElementsForStep[i];
                                if (candidateHint.hasOwnProperty("@existingBar"))
                                {
                                    var partNamePrefix:String = candidateHint.@existingBar;
                                    for each (var barLabelPartName:String in existingLabelParts)
                                    {
                                        if (barLabelPartName.indexOf(partNamePrefix) == 0)
                                        {
                                            indexForStep = i;
                                            break;
                                        }
                                    }
                                }
                                
                                if (indexForStep > -1)
                                {
                                    break;
                                }
                            }
                        }
                        // Filter indicates that a value associated with a tagged document id is missing.
                        // Get the hint that exactly references this
                        else if (filterData.hasOwnProperty("targetMissingDocId"))
                        {
                            for (i = 0; i < hintElementsForStep.length; i++)
                            {
                                candidateHint = hintElementsForStep[i];
                                if (candidateHint.hasOwnProperty("@targetMissingDocId") && 
                                    candidateHint.@targetMissingDocId.toString() == filterData["targetMissingDocId"])
                                {
                                    indexForStep = i;
                                }
                                
                                if (indexForStep > -1)
                                {
                                    break;
                                }
                            }
                        }
                    }
                    
                    // Randomly pick from list if no filter
                    if (indexForStep < 0)
                    {
                        indexForStep = Math.floor(Math.random() * hintElementsForStep.length);
                    }
                    
                    var hintElementToUse:XML = hintElementsForStep[indexForStep];
                    hintData = {};
                    
                    var text:String = hintElementToUse.text().toString();
                    text = replaceParamsWithValues(text, params);
                    hintData['descriptionContent'] = text;
                    
                    var attributes:XMLList = hintElementToUse.attributes();
                    for (i = 0; i < attributes.length(); i++)
                    {
                        var attributeName:String = attributes[i].name();
                        var attributeValue:String = hintElementToUse.attribute(attributeName);
                        if (attributeValue.indexOf("$") > -1)
                        {
                            attributeValue = replaceParamsWithValues(attributeValue, params);
                        }
                        hintData[attributeName] = attributeValue;
                    }
                }
            }
            
            return hintData;
        }
        
        private function replaceParamsWithValues(valueString:String, params:Array):String
        {
            if (params != null)
            {
                var i:int;
                for (i = 0; i < params.length; i++)
                {
                    //var paramReplaceString:String = "\$" + i;
                    //var pattern:RegExp = new RegExp(/ /.source + paramReplaceString, 'g');
                    var pattern:String = "\\$" + i;
                    var patternRegex:RegExp = new RegExp(pattern, "g");
                    valueString = valueString.replace(patternRegex, params[i]);
                }
            }
            
            return valueString;
        }
    }
}