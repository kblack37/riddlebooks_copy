package wordproblem.hints.tips
{
    import flash.geom.Rectangle;
    
    import dragonbox.common.math.vectorspace.RealsVectorSpace;
    import dragonbox.common.time.Time;
    import dragonbox.common.ui.MouseState;
    
    import starling.display.DisplayObjectContainer;
    
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.expression.tree.ExpressionTree;
    import wordproblem.engine.widget.TermAreaWidget;
    import wordproblem.resource.AssetManager;
    
    /**
     * General hint for all the gestures involving a single term area.
     */
    public class TermAreaTip extends GestureAndTextTip
    {
        protected var m_termArea:TermAreaWidget;
        
        protected var m_screenBounds:Rectangle;
        
        public function TermAreaTip(expressionSymbolMap:ExpressionSymbolMap,
                                     canvas:DisplayObjectContainer,
                                     mouseState:MouseState,
                                     time:Time,
                                     assetManager:AssetManager,
                                     termAreaTotalWidth:Number,
                                     termAreaTotalHeight:Number,
                                     screenBounds:Rectangle,
                                     titleText:String,
                                     descriptionText:String,
                                     id:String=null, 
                                     isActive:Boolean=true)
        {
            super(expressionSymbolMap, canvas, mouseState, time, assetManager, titleText, descriptionText, id, isActive);
            
            m_screenBounds = screenBounds;
            m_termArea = new TermAreaWidget(new ExpressionTree(new RealsVectorSpace(), null),
                expressionSymbolMap, assetManager, assetManager.getTexture("term_area_left"), termAreaTotalWidth, termAreaTotalHeight);
        }
        
        override public function show():void
        {
            var termAreaWidth:Number = m_termArea.getConstraintsWidth();
            var termAreaHeight:Number = m_termArea.getConstraintsHeight()
            m_termArea.x = (m_screenBounds.width - termAreaWidth) * 0.5;
            m_termArea.y = 100;
            
            m_mainDisplay.addChild(m_termArea);
            m_canvas.addChild(m_mainDisplay);
            
            var descriptionWidth:Number = m_screenBounds.width - 50;
            var titleWidth:Number = 500;
            super.drawTextOnMainDisplay(500, 
                (m_screenBounds.width - titleWidth) * 0.5, 
                0, 
                (termAreaWidth - descriptionWidth) * 0.5 + m_termArea.x,
                m_termArea.y + termAreaHeight + 20,
                descriptionWidth)
        }
        
        override public function hide():void
        {
            super.hide();
            
            m_termArea.removeFromParent();
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_termArea.dispose();
        }
    }
}