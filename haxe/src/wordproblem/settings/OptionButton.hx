package wordproblem.settings;

import haxe.Constraints.Function;
import motion.Actuate;
import motion.easing.Linear;
import openfl.display.Bitmap;
import openfl.events.MouseEvent;
import wordproblem.display.DisposableSprite;
import wordproblem.display.PivotSprite;

import wordproblem.display.LabelButton;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;

import wordproblem.engine.widget.WidgetUtil;
import wordproblem.resource.AssetManager;

/**
 * Use this so the option button can appear+behave uniform in several places without duplicating code
 */
class OptionButton extends DisposableSprite
{
    private var m_button : LabelButton;
    private var m_onClickCallback : Function;
	
	private var m_isAnimating : Bool;
    
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
		m_button.scaleWhenUp = m_button.scaleX;
		m_button.scaleWhenOver = m_button.scaleX;
		m_button.scaleWhenDown = m_button.scaleX;
        
        m_button.upState = new Bitmap(assetManager.getBitmapData("gear_yellow_icon"));
		m_button.overState = m_button.upState;
		m_button.downState = m_button.upState;
		
		m_button.x += m_button.width / 2;
		m_button.y += m_button.height / 2;
		m_button.pivotX = m_button.width / 2;
		m_button.pivotY = m_button.height / 2;
        
        m_button.addEventListener(MouseEvent.CLICK, onButtonClicked);
        m_button.addEventListener(MouseEvent.MOUSE_OVER, onButtonMouseOver);
		m_button.addEventListener(MouseEvent.MOUSE_OUT, onButtonMouseOut);
        addChild(m_button);
    }
    
    override public function dispose() : Void
    {
		super.dispose();
		
        m_button.removeEventListener(MouseEvent.CLICK, onButtonClicked);
        m_button.removeEventListener(MouseEvent.MOUSE_OVER, onButtonMouseOver);
		m_button.removeEventListener(MouseEvent.MOUSE_OUT, onButtonMouseOut);
    }
    
    private function onButtonClicked(event : Dynamic) : Void
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
    private function onButtonMouseOver(event : Dynamic) : Void
    {
		if (!m_isAnimating) {
			Actuate.tween(m_button, 2, { rotation: 360 }).ease(Linear.easeNone).repeat();
			m_isAnimating = true;
		}
    }
	
	private function onButtonMouseOut(event : Dynamic) {
		if (m_isAnimating) {
			Actuate.stop(m_button);
			m_button.rotation = 0;
			m_isAnimating = false;
		}
	}
}
