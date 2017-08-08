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
        
        var optionsIcon : Image = new Image(assetManager.getTexture("gear_yellow_icon"));
        optionsIcon.pivotX = optionsIcon.width * 0.5;
        optionsIcon.pivotY = optionsIcon.height * 0.5;
        m_button.upState = optionsIcon.texture;
		// TODO: this was changed from the feathers library button and will
		// probably need to be fixed
        //m_button.iconOffsetX = optionsIcon.pivotX;
        //m_button.iconOffsetY = optionsIcon.pivotY;
        
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
        var gearIconToAnimate : DisplayObject = try cast(m_button.upState, DisplayObject) catch (e : Dynamic) null;
        if (hoverTouch != null && m_optionsButtonIconTween == null) 
        {
            var iconTween : Tween = new Tween(gearIconToAnimate, 2);
            iconTween.animate("rotation", Math.PI * 2);
            iconTween.repeatCount = 0;
            Starling.current.juggler.add(iconTween);
            m_optionsButtonIconTween = iconTween;
        }
        else if (hoverTouch == null && m_optionsButtonIconTween != null) 
        {
            gearIconToAnimate.rotation = 0.0;
            Starling.current.juggler.remove(m_optionsButtonIconTween);
            m_optionsButtonIconTween = null;
        }
    }
}
