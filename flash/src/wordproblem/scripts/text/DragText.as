package wordproblem.scripts.text
{
    import flash.geom.Point;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.math.util.MathUtil;
    import dragonbox.common.ui.MouseState;
    
    import wordproblem.display.Layer;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.ComponentManager;
    import wordproblem.engine.component.ExpressionComponent;
    import wordproblem.engine.component.RenderableComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.text.view.DocumentView;
    import wordproblem.engine.text.view.TextView;
    import wordproblem.engine.widget.DeckWidget;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.BaseGameScript;
    
    /**
     * Script that handles detecting mouse presses on the text and dispatching selection events.
     */
    public class DragText extends BaseGameScript
    {
        /**
         * Reference to the text area so we can detect mouse events on it
         */
        private var m_textAreaWidget:TextAreaWidget;
        
        /**
         * Global coordinates of the mouse
         */
        private const m_mousePoint:Point = new Point();
        
        /**
         * A temp variable that remember the last view that was pressed down on.
         * Is unset as soon as the mouse is released or a drag is started
         */
        private var m_viewPressedDownOn:DocumentView;
        
        /**
         * A temp variable to remember the last point that was pressed down on.
         */
        private var m_lastMouseDownPoint:Point;
        
        /**
         * The document view that was pressed or dragged
         */
        private var m_viewUnderMouse:DocumentView;
        
        public function DragText(gameEngine:IGameEngine, 
                                 compiler:IExpressionTreeCompiler, 
                                 assetManager:AssetManager, 
                                 id:String, 
                                 isActive:Boolean=true)
        {
            super(gameEngine, compiler, assetManager, id, isActive);
        }
        
        override public function visit():int
        {
            if (super.m_ready && super.m_isActive)
            {
                // The dragging of existing items and their release does not care about the layering
                // deactivation.
                var params:Object;
                var mouseState:MouseState = super.m_gameEngine.getMouseState();
                m_mousePoint.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
                if (mouseState.leftMouseDraggedThisFrame && m_viewPressedDownOn != null)
                {
                    // Check if we have exceeded some drag radius threshold
                    const startDrag:Boolean = !MathUtil.pointInCircle(m_lastMouseDownPoint, 5, m_mousePoint);
                    if (startDrag)
                    {
                        super.m_gameEngine.dispatchEventWith(GameEvent.START_DRAG_TEXT_AREA, false, {documentView:m_viewPressedDownOn, location:m_mousePoint.clone()});
                        m_viewPressedDownOn = null;
                    }
                }
                else if (mouseState.leftMouseReleasedThisFrame)
                {
                    // TODO: This had a guard that there was a valid view underneath the mouse
                    // this is was to prevent a mouse release over a text area from always firing an event
					if (m_viewUnderMouse != null)
					{
						var renderComponentUnderMouse:RenderableComponent = m_gameEngine.getUiEntityUnder(m_mousePoint);
						var uiComponentName:String = null;
						if (renderComponentUnderMouse != null)
						{
							uiComponentName = renderComponentUnderMouse.entityId;
						}
						
						// Log the phrase drop
						// Note: We want to make sure to log the drop before we actually execute the drop in the code, so that any additional logs that occur
						// (ie. expression found) come strictly after the drop in the logs.
                        var text:String = (m_viewUnderMouse is TextView) ? (m_viewUnderMouse as TextView).getTextField().text : "";
                        var expressionUnder:Array = viewContainsExpressionThatHasBeenModeled(m_viewUnderMouse);
						var dropIsAnExpression:Boolean = expressionUnder != null;
						
                        var loggingDetails_drop:Object = {
                            rawText:text, 
                            isExpression:dropIsAnExpression, 
							regionDropped: uiComponentName, 
							locationX:m_mousePoint.x, 
							locationY:m_mousePoint.y
                        }
						if (dropIsAnExpression)
						{
							loggingDetails_drop["expressionName"] = expressionUnder[0];
                            loggingDetails_drop["hasBeenModeled"] = expressionUnder[1];
						}
						m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.PHRASE_DROP_EVENT, false, loggingDetails_drop);
						
						// Release the phrase
						params = {view:m_viewUnderMouse, isExpression:dropIsAnExpression, regionDropped: uiComponentName, location:m_mousePoint};
						m_gameEngine.dispatchEventWith(GameEvent.RELEASE_TEXT_AREA, false, params);
					}
                    
                    m_viewPressedDownOn = null;
                    m_viewUnderMouse = null;
                }
                
                // Kill the mouse detection is text area is blocked
                if (Layer.getDisplayObjectIsInInactiveLayer(m_textAreaWidget))
                {
                    return ScriptStatus.FAIL;
                }
                
                // Need to check that we are within the bounding of this mask
                if (mouseState.leftMousePressedThisFrame)
                {
                    // The hit test should return the document view furthest down in the tree structure.
                    var hitView:DocumentView = m_textAreaWidget.hitTestDocumentView(m_mousePoint);
                    if (hitView != null)
                    {
                        m_lastMouseDownPoint = m_mousePoint.clone();
                        m_viewPressedDownOn = hitView;
                        m_viewUnderMouse = hitView;
                    }
					
					if (m_viewPressedDownOn != null)
					{
						// Press the phrase
                        var expressionPressed:Array = viewContainsExpressionThatHasBeenModeled(m_viewPressedDownOn);
						var pickupIsAnExpression:Boolean = expressionPressed != null;
						params = {view:m_viewPressedDownOn, isExpression:(expressionPressed != null) ? true : false}
						super.m_gameEngine.dispatchEventWith(GameEvent.PRESS_TEXT_AREA, false, params);
						
                        if (m_viewPressedDownOn is TextView)
                        {
    						// Log the phrase pickup
                            var loggingDetails_pickup:Object = {
                                rawText:(m_viewPressedDownOn as TextView).getTextField().text,
								isExpression:pickupIsAnExpression, 
								locationX:m_mousePoint.x, 
								locationY:m_mousePoint.y
                            }
							if (pickupIsAnExpression)
							{
								loggingDetails_pickup["expressionName"] = expressionPressed;
							}
							
    						m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.PHRASE_PICKUP_EVENT, false, loggingDetails_pickup);
                        }
					}
                }
            }
            
            return ScriptStatus.FAIL;
		
        }
        
        /** 
         * Rather than return a Boolean as the name might imply, return an Array including the expressionString of the term widget found and whether it has been found yet.
         * or null view is not an expression
         */
        private function viewContainsExpressionThatHasBeenModeled(aView:DocumentView):Array
        {
            var result:Array = null;
            var textComponentManager:ComponentManager = m_textAreaWidget.componentManager;
            var components:Vector.<Component> = textComponentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
            var numComponents:int = components.length;
            for (var i:int = 0; i < numComponents; i++) {
                var expressionComponent:ExpressionComponent = components[i] as ExpressionComponent;
                var documentIdBoundToExpression:String = expressionComponent.entityId;
                if(m_textAreaWidget.getViewIsInContainer(aView, documentIdBoundToExpression)) {
                    var deckComponentManager:ComponentManager = (m_gameEngine.getUiEntity("deckArea") as DeckWidget).componentManager;
                    var deckcomponents:Vector.<Component> = deckComponentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
                    var numDeckComponents:int = deckcomponents.length;
                    var hasBeenModeled:Boolean = false;
                    for (var j:int = 0; j < numDeckComponents; j++) {
                        var deckComponent:ExpressionComponent = deckcomponents[j] as ExpressionComponent;
                        var deckIdBoundToExpression:String = deckComponent.entityId;
                        if(expressionComponent.expressionString == deckComponent.expressionString) {
                            hasBeenModeled = deckComponent.hasBeenModeled;
                        }
                    }
                    result = [expressionComponent.expressionString, hasBeenModeled];
                    break;
                }
            }
            return result;
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            m_textAreaWidget = super.m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
        }
    }
}