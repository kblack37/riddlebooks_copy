package wordproblem.engine.expression.widget.manager;


import dragonbox.common.math.vectorspace.RealsVectorSpace;
import flash.geom.Point;
import flash.geom.Rectangle;

import dragonbox.common.dispose.IDisposable;
import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.ExpressionUtil;
import dragonbox.common.expressiontree.WildCardNode;
import dragonbox.common.math.util.MathUtil;
import dragonbox.common.math.vectorspace.IVectorSpace;
import dragonbox.common.ui.MouseState;

import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.events.Event;

import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.expression.event.ExpressionTreeEvent;
import wordproblem.engine.expression.tree.ExpressionTree;
import wordproblem.engine.expression.widget.ExpressionTreeWidget;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.expression.widget.term.GroupTermWidget;
import wordproblem.engine.expression.widget.term.WildCardTermWidget;
import wordproblem.engine.level.LevelRules;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.resource.AssetManager;

/**
 * This class is responsible for taking in a term widget and a term area and 
 * determining whether the term widget should be snapped or bound to an existing
 * card in the area. In dragonbox 2, this operation occurs whenever there is the
 * lightning animation.
 * 
 * A term widget can be dragged from either a deck or it can be an existing term in
 * the area.
 * 
 * NOTE: The update function changes the visibility of the dragged object, this is to prevent it
 * from obscuring the snap preview
 */
class SnapManager implements IDisposable
{
    /**
     * Term area stores the collection of candidate terms that can be snapped to.
     * It also will be visually updated and snaps are created and removed.
     */
    private var m_termArea : TermAreaWidget;
    
    private var m_vectorSpace : RealsVectorSpace;
    private var m_assetManager : AssetManager;
    private var m_expressionResourceMap : ExpressionSymbolMap;
    
    /**
     * Rules will help determine what type of bindings with a dragged card are
     * possible. Since rules can change at any time, they need to be read in on
     * every update.
     */
    private var m_levelRules : LevelRules;
    
    /**
     * When determining how to snap items with each other we maintain a list of candidate widgets
     * available for snapping. (Artifact of old architecture, only purpose it serves now
     * is to save calculating hit areas on every frame)
     * 
     * In nearly all cases the candidate widgets are either symbols or parentheses groups
     * 
     * List needs to be refreshed everytime the term area gets modified or reset
     */
    private var m_widgetCandidates : Array<BaseTermWidget>;
    
    /**
     * List of bounding rectangles for each candidate widget, index is the same as in the
     * widget list.
     */
    private var m_widgetCandidateBounds : Array<Rectangle>;
    
    /**
     * List of bounding rectangles for the parenthesis of a widget, indices matches with the widget list
     * in pairs, i matches to 2*i and 2*i+1
     * Contains null pairs if no parenthesis are used.
     */
    private var m_widgetCandidateParenthesisBounds : Array<Rectangle>;
    
    /**
     * This keeps track of the bounding rectangle of whatever object is being dragged around.
     * Note that for any drag session of an object (until it gets released) we take a single
     * snapshot of the bounds at the start to prevent any possible oscillation issues caused by the
     * dragged object get rescaled.
     */
    private var m_widgetToSnapLocalBounds : Rectangle;
    
    /**
     * If true, it means we are in the middle of a drag session. False indicates nothing is being dragged
     * at the moment.
     */
    private var m_widgetToSnapStartDrag : Bool;
    
    /**
     * This is an existing widget in the term area that is accepting a snap
     */
    private var m_widgetAcceptingSnap : BaseTermWidget;
    
    /**
     * This is the operator for the snap, operator in the the vectorspace
     */
    private var m_operatorForSnap : String;
    
    /**
     * This indicates whether the snap to make is to the left or right of the
     * operator for the snap.
     */
    private var m_snapToLeft : Bool;
    
    /**
     * For multiply and divide previews, we create a blink animation to make it clear what card
     * is being added
     */
    private var m_blinkTween : Tween;
    
    /**
     * For multiply and divide previews, we animate the operators to make clearer the modification to the terms
     */
    private var m_operatorTween : Tween;
    
    /**
     * Seconds for each repitition of a tween.
     */
    private var m_tweenRepeatDuration : Float;
    
    public function new(termArea : TermAreaWidget,
            levelRules : LevelRules,
            vectorSpace : RealsVectorSpace,
            assetManager : AssetManager,
            expressionResourceMap : ExpressionSymbolMap)
    {
        termArea.addEventListener(GameEvent.TERM_AREA_CHANGED, onTermAreaChanged);
        //termArea.addEventListener(GameEvent.TERM_AREA_RESET, onTermAreaChanged);
        m_termArea = termArea;
        m_levelRules = levelRules;
        
        // Set the initial widgets and bounds
        m_widgetCandidates = new Array<BaseTermWidget>();
        m_widgetCandidateBounds = new Array<Rectangle>();
        m_widgetCandidateParenthesisBounds = new Array<Rectangle>();
        onTermAreaChanged();
        
        m_vectorSpace = vectorSpace;
        m_assetManager = assetManager;
        m_expressionResourceMap = expressionResourceMap;
        m_widgetToSnapLocalBounds = new Rectangle();
        m_widgetToSnapStartDrag = false;
        m_blinkTween = new Tween(null, 0);
        m_operatorTween = new Tween(null, 0);
        m_tweenRepeatDuration = 0.4;
    }
    
    /**
     * Need to call on every frame to correctly process changes in how a dragged object
     * should be snapped as it is being moved.
     * 
     * @param termWidgetToSnap
     *      The term that is being dragged, see what parts of the given term area intersect
     *      with it.
     */
    private var m_globalMouseBuffer : Point = new Point();
    private var m_localTermAreaMouseBuffer : Point = new Point();
    public function update(mouseState : MouseState, termWidgetToSnap : BaseTermWidget) : Void
    {
        /*
        By constantly checking where a snap should go relative to an existing tree we can more smoothly switch between existing snaps. 
        Instead of display object intersection we can apply some distance function algorithm to each leaf node. Get the 
        bounding rectangle of each leaf node and its data will be the determining factor in what gets snapped. We do not 
        want any changes applied by a preview to factor into this check. The bounds check should be relative to the old 
        positions before the preview layout was applied.
        */
        
        // On every update we clear the snapping information
        // These are the snapping parameters that should be modified is any snap
        // is applied. At the end of the update if they maintain these values then no
        // snap was detected on this frame.
        var snapOperator : String = null;
        var widgetAcceptingSnap : BaseTermWidget = null;
        var snapToLeft : Bool = false;
        
        // If the term widget is null we can kill any further processing
        if (termWidgetToSnap != null && m_termArea.isInteractable) 
        {
            // Re-adjust the bounds of the dragged object to fit into the coordinate space of the
            // the term area
            if (!m_widgetToSnapStartDrag) 
            {
                m_widgetToSnapStartDrag = true;
                termWidgetToSnap.getBounds(m_termArea, m_widgetToSnapLocalBounds);
            }
            m_globalMouseBuffer.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
            m_termArea.globalToLocal(m_globalMouseBuffer, m_localTermAreaMouseBuffer);
            
            var widgetBoundsHalfWidth : Float = m_widgetToSnapLocalBounds.width * 0.5;
            var widgetBoundsHalfHeight : Float = m_widgetToSnapLocalBounds.height * 0.5;
            m_widgetToSnapLocalBounds.x = m_localTermAreaMouseBuffer.x - widgetBoundsHalfWidth;
            m_widgetToSnapLocalBounds.y = m_localTermAreaMouseBuffer.y - widgetBoundsHalfHeight;
            
            // Doing a dumb method of several iterations
            // First iteration checks for wild cards, since they take the highest priority for snaps
            // Iterate through every leaf widget and apply a distance function check to see if a snap applies
            var i : Int = 0;
            var widgetCandidate : BaseTermWidget = null;
            var widgetCandidateBounds : Rectangle = null;
            var numLeafWidgets : Int = m_widgetCandidates.length;
            for (i in 0...numLeafWidgets){
                widgetCandidate = m_widgetCandidates[i];
                widgetCandidateBounds = m_widgetCandidateBounds[i];
                
                var widgetCandidateCenterX : Float = widgetCandidateBounds.x + widgetCandidateBounds.width * 0.5;
                var widgetCandidateCenterY : Float = widgetCandidateBounds.y + widgetCandidateBounds.height * 0.5;
                
                var termWidgetToSnapCenterX : Float = m_widgetToSnapLocalBounds.x + widgetBoundsHalfWidth;
                var termWidgetToSnapCenterY : Float = m_widgetToSnapLocalBounds.y + widgetBoundsHalfHeight;
                
                // If the candiate widget is a wild card then it takes the highest priority for snapping
                var node : ExpressionNode = widgetCandidate.getNode();
                if (Std.is(node, WildCardNode)) 
                {
                    if (widgetCandidateBounds.intersects(m_widgetToSnapLocalBounds)) 
                    {
                        widgetAcceptingSnap = widgetCandidate;
                        break;
                    }
                }
				
				// For candiates that are operators, we only care about whether the dragged card hits a parenthesis  
				// Check if an intersection occurs with the bounding box of the dragged widget and the boxes of either parenthesis
                var doPerformSnap : Bool = false;
                if (node.isOperator() &&
                    node.wrapInParentheses &&
                    widgetCandidate.m_parenthesesCanvas.numChildren == 2) 
                {
                    // Preview causes the parenthesis to shift so we need to to reference a saved copy of the bounds when
                    // the expression was first created
                    var firstParenthesisBounds : Rectangle = m_widgetCandidateParenthesisBounds[2 * i];
                    if (!m_widgetToSnapLocalBounds.intersects(firstParenthesisBounds)) 
                    {
                        var secondParenthesisBounds : Rectangle = m_widgetCandidateParenthesisBounds[2 * i + 1];
                        if (m_widgetToSnapLocalBounds.intersects(secondParenthesisBounds)) 
                        {
                            doPerformSnap = true;
                            widgetCandidateCenterX = secondParenthesisBounds.width * 0.5 + secondParenthesisBounds.x;
                            widgetCandidateCenterY = secondParenthesisBounds.height * 0.5 + secondParenthesisBounds.y;
                        }
                    }
                    else 
                    {
                        doPerformSnap = true;
                        widgetCandidateCenterX = firstParenthesisBounds.width * 0.5 + firstParenthesisBounds.x;
                        widgetCandidateCenterY = firstParenthesisBounds.height * 0.5 + firstParenthesisBounds.y;
                    }
                }
                else if (!node.isOperator()) 
                {
                    // Check for an intersect on a terminal card
                    var intersectRadius : Float = Math.min(m_widgetToSnapLocalBounds.width, m_widgetToSnapLocalBounds.height) * 0.6 * widgetCandidate.scaleX;
                    doPerformSnap = MathUtil.circleIntersect(widgetCandidateCenterX, widgetCandidateCenterY, intersectRadius, termWidgetToSnapCenterX, termWidgetToSnapCenterY, intersectRadius);
                }
                
                if (doPerformSnap) 
                {
                    var allowMultiply : Bool = m_levelRules.allowMultiply;
                    var allowDivide : Bool = m_levelRules.allowDivide;
                    
                    // Create a vector pointing from the term widget to snap to the widget on the board
                    // Negative x means the term to to snap is approaching from the right,
                    // otherwise it is approaching from the left
                    // Negative y means it is approaching from the bottom
                    // otherwise it is approaching from the top
                    var deltaX : Float = widgetCandidateCenterX - termWidgetToSnapCenterX;
                    var deltaY : Float = widgetCandidateCenterY - termWidgetToSnapCenterY;
                    
                    // If a node is part of a fraction then the snapping operator can never be a divide
                    // since we don't want multiple division bars to stack up on top of each other
                    var isInFraction : Bool = ExpressionUtil.isNodePartOfFraction(m_vectorSpace, node);
                    if (isInFraction) 
                    {
                        if (allowMultiply) 
                        {
                            widgetAcceptingSnap = widgetCandidate;
                            snapOperator = m_vectorSpace.getMultiplicationOperator();
                            if (deltaX < 0) 
                            {
                                // Multiply and do it to the right of the candidate
                                snapToLeft = false;
                            }
                            else 
                            {
                                // Multiply and do it to the left of the candidate
                                snapToLeft = true;
                            }
                        }
                    }
                    else 
                    {
                        // Attempting a division on the candidate, the division needs to occur on the highest
                        // level product group containing this node.
                        if (deltaY < 0) 
                        {
                            if (allowDivide) 
                            {
                                var nodeTracker : ExpressionNode = node;
                                var nodeWidgetTracker : BaseTermWidget = widgetCandidate;
                                while (nodeTracker.parent != null &&
                                nodeTracker.parent.isSpecificOperator(m_vectorSpace.getMultiplicationOperator()))
                                {
                                    nodeTracker = nodeTracker.parent;
                                    nodeWidgetTracker = nodeWidgetTracker.parentWidget;
                                }
                                
                                widgetAcceptingSnap = nodeWidgetTracker;
                                snapOperator = m_vectorSpace.getDivisionOperator();
                                snapToLeft = false;
                            }
                        }
                        else 
                        {
                            if (allowMultiply) 
                            {
                                widgetAcceptingSnap = widgetCandidate;
                                snapOperator = m_vectorSpace.getMultiplicationOperator();
                                if (deltaX < 0) 
                                {
                                    // Multiply and do it to the right of the candidate
                                    snapToLeft = false;
                                }
                                else 
                                {
                                    // Multiply and do it to the left of the candidate
                                    snapToLeft = true;
                                }
                            }
                        }
                    }
                }  
				
				// TODO: This may be breaking to early  
                // Stopping on first valid snap   
                if (widgetAcceptingSnap != null) 
                {
                    break;
                }
            }
        }
        else 
        {
            m_widgetToSnapStartDrag = false;
        }  
		
		// If a snap was detected check if the parameters for the snap were altered. If it is, clear  
		// any animations or previews with the old snap and start the animations for the new snapped widget.  
        // The parameters for the snap are the target node, the operator, and side of the snap (left or right) 
        if (m_snapToLeft != snapToLeft ||
            m_operatorForSnap != snapOperator ||
            m_widgetAcceptingSnap != widgetAcceptingSnap) 
        {
            // Previews are only erased if the snap was a mult or div
            if (m_widgetAcceptingSnap != null && !(Std.is(m_widgetAcceptingSnap, WildCardTermWidget))) 
            {
                if (termWidgetToSnap != null) {
                    termWidgetToSnap.visible = true;
                }
                hideMultiplyDividePreview();
            }
            
            if (widgetAcceptingSnap != null && !(Std.is(widgetAcceptingSnap, WildCardTermWidget))) 
            {
                if (termWidgetToSnap != null) {
                    termWidgetToSnap.visible = false;
                }
                showMultiplyDividePreview(
                        termWidgetToSnap.getNode().data,
                        snapOperator,
                        snapToLeft,
                        widgetAcceptingSnap
                        );
            }
            
            m_snapToLeft = snapToLeft;
            m_operatorForSnap = snapOperator;
            m_widgetAcceptingSnap = widgetAcceptingSnap;
        }
    }
    
    /**
     * This is a hacky function as we force a clearing of snaps before we apply modification to
     * the term area
     */
    public function clearAll() : Void
    {
        if (m_widgetAcceptingSnap != null) 
        {
            hideMultiplyDividePreview();
        }
        m_snapToLeft = false;
        m_operatorForSnap = null;
        m_widgetAcceptingSnap = null;
    }
    
    public function getWidgetAcceptingSnap() : BaseTermWidget
    {
        return m_widgetAcceptingSnap;
    }
    
    public function getOperatorForSnap() : String
    {
        return m_operatorForSnap;
    }
    
    public function getSnapToLeft() : Bool
    {
        return m_snapToLeft;
    }
    
    public function dispose() : Void
    {
        m_termArea.removeEventListener(GameEvent.TERM_AREA_CHANGED, onTermAreaChanged);
    }
    
    private function onTermAreaChanged() : Void
    {
        // Reset the list of available widget and their bounding rectangles
		m_widgetCandidates = new Array<BaseTermWidget>();
		m_widgetCandidateBounds = new Array<Rectangle>();
		m_widgetCandidateParenthesisBounds = new Array<Rectangle>();
		
        _refreshCandidateWidgetList(m_termArea.getWidgetRoot(), m_widgetCandidates, m_widgetCandidateBounds);
        
        // Look at the current state of the widgets and sort based on snapping priority
        // Do an insertion sort on the regex set based on priority
        var i : Int = 0;
        var currentWidget : BaseTermWidget = null;
        var currentBounds : Rectangle = null;
        var prevWidget : BaseTermWidget = null;
        var prevBounds : Rectangle = null;
        var holeIndex : Int = 0;
        var numWidgets : Int = m_widgetCandidates.length;
        for (i in 1...numWidgets){
            prevWidget = m_widgetCandidates[i - 1];
            prevBounds = m_widgetCandidateBounds[i - 1];
            currentWidget = m_widgetCandidates[i];
            currentBounds = m_widgetCandidateBounds[i];
            holeIndex = i;
            
            // If current is higher priority than previous, then keep shifting
            // the previous over until we find the proper index
            var currentPriorityValue : Int = ((Std.is(currentWidget, WildCardTermWidget))) ? 1 : 0;
            var prevPriorityValue : Int = ((Std.is(prevWidget, WildCardTermWidget))) ? 1 : 0;
            while (holeIndex > 0 && currentPriorityValue > prevPriorityValue)
            {
                m_widgetCandidates[holeIndex] = prevWidget;
                m_widgetCandidateBounds[holeIndex] = currentBounds;
                holeIndex--;
                
                var nextHoleIndex : Int = holeIndex - 1;
                if (nextHoleIndex > -1) 
                {
                    prevWidget = m_widgetCandidates[nextHoleIndex];
                    prevBounds = m_widgetCandidateBounds[nextHoleIndex];
                    prevPriorityValue = ((Std.is(prevWidget, WildCardTermWidget))) ? 1 : 0;
                }
            }
            
            m_widgetCandidates[holeIndex] = currentWidget;
            m_widgetCandidateBounds[holeIndex] = currentBounds;
        }
    }
    
    /**
     * Candidate widgets are the terminal symbol nodes AND operators containing the parenthesis.
     * These are the nodes that accept snaps.
     * 
     * The way parenthesis should work is if the actual parenthesis graphic is touched, a snap should occur
     * outside of it.
     */
    private function _refreshCandidateWidgetList(widget : BaseTermWidget,
            candidateWidgetList : Array<BaseTermWidget>,
            candidateWidgetBoundsList : Array<Rectangle>) : Void
    {
        if (widget != null) 
        {
            if (widget.leftChildWidget == null && widget.rightChildWidget == null ||
                widget.getNode().wrapInParentheses) 
            {
                candidateWidgetList.push(widget);
                candidateWidgetBoundsList.push(widget.rigidBodyComponent.boundingRectangle.clone());
                
                if (widget.m_parenthesesCanvas.numChildren == 2) 
                {
                    m_widgetCandidateParenthesisBounds.push(widget.m_parenthesesCanvas.getChildAt(0).getBounds(m_termArea));
                    m_widgetCandidateParenthesisBounds.push(widget.m_parenthesesCanvas.getChildAt(1).getBounds(m_termArea));
                }
                else 
                {
                    m_widgetCandidateParenthesisBounds.push(null);
                    m_widgetCandidateParenthesisBounds.push(null);
                    
                }
            }
            
            _refreshCandidateWidgetList(widget.leftChildWidget, candidateWidgetList, candidateWidgetBoundsList);
            _refreshCandidateWidgetList(widget.rightChildWidget, candidateWidgetList, candidateWidgetBoundsList);
        }
    }
    
    // TODO: Replace with routine that modifies the preview
    private function showMultiplyDividePreview(data : String,
            operator : String,
            snapToLeft : Bool,
            widgetAcceptingSnap : BaseTermWidget) : Void
    {
        var vectorspace : RealsVectorSpace = m_vectorSpace;
        var previewTree : ExpressionTreeWidget = m_termArea.getPreviewView(true);
        var previewExpressionTree : ExpressionTree = previewTree.getTree();
		function onNodeAddedToPreview(event : Event, params : Dynamic) : Void
        {
            // Timing issue:
            // Only redraw the preview after the new node has been added to the expression tree
            m_termArea.showPreview(true);
            previewExpressionTree.removeEventListener(ExpressionTreeEvent.ADD, onNodeAddedToPreview);
            
            // Use the added node id to find the new widgets created for the preview
            var nodeAdded : ExpressionNode = params.nodeAdded;
            
            var snappedSymbolCopy : BaseTermWidget = previewTree.getWidgetFromNodeId(nodeAdded.id);
            var snappedOperatorCopy : BaseTermWidget = snappedSymbolCopy.parentWidget;
            
            // Blink the new card in the preview
            m_blinkTween.reset(snappedSymbolCopy, m_tweenRepeatDuration);
            m_blinkTween.scaleTo(1.1);
            m_blinkTween.repeatCount = 0;
            m_blinkTween.reverse = true;
            Starling.current.juggler.add(m_blinkTween);
            
            // For division, the bar spills over horizontally after some amount so width should be capped to some max amount
            var operatorImage : DisplayObject = (try cast(snappedOperatorCopy, GroupTermWidget) catch(e:Dynamic) null).groupImage;
            var scaleXValue : Float = ((operator == vectorspace.getDivisionOperator())) ? 
            1 + (25.0 / operatorImage.width) : 1.5;
            
            m_operatorTween.reset(operatorImage, m_tweenRepeatDuration);
            m_operatorTween.animate("scaleX", scaleXValue);
            m_operatorTween.animate("scaleY", 1.5);
            m_operatorTween.repeatCount = 0;
            m_operatorTween.reverse = true;
            Starling.current.juggler.add(m_operatorTween);
        };
        previewExpressionTree.addEventListener(ExpressionTreeEvent.ADD, onNodeAddedToPreview);
        var matchingNode : ExpressionNode = ExpressionUtil.getNodeById(widgetAcceptingSnap.getNode().id, previewExpressionTree.getRoot());
        previewExpressionTree.addLeafNode(operator, data, snapToLeft, matchingNode, 0, 0);
    }
    
    private function hideMultiplyDividePreview() : Void
    {
        if (m_termArea.getPreviewShowing()) 
        {
            // Kill the blink tween on the preview card
            Starling.current.juggler.remove(m_blinkTween);
            
            // Kill the operator tween on the preview operator
            Starling.current.juggler.remove(m_operatorTween);
            
            m_termArea.showPreview(false);
        }
    }
}



