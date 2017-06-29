package wordproblem.hints.selector;


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
class HighlightTextHintSelector extends HintSelectorNode
{
    private var m_gameEngine : IGameEngine;
    private var m_assetManager : AssetManager;
    
    /**
     * If null, then the level does not have a bar model mode.
     * This affects how some of the hints are generated.
     */
    private var m_validateBarModelAreaScript : ValidateBarModelArea;
    
    private var m_globalBuffer : Point;
    
    /**
     * A running count of how many times the user has attempted to press something in the text area.
     * A high number may indicate that the user is having problems finding what the correct terms are.
     */
    private var m_attemptsToClickText : Int;
    private var m_characterController : HelperCharacterController;
    private var m_textParser : TextParser;
    private var m_textViewFactory : TextViewFactory;
    private var m_outDocumentViewsBuffer : Array<DocumentView>;
    private var m_uniqueExpressionsBuffer : Array<String>;
    
    /**
     * This is a guess that after this many number of presses on the text, if the user has not
     * yet gathered all the important terms they need help finding the terms.
     */
    private var m_attemptsToClickThreshold : Int = 8;
    
    /**
     * Only need to show the read question hint at most once each time the level is started
     */
    private var m_pickedShowQuestionHint : Bool;
    
    public function new(gameEngine : IGameEngine,
            assetManager : AssetManager,
            validateBarModelArea : ValidateBarModelArea,
            characterController : HelperCharacterController,
            textParser : TextParser,
            textViewFactory : TextViewFactory)
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
        m_outDocumentViewsBuffer = new Array<DocumentView>();
        m_uniqueExpressionsBuffer = new Array<String>();
        m_pickedShowQuestionHint = false;
    }
    
    override public function visit() : Void
    {
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        var mouseState : MouseState = m_gameEngine.getMouseState();
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
    
    override public function getHint() : HintScript
    {
        var textArea : TextAreaWidget = null;
        var textAreas : Array<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TextAreaWidget);
        if (textAreas.length > 0) 
        {
            textArea = try cast(textAreas[0], TextAreaWidget) catch(e:Dynamic) null;
        }
        
        if (textArea != null) 
        {
            // Checking if the user has picked up all the critical pieces from the text
            // To identify the critical pieces, go through the reference models and see what labels
            // were needed. (non-labels not critical because it is possible for the user to create arbitrary number
            // of boxes using the copy gesture)
            // Compare those parts to what the user has in the deck
            var deckArea : DeckWidget = try cast(m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null;
            var expressionsInDeck : Array<Component> = deckArea.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
            var numExpressionsInDeck : Int = expressionsInDeck.length;
            var importantLabelIsMissing : Bool = false;
            
            // Need to handle levels that have bar model and ones that are just expression modeling
            if (m_validateBarModelAreaScript != null) 
            {
                for (decomposedReference/* AS3HX WARNING could not determine type for var: decomposedReference exp: ECall(EField(EIdent(m_validateBarModelAreaScript),getDecomposedReferenceModels),[]) type: null */ in m_validateBarModelAreaScript.getDecomposedReferenceModels())
                {
                    for (labelName in Reflect.fields(decomposedReference.labelValueToType))
                    {
                        var isLabelInDeck : Bool = false;
                        var i : Int;
                        for (i in 0...expressionsInDeck.length){
                            var expressionInDeck : ExpressionComponent = try cast(expressionsInDeck[i], ExpressionComponent) catch(e:Dynamic) null;
                            if (expressionInDeck.expressionString == labelName) 
                            {
                                isLabelInDeck = true;
                                break;
                            }
                        }  // There is at least one reference model where a necessary label has not been discovered  
                        
                        
                        
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
                var expressionsInText : Array<Component> = textArea.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
                as3hx.Compat.setArrayLength(m_uniqueExpressionsBuffer, 0);
                for (expressionInText in expressionsInText)
                {
                    if (Lambda.indexOf(m_uniqueExpressionsBuffer, expressionInText.expressionString) == -1) 
                    {
                        m_uniqueExpressionsBuffer.push(expressionInText.expressionString);
                    }
                }
                
                for (uniqueExpression in m_uniqueExpressionsBuffer)
                {
                    var foundMatch : Bool = false;
                    for (i in 0...expressionsInDeck.length){
                        expressionInDeck = try cast(expressionsInDeck[i], ExpressionComponent) catch(e:Dynamic) null;
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
            
            var hint : HintScript = null;
            if (importantLabelIsMissing && m_attemptsToClickText > m_attemptsToClickThreshold) 
            {
                var hintData : Dynamic = {
                    descriptionContent : "Make sure you've found all the important numbers and names first.",
                    highlightDocIds : textArea.getAllDocumentIdsTiedToExpression(),

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
                as3hx.Compat.setArrayLength(m_outDocumentViewsBuffer, 0);
                textArea.getDocumentViewsAtPageIndexById("question", m_outDocumentViewsBuffer);
                if (m_outDocumentViewsBuffer.length > 0) 
                {
                    hintData = {
                                descriptionContent : "Read carefully, what is the question asking you to find?",
                                highlightDocIds : ["question"],

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
