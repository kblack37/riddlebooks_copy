package wordproblem.scripts.text
{
    import dragonbox.common.ui.MouseState;
    
    import starling.events.Event;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.component.BlinkComponent;
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.ExpressionComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.scripting.graph.ScriptNode;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.text.view.DocumentView;
    import wordproblem.engine.widget.DeckWidget;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.resource.AssetManager;
    
    /**
     * This script controls a visual effect on the part of the text that is associated
     * with a dragged card.
     */
    public class HighlightTextForCard extends ScriptNode
    {
        private var m_gameEngine:IGameEngine;
        private var m_currentlyBlinkingTextAreaIds:Vector.<String>;
        private var m_textAreaWidget:TextAreaWidget;
        private var m_deckWidget:DeckWidget;
        
        public function HighlightTextForCard(gameEngine:IGameEngine, 
                                     assetManager:AssetManager)
        {
            super();
            
            m_currentlyBlinkingTextAreaIds = new Vector.<String>();
            m_gameEngine = gameEngine;
            m_gameEngine.addEventListener(GameEvent.LEVEL_READY, onLevelReady);
        }
        
        override public function dispose():void
        {
            removeBlinks();
            
            m_gameEngine.removeEventListener(GameEvent.LEVEL_READY, onLevelReady);
            
            // Clean up the event listeners and dispose the animation
            m_gameEngine.removeEventListener(GameEvent.START_DRAG_DECK_AREA, onStartDrag);
            m_gameEngine.removeEventListener(GameEvent.START_DRAG_TERM_WIDGET, onStartDrag);
        }
        
        override public function visit():int
        {
            // The shimmer animation should trigger whenver a card is dragged
            // OR the user taps on a card in the deck or term area
            // If animation is already playing it should not restart
            // (occurs if they tap on the deck and then drag)
            
            // If the mouse is in an up position, the animation on the text should not be playing
            // HACK: This is assuming that scripts fire on the same update tick as the mouse
            const mouseState:MouseState = m_gameEngine.getMouseState();
            if (mouseState.leftMouseReleasedThisFrame)
            {
                removeBlinks();
            }
            
            return ScriptStatus.RUNNING;
        }
        
        private function onLevelReady():void
        {
            m_textAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            
            m_deckWidget = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
            
            m_gameEngine.addEventListener(GameEvent.START_DRAG_DECK_AREA, onStartDrag);
            m_gameEngine.addEventListener(GameEvent.START_DRAG_TERM_WIDGET, onStartDrag);
        }
        
        private function onStartDrag(event:Event, params:Object):void
        {
            // Remove previous animation
            removeBlinks();
            
            var widget:BaseTermWidget = params["termWidget"] as BaseTermWidget;
            
            // Get the term value of the dragged widget, possibly ignore negative signs if
            // specified in the level config.
            
            const draggedTermValue:String = widget.getNode().data;
            findAndShimmerTextBoundToTerm(draggedTermValue);
        }
        
        private function findAndShimmerTextBoundToTerm(termValue:String):void
        {
            // Look through all sections of the text with matching term values and
            // apply some highlighting to them
            var documentIds:Vector.<String> = new Vector.<String>();
            const viewsToShimmer:Vector.<DocumentView> = new Vector.<DocumentView>();
            const expressionsInText:Vector.<Component> = m_textAreaWidget.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
            const numComponents:int = expressionsInText.length;
            var i:int;
            for (i = 0; i < numComponents; i++)
            {
                var expressionInText:ExpressionComponent = expressionsInText[i] as ExpressionComponent;
                
                if (termValue == expressionInText.expressionString)
                {
                    documentIds.push(expressionInText.entityId);
                    
                    const views:Vector.<DocumentView> = m_textAreaWidget.getDocumentViewsAtPageIndexById(expressionInText.entityId);
                    const numViews:int = views.length;
                    var j:int;
                    for (j = 0; j < numViews; j++)
                    {
                        var view:DocumentView = views[j];
                        
                        // Need to look at the node and trace up through its parents
                        // to see if it is hidden. Do not try to shimmer it if its hidden
                        var isHidden:Boolean = false;
                        var viewTracker:DocumentView = view;
                        while (viewTracker != null)
                        {
                            if (!viewTracker.node.getIsVisible())
                            {
                                isHidden = true;
                                break;
                            }
                            viewTracker = viewTracker.parentView;
                        }
                        
                        if (!isHidden)
                        {
                            // Shimmer the childs nodes
                            view.getDocumentViewLeaves(viewsToShimmer);
                        }
                    }
                }
            }
            
            // Problem, a text id is not actually unique and might be attached to several views
            // The blink system we have set up might not be appropriate
            /*
            // Run animation only if there is in fact a view to highlight
            if (viewsToShimmer.length > 0)
            {
                for (i = 0; i < documentIds.length; i++)
                {
                    var entityId:String = documentIds[i];
                    var renderComponent:RenderableComponent = new RenderableComponent(entityId);
                    renderComponent.view = viewsToShimmer[i];
                    m_textAreaWidget.componentManager.addComponentToEntity(renderComponent);
                    
                    var blinkTextComponent:BlinkComponent = new BlinkComponent(entityId);
                    m_textAreaWidget.componentManager.addComponentToEntity(blinkTextComponent);
                }
            }
            */
        }
        
        private function removeBlinks():void
        {
            for each (var blinkId:String in m_currentlyBlinkingTextAreaIds)
            {
                m_textAreaWidget.componentManager.removeComponentFromEntity(blinkId, BlinkComponent.TYPE_ID);
            }
            m_currentlyBlinkingTextAreaIds.length = 0;
        }   
    }
}