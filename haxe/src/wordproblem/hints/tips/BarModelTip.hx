package wordproblem.hints.tips;

import wordproblem.hints.tips.GestureAndTextTip;

import openfl.geom.Rectangle;

import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

import openfl.display.DisplayObjectContainer;

import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.systems.BlinkSystem;
import wordproblem.engine.widget.BarModelAreaWidget;
import wordproblem.resource.AssetManager;

/**
 * Base class for all the tip animations related to the bar model
 */
class BarModelTip extends GestureAndTextTip
{
    private static var DEFAULT_BAR_MODEL_WIDTH : Float = 450;
    private static var DEFAULT_BAR_MODEL_HEIGHT : Float = 220;
    
    /**
     * Several tips will want to re-use this bar model for an animation of how to
     * perform a certain action.
     */
    private var m_barModelArea : BarModelAreaWidget;
    
    /**
     * Blink the preview portions of a bar model
     */
    private var m_blinkSystem : BlinkSystem;
    
    private var m_screenBounds : Rectangle;
    
    public function new(expressionSymbolMap : ExpressionSymbolMap,
            canvas : DisplayObjectContainer,
            mouseState : MouseState,
            time : Time,
            assetManager : AssetManager,
            barModelTotalWidth : Float,
            barModelTotalHeight : Float,
            screenBounds : Rectangle,
            titleText : String,
            descriptionText : String,
            id : String = null, isActive : Bool = true)
    {
        super(expressionSymbolMap, canvas, mouseState, time, assetManager, titleText, descriptionText, id, isActive);
        
        var padding : Float = 50;
        m_barModelArea = new BarModelAreaWidget(expressionSymbolMap, assetManager, 100, 50, 
                padding, padding, padding, padding, 20);
        m_barModelArea.setDimensions(barModelTotalWidth, barModelTotalHeight);
        
        m_blinkSystem = new BlinkSystem();
        
        m_screenBounds = screenBounds;
    }
    
    override public function visit() : Int
    {
        m_blinkSystem.update(m_barModelArea.componentManager);
        
        return super.visit();
    }
    
    /**
     * The common show function just tries to paste the bar model into the middle of the
     * screen and add the title/description of the action right below.
     */
    override public function show() : Void
    {
        var barModelWidth : Float = m_barModelArea.getConstraints().width;
        m_barModelArea.x = (m_screenBounds.width - barModelWidth) * 0.5;
        m_barModelArea.y = 100;
        
        m_mainDisplay.addChild(m_barModelArea);
        m_canvas.addChild(m_mainDisplay);
        
        var descriptionWidth : Float = m_screenBounds.width - 50;
        super.drawTextOnMainDisplay(m_screenBounds.width, 0, 0,
                (m_screenBounds.width - descriptionWidth) * 0.5, m_barModelArea.y + m_barModelArea.getConstraints().height + 10,
                descriptionWidth);
    }
    
    /**
     * The common hide function should remove the parts it added in the common show
     */
    override public function hide() : Void
    {
        super.hide();
        if (m_barModelArea.parent != null) m_barModelArea.parent.removeChild(m_barModelArea);
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
		if (m_barModelArea.parent != null) m_barModelArea.parent.removeChild(m_barModelArea);
		m_barModelArea.dispose();
		m_barModelArea = null;
    }
}
