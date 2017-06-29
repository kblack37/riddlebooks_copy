package wordproblem.scripts.barmodel;

import wordproblem.scripts.barmodel.ICardOnSegmentScript;
import wordproblem.scripts.barmodel.RadialMenuControl;

import flash.geom.Rectangle;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.ui.MouseState;

import feathers.display.Scale9Image;
import feathers.textures.Scale9Textures;

import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Sprite;
import starling.extensions.textureutil.TextureUtil;
import starling.filters.ColorMatrixFilter;
import starling.text.TextField;
import starling.textures.Texture;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.component.BlinkComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.SymbolData;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.expression.widget.term.SymbolTermWidget;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;

/**
 * This script controls showing all the valid gestures possible when the user drops a card on top of a bar
 * segment. These options are shown in a radial menu if enough gestures are possible.
 * This is to allow for multiple action types with a single gesture.
 */
class CardOnSegmentRadialOptions extends BaseBarModelScript
{
    /**
     * These are the possible actions in a level when a card is dropped
     */
    private var m_gestures : Array<ICardOnSegmentScript>;
    
    /**
     * On every end drag we keep track of what gestures in the candidate list have
     * been marked as valid. Each element here should match with the element in the
     * gesture list.
     * 
     * True means the gesture at the same index can be performed
     */
    private var m_isGestureValid : Array<Bool>;
    
    private var m_outParamsBuffer : Array<Dynamic>;
    
    /**
     * This controls all the logic to get a radial menu to be drawn and to figure
     * out which segment was selected.
     */
    private var m_radialMenuControl : RadialMenuControl;
    
    private var m_savedDraggedValue : String;
    private var m_savedSelectedSegmentId : String;
    
    private var m_hoveredSegmentIdOnLastFrame : String;
    
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
    private var m_gesturePreviewWithoutMenu : ICardOnSegmentScript;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_outParamsBuffer = new Array<Dynamic>();
        m_gestures = new Array<ICardOnSegmentScript>();
        m_isGestureValid = new Array<Bool>();
        m_gestureIcons = new Array<DisplayObject>();
        m_gestureHoverOverName = new Array<String>();
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.FAIL;
        if (m_ready) 
        {
            var mouseState : MouseState = m_gameEngine.getMouseState();
            m_globalMouseBuffer.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
            m_barModelArea.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
            
            iterateThroughBufferedEvents();
            
            // While dragging, check if the mouse is over a segment and at least on of the gestures
            // is executable.
            // We should blink the segment to tell the player something can happen
            if ((mouseState.leftMouseDraggedThisFrame || mouseState.leftMouseDown) && Std.is(m_widgetDragSystem.getWidgetSelected(), SymbolTermWidget)) 
            {
                as3hx.Compat.setArrayLength(m_outParamsBuffer, 0);
                if (BarModelHitAreaUtil.checkPointInBarSegment(m_outParamsBuffer, m_barModelArea, m_localMouseBuffer)) 
                {
                    var value : String = m_widgetDragSystem.getWidgetSelected().getNode().data;
                    var targetBarWhole : BarWhole = m_barModelArea.getBarWholeViews()[Std.parseInt(m_outParamsBuffer[0])].data;
                    var targetBarSegmentIndex : Int = Std.parseInt(m_outParamsBuffer[1]);
                    var segmentId : String = targetBarWhole.barSegments[targetBarSegmentIndex].id;
                    
                    // For the radial menu to pop up, the number of possible actions that can execute with the given
                    // segment and dragged expression need to pass some threshold
                    // This indicates there is ambiguity in the gesture that the user needs to explicitly resolve.
                    var i : Int;
                    var numGestures : Int = m_gestures.length;
                    var numValidGestures : Int = 0;
                    var lastValidGestureIndex : Int = -1;
                    for (i in 0...numGestures){
                        var gestureScript : ICardOnSegmentScript = m_gestures[i];
                        m_isGestureValid[i] = gestureScript.canPerformAction(value, segmentId);
                        if (m_isGestureValid[i]) 
                        {
                            numValidGestures++;
                            lastValidGestureIndex = i;
                        }
                    }  // Remove old blink if the segment changed from last time  
                    
                    
                    
                    if (segmentId != m_hoveredSegmentIdOnLastFrame && m_hoveredSegmentIdOnLastFrame != null) 
                    {
                        m_barModelArea.componentManager.removeComponentFromEntity(m_hoveredSegmentIdOnLastFrame, BlinkComponent.TYPE_ID);
                        
                        if (m_gesturePreviewWithoutMenu != null) 
                        {
                            super.setDraggedWidgetVisible(true);
                            m_gesturePreviewWithoutMenu.hidePreview();
                        }
                    }
                    
                    if (numValidGestures > 0) 
                    {
                        // Remember the bar segment hovered on this frame so we can remove it if needed on
                        // later frames.
                        if (segmentId != m_hoveredSegmentIdOnLastFrame) 
                        {
                            // Add blink to the target segment box
                            // (requires pairing with valid render component)
                            m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(segmentId));
                            var renderComponent : RenderableComponent = new RenderableComponent(segmentId);
                            renderComponent.view = m_barModelArea.getBarSegmentViewById(segmentId);
                            m_barModelArea.componentManager.addComponentToEntity(renderComponent);
                            
                            m_hoveredSegmentIdOnLastFrame = segmentId;
                            
                            // If only one gesture is valid on the current segment, apply the preview of that gesture
                            if (numValidGestures == 1) 
                            {
                                gestureScript = m_gestures[lastValidGestureIndex];
                                gestureScript.showPreview(value, segmentId);
                                m_gesturePreviewWithoutMenu = gestureScript;
                                setDraggedWidgetVisible(false);
                                status = ScriptStatus.SUCCESS;
                            }
                        }
                    }
                }
                // Dragged card no longer over any segment
                else if (m_hoveredSegmentIdOnLastFrame != null) 
                {
                    clearAllPreviews();
                }
            }
            // Nothing is being dragged
            // If the radial menu has been opened, update it on every frame to get the proper mouse over state
            else if (m_hoveredSegmentIdOnLastFrame != null) 
            {
                clearAllPreviews();
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
        
        return status;
    }
    
    private function clearAllPreviews() : Void
    {
        m_barModelArea.componentManager.removeComponentFromEntity(m_hoveredSegmentIdOnLastFrame, BlinkComponent.TYPE_ID);
        m_hoveredSegmentIdOnLastFrame = null;
        
        if (m_gesturePreviewWithoutMenu != null) 
        {
            super.setDraggedWidgetVisible(true);
            m_gesturePreviewWithoutMenu.hidePreview();
            m_gesturePreviewWithoutMenu = null;
        }
    }
    
    public function addGesture(gestureScript : ICardOnSegmentScript) : Void
    {
        if (m_ready) 
        {
            // HACK: Doesn't fire at the right time
            // Override needs to be called after the nodes are added to the graph since some of the ready function trace up the
            // parent pointers to find other script nodes.
            (try cast(gestureScript, BaseGameScript) catch(e:Dynamic) null).overrideLevelReady();
        }
        
        m_gestures.push(gestureScript);
        m_isGestureValid.push(false);
    }
    
    public function getGestureScript(name : String) : ICardOnSegmentScript
    {
        var matchingGestureScript : ICardOnSegmentScript;
        for (gestureScript in m_gestures)
        {
            if (gestureScript.getName() == name) 
            {
                matchingGestureScript = gestureScript;
                break;
            }
        }
        
        return matchingGestureScript;
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        // Set up controls for the radial menu
        m_radialMenuControl = new RadialMenuControl(
                m_gameEngine.getMouseState(), 
                mouseOverRadialOption, 
                mouseOutRadialOption, 
                clickRadialOption, 
                drawMenuSegment, 
                disposeMenuSegment, 
                );
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.END_DRAG_TERM_WIDGET) 
        {
            // If a dragged card was dropped first check that the drop point is over a bar
            var droppedObject : BaseTermWidget = param.widget;
            as3hx.Compat.setArrayLength(m_outParamsBuffer, 0);
            if (Std.is(droppedObject, SymbolTermWidget) && BarModelHitAreaUtil.checkPointInBarSegment(m_outParamsBuffer, m_barModelArea, m_localMouseBuffer)) 
            {
                var value : String = droppedObject.getNode().data;
                var targetBarWhole : BarWhole = m_barModelArea.getBarWholeViews()[Std.parseInt(m_outParamsBuffer[0])].data;
                var targetBarSegmentIndex : Int = Std.parseInt(m_outParamsBuffer[1]);
                var segmentId : String = targetBarWhole.barSegments[targetBarSegmentIndex].id;
                
                // For the radial menu to pop up, the number of possible actions that can execute with the given
                // segment and dragged expression need to pass some threshold
                // This indicates there is ambiguity in the gesture that the user needs to explicitly resolve.
                var i : Int;
                var numGestures : Int = m_gestures.length;
                var numValidGestures : Int = 0;
                for (i in 0...numGestures){
                    var gestureScript : ICardOnSegmentScript = m_gestures[i];
                    m_isGestureValid[i] = gestureScript.canPerformAction(value, segmentId);
                    if (m_isGestureValid[i]) 
                    {
                        numValidGestures++;
                    }
                }  // Open the radial menu only if there are enough gestures  
                
                
                
                if (numValidGestures > 0) 
                {
                    // Special case, if there is only one valid gesture then just execute that gesture directly
                    if (numValidGestures == 1) 
                    {
                        for (i in 0...numGestures){
                            if (m_isGestureValid[i]) 
                            {
                                m_gestures[i].performAction(value, segmentId);
                                break;
                            }
                        }
                    }
                    else 
                    {
                        m_savedDraggedValue = value;
                        m_savedSelectedSegmentId = segmentId;
                        
                        // Draw the radial menu with the above options
                        var gestureEnabledList : Array<Bool> = m_isGestureValid.copy();
                        
                        // The radial menu should appear just above the hit segment view
                        // It should not obscure it, since mousing over options applies a preview
                        // on the action on the bar
                        var hitView : DisplayObject = m_barModelArea.getBarSegmentViewById(segmentId);
                        var hitViewBounds : Rectangle = hitView.getBounds(m_barModelArea.stage);
                        
                        // Create hover over names
                        
                        // Unlike previous iterations, we do not have a cancel option
                        m_radialMenuControl.open(gestureEnabledList,
                                hitViewBounds.left + hitViewBounds.width * 0.5,
                                hitViewBounds.top - 60,
                                m_gameEngine.getSprite()
                                );
                        
                        // Put the dragged card in the middle
                        var termWidget : BaseTermWidget = new SymbolTermWidget(
                        new ExpressionNode(m_expressionCompiler.getVectorSpace(), value), 
                        m_gameEngine.getExpressionSymbolResources(), 
                        m_assetManager, 
                        );
                        var centerSpaceDiameter : Float = 60;
                        var targetScaleY : Float = centerSpaceDiameter / termWidget.height;
                        var targetScaleX : Float = centerSpaceDiameter / termWidget.width;
                        termWidget.scaleX = termWidget.scaleY = Math.min(targetScaleX, targetScaleY);
                        m_radialMenuControl.getRadialMenuContainer().addChildAt(termWidget, 0);
                        
                        m_gameEngine.dispatchEventWith(GameEvent.OPEN_RADIAL_OPTIONS, false, {
                                    display : m_radialMenuControl.getRadialMenuContainer()

                                });
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
        var icon : DisplayObject = getIconAtSegmentIndex(optionIndex);
        icon.pivotX = icon.width * 0.5;
        icon.pivotY = icon.height * 0.5;
        icon.scaleX = icon.scaleY = (radiusDelta - 8) / Math.max(icon.width, icon.height);
        icon.x = Math.cos(rotation + arcLength * 0.5) * (outerRadius - radiusDelta * 0.5);
        icon.y = Math.sin(rotation + arcLength * 0.5) * (outerRadius - radiusDelta * 0.5);
        
        var outerTexture : Texture;
        var outlineThickness : Float = 2;
        if (mode == "up") 
        {
            outerTexture = TextureUtil.getRingSegmentTexture(30, outerRadius, 0, arcLength, true, null, 0x6AA2C8, true, outlineThickness, 0x000000);
        }
        else if (mode == "over") 
        {
            outerTexture = TextureUtil.getRingSegmentTexture(30, outerRadius, 0, arcLength, true, null, 0xF7A028, true, outlineThickness, 0x000000);
        }
        else 
        {
            outerTexture = TextureUtil.getRingSegmentTexture(30, outerRadius, 0, arcLength, true, null, 0xCCCCCC, true, outlineThickness, 0x000000);
            
            // Set icon to grey scale
            var colorMatrixFilter : ColorMatrixFilter = new ColorMatrixFilter();
            colorMatrixFilter.adjustSaturation(-1);
            icon.filter = colorMatrixFilter;
        }
        
        var segmentImage : Image = new Image(outerTexture);
        segmentImage.pivotX = segmentImage.pivotY = outerRadius;
        segmentImage.rotation = rotation;
        
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
        var ringImage : Image = try cast((try cast(segment, DisplayObjectContainer) catch(e:Dynamic) null).getChildAt(0), Image) catch(e:Dynamic) null;
        ringImage.texture.dispose();
        
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
        
        var gestureScript : ICardOnSegmentScript = null;
        if (index < m_gestures.length) 
        {
            gestureScript = m_gestures[index];
        }  // name value pasted on top (just make the bar the  same color    // The first gesture is adding name on top, this can just be a tiny version of the bar with the  
        
        
        
        
        
        if (Std.is(gestureScript, AddNewLabelOnSegment)) 
        {
            var symbolData : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_savedDraggedValue);
            
            var barBackgroundTexture : Texture = m_assetManager.getTexture("card_background_square");
            var scale9Offset : Float = 8;
            var barBackground : Scale9Image = new Scale9Image(new Scale9Textures(
            barBackgroundTexture, 
            new Rectangle(scale9Offset, scale9Offset, barBackgroundTexture.width - 2 * scale9Offset, barBackgroundTexture.height - 2 * scale9Offset)), 
            );
            barBackground.color = ((symbolData.useCustomBarColor)) ? symbolData.customBarColor : 0xFFFFFF;
            
            var nameOnBar : String = symbolData.name;
            if (nameOnBar == null) 
            {
                nameOnBar = m_savedDraggedValue;
            }
            var nameTextfield : TextField = new TextField(barBackground.width, barBackground.height, nameOnBar, symbolData.fontName, 12, symbolData.fontColor);
            var nameIconContainer : Sprite = new Sprite();
            nameIconContainer.addChild(barBackground);
            nameIconContainer.addChild(nameTextfield);
            icon = nameIconContainer;
        }
        else if (Std.is(gestureScript, SplitBarSegment)) 
        {
            var divideIcon : Image = new Image(m_assetManager.getTexture("divide_obelus"));
            icon = divideIcon;
        }
        
        return icon;
    }
    
    private function mouseOutRadialOption(optionIndex : Int) : Void
    {
        // Delete any preview that the option triggered
        if (optionIndex >= 0 && optionIndex < m_gestures.length) 
        {
            var gestureOver : ICardOnSegmentScript = m_gestures[optionIndex];
            gestureOver.hidePreview();
        }
    }
    
    private function mouseOverRadialOption(optionIndex : Int) : Void
    {
        // Show a new preview related to the given option
        if (optionIndex >= 0 && optionIndex < m_gestures.length) 
        {
            var gestureOver : ICardOnSegmentScript = m_gestures[optionIndex];
            gestureOver.showPreview(m_savedDraggedValue, m_savedSelectedSegmentId);
        }
    }
    
    private function clickRadialOption(optionIndex : Int) : Void
    {
        // Map the index to a selected option
        if (optionIndex >= 0 && optionIndex < m_gestures.length && m_isGestureValid[optionIndex]) 
        {
            var gestureToExecute : ICardOnSegmentScript = m_gestures[optionIndex];
            gestureToExecute.performAction(m_savedDraggedValue, m_savedSelectedSegmentId);
        }  // Close the menu on click  
        
        
        
        m_radialMenuControl.close();
        
        // On close, discard the blink
        m_barModelArea.componentManager.removeComponentFromEntity(m_savedSelectedSegmentId, BlinkComponent.TYPE_ID);
        
        m_gameEngine.dispatchEventWith(GameEvent.CLOSE_RADIAL_OPTIONS);
    }
}
