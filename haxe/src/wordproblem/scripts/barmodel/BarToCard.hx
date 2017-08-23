package wordproblem.scripts.barmodel;

import motion.Actuate;
import openfl.display.Bitmap;
import wordproblem.display.PivotSprite;
import wordproblem.scripts.barmodel.BaseBarModelScript;

import openfl.geom.Point;
import openfl.geom.Rectangle;

import cgs.audio.Audio;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import haxe.Constraints.Function;

import openfl.display.DisplayObject;

import wordproblem.display.Layer;
import wordproblem.engine.IGameEngine;
//import wordproblem.engine.barmodel.animation.BarModelToExpressionAnimation;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.view.BarComparisonView;
import wordproblem.engine.barmodel.view.BarLabelView;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.barmodel.view.BarWholeView;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.widget.BarModelAreaWidget;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.drag.WidgetDragSystem;

/**
 * Script that handles converting elements of the bar model area into single terms that the player moves around.
 * Used for both bar modeling and equation modeling.
 */
class BarToCard extends BaseBarModelScript
{
    /**
     * Storage for bounds for hit tests
     */
    private var m_boundsBuffer : Rectangle;
    
    /**
     * If true, then bar segment without a label attached are allowed to change into draggable blocks
     * that don't display a value. If false,
     */
    private var m_allowCustomDisplayCards : Bool;
    
    /**
     * If true then the target bar elements should transform into a regular card
     * Other wise it should maintain it's normal appearance
     * (Used internally and only when dragging bar segments to make duplicates of them)
     */
    private var m_doCreateCardForBarElements : Bool;
    
    /**
     * Keep track of the pieces of the bar model that were selected across multiple frames
     */
    private var m_barElementsToTransform : Array<DisplayObject>;
    
    /**
     * This is a copy of the bar views to transform. For a small amount of time this view
     * is visible and follows the mouse until a card appears
     */
    private var m_barElementCopy : PivotSprite;
    
    /**
     * Out parameters used for the hit test checks
     */
    private var m_outParamsBuffer : Array<Dynamic>;
    
    /**
     * The current expression value of the bar element that was pressed on.
     * If null, either nothing was last hit or the bar element cannot be represented by a single expression
     */
    private var m_termValueSelected : String;
    
    private var m_setBarColor : Bool;
    private var m_barColor : Int;
    
    /**
     * If not null, then a dragged bar segment has a label name that should be pasted on top of it
     */
    private var m_barLabelValueOnSegment : String;
    
    /**
     * In some tutorials we want to restrict the selection of pieces.
     * This is a list of bar model element ids that should not be selectable
     */
    private var m_idsToIgnore : Array<String>;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            allowCustomDisplayCards : Bool,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_allowCustomDisplayCards = allowCustomDisplayCards;
        m_barElementsToTransform = new Array<DisplayObject>();
        m_boundsBuffer = new Rectangle();
        m_outParamsBuffer = new Array<Dynamic>();
        m_doCreateCardForBarElements = true;
        m_idsToIgnore = new Array<String>();
    }
    
    public function getIdsToIgnore() : Array<String>
    {
        return m_idsToIgnore;
    }
    
    /**
     * Exposing this function so that the hold to copy can force a bar element to turn into a card
     * without going through the mouse gestures defined in the visit function.
     * 
     * REQUIRES bufferHitElementsAtPoint to be called beforehand
     * 
     * @param dragX
     *      Global x location to start
     * @param dragY
     *      Global y location to start
     * @param onTransformComplete
     */
    public function forceTransform(dragX : Float,
            dragY : Float,
            dragValue : String,
            widgetDragSystem : WidgetDragSystem,
            barModelArea : BarModelAreaWidget,
            onTransformComplete : Function = null) : Void
    {
        // Need to pivot on point on the bar model that the mouse is at
        // HACK: Other the removal scripts changes the transparency of the view, restore to original values
        for (barElementView in m_barElementsToTransform)
        {
            barElementView.alpha = 1.0;
        }
        
        //var selectedBarModelElementCopy : Image = BarModelToExpressionAnimation.convertBarModelViewsToSingleImage(
                //m_barElementsToTransform, barModelArea.stage, barModelArea.scaleFactor, m_boundsBuffer
        //);
		
		// TODO: this is empty due to the above class needing a redesign with the removal of Starling
		var selectedBarModelElementCopy : PivotSprite = new PivotSprite();
		
        // If the element should be converted into a card we play a tween where the element shrinks to nothing
        // otherwise we can start dragging the element without any extra tween
        if (m_doCreateCardForBarElements) 
        {
            var pivotX : Float = dragX - m_boundsBuffer.x;
            var pivotY : Float = dragY - m_boundsBuffer.y;
            selectedBarModelElementCopy.pivotX = pivotX;
            selectedBarModelElementCopy.pivotY = pivotY;
            selectedBarModelElementCopy.x = m_boundsBuffer.x + pivotX;
            selectedBarModelElementCopy.y = m_boundsBuffer.y + pivotY;
            
            m_barElementCopy = selectedBarModelElementCopy;
            barModelArea.stage.addChild(selectedBarModelElementCopy);
            
            // Start drag immediate BUT keep it hidden until the transform finishes
            // The dragged card need to start at the current position of the mouse
            // (make sure coordinates are relative to the canvas)
            widgetDragSystem.selectAndStartDrag(new ExpressionNode(m_expressionCompiler.getVectorSpace(), dragValue),
                    m_mouseState.mousePositionThisFrame.x,
                    m_mouseState.mousePositionThisFrame.y,
                    barModelArea, null);
			
            if (widgetDragSystem.getWidgetSelected() != null) 
            {
                widgetDragSystem.getWidgetSelected().alpha = 0.0;
            }
			
			// Tween to shrink copy to nothing  
			Actuate.tween(m_barElementCopy, 0.3, { scaleX: 0, scaleY: 0 }).onComplete(function() : Void
                {
                    // Make the dragged part visible after the transform is finished
                    if (widgetDragSystem.getWidgetSelected() != null) 
                    {
                        widgetDragSystem.getWidgetSelected().alpha = 1.0;
                    }
                    
                    clearBarElementCopy();
                    if (onTransformComplete != null) 
                    {
                        onTransformComplete();
                    }
                });
        }
        // Other wise the new dragged segment just appears as it did in the bar model
        else 
        {
            selectedBarModelElementCopy.pivotX = m_boundsBuffer.width * 0.5;
            selectedBarModelElementCopy.pivotY = m_boundsBuffer.height * 0.5;
            
            var extraDragParams : Dynamic = null;
            if (m_setBarColor) 
            {
                extraDragParams = {
                            color : m_barColor
                        };
            }
            
            if (m_barLabelValueOnSegment != null) 
            {
                extraDragParams = {
                            label : m_barLabelValueOnSegment
                        };
            }
            
            widgetDragSystem.selectAndStartDrag(new ExpressionNode(m_expressionCompiler.getVectorSpace(), dragValue),
                    m_mouseState.mousePositionThisFrame.x,
                    m_mouseState.mousePositionThisFrame.y,
                    barModelArea, extraDragParams, selectedBarModelElementCopy, onCustomDispose);
        }
    }
    
    /**
     * There is a small slice of time after forceTransform has been called where an animation to start the drag of
     * a bar element is playing. During this time the user can actually release the mouse to cancel the transform.
     * This function handles that edge case where the animation can be stopped
     */
    public function cancelTransform() : Void
    {
		if (m_barElementCopy != null) {
			Actuate.stop(m_barElementCopy);
			if (m_barElementCopy != null && m_barElementCopy.parent != null) m_barElementCopy.parent.removeChild(m_barElementCopy);
		}
    }
    
    /**
     * Another hack function needed for the hold to copy to work
     * 
     * @param prioritizeLabels
     *      If true, then labels appearing on top of the segment will be the expression value the card
     *      should have when dragged
     * @return
     *      The expression value to make a card from
     */
    public function bufferHitElementsAtPoint(barModelPoint : Point,
            barModelArea : BarModelAreaWidget,
            prioritizeLabels : Bool = true) : String
    {
        m_barLabelValueOnSegment = null;
        m_setBarColor = false;
		m_barElementsToTransform = new Array<DisplayObject>();
		m_outParamsBuffer = new Array<Dynamic>();
        
        var hitExpressionValue : String = null;
		var hitElement : Dynamic = { };
        if (BarModelHitAreaUtil.getBarElementUnderPoint(m_outParamsBuffer, barModelArea, barModelPoint, m_boundsBuffer, prioritizeLabels)) 
        {
            hitElement = m_outParamsBuffer[0];
            var hitElementIndex : Int = m_outParamsBuffer[1];
            var hitBarView : BarWholeView = try cast(m_outParamsBuffer[2], BarWholeView) catch(e:Dynamic) null;
            
            // Save the view that was hit
            m_barElementsToTransform.push(hitElement);
            
            m_doCreateCardForBarElements = true;
            
            // Need to figure out what term value each particular type of hit
            // object should convert to
			var barLabelView : BarLabelView = null;
            if (hitBarView != null) 
            {
                if (Std.is(hitElement, BarSegmentView)) 
                {
                    // The easy way is to just get the segment value directly and transform it back into a term value
                    var barSegmentView : BarSegmentView = try cast(hitElement, BarSegmentView) catch(e:Dynamic) null;
                    
                    // Segments are the trickiest case potentially as the card value is really governed by values assigned to it
                    // If a segment has a no-bracket label it takes the value of that label
                    // Look through all labels and fetch ones that lie exactly on top
                    var barLabelViews : Array<BarLabelView> = hitBarView.labelViews;
                    var i : Int = 0;
                    var numBarLabelViews : Int = barLabelViews.length;
                    var segmentMatchedSingleLabel : Bool = false;
                    for (i in 0...numBarLabelViews){
                        barLabelView = barLabelViews[i];
                        if (barLabelView.data.endSegmentIndex == hitElementIndex &&
                            barLabelView.data.startSegmentIndex == hitElementIndex &&
                            barLabelView.data.bracketStyle == BarLabel.BRACKET_NONE) 
                        {
                            m_barLabelValueOnSegment = barLabelView.data.value;
                            segmentMatchedSingleLabel = true;
                            hitExpressionValue = barLabelView.data.value;
                            
                            // If label lies on top, save that it was hit as well
                            m_barElementsToTransform.push(barLabelView);
                        }
                    }
                    
                    if (m_allowCustomDisplayCards && !segmentMatchedSingleLabel) 
                    {
                        var segmentTermValue : Float = barSegmentView.data.numeratorValue * barModelArea.normalizingFactor / barSegmentView.data.denominatorValue;
                        hitExpressionValue = segmentTermValue + "";
                        m_doCreateCardForBarElements = false;
                        
                        m_setBarColor = true;
                        m_barColor = barSegmentView.data.color;
                    }
                    else if (segmentMatchedSingleLabel) 
                    {
                        m_doCreateCardForBarElements = true;
                    }
                    else 
                    {
                        // A segment without a label on top was dragged, in equation building mode we want this
                        // to convert to a number. That number should be equal to the number of segment in the
                        // row with the same segment value as the one that was dragged.
                        var numSegmentsWithTheSameValue : Int = 0;
                        var segmentValueOfHitPart : Float = barSegmentView.data.getValue();
                        for (segmentViewInBar in hitBarView.segmentViews)
                        {
                            if (segmentViewInBar.data.getValue() == segmentValueOfHitPart) 
                            {
                                numSegmentsWithTheSameValue++;
                                m_barElementsToTransform.push(segmentViewInBar);
                            }
                        }
                        
                        if (numSegmentsWithTheSameValue > 1) 
                        {
                            hitExpressionValue = Std.string(numSegmentsWithTheSameValue);
                        }
                        else 
                        {
                            // Act like a display was never hit if not allowed to create custom cards and hit a segment
                            hitExpressionValue = null;
							m_barElementsToTransform = new Array<DisplayObject>();
                        }
                    }
                }
                else if (Std.is(hitElement, BarLabelView)) 
                {
                    barLabelView = try cast(hitElement, BarLabelView) catch(e:Dynamic) null;
                    hitExpressionValue = barLabelView.data.value;
                }
                else if (Std.is(hitElement, BarComparisonView)) 
                {
                    var barComparisonView : BarComparisonView = try cast(hitElement, BarComparisonView) catch(e:Dynamic) null;
                    hitExpressionValue = barComparisonView.data.value;
                }
            }
            else 
            {
                if (Std.is(hitElement, BarLabelView)) 
                {
                    barLabelView = try cast(hitElement, BarLabelView) catch(e:Dynamic) null;
                    hitExpressionValue = barLabelView.data.value;
                }
            }
        }
        
        if (m_idsToIgnore.length > 0) 
        {
            var idOfHitElement : String = null;
            if (Std.is(hitElement, BarSegmentView)) 
            {
                idOfHitElement = (try cast(hitElement, BarSegmentView) catch(e:Dynamic) null).data.id;
            }
            else if (Std.is(hitElement, BarLabelView)) 
            {
                idOfHitElement = (try cast(hitElement, BarLabelView) catch(e:Dynamic) null).data.id;
            }
            // Ignore this hit if the target element was specified in the ignore list
            else if (Std.is(hitElement, BarComparisonView)) 
            {
                idOfHitElement = (try cast(hitElement, BarComparisonView) catch(e:Dynamic) null).data.id;
            }
            
            if (idOfHitElement != null && Lambda.indexOf(m_idsToIgnore, idOfHitElement) > -1) 
            {
                hitExpressionValue = null;
            }
        }
        
        return hitExpressionValue;
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.FAIL;
        
        if (m_ready && m_isActive && !Layer.getDisplayObjectIsInInactiveLayer(m_barModelArea)) 
        {
            m_globalMouseBuffer.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
            m_localMouseBuffer = m_barModelArea.globalToLocal(m_globalMouseBuffer);
            if (m_mouseState.leftMousePressedThisFrame) 
            {
                m_termValueSelected = bufferHitElementsAtPoint(m_localMouseBuffer, m_barModelArea, false);
            }
            // On release clear the buffers.
            // If a tween is not finished then stop it immediately and dispose the bar element copy textures
            else if (m_mouseState.leftMouseDraggedThisFrame && m_termValueSelected != null) 
            {
                if (m_barElementCopy != null) 
                {
                    m_barElementCopy.x = m_globalMouseBuffer.x;
                    m_barElementCopy.y = m_globalMouseBuffer.y;
                }  
				
				// We only want to create the dragged copy once while dragging.  
                // In the case of a bar segment there is no tween so the drag system will immediately detect the drag.
                if (m_barElementCopy == null && m_widgetDragSystem.getWidgetSelected() == null) 
                {
                    Audio.instance.playSfx("bar2card");
                    forceTransform(m_globalMouseBuffer.x, m_globalMouseBuffer.y, m_termValueSelected, m_widgetDragSystem, m_barModelArea);
                }
            }
            
            if (m_mouseState.leftMouseReleasedThisFrame) 
            {
				clearBarElementCopy();
				m_barElementsToTransform = new Array<DisplayObject>();
                m_termValueSelected = null;
            }
        }
        
        return status;
    }
    
    private function clearBarElementCopy() : Void
    {
		Actuate.stop(m_barElementCopy);
		
		if (m_barElementCopy != null && m_barElementCopy.parent != null) {
			m_barElementCopy.parent.removeChild(m_barElementCopy);
			// The dragged copy can be destroyed along with the custom texture
			m_barElementCopy.dispose();
			m_barElementCopy = null;
		}
        m_termValueSelected = null;
    }
    
    private function onCustomDispose(customDisplay : DisplayObject) : Void
    {
        if (Std.is(customDisplay, Bitmap)) 
        {
            (try cast(customDisplay, Bitmap) catch(e:Dynamic) null).bitmapData.dispose();
        }
    }
}
