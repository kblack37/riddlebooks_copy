package wordproblem.scripts.barmodel;

import wordproblem.scripts.barmodel.IRemoveBarElement;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;

import cgs.audio.Audio;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.math.util.MathUtil;
import dragonbox.common.time.Time;

import starling.animation.Transitions;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Sprite;
import starling.extensions.textureutil.TextureUtil;
import starling.text.TextField;
import starling.textures.Texture;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.view.BarLabelView;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.barmodel.view.BarWholeView;
import wordproblem.engine.component.BlinkComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;
import wordproblem.scripts.drag.WidgetDragSystem;

/**
 * The script enables the gesture where the player presses and holds down on an element
 * to trigger a copy.
 * 
 * This script will have hard coded dependencies on other scripts (remove and bar to card) since this
 * action will want to short circuit those while the press is happening but allow them
 * to run if the mouse is dragged enough off the hit target.
 */
class HoldToCopy extends BaseBarModelScript
{
    /**
     * A bit of a hack:
     * There are times where we want to preserve the behavior of the user dragging something to pickup a
     * copy of the element but only if a delete occurs (i.e. the level rule to allow copy is false but
     * deletion is still allowed)
     * 
     * True if the pick up + copy without delete should be allowed
     */
    public var allowCopy : Bool;
    
    private var m_globalBuffer : Point;
    private var m_localBuffer : Point;
    private var m_rectBuffer : Rectangle;
    
    private var m_time : Time;
    
    private var m_fillInProgress : Bool;
    private var m_transformInProgress : Bool;
    private var m_hitBarElement : DisplayObject;
    private var m_hitBarElementId : String;
    
    /**
     * This is the main container to paste the ring fill texture on top
     */
    private var m_canvas : DisplayObjectContainer;
    
    /**
     * The radial fill should be centered on the point of the mouse press.
     * Should be converted to the frame of reference of the canvas the fill image is added to.
     */
    private var m_originPoint : Point;
    
    /**
     * The number of millisecond the player needs to hold down the mouse
     * before the circle is completely filled
     */
    private var m_holdDurationMs : Float = 1000;
    
    private var m_timeMsElapsedSincePress : Float;
    
    /**
     * Rate of fill calculated from the hold duration
     */
    private var m_radiansPerMs : Float;
    
    /**
     * Have a textfield telling the player to hold down the mouse to copy
     * the pressed element. Used to provide better feedback to the player what
     * the ring being filled indicates.
     */
    private var m_holdToCopyDescription : DisplayObject;
    
    /**
     * Animation of the text bubble popping up
     */
    private var m_holdToCopyDescriptionTween : Tween;
    
    /**
     * The current image showing the fill progress
     * 
     * This has the dynamically created texture representing the fill.
     * (Make sure this is properly cleaned up whenever a new snapshot is drawn)
     */
    private var m_currentFillImage : Image;
    
    /**
     * This is a running counter of the amount of the image that should be filled
     */
    private var m_radiansToFill : Float;
    
    /**
     * When the progress ring is filled, want to play an animation to tell the player
     * that the hold to copy is complete.
     * 
     * In the timer code
     */
    private var m_hasStartedCompletionAnimation : Bool;
    
    private var m_innerRadius : Float = 16;
    private var m_outerRadius : Float = 32;
    private var m_fillBitmapData : BitmapData;
    
    private var m_outParams : Array<Dynamic>;
    
    /**
     * Need a reference to all of the remove bar element scripts as these are the
     * actions that need to manually get triggered if the user drag the bar
     * without the hold succeeding
     */
    private var m_removeScripts : Array<IRemoveBarElement>;
    
    /**
     * Need a reference to the bar to card because we want to force a transform on the 
     * completion of the hold
     */
    private var m_barToCard : BarToCard;
    
    /**
     * Keep track of the expression value of the bar element that was pressed, this is needed to
     * perform the transformation from that element to a draggable card.
     */
    private var m_hitExpressionValue : String;
    
    /**
     * The texture to use when the ring is filled and the copy successfully occured
     */
    private var m_completedRingTexture : Texture;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            time : Time,
            fillBitmapData : BitmapData,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        this.allowCopy = true;
        m_time = time;
        m_fillInProgress = false;
        m_globalBuffer = new Point();
        m_localBuffer = new Point();
        m_rectBuffer = new Rectangle();
        m_originPoint = new Point();
        m_outParams = new Array<Dynamic>();
        m_fillBitmapData = fillBitmapData;
        
        m_radiansPerMs = Math.PI * 2 / m_holdDurationMs;
        m_timeMsElapsedSincePress = 0.0;
        
        // Text indicator for hold to copy appears as a thought bubble
        var textWidth : Float = 150;
        var textHeight : Float = 40;
        var descriptionText : TextField = new TextField(Std.int(textWidth), Std.int(textHeight), "Hold to Copy", "Verdana", 20, 0x000000);
        var background : Image = new Image(m_assetManager.getTexture("thought_bubble"));
        background.scaleX = textWidth / background.width;
        background.scaleY = (textHeight * 2) / background.height;
        background.color = 0xFFFFFF;
        
        var descriptionContainer : Sprite = new Sprite();
        descriptionContainer.addChild(background);
        descriptionText.x = (background.width - descriptionText.width) * 0.5;
        descriptionText.y = (background.height - descriptionText.height) * 0.5;
        descriptionContainer.addChild(descriptionText);
        m_holdToCopyDescription = descriptionContainer;
        
        m_holdToCopyDescriptionTween = new Tween(m_holdToCopyDescription, 0.3);
        
        m_completedRingTexture = TextureUtil.getRingSegmentTexture(
                        m_innerRadius, m_outerRadius, -Math.PI / 2, Math.PI * 2, true, m_fillBitmapData, 0x00FF00, true, 1, 0
                        );
        
        m_removeScripts = new Array<IRemoveBarElement>();
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (!value && m_ready) 
        {
            // On set inactive, do a complete reset of all running state elements
            Starling.current.juggler.remove(m_holdToCopyDescriptionTween);
            
            if (m_holdToCopyDescription != null) 
            {
                m_holdToCopyDescription.removeFromParent();
            }
            
            if (m_currentFillImage != null) 
            {
                m_currentFillImage.removeFromParent(true);
                m_currentFillImage.texture.dispose();
                m_currentFillImage = null;
            }
            m_radiansToFill = 0.0;
            
            // Stop any blink animations
            if (m_hitBarElementId != null) 
            {
                m_barModelArea.componentManager.removeComponentFromEntity(m_hitBarElementId, BlinkComponent.TYPE_ID);
            }
            
            m_hitBarElement = null;
            m_hitBarElementId = null;
            m_fillInProgress = false;
        }
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        // Clear the texture
        m_completedRingTexture.dispose();
    }
    
    /**
     * Removal script involve tapping on an element which must be interupted in some cases.
     * A bit of a hack
     */
    public function addRemoveScript(removeScript : IRemoveBarElement) : Void
    {
        m_removeScripts.push(removeScript);
        
        // If already got the ready signal, call the ready signal to the just added script
        if (m_ready) 
        {
            (try cast(removeScript, BaseGameScript) catch(e:Dynamic) null).overrideLevelReady();
        }
    }
    
    override public function visit() : Int
    {
        if (m_ready && m_isActive) 
        {
            m_globalBuffer.x = m_mouseState.mousePositionThisFrame.x;
            m_globalBuffer.y = m_mouseState.mousePositionThisFrame.y;
            m_canvas.globalToLocal(m_globalBuffer, m_localBuffer);
            if (m_mouseState.leftMousePressedThisFrame) 
            {
				m_outParams = new Array<Dynamic>();
                m_originPoint.x = m_localBuffer.x;
                m_originPoint.y = m_localBuffer.y;
                if (BarModelHitAreaUtil.getBarElementUnderPoint(m_outParams, m_barModelArea, m_localBuffer, m_rectBuffer, false)) 
                {
                    var selectedObject : DisplayObject = try cast(m_outParams[0], DisplayObject) catch(e:Dynamic) null;
                    m_hitBarElement = selectedObject;
                    
                    // Press on a segment will initialize the fill
                    m_radiansToFill = 0.0;
                    
                    m_fillInProgress = true;
                    m_timeMsElapsedSincePress = 0.0;
                    
                    if (this.allowCopy) 
                    {
                        // Show the help text above the progress ring
                        // Want this to appear above all the widgets so add to a layer on top of most of the components
                        m_holdToCopyDescription.x = m_globalBuffer.x - m_holdToCopyDescription.width * 0.5;
                        m_holdToCopyDescription.y = m_globalBuffer.y - m_outerRadius - m_holdToCopyDescription.height;
                        if (m_gameEngine != null) 
                        {
                            (try cast(m_gameEngine.getUiEntity("middleLayer"), DisplayObjectContainer) catch(e:Dynamic) null).addChild(m_holdToCopyDescription);
                        }
                        
                        m_holdToCopyDescription.alpha = 0.0;
                        m_holdToCopyDescriptionTween.reset(m_holdToCopyDescription, 0.3);
                        m_holdToCopyDescriptionTween.animate("alpha", 1.0);
                        Starling.current.juggler.add(m_holdToCopyDescriptionTween);
                    }  
					
					// Add a blink to the element so it is clear what is being copied  
					// Remember need to pair it with a valid render component  
                    // Must iterate through every type of view 
                    var barWholeViews : Array<BarWholeView> = m_barModelArea.getBarWholeViews();
                    m_hitBarElementId = null;
                    for (barWholeView in barWholeViews)
                    {
                        var barSegmentViews : Array<BarSegmentView> = barWholeView.segmentViews;
                        for (barSegmentView in barSegmentViews)
                        {
                            if (barSegmentView == m_hitBarElement) 
                            {
                                m_hitBarElementId = barSegmentView.data.id;
                                break;
                            }
                        }
                        
                        var barLabelViews : Array<BarLabelView> = barWholeView.labelViews;
                        for (barLabelView in barLabelViews)
                        {
                            if (barLabelView == m_hitBarElement) 
                            {
                                m_hitBarElementId = barLabelView.data.id;
                                break;
                            }
                        }
                        
                        if (barWholeView.comparisonView != null && barWholeView.comparisonView == m_hitBarElement) 
                        {
                            m_hitBarElementId = barWholeView.comparisonView.data.id;
                        }
                        
                        if (m_hitBarElementId != null) 
                        {
                            break;
                        }
                    }
                    
                    if (m_hitBarElementId == null) 
                    {
                        var verticalLabelViews : Array<BarLabelView> = m_barModelArea.getVerticalBarLabelViews();
                        for (verticalLabelView in verticalLabelViews)
                        {
                            if (verticalLabelView == m_hitBarElement) 
                            {
                                m_hitBarElementId = verticalLabelView.data.id;
                                break;
                            }
                        }
                    }
                    
                    m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(m_hitBarElementId));
                    var renderComponent : RenderableComponent = new RenderableComponent(m_hitBarElementId);
                    renderComponent.view = m_hitBarElement;
                    m_barModelArea.componentManager.addComponentToEntity(renderComponent);
                    
                    Audio.instance.playSfx("card_flip");
                } 
				
				// Buffer what elements were hit in the transform script  
                // This data may need to be used later
                m_hitExpressionValue = m_barToCard.bufferHitElementsAtPoint(m_localBuffer, m_barModelArea, false);
            }
            else if (m_mouseState.leftMouseDraggedThisFrame && m_fillInProgress) 
            {
                // Check if the mouse has deviated far enough from the origin point to cancel the hold
                // Imagine a very small circle around the origin point
                // If the dragged point is outside this circle then cancel the hold
                if (!MathUtil.pointInCircle(m_originPoint, 5, m_localBuffer)) 
                {
                    stopFill();
                    
                    // A remove also starts a drag
                    // (HACK: for there is one tutorial where we don't want the remove to occur
                    // while hold to copy is active, thus dragging away should not hold onto a piece)
                    if (m_removeScripts.length > 0) 
                    {
                        m_barToCard.forceTransform(
                                m_globalBuffer.x,
                                m_globalBuffer.y,
                                m_hitExpressionValue,
                                try cast(this.getNodeById("WidgetDragSystem"), WidgetDragSystem) catch(e:Dynamic) null,
                                m_barModelArea
                                );
                    } 
					
					// Loop through all the remove scripts and check if the hit element can be deleted.  
                    for (removeScript in m_removeScripts)
                    {
                        if (removeScript.removeElement(m_hitBarElement)) 
                        {
                            break;
                        }
                    }
                }
            }
            else if (m_mouseState.leftMouseReleasedThisFrame) 
            {
                // HACK: Edge case where the player releases the mouse before the hold to copy
                // finished AND before the animation of the bar transforming into the card has finished
                // Interupt the animation and cancel the drag
                m_barToCard.cancelTransform();
                
                if (m_fillInProgress) 
                {
                    stopFill();
                    m_hasStartedCompletionAnimation = false;
                }
                
                if (m_transformInProgress) 
                {
                    m_barToCard.cancelTransform();
                    m_transformInProgress = false;
                } 
				
				// Stop the blink on the element to copy  
                if (m_hitBarElementId != null) 
                {
                    m_barModelArea.componentManager.removeComponentFromEntity(m_hitBarElementId, BlinkComponent.TYPE_ID);
                    m_hitBarElementId = null;
                } 
				
				// Stop the tween of the dialog box  
                Starling.current.juggler.remove(m_holdToCopyDescriptionTween);
            }
            
            if (m_mouseState.leftMouseDown && m_fillInProgress && this.allowCopy) 
            {
                var timeDelta : Float = m_time.currentDeltaMilliseconds;
                m_timeMsElapsedSincePress += timeDelta;
                
                // If enough time has elapsed without the hold being cancelled, we hand control
                // to the bar to card script to convert the hit element to a card.
                // (Need function to start drag given a particular element)
                var doFill : Bool = false;
                if (m_timeMsElapsedSincePress >= m_holdDurationMs) 
                {
                    // Perform one last fill so the whole circle looks complete
                    if (!m_hasStartedCompletionAnimation) 
                    {
                        m_radiansToFill = 2 * Math.PI;
                        m_hasStartedCompletionAnimation = true;
                    }
					
					// Stop the blink on the element to copy  
                    if (m_hitBarElementId != null) 
                    {
                        m_barModelArea.componentManager.removeComponentFromEntity(m_hitBarElementId, BlinkComponent.TYPE_ID);
                        m_hitBarElementId = null;
                    }  
					
					// Force transform and start dragging  
                    m_transformInProgress = true;
                    m_barToCard.forceTransform(
                            m_globalBuffer.x,
                            m_globalBuffer.y,
                            m_hitExpressionValue,
                            m_widgetDragSystem,
                            m_barModelArea,
                            onTransformComplete
                            );
                    
                    stopFill();
                    
                    // Play animation of a version of the filled image fading away to indicate the
                    // hold was completed
                    var completedImage : Image = new Image(m_completedRingTexture);
                    completedImage.pivotX = m_completedRingTexture.width * 0.5;
                    completedImage.pivotY = m_completedRingTexture.height * 0.5;
                    completedImage.x = m_originPoint.x;
                    completedImage.y = m_originPoint.y;
                    m_canvas.addChild(completedImage);
                    
                    var fadeoutCompletedTween : Tween = new Tween(completedImage, 0.5, Transitions.EASE_OUT);
                    fadeoutCompletedTween.fadeTo(0);
                    fadeoutCompletedTween.scaleTo(2.0);
                    fadeoutCompletedTween.onCompleteArgs = [completedImage];
                    fadeoutCompletedTween.onComplete = onFadeCompletedRingComplete;
                    Starling.current.juggler.add(fadeoutCompletedTween);
                    
                    Audio.instance.playSfx("text2card");
                }
                else 
                {
                    // Otherwise if the hold is still valid, then animate the ring filling up
                    // Figure out how much the fill changed
                    doFill = true;
                    m_radiansToFill += m_radiansPerMs * timeDelta;
                }
                
                if (doFill && this.allowCopy) 
                {
                    if (m_currentFillImage != null) 
                    {
                        m_currentFillImage.removeFromParent(true);
                        m_currentFillImage.texture.dispose();
                    } 
					
					// After every visit we need to update the fill of the radial bar  
                    var newFillTexture : Texture = TextureUtil.getRingSegmentTexture(
                            m_innerRadius, m_outerRadius, -Math.PI / 2, m_radiansToFill, true, m_fillBitmapData, 0, true, 1, 0
                            );
                    
                    m_currentFillImage = new Image(newFillTexture);
                    m_currentFillImage.pivotX = newFillTexture.width * 0.5;
                    m_currentFillImage.pivotY = newFillTexture.height * 0.5;
                    m_currentFillImage.x = m_originPoint.x;
                    m_currentFillImage.y = m_originPoint.y;
                    m_canvas.addChild(m_currentFillImage);
                }
            }
        }
        
        return ScriptStatus.FAIL;
    }
    
    /**
     * HACK: when this class is used outside of the level script, the level ready is not valid.
     * Need a way to initialize other parts of this class not set up by the set common params logic.
     * (Used for the tips section)
     */
    public function init(barToCard : BarToCard) : Void
    {
        m_canvas = m_barModelArea;
        
        for (removeScript in m_removeScripts)
        {
            (try cast(removeScript, BaseGameScript) catch(e:Dynamic) null).overrideLevelReady();
        }
        
        m_barToCard = barToCard;
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        init(new BarToCard(m_gameEngine, m_expressionCompiler, m_assetManager, true, "BarToCardModelMode"));
        m_barToCard.overrideLevelReady();
    }
    
    private function stopFill() : Void
    {
        m_fillInProgress = false;
        
        // Kill the fill image if it was playing
        if (m_currentFillImage != null) 
        {
            m_currentFillImage.removeFromParent(true);
            m_currentFillImage.texture.dispose();
        }
        
        m_holdToCopyDescription.removeFromParent();
    }
    
    private function onFadeCompletedRingComplete(target : Image) : Void
    {
        target.removeFromParent(true);
    }
    
    private function onTransformComplete() : Void
    {
        m_transformInProgress = false;
    }
}
