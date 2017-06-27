package wordproblem.hints.tips
{
    import flash.geom.Rectangle;
    
    import dragonbox.common.time.Time;
    import dragonbox.common.ui.MouseState;
    
    import starling.display.DisplayObjectContainer;
    
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.systems.BlinkSystem;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.resource.AssetManager;
    
    /**
     * Base class for all the tip animations related to the bar model
     */
    public class BarModelTip extends GestureAndTextTip
    {
        protected static var DEFAULT_BAR_MODEL_WIDTH:Number = 450;
        protected static var DEFAULT_BAR_MODEL_HEIGHT:Number = 220;
        
        /**
         * Several tips will want to re-use this bar model for an animation of how to
         * perform a certain action.
         */
        protected var m_barModelArea:BarModelAreaWidget;
        
        /**
         * Blink the preview portions of a bar model
         */
        private var m_blinkSystem:BlinkSystem;
        
        protected var m_screenBounds:Rectangle;
        
        public function BarModelTip(expressionSymbolMap:ExpressionSymbolMap,
                                    canvas:DisplayObjectContainer,
                                    mouseState:MouseState,
                                    time:Time,
                                    assetManager:AssetManager,
                                    barModelTotalWidth:Number,
                                    barModelTotalHeight:Number,
                                    screenBounds:Rectangle,
                                    titleText:String,
                                    descriptionText:String,
                                    id:String=null, isActive:Boolean=true)
        {
            super(expressionSymbolMap, canvas, mouseState, time, assetManager, titleText, descriptionText, id, isActive);
            
            var padding:Number = 50;
            m_barModelArea = new BarModelAreaWidget(expressionSymbolMap, assetManager, 100, 50, 
                padding, padding, padding, padding, 20);
            m_barModelArea.setDimensions(barModelTotalWidth, barModelTotalHeight);
            
            m_blinkSystem = new BlinkSystem();
            
            m_screenBounds = screenBounds;
            
        }
        
        override public function visit():int
        {
            m_blinkSystem.update(m_barModelArea.componentManager);
            
            return super.visit();
        }
        
        /**
         * The common show function just tries to paste the bar model into the middle of the
         * screen and add the title/description of the action right below.
         */
        override public function show():void
        {
            var barModelWidth:Number = m_barModelArea.getConstraints().width;
            m_barModelArea.x = (m_screenBounds.width - barModelWidth) * 0.5;
            m_barModelArea.y = 100;
            
            m_mainDisplay.addChild(m_barModelArea);
            m_canvas.addChild(m_mainDisplay);
            
            var descriptionWidth:Number = m_screenBounds.width - 50;
            super.drawTextOnMainDisplay(m_screenBounds.width, 0, 0, 
                (m_screenBounds.width - descriptionWidth) * 0.5, m_barModelArea.y + m_barModelArea.getConstraints().height + 10, 
                descriptionWidth)
        }
        
        /**
         * The common hide function should remove the parts it added in the common show
         */
        override public function hide():void
        {
            super.hide();
            m_barModelArea.removeFromParent();
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_barModelArea.removeFromParent(true);
        }
    }
}