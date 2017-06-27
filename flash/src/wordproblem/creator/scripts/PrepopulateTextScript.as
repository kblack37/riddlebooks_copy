package wordproblem.creator.scripts
{
    import dragonbox.common.util.XString;
    
    import wordproblem.creator.EditableTextArea;
    import wordproblem.creator.ProblemCreateData;
    import wordproblem.creator.WordProblemCreateState;
    import wordproblem.creator.WordProblemCreateUtil;
    import wordproblem.engine.barmodel.BarModelTypeDrawer;
    
    /**
     * This script handles prepopulating the main text area with a partially completed wordproblem.
     * The logic is intended to provide scaffolding to the custom problem creation portion as
     * filling in missing sentences would be simpler than creating an entire original problem.
     * 
     * Prepopulated text should be configurable with a few settings. One is a text block may be marked
     * as immutable, player cannot change anything about. Another is the user may be able to highlight
     * portions of the text but not modify the text content.
     */
    public class PrepopulateTextScript extends BaseProblemCreateScript
    {
        public function PrepopulateTextScript(wordproblemCreateState:WordProblemCreateState,
                                              id:String=null, 
                                              isActive:Boolean=true)
        {
            super(wordproblemCreateState, null, id, isActive);
        }
        
        override public function dispose():void
        {
            super.dispose();
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            var textArea:EditableTextArea = m_createState.getWidgetFromId("editableTextArea") as EditableTextArea;
            
            // Fetch the wordproblem level data (this contains the information)
            var paragraphElements:Vector.<XML> = m_createState.getCurrentLevel().getPrepopulatedTextBlocks();
            
            if (paragraphElements.length == 0)
            {
                // If no text to pre-populate then create a single empty block that takes up the entire viewport
                textArea.addTextBlock(textArea.getConstraints().width, textArea.getConstraints().height, true, true);
            }
            else
            {
                var currentLevel:ProblemCreateData = m_createState.getCurrentLevel();
                var barModelType:String = currentLevel.barModelType;
                var barModelTypeDrawer:BarModelTypeDrawer = new BarModelTypeDrawer();
                var highlightColorsForBarPart:Object = (currentLevel.currentlySelectedBackgroundData.hasOwnProperty("highlightColors")) ?
                    currentLevel.currentlySelectedBackgroundData["highlightColors"] : null;
                var stylePropertiesForBarModelType:Object = barModelTypeDrawer.getStyleObjectForType(barModelType, highlightColorsForBarPart);
                
                var i:int;
                var numBlocks:int = paragraphElements.length;
                var availableVerticalSpace:Number = textArea.getConstraints().height;
                for (i = 0; i < paragraphElements.length; i++)
                {
                    var paragraphElement:XML = paragraphElements[i];
                    
                    // We expect the predefined text to potentially contain settings to define
                    // text dimensions as well as whether the block should be editable.
                    // Will need to do an initial pass to parse this information.
                    
                    // Default block height assumes even partitioning of remaining space
                    var blockHeight:Number = availableVerticalSpace / (numBlocks - i);
                    if (paragraphElement.hasOwnProperty("@height"))
                    {
                        blockHeight = paragraphElement.@height;
                    }
                    availableVerticalSpace -= blockHeight;
                    
                    var isEditable:Boolean = true;
                    if (paragraphElement.hasOwnProperty("@editable"))
                    {
                        isEditable = XString.stringToBool(paragraphElement.@editable);
                    }
                    
                    var isSelectable:Boolean = true;
                    if (paragraphElement.hasOwnProperty("@selectable"))
                    {
                        isSelectable = XString.stringToBool(paragraphElement.@selectable);
                    }
                    
                    // Create a new text block for each one of the paragraphs.
                    // Populate it with the text in the xml element
                    textArea.addTextBlock(textArea.getConstraints().width, blockHeight, isEditable, isSelectable);
                    
                    // TODO: It is not guaranteed that the correct values are set with prepopulated highlights.
                    // For example if a part highlights a number, that number will not appear in the starting bar model
                    WordProblemCreateUtil.addTextFromXmlToBlock(paragraphElement, textArea, i, stylePropertiesForBarModelType);
                    textArea.layoutTextBlocks();
                }
            }
        }
    }
}