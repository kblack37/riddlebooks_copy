package wordproblem.scripts.expression;


import flash.geom.Point;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.WildCardNode;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.ui.MouseState;

import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.events.Event;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.animation.EmphasizeAnimation;
import wordproblem.engine.animation.PackingAnimation;
import wordproblem.engine.animation.SubstitutionAnimation;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.expression.event.ExpressionTreeEvent;
import wordproblem.engine.expression.tree.ExpressionTree;
import wordproblem.engine.expression.widget.ExpressionTreeWidget;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.level.WordProblemLevelData;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.widget.ExpressionContainer;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;

/**
 * This system handles the substitution operation. It will depend on the item selection system to tell it
 * when the player has started dragging a substitutable object. It will also modify the expression to take
 * in a substituted value.
 */
class SubstituteTerm extends BaseGameScript
{
    private var m_termAreas : Array<TermAreaWidget>;
    private var m_currentLevel : WordProblemLevelData;
    private var m_expressionSymbolMap : ExpressionSymbolMap;
    
    /**
     * The widget that is dragged around for the substitution phase, it is a copy
     */
    private var m_draggedSubstitutionWidget : BaseTermWidget;
    
    /**
     * A reference to the actual display object from which a draggable copy was made from
     */
    private var m_originalDraggedDisplayObject : DisplayObject;
    
    /**
     * Animation to show highlight a specific widget in a term area, used
     * to highlight items that are substitutable.
     */
    private var m_emphasizeAnimation : EmphasizeAnimation;
    
    /**
     * Animation to show parts of an equation filling into a definition variable.
     */
    private var m_packingAnimation : PackingAnimation;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        m_termAreas = new Array<TermAreaWidget>();
        var termAreaDisplays : Array<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TermAreaWidget);
        for (termAreaDisplay in termAreaDisplays)
        {
            m_termAreas.push(try cast(termAreaDisplay, TermAreaWidget) catch(e:Dynamic) null);
        }
        m_currentLevel = m_gameEngine.getCurrentLevel();
        m_expressionSymbolMap = m_gameEngine.getExpressionSymbolResources();
        
        m_emphasizeAnimation = new EmphasizeAnimation(m_assetManager);
        m_packingAnimation = new PackingAnimation();
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        if (m_isActive != value && m_ready) 
        {
            super.setIsActive(value);
            if (value) 
            {
                m_gameEngine.addEventListener(GameEvent.START_DRAG_INVENTORY_AREA, onStartDragFromSubstitution);
            }
            else 
            {
                m_gameEngine.removeEventListener(GameEvent.START_DRAG_INVENTORY_AREA, onStartDragFromSubstitution);
            }
        }
    }
    
    override public function dispose() : Void
    {
        setIsActive(false);
    }
    
    private var mousePoint : Point = new Point();
    private var localPoint : Point = new Point();
    override public function visit() : Int
    {
        var mouseState : MouseState = m_gameEngine.getMouseState();
        mousePoint.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
        
        // If object is being dragged the move it
        if (m_draggedSubstitutionWidget != null) 
        {
            // Update drag position
            m_draggedSubstitutionWidget.parent.globalToLocal(mousePoint, localPoint);
            m_draggedSubstitutionWidget.x = localPoint.x;
            m_draggedSubstitutionWidget.y = localPoint.y;
        }
        
        if (mouseState.leftMouseReleasedThisFrame) 
        {
            if (m_draggedSubstitutionWidget != null) 
            {
                this.onReleaseDragFromSubstitution(m_draggedSubstitutionWidget);
            }
        }
        
        return ScriptStatus.SUCCESS;
    }
    
    private function onStartDragFromSubstitution(event : Event, args : Array<Dynamic>) : Void
    {
        // Create a copy of the sub widget that moves with the mouse, the dragged object will
        // be used to create substitutions.
        var entry : RenderableComponent = args[0];
        var point : Point = args[1];
        var draggedContainer : ExpressionContainer = try cast(entry.view, ExpressionContainer) catch(e:Dynamic) null;
        if (draggedContainer != null) 
        {
            var equationWidgetRoot : BaseTermWidget = draggedContainer.getExpressionWidget().getWidgetRoot();
            
            if (equationWidgetRoot == null) 
            {
                return;
            }
            
            var definitionWidgetRoot : BaseTermWidget = equationWidgetRoot.leftChildWidget;
            
            // TODO: Should not be able to drag an equation that has already been selected
            // draggedContainer != m_itemSelectionSystem.getEquationInFocus() &&
            if (definitionWidgetRoot.getNode().isLeaf()) 
            {
                selectAndStartDrag(
                        equationWidgetRoot,
                        point.x + definitionWidgetRoot.width / 2 + equationWidgetRoot.mainGraphicBounds.width / 2,
                        point.y);
                
                // Look at each area and try to view which terms are compatible with what was just dragged
                // These terms should be highlighted
                var existingWidgetsThatCanSubstitute : Array<BaseTermWidget> = new Array<BaseTermWidget>();
                for (i in 0...m_termAreas.length){
                    var evaluationArea : TermAreaWidget = m_termAreas[i];
                    evaluationArea.getWidgetsMatchingData(
                            definitionWidgetRoot.getNode().data,
                            evaluationArea.getWidgetRoot(),
                            existingWidgetsThatCanSubstitute);
                }  // Highlight all terms that can be substituted  
                
                
                
                m_emphasizeAnimation.play(existingWidgetsThatCanSubstitute);
                Starling.juggler.add(m_emphasizeAnimation);
            }
        }
    }
    
    private function onReleaseDragFromSubstitution(equationWidget : BaseTermWidget) : Void
    {
        var equationRoot : ExpressionNode = equationWidget.getNode();
        // A release when we are in the evaluation phase might indicate an attempt to drop a selected
        // substitutable.
        for (i in 0...m_termAreas.length){
            var evaluationArea : TermAreaWidget = m_termAreas[i];
            
            // Check if the dragged object is over a symbol
            // If it is we then check whether the dragged symbol and the picked symbols are
            // the same, if they are then we can perform the replacement
            var pickedNodes : Array<BaseTermWidget> = evaluationArea.pickLeafWidgetsUnderObject(equationWidget.leftChildWidget);
            for (pickedNode in pickedNodes)
            {
                var pickedExpressionNode : ExpressionNode = pickedNode.getNode();
                var subExpressionNode : ExpressionNode = equationRoot.left;
                if (pickedExpressionNode.data == subExpressionNode.data) 
                {
                    var replacementSubtree : ExpressionNode = equationRoot.right;
                    evaluationArea.isReady = false;
                    evaluationArea.getTree().addEventListener(ExpressionTreeEvent.SUBSTITUTE, onSubstituteNode);
                    evaluationArea.getTree().replaceNode(pickedNode.getNode(), replacementSubtree);
                    
                    function onSubstituteNode(event : Event, data : Dynamic) : Void
                    {
                        evaluationArea.getTree().removeEventListener(ExpressionTreeEvent.SUBSTITUTE, onSubstituteNode);
                        
                        var nodeIdToReplace : Int = data.nodeIdToReplace;
                        var subtreeToReplace : ExpressionNode = data.subtreeToReplace;
                        
                        var widgetToReplace : BaseTermWidget = ExpressionTreeWidget.getWidgetFromId(nodeIdToReplace, evaluationArea.getWidgetRoot());
                        
                        if (Std.is(widgetToReplace.getNode(), WildCardNode)) 
                        {
                            evaluationArea.redrawAfterModification();
                        }
                        else 
                        {
                            // Play substitute animation
                            var substitutionAnimation : SubstitutionAnimation = new SubstitutionAnimation(
                            widgetToReplace, 
                            subtreeToReplace, 
                            evaluationArea, 
                            m_expressionCompiler.getVectorSpace(), 
                            m_assetManager, 
                            m_gameEngine.getExpressionSymbolResources(), 
                            evaluationArea, 
                            evaluationArea.getPreviewExpressionTreeWidget(), 
                            );
                            substitutionAnimation.play(evaluationArea.redrawAfterModification);
                        }
                    };
                    
                    break;
                }
            }
        }  // Kill the emphasize animation  
        
        
        
        m_emphasizeAnimation.stop();
        Starling.juggler.remove(m_emphasizeAnimation);
        
        if (m_draggedSubstitutionWidget != null) 
        {
            if (m_draggedSubstitutionWidget.parent != null) 
            {
                m_draggedSubstitutionWidget.parent.removeChild(m_draggedSubstitutionWidget);
            }
            
            m_draggedSubstitutionWidget = null;
        }
        
        m_originalDraggedDisplayObject.alpha = 1.0;
        m_originalDraggedDisplayObject = null;
    }
    
    private function selectAndStartDrag(widget : BaseTermWidget,
            x : Float,
            y : Float) : Void
    {
        m_originalDraggedDisplayObject = widget;
        m_originalDraggedDisplayObject.alpha = 0.3;
        
        // Instead of a single widget may need to reconstruct the entire tree
        var substituteTree : ExpressionTree = new ExpressionTree(m_expressionCompiler.getVectorSpace(), widget.getNode());
        var copy : ExpressionTreeWidget = new ExpressionTreeWidget(
        substituteTree, 
        m_expressionSymbolMap, 
        m_assetManager, 
        72 * 4, 
        72, 
        );
        copy.buildTreeWidget();
        
        var widgetCopy : BaseTermWidget = copy.getWidgetRoot();
        var parentContainer : DisplayObjectContainer = widget.stage;
        var localCoordinate : Point = parentContainer.globalToLocal(new Point(x, y));
        widgetCopy.x = localCoordinate.x;
        widgetCopy.y = localCoordinate.y;
        parentContainer.addChild(widgetCopy);
        
        // Play the packing animation
        m_packingAnimation.play(widgetCopy, m_expressionCompiler.getVectorSpace(), null);
        
        m_draggedSubstitutionWidget = widgetCopy;
    }
}
