package wordproblem.scripts.deck
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import cgs.Audio.Audio;
    
    import starling.display.DisplayObject;
    import starling.events.Event;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.ExpressionComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.widget.DeckWidget;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.BaseGameScript;
    import wordproblem.scripts.drag.WidgetDragSystem;
    
    /**
     * Script to handle taking a dragged widget, detecting a slot it should fall into, and revealing it when it is released while
     * inside the hit bounds of a slot.
     */
    public class DiscoverTerm extends BaseGameScript
    {
        private var m_deckWidget:DeckWidget;
        private var m_widgetDragSystem:WidgetDragSystem;
        
        /**
         * Reference to the term in the deck that is still an empty slot that the card is over. This
         * is null if a dragged card is not over an empty slot.
         */
        private var m_hitEmptyTerm:BaseTermWidget;
        
        private const m_bounds:Rectangle = new Rectangle();
        private const m_origin:Point = new Point();
        
        public function DiscoverTerm(gameEngine:IGameEngine, 
                                     assetManager:AssetManager, 
                                     id:String=null)
        {
            super(gameEngine, null, assetManager, id);
        }
        
        override public function dispose():void
        {
            m_gameEngine.removeEventListener(GameEvent.END_DRAG_TERM_WIDGET, onEndDrag);
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            m_gameEngine.addEventListener(GameEvent.END_DRAG_TERM_WIDGET, onEndDrag);
            
            m_deckWidget = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
            m_widgetDragSystem = this.getNodeById("WidgetDragSystem") as WidgetDragSystem;
        }
        
        private function onEndDrag(event:Event, args:Object):void
        {
            var widget:BaseTermWidget = args.widget;
            var origin:DisplayObject = args.origin;
            
            // On any drag release of something from the text, we create a shortcut for it in the deck
            if (origin is TextAreaWidget)
            {
                // Only add the variable if the expression is not in the deck
                // OR it is hidden
                var expressionValueDragged:String = widget.getNode().data;
                var expressionComponents:Vector.<Component> = m_deckWidget.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
                var numExpressionsInDeck:int = expressionComponents.length;
                
                var expressionComponent:ExpressionComponent;
                var hiddenExpressionComponent:ExpressionComponent = null;
                var doAddNewExpressionValue:Boolean = true;
                var i:int;
                for (i = 0; i < numExpressionsInDeck; i++)
                {
                    expressionComponent = expressionComponents[i] as ExpressionComponent;
                    if (expressionComponent.expressionString == expressionValueDragged)
                    {
                        if (expressionComponent.hasBeenModeled)
                        {
                            doAddNewExpressionValue = false;
                        }
                        else
                        {
                            hiddenExpressionComponent = expressionComponent;
                        }
                        break;
                    }
                }
                
                if (doAddNewExpressionValue)
                {
                    // Handle case where we are just revealing a hidden card vs
                    // adding a brand new one
                    if (hiddenExpressionComponent == null)
                    {
                        var currentExpressions:Vector.<String> = new Vector.<String>();
                        var currentExpressionHidden:Vector.<Boolean> = new Vector.<Boolean>();
                        for (i = 0; i < numExpressionsInDeck; i++)
                        {
                            expressionComponent = expressionComponents[i] as ExpressionComponent;
                            currentExpressions.push(expressionComponent.expressionString);
                            currentExpressionHidden.push(!expressionComponent.hasBeenModeled);
                        }
                        
                        currentExpressions.push(expressionValueDragged);
                        currentExpressionHidden.push(false);
                        m_gameEngine.setDeckAreaContent(currentExpressions, currentExpressionHidden, true);
                        Audio.instance.playSfx("card2deck");
                    }
                    else
                    {
                        revealCard(expressionValueDragged);
                    }
                }
            }
        }
        
        public function revealCard(data:String):void
        {
            // Player can drop a term over ANY blank spot to fill it
            var widgetWithMatchingValue:BaseTermWidget = m_deckWidget.getWidgetFromSymbol(data);
            if (widgetWithMatchingValue != null && widgetWithMatchingValue.getIsHidden())
            {
				// Log expression found
				var loggingDetails:Object = {expressionName:widgetWithMatchingValue.getNode().toString(), isAlreadyFound:false};
                m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.EXPRESSION_FOUND_EVENT, false, loggingDetails);
                
                const expressionComponent:ExpressionComponent = m_deckWidget.componentManager.getComponentFromEntityIdAndType(
                    data, 
                    ExpressionComponent.TYPE_ID
                ) as ExpressionComponent;
                expressionComponent.hasBeenModeled = true;
                
                // Reveal the term and deactivate it in the paragraph
                widgetWithMatchingValue.setIsHidden(false);
                widgetWithMatchingValue.visible = false;
                
                // Terms in the modeling deck may need to be re-enabled as well, only if the current
                // segment requires the newly discovered term for modeling purposes.
                m_deckWidget.toggleSymbolEnabled(true, data);
                m_deckWidget.layout();
                
                Audio.instance.playSfx("card2deck");
                
                // Signal expression revealed
                var aComponent:ExpressionComponent = m_deckWidget.componentManager.getComponentFromEntityIdAndType(data, ExpressionComponent.TYPE_ID) as ExpressionComponent;
                var params:Object = {component:aComponent}
                m_gameEngine.dispatchEventWith(GameEvent.EXPRESSION_REVEALED, false, params);
            }
        }
    }
}