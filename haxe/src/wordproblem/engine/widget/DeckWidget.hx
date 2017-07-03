package wordproblem.engine.widget;

import wordproblem.engine.widget.IBaseWidget;
import wordproblem.engine.widget.ScrollGridWidget;

import flash.geom.Point;

import dragonbox.common.dispose.IDisposable;

import feathers.controls.Button;

import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.events.Event;
import starling.textures.Texture;

import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.component.RigidBodyComponent;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.expression.widget.term.SymbolTermWidget;
import wordproblem.resource.AssetManager;

/**
	 * This is a tool box type widget that is restricted to dragging and flipping cards
 * only representing expressions.
	 * 
	 * Given a set of symbols, it will create a deck of cards that can be picked up
	 * and dragged. Usually it should just not be making changes to the component manager,
 * it simply reads in the data that was modified by some of the systems.
	 */
class DeckWidget extends ScrollGridWidget implements IDisposable implements IBaseWidget
{
    public var componentManager(get, never) : ComponentManager;

    /**
     * Fired whenever bounds of this area has finished refreshing
     */
    public static inline var EVENT_REFRESH : String = "refresh";
    
    /**
     * We treat each object in the deck as a different entity.
     * 
     * Each deck really refers to a expression subtree, each expression may or may not
     * be rendered as a single card
     */
    private var m_componentManager : ComponentManager;
    
    /**
     * Button to scroll the left side
     */
    private var m_leftScrollButton : Button;
    private var m_rightScrollButton : Button;
    
    private var m_background : DisplayObject;
    
    // Keep a buffered queue of requests to set the deck to a new value
    // If the deck is still trying to transform itself while a new request is made
    // we queue the request and wait for the current animation to finish
    // We really only care about the most recent set of items as far as animation
    // but everything in the queue is needed to correctly apply all necessary add/remove
    // from the widget
    private var m_entitiesToAddQueue : Array<Array<DisplayObject>>;
    private var m_entitiesToRemoveQueue : Array<Array<DisplayObject>>;
    
    /**
     * We need to keep track whether or not animations are still playing. Animations
     * affect the changing of the deck layout, so we need to make sure it gets completed
     * before triggering a new set.
     * 
     * Also used to prevent further clicks on a card will it is playing its turn animation
     */
    private var m_animationPlaying : Bool;
    
    private var m_scrollButtonWidth : Float = 0;
    
    public function new(assetManager : AssetManager,
            backgroundImage : DisplayObject,
            maxColumns : Int = -1,
            gap : Float = 18)
    {
        super(gap, false, null, null, true);
        
        m_componentManager = new ComponentManager();
        
        // Adding background for the deck
        if (backgroundImage != null) 
        {
            m_background = backgroundImage;
            addChildAt(backgroundImage, 0);
        }
        
        m_entitiesToAddQueue = new Array<Array<DisplayObject>>();
        m_entitiesToRemoveQueue = new Array<Array<DisplayObject>>();
        
        var arrowTexture : Texture = assetManager.getTexture("arrow_short");
        var arrowScale : Float = 1.0;
        m_scrollButtonWidth = arrowTexture.width * arrowScale;
        var leftUpArrow : Image = WidgetUtil.createPointingArrow(arrowTexture, true, arrowScale, 0xFFFFFF);
        m_leftScrollButton = WidgetUtil.createButtonFromImages(leftUpArrow, null, null, null, null, null);
        m_leftScrollButton.scaleWhenHovering = m_leftScrollButton.scaleX * 1.1;
        m_leftScrollButton.scaleWhenDown = m_leftScrollButton.scaleX * 0.9;
        m_leftScrollButton.addEventListener(Event.TRIGGERED, onLeftScrollClick);
        
        var rightUpArrow : Image = WidgetUtil.createPointingArrow(arrowTexture, false, arrowScale, 0xFFFFFF);
        m_rightScrollButton = WidgetUtil.createButtonFromImages(rightUpArrow, null, null, null, null, null);
        m_rightScrollButton.scaleWhenHovering = m_leftScrollButton.scaleWhenHovering;
        m_rightScrollButton.scaleWhenDown = m_leftScrollButton.scaleWhenDown;
        m_rightScrollButton.addEventListener(Event.TRIGGERED, onRightScrollClick);
    }
    
    private function get_componentManager() : ComponentManager
    {
        return m_componentManager;
    }
    
    public function setDimensions(maxWidth : Float, maxHeight : Float) : Void
    {
        if (m_background != null) 
        {
            m_background.scaleX = maxWidth / m_background.width;
            m_background.scaleY = maxHeight / m_background.height;
        }
        
        m_leftScrollButton.x = 0;
        m_rightScrollButton.x = maxWidth - m_scrollButtonWidth;
        
        // View port shrinks slightly to accomadate possible scroll buttons
        maxWidth -= (m_scrollButtonWidth * 2);
        super.setViewport(m_scrollButtonWidth, 0, maxWidth, maxHeight);
    }
    
    /**
     * Swap the ordering of cards as they were laid out in the deck.
     */
    public function switchOrder(widgetA : BaseTermWidget,
            widgetB : BaseTermWidget) : Void
    {
        var renderComponentList : Array<DisplayObject> = super.getObjects();
        var indexA : Int;
        var indexB : Int;
        var i : Int;
        var widget : BaseTermWidget;
        for (renderComponentList.length){
            widget = try cast(renderComponentList[i], BaseTermWidget) catch(e:Dynamic) null;
            if (widget == widgetA) 
            {
                indexA = i;
            }
            else if (widget == widgetB) 
            {
                indexB = i;
            }
        }
        
        var renderComponentA : DisplayObject = renderComponentList[indexA];
        var renderComponentB : DisplayObject = renderComponentList[indexB];
        renderComponentList[indexA] = renderComponentB;
        renderComponentList[indexB] = renderComponentA;
        super.layoutObjects();
    }
    
    private var componentsToAddBuffer : Array<DisplayObject> = new Array<DisplayObject>();
    private var componentsToRemoveBuffer : Array<DisplayObject> = new Array<DisplayObject>();
    public function batchAddRemoveExpressions(entitiesToAdd : Array<DisplayObject>, entitiesToRemove : Array<DisplayObject>) : Void
    {
        // If an animation of the cards fading in/out is still player we push these requests to
        // the queue and run them later after the animations have completed.
        if (m_animationPlaying) 
        {
            m_entitiesToAddQueue.push(entitiesToAdd);
            m_entitiesToRemoveQueue.push(entitiesToRemove);
            return;
        }
        
        var i : Int;
        var numEntitiesToAdd : Int = entitiesToAdd.length;
        as3hx.Compat.setArrayLength(componentsToAddBuffer, 0);
        for (i in 0...numEntitiesToAdd){
            componentsToAddBuffer.push(entitiesToAdd[i]);
        }  // We assume the disposal of a render component does not automatically remove it from the display list    // to fetch the render components from the scroll widget.    // Since at this point the components have already been removed we have no choice but  
        
        
        
        
        
        
        
        var existingObjects : Array<DisplayObject> = super.getObjects();
        var numExistingObjects : Int = existingObjects.length;
        var numEntitiesToRemove : Int = entitiesToRemove.length;
        as3hx.Compat.setArrayLength(componentsToRemoveBuffer, 0);
        for (i in 0...numEntitiesToRemove){
            var viewToRemove : DisplayObject = entitiesToRemove[i];
            
            // Get the render component currently in the scrolling grid that matches the
            // entity id to remove.
            var j : Int;
            var existingObject : DisplayObject;
            for (j in 0...numExistingObjects){
                existingObject = existingObjects[j];
                if (existingObject == viewToRemove) 
                {
                    componentsToRemoveBuffer.push(existingObject);
                    break;
                }
            }
        }  // of new and current objects    // beforehand. We can do whatever we want with them since after the call they should have no effect on the layout    // Since the batch add/remove call immediately removes objects from the display list we need to animate cards disappearing  
        
        
        
        
        
        
        
        if (componentsToRemoveBuffer.length > 0) 
        {
            var animationsToPlay : Int = numEntitiesToRemove;
            var duration : Float = 0.25;
            for (i in 0...numEntitiesToRemove){
                existingObject = componentsToRemoveBuffer[i];
                var tween : Tween = new Tween(existingObject, duration);
                tween.scaleTo(0);
                tween.onComplete = function() : Void
                        {
                            animationsToPlay--;
                            if (animationsToPlay == 0) 
                            {
                                onRemoveTweensComplete();
                            }
                        };
                Starling.juggler.add(tween);
                m_animationPlaying = true;
            }
        }
        else 
        {
            onRemoveTweensComplete();
        }
        
        function onRemoveTweensComplete() : Void
        {
            batchAddRemove(componentsToAddBuffer, componentsToRemoveBuffer, false);
            
            // Call the layout animation of this widget, this fades in the new cards as well
            // as shift over the previous ones.
            layout();
        };
    }
    
    /**
     * Look at the current deck components and run the layout algorithm on them, it will
     * attempt to smoothly animate objects from their previous coordinates to their new ones.
     */
    public function layout() : Void
    {
        // Go through all objects and cache their previous positions
        // If they are not part of the display list then we presume they are new objects
        // that had never been laid out before.
        var previousCoordinates : Array<Point> = new Array<Point>();
        var renderComponents : Array<DisplayObject> = super.getObjects();
        var numComponents : Int = renderComponents.length;
        var i : Int;
        var renderView : DisplayObject;
        for (i in 0...numComponents){
            renderView = renderComponents[i];
            if (renderView.parent == null) 
            {
                previousCoordinates.push(null);
            }
            else 
            {
                previousCoordinates.push(new Point(renderView.x, renderView.y));
            }
        }  // They provide the final coordinates for the smooth shift    // Perform the layout, which modifies the positions of the objects themselves  
        
        
        
        
        
        super.layoutObjects();
        var newCoordinates : Array<Point> = new Array<Point>();
        for (i in 0...numComponents){
            renderView = renderComponents[i];
            newCoordinates.push(new Point(renderView.x, renderView.y));
        }  // a fade in animation will be played for it    // Any object that does not have a previous position is presumed to be new and in which case  
        
        
        
        
        
        var previousCoordinate : Point;
        var newCoordinate : Point;
        var animationsToPlay : Int = numComponents;
        for (i in 0...numComponents){
            renderView = renderComponents[i];
            previousCoordinate = previousCoordinates[i];
            newCoordinate = newCoordinates[i];
            
            var tween : Tween;
            if (previousCoordinate == null) 
            {
                var scaleDuration : Float = 0.25;
                renderView.scaleX = renderView.scaleY = 0.0;
                tween = new Tween(renderView, scaleDuration);
                tween.scaleTo(1.0);
                Starling.juggler.add(tween);
            }
            else 
            {
                var shiftDuration : Float = 0.25;
                renderView.x = previousCoordinate.x;
                renderView.y = previousCoordinate.y;
                tween = new Tween(renderView, shiftDuration);
                tween.moveTo(newCoordinate.x, newCoordinate.y);
                Starling.juggler.add(tween);
            }
            tween.onComplete = function() : Void
                    {
                        animationsToPlay--;
                        checkAnimationsCompleted();
                    };
            m_animationPlaying = true;
        }  // For the case where there is nothing to animate  
        
        
        
        checkAnimationsCompleted();
        
        function checkAnimationsCompleted() : Void
        {
            if (animationsToPlay == 0) 
            {
                m_animationPlaying = false;
                
                // Check if another call to set the deck contents was made while the animations
                // were finishing
                
                // If the component manager still contains an entity that was requested to be added,
                // we grab the renderer and immediately add it to the widget.
                // Do not do this for the last one as that will be added via an animation.
                var numEntitiesToAddQueued : Int = m_entitiesToAddQueue.length;
                var entitiesToAddPending : Array<DisplayObject>;
                var j : Int;
                for (i in 0...numEntitiesToAddQueued){
                    entitiesToAddPending = m_entitiesToAddQueue[i];
                    if (i < numEntitiesToAddQueued - 1) 
                    {
                        for (j in 0...entitiesToAddPending.length){
                            if (entitiesToAddPending[j] != null) 
                            {
                                addObject(entitiesToAddPending[j], false);
                            }
                        }
                    }
                }  // as that will be removed via the animation    // Remove all components that were queued except for the most recent one  
                
                
                
                
                
                var numEnititiesToRemoveQueued : Int = m_entitiesToRemoveQueue.length;
                var entitiesToRemovePending : Array<DisplayObject>;
                for (i in 0...numEnititiesToRemoveQueued){
                    entitiesToRemovePending = m_entitiesToRemoveQueue[i];
                    if (i < numEnititiesToRemoveQueued - 1) 
                    {
                        for (j in 0...entitiesToRemovePending.length){
                            removeObject(entitiesToRemovePending[j], false);
                        }
                    }
                }  // Clear the queues  
                
                
                
                as3hx.Compat.setArrayLength(m_entitiesToAddQueue, 0);
                as3hx.Compat.setArrayLength(m_entitiesToRemoveQueue, 0);
                
                if (entitiesToAddPending != null && entitiesToRemovePending != null) 
                {
                    batchAddRemoveExpressions(entitiesToAddPending, entitiesToRemovePending);
                }
                
                refreshHitAreaBounds();
                
                // Determin whether scroll arrows are even necessary.
                // Check if the objects bounds would overflow from the view port
                if (getObjectTotalWidth() > getViewport().width) 
                {
                    addChild(m_leftScrollButton);
                    addChild(m_rightScrollButton);
                }
                else 
                {
                    m_leftScrollButton.removeFromParent();
                    m_rightScrollButton.removeFromParent();
                }
            }
        };
    }
    
    public function getWidgetFromSymbol(symbol : String) : BaseTermWidget
    {
        var expressionComponents : Array<Component> = m_componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
        
        var widget : BaseTermWidget = null;
        for (i in 0...expressionComponents.length){
            var expressionComponent : ExpressionComponent = try cast(expressionComponents[i], ExpressionComponent) catch(e:Dynamic) null;
            if (expressionComponent.root.data == symbol) 
            {
                var renderer : RenderableComponent = try cast(m_componentManager.getComponentFromEntityIdAndType(
                        expressionComponent.entityId,
                        RenderableComponent.TYPE_ID
                        ), RenderableComponent) catch(e:Dynamic) null;
                widget = try cast(renderer.view, BaseTermWidget) catch(e:Dynamic) null;
                break;
            }
        }
        
        return widget;
    }
    
    /**
     * Disabled widgets should not be selectable or draggable.
     * 
     * @param enabled
     * @param symbol
     */
    public function toggleSymbolEnabled(enabled : Bool, symbol : String) : Void
    {
        // Look through our set of disabled widgets, if one of them has
        // the matching symbol then we remove it from the list and apply some
        // graphic effect on it
        var widget : BaseTermWidget = getWidgetFromSymbol(symbol);
        if (widget != null) 
        {
            widget.setEnabled(enabled);
        }
    }
    
    /**
     * @param x
		 * 		global x coordinate
		 * @param y
		 * 		global y coordinate
     * @param allowHidden
     *      if true then we allow for widgets that are hidden to be picked
     */
    public function pickSelectedWidget(x : Float, y : Float, allowHidden : Bool = false) : BaseTermWidget
    {
        // Make sure mouse is in the view port
        var pickedWidget : BaseTermWidget = try cast(super.getObjectUnderPoint(x, y), BaseTermWidget) catch(e:Dynamic) null;
        if (pickedWidget != null) 
        {
            if (!pickedWidget.getIsEnabled() || (!allowHidden && pickedWidget.getIsHidden())) 
            {
                pickedWidget = null;
            }
        }
        
        return pickedWidget;
    }
    
    /**
     * Note that is the turn animation is already playing, it will ignore this call.
     */
    public function reverseValue(widget : BaseTermWidget) : Void
    {
        if (!m_animationPlaying) 
        {
            var symbolWidget : SymbolTermWidget = try cast(widget, SymbolTermWidget) catch(e:Dynamic) null;
            if (symbolWidget != null) 
            {
                m_animationPlaying = true;
                symbolWidget.reverseValue(
                        function() : Void
                        {
                            m_animationPlaying = false;
                        }
                        );
            }
        }
    }
    
    /**
     * Get whether the deck is currently animation one or more of its cards.
     */
    public function getAnimationPlaying() : Bool
    {
        return m_animationPlaying;
    }
    
    /**
     * External scripts may need to lock the deck through an external animation.
     * For example the discover term plays an animation.
     */
    public function setAnimationPlaying(value : Bool) : Void
    {
        m_animationPlaying = value;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        m_leftScrollButton.removeEventListener(Event.TRIGGERED, onLeftScrollClick);
        m_leftScrollButton.removeFromParent(true);
        m_rightScrollButton.removeEventListener(Event.TRIGGERED, onRightScrollClick);
        m_rightScrollButton.removeFromParent(true);
    }
    
    override private function scrollButtonsEnabled(leftEnabled : Bool, rightEnabled : Bool) : Void
    {
        m_leftScrollButton.alpha = ((leftEnabled)) ? 1.0 : 0.3;
        m_leftScrollButton.isEnabled = leftEnabled;
        m_rightScrollButton.alpha = ((rightEnabled)) ? 1.0 : 0.3;
        m_rightScrollButton.isEnabled = rightEnabled;
    }
    
    private function onLeftScrollClick() : Void
    {
        this.scrollByObjectAmount(1);
        refreshHitAreaBounds();
    }
    
    private function onRightScrollClick() : Void
    {
        this.scrollByObjectAmount(-1);
        refreshHitAreaBounds();
    }
    
    /**
     * Refreshes the bound hit areas, needs to be called everytime the deck is moved as well
     * as whenever objects are laid out again.
     */
    private function refreshHitAreaBounds() : Void
    {
        // If deck isn't visible we cannot do a refresh
        if (this.parent == null || this.stage == null) 
        {
            return;
        }  // Note the rigid body is relative to this widget    // of the object is refreshed as it is what is used to check hits    // After layout is completed for each object we need to make sure the rigid body component  
        
        
        
        
        
        
        
        var rigidBodyComponents : Array<Component> = m_componentManager.getComponentListForType(RigidBodyComponent.TYPE_ID);
        var rigidBodyComponent : RigidBodyComponent;
        var i : Int;
        var renderComponent : RenderableComponent;
        for (i in 0...rigidBodyComponents.length){
            rigidBodyComponent = try cast(rigidBodyComponents[i], RigidBodyComponent) catch(e:Dynamic) null;
            renderComponent = try cast(m_componentManager.getComponentFromEntityIdAndType(rigidBodyComponent.entityId, RenderableComponent.TYPE_ID), RenderableComponent) catch(e:Dynamic) null;
            if (renderComponent.view.parent) 
            {
                renderComponent.view.getBounds(this, rigidBodyComponent.boundingRectangle);
            }
        }
        
        dispatchEventWith(DeckWidget.EVENT_REFRESH);
    }
}