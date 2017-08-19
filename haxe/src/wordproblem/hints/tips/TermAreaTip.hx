package wordproblem.hints.tips;


import openfl.geom.Rectangle;

import dragonbox.common.math.vectorspace.RealsVectorSpace;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

import openfl.display.DisplayObjectContainer;

import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.expression.tree.ExpressionTree;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.resource.AssetManager;

/**
 * General hint for all the gestures involving a single term area.
 */
class TermAreaTip extends GestureAndTextTip
{
    private var m_termArea : TermAreaWidget;
    
    private var m_screenBounds : Rectangle;
    
    public function new(expressionSymbolMap : ExpressionSymbolMap,
            canvas : DisplayObjectContainer,
            mouseState : MouseState,
            time : Time,
            assetManager : AssetManager,
            termAreaTotalWidth : Float,
            termAreaTotalHeight : Float,
            screenBounds : Rectangle,
            titleText : String,
            descriptionText : String,
            id : String = null,
            isActive : Bool = true)
    {
        super(expressionSymbolMap, canvas, mouseState, time, assetManager, titleText, descriptionText, id, isActive);
        
        m_screenBounds = screenBounds;
        m_termArea = new TermAreaWidget(new ExpressionTree(new RealsVectorSpace(), null), 
                expressionSymbolMap, assetManager, assetManager.getBitmapData("term_area_left"), termAreaTotalWidth, termAreaTotalHeight);
    }
    
    override public function show() : Void
    {
        var termAreaWidth : Float = m_termArea.getConstraintsWidth();
        var termAreaHeight : Float = m_termArea.getConstraintsHeight();
        m_termArea.x = (m_screenBounds.width - termAreaWidth) * 0.5;
        m_termArea.y = 100;
        
        m_mainDisplay.addChild(m_termArea);
        m_canvas.addChild(m_mainDisplay);
        
        var descriptionWidth : Float = m_screenBounds.width - 50;
        var titleWidth : Float = 500;
        super.drawTextOnMainDisplay(500,
                (m_screenBounds.width - titleWidth) * 0.5,
                0,
                (termAreaWidth - descriptionWidth) * 0.5 + m_termArea.x,
                m_termArea.y + termAreaHeight + 20,
                descriptionWidth);
    }
    
    override public function hide() : Void
    {
        super.hide();
        
        if (m_termArea.parent != null) m_termArea.parent.removeChild(m_termArea);
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_termArea.dispose();
    }
}
