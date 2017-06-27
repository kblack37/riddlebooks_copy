package wordproblem.hints.selector
{
    import flash.geom.Point;
    
    import dragonbox.common.ui.MouseState;
    
    import starling.display.DisplayObject;
    
    import wordproblem.characters.HelperCharacterController;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.DecomposedBarModelData;
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.ExpressionComponent;
    import wordproblem.engine.text.TextParser;
    import wordproblem.engine.text.TextViewFactory;
    import wordproblem.engine.text.view.DocumentView;
    import wordproblem.engine.widget.DeckWidget;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.hints.HintCommonUtil;
    import wordproblem.hints.HintScript;
    import wordproblem.hints.HintSelectorNode;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.barmodel.ValidateBarModelArea;
    
    /**
     * Used to select hints related highlighting portions of the text.
     */
    public class HighlightTextHintSelector extends HintSelectorNode
    {
        private var m_gameEngine:IGameEngine;
        private var m_assetManager:AssetManager;
        
        /**
         * If null, then the level does not have a bar model mode.
         * This affects how some of the hints are generated.
         */
        private var m_validateBarModelAreaScript:ValidateBarModelArea;
        
        private var m_globalBuffer:Point;
        
        /**
         * A running count of how many times the user has attempted to press something in the text area.
         * A high number may indicate that the user is having problems finding what the correct terms are.
         */
        private var m_attemptsToClickText:int;
        private var m_characterController:HelperCharacterController;
        private var m_textParser:TextParser;
        private var m_textViewFactory:TextViewFactory;
        private var m_outDocumentViewsBuffer:Vector.<DocumentView>;
        private var m_uniqueExpressionsBuffer:Vector.<String>;
        
        /**
         * This is a guess that after this many number of presses on the text, if the user has not
         * yet gathered all the important terms they need help finding the terms.
         */
        private var m_attemptsToClickThreshold:int = 8;
        
        /**
         * Only need to show the read question hint at most once each time the level is started
         */
        private var m_pickedShowQuestionHint:Boolean;
        
        public function HighlightTextHintSelector(gameEngine:IGameEngine,
                                                  assetManager:AssetManager,
                                                  validateBarModelArea:ValidateBarModelArea,
                                                  characterController:HelperCharacterController,
                                                  textParser:TextParser,
                                                  textViewFactory:TextViewFactory)
        {
            super();
            
            m_gameEngine = gameEngine;
            m_assetManager = assetManager;
            m_validateBarModelAreaScript = validateBarModelArea;
            m_characterController = characterController;
            m_textParser = textParser;
            m_textViewFactory = textViewFactory;
            m_globalBuffer = new Point();
            m_attemptsToClickText = 0;
            m_outDocumentViewsBuffer = new Vector.<DocumentView>();
            m_uniqueExpressionsBuffer = new Vector.<String>();
            m_pickedShowQuestionHint = false;
        }
        
        override public function visit():void
        {
            var textArea:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            var mouseState:MouseState = m_gameEngine.getMouseState();
            m_globalBuffer.x = mouseState.mousePositionThisFrame.x;
            m_globalBuffer.y = mouseState.mousePositionThisFrame.y;
            
            if (mouseState.leftMousePressedThisFrame)
            {
                if (textArea.hitTestDocumentView(m_globalBuffer, false) != null)
                {
                    m_attemptsToClickText++;
                }
            }
        }
        
        override public function getHint():HintScript
        {
            var textArea:TextAreaWidget = null;
            var textAreas:Vector.<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TextAreaWidget);
            if (textAreas.length > 0)
            {
                textArea = textAreas[0] as TextAreaWidget;
            }
            
            if (textArea != null)
            {
                // Checking if the user has picked up all the critical pieces from the text
                // To identify the critical pieces, go through the reference models and see what labels
                // were needed. (non-labels not critical because it is possible for the user to create arbitrary number
                // of boxes using the copy gesture)
                // Compare those parts to what the user has in the deck
                var deckArea:DeckWidget = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
                var expressionsInDeck:Vector.<Component> = deckArea.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
                var numExpressionsInDeck:int = expressionsInDeck.length;
                var importantLabelIsMissing:Boolean = false;
                
                // Need to handle levels that have bar model and ones that are just expression modeling
                if (m_validateBarModelAreaScript != null)
                {
                    for each (var decomposedReference:DecomposedBarModelData in m_validateBarModelAreaScript.getDecomposedReferenceModels())
                    {
                        for (var labelName:String in decomposedReference.labelValueToType)
                        {
                            var isLabelInDeck:Boolean = false;
                            var i:int;
                            for (i = 0; i < expressionsInDeck.length; i++)
                            {
                                var expressionInDeck:ExpressionComponent = expressionsInDeck[i] as ExpressionComponent;
                                if (expressionInDeck.expressionString == labelName)
                                {
                                    isLabelInDeck = true;
                                    break;
                                }
                            }
                            
                            // There is at least one reference model where a necessary label has not been discovered
                            if (!isLabelInDeck)
                            {
                                importantLabelIsMissing = true;
                            }
                        }
                    }
                }
                // For levels without bar models we assume that every term is important, all number of unique expressions
                else
                {
                    var expressionsInText:Vector.<Component> = textArea.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
                    m_uniqueExpressionsBuffer.length = 0;
                    for each (var expressionInText:ExpressionComponent in expressionsInText)
                    {
                        if (m_uniqueExpressionsBuffer.indexOf(expressionInText.expressionString) == -1)
                        {
                            m_uniqueExpressionsBuffer.push(expressionInText.expressionString);
                        }
                    }
                    
                    for each (var uniqueExpression:String in m_uniqueExpressionsBuffer)
                    {
                        var foundMatch:Boolean = false;
                        for (i = 0; i < expressionsInDeck.length; i++)
                        {
                            expressionInDeck = expressionsInDeck[i] as ExpressionComponent;
                            if (expressionInDeck.expressionString == uniqueExpression)
                            {
                                foundMatch = true;
                                break;
                            }
                        }
                        
                        if (!foundMatch)
                        {
                            importantLabelIsMissing = true;
                            break;
                        }
                    }
                }
                
                var hint:HintScript = null;
                if (importantLabelIsMissing && m_attemptsToClickText > m_attemptsToClickThreshold)
                {
                    var hintData:Object = {
                        descriptionContent: "Make sure you've found all the important numbers and names first.",
                        highlightDocIds: textArea.getAllDocumentIdsTiedToExpression()
                    };
                    hint = HintCommonUtil.createHintFromMismatchData(hintData,
                        m_characterController,
                        m_assetManager, m_gameEngine.getMouseState(), m_textParser, m_textViewFactory, textArea, 
                        m_gameEngine, 200, 350);
                }
                else if (!m_pickedShowQuestionHint)
                {
                    // Check if the question exists
                    // Go to the text area and see if there is an element with the id tagged question
                    m_outDocumentViewsBuffer.length = 0;
                    textArea.getDocumentViewsAtPageIndexById("question", m_outDocumentViewsBuffer);
                    if (m_outDocumentViewsBuffer.length > 0)
                    {
                        hintData = {
                            descriptionContent: "Read carefully, what is the question asking you to find?",
                            highlightDocIds: ["question"]
                        };
                        hint = HintCommonUtil.createHintFromMismatchData(hintData,
                            m_characterController,
                            m_assetManager, m_gameEngine.getMouseState(), m_textParser, m_textViewFactory, textArea, 
                            m_gameEngine, 200, 350);
                        m_pickedShowQuestionHint = true;
                    }
                }
            }
            
            return hint;
        }
    }
}