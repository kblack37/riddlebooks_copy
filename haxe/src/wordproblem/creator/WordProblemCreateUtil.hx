package wordproblem.creator;


import wordproblem.engine.barmodel.BarModelTypeDrawerProperties;
import wordproblem.engine.text.MeasuringTextField;

/**
 * Static helper function that we might want to refactor into classes later
 */
class WordProblemCreateUtil
{
    public function new()
    {
    }
    
    /**
     *
     * @param outErrors
     *      A list of error strings caused by restriction values
     * @return
     *      True if the given value passes all the restrictions and checks
     */
    public static function checkValueValid(properties : BarModelTypeDrawerProperties, value : String, outErrors : Dynamic = null) : Bool
    {
        var errorValues : Array<Dynamic> = [];
        var valueValid : Bool = true;
        var restrictions : Dynamic = properties.restrictions;
        var typeClass : Class<Dynamic> = restrictions.type;
        if (typeClass == String) 
        {
            // Values that are just variable can really be anything
            
        }
        else if (typeClass == Float || typeClass == Int) 
        {
            // Numeric values may have several restriction
            var extractedNumber : Float = parseFloat(value);
            if (!Math.isNaN(extractedNumber)) 
            {
                if (restrictions.exists("min") && extractedNumber < Reflect.field(restrictions, "min")) 
                {
                    errorValues.push("Must be greater than " + Reflect.field(restrictions, "min"));
                    valueValid = false;
                }
                
                if (restrictions.exists("max") && extractedNumber > Reflect.field(restrictions, "max")) 
                {
                    errorValues.push("Must be less than " + Reflect.field(restrictions, "max"));
                    valueValid = false;
                }  // If an integer, make sure the extracted value has no decimal values  
                
                
                
                if (typeClass == Int && (extractedNumber - Math.floor(extractedNumber)) > 0.00001) 
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
            Reflect.setField(outErrors, "errors", errorValues);
        }
        return valueValid;
    }
    
    /**
     *
     * @return
     *      List of objects with id, value pairings of the highlights added
     */
    public static function addTextFromXmlToBlock(xml : FastXML,
            textArea : EditableTextArea,
            blockIndex : Int,
            stylePropertiesForHighlight : Dynamic) : Array<Dynamic>
    {
        var outHighlightWordsDataInBlock : Array<Dynamic> = new Array<Dynamic>();
        calculateWordIndices(xml, outHighlightWordsDataInBlock, 0);
        
        var measuringText : MeasuringTextField = new MeasuringTextField();
        measuringText.htmlText = Std.string(xml);
        
        // For the appropriate areas of the text to be highlighted we need to be able to
        // convert the word indices to the actual character indices
        // From the content we can just create a mapping from word index to the start and
        // end character index for that word
        var untaggedContent : String = measuringText.text;
        
        // The html text conversion in flash does not completely format things as we want, the span
        // tags cause extra line breaks and spaces within the text content.
        // Strip out line breaks
        untaggedContent = untaggedContent.replace(new EReg('[\\n\\r]', "g"), "");
        
        // Replace double spaces
        untaggedContent = untaggedContent.replace(new EReg('\\s\\s', "g"), " ");
        var wordIndexToCharacterIndex : Array<Dynamic> = new Array<Dynamic>();
        var numCharacters : Int = untaggedContent.length;
        var startCharacterIndexOfWord : Int = 0;
        var inMiddleOfWord : Bool = false;
        var charIndex : Int = 0;
        for (charIndex in 0...numCharacters){
            var characterAtIndex : String = untaggedContent.charAt(charIndex);
            if (characterAtIndex.search(new EReg('[\\s\\n\\r]', "")) != -1) 
            {
                // Treat white space as an indicator for the end of a word
                if (inMiddleOfWord) 
                {
                    wordIndexToCharacterIndex.push({
                                start : startCharacterIndexOfWord,
                                end : charIndex - 1,

                            });
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
        }  // Add the word at the end  
        
        
        
        if (inMiddleOfWord) 
        {
            wordIndexToCharacterIndex.push({
                        start : startCharacterIndexOfWord,
                        end : numCharacters - 1,

                    });
        }
        
        textArea.setText(untaggedContent, blockIndex);
        
        // TODO: Should not need to do this every time.
        // Need to make sure the blocks are laid out before drawing the highlight
        // since the highlights rely on positioning
        textArea.layoutTextBlocks();
        
        for (highlightWordsData in outHighlightWordsDataInBlock)
        {
            var wordHighlightId : String = highlightWordsData.id;
            var wordStartIndex : Int = highlightWordsData.start;
            var wordEndIndex : Int = highlightWordsData.end;
            
            var startingWordCharacters : Dynamic = wordIndexToCharacterIndex[wordStartIndex];
            var endingWordCharacters : Dynamic = wordIndexToCharacterIndex[wordEndIndex];
            var startCharacterIndex : Int = startingWordCharacters.start;
            var endCharacterIndex : Int = endingWordCharacters.end;
            textArea.highlightWordsAtIndices(
                    startCharacterIndex,
                    endCharacterIndex,
                    Reflect.field(stylePropertiesForHighlight, wordHighlightId).color,
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
    private static function calculateWordIndices(element : FastXML, outData : Array<Dynamic>, startingWordIndex : Int) : Int
    {
        // Simple parsing of xml and counting character indices via the text nodes in
        // the xml is not accurate enough. It does not account for whitespace that
        // occurs between elements. It seems the whitespace between the element tags is ignored so
        // those character would be ignored in the count.
        
        // The work around is to instead rely on word indices.
        var wordIndex : Int = startingWordIndex;
        var tagName : String = element.node.name.innerData();
        
        // We assume a null tag name is associated with text elements
        if (tagName == null) 
        {
            var words : Array<Dynamic> = Std.string(element).split(new EReg('\\s+', "g"));
            for (word in words)
            {
                if (word != "") 
                {
                    wordIndex++;
                }
            }
        }
        
        var childElements : FastXMLList = element.node.children.innerData();
        var numChildElements : Int = childElements.length();
        for (i in 0...numChildElements){
            var childElement : FastXML = childElements.get(i);
            wordIndex = calculateWordIndices(childElement, outData, wordIndex);
        }  // An element only has text if it is a 'direct' child    // TODO: Handle case where a span has multiple words  
        
        
        
        
        
        if (tagName == "span" && element.node.attribute.innerData("class") == "term") 
        {
            var highlightedTextData : Dynamic = {
                id : element.node.attribute.innerData("id"),
                start : startingWordIndex,
                end : wordIndex - 1,

            };
            
            // Add extra value tag that associates the alias name to the element id
            if (element.node.exists.innerData("@value")) 
            {
                highlightedTextData.value = element.att.value;
            }
            outData.push(highlightedTextData);
        }
        
        return wordIndex;
    }
    
    /**
     * Convert the html text pulled from the textfield to a standardized
     * format that can be saved to a database
     */
    public static function createSaveableXMLFromTextfieldText(rawHtmlText : String, elementIdToAliasName : Dynamic) : String
    {
        // HACK: The easiest way to create a span on the highlighted word is to set a text format
        // around the important text.
        // We can piggyback off a property in the text format call 'url', this creates an anchor
        // tag around the text
        
        // Need to recursively parse through the tags
        var outputXml : FastXML = convertElements(new FastXML("<root>" + rawHtmlText + "</root>"));
        
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
    private static function convertElements(element : FastXML) : FastXML
    {
        var newElement : FastXML = null;
        var elementName : String = element.node.name.innerData();
        if (elementName == "root") 
        {
            newElement = FastXML.parse("<page></page>");
        }
        else if (elementName == "P") 
        {
            newElement = FastXML.parse("<p></p>");
        }
        else if (elementName == "FONT") 
        {
            var fontFamily : String = element.node.attribute.innerData("FACE");
            var fontSize : String = element.node.attribute.innerData("SIZE");
            var fontColor : String = element.node.attribute.innerData("COLOR");
            newElement = FastXML.parse("<span></span>");
        }
        else if (elementName == "A") 
        {
            var id : String = element.node.attribute.innerData("HREF");
            newElement = FastXML.parse("<span></span>");
            newElement.setAttribute("id", id);
            newElement.setAttribute("class", "term");
        }
        else 
        {
            // Text content does not have any name
            newElement = new FastXML(Std.string(element));
        }
        
        var childElements : FastXMLList = element.node.children.innerData();
        var i : Int = 0;
        var numChildren : Int = childElements.length();
        for (i in 0...numChildren){
            var childElement : FastXML = childElements.get(i);
            newElement.node.appendChild.innerData(convertElements(childElement));
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
    private static function removeUnnecessaryTaggedElements(probxml : FastXML,
            elementIdToAliasName : Dynamic) : String
    {
        var problemText : String = "";
        var childElms : FastXMLList = probxml.node.children.innerData();
        
        var i : Int = 0;
        var numChildren : Int = childElms.length();
        for (i in 0...numChildren){
            if (childElms.get(i).node.name.innerData() == "p") 
            {
                problemText += paragraphText(childElms.get(i), elementIdToAliasName);
            }
        }
        return problemText;
    }
    
    private static function paragraphText(paraElm : FastXML, elementIdToAliasName : Dynamic) : String
    {
        var paraText : String = "";
        if (paraElm.node.nodeKind.innerData() == "text") 
        {
            paraText = Std.string(paraElm);
        }
        else 
        {
            var paraChildren : FastXMLList = paraElm.node.children.innerData();
            var i : Int = 0;
            var numChildren : Int = paraChildren.length();
            for (i in 0...numChildren){
                paraText += spanText(paraChildren.get(i), elementIdToAliasName);
            }
        }
        
        return paraText;
    }
    
    private static function spanText(spanElm : FastXML, elementIdToAliasName : Dynamic) : String
    {
        var spanTxt : String = "";
        
        if (spanElm.node.nodeKind.innerData() == "text") 
        {
            spanTxt += Std.string(spanElm) + " ";
        }
        else if (spanElm.node.name.innerData() == "span") 
        {
            if (spanElm.node.attribute.innerData("class").length() > 0) 
            {
                // Rename the ids of the spanned text to the document id pattern
                // used by all other bar model levels
                var originalSpanId : String = spanElm.att.id;
                if (originalSpanId == "a") 
                {
                    spanElm.setAttribute("id", "a1");
                }
                if (originalSpanId == "b") 
                {
                    spanElm.setAttribute("id", "b1");
                }
                if (originalSpanId == "?") 
                {
                    spanElm.setAttribute("id", "unk");
                }  // This requires adding the alias attribute to the appropriate span    // to be added on a card.    // Add any applicable alias to terms where the text content is too long  
                
                
                
                
                
                
                
                if (elementIdToAliasName.exists(originalSpanId)) 
                {
                    spanElm.setAttribute("alias", Reflect.setField(elementIdToAliasName, originalSpanId, ));
                }
                
                spanTxt += spanElm.node.toXMLString.innerData();
            }
            else 
            {
                // this is span that is just a wrapper for text and other tagged elements
                var spanChildren : FastXMLList = spanElm.node.children.innerData();
                var j : Int = 0;
                var spanChildLength : Int = spanChildren.length();
                for (j in 0...spanChildLength){
                    spanTxt += spanText(spanChildren.get(j), elementIdToAliasName);
                }
            }
        }
        return spanTxt;
    }
}
