package wordproblem.scripts.barmodel;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.math.util.MathUtil;
import dragonbox.common.ui.MouseState;
import dragonbox.common.util.XColor;

import motion.Actuate;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.filters.BitmapFilter;
import openfl.geom.Point;
import openfl.geom.Rectangle;

import wordproblem.display.DottedRectangle;
import wordproblem.display.PivotSprite;
import wordproblem.display.util.BitmapUtil;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.barmodel.view.BarWholeView;
import wordproblem.engine.events.DataEvent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.expression.widget.term.SymbolTermWidget;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;
import wordproblem.scripts.barmodel.ICardOnSegmentEdgeScript;
import wordproblem.scripts.barmodel.IHitAreaScript;
import wordproblem.scripts.barmodel.RadialMenuControl;

/**
 * This script controls showing all the actions possible when the user drops a card
 * on the right edge of a segment. The purpose is to allow for multiple action types in a
 * single gesture
 */
class CardOnSegmentEdgeRadialOptions extends BaseBarModelScript implements IHitAreaScript
{
    /**
     * These are the possible actions in a level when a card is dropped
     */
    private var m_gestures : Array<ICardOnSegmentEdgeScript>;
    
    /**
     * On every end drag we keep track of what gestures in the candidate list have
     * been marked as valid. Each element here should match with the element in the
     * gesture list.
     * 
     * True means the gesture at the same index can be performed
     */
    private var m_isGestureValid : Array<Bool>;
    
    /**
     * This controls all the logic to get a radial menu to be drawn and to figure
     * out which segment was selected.
     */
    private var m_radialMenuControl : RadialMenuControl;
    
    private var m_savedDraggedWidget : BaseTermWidget;
    private var m_savedDraggedWidgetExtraParams : Dynamic;
    private var m_savedSelectedBarId : String;
    private var m_hoveredBarIdOnLastFrame : String;
    
    /**
     * Each menu slice needs icons to indicate what slice does, these are pasted on top of the
     * segment image.
     * Icons need to be created every time the menu reopens
     */
    private var m_gestureIcons : Array<DisplayObject>;
    
    /**
     * When the user mouses over a segment, a hover name describing the action pops up
     */
    private var m_gestureHoverOverName : Array<String>;
    
    /**
     * For the special cases where only one gesture is valid with a specific card on a segment,
     * the preview is applied automatically on that segment without the radial menu appearing.
     * This keeps track of such a gesture that is active, must be disable if mouse is over a different segment
     */
    private var m_gesturePreviewWithoutMenu : ICardOnSegmentEdgeScript;
    
    /**
     * Active hit areas on a given frame
     */
    private var m_hitAreas : Array<Rectangle>;
    private var m_hitAreaPool : Array<Rectangle>;
    
    /**
     * It is not guaranteed that each bar whole will has a hit area, for example without any add new segment gesture
     * the longest bar should not get a hit area. The index of this list matches that of the hit area buffer, the
     * value at an index is the index of the bar whole in the bar model data.
     */
    private var m_hitAreaIndexToBarWholeIndex : Array<Int>;
    
    /**
     * If user has dragged over a hit area and there are multiple options for that area we need to show some
     * visual feedback that the area will apply some change. Since we do not know what option the player will select,
     * we do not know what preview to use.
     * 
     * For know we just redraw the hit box.
     */
    private var m_currentMouseOverHitAreaDisplay : DottedRectangle;
    private var m_currentAddSubtractIcon : PivotSprite;
    private var m_currentMouseOverHitArea : Rectangle;
    
    /**
     * Should hit areas for this action be shown in at the start of a frame
     */
    private var m_showHitAreas : Bool;
    
    /**
     * On the frame that an end drag occurs we want this script to all others in the same sequence to
     * prevent those scripts performing logic based on that event. If we don't have this flag, those
     * scripts would continue executing and multiple gestures might be performed on a single end drag.
     */
    private var m_bufferedEventOnFrameCausedChange : Bool;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_gestures = new Array<ICardOnSegmentEdgeScript>();
        m_isGestureValid = new Array<Bool>();
        m_gestureIcons = new Array<DisplayObject>();
        m_gestureHoverOverName = new Array<String>();
        
        m_hitAreas = new Array<Rectangle>();
        m_hitAreaPool = new Array<Rectangle>();
        m_hitAreaIndexToBarWholeIndex = new Array<Int>();
        m_bufferedEventOnFrameCausedChange = false;
        
        var hitAreaBackgroundBitmapData : BitmapData = m_assetManager.getBitmapData("wildcard");
        var nineslicePadding : Int = 10;
        var ninesliceGrid : Rectangle = new Rectangle(nineslicePadding, nineslicePadding, hitAreaBackgroundBitmapData.width - 2 * nineslicePadding, hitAreaBackgroundBitmapData.height - 2 * nineslicePadding);
        var cornerBitmapData : BitmapData = m_assetManager.getBitmapData("dotted_line_corner");
        var segmentBitmapData : BitmapData = m_assetManager.getBitmapData("dotted_line_segment");
        m_currentMouseOverHitAreaDisplay = new DottedRectangle(hitAreaBackgroundBitmapData, ninesliceGrid, 1, cornerBitmapData, segmentBitmapData);
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        hideMouseOverHitAreaPreview();
		m_currentMouseOverHitAreaDisplay.dispose();
		m_currentMouseOverHitAreaDisplay = null;
        
        if (m_currentAddSubtractIcon != null) 
        {
			if (m_currentAddSubtractIcon.parent != null) m_currentAddSubtractIcon.parent.removeChild(m_currentAddSubtractIcon);
			m_currentAddSubtractIcon.dispose();
			m_currentAddSubtractIcon = null;
        }
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.FAIL;
        m_showHitAreas = false;
        if (m_ready) 
        {
            var mouseState : MouseState = m_gameEngine.getMouseState();
            m_globalMouseBuffer.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
            m_localMouseBuffer = m_barModelArea.globalToLocal(m_globalMouseBuffer);
            
            iterateThroughBufferedEvents();
            
            // While dragging, check if the mouse is over the hit area representing the edge of a segment
            // We should blink the segment to tell the player something can happen
            var targetHitAreaIndex : Int = -1;
            if ((mouseState.leftMouseDraggedThisFrame || mouseState.leftMouseDown) && m_widgetDragSystem.getWidgetSelected() != null) 
            {
                m_showHitAreas = true;
                var hitAreas : Array<Rectangle> = getActiveHitAreas();
                var numHitAreas : Int = hitAreas.length;
                var i : Int = 0;
				var hitArea : Rectangle = null;
                for (i in 0...numHitAreas){
                    hitArea = hitAreas[i];
                    if (hitArea.containsPoint(m_localMouseBuffer)) 
                    {
                        targetHitAreaIndex = i;
                        break;
                    }
                }
                
                if (targetHitAreaIndex != -1) 
                {
                    // Need to map the hit area index to the bar whole
                    var targetBarWholeIndex : Int = m_hitAreaIndexToBarWholeIndex[targetHitAreaIndex];
                    var targetBarWhole : BarWhole = m_barModelArea.getBarWholeViews()[targetBarWholeIndex].data;
                    
                    // For the radial menu to pop up, the number of possible actions that can execute with the given
                    // segment and dragged expression need to pass some threshold
                    // This indicates there is ambiguity in the gesture that the user needs to explicitly resolve.
                    var numGestures : Int = m_gestures.length;
                    var numValidGestures : Int = 0;
                    var lastValidGestureIndex : Int = -1;
                    for (i in 0...numGestures){
                        var gestureScript : ICardOnSegmentEdgeScript = m_gestures[i];
                        m_isGestureValid[i] = gestureScript.canPerformAction(m_widgetDragSystem.getWidgetSelected(), targetBarWhole.id);
                        if (m_isGestureValid[i]) 
                        {
                            numValidGestures++;
                            lastValidGestureIndex = i;
                        }
                    }
                    
                    if (numValidGestures > 0) 
                    {
                        status = ScriptStatus.SUCCESS;
                        // Remember the bar segment hovered on this frame so we can remove it if needed on
                        // later frames.
                        if (targetBarWhole.id != m_hoveredBarIdOnLastFrame) 
                        {
                            setDraggedWidgetVisible(false);
                            m_hoveredBarIdOnLastFrame = targetBarWhole.id;
                            m_barModelArea.showPreview(false);
                            
                            // If only one gesture is valid on the current segment, apply the preview of that gesture
                            if (numValidGestures == 1) 
                            {
                                var gestureScript = m_gestures[lastValidGestureIndex];
                                gestureScript.showPreview(m_widgetDragSystem.getWidgetSelected(), m_widgetDragSystem.getExtraParams(), targetBarWhole.id);
                                m_gesturePreviewWithoutMenu = gestureScript;
                            }
                            // Multiple options mean we do not know what preview to show, however we still need some feedback that the hit area they moused
                            // over will have some effect
                            else 
                            {
                                // Add some animation here to show that something would happen if the user drops over this hit area
                                m_currentMouseOverHitArea = hitArea;
                                showMouseOverHitAreaPreview();
                            }
                        }
                    }
                }
                // Dragged card is not over any hit areas
                else 
                {
                    hideMouseOverHitAreaPreview();
                    clearAllPreviews();
                    m_hoveredBarIdOnLastFrame = null;
                }
            }
            // Nothing is being dragged
            // If the radial menu has been opened, update it on every frame to get the proper mouse over state
            else if (m_hoveredBarIdOnLastFrame != null) 
            {
                //clearAllPreviews();
                
            }
            
            
            
            if (m_radialMenuControl.isOpen) 
            {
                m_radialMenuControl.visit();
                
                // If menu is open we may want to interupt other scripts from executing,
                // namely any ones that interprets clicks, as the menu requires the clicks to
                // pick an option. This might result in a conflict.
                status = ScriptStatus.SUCCESS;
            }
        }  
		
		// HACK: On a buffered event that causes a change to the bar model we return success to short  
		// circuit other scripts that might try to act on that event as well.  
		// The case where this is a problem is when another gesture has a hit area overlapping with this one.  
		// For example the add vertical label hit area may overlap and on a release it gets executed along with 
        // an action in this script, two changes are applied to the model instead of one
        if (m_bufferedEventOnFrameCausedChange) 
        {
            status = ScriptStatus.SUCCESS;
            m_bufferedEventOnFrameCausedChange = false;
        }
        
        return status;
    }
    
    public function getActiveHitAreas() : Array<Rectangle>
    {
        while (m_hitAreas.length > 0)
        {
            m_hitAreaPool.push(m_hitAreas.pop());
        }  
		
		// Reset hit area to bar whole index  
		m_hitAreaIndexToBarWholeIndex = new Array<Int>();
        
        // The hit areas for adding to edge are governed by these rules:
        // Should appear on the rightmost edge
        // Should try to extend the hit area from that edge to the rightmost edge
        // of the longest bar.
        // If hit area created by doing this appears smaller than some minimum size, then
        // use the minimum size instead (this is true for the longest bar)
        
        // Find the rightmost edge to serve as the limit to extend the other bars to
        var furthestRightEdgeX : Float = 0;
        var barWholeViews : Array<BarWholeView> = m_barModelArea.getBarWholeViews();
        var i : Int = 0;
        var barWholeView : BarWholeView = null;
        var numBarWholeViews : Int = barWholeViews.length;
        var longestBarValue : Float = 0;
        for (i in 0...numBarWholeViews){
            barWholeView = barWholeViews[i];
            var segmentViews : Array<BarSegmentView> = barWholeView.segmentViews;
            var rightEdgeX : Float = segmentViews[segmentViews.length - 1].rigidBody.boundingRectangle.right;
            if (rightEdgeX > furthestRightEdgeX) 
            {
                furthestRightEdgeX = rightEdgeX;
                longestBarValue = barWholeView.data.getValue();
            }
        }
        
        var hitBoxMinimumWidth : Float = 50;
        var xOffsetIntoBox : Float = 10;
        for (i in 0...numBarWholeViews){
            barWholeView = barWholeViews[i];
            
            // HACK: Need to handle the case where adding new segment is disabled but add comparison is enabled
            // An incorrect hit area showing '-' on the longest bar appears
            // Hit areas would need to know about what child scripts are active
            // Need to know before hand whether add bar segments scripts is active, if it is not then there
            // should not be a hit area on the longest bar
            if (barWholeView.data.getValue() == longestBarValue && !canAddNewBarSegment()) 
            {
                // This is the longest bar and we cannot add new segments, don't do anything
                
            }
            else 
            {
                var segmentViews = barWholeView.segmentViews;
                var hitAreaX : Float = 0;
                var hitAreaY : Float = 0;
                var hitAreaWidth : Float = 0;
                var hitAreaHeight : Float = 0;
                if (segmentViews.length > 0) 
                {
                    // The right edge of the last segment view acts as the anchor point
                    var lastSegmentViewBounds : Rectangle = segmentViews[segmentViews.length - 1].rigidBody.boundingRectangle;
                    var rightEdgeX = lastSegmentViewBounds.right;
                    
                    hitAreaX = lastSegmentViewBounds.right - xOffsetIntoBox;
                    hitAreaY = lastSegmentViewBounds.top;
                    hitAreaWidth = furthestRightEdgeX - rightEdgeX + xOffsetIntoBox;
                    hitAreaHeight = lastSegmentViewBounds.height;
                }
                
                if (hitAreaWidth < hitBoxMinimumWidth) 
                {
                    hitAreaWidth = hitBoxMinimumWidth;
                }  
				
				// Grab a rectangle from the pool  
                var segmentHitArea : Rectangle = ((m_hitAreaPool.length > 0)) ? m_hitAreaPool.pop() : new Rectangle();
                segmentHitArea.setTo(hitAreaX, hitAreaY, hitAreaWidth, hitAreaHeight);
                m_hitAreas.push(segmentHitArea);
                
                m_hitAreaIndexToBarWholeIndex.push(i);
            }
        }
        
        return m_hitAreas;
    }
    
    private function canAddNewBarSegment() : Bool
    {
        var canAdd : Bool = false;
        for (gesture in m_gestures)
        {
            if (Std.is(gesture, AddNewBarSegment)) 
            {
                canAdd = (try cast(gesture, AddNewBarSegment) catch(e:Dynamic) null).getIsActive();
            }
        }
        return canAdd;
    }
    
    public function getShowHitAreasForFrame() : Bool
    {
        return m_showHitAreas;
    }
    
    public function postProcessHitAreas(hitAreas : Array<Rectangle>, hitAreaGraphics : Array<DisplayObjectContainer>) : Void
    {
        // We will need to check whether each hit area allows for adding the comparison, adding a new segment, or both
        var allowAddNewSegment : Bool = false;
        var allowAddComparison : Bool = false;
        for (gesture in m_gestures)
        {
            if (Std.is(gesture, AddNewBarSegment)) 
            {
                allowAddNewSegment = true;
            }
            else if (Std.is(gesture, AddNewBarComparison)) 
            {
                allowAddComparison = true;
            }
        }
		
		// We are assuming that each bar on a line has its own hit area  
        // Get the bar with the greatest value
        var barWholes : Array<BarWhole> = m_barModelArea.getBarModelData().barWholes;
        var i : Int = 0;
        var maxBarWholeValue : Float = -1;
        for (i in 0...barWholes.length){
            var barValue : Float = barWholes[i].getValue();
            if (maxBarWholeValue < barValue) 
            {
                maxBarWholeValue = barValue;
            }
        }
        
        for (i in 0...hitAreas.length){
            var barValue = barWholes[i].getValue();
            var mainIcon : PivotSprite = new PivotSprite();
            var hitArea : Rectangle = hitAreas[i];
            if (allowAddComparison && allowAddNewSegment) 
            {
                // Do not add comparison on the longest bar (or any bar with that same value)
                if (barValue < maxBarWholeValue) 
                {
                    mainIcon = createAddSubtractIcon();
                }
                else 
                {
                    var addIcon : Bitmap = new Bitmap(m_assetManager.getBitmapData("plus"));
                    mainIcon.addChild(addIcon);
                }
            }
            else if (allowAddComparison) 
            {
                var subtractIcon : Bitmap = new Bitmap(m_assetManager.getBitmapData("subtract"));
                mainIcon.addChild(subtractIcon);
            }
            else if (allowAddNewSegment) 
            {
                var addIcon = new Bitmap(m_assetManager.getBitmapData("plus"));
                mainIcon.addChild(addIcon);
            }
            
            if (mainIcon != null) 
            {
                var spacePadding : Float = 4;
                // Center and fit the icon in the box
                mainIcon.x = hitArea.width * 0.5;
                mainIcon.y = hitArea.height * 0.5;
                mainIcon.pivotX = mainIcon.width * 0.5;
                mainIcon.pivotY = mainIcon.height * 0.5;
                
                var targetScale : Float = 1.0;
                var maxWidth : Float = hitArea.width - 2 * spacePadding;
                if (mainIcon.width > maxWidth) 
                {
                    targetScale = Math.min(targetScale, maxWidth / mainIcon.width);
                }
                
                var maxHeight : Float = hitArea.height - 2 * spacePadding;
                if (mainIcon.height > maxHeight) 
                {
                    targetScale = Math.min(targetScale, maxHeight / mainIcon.height);
                }
                mainIcon.scaleX = mainIcon.scaleY = targetScale;
                
                hitAreaGraphics[i].addChild(mainIcon);
            }
        }
    }
    
    private function createAddSubtractIcon() : PivotSprite
    {
        var compositeOperators : PivotSprite = new PivotSprite();
        var addIcon : Bitmap = new Bitmap(m_assetManager.getBitmapData("plus"));
        var subtractIcon : Bitmap = new Bitmap(m_assetManager.getBitmapData("subtract"));
        var slashIcon : PivotSprite = new PivotSprite();
		slashIcon.addChild(new Bitmap(m_assetManager.getBitmapData("divide_bar")));
        slashIcon.scaleX = slashIcon.scaleY = 0.8;
        slashIcon.pivotX = slashIcon.width * 0.5;
        slashIcon.pivotY = slashIcon.height * 0.5;
        slashIcon.rotation = MathUtil.radsToDegrees(Math.PI * -0.30);
        var slashOppositeSideLength : Float = -Math.sin(MathUtil.degreesToRads(slashIcon.rotation)) * slashIcon.width;
        addIcon.x = 0;
        addIcon.y = 0;
        addIcon.scaleX = addIcon.scaleY = 0.9;
        slashIcon.x = addIcon.width + slashIcon.width * Math.cos(MathUtil.degreesToRads(slashIcon.rotation)) * 0.5 - 7;
        slashIcon.y = slashOppositeSideLength;
        subtractIcon.x = slashIcon.x + slashIcon.width * Math.cos(MathUtil.degreesToRads(slashIcon.rotation)) * 0.5;
        subtractIcon.y = slashOppositeSideLength * 0.5 + subtractIcon.height + 4;
        subtractIcon.scaleX = subtractIcon.scaleY = 0.9;
        compositeOperators.addChild(slashIcon);
        compositeOperators.addChild(addIcon);
        compositeOperators.addChild(subtractIcon);
        return compositeOperators;
    }
    
    private function clearAllPreviews() : Void
    {
        if (m_gesturePreviewWithoutMenu != null) 
        {
            super.setDraggedWidgetVisible(true);
            m_gesturePreviewWithoutMenu.hidePreview();
            m_gesturePreviewWithoutMenu = null;
        }
    }
    
    private function showMouseOverHitAreaPreview() : Void
    {
        hideMouseOverHitAreaPreview();
        
        if (m_currentMouseOverHitArea != null) 
        {
            m_currentMouseOverHitAreaDisplay.resize(m_currentMouseOverHitArea.width, m_currentMouseOverHitArea.height, 5, 5);
            m_currentMouseOverHitAreaDisplay.x = m_currentMouseOverHitArea.x;
            m_currentMouseOverHitAreaDisplay.y = m_currentMouseOverHitArea.y;
            m_barModelArea.addChild(m_currentMouseOverHitAreaDisplay);
            
            m_currentMouseOverHitAreaDisplay.alpha = 1.0;
			Actuate.tween(m_currentMouseOverHitAreaDisplay, 0.6, { alpha: 0.3 }).repeat().reflect();
            
            // Add the add/subtract icon
            var addSubtractIcon : PivotSprite = m_currentAddSubtractIcon != null ? m_currentAddSubtractIcon : createAddSubtractIcon();
            m_currentAddSubtractIcon = addSubtractIcon;
            var spacePadding : Float = 4;
            addSubtractIcon.scaleX = addSubtractIcon.scaleY = 1.0;
            addSubtractIcon.x = m_currentMouseOverHitArea.width * 0.5;
            addSubtractIcon.y = m_currentMouseOverHitArea.height * 0.5;
            addSubtractIcon.pivotX = addSubtractIcon.width * 0.5;
            addSubtractIcon.pivotY = addSubtractIcon.height * 0.5;
            
            var targetScale : Float = 1.0;
            var maxWidth : Float = m_currentMouseOverHitArea.width - 2 * spacePadding;
            if (addSubtractIcon.width > maxWidth) 
            {
                targetScale = Math.min(targetScale, maxWidth / addSubtractIcon.width);
            }
            
            var maxHeight : Float = m_currentMouseOverHitArea.height - 2 * spacePadding;
            if (addSubtractIcon.height > maxHeight) 
            {
                targetScale = Math.min(targetScale, maxHeight / addSubtractIcon.height);
            }
            addSubtractIcon.scaleX = addSubtractIcon.scaleY = targetScale;
            m_currentMouseOverHitAreaDisplay.addChild(addSubtractIcon);
        }
    }
    
    private function hideMouseOverHitAreaPreview() : Void
    {
        if (m_currentMouseOverHitAreaDisplay.parent != null) 
        {
            if (m_currentMouseOverHitAreaDisplay.parent != null) m_currentMouseOverHitAreaDisplay.parent.removeChild(m_currentMouseOverHitAreaDisplay);
        }
        
        if (m_currentMouseOverHitAreaDisplay != null) 
        {
			Actuate.stop(m_currentMouseOverHitAreaDisplay);
        }
    }
    
    public function addGesture(gestureScript : ICardOnSegmentEdgeScript) : Void
    {
        if (m_ready) 
        {
            // HACK: Doesn't fire at the right time
            // Override needs to be called after the nodes are added to the graph since some of the ready function trace up the
            // parent pointers to find other script nodes.
            (try cast(gestureScript, BaseGameScript) catch(e:Dynamic) null).overrideLevelReady({ });
        }
        
        m_gestures.push(gestureScript);
        m_isGestureValid.push(false);
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        
        // Set up controls for the radial menu
        m_radialMenuControl = new RadialMenuControl(
                m_gameEngine.getMouseState(), 
                mouseOverRadialOption, 
                mouseOutRadialOption, 
                clickRadialOption, 
                drawMenuSegment, 
                disposeMenuSegment
                );
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.END_DRAG_TERM_WIDGET) 
        {
            // If a dragged card was dropped, first check that the drop point is over a valid hit area
            var droppedObject : BaseTermWidget = param.widget;
            var hitAreas : Array<Rectangle> = getActiveHitAreas();
            var numHitAreas : Int = hitAreas.length;
            var i : Int = 0;
            var hitAreaIndex : Int = -1;
            for (i in 0...numHitAreas){
                var hitArea : Rectangle = hitAreas[i];
                if (hitArea.containsPoint(m_localMouseBuffer)) 
                {
                    hitAreaIndex = i;
                    break;
                }
            }
            
            if (hitAreaIndex != -1) 
            {
                var value : String = droppedObject.getNode().data;
                var targetBarWhole : BarWhole = m_barModelArea.getBarWholeViews()[hitAreaIndex].data;
                
                // For the radial menu to pop up, the number of possible actions that can execute with the given
                // segment and dragged expression need to pass some threshold
                // This indicates there is ambiguity in the gesture that the user needs to explicitly resolve.
                var numGestures : Int = m_gestures.length;
                var numValidGestures : Int = 0;
                for (i in 0...numGestures){
                    var gestureScript : ICardOnSegmentEdgeScript = m_gestures[i];
                    m_isGestureValid[i] = gestureScript.canPerformAction(droppedObject, targetBarWhole.id);
                    if (m_isGestureValid[i]) 
                    {
                        numValidGestures++;
                    }
                } 
				
				// Open the radial menu only if there are enough gestures  
                if (numValidGestures > 0) 
                {
                    // Special case, if there is only one valid gesture then just execute that gesture directly
                    if (numValidGestures == 1) 
                    {
                        for (i in 0...numGestures){
                            if (m_isGestureValid[i]) 
                            {
                                m_gestures[i].performAction(droppedObject, param, targetBarWhole.id);
                                m_bufferedEventOnFrameCausedChange = true;
                                break;
                            }
                        }
                    }
                    // Multiple gestures requires opening the radial options
                    else 
                    {
                        m_savedDraggedWidget = droppedObject;
                        m_savedDraggedWidgetExtraParams = param;
                        m_savedSelectedBarId = targetBarWhole.id;
                        
                        // Draw the radial menu with the above options
                        var gestureEnabledList : Array<Bool> = m_isGestureValid.copy();
                        
                        // The radial menu should appear just above the target bar view that was hit
                        // It should not obscure it, since mousing over options applies a preview
                        // on the action on the bar
                        var targetHitArea : Rectangle = hitAreas[hitAreaIndex];
                        var globalHitAreaCoordinates : Point = m_barModelArea.localToGlobal(new Point(targetHitArea.x, targetHitArea.y));
                        
                        // Create hover over names
                        
                        // Unlike previous iterations, we do not have a cancel option
                        m_radialMenuControl.open(gestureEnabledList,
                                globalHitAreaCoordinates.x + targetHitArea.width * 0.5,
                                globalHitAreaCoordinates.y - 60,
                                m_gameEngine.getSprite()
                                );
                        
                        // Put the dragged card in the middle, must scale it down so it fits within
                        // the 60x60 space in the middle
                        var termWidget : BaseTermWidget = new SymbolTermWidget(
                        new ExpressionNode(m_expressionCompiler.getVectorSpace(), value), 
							m_gameEngine.getExpressionSymbolResources(), 
							m_assetManager
                        );
                        var targetScaleY : Float = 60 / termWidget.height;
                        var targetScaleX : Float = 60 / termWidget.width;
                        termWidget.scaleX = termWidget.scaleY = Math.min(targetScaleX, targetScaleY);
                        m_radialMenuControl.getRadialMenuContainer().addChildAt(termWidget, 0);
                        
                        m_gameEngine.dispatchEvent(new DataEvent(GameEvent.OPEN_RADIAL_OPTIONS, {
                                    display : m_radialMenuControl.getRadialMenuContainer()
                                }));
                    }
                }
            }
        }
    }
    
    private function drawMenuSegment(optionIndex : Int,
            rotation : Float,
            arcLength : Float,
            mode : String) : DisplayObject
    {
        var outerRadius : Float = 60;
        var innerRadius : Float = 30;
        var menuSegment : Sprite = new Sprite();
        
        // Map index to the gesture to get the icon name
        var radiusDelta : Float = outerRadius - innerRadius;
        var icon : PivotSprite = new PivotSprite();
		icon.addChild(getIconAtSegmentIndex(optionIndex));
        icon.pivotX = icon.width * 0.5;
        icon.pivotY = icon.height * 0.5;
        icon.scaleX = icon.scaleY = (radiusDelta - 8) / Math.max(icon.width, icon.height);
        icon.x = Math.cos(rotation + arcLength * 0.5) * (outerRadius - radiusDelta * 0.5);
        icon.y = Math.sin(rotation + arcLength * 0.5) * (outerRadius - radiusDelta * 0.5);
        
        var outerBitmapData : BitmapData = null;
        var outlineThickness : Float = 2;
        if (mode == "up") 
        {
            outerBitmapData = BitmapUtil.getRingSegmentBitmapData(30, outerRadius, 0, arcLength, true, null, 0x6AA2C8, true, outlineThickness, 0x000000);
        }
        else if (mode == "over") 
        {
            outerBitmapData = BitmapUtil.getRingSegmentBitmapData(30, outerRadius, 0, arcLength, true, null, 0xF7A028, true, outlineThickness, 0x000000);
        }
        else 
        {
            outerBitmapData = BitmapUtil.getRingSegmentBitmapData(30, outerRadius, 0, arcLength, true, null, 0xCCCCCC, true, outlineThickness, 0x000000);
            
            // Set icon to grey scale
			var filters = new Array<BitmapFilter>();
			filters.push(XColor.getGrayscaleFilter());
			icon.filters = filters;
        }
        
        var segmentImage : PivotSprite = new PivotSprite();
		segmentImage.addChild(new Bitmap(outerBitmapData));
        segmentImage.pivotX = segmentImage.pivotY = outerRadius;
        segmentImage.rotation = MathUtil.radsToDegrees(rotation);
        
        if (mode == "disabled") 
        {
            segmentImage.alpha = 0.7;
        }
        
        menuSegment.addChild(segmentImage);
        menuSegment.addChild(icon);
        
        return menuSegment;
    }
    
    private function disposeMenuSegment(segment : DisplayObject,
            mode : String) : Void
    {
        // Assume the ring texture is the bottom most child
		var ringImage : Bitmap = try cast((try cast((try cast(segment, DisplayObjectContainer) catch (e : Dynamic) null).getChildAt(0), DisplayObjectContainer) catch (e : Dynamic) null).getChildAt(0), Bitmap) catch (e : Dynamic) null;
        ringImage.bitmapData.dispose();
        
        if (mode == "up") 
            { }
        else if (mode == "over") 
            { }
        else 
        { };
    }
    
    private function getIconAtSegmentIndex(index : Int) : DisplayObject
    {
        // Draw icons for each of the gestures
        var icon : DisplayObject = null;
        
        var gestureScript : ICardOnSegmentEdgeScript = null;
        if (index < m_gestures.length) 
        {
            gestureScript = m_gestures[index];
        }  
		
		// The first gesture is adding name on top, this can just be a tiny version of the bar with the  
        // name value pasted on top (just make the bar the  same color
        if (Std.is(gestureScript, AddNewBarComparison)) 
        {
            var subtractIcon : Bitmap = new Bitmap(m_assetManager.getBitmapData("subtract"));
            icon = subtractIcon;
        }
        else if (Std.is(gestureScript, AddNewBarSegment)) 
        {
            var addIcon : Bitmap = new Bitmap(m_assetManager.getBitmapData("plus"));
            icon = addIcon;
        }
        
        return icon;
    }
    
    private function mouseOutRadialOption(optionIndex : Int) : Void
    {
        // Delete any preview that the option triggered
        if (optionIndex >= 0 && optionIndex < m_gestures.length) 
        {
            var gestureOver : ICardOnSegmentEdgeScript = m_gestures[optionIndex];
            gestureOver.hidePreview();
            
            showMouseOverHitAreaPreview();
        }
    }
    
    private function mouseOverRadialOption(optionIndex : Int) : Void
    {
        // Show a new preview related to the given option
        if (optionIndex >= 0 && optionIndex < m_gestures.length) 
        {
            var gestureOver : ICardOnSegmentEdgeScript = m_gestures[optionIndex];
            gestureOver.showPreview(m_savedDraggedWidget, m_savedDraggedWidgetExtraParams, m_savedSelectedBarId);
            
            hideMouseOverHitAreaPreview();
        }
    }
    
    private function clickRadialOption(optionIndex : Int) : Void
    {
        // Map the index to a selected option
        if (optionIndex >= 0 && optionIndex < m_gestures.length && m_isGestureValid[optionIndex]) 
        {
            var gestureToExecute : ICardOnSegmentEdgeScript = m_gestures[optionIndex];
            gestureToExecute.performAction(m_savedDraggedWidget, m_savedDraggedWidgetExtraParams, m_savedSelectedBarId);
        } 
		
		// Close the menu on click  
        m_radialMenuControl.close();
		
        // If radial menu is closed and the mouse is not currently over a hit area, make sure the
        // hit area preview is not visible
        hideMouseOverHitAreaPreview();
        
        m_gameEngine.dispatchEvent(new Event(GameEvent.CLOSE_RADIAL_OPTIONS));
    }
}
