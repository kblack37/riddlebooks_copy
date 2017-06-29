package wordproblem.scripts.expression;

import wordproblem.scripts.expression.BaseTermAreaScript;

import flash.geom.Point;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.ExpressionUtil;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.math.vectorspace.IVectorSpace;
import dragonbox.common.ui.MouseState;

import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.events.Event;
import starling.events.EventDispatcher;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.animation.AddCardsAnimation;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.expression.event.ExpressionTreeEvent;
import wordproblem.engine.expression.widget.manager.SnapManager;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.expression.widget.term.SymbolTermWidget;
import wordproblem.engine.level.LevelRules;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.drag.WidgetDragSystem;

/**
 * This script handles adding new cards to a term area widget
 */
class AddTerm extends BaseTermAreaScript
{
    private var m_snapManagers : Array<SnapManager>;
    
    /**
     * Need access to the controller that handles keeping track of dragged objects
     */
    private var m_widgetDragSystem : WidgetDragSystem;
    
    /**
     * Animation for show added cards smoothly snapping into place
     */
    private var m_addCardAnimation : AddCardsAnimation;
    
    /**
     * If not null, then an image of the addition sign pulses next to the dragged widget
     */
    private var m_additionPreviewTween : Tween;
    private var m_additionPreviewImage : Image;
    private var m_additionPreviewCanvas : DisplayObjectContainer;
    
    private var m_expressionSymbolMap : ExpressionSymbolMap;
    
    private var m_globalMouseBuffer : Point = new Point();
    private var m_localMouseBuffer : Point = new Point();
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_addCardAnimation = new AddCardsAnimation();
        
        m_additionPreviewImage = new Image(m_assetManager.getTexture("add"));
        m_additionPreviewImage.pivotX = m_additionPreviewImage.width * 0.5;
        m_additionPreviewImage.pivotY = m_additionPreviewImage.height * 0.5;
    }
    
    public function setParams(termAreas : Array<TermAreaWidget>,
            levelRules : LevelRules,
            gameEngineEventDispatcher : EventDispatcher,
            mouseState : MouseState,
            widgetDragSystem : WidgetDragSystem,
            additionPreviewCanvas : DisplayObjectContainer,
            expressionSymbolMap : ExpressionSymbolMap) : Void
    {
        super.setCommonParams(termAreas, levelRules, gameEngineEventDispatcher, mouseState);
        
        m_widgetDragSystem = widgetDragSystem;
        m_additionPreviewCanvas = additionPreviewCanvas;
        
        m_snapManagers = new Array<SnapManager>();
        m_expressionSymbolMap = expressionSymbolMap;
        
        for (i in 0...termAreas.length){
            var termArea : TermAreaWidget = termAreas[i];
            m_snapManagers.push(new SnapManager(
                    termArea, 
                    levelRules, 
                    m_expressionCompiler.getVectorSpace(), 
                    m_assetManager, 
                    expressionSymbolMap, 
                    ));
        }
        
        this.setIsActive(true);
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_ready) 
        {
            m_eventDispatcher.removeEventListener(GameEvent.END_DRAG_TERM_WIDGET, bufferEvent);
            m_eventDispatcher.removeEventListener(GameEvent.END_DRAG_EXISTING_TERM_WIDGET, bufferEvent);
            if (value) 
            {
                m_eventDispatcher.addEventListener(GameEvent.END_DRAG_TERM_WIDGET, bufferEvent);
                m_eventDispatcher.addEventListener(GameEvent.END_DRAG_EXISTING_TERM_WIDGET, bufferEvent);
            }
        }
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        if (m_additionPreviewTween != null) 
        {
            Starling.juggler.remove(m_additionPreviewTween);
        }
        m_additionPreviewImage.removeFromParent(true);
    }
    
    override public function visit() : Int
    {
        if (m_ready && m_isActive) 
        {
            iterateThroughBufferedEvents();
            
            m_globalMouseBuffer.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
            
            var draggedWidget : BaseTermWidget = m_widgetDragSystem.getWidgetSelected();
            var numTermAreas : Int = m_termAreas.length;
            for (i in 0...numTermAreas){
                // Snapping shows a preview of the divide or multiply being applied
                // (Always must update the snap managers
                var termArea : TermAreaWidget = m_termAreas[i];
                if (termArea.isInteractable) 
                {
                    var numNodes : Int = ExpressionUtil.nodeCount(termArea.getTree().getRoot(), true);
                    if ((termArea.maxCardAllowed < 0 || termArea.maxCardAllowed > numNodes) &&
                        (!termArea.restrictValues || (draggedWidget != null && termArea.restrictedValues.indexOf(draggedWidget.getNode().data) > -1))) 
                    {
                        var snapManager : SnapManager = m_snapManagers[i];
                        snapManager.update(m_mouseState, draggedWidget);
                    }
                }
            }  // Preview for add only valid if something is being dragged    // Check if we should show a small addition image to signal to the player that adding the dragged card is allowed  
            
            
            
            
            
            var showAddPreviewForFrame : Bool = false;
            if (draggedWidget != null && canPerformAddition()) 
            {
                for (i in 0...numTermAreas){
                    termArea = m_termAreas[i];
                    if (termArea.isInteractable && termArea.containsPoint(m_globalMouseBuffer)) 
                    {
                        snapManager = m_snapManagers[i];
                        
                        // If no snap and mouse is in a term area then we want to give feed back that the
                        // current orientation will cause an add to occur
                        if (snapManager.getOperatorForSnap() == null) 
                        {
                            showAddPreviewForFrame = true;
                        }  // We assume term areas do not overlap so stop search after first hit  
                        
                        
                        
                        break;
                    }
                }
            }  // Clear the add preview if it was  
            
            
            
            if (showAddPreviewForFrame) 
            {
                var scaleUpFactor : Float = 1.5;
                if (m_additionPreviewTween == null) 
                {
                    m_additionPreviewTween = new Tween(m_additionPreviewImage, 0.7);
                    m_additionPreviewTween.scaleTo(scaleUpFactor);
                    m_additionPreviewTween.reverse = true;
                    m_additionPreviewTween.repeatCount = 0;
                    Starling.juggler.add(m_additionPreviewTween);
                    
                    m_additionPreviewCanvas.addChild(m_additionPreviewImage);
                }  // Convert the global mouse point to the reference frame of the canvas    // The addition preview should be positioned just around the mouse  
                
                
                
                
                
                m_additionPreviewCanvas.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
                m_additionPreviewImage.x = m_localMouseBuffer.x - (draggedWidget.width * 0.5) - m_additionPreviewImage.pivotX * scaleUpFactor;
                m_additionPreviewImage.y = m_localMouseBuffer.y;
            }
            else if (!showAddPreviewForFrame && m_additionPreviewTween != null) 
            {
                Starling.juggler.remove(m_additionPreviewTween);
                m_additionPreviewImage.removeFromParent();
                m_additionPreviewImage.scaleX = m_additionPreviewImage.scaleY = 1.0;
                m_additionPreviewTween = null;
            }
        }
        
        return ScriptStatus.SUCCESS;
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.END_DRAG_EXISTING_TERM_WIDGET || eventType == GameEvent.END_DRAG_TERM_WIDGET) 
        {
            onReleaseDraggedWidget(eventType, param);
        }
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        // TODO: Need to repeat some of the initialization
        m_widgetDragSystem = try cast(this.getNodeById("WidgetDragSystem"), WidgetDragSystem) catch(e:Dynamic) null;
        m_snapManagers = new Array<SnapManager>();
        m_additionPreviewCanvas = m_gameEngine.getSprite();
        m_expressionSymbolMap = m_gameEngine.getExpressionSymbolResources();
        
        for (i in 0...super.m_termAreas.length){
            var termArea : TermAreaWidget = super.m_termAreas[i];
            m_snapManagers.push(new SnapManager(
                    termArea, 
                    m_gameEngine.getCurrentLevel().getLevelRules(), 
                    m_expressionCompiler.getVectorSpace(), 
                    m_assetManager, 
                    m_expressionSymbolMap, 
                    ));
        }
        
        this.setIsActive(m_isActive);
    }
    
    private function canPerformAddition() : Bool
    {
        var canPerformAddition : Bool = true;
        if (m_gameEngine != null) 
        {
            canPerformAddition = m_gameEngine.getCurrentLevel().getLevelRules().allowAddition;
        }
        
        return canPerformAddition;
    }
    
    private function onReleaseDraggedWidget(eventType : String, args : Dynamic) : Void
    {
        var releasedWidgit : BaseTermWidget = args.widget;
        var releasedWidgetOrigin : DisplayObject = args.origin;
        
        if (Std.is(releasedWidgit, SymbolTermWidget)) 
        {
            var data : String = releasedWidgit.getNode().data;
            var addSuccessful : Bool = false;
            var readdedToDisplay : Bool = false;
            for (i in 0...m_termAreas.length){
                var termArea : TermAreaWidget = m_termAreas[i];
                
                // HACK need to re-add widget so we can get whether the bounds are in the term area
                if (releasedWidgit.parent == null) 
                {
                    readdedToDisplay = true;
                    termArea.stage.addChild(releasedWidgit);
                }
                
                var numNodes : Int = ExpressionUtil.nodeCount(termArea.getTree().getRoot(), true);
                
                // If we are in the bounds of the hit area, we attempt to add the node represented by the
                // released object into the specified term area.
                if (termArea.isInteractable && termArea.containsObject(releasedWidgit) &&
                    (termArea.maxCardAllowed < 0 || termArea.maxCardAllowed > numNodes) &&
                    (!termArea.restrictValues || termArea.restrictedValues.indexOf(data) > -1)) 
                {
                    var snapManagerForArea : SnapManager = m_snapManagers[i];
                    addSuccessful = attemptToAddSelectedNode(data, termArea, snapManagerForArea);
                    
                    // Dispatch event whether adding a card was successful or not
                    m_eventDispatcher.dispatchEventWith(GameEvent.ADD_TERM_ATTEMPTED, false, {
                                widget : releasedWidgit,
                                success : addSuccessful,

                            });
                    if (addSuccessful) 
                    {
                        m_eventDispatcher.dispatchEventWith(GameEvent.EQUATION_CHANGED);
                    }
                    break;
                }
            }
            
            if (readdedToDisplay) 
            {
                releasedWidgit.removeFromParent();
            }
        }
    }
    
    /**
     * Attempt to add a single new node into one of the term areas
     * 
     * @return
     *      True if the add was successful
     */
    private function attemptToAddSelectedNode(data : String,
            hitTermArea : TermAreaWidget,
            snapManager : SnapManager) : Bool
    {
        var addSuccessful : Bool = false;
        var vectorSpace : IVectorSpace = m_expressionCompiler.getVectorSpace();
        
        // If we are in the bounds of the hit area and we were not snapped
        // to anything then we perform an addition
        // If there are any wild card nodes we only allow operations that satisfy the
        // wild card
        var wildCardExists : Bool = false;
        for (i in 0...m_termAreas.length){
            var termArea : TermAreaWidget = m_termAreas[i];
            var widgetRoot : BaseTermWidget = termArea.getWidgetRoot();
            if (widgetRoot != null && ExpressionUtil.wildCardNodeExists(widgetRoot.getNode())) 
            {
                wildCardExists = true;
                break;
            }
        }
        
        if (wildCardExists) 
        {
            // Wild card is resolved only if the dragged node's data matches the expected data of
            // the wild card
            if (snapManager.getWidgetAcceptingSnap() != null) 
            {
                var wildcardSnappedTo : ExpressionNode = snapManager.getWidgetAcceptingSnap().getNode();
                if (wildcardSnappedTo.data == data) 
                {
                    addSuccessful = true;
                    hitTermArea.isReady = false;
                    hitTermArea.getTree().replaceNode(wildcardSnappedTo, new ExpressionNode(m_expressionCompiler.getVectorSpace(), data));
                    hitTermArea.redrawAfterModification();
                }
            }
        }
        // If no wild cards exist then the attempt to add new nodes may result in the addition
        // of new wild cards if the rules allow
        else if (m_levelRules.allowImbalance) 
        {
            // TODO: we have two modes for this system
            // one is for modeling and the other is for evaluation
            // If we are in the bounds of the hit area and we were not snapped
            // to anything then we perform an addition
            if (snapManager.getWidgetAcceptingSnap() != null) 
            {
                operator = snapManager.getOperatorForSnap();
                var attachToLeft : Bool = snapManager.getSnapToLeft();
                var nodeSnappedTo : ExpressionNode = snapManager.getWidgetAcceptingSnap().getNode();
                snapManager.clearAll();
                
                addSuccessful = true;
                this.addNode(
                        hitTermArea,
                        data,
                        operator,
                        m_globalMouseBuffer,
                        nodeSnappedTo,
                        attachToLeft,
                        false
                        );
            }
            else if (hitTermArea.isInteractable && canPerformAddition()) 
            {
                addSuccessful = true;
                nodeSnappedTo = null;
                attachToLeft = true;
                
                // When adding a new node, we may end up having to place the new node in between
                // others. This is mostly to handle when the equation is inline.
                // gather all the addition terms. Compare the global position of the node to
                // the mouse drop point
                var root : ExpressionNode = ((hitTermArea.getWidgetRoot() != null)) ? hitTermArea.getWidgetRoot().getNode() : null;
                
                if (root != null) 
                {
                    var additiveTermNodes : Array<ExpressionNode> = new Array<ExpressionNode>();
                    var nodeGlobalBuffer : Point = new Point();
                    var nodeLocalBuffer : Point = new Point();
                    ExpressionUtil.getAdditiveTerms(root, additiveTermNodes);
                    var additiveTerm : ExpressionNode;
                    for (i in 0...additiveTermNodes.length){
                        additiveTerm = additiveTermNodes[i];
                        nodeLocalBuffer.setTo(additiveTerm.position.x, additiveTerm.position.y);
                        hitTermArea.localToGlobal(nodeLocalBuffer, nodeGlobalBuffer);
                        
                        // Cases to deal with:
                        // -No other terms
                        // -Left of the furthest left term
                        // -Right of the furthest right term
                        // -Normal case is to add the new node as a left sibling of the
                        // first node it is to the left of
                        if (m_globalMouseBuffer.x < nodeGlobalBuffer.x) 
                        {
                            // Stop at this node, it is further right than drop point.
                            nodeSnappedTo = additiveTerm;
                            break;
                        }
                    }  // or we add it farthest right    // If we did not encounter a node in the above loop, then there wasn't any content  
                    
                    
                    
                    
                    
                    if (additiveTermNodes.length > 0 && nodeSnappedTo == null) 
                    {
                        attachToLeft = false;
                    }
                }
                
                this.addNode(
                        hitTermArea,
                        data,
                        m_expressionCompiler.getVectorSpace().getAdditionOperator(),
                        m_globalMouseBuffer,
                        nodeSnappedTo,
                        attachToLeft
                        );
            }
        }
        else 
        {
            // Distinguish between mult/div and addition as mult/div will requires putting wild cards
            // on every new group of nodes.
            if (snapManager.getWidgetAcceptingSnap() != null) 
            {
                var dataToAdd : Array<String> = new Array<String>();
                var operators : Array<String> = new Array<String>();
                var dropLocationsX : Array<Float> = new Array<Float>();
                var dropLocationsY : Array<Float> = new Array<Float>();
                var nodesToAttachTo : Array<ExpressionNode> = new Array<ExpressionNode>();
                var attachToLeftList : Array<Bool> = new Array<Bool>();
                dataToAdd.push(data);
                
                var operator : String = snapManager.getOperatorForSnap();
                operators.push(operator);
                dropLocationsX.push(m_globalMouseBuffer.x);
                dropLocationsY.push(m_globalMouseBuffer.y);
                attachToLeftList.push(snapManager.getSnapToLeft());
                
                var nodeAcceptingSnap : ExpressionNode = snapManager.getWidgetAcceptingSnap().getNode();
                nodesToAttachTo.push(nodeAcceptingSnap);
                snapManager.clearAll();
                
                // In the case where we multiply a denominator we really want to divide every other group
                if (ExpressionUtil.isNodePartOfDenominator(vectorSpace, nodeAcceptingSnap)) 
                {
                    operator = vectorSpace.getDivisionOperator();
                }  // Need to do this hear since parameters might be cleared in the loop below    // group containing the snapped node (this already has the data to be attached)    // Fill in wild cards for the just hit term area with the exception of the  
                
                
                
                
                
                
                
                var groupRoots : Array<ExpressionNode> = new Array<ExpressionNode>();
                ExpressionUtil.getCommutativeGroupRoots(
                        hitTermArea.getWidgetRoot().getNode(),
                        vectorSpace.getAdditionOperator(),
                        groupRoots);
                fillGroupsWithWildCards(
                        data,
                        groupRoots,
                        operator,
                        nodeAcceptingSnap,
                        dataToAdd,
                        operators,
                        dropLocationsX,
                        dropLocationsY,
                        nodesToAttachTo,
                        attachToLeftList,
                        hitTermArea
                        );
                addSuccessful = true;
                this.addNodeBatch(hitTermArea, dataToAdd, operators, dropLocationsX, dropLocationsY, nodesToAttachTo, attachToLeftList);
                
                // Fill all groups with wildcards in other term areas
                for (i in 0...m_termAreas.length){
                    termArea = m_termAreas[i];
                    
                    if (termArea != hitTermArea) 
                    {
                        // Need to reset parameters for just this area
                        dataToAdd = new Array<String>();
                        operators = new Array<String>();
                        dropLocationsX = new Array<Float>();
                        dropLocationsY = new Array<Float>();
                        nodesToAttachTo = new Array<ExpressionNode>();
                        attachToLeftList = new Array<Bool>();
                        groupRoots = new Array<ExpressionNode>();
                        ExpressionUtil.getCommutativeGroupRoots(
                                termArea.getWidgetRoot().getNode(),
                                vectorSpace.getAdditionOperator(),
                                groupRoots);
                        fillGroupsWithWildCards(
                                data,
                                groupRoots,
                                operator,
                                nodeAcceptingSnap,
                                dataToAdd,
                                operators,
                                dropLocationsX,
                                dropLocationsY,
                                nodesToAttachTo,
                                attachToLeftList,
                                termArea
                                );
                        this.addNodeBatch(termArea, dataToAdd, operators, dropLocationsX, dropLocationsY, nodesToAttachTo, attachToLeftList);
                    }
                }
            }
            else 
            {
                addSuccessful = true;
                this.addNode(
                        hitTermArea,
                        data,
                        vectorSpace.getAdditionOperator(),
                        m_globalMouseBuffer
                        );
                
                // Add wild card to the side opposite to that which the new card was just added
                for (i in 0...m_termAreas.length){
                    termArea = m_termAreas[i];
                    if (termArea != hitTermArea) 
                    {
                        this.addNode(
                                hitTermArea,
                                "?_" + data,
                                vectorSpace.getAdditionOperator(),
                                m_globalMouseBuffer
                                );
                    }
                }
            }
        }
        
        return addSuccessful;
    }
    
    private function fillGroupsWithWildCards(expectedValue : String,
            groupRoots : Array<ExpressionNode>,
            operator : String,
            nodeToExclude : ExpressionNode,
            outDataToAdd : Array<String>,
            outOperators : Array<String>,
            outDropLocationsX : Array<Float>,
            outDropLocationsY : Array<Float>,
            outNodesToAttachTo : Array<ExpressionNode>,
            outAttachToLeftList : Array<Bool>,
            termArea : TermAreaWidget) : Void
    {
        // Like the latex compiler, the incoming data needs to be formatted properly in order for wild cards
        // to be created
        
        var vectorSpace : IVectorSpace = m_expressionCompiler.getVectorSpace();
        var nodeToAttachTo : ExpressionNode;
        var attachToLeft : Bool;
        var operatorToUse : String;
        for (groupRoot in groupRoots)
        {
            // Exclude the root containing the specified node that accepted the expectedValue
            if (!ExpressionUtil.containsNode(groupRoot, nodeToExclude)) 
            {
                outDataToAdd.push("?_" + expectedValue);
                outDropLocationsX.push(m_globalMouseBuffer.x);
                outDropLocationsY.push(m_globalMouseBuffer.y);
                
                operatorToUse = operator;
                
                if (operator == vectorSpace.getMultiplicationOperator()) 
                {
                    // If the group root is a division or multiplication then we multiply the left child
                    // If its a leaf, we multiply the group root directly
                    attachToLeft = false;
                    if (groupRoot.isLeaf()) 
                    {
                        nodeToAttachTo = groupRoot;
                    }
                    else 
                    {
                        nodeToAttachTo = groupRoot.left;
                    }
                }
                else if (operator == vectorSpace.getDivisionOperator()) 
                {
                    // If the group root is a division, we multiply the right child
                    // If its a multiplication or a leaf, we divide the root directly
                    attachToLeft = false;
                    if (groupRoot.isSpecificOperator(vectorSpace.getDivisionOperator())) 
                    {
                        operatorToUse = vectorSpace.getMultiplicationOperator();
                        nodeToAttachTo = groupRoot.right;
                    }
                    else 
                    {
                        nodeToAttachTo = groupRoot;
                    }
                }
                
                outOperators.push(operator);
                outNodesToAttachTo.push(nodeToAttachTo);
                outAttachToLeftList.push(attachToLeft);
            }
        }
    }
    
    /**
     * Add brand new node to visualize in the term area
     * 
     * @param animate
     *      Should the cards animate from their previous positions to the new ones later.
     *      Main reason to set to false is when the cards have already been shifted over as with the
     *      case with snapping
     */
    public function addNode(termArea : TermAreaWidget,
            data : String,
            operator : String,
            globalMousePoint : Point,
            nodeToAttach : ExpressionNode = null,
            attachToLeft : Bool = false,
            animate : Bool = true) : Void
    {
        termArea.isReady = false;
        
        if (nodeToAttach == null) 
        {
            nodeToAttach = termArea.getTree().getRoot();
        }  // left child    // To do this check up until the parenthesis is found that a tracking node is always the    // Need to check whether the note to attach is the left edge of a parenthesis    // ex.) have (a+b), dropping c to left should result in c+(a+b) and not (c+a+b)    // Handle case where we want to add new nodes outside a parenthesis.  
        
        
        
        
        
        
        
        
        
        
        
        var isAddedToLeftOfParenthesis : Bool = false;
        
        var trackingNode : ExpressionNode = nodeToAttach;
        while (trackingNode != null)
        {
            // Discontinue search with failure if the tracking node is not the left child
            if (trackingNode.parent != null && trackingNode.parent.left != trackingNode) 
            {
                break;
            }  // Discontinue search with success if the tracking node is wrapped in parenthesis  
            
            
            
            if (trackingNode.wrapInParentheses) 
            {
                isAddedToLeftOfParenthesis = true;
                break;
            }
            
            trackingNode = trackingNode.parent;
        }  // of a parenthesis then the node to attach to should become that parenthesis node    // If we were attaching to the left and the node to attach was in fact the left most edge  
        
        
        
        
        
        if (attachToLeft && isAddedToLeftOfParenthesis) 
        {
            nodeToAttach = trackingNode;
        }  // Convert point from global to this coordinate space  
        
        
        
        var pointBuffer : Point = termArea.globalToLocal(globalMousePoint);
        termArea.getTree().addEventListener(ExpressionTreeEvent.ADD, onAddedNode);
        termArea.getTree().addLeafNode(operator, data, attachToLeft, nodeToAttach, pointBuffer.x, pointBuffer.y);
        
        function onAddedNode(event : Event, data : Dynamic) : Void
        {
            termArea.getTree().removeEventListener(ExpressionTreeEvent.ADD, onAddedNode);
            if (animate) 
            {
                m_addCardAnimation.play(
                        termArea,
                        data.nodeAdded.id,
                        data.initialXPosition,
                        data.initialYPosition,
                        m_expressionSymbolMap,
                        m_assetManager,
                        termArea.redrawAfterModification
                        );
            }
            else 
            {
                termArea.redrawAfterModification();
            }
        };
    }
    
    public function addNodeBatch(termArea : TermAreaWidget,
            data : Array<String>,
            operators : Array<String>,
            dropLocationsX : Array<Float>,
            dropLocationsY : Array<Float>,
            nodesToAttachTo : Array<ExpressionNode>,
            attachToLeft : Array<Bool>) : Void
    {
        termArea.isReady = false;
        
        // Convert point from global to this coordinate space
        var startPoint : Point = new Point();
        var resultPoint : Point = new Point();
        var numNodesToAdd : Int = data.length;
        var i : Int;
        for (i in 0...numNodesToAdd){
            startPoint.setTo(dropLocationsX[i], dropLocationsY[i]);
            termArea.globalToLocal(startPoint, resultPoint);
            dropLocationsX[i] = resultPoint.x;
            dropLocationsY[i] = resultPoint.y;
        }
        
        termArea.getTree().addLeafNodeBatch(
                operators,
                data,
                nodesToAttachTo,
                attachToLeft,
                dropLocationsX,
                dropLocationsY
                );
        
        termArea.redrawAfterModification();
    }
}
