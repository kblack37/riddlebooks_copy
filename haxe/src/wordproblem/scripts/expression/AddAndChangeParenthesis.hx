package wordproblem.scripts.expression;

import dragonbox.common.util.XColor;
import motion.Actuate;
import motion.easing.Expo;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.Event;
import wordproblem.display.PivotSprite;
import wordproblem.display.Scale9Image;
import wordproblem.scripts.expression.BaseTermAreaScript;

import openfl.geom.Point;
import openfl.geom.Rectangle;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.ExpressionUtil;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;

import wordproblem.display.Layer;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.widget.ExpressionTreeWidget;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.resource.AssetManager;

/**
 * Script to handle adding or changing the parenthesis in an existing expression
 * 
 * Press and drag to pull out a new parenthesis.
 * If drop without intersecting any area then nothing happens
 */
class AddAndChangeParenthesis extends BaseTermAreaScript
{
    /** Color when user has not pressed down on the button*/
    private var m_inactiveColor : Int = 0x6AA2C8;
    /** Color when user has pressed down on the button*/
    private var m_activeColor : Int = 0xF7A028;
    
    /**
     * The draggable button to create new parentheses
     */
    private var m_parenthesisButton : Layer;
    
    // Stuff related to the drawing of the button
    private var m_buttonBackground : Scale9Image;
    
    /**
     * A copy of the left paren to show when the player is dragging an edge
     */
    private var m_draggedLeftParenthesisImage : DisplayObject;
    
    /**
     * A copy of the right paren to show when the player is dragging an edge
     */
    private var m_draggedRightParenthesisImage : DisplayObject;
    
    /**
     * When the player is dragging a parenthesis, the movement is only from the left to the right
     * so we fix the y axis and image moves along a rail.
     */
    private var m_fixedYForDraggedParenthesis : Float;
    
    /**
     * The image that is dragged around when a user want to add new parenthesis
     */
    private var m_draggedWholeParenthesis : Sprite;
    
    /** Storage for mouse coordinates during a frame */
    private var m_globalPointBuffer : Point;
    
    /** Storage for mouse coordinates in a different frame of reference during a frame */
    private var m_localPointBuffer : Point;
    
    /**
     * We need to keep of whether the user has initiated a drag on an existing parenthesis
     * If not null then the user is modifying the position
     */
    private var m_widgetWithParenthesisToMove : BaseTermWidget;
    private var m_termAreaWithParenthesisToMove : TermAreaWidget;
    
    /**
     * Reference to the left or right paren edge
     */
    private var m_draggedParenImage : DisplayObject;
    
    /**
     * Reference to the paren image that the user selected to initiate the drag.
     */
    private var m_draggedParenSourceImage : DisplayObject;
    
    /**
     * Set the container and frame of reference the dragged parenthesis image
     * should be pasted on top of.
     */
    private var m_draggedParenCanvas : DisplayObjectContainer;
    
    /**
     * Defining parenthesis requires knowing the furthest left and right edges
     */
    private var m_widgetAnchoredAtEdge : BaseTermWidget;
    private var m_xAnchoredAtLeftEdge : Float;
    private var m_xAnchoredAtRightEdge : Float;
    
    /**
     * List of widgets that a player can stretch or shrink the parenthesis to fit into
     */
    private var m_widgetsParenthesisCanMoveTo : Array<BaseTermWidget>;
    
    /**
     * At any given frame we need to remember what widget we need to add an entire parenthesis to
     * (Needed so we know how to change the preview)
     */
    private var m_hoveredWidgetToAddWholeParenthesisTo : BaseTermWidget;
    private var m_termAreaToAddWholeParenthesisTo : TermAreaWidget;
    
    private var m_outParamsBuffer : Array<Dynamic>;
    
    private var m_hitBoundsBuffer : Rectangle;
    
    private var m_bufferedStatus : Int;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_draggedLeftParenthesisImage = createParenthesisImage("parentheses_left");
        m_draggedRightParenthesisImage = createParenthesisImage("parentheses_right");
        
        m_draggedWholeParenthesis = new Sprite();
        var leftParenImage : DisplayObject = createParenthesisImage("parentheses_left");
        m_draggedWholeParenthesis.addChild(leftParenImage);
        leftParenImage.x = -leftParenImage.width;
        var rightParenImage : DisplayObject = createParenthesisImage("parentheses_right");
        m_draggedWholeParenthesis.addChild(rightParenImage);
        rightParenImage.x = rightParenImage.width;
        
        m_widgetsParenthesisCanMoveTo = new Array<BaseTermWidget>();
        m_hitBoundsBuffer = new Rectangle();
        
        m_globalPointBuffer = new Point();
        m_localPointBuffer = new Point();
        m_outParamsBuffer = new Array<Dynamic>();
    }
    
    public function setParams(canvasForDraggedParen : DisplayObjectContainer,
            containerForParenthesisButton : DisplayObjectContainer) : Void
    {
        m_draggedParenCanvas = canvasForDraggedParen;
        commonInit(containerForParenthesisButton);
        this.setIsActive(m_isActive);
    }
    
    private function createParenthesisImage(bitmapDataName : String) : DisplayObject
    {
        var parenthesisImage : PivotSprite = new PivotSprite();
		parenthesisImage.addChild(new Bitmap(m_assetManager.getBitmapData(bitmapDataName)));
        parenthesisImage.pivotX = parenthesisImage.width * 0.5;
        parenthesisImage.pivotY = parenthesisImage.height * 0.5;
        return parenthesisImage;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
		if (m_draggedLeftParenthesisImage.parent != null) m_draggedLeftParenthesisImage.parent.removeChild(m_draggedLeftParenthesisImage);
		m_draggedLeftParenthesisImage = null;
		if (m_draggedRightParenthesisImage.parent != null) m_draggedRightParenthesisImage.parent.removeChild(m_draggedRightParenthesisImage);
		m_draggedRightParenthesisImage = null;
		if (m_draggedWholeParenthesis.parent != null) m_draggedWholeParenthesis.parent.removeChild(m_draggedWholeParenthesis);
		m_draggedWholeParenthesis = null;
		if (m_parenthesisButton.parent != null) m_parenthesisButton.parent.removeChild(m_parenthesisButton);
		m_parenthesisButton.dispose();
		m_parenthesisButton = null;
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_ready) 
        {
            m_eventDispatcher.removeEventListener(GameEvent.PRESS_PARENTHESIS_TERM_AREA, bufferEvent);
            if (value) 
            {
                // Listen for presses on the cards and operators in the term areas
                m_eventDispatcher.addEventListener(GameEvent.PRESS_PARENTHESIS_TERM_AREA, bufferEvent);
            }
            else 
            {
                // Make sure the dragged paren images are removed when deactivated
                if (m_draggedParenImage != null) 
                {
					if (m_draggedParenImage.parent != null) m_draggedParenImage.parent.removeChild(m_draggedParenImage);
                    m_draggedParenImage = null;
                }
				if (m_draggedWholeParenthesis.parent != null) m_draggedWholeParenthesis.parent.removeChild(m_draggedWholeParenthesis);
                
                // Make sure the paren button is deactived as well
				m_buttonBackground.transform.colorTransform = XColor.rgbToColorTransform(m_inactiveColor);
                m_parenthesisButton.alpha = 1.0;
            }
        }
    }
    
    override public function visit() : Int
    {
        m_bufferedStatus = ScriptStatus.FAIL;
        
        if (m_ready && m_isActive) 
        {
            m_globalPointBuffer.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
            m_outParamsBuffer = new Array<Dynamic>();
            
            // Checking for hit on one of the parenthesis
            super.iterateThroughBufferedEvents();
            
            // The player is actively dragging a whole parenthesis, meaning they are at the stage where
            // they are adding a brand new parenthesis to one of the term areas
            if (m_draggedWholeParenthesis.parent != null) 
            {
				m_outParamsBuffer = new Array<Dynamic>();
                if (m_mouseState.leftMouseReleasedThisFrame) 
                {
					if (m_draggedWholeParenthesis.parent != null) m_draggedWholeParenthesis.parent.removeChild(m_draggedWholeParenthesis);
                    
                    if (this.getTermWidgetUnderPoint(m_globalPointBuffer, m_outParamsBuffer)) 
                    {
                        var widgetToAddParenthesisTo : BaseTermWidget = try cast(m_outParamsBuffer[0], BaseTermWidget) catch(e:Dynamic) null;
                        var termArea : TermAreaWidget = try cast(m_outParamsBuffer[1], TermAreaWidget) catch(e:Dynamic) null;
                        termArea.showPreview(false);
                        widgetToAddParenthesisTo.getNode().wrapInParentheses = true;
                        termArea.redrawAfterModification();
                        
                        m_eventDispatcher.dispatchEvent(new Event(GameEvent.EQUATION_CHANGED));
                    } 
					
					// Revert the color of the button background to inactive state  
					m_buttonBackground.transform.colorTransform = XColor.rgbToColorTransform(m_inactiveColor);
                    m_parenthesisButton.alpha = 1.0;
                }
                else 
                {
                    if (this.getTermWidgetUnderPoint(m_globalPointBuffer, m_outParamsBuffer)) 
                    {
                        // Show preview of what the expression would look like with the new parenthesis
                        var widgetToAddParenthesisTo = try cast(m_outParamsBuffer[0], BaseTermWidget) catch(e:Dynamic) null;
                        var termArea = try cast(m_outParamsBuffer[1], TermAreaWidget) catch(e:Dynamic) null;
                        
                        if (widgetToAddParenthesisTo != m_hoveredWidgetToAddWholeParenthesisTo) 
                        {
                            m_hoveredWidgetToAddWholeParenthesisTo = widgetToAddParenthesisTo;
                            
                            // Hide the last preview
                            if (m_termAreaToAddWholeParenthesisTo != null) 
                            {
                                m_termAreaToAddWholeParenthesisTo.showPreview(false);
                            }
                            m_termAreaToAddWholeParenthesisTo = termArea;
                            
                            // Get the equivalent node data in the preview and wrap it in parenthesis
                            var previewView : ExpressionTreeWidget = termArea.getPreviewView(true);
                            var nodeClone : ExpressionNode = ExpressionUtil.getNodeById(widgetToAddParenthesisTo.getNode().id, previewView.getTree().getRoot());
                            nodeClone.wrapInParentheses = true;
                            termArea.showPreview(true);
                        }
                    }
                    else 
                    {
                        m_hoveredWidgetToAddWholeParenthesisTo = null;
                        if (m_termAreaToAddWholeParenthesisTo != null && m_termAreaToAddWholeParenthesisTo.getPreviewShowing()) 
                        {
                            m_termAreaToAddWholeParenthesisTo.showPreview(false);
                            m_termAreaToAddWholeParenthesisTo = null;
                        }
                    }
                }  // Always return success if in middle of manipulating parens  
                
                
                
                m_bufferedStatus = ScriptStatus.SUCCESS;
            }
            // The player is actively dragging either the left or right part of an existing parenthesis
            // Check if user has pressed on the parenthesis button
            // (This event is not buffered)
            else if (m_widgetWithParenthesisToMove != null) 
            {
                if (m_mouseState.leftMouseReleasedThisFrame) 
                {
                    // Perhaps the easiest method is to fetch all leaves in-order
                    // We know the default layout will read out the leaves from left to right.
                    // Looking at the bounds we check which widgets the dragged points lies between
                    if (this.getTermWidgetClosestToHorizontal(m_globalPointBuffer, m_draggedParenImage == m_draggedLeftParenthesisImage, m_outParamsBuffer)) 
                    {
                        var baseTermWidget : BaseTermWidget = try cast(m_outParamsBuffer[0], BaseTermWidget) catch(e:Dynamic) null;
                        
                        // Delete the original parens
                        m_widgetWithParenthesisToMove.getNode().wrapInParentheses = false;
                        
                        // Make sure both nodes are the leaves at the 'edge' of a term
                        // If it is not then traverse down to the furthest right or left term depending on which paren was dragged
                        if (baseTermWidget.leftChildWidget != null && baseTermWidget.rightChildWidget != null) 
                        {
                            if (m_draggedParenImage == m_draggedLeftParenthesisImage) 
                            {
                                while (baseTermWidget.leftChildWidget != null)
                                {
                                    baseTermWidget = baseTermWidget.leftChildWidget;
                                }
                            }
                            else 
                            {
                                while (baseTermWidget.rightChildWidget != null)
                                {
                                    baseTermWidget = baseTermWidget.rightChildWidget;
                                }
                            }
                        }
                        
                        m_termAreaWithParenthesisToMove.getTree().addParenenthesis(m_widgetAnchoredAtEdge.getNode(), baseTermWidget.getNode());
                        m_termAreaWithParenthesisToMove.redrawAfterModification();
                        m_eventDispatcher.dispatchEvent(new Event(GameEvent.EQUATION_CHANGED));
                    }  
					
					// Based on horizontal position move the bounds of the parens over  
                    m_termAreaWithParenthesisToMove = null;
                    m_widgetWithParenthesisToMove = null;
                    
                    // Remove dragged paren
                    if (m_draggedParenImage != null) 
                    {
						if (m_draggedParenImage.parent != null) m_draggedParenImage.parent.removeChild(m_draggedParenImage);
                        m_draggedParenImage = null;
                        m_draggedParenSourceImage.alpha = 1.0;
                    }
                }
                else if (m_mouseState.leftMouseDraggedThisFrame) 
                {
					m_outParamsBuffer = new Array<Dynamic>();
                    
                    // Update the position of the dragged left/right paren image
                    // The coordinates should be relative to the canvas
                    if (this.getMouseWithinAffectedWidgetBounds(m_globalPointBuffer)) 
                    {
                        if (m_draggedParenImage != null) 
                        {
                            m_localPointBuffer = m_draggedParenCanvas.globalToLocal(m_globalPointBuffer);
                            var localToGlobalYDelta : Float = m_localPointBuffer.y - m_globalPointBuffer.y;
                            
                            m_draggedParenImage.y = m_fixedYForDraggedParenthesis + localToGlobalYDelta;
                            m_draggedParenImage.x = m_localPointBuffer.x;
                            m_draggedParenCanvas.addChild(m_draggedParenImage);
                        }
                    }
                    // Remove the parens as they were dragged out of the valid hit area
                    else 
                    {
                        // Redraw to remove the parens
                        m_widgetWithParenthesisToMove.getNode().wrapInParentheses = false;
                        m_termAreaWithParenthesisToMove.redrawAfterModification();
                        
                        m_widgetWithParenthesisToMove = null;
                        m_termAreaWithParenthesisToMove = null;
                        
                        // Start drag of whole paren, same as if they had pulled it from the button
                        m_draggedParenCanvas.addChild(m_draggedWholeParenthesis);
                        
                        // Remove dragged paren
                        if (m_draggedParenImage != null) 
                        {
							if (m_draggedParenImage.parent != null) m_draggedParenImage.parent.removeChild(m_draggedParenImage);
                            m_draggedParenImage = null;
                            m_draggedParenSourceImage.alpha = 1.0;
                        }
                        
                        m_eventDispatcher.dispatchEvent(new Event(GameEvent.EQUATION_CHANGED));
                    }
                }
                
                m_bufferedStatus = ScriptStatus.SUCCESS;
            }
            
            if (m_mouseState.leftMousePressedThisFrame) 
            {
                m_hitBoundsBuffer = m_parenthesisButton.getBounds(m_parenthesisButton.stage);
                
                // If the mouse hit the button had started a drag on the parens
                if (m_hitBoundsBuffer.containsPoint(m_globalPointBuffer)) 
                {
                    m_draggedParenCanvas.addChild(m_draggedWholeParenthesis);
                    
                    // Have short animation of the paren popping in
					Actuate.tween(m_draggedWholeParenthesis, 0.4, { scaleX: 1.0, scaleY: 1.0 }).ease(Expo.easeOut);
                    
                    // Change color to active
					m_buttonBackground.transform.colorTransform = XColor.rgbToColorTransform(m_activeColor);
                    m_parenthesisButton.alpha = 0.7;
                }
            }  
			
			// Update position of dragged parens, the coordinates should be relative  
            // to the canvas  
            if (m_draggedWholeParenthesis.parent != null) 
            {
                m_localPointBuffer = m_draggedParenCanvas.globalToLocal(m_globalPointBuffer);
                m_draggedWholeParenthesis.x = m_localPointBuffer.x;
                m_draggedWholeParenthesis.y = m_localPointBuffer.y;
            }
        }
        
        return m_bufferedStatus;
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.PRESS_PARENTHESIS_TERM_AREA) 
        {
            // On press we need to remember the original widget containing the affected parens.
            // We can record what the edges are in order to restrict how far the drag should go
            var baseTermWidget : BaseTermWidget = param.widget;
            var termArea : TermAreaWidget = param.termArea;
            var leftParenSelected : Bool = param.left;
            
            m_widgetWithParenthesisToMove = baseTermWidget;
            m_termAreaWithParenthesisToMove = termArea;
            m_draggedParenImage = ((leftParenSelected)) ? m_draggedLeftParenthesisImage : m_draggedRightParenthesisImage;
            
            var originalParen : DisplayObject = baseTermWidget.m_parenthesesCanvas.getChildAt(((leftParenSelected)) ? 0 : 1);
            originalParen.alpha = 0.2;
            m_draggedParenSourceImage = originalParen;
            
            // TODO:
            // Highlight the paren image that was dragged.
            // Move of the dragged paren should be like on a horizontal rail as thats the only degree of freedom
            
            // Check if the affect term widget is part of a numerator or denominator.
            // If division is laid out vertically the in order traversal of a tree will not be
            // in the same order as visually going left to right from the term area.
            // This restriction will prevent strange looking attempts to modify parenthesized group
            var targetRootToGetCandidates : BaseTermWidget = m_termAreaWithParenthesisToMove.getWidgetRoot();
            var isInFraction : Bool = m_termAreaWithParenthesisToMove.layoutDivisionVertically &&
            ExpressionUtil.isNodePartOfFraction(m_expressionCompiler.getVectorSpace(), m_widgetWithParenthesisToMove.getNode());
            if (isInFraction) 
            {
                var divisionWidgetTracker : BaseTermWidget = m_widgetWithParenthesisToMove;
                while (!divisionWidgetTracker.parentWidget.getNode().isSpecificOperator(m_expressionCompiler.getVectorSpace().getDivisionOperator()))
                {
                    divisionWidgetTracker = divisionWidgetTracker.parentWidget;
                }
                
                targetRootToGetCandidates = divisionWidgetTracker;
            }
			
			// Get all pieces that are not horizontal fractions
			m_widgetsParenthesisCanMoveTo = new Array<BaseTermWidget>();
            getWidgetsParenthesisCanMoveTo(targetRootToGetCandidates, m_termAreaWithParenthesisToMove, m_widgetsParenthesisCanMoveTo);
            
            var rightMostWidget : BaseTermWidget = baseTermWidget;
            while (rightMostWidget.rightChildWidget != null)
            {
                rightMostWidget = rightMostWidget.rightChildWidget;
            }
            m_xAnchoredAtRightEdge = rightMostWidget.rigidBodyComponent.boundingRectangle.right;
            
            var leftMostWidget : BaseTermWidget = baseTermWidget;
            while (leftMostWidget.leftChildWidget != null)
            {
                leftMostWidget = leftMostWidget.leftChildWidget;
            }
            m_xAnchoredAtLeftEdge = leftMostWidget.rigidBodyComponent.boundingRectangle.left;
            
            m_widgetAnchoredAtEdge = ((leftParenSelected)) ? rightMostWidget : leftMostWidget;
            var middleY : Float = baseTermWidget.rigidBodyComponent.boundingRectangle.y + baseTermWidget.rigidBodyComponent.boundingRectangle.height * 0.5;
            m_localPointBuffer.setTo(0, middleY);
            m_fixedYForDraggedParenthesis = m_termAreaWithParenthesisToMove.localToGlobal(m_localPointBuffer).y;
            
            m_bufferedStatus = ScriptStatus.SUCCESS;
        }
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        
        m_draggedParenCanvas = m_gameEngine.getSprite();
        commonInit(try cast(m_gameEngine.getUiEntity("parenthesisButton"), DisplayObjectContainer) catch(e:Dynamic) null);
        this.setIsActive(m_isActive);
    }
    
    /**
     * Common setup logic for the script whether it is part of a level or part of a standalone
     * replay where some objects are not setup
     */
    private function commonInit(containerForParenthesisButton : DisplayObjectContainer) : Void
    {
        // Create an icon with a card surrounding by parens
        var parenthesisButtonWidth : Float = 50;
        var parenthesisButtonHeight : Float = 50;
        
        var backgroundBitmapData : BitmapData = m_assetManager.getBitmapData("card_background_square");
        var cornerPadding : Float = 8;
        m_buttonBackground = new Scale9Image(backgroundBitmapData, new Rectangle(
			cornerPadding,
			cornerPadding,
			backgroundBitmapData.width - 2 * cornerPadding,
			backgroundBitmapData.height - 2 * cornerPadding
		));
		m_buttonBackground.transform.colorTransform = XColor.rgbToColorTransform(m_inactiveColor);
        m_buttonBackground.width = parenthesisButtonWidth;
        m_buttonBackground.height = parenthesisButtonHeight;
        
        var parenthesisButton : Layer = new Layer();
        var iconContainer : Sprite = new Sprite();
        var leftParenImage : Bitmap = new Bitmap(m_assetManager.getBitmapData("parentheses_left"));
        var parenScaleFactor : Float = 0.7;
        leftParenImage.scaleX = leftParenImage.scaleY = parenScaleFactor;
        iconContainer.addChild(leftParenImage);
        var rightParenImage : Bitmap = new Bitmap(m_assetManager.getBitmapData("parentheses_right"));
        rightParenImage.scaleX = rightParenImage.scaleY = parenScaleFactor;
        rightParenImage.x = leftParenImage.x + leftParenImage.width * 2;
        iconContainer.addChild(rightParenImage);
        
        parenthesisButton.addChild(m_buttonBackground);
        iconContainer.x = (parenthesisButtonWidth - iconContainer.width) * 0.5;
        iconContainer.y = (parenthesisButtonHeight - iconContainer.height) * 0.5;
        parenthesisButton.addChild(iconContainer);
        
        m_parenthesisButton = parenthesisButton;
        
        if (containerForParenthesisButton != null) 
        {
            containerForParenthesisButton.addChild(m_parenthesisButton);
        }
    }
    
    /**
     * Need to make sure that if the user if dragging around a part of an existing paren that
     * the vertical position has not gone too far above and below the limits of the expression.
     * 
     * Doing so will be interpreted as the user wanting to remove the parenthesis altogether
     * 
     * @return
     *      true if the mouse is still within the expression bounds, false if it has gone too far
     *      up or down
     */
    private function getMouseWithinAffectedWidgetBounds(globalPoint : Point) : Bool
    {
        var withinBounds : Bool = false;
        withinBounds = m_termAreaWithParenthesisToMove.containsPoint(globalPoint);
        return withinBounds;
    }
    
    /**
     * Given the current mouse point figure out what is the new edge that a parenthesis should wrap around
     */
    private function getTermWidgetClosestToHorizontal(globalPoint : Point, movingLeftParen : Bool, outParams : Array<Dynamic>) : Bool
    {
        // Check whether we are moving the left or the right paren, as this determines the side of the bounds
        // we are comparing
        var foundWidget : Bool = false;
        m_localPointBuffer = m_termAreaWithParenthesisToMove.globalToLocal(globalPoint);
        
        // TODO:
        // Left paren cannot move to right of original location
        // Right paren cannot move to left of original location
        
        // Iterate through all possible pieces that are laid out horizontally
        var i : Int = 0;
        var numWidgetsCanMoveParenthesisTo : Int = m_widgetsParenthesisCanMoveTo.length;
        var termWidget : BaseTermWidget = null;
        var termWidgetBounds : Rectangle = null;
        
        if (movingLeftParen && m_localPointBuffer.x <= m_xAnchoredAtRightEdge) 
        {
            // When moving the left paren the hit/snap are for any given object is the hit box formed by the
            // object and the space to the left up to the right edge of the previous widget
            for (i in 0...numWidgetsCanMoveParenthesisTo){
                termWidget = m_widgetsParenthesisCanMoveTo[i];
                termWidgetBounds = termWidget.rigidBodyComponent.boundingRectangle;
                
                if (i > 0) 
                {
                    var prevTermWidget : BaseTermWidget = m_widgetsParenthesisCanMoveTo[i - 1];
                    var prevBounds : Rectangle = prevTermWidget.rigidBodyComponent.boundingRectangle;
                    
                    m_hitBoundsBuffer.setTo(prevBounds.right, termWidgetBounds.y, termWidgetBounds.right - prevBounds.right, termWidgetBounds.height);
                    if (m_hitBoundsBuffer.containsPoint(m_localPointBuffer)) 
                    {
                        foundWidget = true;
                    }
                }
                else if (m_localPointBuffer.x < termWidgetBounds.right) 
                {
                    foundWidget = true;
                }
                
                if (foundWidget) 
                {
                    outParams.push(termWidget);
                    break;
                }
            }
        }
        // Must make sure the picked candidate is within the limits
        /*
            termWidgetBounds = m_widgetWithParenthesisToMove.rigidBodyComponent.boundingRectangle;
            var xLimit:int = (m_movingLeftParen) ? termWidgetBounds.right : termWidgetBounds.left;
            */
        else if (!movingLeftParen && m_localPointBuffer.x > m_xAnchoredAtLeftEdge) 
        {
            // When moving the right paren the hit box is formed by the object and the space until the
            // left edge of the next object
            i = numWidgetsCanMoveParenthesisTo - 1;
            while (i >= 0){
                termWidget = m_widgetsParenthesisCanMoveTo[i];
                termWidgetBounds = termWidget.rigidBodyComponent.boundingRectangle;
                
                if (i < numWidgetsCanMoveParenthesisTo - 1) 
                {
                    // Since we are going from right to left in this search the previous one
                    // is actually to the right
                    var prevTermWidget = m_widgetsParenthesisCanMoveTo[i + 1];
                    var prevBounds = prevTermWidget.rigidBodyComponent.boundingRectangle;
                    
                    m_hitBoundsBuffer.setTo(termWidgetBounds.x, termWidgetBounds.y, prevBounds.left - termWidgetBounds.left, termWidgetBounds.height);
                    if (m_hitBoundsBuffer.containsPoint(m_localPointBuffer)) 
                    {
                        foundWidget = true;
                    }
                }
                else if (m_localPointBuffer.x > termWidgetBounds.left) 
                {
                    foundWidget = true;
                }
                
                if (foundWidget) 
                {
                    outParams.push(termWidget);
                    break;
                }
                i--;
            }
        }
        
        return foundWidget;
    }
    
    /**
     * Given the current mouse point (or dragged object if we want a different hit test), figure out what
     * entire expression chunk should be wrapped in parenthesis.
     * 
     * @param outParams
     *      First index is the term widget, Second index is the term area containing the widget
     * @return
     *      true if something was hit
     */
    private function getTermWidgetUnderPoint(globalPoint : Point, outParams : Array<Dynamic>) : Bool
    {
        // On release we need to check which chunk of the expression the drag paren is over
        // Add a new paren at that point
        // Check which term is underneath the dragged object, wrap parens around it
        var termWidgetUnderPoint : Bool = false;
        var termArea : TermAreaWidget = null;
        var i : Int = 0;
        for (i in 0...m_termAreas.length){
            termArea = m_termAreas[i];
            
            // TODO: Should not need to be directly over a card to work
            var widgetToAddParens : BaseTermWidget = termArea.pickWidgetUnderPoint(globalPoint.x, globalPoint.y, true);
            if (widgetToAddParens != null) 
            {
                termWidgetUnderPoint = true;
                outParams.push(widgetToAddParens);
                outParams.push(termArea);
                break;
            }
        }
        
        return termWidgetUnderPoint;
    }
    
    private function getWidgetsParenthesisCanMoveTo(widget : BaseTermWidget, termArea : TermAreaWidget, outWidgets : Array<BaseTermWidget>) : Void
    {
        if (widget != null) 
        {
            if (widget.getNode().isSpecificOperator(m_expressionCompiler.getVectorSpace().getDivisionOperator()) && termArea.layoutDivisionVertically) 
            {
                outWidgets.push(widget);
            }
            else if (widget.leftChildWidget == null && widget.rightChildWidget == null) 
            {
                outWidgets.push(widget);
            }
            else 
            {
                getWidgetsParenthesisCanMoveTo(widget.leftChildWidget, termArea, outWidgets);
                getWidgetsParenthesisCanMoveTo(widget.rightChildWidget, termArea, outWidgets);
            }
        }
    }
}
