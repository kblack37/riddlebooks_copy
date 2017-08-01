package wordproblem.hints;

import haxe.xml.Fast;

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
class CustomHintGenerator
{
    private var m_customHintTemplateXml : Fast;
    
    /**
     * Mapping for a string id of a hint template to the xml element containing all the data
     * for that template. Use this to generate the appropriate hint.
     */
    private var m_hintLabelIdToHintXmlListMap : Dynamic;
    
    /**
     * Mapping from the string bar model type to a list of xml elements
     * containing label id and step. The are the hint valid for that type
     */
    private var m_barModelTypeToLabelIdListMap : Dynamic;
    
    public function new(customHintTemplateXml : Fast)
    {
        m_customHintTemplateXml = customHintTemplateXml;
        
        // Do some pre-processing on the template xml.
        // Each bar model type should link to a list of hint ids that represent the
        // pool of candidate hints that might be useful to show to the player.
		var barModelHintBlocks = customHintTemplateXml.nodes.barmodelhints;
        m_hintLabelIdToHintXmlListMap = { };
        for (barModelHintBlock in barModelHintBlocks){
			var hintElements = barModelHintBlock.nodes.hint;
			
            for (hintElement in hintElements){
                // Create the mapping from label to step based on the selected block
				var hintLabelId : String = hintElement.att.labelId;
                if (!m_hintLabelIdToHintXmlListMap.exists(hintLabelId)) 
                {
                    Reflect.setField(m_hintLabelIdToHintXmlListMap, hintLabelId, new Array<Fast>());
                }
                
                var hintXmlListForId : Array<Fast> = Reflect.field(m_hintLabelIdToHintXmlListMap, hintLabelId);
                hintXmlListForId.push(hintElement);
            }
        }
        
        m_barModelTypeToLabelIdListMap = { };
		var typeToHintsMappings = customHintTemplateXml.nodes.mapping;
        for (mappingBlock in typeToHintsMappings) {
            var hintLabels : Array<Fast> = new Array<Fast>();
			var mappingElements = mappingBlock.nodes.label;
            for (mappingElement in mappingElements){
                hintLabels.push(mappingElement);
            }
            
			var typeAttribute : String = mappingBlock.att.type;
            var typesForMapping : Array<String> = StringTools.replace(typeAttribute, " ", "").split(",");
            for (barModelType in typesForMapping)
            {
                if (barModelType != null && barModelType.length > 0) 
                {
                    Reflect.setField(m_barModelTypeToLabelIdListMap, Std.string(barModelType), hintLabels);
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
    public function generateHintsForLevel(barModelTypeForLevel : String,
            docIdToValueMap : Dynamic,
            hintDataForLevel : Dynamic) : Fast
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
        var generalTermsToNumbersMap : Dynamic = { };
        
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
        var tagsInProblem : Array<Dynamic> = ((hintDataForLevel.exists("tags"))) ? 
        Reflect.field(hintDataForLevel, "tags") : [];
        
        if (barModelTypeForLevel == BarModelTypes.TYPE_1A) 
        {
            // TODO: We are expecting some other part of the application to send us a mapping
            // from tagged document id to the actual numeric value
            Reflect.setField(generalTermsToNumbersMap, "total", Reflect.field(docIdToValueMap, "unk"));
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
            { }
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
            Reflect.setField(generalTermsToNumbersMap, "numGroups", Reflect.field(docIdToValueMap, "b1"));
            Reflect.setField(generalTermsToNumbersMap, "unitValue", Reflect.field(docIdToValueMap, "a1"));
            tagsInProblem.push("totalIsVariable");
        }
        else if (barModelTypeForLevel == BarModelTypes.TYPE_3B) 
        {
            Reflect.setField(generalTermsToNumbersMap, "numGroups", Reflect.field(docIdToValueMap, "a1"));
            Reflect.setField(generalTermsToNumbersMap, "total", Reflect.field(docIdToValueMap, "b1"));
        }
        else if (barModelTypeForLevel == BarModelTypes.TYPE_4A) 
        {
            Reflect.setField(generalTermsToNumbersMap, "numGroups", Reflect.field(docIdToValueMap, "b1"));
            Reflect.setField(generalTermsToNumbersMap, "unitValue", Reflect.field(docIdToValueMap, "a1"));
            tagsInProblem.push("totalIsVariable");
        }
        else if (barModelTypeForLevel == BarModelTypes.TYPE_4B) 
        {
            Reflect.setField(generalTermsToNumbersMap, "numGroups", Reflect.field(docIdToValueMap, "b1"));
            Reflect.setField(generalTermsToNumbersMap, "total", Reflect.field(docIdToValueMap, "a1"));
        }
        else if (barModelTypeForLevel == BarModelTypes.TYPE_4C) 
        {
            Reflect.setField(generalTermsToNumbersMap, "numGroups", Reflect.field(docIdToValueMap, "b1"));
            Reflect.setField(generalTermsToNumbersMap, "unitValue", Reflect.field(docIdToValueMap, "a1"));
        }
        else if (barModelTypeForLevel == BarModelTypes.TYPE_4D) 
        {
            Reflect.setField(generalTermsToNumbersMap, "numGroups", Reflect.field(docIdToValueMap, "b1"));
            Reflect.setField(generalTermsToNumbersMap, "unitValue", Reflect.field(docIdToValueMap, "a1"));
        }
        else if (barModelTypeForLevel == BarModelTypes.TYPE_4E) 
        {
            Reflect.setField(generalTermsToNumbersMap, "numGroups", Reflect.field(docIdToValueMap, "b1"));
            Reflect.setField(generalTermsToNumbersMap, "difference", Reflect.field(docIdToValueMap, "a1"));
        }
        else if (barModelTypeForLevel == BarModelTypes.TYPE_4F) 
        {
            Reflect.setField(generalTermsToNumbersMap, "numGroups", Reflect.field(docIdToValueMap, "b1"));
            Reflect.setField(generalTermsToNumbersMap, "total", Reflect.field(docIdToValueMap, "a1"));
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
            Reflect.setField(generalTermsToNumbersMap, "numGroups", Reflect.field(docIdToValueMap, "b1"));
        }
        else if (barModelTypeForLevel == BarModelTypes.TYPE_5G) 
        {
            tagsInProblem.push("totalIsVariable");
            Reflect.setField(generalTermsToNumbersMap, "numGroups", Reflect.field(docIdToValueMap, "b1"));
        }
        else if (barModelTypeForLevel == BarModelTypes.TYPE_5H) 
        {
            tagsInProblem.push("totalIsVariable");
            Reflect.setField(generalTermsToNumbersMap, "numGroups", Reflect.field(docIdToValueMap, "b1"));
        }
        else if (barModelTypeForLevel == BarModelTypes.TYPE_5I) 
        {
            tagsInProblem.push("totalIsVariable");
            Reflect.setField(generalTermsToNumbersMap, "numGroups", Reflect.field(docIdToValueMap, "b1"));
        }
        else if (barModelTypeForLevel == BarModelTypes.TYPE_5J) 
        {
            tagsInProblem.push("totalIsVariable");
            Reflect.setField(generalTermsToNumbersMap, "numGroups", Reflect.field(docIdToValueMap, "b1"));
        }
        else if (barModelTypeForLevel == BarModelTypes.TYPE_5K) 
        {
            tagsInProblem.push("differenceIsVariable");
            Reflect.setField(generalTermsToNumbersMap, "numGroups", Reflect.field(docIdToValueMap, "b1"));
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
		
        // Need to deal with the situation where a hint template slightly changes depending on variations in the user bar model
        // In the previous turk hinting system, there was a need for existing bar model value. How would that apply here?
        // It will be up to the problem data to tell us to create multiple copies of a particular hint, the template will need
        // Essentially we will need a hint template that splits into more templates
        // ex.) You need to add the number of <noun x>, where <noun x> can be several things
        // The way to handle this:
        // A particular hint template will need know that there are multiple similar variations that can be applied to it
        // Within the properties of the problem we need to list all the variations need
        // <noun x> = #noun-a, #noun-b, #noun-c
        else if (barModelTypeForLevel == BarModelTypes.TYPE_7G) 
        {
            tagsInProblem.push("totalIsVariable");
            tagsInProblem.push("differenceIsNumber");
        }
        
        var generatedCustomHints : Fast = new Fast(Xml.parse("<customHints/>"));
        if (m_barModelTypeToLabelIdListMap.exists(barModelTypeForLevel)) 
        {
            var labelIdList : Array<Fast> = Reflect.field(m_barModelTypeToLabelIdListMap, barModelTypeForLevel);
            for (labelIdElement in labelIdList)
            {
                var labelId : String = labelIdElement.att.id;
                var step : String = labelIdElement.att.step;
                
                if (m_hintLabelIdToHintXmlListMap.exists(labelId)) 
                {
                    var hintXmlsForLabel : Array<Fast> = Reflect.field(m_hintLabelIdToHintXmlListMap, labelId);
                    for (hintXmlForLabel in hintXmlsForLabel)
                    {
                        // Skip over this hint if the type restriction tags for this particular problem does not
                        // fit with the restriction defined in the custom hint template
                        // A hint template that doesn't include a restriction is still acceptable
                        var tagsForHintXmlString : String = hintXmlForLabel.has.tags ? hintXmlForLabel.att.tags : null;
                        var tagsListInHintTemplate : Array<Dynamic> = ((tagsForHintXmlString != null)) ? tagsForHintXmlString.split(" ") : [];
                        var allTagsSatisfied : Bool = true;
                        for (tagInHintTemplate in tagsListInHintTemplate)
                        {
                            // Template has a tag the problem has not specified
                            // It should not be used
                            if (Lambda.indexOf(tagsInProblem, tagInHintTemplate) < 0) 
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
                            if (hintXmlForLabel.has.replicateFor) 
                            {
                                var replicateProperty : String = hintXmlForLabel.att.replicateFor;
                                if (hintDataForLevel.exists("replicaReplacements") && Reflect.field(hintDataForLevel, "replicaReplacements").exists(replicateProperty)) 
                                {
                                    var replicationData : Dynamic = Reflect.field(Reflect.field(hintDataForLevel, "replicaReplacements"), replicateProperty);
                                    var numReplications : Int = replicationData.names.length;
                                    for (i in 0...numReplications){
                                        var targetDocIdForReplica : String = replicationData.docIds[i];
                                        var doCreateReplica : Bool = false;
                                        if (Lambda.indexOf(tagsListInHintTemplate, "partIsVariable") >= 0) 
                                        {
                                            doCreateReplica = (targetDocIdForReplica.indexOf("unk") == 0 || targetDocIdForReplica.indexOf("c") == 0);
                                        }
                                        else if (Lambda.indexOf(tagsListInHintTemplate, "partIsNumber") >= 0) 
                                        {
                                            doCreateReplica = !(targetDocIdForReplica.indexOf("unk") == 0 || targetDocIdForReplica.indexOf("c") == 0);
                                        }
                                        else 
                                        {
                                            doCreateReplica = true;
                                        }
                                        
                                        if (doCreateReplica) 
                                        {
                                            var replicaXML : Fast = createCustomHintXML(step, hintXmlForLabel, generalTermsToNumbersMap, hintDataForLevel);
                                            var replicaText : String = replicaXML.innerData;
											for (xml in replicaXML.elements) {
												xml.x.nodeValue = (new EReg("#" + replicateProperty, "g")).replace(replicaText, replicationData.names[i]);
											}
                                            replicaXML.x.set("targetMissingDocId", replicationData.docIds[i]);
                                            generatedCustomHints.x.addChild(replicaXML.x);
                                        }
                                    }
                                }
                            }
                            else 
                            {
                                generatedCustomHints.x.addChild(createCustomHintXML(step, hintXmlForLabel, generalTermsToNumbersMap, hintDataForLevel).x);
                            }
                        }
                    }
                }
            }
        }
        
        return generatedCustomHints;
    }
    
    private function createCustomHintXML(step : String,
            hintTemplateXML : Fast,
            generalTermsToNumbersMap : Dynamic,
            hintDataForLevel : Dynamic) : Fast
    {
        var generatedHintForLabel : Xml = Xml.parse("<hint/>");
        generatedHintForLabel.set("step", step);
        
        // The text content has regions that should be replaced with word or phrases
        // that are specific to that problem
        var textContentForHint : String = hintTemplateXML.node.text.innerData;
        if (hintDataForLevel != null && hintDataForLevel.exists("replacements")) 
        {
            var hintReplacements : Dynamic = Reflect.field(hintDataForLevel, "replacements");
            for (replacement in Reflect.fields(hintReplacements))
            {
                var textToReplaceWith : String = Reflect.field(hintReplacements, replacement);
                if (replacement == "containerNameSingle") 
                {
                    replacement = "containerSingle";
                }
                
                var replacementRegex : EReg = new EReg("#" + replacement, "g");
                textContentForHint = replacementRegex.replace(textContentForHint, textToReplaceWith);
            }
        }
        
        for (generalTermToReplace in Reflect.fields(generalTermsToNumbersMap))
        {
            var replacementRegex = new EReg("#" + generalTermToReplace, "g");
            textContentForHint = replacementRegex.replace(textContentForHint, Reflect.field(generalTermsToNumbersMap, generalTermToReplace));
        }
        
		generatedHintForLabel.addChild(Xml.createPCData(textContentForHint));
        return new Fast(generatedHintForLabel);
    }
}
