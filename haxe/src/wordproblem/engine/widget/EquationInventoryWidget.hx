package wordproblem.engine.widget;

import dragonbox.common.util.XColor;
import motion.Actuate;
import motion.easing.Linear;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import wordproblem.display.LabelButton;
import openfl.events.MouseEvent;
import openfl.filters.GlowFilter;
import wordproblem.display.PivotSprite;
import wordproblem.engine.events.DataEvent;
import wordproblem.engine.widget.ScrollGridWidget;

import openfl.geom.Rectangle;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.filters.BlurFilter;
import openfl.text.TextField;
import wordproblem.resource.AssetManager;

import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.text.OutlinedTextField;

/**
 * The equation inventory should have a button that when clicked will expand a horizontal
 * scroller holding all the equations owned by the player
 */
class EquationInventoryWidget extends Sprite
{
    /**
     * The button area that helps toggle whether the scroller is expanded or collapsed
     */
    private var m_expandButtonContainer : PivotSprite;
    private var m_expandIconClosed : Bitmap;
    private var m_expandIconOpen : Bitmap;
    
    /**
     * Keep track of whether the equation contents is fully expanded and visible.
     */
    private var m_isExpanded : Bool;
    
    /**
     * Is the widget in the middle of the expand animation.
     * 
     * Generally we do not want to interrupt an animation that is in progress
     */
    private var m_isAnimating : Bool;
    
    /**
     * Texture representing the background for the scroll button and equations
     */
    private var m_background : PivotSprite;
    
    private var m_scrollLeftButton : LabelButton;
    private var m_scrollRightButton : LabelButton;
    
    // The feathers buttons do not have a width assigned immediately
    private var m_expandButtonWidth : Float;
    private var m_backgroundInitialDimensions : Rectangle;
    private var m_scrollButtonDimensions : Rectangle;
    private var m_totalWidth : Float;
    private var m_totalHeight : Float;
    private inline static var m_backgroundDuration : Float = 0.5;
    private inline static var m_equationDuration : Float = 0.25;
    
    /**
     * The text displaying how many equations are contained within this widget.
     * The value should automatically update each time the contents of the scroller
     * is altered.
     */
    private var m_equationsTextfield : OutlinedTextField;
    
    /**
     * The scroller container the actual widgets.
     * 
     * (The display objects need to be masked)
     */
    private var m_scrollArea : ScrollGridWidget;
    
    public function new(assetManager : AssetManager)
    {
        super();
        
        var padding : Float = 20;
        var backgroundBitmapData : BitmapData = assetManager.getBitmapData("button_white");
        var backgroundImage : PivotSprite = new PivotSprite();
		backgroundImage.addChild(new Bitmap(backgroundBitmapData));
		backgroundImage.scale9Grid = new Rectangle(padding, 0, backgroundBitmapData.width - 2 * padding, backgroundBitmapData.height);
		backgroundImage.transform.colorTransform.concat(XColor.rgbToColorTransform(0xCCCCCC));
        m_backgroundInitialDimensions = new Rectangle(0, 0, backgroundBitmapData.width, backgroundBitmapData.height);
        m_background = backgroundImage;
        
        m_scrollArea = new ScrollGridWidget(
                10, 
                false, 
                null, 
                null, 
                true
                );
        
        var scaleFactor : Float = 0.7;
        var buttonBitmapData : BitmapData = assetManager.getBitmapData("button_sidebar_minimize");
        m_scrollButtonDimensions = new Rectangle(0, 0, buttonBitmapData.width * scaleFactor, buttonBitmapData.height * scaleFactor);
        m_scrollLeftButton = WidgetUtil.createButton(assetManager, "button_sidebar_minimize", "button_sidebar_minimize_click", null, "button_sidebar_minimize_mouseover", null, null);
        m_scrollLeftButton.scaleX = m_scrollLeftButton.scaleY = scaleFactor;
        m_scrollLeftButton.addEventListener(MouseEvent.CLICK, onClickLeft);
        
        m_scrollRightButton = WidgetUtil.createButton(assetManager, "button_sidebar_maximize", "button_sidebar_maximize_click", null, "button_sidebar_maximize_mouseover", null, null);
        m_scrollRightButton.scaleX = m_scrollRightButton.scaleY = scaleFactor;
        m_scrollRightButton.addEventListener(MouseEvent.CLICK, onClickRight);
        
        var expandBitmapData : BitmapData = assetManager.getBitmapData("box_closed");
        m_expandIconClosed = new Bitmap(expandBitmapData);
        m_expandIconOpen = new Bitmap(assetManager.getBitmapData("box_open"));
        
        m_expandButtonWidth = expandBitmapData.width;
		m_expandButtonContainer = new PivotSprite();
        m_expandButtonContainer.addChild(WidgetUtil.createButton(assetManager, "box_closed", null, null, null, null, null));
        m_expandButtonContainer.getChildAt(0).addEventListener(MouseEvent.CLICK, onClickExpand);
        m_expandButtonContainer.pivotY = expandBitmapData.height * 0.5;
        addChild(m_expandButtonContainer);
        
        // Initially we need to set whether the contents are visible or not
        m_isAnimating = false;
        m_isExpanded = false;
        
        // To use outlined text we create a regular flash textfield, add a glow filter to it then
        // flush it to a bitmap which then acts as a texture for a regular starling image.
        m_equationsTextfield = new OutlinedTextField(expandBitmapData.width, expandBitmapData.height, "Verdana", 28, 0xFFFFFF, 0);
        m_equationsTextfield.setText("0");
        m_scrollArea.addEventListener(ScrollGridWidget.EVENT_LAYOUT_COMPLETE, onLayoutComplete);
    }
    
    public function setDimensions(width : Float, height : Float) : Void
    {
        m_totalWidth = width;
        m_totalHeight = height;
        
        // Center the expand button
        m_expandButtonContainer.y = height * 0.4;
        m_background.y = height * 0.5;
        m_background.height *= 0.75;
        m_background.pivotY = m_background.height * 0.5;
        
        m_equationsTextfield.y = m_expandButtonContainer.y;
        m_equationsTextfield.x = m_expandButtonContainer.x;
        m_equationsTextfield.pivotY = m_equationsTextfield.height * 0.5;
        m_expandButtonContainer.addChild(m_equationsTextfield);
        
        m_scrollLeftButton.x = m_expandButtonWidth;
        m_scrollLeftButton.y = (m_scrollLeftButton.height + m_background.height) * 0.5;
        
        // The scroll area dimension needs to subtract the contributions of the expand button
        // and the scroll buttons
        m_scrollArea.x = m_scrollLeftButton.x + m_scrollButtonDimensions.width;
        m_scrollArea.setViewport(0, 0, width - 2 * m_scrollButtonDimensions.width - m_expandButtonWidth, height);
        
        m_scrollRightButton.x = width - m_scrollButtonDimensions.width;
        m_scrollRightButton.y = (m_scrollRightButton.height + m_background.height) * 0.5;
    }
    
    public function getScrollArea() : ScrollGridWidget
    {
        return m_scrollArea;
    }
    
    public function setExpanded(expand : Bool) : Void
    {
        if (m_isExpanded != expand) 
        {
            m_isAnimating = true;
            
            var renderComponents : Array<RenderableComponent> = null;  // m_scrollArea.getObjects();  
            var numComponents : Int = renderComponents.length;
            var i : Int = 0;
            var item : DisplayObject = null;
            var numRemainingToAnimate : Int = numComponents;
            
            // If we want to expand out, the background should stretch out first
            if (expand) 
            {
                addChildAt(m_background, 0);
                
                // Need to tween the scale factor
                m_background.width = 0;
				function onBackgroundExpand() : Void
                {
                    // On every update of the contents needs to get the dimensions of the visible area. Check if the change forces an update
                    // of whether the arrows should appear (i.e. some content is now hidden
                    var contentWidth : Float = m_scrollArea.getObjectTotalWidth();
					function onEquationExpand() : Void
                        {
                            numRemainingToAnimate--;
                            if (numRemainingToAnimate == 0) 
                            {
                                m_isAnimating = false;
                            }
                        };
						
                    for (i in 0...numComponents){
                        item = renderComponents[i].view;
                        
                        // Quickly pull out the background
                        // The equations should not be visible
                        // Once it is finished, each equation should scale up to pop in along with the buttons
                        item.scaleX = item.scaleY = 0;
						Actuate.tween(item, m_equationDuration, { scaleX: 1, scaleY: 1}).ease(Linear.easeNone).onComplete(onEquationExpand);
                    }
                    
                    if (numComponents == 0) 
                    {
                        m_isAnimating = false;
                    }
                    
                    addChild(m_scrollArea);
                    
                    
                    if (contentWidth > m_scrollArea.getViewport().width) 
                    {
                        addChild(m_scrollLeftButton);
                        addChild(m_scrollRightButton);
                    }
                };
				
				Actuate.tween(m_background, m_backgroundDuration, { width : m_totalWidth }).onComplete(onBackgroundExpand);
            }
            else 
            {
				function onEquationContract() : Void
                {
                    numRemainingToAnimate--;
					function onBackgroundContract() : Void
                        {
                            if (m_background.parent != null) m_background.parent.removeChild(m_background);
                            m_isAnimating = false;
                            
                            // For each item return it to items original scale
                            for (renderComponent in renderComponents)
                            {
                                renderComponent.view.scaleX = 1;
                                renderComponent.view.scaleY = 1;
                            }
                        };
                    
                    // One the equations are shrunk, the we will push the background back into the button
                    if (numRemainingToAnimate <= 0) 
                    {
                        if (m_scrollArea.parent != null) m_scrollArea.parent.removeChild(m_scrollArea);
                        
						Actuate.tween(m_background, m_backgroundDuration, { width : 0 }).ease(Linear.easeNone).onComplete(onBackgroundContract);
                    }
                };
				
                for (i in 0...numComponents){
                    item = renderComponents[i].view;
                    // Quickly scale down the equations and then shift the background into the button
					Actuate.tween(item, m_equationDuration, { scaleX: 0, scaleY: 0 }).ease(Linear.easeNone).onComplete(onEquationContract);
                }
                
                if (numComponents == 0) 
                {
                    onEquationContract();
                }
                
                if (m_scrollLeftButton.parent != null) m_scrollLeftButton.parent.removeChild(m_scrollLeftButton);
                if (m_scrollRightButton.parent != null) m_scrollRightButton.parent.removeChild(m_scrollRightButton);
            }
            
            m_isExpanded = expand;
        }
    }
    
    private function onClickLeft(event : Event) : Void
    {
        m_scrollArea.scrollByPixelAmount(-250);
    }
    
    private function onClickRight(event : Event) : Void
    {
        m_scrollArea.scrollByPixelAmount(250);
    }
    
    private function onClickExpand(event : Event) : Void
    {
        // The scroll area should spill out of the expand button
        if (!m_isAnimating) 
        {
            // If the scroller is empty then do not try expanding, wiggle the box around
            if (m_scrollArea.getObjects().length != 0) 
            {
                setExpanded(!m_isExpanded);
                this.dispatchEvent(new DataEvent(GameEvent.EXPAND_INVENTORY_AREA, m_isExpanded));
                
				var expandButton = try cast(m_expandButtonContainer.getChildAt(0), LabelButton) catch (e : Dynamic) null;
				
				if (expandButton != null) {
					expandButton.upState = m_isExpanded ? m_expandIconOpen : m_expandIconClosed;
					
					var filters = expandButton.filters;
					if (filters != null && m_isExpanded) filters.push(new GlowFilter());
					expandButton.filters = filters;
				}
            }
            else 
            {
				Actuate.tween(m_expandButtonContainer, 0.1, { x: m_expandButtonContainer.x + 10 }).repeat(6).reflect().onComplete(function() : Void
                        {
                            m_isAnimating = false;
                        });
                
                m_isAnimating = true;
            }
        }
    }
    
    private function onLayoutComplete(event : Dynamic) : Void
    {
        // HACK:
        // Possible that layout does not cover all cases where the equations possessed changes in number
        // Need to update the counter of equations contained in the scroller.
        m_equationsTextfield.setText(Std.string(m_scrollArea.getObjects().length));
    }
}
