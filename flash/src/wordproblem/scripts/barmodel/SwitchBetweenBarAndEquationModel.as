package wordproblem.scripts.barmodel
{
    import cgs.Audio.Audio;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import feathers.controls.Button;
    
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.events.Event;
    import starling.filters.ColorMatrixFilter;
    
    import wordproblem.callouts.TooltipControl;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.widget.WidgetUtil;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.BaseGameScript;
    
    /**
     * Handles the logic involved with sliding a portion of the ui up and down to switch between
     * bar modeling and equation modeling.
     */
    public class SwitchBetweenBarAndEquationModel extends BaseGameScript
    {
        private var m_switchModelButton:Button;
        
        /**
         * Need to remember if the ui is in a down state or an up state.
         * 
         * This is true if ui is in a down state where the equation model portion is
         * presumably hidden.
         */
        private var m_inSlideDownState:Boolean;
        
        /**
         * Callback when the sliding is completed
         * 
         * Callback accepts boolean that is true if the ui is in bar model mode
         * and false if it is in equation mode
         */
        private var m_onSwitchModelClick:Function;
        
        /**
         * Original y location of the ui container
         */
        private var m_deckAndTermContainerOriginalY:Number;
        
        private var m_tooltipControl:TooltipControl;
        private const TOOLTIP_SHOW_EQUATION:String = "Show Equation";
        private const TOOLTIP_SHOW_TEXT:String = "Show Problem";
        
        /**
         * The y value of the ui that is should move to when revealing the model area
         */
        public var targetY:Number = 30;
        
        public function SwitchBetweenBarAndEquationModel(gameEngine:IGameEngine, 
                                                         expressionCompiler:IExpressionTreeCompiler, 
                                                         assetManager:AssetManager, 
                                                         onSwitchModelClick:Function,
                                                         id:String=null, 
                                                         isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            m_onSwitchModelClick = onSwitchModelClick;
        }
        
        /**
         * Due to timing issues of when this script gets called vs other scripts messing with the
         * positioning of the container, have this extra function that explicitly sets the 'resting value'
         * of the container
         */
        public function setContainerOriginalY(value:Number):void
        {
            m_deckAndTermContainerOriginalY = value;
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            
            if (m_ready)
            {
                // Set whether the button is enabled
                m_switchModelButton.isEnabled = value;
                m_switchModelButton.removeEventListener(Event.TRIGGERED, onSwitchModelClicked);
                if (value)
                {
                    m_switchModelButton.addEventListener(Event.TRIGGERED, onSwitchModelClicked);
                    
                    // Set color to normal
                    m_switchModelButton.filter = null;
                    m_switchModelButton.alpha = 1.0;
                }
                else
                {
                    // Set color to grey scale
                    var colorMatrixFilter:ColorMatrixFilter = new ColorMatrixFilter();
                    colorMatrixFilter.adjustSaturation(-1);
                    m_switchModelButton.filter = colorMatrixFilter;
                    m_switchModelButton.alpha = 0.5;
                }
            }
        }
        
        override public function visit():int
        {
            if (m_ready && m_isActive)
            {
                m_tooltipControl.onEnterFrame();
            }
            return ScriptStatus.SUCCESS;
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_tooltipControl.dispose();
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            // We perform the drawing of the button here since it's graphics require some special drawing
            var switchModelCanvas:DisplayObjectContainer = m_gameEngine.getUiEntity("switchModelButton") as DisplayObjectContainer;
            var switchModelButton:Button = WidgetUtil.createButton(
                m_assetManager,
                "button_sidebar_maximize",
                "button_sidebar_maximize_click",
                null,
                "button_sidebar_maximize_mouseover",
                null,
                null
            );
            switchModelButton.width = switchModelButton.height = 52;
            switchModelButton.pivotX = switchModelButton.width * 0.5;
            switchModelButton.pivotY = switchModelButton.height * 0.5;
            
            // Initial graphic has arrow pointing to the right
            // Make it point down
            switchModelButton.rotation = Math.PI * 0.5;
            m_inSlideDownState = true;
            
            switchModelButton.x += switchModelButton.pivotX;
            switchModelButton.y += switchModelButton.pivotY;
            
            m_switchModelButton = switchModelButton;
            switchModelCanvas.addChild(switchModelButton);
            
            m_tooltipControl = new TooltipControl(m_gameEngine, "switchModelButton", TOOLTIP_SHOW_EQUATION, "Verdana", 14);
            
            // Reset active flag
            this.setIsActive(m_isActive);
        }
        
        public function onSwitchModelClicked():void
        {
            Audio.instance.playSfx("page_flip");
            
            // Perform animation of the button rotating between pointing up and down.
            var uiContainer:DisplayObject = m_gameEngine.getUiEntity("deckAndTermContainer");
            var targetRotation:Number = 0.0;
            var targetY:Number = 0.0;
            if (m_inSlideDownState)
            {
                targetRotation = Math.PI * -0.5;
                targetY = this.targetY;
                m_tooltipControl.setText(TOOLTIP_SHOW_TEXT);
            }
            else
            {
                targetRotation = Math.PI * 0.5;
                targetY = m_deckAndTermContainerOriginalY;
                m_tooltipControl.setText(TOOLTIP_SHOW_EQUATION);
            }
            m_inSlideDownState = !m_inSlideDownState;
            
            if (m_onSwitchModelClick != null)
            {
                m_onSwitchModelClick(m_inSlideDownState);
            }
            
            var rotateDuration:Number = 0.2;
            var rotateTween:Tween = new Tween(m_switchModelButton, rotateDuration);
            rotateTween.animate("rotation", targetRotation);
            Starling.juggler.add(rotateTween);
            
            var slideTween:Tween = new Tween(uiContainer, rotateDuration);
            slideTween.animate("y", targetY);
            Starling.juggler.add(slideTween);
        }
    }
}