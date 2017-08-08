package wordproblem.engine.expression.widget;

import dragonbox.common.math.vectorspace.RealsVectorSpace;
import flash.errors.Error;

import flash.geom.Point;
import flash.geom.Rectangle;
import flash.geom.Vector3D;

import dragonbox.common.dispose.IDisposable;
import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.ExpressionUtil;
import dragonbox.common.expressiontree.WildCardNode;
import dragonbox.common.math.util.MathUtil;
import dragonbox.common.math.vectorspace.IVectorSpace;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;

import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.expression.tree.ExpressionTree;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.expression.widget.term.GroupTermWidget;
import wordproblem.engine.expression.widget.term.SymbolTermWidget;
import wordproblem.engine.expression.widget.term.WildCardTermWidget;
import wordproblem.resource.AssetManager;

/**
 * This is the base rendering class for all expressions
 * 
 * The actual rendering output of the expression tree depends on a few factors:
 * The layout scheme to impart, linear or particle-like layout
 * The appearance of the operators and how they would affect grouping
 * 
 * One important note. The registration point of each individual node is such that the
 * center of that node is (0, 0). For example, a multiplication node will have its (0,0)
 * at the center of its icon and it stays that way regardless of the size of the children
 * that get appended to it.
 * 
 * (Extending classes will need to figure out mouse interaction on their own)
 * 
 */
class ExpressionTreeWidget extends Sprite implements IDisposable
{
    /**
     * A bit of a hack, in a few rare instances we don't even want things labeled as wild
     * cards to even show up, but they still take up space. This is really to have something show
     * partial expressions like +8 or -a
     */
    public var showWildCards : Bool;
    
    public var layoutDivisionVertically : Bool = true;
    
    /**
     * Contraints defines the border in which the tree must fit into.
     * The various node widgets must scale themselves in order to fit these
     * boundaries.
     * 
     * This will define the dimensions of this widget.
     */
    private var m_contraintsBox : Rectangle;
    private var m_vectorSpace : RealsVectorSpace;
    private var m_tree : ExpressionTree;
    private var m_expressionSymbolResources : ExpressionSymbolMap;
    
    /**
     * For simplicity sake we will accept the requirement that every logical expression
     * tree node will have a companion term widget and that companion term widget
     * will share the same child/parent structure as the tree nodes. Thus we have a single
     * root widget and can traverse the widget tree like the expression tree.
     * 
     * Note that we might have instance where we have widgets without a corresponding node
     * in the case of preview boxes.
     */
    private var m_widgetRoot : BaseTermWidget;
    
    /**
     * These are the list of root widgets that represent groups of terms that can be moved
     * around independent of each other.
     * 
     * In regular DragonBox these were composed of additive terms, if we ever end up having
     * a free form layout be may want quick access to each of these independent pieces
     */
    private var m_widgetRootGroups : Array<BaseTermWidget>;
    
    /**
     * In order to quickly search for widgets during updates we will link them to an id,
     * each created node instance has a unique id.
     */
    private var m_nodeIdToWidgetMap : Map<Int, BaseTermWidget>;
    
    /**
     * Since it is possible that all the terms in a widget will not fit the borders
     * of the constraints, we may need to apply scaling to the the terms.
     * 
     * We also allow for manual adjustment of the scaling
     */
    private var m_scaleFactor : Float;
    
    /**
     * Normally if the given constraints exceeds the size needed for the expression
     * we leave everything as is. If this is set to false, we shrink the constraints
     * to fit the actual size of the drawn expression.
     */
    private var m_allowConstraintPadding : Bool;
    
    private var m_assetManager : AssetManager;
    
    private var m_pointBuffer : Point;
    private var m_boundsBuffer : Rectangle;
    
    /**
     * This is a container that groups together the card contents. Reason is that at certain points
     * the visibility of the terms need to be toggled.
     */
    private var m_objectLayer : Sprite;
    
    /**
     * Function gets particular widget with matching id from a given widget root
     * Operates independently of data store in this class
     */
    public static function getWidgetFromId(nodeId : Int, widget : BaseTermWidget) : BaseTermWidget
    {
        var widgetToReplace : BaseTermWidget = null;
        if (widget != null) 
        {
            if (widget.getNode().id == nodeId) 
            {
                widgetToReplace = widget;
            }
            else 
            {
                var leftWidget : BaseTermWidget = getWidgetFromId(nodeId, widget.leftChildWidget);
                var rightWidget : BaseTermWidget = getWidgetFromId(nodeId, widget.rightChildWidget);
                widgetToReplace = ((leftWidget != null)) ? leftWidget : rightWidget;
            }
        }
        
        return widgetToReplace;
    }
    
    /**
     * Get back all leaf widgets belonging to a expression tree widget
     * 
     * @param outWidgetLeaves
     *      List that will be populated with leaf widgets belonging to the root
     */
    public function getWidgetLeaves(outWidgetLeaves : Array<BaseTermWidget>) : Void
    {
        _getWidgetLeaves(this.getWidgetRoot(), outWidgetLeaves);
    }
    
    /**
     * @param widget
     *      Root expression widget
     */
    private function _getWidgetLeaves(widget : BaseTermWidget,
            outWidgetLeaves : Array<BaseTermWidget>) : Void
    {
        if (widget != null) 
        {
            if (widget.leftChildWidget == null && widget.rightChildWidget == null) 
            {
                outWidgetLeaves.push(widget);
            }
            else 
            {
                _getWidgetLeaves(widget.leftChildWidget, outWidgetLeaves);
                _getWidgetLeaves(widget.rightChildWidget, outWidgetLeaves);
            }
        }
    }
    
    public function new(tree : ExpressionTree,
            expressionSymbolResources : ExpressionSymbolMap,
            assetManager : AssetManager,
            constraintWidth : Float,
            constraintHeight : Float,
            allowConstraintPadding : Bool = true,
            showWildCards : Bool = true)
    {
        super();
        
        m_pointBuffer = new Point();
        m_boundsBuffer = new Rectangle();
        m_objectLayer = new Sprite();
        addChild(m_objectLayer);
        
        m_scaleFactor = 1.0;
        m_vectorSpace = tree.getVectorSpace();
        m_expressionSymbolResources = expressionSymbolResources;
        m_nodeIdToWidgetMap = new Map();
        m_assetManager = assetManager;
        m_widgetRootGroups = new Array<BaseTermWidget>();
        setConstraints(constraintWidth, constraintHeight, allowConstraintPadding, false);
        setTree(tree);
        
        this.touchable = false;
        this.showWildCards = showWildCards;
    }
    
    /**
     * Resize the constaints, note that the tree needs to be manually rebuilt in order for
     * it to be centered
     * 
     * @param constraintWidth
     *      New width in pixels
     * @param constraintHeight
     *      New height in pixels
     * @param allowConstrainPadding
     *      If false we will automatically resize the constraint dimension to fit
     *      into the expression. Useful only for static content.
     * @param scaleAndLayoutTree
     *      Should the tree immediately try to rescale and layout again.
     */
    public function setConstraints(constraintWidth : Float,
            constraintHeight : Float,
            allowConstraintPadding : Bool,
            scaleAndLayoutTree : Bool) : Void
    {
        m_contraintsBox = new Rectangle(0, 0, constraintWidth, constraintHeight);
        m_allowConstraintPadding = allowConstraintPadding;
        
        if (scaleAndLayoutTree) 
        {
            this.scaleAndLayoutTreeWidgetGroups(this.getWidgetRoot());
        }
    }
    
    public function setScaleFactor(value : Float) : Void
    {
        m_scaleFactor = value;
        for (i in 0...m_widgetRootGroups.length){
            var widgetRoot : BaseTermWidget = m_widgetRootGroups[i];
            widgetRoot.scaleX = widgetRoot.scaleY = m_scaleFactor;
        }
    }
    
    public function getScaleFactor() : Float
    {
        return m_scaleFactor;
    }
    
    /**
     * Set up a new expression tree to be rendered. This will completely discard the old
     * view, however it does not immediately redraw the new one.
     * 
     * Need to call refresh nodes then rebuild
     */
    public function setTree(tree : ExpressionTree) : Void
    {
        for (widget in m_nodeIdToWidgetMap.iterator())
        {
            if (widget.parent != null) 
            {
                widget.parent.removeChild(widget);
            }
        }
        m_nodeIdToWidgetMap = new Map();
        
        m_tree = tree;
    }
    
    public function getTree() : ExpressionTree
    {
        return m_tree;
    }
    
    /**
     * This is the update function for the tree widget, it is how it will know
     * about changes in the backing expression tree structure and to create and destroy
     * widgets for each of the expression nodes.
     * 
     * If forced to create and delete we destroy the old tree and reconstruct a new view.
     * This is useful for undo or restart situations where its far simpler to just re-construct
     * the view.
     * 
     * @param forceCreate
     *         Force the creation of widgets
     * @param forceDelete
     *         Force all old widgets to be deleted
     */
    public function refreshNodes(forceCreate : Bool = false, forceDelete : Bool = false) : Void
    {
        // Prune out deleted nodes in our current widget structure
        var treeRoot : ExpressionNode = m_tree.getRoot();
        var widgetsToDelete : Array<BaseTermWidget> = new Array<BaseTermWidget>();
        if (m_widgetRoot != null) 
        {
            _getWidgetsToDelete(m_widgetRoot, treeRoot, widgetsToDelete, forceDelete);
        }
        
        var i : Int = 0;
        for (i in 0...widgetsToDelete.length){
            var widgetToRemove : BaseTermWidget = widgetsToDelete[i];
            widgetToRemove.removeChildWidgets();
            
            if (widgetToRemove.parent != null) 
                widgetToRemove.parent.removeChild(widgetToRemove);
            m_nodeIdToWidgetMap.remove(widgetToRemove.getNode().id);
            widgetToRemove.parentWidget = null;
            
            if (widgetToRemove == m_widgetRoot) 
            {
                m_widgetRoot = null;
            }
        }  
		
		// Go through all the nodes in the expression tree and check for ones that do not  
        // have an associated widget created for it 
        var widgetsToCreate : Array<ExpressionNode> = new Array<ExpressionNode>();
        _getWidgetsToCreate(treeRoot, m_nodeIdToWidgetMap, widgetsToCreate, forceCreate);
        for (i in 0...widgetsToCreate.length){
            var nodeToCreateWidgetFor : ExpressionNode = widgetsToCreate[i];
            
            var addedNodeWidget : BaseTermWidget = null;
            if (nodeToCreateWidgetFor.isLeaf()) 
            {
                if (Std.is(nodeToCreateWidgetFor, WildCardNode)) 
                {
                    addedNodeWidget = new WildCardTermWidget(
                            try cast(nodeToCreateWidgetFor, WildCardNode) catch(e:Dynamic) null, 
                            m_expressionSymbolResources, 
                            m_assetManager, 
                            this.showWildCards);
                }
                else 
                {
                    addedNodeWidget = new SymbolTermWidget(
                            nodeToCreateWidgetFor, 
                            m_expressionSymbolResources, 
                            m_assetManager);
                }
            }
            else 
            {
                var groupWidget : GroupTermWidget = new GroupTermWidget(
                nodeToCreateWidgetFor, 
                m_vectorSpace, 
                m_expressionSymbolResources, 
                m_assetManager);
                addedNodeWidget = groupWidget;
            }
            m_nodeIdToWidgetMap.set(nodeToCreateWidgetFor.id, addedNodeWidget);
        } 
		
		// Create widget for root if it doesn't exist already  
        if (treeRoot != null && m_widgetRoot == null) 
        {
            m_widgetRoot = m_nodeIdToWidgetMap.get(treeRoot.id);
            if (m_widgetRoot != null) 
            {
                m_widgetRoot.parentWidget = null;
            }
        }
    }
    
    private function _getWidgetsToDelete(widget : BaseTermWidget,
            rootTreeNode : ExpressionNode,
            outWidgetToDelete : Array<BaseTermWidget>,
            deleteAll : Bool) : Void
    {
        if (widget != null) 
        {
            _getWidgetsToDelete(widget.leftChildWidget, rootTreeNode, outWidgetToDelete, deleteAll);
            _getWidgetsToDelete(widget.rightChildWidget, rootTreeNode, outWidgetToDelete, deleteAll);
            
            if (deleteAll || !ExpressionUtil.containsId(widget.getNode().id, rootTreeNode)) 
            {
                outWidgetToDelete.push(widget);
            }
        }
    }
    
    private function _getWidgetsToCreate(node : ExpressionNode,
            existingNodeIdsMap : Map<Int, BaseTermWidget>,
            outNodesToCreate : Array<ExpressionNode>,
            createAll : Bool) : Void
    {
        // For every node in the tree, get ones who have ids not stored in
        // in out current mapping.
        if (node != null) 
        {
            _getWidgetsToCreate(node.left, existingNodeIdsMap, outNodesToCreate, createAll);
            _getWidgetsToCreate(node.right, existingNodeIdsMap, outNodesToCreate, createAll);
            
            if (createAll || !existingNodeIdsMap.exists(node.id)) 
            {
                outNodesToCreate.push(node);
            }
        }
    }
    
    override public function dispose() : Void
    {
        if (m_widgetRoot != null) 
        {
            removeChild(m_widgetRoot);
        }
        
        super.dispose();
    }
    
    public function getConstraintsWidth() : Float
    {
        return this.m_contraintsBox.width;
    }
    
    public function getConstraintsHeight() : Float
    {
        return this.m_contraintsBox.height;
    }
    
    public function setWidgetRoot(value : BaseTermWidget) : Void
    {
        m_widgetRoot = value;
    }
    
    public function getWidgetRoot() : BaseTermWidget
    {
        return m_widgetRoot;
    }
    
    /**
     * Get back the leaf widgets that match a particular expression data string. 
     *
     * @param data
     *      In most cases this is just the data of a node, but if we want to match wildcards
     *      this value will be a compound string with the wild card prefix
     */
    public function getWidgetsMatchingData(data : String,
            widgetRoot : BaseTermWidget,
            outWidgets : Array<BaseTermWidget>) : Void
    {
        if (widgetRoot != null) 
        {
            if (widgetRoot.leftChildWidget == null && widgetRoot.rightChildWidget == null) 
            {
                if (widgetRoot.getNode().data == data) 
                {
                    outWidgets.push(widgetRoot);
                }
            }
            else 
            {
                getWidgetsMatchingData(data, widgetRoot.leftChildWidget, outWidgets);
                getWidgetsMatchingData(data, widgetRoot.rightChildWidget, outWidgets);
            }
        }
    }
    
    /**
     * Get back the term widget from the id of its backing expression node
     * 
     * @return
     *      Widget with the expression node of the same id or null if no widget for
     *      that id exists
     */
    public function getWidgetFromNodeId(nodeId : Int) : BaseTermWidget
    {
        return m_nodeIdToWidgetMap.get(nodeId);
    }
    
    /**
     * Get whether the given visible display object is contained with the
     * constraints
     * 
     * @param displayObject
     * @param striclyContained
     *         Flag if true means the object must be fully contained within the
     *         box, otherwise we just check that part of it intersects
     */
    public function containsObject(displayObject : DisplayObject,
            strictlyContained : Bool = false) : Bool
    {
        // If a term area is not visible then it can never contain an object
        if (this.parent == null) 
        {
            return false;
        }
        
        var containsObject : Bool = false;
        displayObject.getBounds(this, m_boundsBuffer);
        if (strictlyContained) 
        {
            containsObject = m_contraintsBox.containsRect(m_boundsBuffer);
        }
        else 
        {
            containsObject = m_contraintsBox.intersects(m_boundsBuffer);
        }
        
        return containsObject;
    }
    
    /**
     * @param globalPoint
     *         A (x,y) coordinate relative to the global screen space
     */
    public function containsPoint(globalPoint : Point) : Bool
    {
        this.globalToLocal(globalPoint, m_pointBuffer);
        return this.m_contraintsBox.contains(m_pointBuffer.x, m_pointBuffer.y);
    }
    
    /**
     * Get back a list of leaf widgets intersecting with a given display object.
     * 
     * Needs to be modified to allow for parentheses to be picked and perhaps even
     * the node in the tree to start the search to deal with the case of dragging a
     * node inside a paren into another nested paren.
     */
    public function pickLeafWidgetsUnderObject(object : DisplayObject,
            pickParentheses : Bool = false,
            outWidgets : Array<BaseTermWidget> = null) : Array<BaseTermWidget>
    {
        if (outWidgets == null) 
        {
            outWidgets = new Array<BaseTermWidget>();
        }
        
        if (this.stage != null) 
        {
            object.getBounds(this, m_boundsBuffer);
            _pickLeafWidgetsUnderObject(m_widgetRoot, object, m_boundsBuffer, outWidgets, pickParentheses);
        }
        
        return outWidgets;
    }
    
    private function _pickLeafWidgetsUnderObject(widget : BaseTermWidget,
            object : DisplayObject,
            objectRectangle : Rectangle,
            outWidgets : Array<BaseTermWidget>,
            pickParentheses : Bool) : Void
    {
        if (widget != null) 
        {
            var widgetRectangle : Rectangle = widget.rigidBodyComponent.boundingRectangle;
            if (Std.is(widget, SymbolTermWidget) || Std.is(widget, WildCardTermWidget)) 
            {
                if (objectRectangle.intersects(widgetRectangle) && widget != object) 
                {
                    outWidgets.push(widget);
                }
            }
            else 
            {
                if (pickParentheses && widget.getNode().wrapInParentheses &&
                    objectRectangle.intersects(widgetRectangle) && widget != object) 
                {
                    outWidgets.push(widget);
                }
                else 
                {
                    _pickLeafWidgetsUnderObject(widget.leftChildWidget, object, objectRectangle, outWidgets, pickParentheses);
                    _pickLeafWidgetsUnderObject(widget.rightChildWidget, object, objectRectangle, outWidgets, pickParentheses);
                }
            }
        }
    }
    
    /**
     *
     * @param globalX
     *      x value in the global coordinates
     * @param globalY
     *      y value in the global coordinates
     * @param outParams.
     *      The first index is the widget containing the parenthesis graphic that is under the point
     *      The second index is boolean that is true if the selected paran was the left. Returns empty if
     *      the nothing is selected
     */
    public function pickParenthesisUnderPoint(globalX : Float, globalY : Float, outParams : Array<Dynamic>) : Void
    {
        pickedParenthesisGlobalPoint.setTo(globalX, globalY);
        this.globalToLocal(pickedParenthesisGlobalPoint, pickedParenthesisLocalPoint);
        
        return _pickParenthesisUnderPoint(m_widgetRoot, pickedParenthesisLocalPoint, outParams);
    }
    
    private var pickedParenthesisGlobalPoint : Point = new Point();
    private var pickedParenthesisLocalPoint : Point = new Point();
    private var pickedParenthesisBounds : Rectangle = new Rectangle();
    private function _pickParenthesisUnderPoint(widget : BaseTermWidget,
            localPoint : Point,
            outParams : Array<Dynamic>) : Void
    {
        var pickedWidget : BaseTermWidget = null;
        if (widget != null) 
        {
            // From a particular widget get if that widget has parenthesis,
            // if it does get the bounds of them and see if the mouse is over it
            if (widget.getNode().wrapInParentheses) 
            {
                var numParenthesisChildren : Int = widget.m_parenthesesCanvas.numChildren;
                var i : Int = 0;
                for (i in 0...numParenthesisChildren){
                    var parenthesisImage : DisplayObject = widget.m_parenthesesCanvas.getChildAt(i);
                    parenthesisImage.getBounds(this, pickedParenthesisBounds);
                    
                    if (pickedParenthesisBounds.containsPoint(localPoint)) 
                    {
                        // Return a hit
                        pickedWidget = widget;
                        outParams.push(pickedWidget);
                        outParams.push(i == 0);
                        
                        break;
                    }
                }
            }  // If we didn't hit anything then we continue searching  
            
            
            
            if (pickedWidget == null) 
            {
                _pickParenthesisUnderPoint(widget.leftChildWidget, localPoint, outParams);
                
                if (outParams.length == 0) 
                {
                    _pickParenthesisUnderPoint(widget.rightChildWidget, localPoint, outParams);
                }
            }
        }
    }
    
    /**
     * Pick the leaf widget that lies underneath a point. The point must be in
     * global coordinates.
     * 
     * @param x
     *      global x value
     * @param y
     *      global y value
     * @param allowPickOperator
     *      true if the picked widget can be an operator, false if only allow for the picking
     *      of widgets at the leaves.
     */
    public function pickWidgetUnderPoint(x : Float, y : Float, allowPickOperator : Bool) : BaseTermWidget
    {
        // Set the local coodinates within the frame of reference of this widget
        pickedWidgetGlobalPoint.setTo(x, y);
        this.globalToLocal(pickedWidgetGlobalPoint, pickedWidgetLocalPoint);
        
        // Look through all widgets
        return _pickWidgetUnderPoint(m_widgetRoot, pickedWidgetLocalPoint, allowPickOperator);
    }
    
    private var pickedWidgetGlobalPoint : Point = new Point();
    private var pickedWidgetLocalPoint : Point = new Point();
    private var pickedWidgetRectangle : Rectangle = new Rectangle();
    private function _pickWidgetUnderPoint(widget : BaseTermWidget,
            localPoint : Point,
            allowPickOperator : Bool) : BaseTermWidget
    {
        var pickedWidget : BaseTermWidget = null;
        if (Std.is(widget, SymbolTermWidget)) 
        {
            var widgetBounds : Rectangle = widget.rigidBodyComponent.boundingRectangle;
            if (widgetBounds.containsPoint(pickedWidgetLocalPoint)) 
            {
                pickedWidget = widget;
            }
        }
        else if (widget != null) 
        {
            // If we can pick an operator the hit test should check if the given
            // point lies within JUST THE GRAPHIC representing the operator
            if (allowPickOperator && Std.is(widget, GroupTermWidget)) 
            {
                (try cast(widget, GroupTermWidget) catch(e:Dynamic) null).groupImage.getBounds(this, pickedWidgetRectangle);
                
                // Add buffering around the operator so it is easier to pick out,
                // use a fixed dimension box
                var fixedDimension : Float = 28;
                var dx : Float = ((pickedWidgetRectangle.width < fixedDimension)) ? 
                (fixedDimension - pickedWidgetRectangle.width) * 0.5 : 0;
                var dy : Float = ((pickedWidgetRectangle.height < fixedDimension)) ? 
                (fixedDimension - pickedWidgetRectangle.height) * 0.5 : 0;
                pickedWidgetRectangle.inflate(dx, dy);
                
                if (pickedWidgetRectangle.containsPoint(pickedWidgetLocalPoint)) 
                {
                    pickedWidget = widget;
                }
            }  // Check children if the widget is still not found  
            
            
            
            if (pickedWidget == null) 
            {
                pickedWidget = _pickWidgetUnderPoint(widget.leftChildWidget, localPoint, allowPickOperator);
            }
            
            if (pickedWidget == null) 
            {
                pickedWidget = _pickWidgetUnderPoint(widget.rightChildWidget, localPoint, allowPickOperator);
            }
        }
        
        return pickedWidget;
    }
    
    /**
     * Pick the leaf widgets that lie underneath a line segment. The points defining the segment
     * must be in global coordinates.
     */
    public function pickLeafWidgetsFromSegment(p1 : Point,
            p2 : Point,
            outWidgets : Array<BaseTermWidget>) : Void
    {
        _pickLeafWidgetsFromSegment(getWidgetRoot(), this.stage, p1, p2, outWidgets);
    }
    
    private function _pickLeafWidgetsFromSegment(widget : BaseTermWidget,
            targetReference : DisplayObject,
            p1 : Point,
            p2 : Point,
            outWidgets : Array<BaseTermWidget>) : Void
    {
        if (Std.is(widget, SymbolTermWidget)) 
        {
            if (MathUtil.lineSegmentIntersectsRectangle(p1, p2, widget.getBounds(targetReference))) 
            {
                outWidgets.push(widget);
            }
        }
        else if (widget != null) 
        {
            _pickLeafWidgetsFromSegment(
                    widget.leftChildWidget,
                    targetReference,
                    p1,
                    p2,
                    outWidgets);
            _pickLeafWidgetsFromSegment(
                    widget.rightChildWidget,
                    targetReference,
                    p1,
                    p2,
                    outWidgets);
        }
    }
    
    /**
     * Rebuild the view structure of the given set of expression nodes
     * (MUST BE ADDED TO DISPLAY LIST TO WORK)
     * 
     * Note that this does not include the construction or destruction of widgets, rather
     * it is the repositioning of current widgets.
     * 
     * IMPORTANT: It is required before this function is called, that every single node
     * in the expression tree has an associated widget created for it already even if that
     * widget is just an empty shell. It is also important to note that deleted nodes
     * should have had their associated widgets disposed of properly otherwise
     * wierd layout and visibility issues will crop up.
     */
    public function buildTreeWidget() : Void
    {
        if (m_tree.getRoot() == null) 
        {
            return;
        }  // Recursively build all links between the various widgets  
        
        
        
        var rootWidget : BaseTermWidget = _buildTreeWidgetLinks(m_tree.getRoot());
        
        // Layout all widgets based on a particular algorithm
        // some example algorithms:
        // layout all inline in one line
        // layout inline in multiple lines
        // layout groups as individual particles
        buildTreeWidgetGroups(rootWidget);
        
        // Perform a final layout and scaling of widget groups
        scaleAndLayoutTreeWidgetGroups(rootWidget);
    }
    
    /**
     * Set up the correct left, right, and parent pointers for each widget based
     * on their backing expression node. Note links are not constructed for node
     * marked as hidden.
     * 
     * @param node
     *      Root of the subtree to assign widget links for
     * @return
     *      The widget associated with the node passed. Is null if the widget is not found
     *      (which is an error) or if the node should be hidden.
     */
    private function _buildTreeWidgetLinks(node : ExpressionNode) : BaseTermWidget
    {
        // Important that widgets have already been created for each node,
        // we fetch the widget for that node.
        var createdWidget : BaseTermWidget = null;
        if (node != null) 
        {
            // If there are nodes in the expression tree that we want to keep hidden, we check
            // a hidden flag contained in the node. If set to true then we do not assign widget links.
            // Note this this method assumes that the function to layout and display widgets uses
            // only the widget links to indicate positioning and layering and not the links of the
            // backing expression nodes
            if (!node.hidden) 
            {
                createdWidget = try cast(m_nodeIdToWidgetMap.get(node.id), BaseTermWidget) catch(e:Dynamic) null;
                if (createdWidget == null) 
                {
                    throw new Error("ExpressionTreeWidget: Widget not created for node with data:" + node.data);
                }
                else if (!node.isLeaf()) 
                {
                    // For non-leaf nodes, if we get that one child is null then for our binary tree requirement
                    // to hold, the widget we return needs to be the non-null child
                    // We essentially ignore the non-leaf node in addition to the hidden node
                    var leftWidget : BaseTermWidget = _buildTreeWidgetLinks(node.left);
                    var rightWidget : BaseTermWidget = _buildTreeWidgetLinks(node.right);
                    
                    if (leftWidget != null) 
                    {
                        leftWidget.parentWidget = createdWidget;
                        createdWidget.leftChildWidget = leftWidget;
                    }
                    else 
                    {
                        createdWidget = rightWidget;
                    }
                    
                    if (rightWidget != null) 
                    {
                        rightWidget.parentWidget = createdWidget;
                        createdWidget.rightChildWidget = rightWidget;
                    }
                    else 
                    {
                        createdWidget = leftWidget;
                    }
                }
            }
        }
        
        return createdWidget;
    }
    
    /**
     * Important to note that this particular function does not explicitly use the
     * backing expression tree. It will simply position everything based on the links
     * set up within each widget.
     * 
     * @param rootWidgets
     *      A list of widget group to be laid out within this container. Common case is a list
     *      of one in which case the entire expression is laid out as a single line. In other
     *      case we would freely be able to move around a widget in its parent container.
     */
    public function buildTreeWidgetGroups(rootWidget : BaseTermWidget) : Void  //  
    {
        // TODO: Figure why when the logical tree root changes, the widget root is
        // not being properly binded to the widget of that new logical node. It will
        // stick to the widget of the old root
        // (Repro: multiply,remove,add creates a blank space)
        // Depending on the layout style, inline vs groups, we may need to call layout
        // multiple times. Right now we always assume inline layout
        m_widgetRoot = rootWidget;
        _buildTermWidgetGroups(rootWidget);
    }
    
    /**
     * Final step in the creation and layout of a tree widget
     * 
     * Apply scaling to make sure all the different groups can fit inside the given constraints and
     * then apply layout to them to get the final position they should be displayed.
     * 
     * Should be re-executed whenever the constraints get altered or when the contents of the
     * tree changes
     */
    public function scaleAndLayoutTreeWidgetGroups(rootWidget : BaseTermWidget) : Void
    {
        // Apply a uniform scaling to each top level widget group, for inline we just have a single
        // widget to layout.
        // Scale objects back up to regular sizes if there is room (occurs if we set a new constraint
        // dimension that gives enough room for the widgets to expand)
        // TODO: Scaling should occur per group, the temp solution is just to
        // check if either the combined width or heights of each of the widget groups exceeds the
        // constraints boundaries
        var rootRectangle : Rectangle = rootWidget.rigidBodyComponent.boundingRectangle;
        var amountToScaleTo : Float = 1.0;
        if (rootRectangle.width > m_contraintsBox.width ||
            rootRectangle.height > m_contraintsBox.height) 
        {
            var scaleAmountToFitWidth : Float = m_contraintsBox.width / rootRectangle.width;
            var scaleAmountToFitHeight : Float = m_contraintsBox.height / rootRectangle.height;
            amountToScaleTo = Math.min(scaleAmountToFitHeight, scaleAmountToFitWidth);
        }
        rootWidget.scaleX = rootWidget.scaleY = amountToScaleTo;
        
        m_scaleFactor = amountToScaleTo;
        
        if (!m_allowConstraintPadding) 
        {
            m_contraintsBox.width = rootRectangle.width;
            m_contraintsBox.height = rootRectangle.height;
        }  
		
		// TODO: After scaling this should use an algorithm to layout the groups in a more  
		// intelligent fashion 
		// This is the final step to the layout. For inline we just center the root and for groups
        // apply repulsive forces for each group to figure out the final position 
        rootWidget.getBounds(this, rootRectangle);
        rootWidget.x -= rootRectangle.left;
        rootWidget.x += (m_contraintsBox.width - rootWidget.width) / 2;
        rootWidget.y = rootRectangle.height / 2 + (m_contraintsBox.height - rootWidget.height) / 2;
        
        // For every widget, reset the bounding rectangles based on the final repositioning
        _setRigidBodyBounds(rootWidget);
        
        // TODO: This should be added the group roots
        m_objectLayer.addChild(m_widgetRoot);
        
        setNodePositions(m_widgetRoot);
    }
    
    /**
     * A function that should be executable at any point in time that will examine a link
     * of widgets and determine how that set should be laid out in a formal grouping.
     * 
     */
    private function _buildTermWidgetGroups(rootWidget : BaseTermWidget) : Void
    {
        if (rootWidget != null) 
        {
            // FIXME: Bounding box get screwed up big time unless we reset the visual
            // properties of the widget, this is bad though!!!!
            rootWidget.removeChildWidgets();
            rootWidget.x = rootWidget.y = 0;
            rootWidget.scaleX = rootWidget.scaleY = 1.0;
            m_objectLayer.addChild(rootWidget);
        }
        
        if (Std.is(rootWidget, GroupTermWidget)) 
        {
            var groupWidget : GroupTermWidget = try cast(rootWidget, GroupTermWidget) catch(e:Dynamic) null;
            var leftWidget : BaseTermWidget = groupWidget.leftChildWidget;
            _buildTermWidgetGroups(leftWidget);
            var rightWidget : BaseTermWidget = groupWidget.rightChildWidget;
            _buildTermWidgetGroups(rightWidget);
            
            // Used the built-in getBounds method of sprites to recalculate the bounding boxes
            // After the children of a group root have been laid out, they need to be
            // repositioned again relative to this root.
            var groupNode : ExpressionNode = groupWidget.getNode();
            if (groupNode.isSpecificOperator(m_vectorSpace.getDivisionOperator()) && this.layoutDivisionVertically) 
            {
                // In division, the terms centers of mass are aligned along the same horizontal line
                groupWidget.addChildWidget(leftWidget);
                groupWidget.addChildWidget(rightWidget);
                
                // The registration point at the center complicates centering objects
                // If the center of mass is postive relative, its to the right of the registration point
                // need to shift to the left.
                // Otherwise the c-o-m is to the left of the registration point and we need to shift to the right
                // Left is the numerator
                // Right is the denominator
                var yOffset : Float = 5;
                var leftCenterX : Float = leftWidget.rigidBodyComponent.getCenterOfMass().x;
                var leftRect : Rectangle = leftWidget.rigidBodyComponent.boundingRectangle;
                leftWidget.x = -1 * leftCenterX;
                leftWidget.y = -1 * leftRect.height / 2 - yOffset;
                
                var rightCenterX : Float = rightWidget.rigidBodyComponent.getCenterOfMass().x;
                var rightRect : Rectangle = rightWidget.rigidBodyComponent.boundingRectangle;
                rightWidget.x = -1 * rightCenterX;
                rightWidget.y = rightRect.height / 2 + yOffset;
                
                // Re-adjust the bounding body size of this group
                leftWidget.getBounds(this, leftWidget.rigidBodyComponent.boundingRectangle);
                rightWidget.getBounds(this, rightWidget.rigidBodyComponent.boundingRectangle);
                groupWidget.getBounds(this, groupWidget.rigidBodyComponent.boundingRectangle);
                
                // For division, we need to scale the division bar up from its default width
                // if the numerator or denominator are too large
                // Need to first fetch a reference to the main graphic of the term widget
                var divisionImage : DisplayObject = groupWidget.groupImage;
                divisionImage.width = Math.max(
                                leftWidget.rigidBodyComponent.boundingRectangle.width,
                                rightWidget.rigidBodyComponent.boundingRectangle.width
                                );
                divisionImage.pivotX = divisionImage.width * 0.5;
                divisionImage.pivotY = divisionImage.height * 0.5;
            }
            else 
            {
                // In multiplication, the product terms centers of mass are aligned along the same vertical line
                // add the children widgets
                // Same thing for inline addition, subtraction, and equality
                layoutHorizontally(groupWidget, leftWidget, rightWidget);
            }
        }
		
		// If the node is marked as showing parenthesis we render it at the end after  
        // bounds for this node have been calculated
        while (rootWidget.m_parenthesesCanvas.numChildren > 0)
        {
            rootWidget.m_parenthesesCanvas.removeChildAt(0);
        }
        
        if (rootWidget.getNode().wrapInParentheses) 
        {
            var currentRectangle : Rectangle = rootWidget.getBounds(this);
            var centralPointInGlobal : Point = rootWidget.localToGlobal(new Point(0, 0));
            var centralPointInLocal : Point = this.globalToLocal(centralPointInGlobal);
            
            var leftOffset : Float = centralPointInLocal.x - currentRectangle.left;
            var topOffset : Float = centralPointInLocal.y - currentRectangle.top;
            var parenPadding : Float = 5;
            
            var leftParen : DisplayObject = new Image(m_assetManager.getTexture("parentheses_left"));
            leftParen.pivotX = leftParen.width / 2.0;
            leftParen.pivotY = leftParen.height / 2.0;
            leftParen.x = -leftOffset - parenPadding;
            rootWidget.m_parenthesesCanvas.addChild(leftParen);
            
            var rightParen : DisplayObject = new Image(m_assetManager.getTexture("parentheses_right"));
            rightParen.pivotX = rightParen.width / 2.0;
            rightParen.pivotY = rightParen.height / 2.0;
            rightParen.x = currentRectangle.right - centralPointInLocal.x + parenPadding;
            rootWidget.m_parenthesesCanvas.addChild(rightParen);
        }
        
        rootWidget.getBounds(this, rootWidget.rigidBodyComponent.boundingRectangle);
    }
    
    private function layoutHorizontally(root : BaseTermWidget, left : BaseTermWidget, right : BaseTermWidget) : Void
    {
        root.addChildWidget(left);
        root.addChildWidget(right);
        var xOffset : Float = root.mainGraphicBounds.width * 0.5;
        
        var leftRightPadding : Float = xOffset * 0.5;
        xOffset += leftRightPadding;
        
        // reposition children them based purely on dimensions RELATIVE the current
        // group widgets coordinate space.
        var leftRect : Rectangle = left.rigidBodyComponent.boundingRectangle;
        left.x = -1 * leftRect.right - xOffset;
        left.y = 0;
        
        // FIXME: For some reason the widget to the right does not have the same padding space
        // as the one to the left if this node is addition
        var rightRect : Rectangle = right.rigidBodyComponent.boundingRectangle;
        right.x = -1 * rightRect.left + xOffset;
        right.y = 0;
        
        // recalculate the bounding box of this term
        left.getBounds(this, left.rigidBodyComponent.boundingRectangle);
        right.getBounds(this, right.rigidBodyComponent.boundingRectangle);
        root.getBounds(this, root.rigidBodyComponent.boundingRectangle);
    }
    
    /**
     * Recursively reset the boundaries of each widget in terms of this container frame
     * 
     * Currently this only works if the widget is part of the starling display list since
     * its using starlings bounds calculations
     * 
     * @param widget
     *      Root of the subtree to recusrively assign bounds to.
     */
    private function _setRigidBodyBounds(widget : BaseTermWidget) : Void
    {
        if (widget != null) 
        {
            widget.getBounds(this, widget.rigidBodyComponent.boundingRectangle);
            _setRigidBodyBounds(widget.leftChildWidget);
            _setRigidBodyBounds(widget.rightChildWidget);
        }
    }
    
    /**
     * Record the positions of the widgets as they are currently laid out relative to
     * the coordinate space of this container into the backing node representations.
     * 
     * @param widget
     *      Root of the subtree to recursively assign positions to
     */
    private function setNodePositions(widget : BaseTermWidget) : Void
    {
        if (widget != null) 
        {
            var widgetGlobalCoordinates : Point = widget.localToGlobal(new Point(0, 0));
            var widgetPosition : Point = this.globalToLocal(widgetGlobalCoordinates);
            var previousPosition : Vector3D = widget.getNode().position;
            previousPosition.x = widgetPosition.x;
            previousPosition.y = widgetPosition.y;
            
            setNodePositions(widget.leftChildWidget);
            setNodePositions(widget.rightChildWidget);
        }
    }
}
