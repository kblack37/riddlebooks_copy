package wordproblem.hints
{
    import wordproblem.engine.barmodel.BarModelTypes;

    /**
     * A rudimentary method to create slightly more customized hints for an individual bar model level.
     * The custom hints still rely on pre-written sentence templates in order to create the hint. The specificity
     * will come from handwritten extra data incorporated along with each individual bar model. The extra data
     * should include info like the nouns for each part or nicer sounding names for the variables.
     * 
     * For example: Suppose we have a problem adding 3 apples and 4 oranges that asks for total number of fruit.
     * Normally there isn't a standard way to figure out one part is talking about apples and the other oranges.
     * The hint data would include this fact in a mapping, it would specify that apples and oranges are important
     * values. Thus our hint template can use those nouns to create more specific sounding hints.
     */
    public class CustomHintGenerator
    {
        private var m_customHintTemplateXml:XML;
        
        /**
         * Mapping for a string id of a hint template to the xml element containing all the data
         * for that template. Use this to generate the appropriate hint.
         */
        private var m_hintLabelIdToHintXmlListMap:Object;
        
        /**
         * Mapping from the string bar model type to a list of xml elements
         * containing label id and step. The are the hint valid for that type
         */
        private var m_barModelTypeToLabelIdListMap:Object;
        
        public function CustomHintGenerator(customHintTemplateXml:XML)
        {
            m_customHintTemplateXml = customHintTemplateXml;
            
            // Do some pre-processing on the template xml.
            // Each bar model type should link to a list of hint ids that represent the 
            // pool of candidate hints that might be useful to show to the player.
            var barModelHintBlocks:XMLList = customHintTemplateXml.elements("barmodelhints");
            m_hintLabelIdToHintXmlListMap = {};
            var i:int;
            for (i = 0; i < barModelHintBlocks.length(); i++)
            {
                var barModelHintBlock:XML = barModelHintBlocks[i];
                var hintElements:XMLList = barModelHintBlock.elements("hint");
                var j:int;
                for (j = 0; j < hintElements.length(); j++)
                {
                    // Create the mapping from label to step based on the selected block
                    var hintElement:XML = hintElements[j];
                    var hintLabelId:String = hintElement.attribute("labelId");
                    if (!m_hintLabelIdToHintXmlListMap.hasOwnProperty(hintLabelId))
                    {
                        m_hintLabelIdToHintXmlListMap[hintLabelId] = new Vector.<XML>();
                    }
                    
                    var hintXmlListForId:Vector.<XML> = m_hintLabelIdToHintXmlListMap[hintLabelId];
                    hintXmlListForId.push(hintElement);
                }
            }
            
            m_barModelTypeToLabelIdListMap = {};
            var typeToHintsMappings:XMLList = customHintTemplateXml.elements("mapping");
            for (i = 0; i < typeToHintsMappings.length(); i++)
            {
                var mappingBlock:XML = typeToHintsMappings[i];
                var hintLabels:Vector.<XML> = new Vector.<XML>();
                var mappingElements:XMLList = mappingBlock.elements("label");
                for (j = 0; j < mappingElements.length(); j++)
                {
                    hintLabels.push(mappingElements[j]);
                }
                
                var typeAttribute:String = mappingBlock.attribute("type");
                var typesForMapping:Array = typeAttribute.replace(" ", "").split(",");
                for each (var barModelType:String in typesForMapping)
                {
                    if (barModelType != null && barModelType.length > 0)
                    {
                        m_barModelTypeToLabelIdListMap[barModelType] = hintLabels;
                    }
                }
            }
        }
        
        /**
         *
         * @param docIdToValueMap
         *      Map from document id of a tagged part of the text to the expression value it is
         *      bound to (either a number or variable)
         * @param hintDataForLevel
         *      The extra details related to hints for a particular problem. Most likely stored in
         *      the problem database
         */
        public function generateHintsForLevel(barModelTypeForLevel:String,
                                              docIdToValueMap:Object,
                                              hintDataForLevel:Object):XML
        {
            // Each bar model type has unique pattern that slightly alters parameters.
            // For example, looking at the reference model pictures, the fact that '?' is a total
            // in one type or a difference in another is an important distinguishing feature that
            // alters how some parameters to generate the hint is set up.
            // This is most useful for the cases where we want the custom hints to display numbers, since the hint
            // have no knowledge of bar model types they can only contain general terms like 'total', 'difference',
            // 'part-of-sum'
            // We need to figure out the specific numbers and variables that map to these general terms so
            // we can do proper replacement on them
            var generalTermsToNumbersMap:Object = {};
            
            // For one type of problem the total is a number, for the other it might be an unknown.
            // This difference sometimes should trigger a different hint.
            // How should this further selection go?
            // Seems like we want to be able to have multiple property type restrictions
            // Each hint template has a collection of tags
            
            // A label might map to multiple hint templates, we can only use one of them and must
            // pick the one that sounds the best.
            // The specific bar model problem will need to include a special set of properties as part of
            // its hint data. These properties will be used to help filter out the hint templates deemed
            // inappropriate
            // The hint template will have a problemType attribute to match up with the problemType defined
            // in hint data for this specific problem.
            var tagsInProblem:Array = (hintDataForLevel.hasOwnProperty("tags")) ? 
                hintDataForLevel["tags"] : [];
            
            if (barModelTypeForLevel == BarModelTypes.TYPE_1A)
            {
                // TODO: We are expecting some other part of the application to send us a mapping
                // from tagged document id to the actual numeric value
                generalTermsToNumbersMap["total"] = docIdToValueMap["unk"];
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_1B)
            {
                tagsInProblem.push("partIsNumber");
                tagsInProblem.push("partIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_2A)
            {
                tagsInProblem.push("partIsNumber");
                tagsInProblem.push("partIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_2B)
            {
                
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_2C)
            {
                tagsInProblem.push("partIsNumber");
                tagsInProblem.push("partIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_2D)
            {
                tagsInProblem.push("partIsNumber");
                tagsInProblem.push("partIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_2E)
            {
                tagsInProblem.push("partIsNumber");
                tagsInProblem.push("partIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_3A)
            {
                generalTermsToNumbersMap["numGroups"] = docIdToValueMap["b1"];
                generalTermsToNumbersMap["unitValue"] = docIdToValueMap["a1"];
                tagsInProblem.push("totalIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_3B)
            {
                generalTermsToNumbersMap["numGroups"] = docIdToValueMap["a1"];
                generalTermsToNumbersMap["total"] = docIdToValueMap["b1"];
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_4A)
            {
                generalTermsToNumbersMap["numGroups"] = docIdToValueMap["b1"];
                generalTermsToNumbersMap["unitValue"] = docIdToValueMap["a1"];
                tagsInProblem.push("totalIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_4B)
            {
                generalTermsToNumbersMap["numGroups"] = docIdToValueMap["b1"];
                generalTermsToNumbersMap["total"] = docIdToValueMap["a1"];
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_4C)
            {
                generalTermsToNumbersMap["numGroups"] = docIdToValueMap["b1"];
                generalTermsToNumbersMap["unitValue"] = docIdToValueMap["a1"];
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_4D)
            {
                generalTermsToNumbersMap["numGroups"] = docIdToValueMap["b1"];
                generalTermsToNumbersMap["unitValue"] = docIdToValueMap["a1"];
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_4E)
            {
                generalTermsToNumbersMap["numGroups"] = docIdToValueMap["b1"];
                generalTermsToNumbersMap["difference"] = docIdToValueMap["a1"];
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_4F)
            {
                generalTermsToNumbersMap["numGroups"] = docIdToValueMap["b1"];
                generalTermsToNumbersMap["total"] = docIdToValueMap["a1"];
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_5A)
            {
                tagsInProblem.push("totalIsVariable");
                tagsInProblem.push("partIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_5B)
            {
                tagsInProblem.push("totalIsVariable");
                tagsInProblem.push("partIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_5C)
            {
                tagsInProblem.push("differenceIsVariable");
                tagsInProblem.push("partIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_5D)
            {
                tagsInProblem.push("partIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_5E)
            {
                tagsInProblem.push("partIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_5F)
            {
                tagsInProblem.push("differenceIsVariable");
                generalTermsToNumbersMap["numGroups"] = docIdToValueMap["b1"];
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_5G)
            {
                tagsInProblem.push("totalIsVariable");
                generalTermsToNumbersMap["numGroups"] = docIdToValueMap["b1"];
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_5H)
            {
                tagsInProblem.push("totalIsVariable");
                generalTermsToNumbersMap["numGroups"] = docIdToValueMap["b1"];
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_5I)
            {
                tagsInProblem.push("totalIsVariable");
                generalTermsToNumbersMap["numGroups"] = docIdToValueMap["b1"];
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_5J)
            {
                tagsInProblem.push("totalIsVariable");
                generalTermsToNumbersMap["numGroups"] = docIdToValueMap["b1"];
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_5K)
            {
                tagsInProblem.push("differenceIsVariable");
                generalTermsToNumbersMap["numGroups"] = docIdToValueMap["b1"];
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_6A)
            {
                tagsInProblem.push("totalIsNumber");
                tagsInProblem.push("partIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_6B)
            {
                tagsInProblem.push("totalIsNumber");
                tagsInProblem.push("partIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_6C)
            {
                tagsInProblem.push("totalIsVariable");
                tagsInProblem.push("partIsNumber");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_6D)
            {
                tagsInProblem.push("partIsVariable");
                tagsInProblem.push("partIsNumber");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_7A)
            {
                tagsInProblem.push("partIsVariable");
                tagsInProblem.push("partIsNumber");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_7B)
            {
                tagsInProblem.push("totalIsVariable");
                tagsInProblem.push("partIsNumber");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_7C)
            {
                tagsInProblem.push("differenceIsNumber");
                tagsInProblem.push("partIsNumber");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_7D_1)
            {
                tagsInProblem.push("totalIsVariable");
                tagsInProblem.push("partIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_7D_2)
            {
                tagsInProblem.push("totalIsVariable");
                tagsInProblem.push("partIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_7E)
            {
                tagsInProblem.push("totalIsVariable");
                tagsInProblem.push("differenceIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_7F_1)
            {
                tagsInProblem.push("differenceIsNumber");
                tagsInProblem.push("partIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_7F_2)
            {
                tagsInProblem.push("differenceIsNumber");
                tagsInProblem.push("partIsVariable");
            }
            else if (barModelTypeForLevel == BarModelTypes.TYPE_7G)
            {
                tagsInProblem.push("totalIsVariable");
                tagsInProblem.push("differenceIsNumber");
            }
            
            // Need to deal with the situation where a hint template slightly changes depending on variations in the user bar model
            // In the previous turk hinting system, there was a need for existing bar model value. How would that apply here?
            // It will be up to the problem data to tell us to create multiple copies of a particular hint, the template will need
            // Essentially we will need a hint template that splits into more templates
            // ex.) You need to add the number of <noun x>, where <noun x> can be several things
            // The way to handle this:
            // A particular hint template will need know that there are multiple similar variations that can be applied to it
            // Within the properties of the problem we need to list all the variations need
            // <noun x> = #noun-a, #noun-b, #noun-c
            
            var generatedCustomHints:XML = <customHints/>;
            if (m_barModelTypeToLabelIdListMap.hasOwnProperty(barModelTypeForLevel))
            {
                var labelIdList:Vector.<XML> = m_barModelTypeToLabelIdListMap[barModelTypeForLevel];
                for each (var labelIdElement:XML in labelIdList)
                {
                    var labelId:String = labelIdElement.attribute("id");
                    var step:String = labelIdElement.attribute("step");
                    
                    if (m_hintLabelIdToHintXmlListMap.hasOwnProperty(labelId))
                    {
                        var hintXmlsForLabel:Vector.<XML> = m_hintLabelIdToHintXmlListMap[labelId];
                        for each (var hintXmlForLabel:XML in hintXmlsForLabel)
                        {   
                            // Skip over this hint if the type restriction tags for this particular problem does not
                            // fit with the restriction defined in the custom hint template
                            // A hint template that doesn't include a restriction is still acceptable
                            var tagsForHintXmlString:String = (hintXmlForLabel.hasOwnProperty("@tags")) ?
                                hintXmlForLabel.@tags : null;
                            var tagsListInHintTemplate:Array = (tagsForHintXmlString != null) ? tagsForHintXmlString.split(" ") : [];
                            var allTagsSatisfied:Boolean = true;
                            for each (var tagInHintTemplate:String in tagsListInHintTemplate)
                            {
                                // Template has a tag the problem has not specified
                                // It should not be used
                                if (tagsInProblem.indexOf(tagInHintTemplate) < 0)
                                {
                                    allTagsSatisfied = false;
                                    break;
                                }
                            }
                            
                            if (allTagsSatisfied)
                            {
                                // Some templates might need to be replicated to make several hints at a step. For example, in addition problems
                                // with multiple parts we may need a template saying "Add itemX", where itemX can be multiple things.
                                // The problem data needs to list all the possibilities for itemX to create the multiple hints
                                // The template looks like <template replicateFor=itemX/>
                                // The problem data looks like itemX: {names:[], docIds:[]}
                                if (hintXmlForLabel.hasOwnProperty("@replicateFor"))
                                {
                                    var replicateProperty:String = hintXmlForLabel.@replicateFor;
                                    if (hintDataForLevel.hasOwnProperty("replicaReplacements") && hintDataForLevel["replicaReplacements"].hasOwnProperty(replicateProperty))
                                    {
                                        var replicationData:Object = hintDataForLevel["replicaReplacements"][replicateProperty];
                                        var numReplications:int = replicationData.names.length;
                                        for (var i:int = 0; i < numReplications; i++)
                                        {
                                            var targetDocIdForReplica:String = replicationData.docIds[i];
                                            var doCreateReplica:Boolean = false;
                                            if (tagsListInHintTemplate.indexOf("partIsVariable") >= 0)
                                            {
                                                doCreateReplica = (targetDocIdForReplica.indexOf("unk") == 0 || targetDocIdForReplica.indexOf("c") == 0);
                                            }
                                            else if (tagsListInHintTemplate.indexOf("partIsNumber") >= 0)
                                            {
                                                doCreateReplica = !(targetDocIdForReplica.indexOf("unk") == 0 || targetDocIdForReplica.indexOf("c") == 0);
                                            }
                                            else
                                            {
                                                doCreateReplica = true;
                                            }
                                            
                                            if (doCreateReplica)
                                            {
                                                var replicaXML:XML = createCustomHintXML(step, hintXmlForLabel, generalTermsToNumbersMap, hintDataForLevel);
                                                var replicaText:String = replicaXML.text();
                                                replicaXML.setChildren(replicaText.replace(new RegExp("#" + replicateProperty, "g"), replicationData.names[i]));
                                                replicaXML.@targetMissingDocId = replicationData.docIds[i];
                                                generatedCustomHints.appendChild(replicaXML);
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    generatedCustomHints.appendChild(createCustomHintXML(step, hintXmlForLabel, generalTermsToNumbersMap, hintDataForLevel));
                                }
                            }
                        }
                    }
                }
            }
            
            return generatedCustomHints;
        }
        
        private function createCustomHintXML(step:String, 
                                             hintTemplateXML:XML, 
                                             generalTermsToNumbersMap:Object, 
                                             hintDataForLevel:Object):XML
        {
            var generatedHintForLabel:XML = <hint/>;
            generatedHintForLabel.@step = step;
            
            // The text content has regions that should be replaced with word or phrases
            // that are specific to that problem
            var textContentForHint:String = hintTemplateXML.text();
            if (hintDataForLevel != null && hintDataForLevel.hasOwnProperty("replacements"))
            {
                var hintReplacements:Object = hintDataForLevel["replacements"];
                for (var replacement:String in hintReplacements)
                {
                    var textToReplaceWith:String = hintReplacements[replacement];
                    if (replacement == "containerNameSingle")
                    {
                        replacement = "containerSingle";
                    }
                    
                    var replacementRegex:RegExp = new RegExp("#" + replacement, "g");
                    textContentForHint = textContentForHint.replace(replacementRegex, textToReplaceWith);
                }
            }
            
            for (var generalTermToReplace:String in generalTermsToNumbersMap)
            {
                replacementRegex = new RegExp("#" + generalTermToReplace, "g");
                textContentForHint = textContentForHint.replace(replacementRegex, generalTermsToNumbersMap[generalTermToReplace]);
            }
            
            generatedHintForLabel.appendChild(textContentForHint);
            return generatedHintForLabel
        }
    }
}