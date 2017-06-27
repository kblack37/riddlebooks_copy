package wordproblem.hints
{
    import starling.display.DisplayObject;
    
    import wordproblem.characters.HelperCharacterController;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.ExpressionComponent;
    import wordproblem.engine.text.TextParser;
    import wordproblem.engine.text.TextViewFactory;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.resource.AssetManager;
    
    /**
     * This hint type is a minor extension of the text hint.
     * 
     * There are locations in the content in which we add new xml tags representing images
     * of cards for a problem. This can only be done after the level data has been read in
     * and we know the exact value of those cards.
     * 
     * This hint relies on a specific pattern in the generated levels where tagged document ids in main level
     * content are labeled unk, a1, b1, a2, etc. Using these mappings we can identify the actual term values
     * specific to the level being played.
     */
    public class BasicTextWithCardsHint extends BasicTextAndCharacterHint
    {
        private var m_descriptionIdToMainDocumentId:Object;
        
        /**
         * Only perform the modification to the xml once on the first draw
         */
        private var m_descriptionXmlModified:Boolean;
        
        /**
         *
         * @param descriptionIdToMainDocumentId
         *      This is a mapping from a xml id to a document id in the main text body of the problem.
         *      This is critical to identify the card as the document id has an implicit connection
         *      to a single expression value.
         */
        public function BasicTextWithCardsHint(gameEngine:IGameEngine,
                                               assetManager:AssetManager,
                                               characterController:HelperCharacterController, 
                                               textParser:TextParser, 
                                               textViewFactory:TextViewFactory, 
                                               descriptionText:XML, 
                                               characterText:XML,
                                               descriptionIdToMainDocumentId:Object,
                                               descriptionStyle:Object=null, 
                                               characterStyle:Object=null, 
                                               id:String=null, 
                                               isActive:Boolean=true)
        {
            super(gameEngine, assetManager, characterController, textParser, textViewFactory, descriptionText, characterText, descriptionStyle, characterStyle, false, id, isActive);
            
            m_descriptionIdToMainDocumentId = descriptionIdToMainDocumentId;
            m_descriptionXmlModified = false;
        }
        
        override public function getDescription(width:Number, height:Number):DisplayObject
        {
            // Replace the description contents in the xml, only need to do this once
            if (!m_descriptionXmlModified)
            {
                m_descriptionXmlModified = true;
                
                // The xml for hints are shared across level, we apply modification to clones of the xml
                // so changes do not persist across levels.
                m_descriptionOriginalContent = m_descriptionOriginalContent.copy();
                
                // The term values available in the level can be found by seeing what parts of the text are mapped directly
                // to an expression value
                var documentIdInMainTextToTermValue:Object = {};
                var textAreaWidget:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
                var expressionComponents:Vector.<Component> = textAreaWidget.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
                var i:int;
                for (i = 0; i < expressionComponents.length; i++)
                {
                    var expressionComponent:ExpressionComponent = expressionComponents[i] as ExpressionComponent;
                    documentIdInMainTextToTermValue[expressionComponent.entityId] = expressionComponent.expressionString;
                }
                
                // Go through the xml and find specific tags with a matching id
                // At that element add a new child element
                for (var descriptionId:String in m_descriptionIdToMainDocumentId)
                {
                    var element:XML = _getElementWithId(m_descriptionOriginalContent, descriptionId);
                    if (element != null)
                    {
                        // Modify the original description appending a new child that is a picture of the card
                        var newCardImageXML:XML = <img height="32"/>;
                        var termValue:String = documentIdInMainTextToTermValue[m_descriptionIdToMainDocumentId[descriptionId]];
                        newCardImageXML.@src = "symbol(" + termValue + ")";
                        element.appendChild(newCardImageXML);
                    }
                }
            }
            
            return super.getDescription(width, height);
        }
        
        private function _getElementWithId(content:XML, id:String):XML
        {
            var element:XML = null;
            if (content.hasOwnProperty("@id") && content.@id == id)
            {
                element = content;   
            }
            else
            {
                var childElements:XMLList = content.children();
                var i:int;
                var numChildren:int = childElements.length();
                for (i = 0; i < numChildren; i++)
                {
                    element = _getElementWithId(childElements[i], id);
                    if (element != null)
                    {
                        break;
                    }
                }
            }
            
            return element;
        }
    }
}