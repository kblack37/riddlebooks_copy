package wordproblem.scripts.text;


import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import wordproblem.engine.events.DataEvent;

import starling.events.Event;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.text.view.DocumentView;
import wordproblem.engine.widget.TextAreaWidget;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;

/**
	 * Script that draws a line through a piece of text that is bound to a card.
 * 
	 * @author Nathaniel Swedberg
	 */
class StrikeTextAfterDrop extends BaseGameScript
{
    private var m_textAreaWidget : TextAreaWidget;
    
    public function new(gameEngine : IGameEngine, compiler : IExpressionTreeCompiler, assetManager : AssetManager, id : String)
    {
        super(gameEngine, compiler, assetManager, id);
    }
    
    /**
		 * When the level starts add eventlisteners and call up the super
		 */
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        m_textAreaWidget = try cast(super.m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        super.m_gameEngine.addEventListener(GameEvent.EXPRESSION_REVEALED, onExpressionRevealed);
    }
    
    /**
		 * truggers when the event is called
		 * @param	event: the event 
		 * @param	param: passed in with the envent
		 */
    private function onExpressionRevealed(event : Dynamic) : Void
    {
        var components : Array<Component> = m_textAreaWidget.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
        var component : ExpressionComponent = (try cast(event, DataEvent) catch (e : Dynamic) null).getData().component;
        for (i in 0...components.length){
            var documentId : ExpressionComponent = try cast(components[i], ExpressionComponent) catch(e:Dynamic) null;
            if (documentId.expressionString == component.expressionString) 
            {
                var children : Array<DocumentView> = m_textAreaWidget.getDocumentViewsAtPageIndexById(documentId.entityId);
                for (c in children)
                {
                    c.node.setTextDecoration("line-through");
                    c.node.setSelectable(false);
                }
            }
        }
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        super.m_gameEngine.removeEventListener(GameEvent.EXPRESSION_REVEALED, onExpressionRevealed);
    }
}

