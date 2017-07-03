package wordproblem.hints.selector;


class HintXMLStorage
{
    // The hint information is formatted as xml
    private var m_hintData : FastXML;
    
    /**
     * Map from step id to list of hint xml elements.
     * On step can have multiple hints
     */
    private var m_stepIdToHintElementList : Dynamic;
    
    public function new(hintData : FastXML)
    {
        m_hintData = hintData;
        
        m_stepIdToHintElementList = { };
        var childHints : FastXMLList = hintData.node.children.innerData();
        var numChildren : Int = childHints.length();
        var i : Int;
        for (i in 0...numChildren){
            var childHint : FastXML = childHints.get(i);
            var stepId : Int = parseInt(childHint.node.attribute.innerData("step"));
            if (!m_stepIdToHintElementList.exists(stepId)) 
                            {
                                m_stepIdToHintElementList[stepId] = new Array<FastXML>();
                            }(try cast(m_stepIdToHintElementList[stepId], Array/*Vector.<T> call?*/) catch(e:Dynamic) null).push(childHint);
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
    public function getHintFromStepId(stepId : Int, params : Array<Dynamic>, filterData : Dynamic) : Dynamic
    {
        var hintData : Dynamic = null;
        
        if (m_stepIdToHintElementList.exists(stepId)) 
        {
            // If possible, look at the params act as a filter.
            // For example a param, might include the bar model pattern name 'a1', 'b1', 'unk'
            // used to indicate which element is missing
            var hintElementsForStep : Array<FastXML> = m_stepIdToHintElementList[stepId];
            if (hintElementsForStep.length > 0) 
            {
                
                var indexForStep : Int = -1;
                
                // Try to use the filter to pick out a hint from the step
                if (filterData != null) 
                {
                    // This filter checks if a step has a 'existingBar' attribute.
                    // This means this step is valid if the user has included the part with that
                    // name in their current bar model.
                    // For example.) existingBar=a mean that part id 'a' has been placed as a part
                    if (filterData.exists("existingLabelParts")) 
                    {
                        var existingLabelParts : Array<Dynamic> = Reflect.field(filterData, "existingLabelParts");
                        for (i in 0...hintElementsForStep.length){
                            var candidateHint : FastXML = hintElementsForStep[i];
                            if (candidateHint.node.exists.innerData("@existingBar")) 
                            {
                                var partNamePrefix : String = candidateHint.att.existingBar;
                                for (barLabelPartName in existingLabelParts)
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
                    else if (filterData.exists("targetMissingDocId")) 
                    {
                        for (i in 0...hintElementsForStep.length){
                            candidateHint = hintElementsForStep[i];
                            if (candidateHint.exists("@targetMissingDocId") &&
                                Std.string(candidateHint.att.targetMissingDocId) == Reflect.field(filterData, "targetMissingDocId")) 
                            {
                                indexForStep = i;
                            }
                            
                            if (indexForStep > -1) 
                            {
                                break;
                            }
                        }
                    }
                }  // Randomly pick from list if no filter  
                
                
                
                if (indexForStep < 0) 
                {
                    indexForStep = Math.floor(Math.random() * hintElementsForStep.length);
                }
                
                var hintElementToUse : FastXML = hintElementsForStep[indexForStep];
                hintData = { };
                
                var text : String = Std.string(hintElementToUse.node.text.innerData());
                text = replaceParamsWithValues(text, params);
                Reflect.setField(hintData, "descriptionContent", text);
                
                var attributes : FastXMLList = hintElementToUse.node.attributes.innerData();
                for (i in 0...attributes.length()){
                    var attributeName : String = attributes.get(i).node.name.innerData();
                    var attributeValue : String = hintElementToUse.node.attribute.innerData(attributeName);
                    if (attributeValue.indexOf("$") > -1) 
                    {
                        attributeValue = replaceParamsWithValues(attributeValue, params);
                    }
                    Reflect.setField(hintData, attributeName, attributeValue);
                }
            }
        }
        
        return hintData;
    }
    
    private function replaceParamsWithValues(valueString : String, params : Array<Dynamic>) : String
    {
        if (params != null) 
        {
            var i : Int;
            for (i in 0...params.length){
                //var paramReplaceString:String = "\$" + i;
                //var pattern:RegExp = new RegExp(/ /.source + paramReplaceString, 'g');
                var pattern : String = "\\$" + i;
                var patternRegex : EReg = new EReg(pattern, "g");
                valueString = valueString.replace(patternRegex, params[i]);
            }
        }
        
        return valueString;
    }
}