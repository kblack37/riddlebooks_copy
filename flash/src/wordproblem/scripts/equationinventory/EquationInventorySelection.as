package wordproblem.scripts.equationinventory
{
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
    import wordproblem.resource.AssetManager
    
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
    public class EquationInventorySelection extends BaseGameScript
    {
        private var m_deckAreaSystem:DeckAreaSystem;
        private var m_inventoryArea:ScrollGridWidget;
        private var m_textArea:TextAreaWidget;
        private var m_draggedItem:DisplayObject;
        private var m_selectedEntityId:String;
        private var m_currentLevel:WordProblemLevelData;
        
        /**
         * The equation the player player is currently trying to solve
         * (must be set from some other external system)
         */
        private var m_equationContainerInFocus:ExpressionContainer;
        
        private var m_termAreas:Vector.<TermAreaWidget>;
        
        /**
         * Keep track of the equations held by the player
         */
        private var m_itemComponentManager:ComponentManager;
        
        /**
         * Keep track of the current object the user has pressed down on.
         * Null if they are not pressed down on anything.
         */
        private var m_currentEntryPressed:RenderableComponent;
        
        /**
         * Record the last coordinates of a mouse press to check whether the mouse has
         * moved far enough to trigger a drag.
         */
        private var m_lastMousePressPoint:Point = new Point();
        
        public function EquationInventorySelection(gameEngine:IGameEngine, 
                                                   expressionCompiler:IExpressionTreeCompiler, 
                                                   assetManager:AssetManager, 
                                                   id:String=null, 
                                                   isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            var inventoryWidget:EquationInventoryWidget = m_gameEngine.getUiEntity("inventoryArea") as EquationInventoryWidget;
            m_inventoryArea = (inventoryWidget != null) ? inventoryWidget.getScrollArea() : null;
            m_textArea = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            
            m_termAreas = new Vector.<TermAreaWidget>();
            var termAreaDisplays:Vector.<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TermAreaWidget);
            for each (var termAreaDisplay:DisplayObject in termAreaDisplays)
            {
                m_termAreas.push(termAreaDisplay as TermAreaWidget);
            }
            
            m_itemComponentManager = m_gameEngine.getParagraphComponentManager("item");
            m_currentLevel = m_gameEngine.getCurrentLevel();
            
            setIsActive(m_isActive);
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            if (m_ready)
            {
                for (i = 0; i < m_termAreas.length; i++)
                {
                    termArea = m_termAreas[i];
                    termArea.removeEventListener(GameEvent.TERM_AREA_CHANGED, onTermAreaChanged);
                }
                
                if (value)
                {
                    var i:int = 0;
                    var termArea:TermAreaWidget;
                    for (i = 0; i < m_termAreas.length; i++)
                    {
                        termArea = m_termAreas[i];
                        termArea.addEventListener(GameEvent.TERM_AREA_CHANGED, onTermAreaChanged);
                    }
                }
            }
        }
        
        override public function dispose():void
        {
            setIsActive(false);
        }
        
        private const mousePoint:Point = new Point();
        private const localPoint:Point = new Point();
        private const objectGlobalBounds:Rectangle = new Rectangle();
        override public function visit():int
        {
            var mouseState:MouseState = m_gameEngine.getMouseState();
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
                var objectUnderPoint:RenderableComponent = m_inventoryArea.getObjectUnderPoint(mousePoint);
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
        
        public function getEquationInFocus():ExpressionContainer
        {
            return m_equationContainerInFocus;
        }
        
        /**
         * Flush the current contents of the term areas back into the given equation component
         */
        public function flushEquation(equation:ExpressionComponent, 
                                      termAreas:Vector.<TermAreaWidget>,
                                      compiler:IExpressionTreeCompiler, 
                                      componentManager:ComponentManager):void
        {
            const leftEvalArea:TermAreaWidget = termAreas[0];
            const rightEvalArea:TermAreaWidget = termAreas[1];
            if (leftEvalArea.getWidgetRoot() == null || rightEvalArea.getWidgetRoot() == null)
            {
                return;
            }
            var leftRoot:ExpressionNode = leftEvalArea.getWidgetRoot().getNode();
            var rightRoot:ExpressionNode = rightEvalArea.getWidgetRoot().getNode();
            
            // Only save the output if there are no wildcards to fulfill
            if (!ExpressionUtil.wildCardNodeExists(leftRoot) && !ExpressionUtil.wildCardNodeExists(rightRoot))
            {
                // If the right is an isolated variable then we re-order it to the left side
                if ((!leftRoot.isLeaf() || ExpressionUtil.isNodeNumeric(leftRoot)) && 
                    (!ExpressionUtil.isNodeNumeric(rightRoot) && rightRoot.isLeaf()))
                {
                    var tempRoot:ExpressionNode = leftRoot;
                    leftRoot = rightRoot;
                    rightRoot = tempRoot;
                }
                
                var newEquationRoot:ExpressionNode = ExpressionUtil.createOperatorTree(leftRoot, rightRoot, 
                    compiler.getVectorSpace(), compiler.getVectorSpace().getEqualityOperator());
                var outputEquation:String = compiler.decompileAtNode(newEquationRoot);
                const equationComponent:ExpressionComponent = componentManager.getComponentFromEntityIdAndType(
                    equation.entityId, 
                    ExpressionComponent.TYPE_ID
                ) as ExpressionComponent;
                equationComponent.setDecompiledEquation(outputEquation, newEquationRoot);
            }
        }
        
        private function onSelectSubstitutionArea(entry:RenderableComponent):void
        {
            const equationContainer:ExpressionContainer = entry.view as ExpressionContainer;
            
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
                }
                
                // Set up the newly select equation
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
        
        private function onStartDragFromSubstitution(entry:RenderableComponent, point:Point):void
        {
            // Create a copy of the sub widget that moves with the mouse, the dragged object will
            // be used to create substitutions.
            const draggedContainer:DisplayObject = entry.view;
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
        
        private function onTermAreaChanged():void
        {
            // Refresh the set of equations, since we always care about the contents of
            // both term areas we need to wait for both of them to be ready before we fetch
            // data from them.
            // This was not an issue in the modeling stage since modeling only ever affected on
            // term area at a given time.
            var termAreasReady:Boolean = true;
            for (i = 0; i < m_termAreas.length; i++)
            {
                if (!m_termAreas[i].isReady)
                {
                    termAreasReady = false;
                    break;
                }
            }
            
            var equationInFocus:ExpressionComponent = (m_equationContainerInFocus == null) ? null : m_equationContainerInFocus.getExpressionComponent();
            if (termAreasReady && equationInFocus != null)
            {
                flushEquation(equationInFocus, m_termAreas, m_expressionCompiler, m_itemComponentManager);
                
                // Make sure the deck contents matches the contents of the term area
                const subtrees:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
                for (var i:int = 0; i < m_termAreas.length; i++)
                {
                    const termArea:TermAreaWidget = m_termAreas[i];
                    if (termArea.getWidgetRoot() != null)
                    {
                        subtrees.push(termArea.getWidgetRoot().getNode());
                    }
                }
                
                // Get the unique symbols in each subtree and derive the union of the symbols.
                const isolationSymbols:Vector.<String> = ExpressionUtil.getUniqueSymbols(
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
        private function setupNewEquation(root:ExpressionNode, 
                                          termAreas:Vector.<TermAreaWidget>, 
                                          vectorSpace:IVectorSpace):void
        {
            const leftEvalArea:TermAreaWidget = termAreas[0];
            var leftRoot:ExpressionNode = ExpressionUtil.copy(root.left, vectorSpace);
            var newLeftTree:ExpressionTree = new ExpressionTree(vectorSpace, leftRoot);
            leftEvalArea.setTree(newLeftTree);
            leftEvalArea.buildTreeWidget();
            
            const rightEvalArea:TermAreaWidget = termAreas[1];
            var rightRoot:ExpressionNode = ExpressionUtil.copy(root.right, vectorSpace);
            var newRightTree:ExpressionTree = new ExpressionTree(vectorSpace, rightRoot)
            rightEvalArea.setTree(newRightTree);
            rightEvalArea.buildTreeWidget();
            
            const subtrees:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            subtrees.push(newLeftTree.getRoot(), newRightTree.getRoot());
            
            // Get the unique symbols in each subtree and derive the union of the symbols.
            const isolationSymbols:Vector.<String> = ExpressionUtil.getUniqueSymbols(
                subtrees, 
                m_expressionCompiler.getVectorSpace(),
                !m_currentLevel.getLevelRules().allowCardFlip
            );
            m_gameEngine.setDeckAreaContents(isolationSymbols, null, true);
        }
    }
}