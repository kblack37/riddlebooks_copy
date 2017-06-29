package wordproblem.hints;

import wordproblem.hints.HintScript;

import flash.geom.Point;

import starling.display.DisplayObject;
import starling.textures.Texture;

import wordproblem.characters.HelperCharacterController;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.CalloutComponent;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.scripting.graph.action.CustomVisitNode;
import wordproblem.engine.scripting.graph.selector.SequenceSelector;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.text.TextParser;
import wordproblem.engine.text.TextParserUtil;
import wordproblem.engine.text.TextViewFactory;
import wordproblem.hints.processes.DismissCharacterOnClickProcess;
import wordproblem.hints.processes.MoveCharacterToProcess;
import wordproblem.hints.processes.ShowCharacterTextProcess;
import wordproblem.resource.AssetManager;

/**
 * This represents a class of hints which has just a text description in the hint screen
 * and then possibly showing the character with a different text description.
 * 
 * Text is constructed from xml with the same structure and properties as those in a level.
 * 
 * TODO: Eliminate this and replace with a customizable hint where we can append processes and
 * descriptors. More flexibility in the behavior of a hint without having to create new
 * classes all the time
 */
class BasicTextAndCharacterHint extends HintScript
{
    private static var DEFAULT_DESC_STYLE : Dynamic = {
            p : {
                color : "0x000000",
                fontName : GameFonts.DEFAULT_FONT_NAME,
                fontSize : 22,

            }

        };
    
    private static var DEFAULT_CHAR_STYLE : Dynamic = {
            p : {
                color : "0x000000",
                fontName : GameFonts.DEFAULT_FONT_NAME,
                fontSize : 18,

            }

        };
    
    private var m_gameEngine : IGameEngine;
    private var m_assetManager : AssetManager;
    private var m_characterController : HelperCharacterController;
    
    private var m_textParser : TextParser;
    
    private var m_textViewFactory : TextViewFactory;
    
    /**
     * Text to show in the hint screen
     */
    private var m_descriptionOriginalContent : FastXML;
    
    /**
     * Text to show in the character callout in the level
     */
    private var m_characterOriginalContent : FastXML;
    
    /**
     * The style to apply to the description text in the hint screen
     */
    private var m_descriptionStyle : Dynamic;
    
    /**
     * The style to apply to the character text callout
     */
    private var m_characterStyle : Dynamic;
    
    private var m_characterStopPoint : Point;
    
    private var characterId : String = "Cookie";
    
    /**
     *
     * @param descriptionText
     *      Stylized text for the hint screen description
     * @param characterText
     *      If null, character does not show up
     * @param descriptionStyle
     *      The style to apply to the description text, null to use default
     * @param characterStyle
     *      The style to apply to the character text, null to use default
     */
    public function new(gameEngine : IGameEngine,
            assetManager : AssetManager,
            characterController : HelperCharacterController,
            textParser : TextParser,
            textViewFactory : TextViewFactory,
            descriptionText : FastXML,
            characterText : FastXML,
            descriptionStyle : Dynamic = null,
            characterStyle : Dynamic = null,
            unlocked : Bool = true,
            id : String = null,
            isActive : Bool = true,
            characterStopPoint : Point = null)
    {
        super(unlocked, id, isActive);
        
        m_gameEngine = gameEngine;
        m_assetManager = assetManager;
        m_characterController = characterController;
        m_textParser = textParser;
        m_textViewFactory = textViewFactory;
        m_descriptionOriginalContent = descriptionText;
        m_characterOriginalContent = characterText;
        m_descriptionStyle = ((descriptionStyle != null)) ? descriptionStyle : DEFAULT_DESC_STYLE;
        m_characterStyle = ((characterStyle != null)) ? characterStyle : DEFAULT_CHAR_STYLE;
        
        m_characterStopPoint = new Point(100, 400);
        if (characterStopPoint != null) 
        {
            m_characterStopPoint.x = characterStopPoint.x;
            m_characterStopPoint.y = characterStopPoint.y;
        }
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.SUCCESS;
        
        // Return fail if the process sequence has finished
        if (m_processSequence != null) 
        {
            if (m_processSequence.allChildrenFinished()) 
            {
                status = ScriptStatus.FAIL;
            }
            else 
            {
                m_processSequence.visit();
            }
        }  // Visit child scripts  
        
        
        
        super.visit();
        
        if (m_defaultInterruptFinishedOnFrame) 
        {
            status = ScriptStatus.FAIL;
            m_defaultInterruptFinishedOnFrame = false;
        }
        
        return status;
    }
    
    private var m_processSequence : SequenceSelector;
    override public function show() : Void
    {
        // Have the helper character fly around to a spot
        if (canShow()) 
        {
            if (m_processSequence != null) 
            {
                m_processSequence.reset();
                m_processSequence.setIsActive(true);
            }
            else 
            {
                m_processSequence = new SequenceSelector();
                // TODO: And child processes to move the character and show the callout
                var moveProcess : MoveCharacterToProcess = new MoveCharacterToProcess(
                m_characterController, characterId, -100, 0, m_characterStopPoint.x, m_characterStopPoint.y, 300);
                m_processSequence.pushChild(moveProcess);
                var showCharacterTextProcess : ShowCharacterTextProcess = new ShowCharacterTextProcess(showHints(), m_characterController, 
                characterId, m_assetManager);
                m_processSequence.pushChild(showCharacterTextProcess);
                var dismissOnClickProcess : DismissCharacterOnClickProcess = new DismissCharacterOnClickProcess(m_characterController, 
                characterId, m_gameEngine.getMouseState(), null, null);
                m_processSequence.pushChild(dismissOnClickProcess);
                var removeDialogProcess : CustomVisitNode = new CustomVisitNode(m_characterController.removeDialogForCharacter, {
                    id : characterId

                });
                m_processSequence.pushChild(removeDialogProcess);
                var moveAwayProcess : MoveCharacterToProcess = new MoveCharacterToProcess(
                m_characterController, characterId, Math.NaN, Math.NaN, -100, 380, 400);
                m_processSequence.pushChild(moveAwayProcess);
                var visibleProcess : CustomVisitNode = new CustomVisitNode(m_characterController.setCharacterVisible, {
                    id : characterId,
                    visible : false,

                });
                m_processSequence.pushChild(visibleProcess);
            }
        }
    }
    
    override public function hide() : Void
    {
        // Remove the character and callout
        if (canShow()) 
        {
            m_characterController.getComponentManager().removeComponentFromEntity(
                    characterId, CalloutComponent.TYPE_ID);
            m_characterController.setCharacterVisible({
                        id : characterId,
                        visible : false,

                    });
            
            m_processSequence.dispose();
        }
    }
    
    override public function getDescription(width : Float, height : Float) : DisplayObject
    {
        return TextParserUtil.createTextViewFromXML(
                m_descriptionOriginalContent,
                m_descriptionStyle,
                width,
                m_textParser,
                m_textViewFactory
                );
    }
    
    override public function canShow() : Bool
    {
        return (m_characterOriginalContent != null);
    }
    
    private function showHints() : DisplayObject
    {
        // Add callout to the character
        var calloutBackgroundName : String = "thought_bubble";
        var measuringTexture : Texture = m_assetManager.getTexture(calloutBackgroundName);
        var paddingSide : Float = 10;
        
        // HACK: It appears the callout will always try to stretch to fit contents
        var actualContent : DisplayObject = TextParserUtil.createTextViewFromXML(
                m_characterOriginalContent,
                m_characterStyle,
                measuringTexture.width - 2 * paddingSide,
                m_textParser,
                m_textViewFactory
                );
        return actualContent;
    }
}
