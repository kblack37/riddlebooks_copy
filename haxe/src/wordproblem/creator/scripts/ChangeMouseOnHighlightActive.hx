package wordproblem.creator.scripts;


import flash.geom.Rectangle;
import js.html.Image;

import dragonbox.common.ui.MouseState;

import starling.animation.Tween;
import starling.core.Starling;
import starling.events.Event;
import starling.textures.Texture;

import wordproblem.creator.ProblemCreateEvent;
import wordproblem.creator.WordProblemCreateState;
import wordproblem.resource.AssetManager;

/**
 * When the user is actively trying to highlight something in the text area, we should add a graphic just below the
 * mouse
 */
class ChangeMouseOnHighlightActive extends BaseProblemCreateScript
{
    private var m_mouseState : MouseState;
    
    private var m_highlightActive : Bool;
    private var m_highlightIndicatorImage : Image;
    private var m_highlightIndicatorTween : Tween;
    
    public function new(createState : WordProblemCreateState,
            assetManager : AssetManager,
            mouseState : MouseState,
            id : String = null,
            isActive : Bool = true)
    {
        super(createState, assetManager, id, isActive);
        
        m_mouseState = mouseState;
        m_highlightActive = false;
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_isReady) 
        {
            m_createState.removeEventListener(ProblemCreateEvent.USER_HIGHLIGHT_STARTED, onHighlightStarted);
            m_createState.removeEventListener(ProblemCreateEvent.USER_HIGHLIGHT_CANCELLED, onHighlightFinished);
            m_createState.removeEventListener(ProblemCreateEvent.USER_HIGHLIGHT_FINISHED, onHighlightFinished);
            if (value) 
            {
                m_createState.addEventListener(ProblemCreateEvent.USER_HIGHLIGHT_STARTED, onHighlightStarted);
                m_createState.addEventListener(ProblemCreateEvent.USER_HIGHLIGHT_CANCELLED, onHighlightFinished);
                m_createState.addEventListener(ProblemCreateEvent.USER_HIGHLIGHT_FINISHED, onHighlightFinished);
            }
        }
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_highlightIndicatorImage.removeFromParent(true);
        Starling.juggler.remove(m_highlightIndicatorTween);
    }
    
    override public function visit() : Int
    {
        if (m_isActive && m_isReady) 
        {
            if (m_highlightActive) 
            {
                if (!m_highlightIndicatorImage.parent) 
                {
                    m_createState.addChild(m_highlightIndicatorImage);
                }
                
                m_highlightIndicatorImage.x = m_mouseState.mousePositionThisFrame.x;
                m_highlightIndicatorImage.y = m_mouseState.mousePositionThisFrame.y;
                
                if (m_mouseState.leftMouseDown) 
                {
                    m_highlightIndicatorImage.alpha = 0.4;
                }
                else 
                {
                    m_highlightIndicatorImage.alpha = 1.0;
                }
            }
        }
        return super.visit();
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        setIsActive(m_isActive);
        
        var padding : Float = 4;
        var indicatorTexture : Texture = m_assetManager.getTexture("card_background_square");
        var scale9Texture : Texture = Texture.fromTexture(indicatorTexture, 
			new Rectangle(padding,
				padding,
				indicatorTexture.width - 2 * padding,
				indicatorTexture.height - 2 * padding
			)
		);
        var indicatorImage : Image = new Image(scale9Texture);
        indicatorImage.pivotX = indicatorTexture.width * 0.5;
        indicatorImage.pivotY = indicatorTexture.height * 0.5;
        
        var desiredWidth : Float = 32;
        indicatorImage.scaleX = indicatorImage.scaleY = (desiredWidth / indicatorTexture.width);
        
        m_highlightIndicatorImage = indicatorImage;
        
        m_highlightIndicatorTween = new Tween(m_highlightIndicatorImage, 0.5);
        m_highlightIndicatorTween.animate("scaleX", indicatorImage.scaleX * 1.3);
        m_highlightIndicatorTween.animate("scaleY", indicatorImage.scaleX * 1.3);
        m_highlightIndicatorTween.repeatCount = 0;
        m_highlightIndicatorTween.reverse = true;
    }
    
    private function onHighlightStarted(event : Event, params : Dynamic) : Void
    {
        // Get the color of the highlight based on the id
        var barPartName : String = params.id;
        var styleInformation : Dynamic = m_createState.getCurrentLevel().currentlySelectedBackgroundData;
        if (styleInformation != null && styleInformation.exists("highlightColors")) 
        {
            m_highlightIndicatorImage.color = Reflect.field(Reflect.field(styleInformation, "highlightColors"), barPartName);
        }
        
        m_highlightActive = true;
        
        Starling.juggler.add(m_highlightIndicatorTween);
    }
    
    // TODO: highlight finished does not trigger if the user clicks on the bar model element to toggle off the highlight
    private function onHighlightFinished() : Void
    {
        m_highlightActive = false;
        m_highlightIndicatorImage.removeFromParent();
        
        Starling.juggler.remove(m_highlightIndicatorTween);
    }
}
