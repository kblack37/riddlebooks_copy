package wordproblem.engine.text
{
    import starling.display.DisplayObject;
    
    import wordproblem.engine.text.model.DocumentNode;
    import wordproblem.engine.text.view.DocumentView;

    public class TextParserUtil
    {
        private static const WHITE_SPACE_REGEX:RegExp = /\s+/g;
        
        /**
         * The parse resource string is formatted like this
         * {
         * type: url or embed
         * name: the location where to find the resource and the id to the asset manager
         * }
         * 
         * @return
         *      A list of objects describing the resource.
         *      In particular it has the loading type and id string
         *      Empty list if source is null
         */
        public static function parseResourceSourceString(source:String):Vector.<Object>
        {
            const resourceObjects:Vector.<Object> = new Vector.<Object>();
            
            // First remove all whitespace
            if (source != null)
            {
                source = source.replace(WHITE_SPACE_REGEX, "");
                
                // The source might reference a list of resources, we need to parse out each
                // individual element. We assume the end of an element is when we encounter
                // a closing paren.
                var i:int;
                var numCharacters:int = source.length;
                var startIndexOfResource:int = -1;
                for (i = 0; i < numCharacters; i++)
                {
                    const currentCharacter:String = source.charAt(i);
                    
                    // Ignore the commas separating the sources
                    if (startIndexOfResource < 0 && currentCharacter != ",")
                    {
                        startIndexOfResource = i;
                    }
                        // Encountering a closing paren, we take the substring going
                        // from the last starting index to here. (Ignore last paren)
                    else if (currentCharacter == ")")
                    {
                        // The indicator of how to fetch the resource is the sequence of text just
                        // before the opening parens. This will produce the loading type, which is a url or embedded
                        // The actual content string is just after the open paren
                        const sourcePieces:Array = source.substring(startIndexOfResource, i).split("(");
                        const sourceObject:Object = {
                            type:sourcePieces[0],
                            name:sourcePieces[1]
                        };
                        resourceObjects.push(sourceObject);
                        
                        startIndexOfResource = -1;
                    }
                }
            }
            
            return resourceObjects;
        }
        
        /**
         * Immediately create a view from xml content. The xml should follow the same format as
         * the content within a level
         * 
         * @param content
         *      xml to be parsed and displayed, has same properties and structure as text in the main
         *      level body
         * @param style
         *      css-like styling object to be applied to the content, has same properties and structure
         *      as styles used in the main level body
         * @param width
         *      Max default width to give to the content if not defined in the content
         * @return
         *      Root node view for the new xml
         *      
         */
        public static function createTextViewFromXML(content:XML, 
                                                     style:Object, 
                                                     width:Number, 
                                                     textParser:TextParser, 
                                                     textViewFactory:TextViewFactory):DisplayObject
        {
            // Parse the content
            var dialogNode:DocumentNode = textParser.parseDocument(content, width);
            textParser.applyStyleAndLayout(dialogNode, style);
            var dialogView:DocumentView = textViewFactory.createView(dialogNode);
            
            return dialogView;
        }
    }
}