package wordproblem.engine.widget;

import motion.Actuate;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.MouseEvent;
import wordproblem.engine.widget.IBaseWidget;
import wordproblem.engine.widget.ScrollGridWidget;

import openfl.geom.Point;

import dragonbox.common.dispose.IDisposable;

import wordproblem.display.LabelButton;
import openfl.display.DisplayObject;
import openfl.events.Event;

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
    private var m_leftScrollButton : LabelButton;
    private var m_rightScrollButton : LabelButton;
    
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
        
        var arrowBitmapData : BitmapData = assetManager.getBitmapData("arrow_short");
        var arrowScale : Float = 1.0;
        m_scrollButtonWidth = arrowBitmapData.width * arrowScale;
        var leftUpArrow : DisplayObject = WidgetUtil.createPointingArrow(arrowBitmapData, true, arrowScale, 0xFFFFFF);
        m_leftScrollButton = WidgetUtil.createButtonFromImages(leftUpArrow, null, null, null, null, null);
		m_leftScrollButton.scaleWhenOver = m_leftScrollButton.scaleX * 1.1;
		m_leftScrollButton.scaleWhenDown = m_leftScrollButton.scaleX * 0.9;
        m_leftScrollButton.addEventListener(MouseEvent.CLICK, onLeftScrollClick);
        
        var rightUpArrow : DisplayObject = WidgetUtil.createPointingArrow(arrowBitmapData, false, arrowScale, 0xFFFFFF);
        m_rightScrollButton = WidgetUtil.createButtonFromImages(rightUpArrow, null, null, null, null, null);
		m_rightScrollButton.scaleWhenOver = m_leftScrollButton.scaleWhenOver;
		m_rightScrollButton.scaleWhenDown = m_leftScrollButton.scaleWhenDown;
        m_rightScrollButton.addEventListener(MouseEvent.CLICK, onRightScrollClick);
    }
    
    private function get_componentManager() : ComponentManager
    {
        return m_componentManager;
    }
    
    public function setDimensions(maxWidth : Float, maxHeight : Float) : Void
    {
        if (m_background != null) 
        {
			m_background.width = maxWidth;
			m_background.height = maxHeight;
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
        var indexA : Int = 0;
        var indexB : Int = 0;
        var i : Int = 0;
        var widget : BaseTermWidget = null;
        for (component in renderComponentList){
            widget = try cast(component, BaseTermWidget) catch(e:Dynamic) null;
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
        
        var i : Int = 0;
        var numEntitiesToAdd : Int = entitiesToAdd.length;
		componentsToAddBuffer = new Array<DisplayObject>();
        for (i in 0...numEntitiesToAdd){
            componentsToAddBuffer.push(entitiesToAdd[i]);
        }  
		
		// Since at this point the components have already been removed we have no choice but  
		// to fetch the render components from the scroll widget. 
        // We assume the disposal of a render component does not automatically remove it from the display list  
        var existingObjects : Array<DisplayObject> = super.getObjects();
        var numExistingObjects : Int = existingObjects.length;
        var numEntitiesToRemove : Int = entitiesToRemove.length;
		componentsToRemoveBuffer = new Array<DisplayObject>();
        for (i in 0...numEntitiesToRemove){
            var viewToRemove : DisplayObject = entitiesToRemove[i];
            
            // Get the render component currently in the scrolling grid that matches the
            // entity id to remove.
            var j : Int = 0;
            var existingObject : DisplayObject = null;
            for (j in 0...numExistingObjects){
                existingObject = existingObjects[j];
                if (existingObject == viewToRemove) 
                {
                    componentsToRemoveBuffer.push(existingObject);
                    break;
                }
            }
        }  
		
		// Since the batch add/remove call immediately removes objects from the display list we need to animate cards disappearing
		// beforehand. We can do whatever we want with them since after the call they should have no effect on the layout    
		// of new and current objects
        function onRemoveTweensComplete() : Void
        {
            batchAddRemove(componentsToAddBuffer, componentsToRemoveBuffer, false);
            
            // Call the layout animation of this widget, this fades in the new cards as well
            // as shift over the previous ones.
            layout();
        };
        
        if (componentsToRemoveBuffer.length > 0) 
        {
            var animationsToPlay : Int = numEntitiesToRemove;
            var duration : Float = 0.25;
            for (i in 0...numEntitiesToRemove){
                var existingObject = componentsToRemoveBuffer[i];
				Actuate.tween(existingObject, duration, { scaleX: 0, scaleY: 0 }).onComplete(function() : Void
                        {
                            animationsToPlay--;
                            if (animationsToPlay == 0) 
                            {
                                onRemoveTweensComplete();
                            }
                        });
                m_animationPlaying = true;
            }
        }
        else 
        {
            onRemoveTweensComplete();
        }
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
        var i : Int = 0;
        var renderView : DisplayObject = null;
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
        }
		
		// Perform the layout, which modifies the positions of the objects themselves  
		// They provide the final coordinates for the smooth shift    
        super.layoutObjects();
        var newCoordinates : Array<Point> = new Array<Point>();
        for (i in 0...numComponents){
            renderView = renderComponents[i];
            newCoordinates.push(new Point(renderView.x, renderView.y));
        }
        
        var previousCoordinate : Point = null;
        var newCoordinate : Point = null;
        var animationsToPlay : Int = numComponents;
		// Any object that does not have a previous position is presumed to be new and in which case  
        // a fade in animation will be played for it    
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
                var entitiesToAddPending : Array<DisplayObject> = null;
                var j : Int = 0;
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
                }
				
				// Remove all components that were queued except for the most recent one 
				// as that will be removed via the animation
                var numEnititiesToRemoveQueued : Int = m_entitiesToRemoveQueue.length;
                var entitiesToRemovePending : Array<DisplayObject> = null;
                for (i in 0...numEnititiesToRemoveQueued){
                    entitiesToRemovePending = m_entitiesToRemoveQueue[i];
                    if (i < numEnititiesToRemoveQueued - 1) 
                    {
                        for (j in 0...entitiesToRemovePending.length){
                            removeObject(entitiesToRemovePending[j], false);
                        }
                    }
                }
				
				// Clear the queues  
				m_entitiesToAddQueue = new Array<Array<DisplayObject>>();
				m_entitiesToRemoveQueue = new Array<Array<DisplayObject>>();
                
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
                    if (m_leftScrollButton.parent != null) m_leftScrollButton.parent.removeChild(m_leftScrollButton);
                    if (m_rightScrollButton.parent != null) m_rightScrollButton.parent.removeChild(m_rightScrollButton);
                }
            }
        };
		
        for (i in 0...numComponents){
            renderView = renderComponents[i];
            previousCoordinate = previousCoordinates[i];
            newCoordinate = newCoordinates[i];
            
			function onTweenComplete() {
				animationsToPlay--;
				checkAnimationsCompleted();
			}
			
            if (previousCoordinate == null) 
            {
                var scaleDuration : Float = 0.25;
                renderView.scaleX = renderView.scaleY = 0.0;
				Actuate.tween(renderView, scaleDuration, { scaleX: 1, scaleY: 1 }).onComplete(onTweenComplete);
            }
            else 
            {
                var shiftDuration : Float = 0.25;
                renderView.x = previousCoordinate.x;
                renderView.y = previousCoordinate.y;
				Actuate.tween(renderView, shiftDuration, { x: newCoordinate.x, y: newCoordinate.y }).onComplete(onTweenComplete);
            }
            m_animationPlaying = true;
        } 
		
		// For the case where there is nothing to animate  
        checkAnimationsCompleted();
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
        m_leftScrollButton.removeEventListener(MouseEvent.CLICK, onLeftScrollClick);
		if (m_leftScrollButton.parent != null) m_leftScrollButton.parent.removeChild(m_leftScrollButton);
		m_leftScrollButton.dispose();
        m_rightScrollButton.removeEventListener(MouseEvent.CLICK, onRightScrollClick);
		if (m_rightScrollButton.parent != null) m_rightScrollButton.parent.removeChild(m_rightScrollButton);
		m_rightScrollButton.dispose();
    }
    
    override private function scrollButtonsEnabled(leftEnabled : Bool, rightEnabled : Bool) : Void
    {
        m_leftScrollButton.alpha = ((leftEnabled)) ? 1.0 : 0.3;
        m_leftScrollButton.enabled = leftEnabled;
        m_rightScrollButton.alpha = ((rightEnabled)) ? 1.0 : 0.3;
        m_rightScrollButton.enabled = rightEnabled;
    }
    
    private function onLeftScrollClick(event : Dynamic) : Void
    {
        this.scrollByObjectAmount(1);
        refreshHitAreaBounds();
    }
    
    private function onRightScrollClick(event : Dynamic) : Void
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
        }  
		
		// After layout is completed for each object we need to make sure the rigid body component  
		// of the object is refreshed as it is what is used to check hits 
        // Note the rigid body is relative to this widget 
        var rigidBodyComponents : Array<Component> = m_componentManager.getComponentListForType(RigidBodyComponent.TYPE_ID);
        var rigidBodyComponent : RigidBodyComponent = null;
        var i : Int = 0;
        var renderComponent : RenderableComponent = null;
        for (i in 0...rigidBodyComponents.length){
            rigidBodyComponent = try cast(rigidBodyComponents[i], RigidBodyComponent) catch(e:Dynamic) null;
            renderComponent = try cast(m_componentManager.getComponentFromEntityIdAndType(rigidBodyComponent.entityId, RenderableComponent.TYPE_ID), RenderableComponent) catch(e:Dynamic) null;
            if (renderComponent.view.parent != null) 
            {
                rigidBodyComponent.boundingRectangle = renderComponent.view.getBounds(this);
            }
        }
        
        dispatchEvent(new Event(DeckWidget.EVENT_REFRESH));
    }
}
