package wordproblem.settings;

import haxe.Constraints.Function;

import starling.animation.Tween;
import starling.core.Starling;
import starling.display.Button;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;

import wordproblem.engine.widget.WidgetUtil;
import wordproblem.resource.AssetManager;

/**
 * Use this so the option button can appear+behave uniform in several places without duplicating code
 */
class OptionButton extends Sprite
{
    private var m_button : Button;
    private var m_onClickCallback : Function;
    
    /**
     * Animation of the icon on the button spinning on mouse over
     */
    private var m_optionsButtonIconTween : Tween;
	private var m_optionsButtonIcon : Image;
    
    public function new(assetManager : AssetManager,
            color : Int,
            onClick : Function)
    {
        super();
        
        m_onClickCallback = onClick;
        
        m_button = WidgetUtil.createGenericColoredButton(
                        assetManager, color, null, null);
        m_button.width = 42;
        m_button.height = 42;
        
        m_button.upState = assetManager.getTexture("gear_yellow_icon");
        
        m_button.addEventListener(Event.TRIGGERED, onButtonClicked);
        m_button.addEventListener(TouchEvent.TOUCH, onButtonTouched);
        addChild(m_button);
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_button.removeEventListener(Event.TRIGGERED, onButtonClicked);
        m_button.removeEventListener(TouchEvent.TOUCH, onButtonTouched);
    }
    
    private function onButtonClicked() : Void
    {
        if (m_onClickCallback != null) 
        {
            m_onClickCallback();
        }
    }
    
    /**
     * Bind listener to the options to get an animation of the yellow gear on the
     * button to spin on mouse over
     */
    private function onButtonTouched(event : TouchEvent) : Void
    {
        var hoverTouch : Touch = event.getTouch(m_button, TouchPhase.HOVER);
        if (hoverTouch != null && m_optionsButtonIconTween == null) 
        {
			// Lazily initialize the button in the correct position
			if (m_optionsButtonIcon == null) {
				m_optionsButtonIcon = new Image(m_button.upState);
				m_optionsButtonIcon.width = m_button.width;
				m_optionsButtonIcon.height = m_button.height;
				m_optionsButtonIcon.alignPivot();
				m_optionsButtonIcon.x = m_optionsButtonIcon.width / 2;
				m_optionsButtonIcon.y = m_optionsButtonIcon.height / 2;
			}
			// Set the button alpha to 0 and add the spinning icon behind it
			// so as to 1) actually display the spinning icon and 2) not interrupt
			// the touch events dispatched to the button
			m_button.alpha = 0;
			addChildAt(m_optionsButtonIcon, 0);
            var iconTween : Tween = new Tween(m_optionsButtonIcon, 2);
            iconTween.animate("rotation", Math.PI * 2);
            iconTween.repeatCount = 0;
            Starling.current.juggler.add(iconTween);
            m_optionsButtonIconTween = iconTween;
        }
        else if (hoverTouch == null && m_optionsButtonIconTween != null) 
        {
            m_optionsButtonIcon.rotation = 0.0;
			removeChild(m_optionsButtonIcon);
			m_button.alpha = 1;
            Starling.current.juggler.remove(m_optionsButtonIconTween);
            m_optionsButtonIconTween = null;
        }
    }
}
