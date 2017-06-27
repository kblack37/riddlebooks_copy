package wordproblem.creator
{
    import wordproblem.engine.barmodel.BarModelTypeDrawerProperties;
    import wordproblem.engine.text.MeasuringTextField;

    /**
     * Static helper function that we might want to refactor into classes later
     */
    public class WordProblemCreateUtil
    {
        public function WordProblemCreateUtil()
        {
        }
        
        /**
         *
         * @param outErrors
         *      A list of error strings caused by restriction values
         * @return
         *      True if the given value passes all the restrictions and checks
         */
        public static function checkValueValid(properties:BarModelTypeDrawerProperties, value:String, outErrors:Object=null):Boolean
        {
            var errorValues:Array = [];
            var valueValid:Boolean = true;
            var restrictions:Object = properties.restrictions;
            var typeClass:Class = restrictions.type;
            if (typeClass === String)
            {
                // Values that are just variable can really be anything
            }
            else if (typeClass === Number || typeClass === int)
            {
                // Numeric values may have several restriction
                var extractedNumber:Number = parseFloat(value);
                if (!isNaN(extractedNumber))
                {
                    if (restrictions.hasOwnProperty("min") && extractedNumber < restrictions["min"])
                    {
                        errorValues.push("Must be greater than " + restrictions["min"]);
                        valueValid = false;
                    }
                    
                    if (restrictions.hasOwnProperty("max") && extractedNumber > restrictions["max"])
                    {
                        errorValues.push("Must be less than " + restrictions["max"]);
                        valueValid = false;
                    }
                    
                    // If an integer, make sure the extracted value has no decimal values
                    if (typeClass === int && (extractedNumber - Math.floor(extractedNumber)) > 0.00001)
                    {
                        errorValues.push("Must be a whole number");
                        valueValid = false;
                    }
                }
                else
                {
                    errorValues.push("Must be a number");
                    valueValid = false;
                }
            }
            
            if (outErrors != null)
            {
                outErrors["errors"] = errorValues;
            }
            return valueValid;
        }
        
        /**
         *
         * @return
         *      List of objects with id, value pairings of the highlights added
         */
        public static function addTextFromXmlToBlock(xml:XML, 
                                                     textArea:EditableTextArea, 
                                                     blockIndex:int, 
                                                     stylePropertiesForHighlight:Object):Vector.<Object>
        {
            var outHighlightWordsDataInBlock:Vector.<Object> = new Vector.<Object>();
            calculateWordIndices(xml, outHighlightWordsDataInBlock, 0);
            
            var measuringText:MeasuringTextField = new MeasuringTextField();
            measuringText.htmlText = xml.toString();
            
            // For the appropriate areas of the text to be highlighted we need to be able to
            // convert the word indices to the actual character indices
            // From the content we can just create a mapping from word index to the start and
            // end character index for that word
            var untaggedContent:String = measuringText.text;
            
            // The html text conversion in flash does not completely format things as we want, the span
            // tags cause extra line breaks and spaces within the text content.
            // Strip out line breaks
            untaggedContent = untaggedContent.replace(/[\n\r]/g, "");
            
            // Replace double spaces
            untaggedContent = untaggedContent.replace(/\s\s/g, " ");
            var wordIndexToCharacterIndex:Vector.<Object> = new Vector.<Object>();
            var numCharacters:int = untaggedContent.length;
            var startCharacterIndexOfWord:int = 0;
            var inMiddleOfWord:Boolean = false;
            var charIndex:int;
            for (charIndex = 0; charIndex < numCharacters; charIndex++)
            {
                var characterAtIndex:String = untaggedContent.charAt(charIndex);
                if (characterAtIndex.search(/[\s\n\r]/) != -1)
                {
                    // Treat white space as an indicator for the end of a word
                    if (inMiddleOfWord)
                    {
                        wordIndexToCharacterIndex.push({start: startCharacterIndexOfWord, end: charIndex - 1});
                        inMiddleOfWord = false;
                    }
                }
                else
                {
                    if (!inMiddleOfWord)
                    {
                        inMiddleOfWord = true;
                        startCharacterIndexOfWord = charIndex;
                    }
                }
            }
            
            // Add the word at the end
            if (inMiddleOfWord)
            {
                wordIndexToCharacterIndex.push({start: startCharacterIndexOfWord, end: numCharacters - 1});
            }
            
            textArea.setText(untaggedContent, blockIndex);
            
            // TODO: Should not need to do this every time.
            // Need to make sure the blocks are laid out before drawing the highlight
            // since the highlights rely on positioning
            textArea.layoutTextBlocks();
            
            for each (var highlightWordsData:Object in outHighlightWordsDataInBlock)
            {
                var wordHighlightId:String = highlightWordsData.id;
                var wordStartIndex:int = highlightWordsData.start;
                var wordEndIndex:int = highlightWordsData.end;
                
                var startingWordCharacters:Object = wordIndexToCharacterIndex[wordStartIndex];
                var endingWordCharacters:Object = wordIndexToCharacterIndex[wordEndIndex];
                var startCharacterIndex:int = startingWordCharacters.start;
                var endCharacterIndex:int = endingWordCharacters.end;
                textArea.highlightWordsAtIndices(
                    startCharacterIndex, 
                    endCharacterIndex, 
                    stylePropertiesForHighlight[wordHighlightId].color, 
                    wordHighlightId,
                    blockIndex,
                    true
                );
            }
            
            return outHighlightWordsDataInBlock;
        }
        
        /**
         * Current word index needs to constantly be accessible and updated as the 
         * recursive function is continuing.
         * 
         * (NOTE: This function assumes the highlighted spans do not overlap)
         * 
         * @return
         *      The character index after traversing all the text contained in the passed in element
         */
        private static function calculateWordIndices(element:XML, outData:Vector.<Object>, startingWordIndex:int):int
        {
            // Simple parsing of xml and counting character indices via the text nodes in
            // the xml is not accurate enough. It does not account for whitespace that
            // occurs between elements. It seems the whitespace between the element tags is ignored so
            // those character would be ignored in the count.
            
            // The work around is to instead rely on word indices.
            var wordIndex:int = startingWordIndex;
            var tagName:String = element.name();
            
            // We assume a null tag name is associated with text elements
            if (tagName == null)
            {
                var words:Array = element.toString().split(/\s+/g);
                for each (var word:String in words)
                {
                    if (word != "")
                    {
                        wordIndex++;
                    }
                }
            }
            
            var childElements:XMLList = element.children();
            var numChildElements:int = childElements.length();
            for (var i:int = 0; i < numChildElements; i++)
            {
                var childElement:XML = childElements[i];
                wordIndex = calculateWordIndices(childElement, outData, wordIndex);
            }
            
            // TODO: Handle case where a span has multiple words
            // An element only has text if it is a 'direct' child
            if (tagName == "span" && element.attribute("class") == "term")
            {
                var highlightedTextData:Object = {
                    id: element.attribute("id"),
                        start: startingWordIndex,
                        end: wordIndex - 1
                };
                
                // Add extra value tag that associates the alias name to the element id
                if (element.hasOwnProperty("@value"))
                {
                    highlightedTextData.value = element.@value;    
                }
                outData.push(highlightedTextData);
            }
            
            return wordIndex;
        }
        
        /**
         * Convert the html text pulled from the textfield to a standardized
         * format that can be saved to a database
         */
        public static function createSaveableXMLFromTextfieldText(rawHtmlText:String, elementIdToAliasName:Object):String
        {
            // HACK: The easiest way to create a span on the highlighted word is to set a text format
            // around the important text.
            // We can piggyback off a property in the text format call 'url', this creates an anchor
            // tag around the text
            
            // Need to recursively parse through the tags
            var outputXml:XML = convertElements(new XML("<root>" + rawHtmlText + "</root>"));
            
            // First strip out tags that are not needed by the Level generation pipeline.
            return removeUnnecessaryTaggedElements(outputXml, elementIdToAliasName);
        }
        
        /**
         * Function used to convert an element created by the default flash player textfield
         * when showing contents as html to an element used by our own level parsing logic
         * 
         * @return
         *      A new corresponding element necessary in a bar model level
         */
        private static function convertElements(element:XML):XML
        {
            var newElement:XML = null;
            var elementName:String = element.name();
            if (elementName == "root")
            {
                newElement = <page></page>;   
            }
            else if (elementName == "P")
            {
                newElement = <p></p>;
            }
            else if (elementName == "FONT")
            {
                var fontFamily:String = element.attribute("FACE");
                var fontSize:String = element.attribute("SIZE");
                var fontColor:String = element.attribute("COLOR");
                newElement = <span></span>;
                
            }
            else if (elementName == "A")
            {
                var id:String = element.attribute("HREF");
                newElement = <span></span>;
                newElement.@["id"] = id;
                newElement.@["class"] = "term";
            }
            else
            {
                // Text content does not have any name
                newElement = new XML(element.toString());
            }
            
            var childElements:XMLList = element.children();
            var i:int;
            var numChildren:int = childElements.length();
            for (i = 0; i < numChildren; i++)
            {
                var childElement:XML = childElements[i];
                newElement.appendChild(convertElements(childElement));
            }
            
            return newElement;
        }
        
        /**
         * Strip out elements in the given xml that do not match up with anything
         * that is necessary in a generating a level.\
         * 
         * @return
         *      A string version of the xml
         */
        private static function removeUnnecessaryTaggedElements(probxml:XML, 
                                                         elementIdToAliasName:Object):String 
        {
            var problemText:String = "";
            var childElms:XMLList = probxml.children();
            
            var i:int;
            var numChildren:int = childElms.length();
            for (i = 0; i < numChildren; i++)
            {
                if (childElms[i].name() == "p")
                {
                    problemText += paragraphText(childElms[i], elementIdToAliasName);
                }
            }
            return problemText;
        }
        
        private static function paragraphText(paraElm:XML, elementIdToAliasName:Object):String 
        {
            var paraText:String = "";
            if (paraElm.nodeKind() == "text")
            {
                paraText = paraElm.toString();
            }
            else
            {
                var paraChildren:XMLList = paraElm.children();
                var i:int;
                var numChildren:int = paraChildren.length();
                for (i = 0; i < numChildren; i++)
                {
                    paraText += spanText(paraChildren[i], elementIdToAliasName);
                }
            }
            
            return paraText;
        }
        
        private static function spanText(spanElm:XML, elementIdToAliasName:Object):String 
        {
            var spanTxt:String = "";
            
            if (spanElm.nodeKind() == "text")
            {
                spanTxt += spanElm.toString() + " ";
            }
            else if (spanElm.name() == "span")  
            {
                if (spanElm.attribute("class").length() > 0) 
                {  
                    // Rename the ids of the spanned text to the document id pattern
                    // used by all other bar model levels
                    var originalSpanId:String = spanElm.@id;
                    if (originalSpanId == "a") 
                    {
                        spanElm.@id = "a1";
                    }
                    if (originalSpanId == "b") 
                    {
                        spanElm.@id = "b1";
                    }
                    if (originalSpanId == "?") 
                    {
                        spanElm.@id = "unk";
                    }
                    
                    // Add any applicable alias to terms where the text content is too long
                    // to be added on a card.
                    // This requires adding the alias attribute to the appropriate span
                    if (elementIdToAliasName.hasOwnProperty(originalSpanId))
                    {
                        spanElm.@alias = elementIdToAliasName[originalSpanId];
                    }
                    
                    spanTxt += spanElm.toXMLString();
                }
                else 
                { 
                    // this is span that is just a wrapper for text and other tagged elements
                    var spanChildren:XMLList = spanElm.children();
                    var j:int;
                    var spanChildLength:int = spanChildren.length();
                    for (j = 0; j < spanChildLength; j++)
                    {
                        spanTxt += spanText(spanChildren[j], elementIdToAliasName);
                    }
                }
            }
            return spanTxt;
        }
    }
}