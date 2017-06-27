package wordproblem.engine.widget
{
    import flash.geom.Rectangle;
    
    import feathers.controls.Button;
    import feathers.display.Scale3Image;
    import feathers.textures.Scale3Textures;
    
    import starling.animation.Transitions;
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.filters.BlurFilter;
    import starling.text.TextField;
    import starling.textures.Texture;
    import wordproblem.resource.AssetManager
    
    import wordproblem.engine.component.RenderableComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.text.OutlinedTextField;
    
    /**
     * The equation inventory should have a button that when clicked will expand a horizontal
     * scroller holding all the equations owned by the player
     */
    public class EquationInventoryWidget extends Sprite
    {
        /**
         * The button area that helps toggle whether the scroller is expanded or collapsed
         */
        private var m_expandButton:Button;
        private var m_expandIconClosed:Image;
        private var m_expandIconOpen:Image;
        
        /**
         * Keep track of whether the equation contents is fully expanded and visible.
         */
        private var m_isExpanded:Boolean;
        
        /**
         * Is the widget in the middle of the expand animation.
         * 
         * Generally we do not want to interrupt an animation that is in progress
         */
        private var m_isAnimating:Boolean;
        
        /**
         * Texture representing the background for the scroll button and equations
         */
        private var m_background:DisplayObject;
        
        private var m_scrollLeftButton:Button;
        private var m_scrollRightButton:Button;
        
        // The feathers buttons do not have a width assigned immediately
        private var m_expandButtonWidth:Number;
        private var m_backgroundInitialDimensions:Rectangle;
        private var m_scrollButtonDimensions:Rectangle;
        private var m_totalWidth:Number;
        private var m_totalHeight:Number;
        private const m_backgroundDuration:Number = 0.5;
        private const m_equationDuration:Number = 0.25;
        
        /**
         * The text displaying how many equations are contained within this widget.
         * The value should automatically update each time the contents of the scroller
         * is altered.
         */
        private var m_equationsTextfield:OutlinedTextField;
        
        /**
         * The scroller container the actual widgets.
         * 
         * (The display objects need to be masked)
         */
        private var m_scrollArea:ScrollGridWidget;
        
        public function EquationInventoryWidget(assetManager:AssetManager)
        {
            super();
            
            const padding:Number = 20;
            const texture:Texture = assetManager.getTexture("button_white");
            const backgroundTexture:Scale3Textures = new Scale3Textures(texture, padding, texture.width - 2 * padding);
            const backgroundImage:Scale3Image = new Scale3Image(backgroundTexture);
            backgroundImage.color = 0xCCCCCC;
            m_backgroundInitialDimensions = new Rectangle(0, 0, texture.width, texture.height);
            m_background = backgroundImage;
            
            m_scrollArea = new ScrollGridWidget(
                10,
                false,
                null,
                null,
                true
            );
            
            const scaleFactor:Number = 0.7;
            const buttonTexture:Texture = assetManager.getTexture("button_sidebar_minimize");
            m_scrollButtonDimensions = new Rectangle(0, 0, buttonTexture.width * scaleFactor, buttonTexture.height * scaleFactor);
            m_scrollLeftButton = WidgetUtil.createButton(assetManager, "button_sidebar_minimize", "button_sidebar_minimize_click", null, "button_sidebar_minimize_mouseover", null, null);
            m_scrollLeftButton.scaleX = m_scrollLeftButton.scaleY = scaleFactor;
            m_scrollLeftButton.addEventListener(Event.TRIGGERED, onClickLeft);
            
            m_scrollRightButton = WidgetUtil.createButton(assetManager, "button_sidebar_maximize", "button_sidebar_maximize_click", null, "button_sidebar_maximize_mouseover", null, null);
            m_scrollRightButton.scaleX = m_scrollRightButton.scaleY = scaleFactor;
            m_scrollRightButton.addEventListener(Event.TRIGGERED, onClickRight);
            
            const expandTexture:Texture = assetManager.getTexture("box_closed");
            m_expandIconClosed = new Image(expandTexture);
            m_expandIconOpen = new Image(assetManager.getTexture("box_open"));
            
            m_expandButtonWidth = expandTexture.width;
            m_expandButton = WidgetUtil.createButton(assetManager, "box_closed", null, null, null, null, null);
            m_expandButton.addEventListener(Event.TRIGGERED, onClickExpand);
            m_expandButton.pivotY = expandTexture.height * 0.5;
            addChild(m_expandButton);
            
            // Initially we need to set whether the contents are visible or not
            m_isAnimating = false;
            m_isExpanded = false;
            
            // To use outlined text we create a regular flash textfield, add a glow filter to it then
            // flush it to a bitmap which then acts as a texture for a regular starling image.
            m_equationsTextfield = new OutlinedTextField(expandTexture.width, expandTexture.height, "Verdana", 28, 0xFFFFFF, 0);
            m_equationsTextfield.setText("0");
            m_scrollArea.addEventListener(ScrollGridWidget.EVENT_LAYOUT_COMPLETE, onLayoutComplete);
        }
        
        public function setDimensions(width:Number, height:Number):void
        {
            m_totalWidth = width;
            m_totalHeight = height;
            
            // Center the expand button
            m_expandButton.y = height * 0.4;
            m_background.y = height * 0.5;
            m_background.height *= 0.75;
            m_background.pivotY = m_background.height * 0.5;
            
            m_equationsTextfield.y = m_expandButton.y;
            m_equationsTextfield.x = m_expandButton.x;
            m_equationsTextfield.pivotY = m_equationsTextfield.height * 0.5;
            m_expandButton.addChild(m_equationsTextfield);
            
            m_scrollLeftButton.x = m_expandButtonWidth;
            m_scrollLeftButton.y = (m_scrollLeftButton.height + m_background.height) * 0.5;
            
            // The scroll area dimension needs to subtract the contributions of the expand button
            // and the scroll buttons
            m_scrollArea.x = m_scrollLeftButton.x + m_scrollButtonDimensions.width;
            m_scrollArea.setViewport(0, 0, width - 2 * m_scrollButtonDimensions.width - m_expandButtonWidth, height);
            
            m_scrollRightButton.x = width - m_scrollButtonDimensions.width;
            m_scrollRightButton.y = (m_scrollRightButton.height + m_background.height) * 0.5;
           
        }
        
        public function getScrollArea():ScrollGridWidget
        {
            return m_scrollArea;
        }
        
        public function setExpanded(expand:Boolean):void
        {
            if (m_isExpanded != expand)
            {
                m_isAnimating = true;
                
                const renderComponents:Vector.<RenderableComponent> = null;// m_scrollArea.getObjects();
                const numComponents:int = renderComponents.length;
                var i:int;
                var item:DisplayObject;
                var numRemainingToAnimate:int = numComponents;
                
                // If we want to expand out, the background should stretch out first
                if (expand)
                {
                    addChildAt(m_background, 0);
                    
                    // Need to tween the scale factor
                    m_background.width = 0;
                    
                    Starling.juggler.tween(m_background, m_backgroundDuration, {
                        onComplete:onBackgroundExpand, 
                        width:m_totalWidth
                    });
                    function onBackgroundExpand():void
                    {
                        // On every update of the contents needs to get the dimensions of the visible area. Check if the change forces an update
                        // of whether the arrows should appear (i.e. some content is now hidden
                        const contentWidth:Number = m_scrollArea.getObjectTotalWidth();
                        
                        for (i = 0; i < numComponents; i++)
                        {
                            item = renderComponents[i].view;

                            // Quickly pull out the background 
                            // The equations should not be visible
                            // Once it is finished, each equation should scale up to pop in along with the buttons
                            item.scaleX = item.scaleY = 0;
                            Starling.juggler.tween(item, m_equationDuration, {transition:Transitions.LINEAR, onComplete:onEquationExpand, scaleX:1, scaleY:1});
                            function onEquationExpand():void
                            {
                                numRemainingToAnimate--;
                                if (numRemainingToAnimate == 0)
                                {
                                    m_isAnimating = false;
                                }
                            }
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
                    }
                }
                else
                {
                    for (i = 0; i < numComponents; i++)
                    {
                        item = renderComponents[i].view;
                        // Quickly scale down the equations and then shift the background into the button
                        Starling.juggler.tween(item, m_equationDuration, {transition:Transitions.LINEAR, onComplete:onEquationContract, scaleX:0, scaleY:0});
                    }
                    
                    if (numComponents == 0)
                    {
                        onEquationContract();
                    }
                    
                    function onEquationContract():void
                    {
                        numRemainingToAnimate--;
                        
                        // One the equations are shrunk, the we will push the background back into the button
                        if (numRemainingToAnimate <= 0)
                        {
                            m_scrollArea.removeFromParent();
                            
                            Starling.juggler.tween(m_background, m_backgroundDuration, {
                                transition:Transitions.LINEAR, 
                                onComplete:onBackgroundContract, width:0
                            });
                            function onBackgroundContract():void
                            {
                                m_background.removeFromParent();
                                m_isAnimating = false;
                                
                                // For each item return it to items original scale
                                for each (var renderComponent:RenderableComponent in renderComponents)
                                {
                                    renderComponent.view.scaleX = 1;
                                    renderComponent.view.scaleY = 1;
                                }
                            }
                        }
                    }
                    
                    m_scrollLeftButton.removeFromParent();
                    m_scrollRightButton.removeFromParent();
                }
               
                m_isExpanded = expand;
            }
        }
        
        private function onClickLeft(event:Event):void
        {
            m_scrollArea.scrollByPixelAmount(-250);
        }
        
        private function onClickRight(event:Event):void
        {
            m_scrollArea.scrollByPixelAmount(250);   
        }
        
        private function onClickExpand(event:Event):void
        {
            // The scroll area should spill out of the expand button
            if (!m_isAnimating)
            {
                // If the scroller is empty then do not try expanding, wiggle the box around
                if (m_scrollArea.getObjects().length != 0)
                {
                    setExpanded(!m_isExpanded);
                    this.dispatchEventWith(GameEvent.EXPAND_INVENTORY_AREA, false, m_isExpanded);
                    
                    m_expandButton.defaultSkin = (m_isExpanded) ? m_expandIconOpen : m_expandIconClosed;
                    m_expandButton.filter = (m_isExpanded) ? BlurFilter.createGlow() : null;
                }
                else
                {
                    const wiggleTween:Tween = new Tween(m_expandButton, 0.1);
                    wiggleTween.repeatCount = 6;
                    wiggleTween.reverse = true;
                    wiggleTween.animate("x", m_expandButton.x + 10);
                    wiggleTween.onComplete = function():void
                    {
                        m_isAnimating = false;  
                    };
                    
                    Starling.juggler.add(wiggleTween);
                    m_isAnimating = true;
                }
            }
        }
        
        private function onLayoutComplete():void
        {
            // HACK:
            // Possible that layout does not cover all cases where the equations possessed changes in number
            // Need to update the counter of equations contained in the scroller.
            m_equationsTextfield.setText(m_scrollArea.getObjects().length.toString());
        }
    }
}