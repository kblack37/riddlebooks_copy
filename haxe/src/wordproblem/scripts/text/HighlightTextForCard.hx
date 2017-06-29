package wordproblem.scripts.text;


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
class HighlightTextForCard extends ScriptNode
{
    private var m_gameEngine : IGameEngine;
    private var m_currentlyBlinkingTextAreaIds : Array<String>;
    private var m_textAreaWidget : TextAreaWidget;
    private var m_deckWidget : DeckWidget;
    
    public function new(gameEngine : IGameEngine,
            assetManager : AssetManager)
    {
        super();
        
        m_currentlyBlinkingTextAreaIds = new Array<String>();
        m_gameEngine = gameEngine;
        m_gameEngine.addEventListener(GameEvent.LEVEL_READY, onLevelReady);
    }
    
    override public function dispose() : Void
    {
        removeBlinks();
        
        m_gameEngine.removeEventListener(GameEvent.LEVEL_READY, onLevelReady);
        
        // Clean up the event listeners and dispose the animation
        m_gameEngine.removeEventListener(GameEvent.START_DRAG_DECK_AREA, onStartDrag);
        m_gameEngine.removeEventListener(GameEvent.START_DRAG_TERM_WIDGET, onStartDrag);
    }
    
    override public function visit() : Int
    {
        // The shimmer animation should trigger whenver a card is dragged
        // OR the user taps on a card in the deck or term area
        // If animation is already playing it should not restart
        // (occurs if they tap on the deck and then drag)
        
        // If the mouse is in an up position, the animation on the text should not be playing
        // HACK: This is assuming that scripts fire on the same update tick as the mouse
        var mouseState : MouseState = m_gameEngine.getMouseState();
        if (mouseState.leftMouseReleasedThisFrame) 
        {
            removeBlinks();
        }
        
        return ScriptStatus.RUNNING;
    }
    
    private function onLevelReady() : Void
    {
        m_textAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        
        m_deckWidget = try cast(m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null;
        
        m_gameEngine.addEventListener(GameEvent.START_DRAG_DECK_AREA, onStartDrag);
        m_gameEngine.addEventListener(GameEvent.START_DRAG_TERM_WIDGET, onStartDrag);
    }
    
    private function onStartDrag(event : Event, params : Dynamic) : Void
    {
        // Remove previous animation
        removeBlinks();
        
        var widget : BaseTermWidget = try cast(Reflect.field(params, "termWidget"), BaseTermWidget) catch(e:Dynamic) null;
        
        // Get the term value of the dragged widget, possibly ignore negative signs if
        // specified in the level config.
        
        var draggedTermValue : String = widget.getNode().data;
        findAndShimmerTextBoundToTerm(draggedTermValue);
    }
    
    private function findAndShimmerTextBoundToTerm(termValue : String) : Void
    {
        // Look through all sections of the text with matching term values and
        // apply some highlighting to them
        var documentIds : Array<String> = new Array<String>();
        var viewsToShimmer : Array<DocumentView> = new Array<DocumentView>();
        var expressionsInText : Array<Component> = m_textAreaWidget.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
        var numComponents : Int = expressionsInText.length;
        var i : Int;
        for (i in 0...numComponents){
            var expressionInText : ExpressionComponent = try cast(expressionsInText[i], ExpressionComponent) catch(e:Dynamic) null;
            
            if (termValue == expressionInText.expressionString) 
            {
                documentIds.push(expressionInText.entityId);
                
                var views : Array<DocumentView> = m_textAreaWidget.getDocumentViewsAtPageIndexById(expressionInText.entityId);
                var numViews : Int = views.length;
                var j : Int;
                for (j in 0...numViews){
                    var view : DocumentView = views[j];
                    
                    // Need to look at the node and trace up through its parents
                    // to see if it is hidden. Do not try to shimmer it if its hidden
                    var isHidden : Bool = false;
                    var viewTracker : DocumentView = view;
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
        }  /*
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
        */    // The blink system we have set up might not be appropriate    // Problem, a text id is not actually unique and might be attached to several views  
    }
    
    private function removeBlinks() : Void
    {
        for (blinkId in m_currentlyBlinkingTextAreaIds)
        {
            m_textAreaWidget.componentManager.removeComponentFromEntity(blinkId, BlinkComponent.TYPE_ID);
        }
        as3hx.Compat.setArrayLength(m_currentlyBlinkingTextAreaIds, 0);
    }
}
