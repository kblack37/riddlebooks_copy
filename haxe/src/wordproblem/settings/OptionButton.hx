package wordproblem.settings;

import haxe.Constraints.Function;
import motion.Actuate;
import openfl.display.Bitmap;
import openfl.events.MouseEvent;
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
class OptionButton extends Sprite
{
    private var m_button : LabelButton;
    private var m_onClickCallback : Function;
    
    /**
     * Animation of the icon on the button spinning on mouse over
     */
	private var m_optionsButtonContainer : PivotSprite;
    
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
        
        m_button.upState = new Bitmap(assetManager.getBitmapData("gear_yellow_icon"));
        
        m_button.addEventListener(MouseEvent.CLICK, onButtonClicked);
        m_button.addEventListener(MouseEvent.MOUSE_OVER, onButtonMouseOver);
		m_button.addEventListener(MouseEvent.MOUSE_OUT, onButtonMouseOut);
        addChild(m_button);
    }
    
    public function dispose() : Void
    {
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
        if (m_optionsButtonContainer == null) 
        {
			m_optionsButtonContainer = new PivotSprite();
			m_optionsButtonContainer.addChild(m_button);
			m_optionsButtonContainer.pivotX = m_button.width / 2;
			m_optionsButtonContainer.pivotY = m_button.height / 2;
			
			Actuate.tween(m_optionsButtonContainer, 2, { rotation: 360 }).repeat();
			addChild(m_optionsButtonContainer);
        }
    }
	
	private function onButtonMouseOut(event : Dynamic) {
		if (m_optionsButtonContainer != null) {
			Actuate.stop(m_optionsButtonContainer);
			m_optionsButtonContainer.removeChild(m_button);
			removeChild(m_optionsButtonContainer);
			m_optionsButtonContainer.dispose();
			m_optionsButtonContainer = null;
		}
	}
}
