package wordproblem.scripts.equationinventory;

import wordproblem.scripts.equationinventory.DeckAreaSystem;

import flash.geom.Point;
import flash.geom.Rectangle;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.ExpressionUtil;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.math.util.MathUtil;
import dragonbox.common.math.vectorspace.IVectorSpace;
import dragonbox.common.ui.MouseState;

import starling.display.DisplayObject;
import starling.extensions.textureutil.TextureUtil;
import wordproblem.resource.AssetManager;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.tree.ExpressionTree;
import wordproblem.engine.level.WordProblemLevelData;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.widget.EquationInventoryWidget;
import wordproblem.engine.widget.ExpressionContainer;
import wordproblem.engine.widget.ScrollGridWidget;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.engine.widget.TextAreaWidget;
import wordproblem.scripts.BaseGameScript;

/**
 * This script handles all the logic related to the player's equation inventory.
 * This includes added new equations to the collection and getting equation that
 * are dragged out of the widget
 */
class EquationInventorySelection extends BaseGameScript
{
    private var m_deckAreaSystem : DeckAreaSystem;
    private var m_inventoryArea : ScrollGridWidget;
    private var m_textArea : TextAreaWidget;
    private var m_draggedItem : DisplayObject;
    private var m_selectedEntityId : String;
    private var m_currentLevel : WordProblemLevelData;
    
    /**
     * The equation the player player is currently trying to solve
     * (must be set from some other external system)
     */
    private var m_equationContainerInFocus : ExpressionContainer;
    
    private var m_termAreas : Array<TermAreaWidget>;
    
    /**
     * Keep track of the equations held by the player
     */
    private var m_itemComponentManager : ComponentManager;
    
    /**
     * Keep track of the current object the user has pressed down on.
     * Null if they are not pressed down on anything.
     */
    private var m_currentEntryPressed : RenderableComponent;
    
    /**
     * Record the last coordinates of a mouse press to check whether the mouse has
     * moved far enough to trigger a drag.
     */
    private var m_lastMousePressPoint : Point = new Point();
    
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
        
        var inventoryWidget : EquationInventoryWidget = try cast(m_gameEngine.getUiEntity("inventoryArea"), EquationInventoryWidget) catch(e:Dynamic) null;
        m_inventoryArea = ((inventoryWidget != null)) ? inventoryWidget.getScrollArea() : null;
        m_textArea = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        
        m_termAreas = new Array<TermAreaWidget>();
        var termAreaDisplays : Array<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TermAreaWidget);
        for (termAreaDisplay in termAreaDisplays)
        {
            m_termAreas.push(try cast(termAreaDisplay, TermAreaWidget) catch(e:Dynamic) null);
        }
        
        m_itemComponentManager = m_gameEngine.getParagraphComponentManager("item");
        m_currentLevel = m_gameEngine.getCurrentLevel();
        
        setIsActive(m_isActive);
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_ready) 
        {
            for (i in 0...m_termAreas.length){
                termArea = m_termAreas[i];
                termArea.removeEventListener(GameEvent.TERM_AREA_CHANGED, onTermAreaChanged);
            }
            
            if (value) 
            {
                var i : Int = 0;
                var termArea : TermAreaWidget = null;
                for (i in 0...m_termAreas.length){
                    termArea = m_termAreas[i];
                    termArea.addEventListener(GameEvent.TERM_AREA_CHANGED, onTermAreaChanged);
                }
            }
        }
    }
    
    override public function dispose() : Void
    {
        setIsActive(false);
    }
    
    private var mousePoint : Point = new Point();
    private var localPoint : Point = new Point();
    private var objectGlobalBounds : Rectangle = new Rectangle();
    override public function visit() : Int
    {
        var mouseState : MouseState = m_gameEngine.getMouseState();
        mousePoint.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
        if (m_draggedItem != null) 
        {
            m_draggedItem.parent.globalToLocal(mousePoint, localPoint);
            m_draggedItem.x = localPoint.x;
            m_draggedItem.y = localPoint.y;
        }
        
        if (mouseState.leftMousePressedThisFrame) 
        {
            // Check if an object is under the point
            var objectUnderPoint : RenderableComponent = m_inventoryArea.getObjectUnderPoint(mousePoint);
            if (objectUnderPoint != null) 
            {
                m_currentEntryPressed = objectUnderPoint;
                m_lastMousePressPoint.setTo(mousePoint.x, mousePoint.y);
            }
        }
        else if (mouseState.leftMouseDraggedThisFrame && m_currentEntryPressed != null) 
        {
            if (!MathUtil.pointInCircle(m_lastMousePressPoint, 10, mousePoint)) 
            {
                this.onStartDragFromSubstitution(m_currentEntryPressed, mousePoint);
                m_currentEntryPressed = null;
            }
        }
        else if (mouseState.leftMouseReleasedThisFrame) 
        {
            if (m_currentEntryPressed != null) 
            {
                this.onSelectSubstitutionArea(m_currentEntryPressed);
                m_currentEntryPressed = null;
            }
            
            if (m_draggedItem != null) 
            {
                m_gameEngine.dispatchEventWith(GameEvent.ITEM_RELEASED_ON_DOCUMENT, false, [m_textArea, m_draggedItem, m_selectedEntityId]);
                m_draggedItem.removeFromParent(true);
                m_draggedItem = null;
            }
        }
        
        return ScriptStatus.SUCCESS;
    }
    
    public function getEquationInFocus() : ExpressionContainer
    {
        return m_equationContainerInFocus;
    }
    
    /**
     * Flush the current contents of the term areas back into the given equation component
     */
    public function flushEquation(equation : ExpressionComponent,
            termAreas : Array<TermAreaWidget>,
            compiler : IExpressionTreeCompiler,
            componentManager : ComponentManager) : Void
    {
        var leftEvalArea : TermAreaWidget = termAreas[0];
        var rightEvalArea : TermAreaWidget = termAreas[1];
        if (leftEvalArea.getWidgetRoot() == null || rightEvalArea.getWidgetRoot() == null) 
        {
            return;
        }
        var leftRoot : ExpressionNode = leftEvalArea.getWidgetRoot().getNode();
        var rightRoot : ExpressionNode = rightEvalArea.getWidgetRoot().getNode();
        
        // Only save the output if there are no wildcards to fulfill
        if (!ExpressionUtil.wildCardNodeExists(leftRoot) && !ExpressionUtil.wildCardNodeExists(rightRoot)) 
        {
            // If the right is an isolated variable then we re-order it to the left side
            if ((!leftRoot.isLeaf() || ExpressionUtil.isNodeNumeric(leftRoot)) &&
                (!ExpressionUtil.isNodeNumeric(rightRoot) && rightRoot.isLeaf())) 
            {
                var tempRoot : ExpressionNode = leftRoot;
                leftRoot = rightRoot;
                rightRoot = tempRoot;
            }
            
            var newEquationRoot : ExpressionNode = ExpressionUtil.createOperatorTree(leftRoot, rightRoot,
                    compiler.getVectorSpace(), compiler.getVectorSpace().getEqualityOperator());
            var outputEquation : String = compiler.decompileAtNode(newEquationRoot);
            var equationComponent : ExpressionComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                    equation.entityId,
                    ExpressionComponent.TYPE_ID
                    ), ExpressionComponent) catch(e:Dynamic) null;
            equationComponent.setDecompiledEquation(outputEquation, newEquationRoot);
        }
    }
    
    private function onSelectSubstitutionArea(entry : RenderableComponent) : Void
    {
        var equationContainer : ExpressionContainer = try cast(entry.view, ExpressionContainer) catch(e:Dynamic) null;
        
        if (equationContainer != null) 
        {
            // Flush the old equation
            if (m_equationContainerInFocus != null) 
            {
                this.flushEquation(
                        m_equationContainerInFocus.getExpressionComponent(),
                        m_termAreas,
                        m_expressionCompiler,
                        m_itemComponentManager
                        );
                m_equationContainerInFocus.setSelected(false);
            }  // Set up the newly select equation  
            
            
            
            setupNewEquation(equationContainer.getExpressionComponent().root, m_termAreas, m_expressionCompiler.getVectorSpace());
            m_equationContainerInFocus = equationContainer;
            m_equationContainerInFocus.setSelected(true);
        }
        else 
        {
            // Clicked on a regular inventory item show some description text
            
        }
        
        m_gameEngine.dispatchEventWith(GameEvent.SELECT_INVENTORY_AREA, false, [entry.entityId]);
    }
    
    private function onStartDragFromSubstitution(entry : RenderableComponent, point : Point) : Void
    {
        // Create a copy of the sub widget that moves with the mouse, the dragged object will
        // be used to create substitutions.
        var draggedContainer : DisplayObject = entry.view;
        if (draggedContainer == null) 
        {
            // Drag inventory item
            m_selectedEntityId = entry.entityId;
            m_draggedItem = TextureUtil.getImageFromDisplayObject(entry.view);
            m_draggedItem.pivotX = m_draggedItem.width / 2;
            m_draggedItem.pivotY = m_draggedItem.height / 2;
            entry.view.stage.addChild(m_draggedItem);
            
            m_gameEngine.dispatchEventWith(GameEvent.START_DRAG_INVENTORY_AREA, false, [entry, point]);
        }
        else 
        {
            m_gameEngine.dispatchEventWith(GameEvent.START_DRAG_INVENTORY_AREA, false, [entry, point]);
        }
    }
    
    private function onTermAreaChanged() : Void
    {
        // Refresh the set of equations, since we always care about the contents of
        // both term areas we need to wait for both of them to be ready before we fetch
        // data from them.
        // This was not an issue in the modeling stage since modeling only ever affected on
        // term area at a given time.
        var termAreasReady : Bool = true;
        for (i in 0...m_termAreas.length){
            if (!m_termAreas[i].isReady) 
            {
                termAreasReady = false;
                break;
            }
        }
        
        var equationInFocus : ExpressionComponent = ((m_equationContainerInFocus == null)) ? null : m_equationContainerInFocus.getExpressionComponent();
        if (termAreasReady && equationInFocus != null) 
        {
            flushEquation(equationInFocus, m_termAreas, m_expressionCompiler, m_itemComponentManager);
            
            // Make sure the deck contents matches the contents of the term area
            var subtrees : Array<ExpressionNode> = new Array<ExpressionNode>();
            for (i in 0...m_termAreas.length){
                var termArea : TermAreaWidget = m_termAreas[i];
                if (termArea.getWidgetRoot() != null) 
                {
                    subtrees.push(termArea.getWidgetRoot().getNode());
                }
            }  // Get the unique symbols in each subtree and derive the union of the symbols.  
            
            
            
            var isolationSymbols : Array<String> = ExpressionUtil.getUniqueSymbols(
                    subtrees,
                    m_expressionCompiler.getVectorSpace(),
                    !m_currentLevel.getLevelRules().allowCardFlip
                    );
            m_gameEngine.setDeckAreaContents(isolationSymbols, null, true);
        }
    }
    
    /**
     * Set a new pair of expressions to be displayed during the evaluation phase
     */
    private function setupNewEquation(root : ExpressionNode,
            termAreas : Array<TermAreaWidget>,
            vectorSpace : IVectorSpace) : Void
    {
        var leftEvalArea : TermAreaWidget = termAreas[0];
        var leftRoot : ExpressionNode = ExpressionUtil.copy(root.left, vectorSpace);
        var newLeftTree : ExpressionTree = new ExpressionTree(vectorSpace, leftRoot);
        leftEvalArea.setTree(newLeftTree);
        leftEvalArea.buildTreeWidget();
        
        var rightEvalArea : TermAreaWidget = termAreas[1];
        var rightRoot : ExpressionNode = ExpressionUtil.copy(root.right, vectorSpace);
        var newRightTree : ExpressionTree = new ExpressionTree(vectorSpace, rightRoot);
        rightEvalArea.setTree(newRightTree);
        rightEvalArea.buildTreeWidget();
        
        var subtrees : Array<ExpressionNode> = new Array<ExpressionNode>();
        subtrees.push(newLeftTree.getRoot());
        subtrees.push(newRightTree.getRoot());
        
        
        // Get the unique symbols in each subtree and derive the union of the symbols.
        var isolationSymbols : Array<String> = ExpressionUtil.getUniqueSymbols(
                subtrees,
                m_expressionCompiler.getVectorSpace(),
                !m_currentLevel.getLevelRules().allowCardFlip
                );
        m_gameEngine.setDeckAreaContents(isolationSymbols, null, true);
    }
}
