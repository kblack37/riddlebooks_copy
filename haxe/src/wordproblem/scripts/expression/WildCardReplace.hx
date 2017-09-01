package wordproblem.scripts.expression;


import flash.geom.Point;
import wordproblem.engine.events.DataEvent;

import dragonbox.common.expressiontree.ExpressionUtil;
import dragonbox.common.expressiontree.WildCardNode;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import starling.events.Event;
import wordproblem.resource.AssetManager;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.expression.widget.term.SymbolTermWidget;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.scripts.drag.WidgetDragSystem;
import wordproblem.engine.widget.TermAreaWidget;

/**
 * This script handles detecting whether a dragged card from the player should satisfy wild card
 * that has intersected with that dragged card.
 */
class WildCardReplace extends BaseTermAreaScript
{
    /**
     * At any given frame what is the wild card widget that satisfies the constraints and
     * is intersecting the dragged card.
     */
    private var m_currentPickedWildCardWidget : BaseTermWidget;
    
    /**
     * The term area widget containing the picked wild card
     */
    private var m_termAreaContainingHitWildCard : TermAreaWidget;
    
    /**
     * A temp image of the dragged card, this is the thing that snaps to the wild card to indicate
     * it can accept it.
     * 
     * Purely for aesthetic purposes.
     */
    private var m_placeholderDraggedWidget : BaseTermWidget;
    
    /**
     * For introductory levels, may not be clear what values blank slots should be accepting.
     * Suppose we have the case where we want to model a+b=c+d. What each slot can accept changes
     * as the player is adding new cards. It is simpler for each level script to write it's own
     * logic.
     */
    private var m_wildcardValidateFunction : Function;
    
    /**
     * Create a single entry place where we have cards being dragged into term areas.
     * Hand over control of the dragged card that was removed
     */
    private var m_widgetDragSystem : WidgetDragSystem;
    
    private var m_pickedWidgetBuffer : Array<BaseTermWidget>;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager)
    {
        super(gameEngine, expressionCompiler, assetManager);
        
        m_wildcardValidateFunction = defaultWildcardValidateFunction;
        m_pickedWidgetBuffer = new Array<BaseTermWidget>();
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        m_gameEngine.removeEventListener(GameEvent.END_DRAG_TERM_WIDGET, onEndDragTermWidget);
    }
    
    override public function visit() : Int
    {
        if (super.m_ready) 
        {
            if (m_widgetDragSystem.getWidgetSelected() != null) 
            {
                var draggedWidget : BaseTermWidget = m_widgetDragSystem.getWidgetSelected();
                
                var i : Int = 0;
                var termArea : TermAreaWidget = null;
                for (i in 0...m_termAreas.length){
                    termArea = m_termAreas[i];
                    
                    as3hx.Compat.setArrayLength(m_pickedWidgetBuffer, 0);
                    termArea.pickLeafWidgetsUnderObject(draggedWidget, false, m_pickedWidgetBuffer);
                    
                    var numHitWidgets : Int = m_pickedWidgetBuffer.length;
                    var pickedWildCardWidgetForFrame : BaseTermWidget = null;
                    var pickedWidget : BaseTermWidget = null;
                    var j : Int = 0;
                    for (j in 0...numHitWidgets){
                        pickedWidget = m_pickedWidgetBuffer[j];
                        if (Std.is(pickedWidget.getNode(), WildCardNode)) 
                        {
                            // Validate whether the dragged node can correctly interact with the
                            // wild cards that were picked.
                            // Since levels each might have specific rules on what things are allowable for each
                            // slot, the validation function needs to be overridable.
                            var canWildCardAcceptDrag : Bool = m_wildcardValidateFunction(pickedWidget, draggedWidget, termArea);
                            if (canWildCardAcceptDrag) 
                            {
                                pickedWildCardWidgetForFrame = pickedWidget;
                                
                                // If the wild card hit is different from the one is a previous update then we trigger some
                                // snapping animation
                                // If it is the same we do not do anything
                                if (pickedWildCardWidgetForFrame != m_currentPickedWildCardWidget) 
                                {
                                    m_currentPickedWildCardWidget = pickedWildCardWidgetForFrame;
                                    
                                    m_placeholderDraggedWidget = new SymbolTermWidget(
                                            draggedWidget.getNode(), 
                                            m_gameEngine.getExpressionSymbolResources(), 
                                            m_assetManager, 
                                            );
                                    
                                    // Hide the dragged widget
                                    draggedWidget.visible = false;
                                    
                                    // Paste the temp card on the term area make sure it is positioned
                                    // right on top.
                                    var pickedWildCardCenter : Point = pickedWildCardWidgetForFrame.rigidBodyComponent.getCenterOfMass();
                                    m_placeholderDraggedWidget.x = pickedWildCardCenter.x;
                                    m_placeholderDraggedWidget.y = pickedWildCardCenter.y;
                                    termArea.addChild(m_placeholderDraggedWidget);
                                }
                            }
                        }
                    }  // No need to check other term areas if we detect a wild card intersect in one already  
                    
                    
                    
                    if (pickedWildCardWidgetForFrame != null) 
                    {
                        m_termAreaContainingHitWildCard = termArea;
                        break;
                    }
                }  // If we had some animation or snapped image beforehand we remove it.    // If no wild card was hit that means a dragged widget is not bound to anything  
                
                
                
                
                
                if (pickedWildCardWidgetForFrame == null && m_currentPickedWildCardWidget != null) 
                {
                    clearPreviousPickedWildCard();
                }
            }
            else 
            {
                // Nothing is being dragged.
                // Don't need to clear out because the event listener and the non-intersect case should do that already
                
            }
        }
        
        return ScriptStatus.SUCCESS;
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        
        m_widgetDragSystem = try cast(super.m_gameEngine.getParagraphGameSystemFromId("WidgetDragSystem"), WidgetDragSystem) catch(e:Dynamic) null;
        
        m_gameEngine.addEventListener(GameEvent.END_DRAG_TERM_WIDGET, onEndDragTermWidget);
    }
    
    
    private function defaultWildcardValidateFunction(wildCardWidget : BaseTermWidget,
            draggedWidget : BaseTermWidget,
            termArea : TermAreaWidget) : Bool
    {
        // Default behavior is that wild cards that are placeholders will only accept terms that have
        // the same data value as the placehold AND those that are not placeholders will accept anything
        var wildCardCompatibleWithDragged : Bool = true;
        var wildCardNode : WildCardNode = try cast(wildCardWidget.getNode(), WildCardNode) catch(e:Dynamic) null;
        if (wildCardNode.data != null) 
        {
            wildCardNode.data == draggedWidget.getNode().data;
        }
        
        return wildCardCompatibleWithDragged;
    }
    
    private function clearPreviousPickedWildCard() : Void
    {
        m_placeholderDraggedWidget.removeFromParent(true);
        m_placeholderDraggedWidget = null;
        m_currentPickedWildCardWidget = null;
        
        if (m_widgetDragSystem.getWidgetSelected() != null) 
        {
            m_widgetDragSystem.getWidgetSelected().visible = true;
        }
        
        m_termAreaContainingHitWildCard = null;
    }
    
    private function onEndDragTermWidget(event : Dynamic) : Void
    {
		if (Std.is(event, DataEvent)) {
			var data = (try cast (event, DataEvent) catch (e : Dynamic) null).getData();
			var releasedWidget : BaseTermWidget = try cast(data.widget, BaseTermWidget) catch(e:Dynamic) null;
			var releasedWidgetOrigin : String = data.origin;
			
			// We are interested in the case where the player drops a card that was intersecting a wild card.
			// For this situation, if the drop is valid we perform a replacements in the appropriate term area
			var addSuccessful : Bool = false;
			if (m_currentPickedWildCardWidget != null) 
			{
				m_termAreaContainingHitWildCard.isReady = false;
				m_termAreaContainingHitWildCard.getTree().replaceNode(m_currentPickedWildCardWidget.getNode(), ExpressionUtil.copy(releasedWidget.getNode(), m_expressionCompiler.getVectorSpace()));
				m_termAreaContainingHitWildCard.redrawAfterModification();
				
				addSuccessful = true;
				clearPreviousPickedWildCard();
			} 
			
			// Either snap back the widget to the deck if the add was not successful  
			if (releasedWidgetOrigin == WidgetDragSystem.DRAG_ORIGIN_DECK) 
			{
				m_gameEngine.dispatchEvent(new DataEvent(GameEvent.ADD_TERM_ATTEMPTED, {
                        widget : releasedWidgit,
                        success : addSuccessful,
                    }));
			}
		}
    }
}
