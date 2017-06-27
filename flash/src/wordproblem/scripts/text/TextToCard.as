package wordproblem.scripts.text
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import cgs.Audio.Audio;
    
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.ui.MouseState;
    
    import feathers.display.Scale9Image;
    import feathers.textures.Scale9Textures;
    
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.extensions.textureutil.TextureUtil;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.utils.Color;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.animation.DocumentViewToCardAnimation;
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.ExpressionComponent;
    import wordproblem.engine.component.MouseInteractableComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.text.model.ImageNode;
    import wordproblem.engine.text.view.DocumentView;
    import wordproblem.engine.text.view.ImageView;
    import wordproblem.engine.text.view.TextView;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.BaseGameScript;
    import wordproblem.scripts.drag.WidgetDragSystem;
    
    /**
     * This script converts document views within the text area to another draggable piece.
     * The separate draggable pieces looks like the cards used to build expressions, but they can
     * be styled to look like anything.
     * 
     * Certain areas of the document are bound to expressions, in those cases this logic is responsible
     * for linking the draggable component to that expression.
     */
    public class TextToCard extends BaseGameScript
    {
        /**
         * Reference to the textual content
         */
        private var m_textArea:TextAreaWidget;
        
        /**
         * When text transforms into a card, the control of the dragged card is handed off to
         * the drag system so other widgets can poll information about it.
         */
        private var m_widgetDragSystem:WidgetDragSystem;

        private var m_expressionSymbolMap:ExpressionSymbolMap;
        
        /**
         * Reference to the view which links to some chunk of text that get dragged into the deck.
         * This is used for the player to discover terms
         */
        private var m_draggedContentFromParagraph:DocumentViewToCardAnimation;
        
        /**
         * Current expression value that was hit
         * 
         * null if nothing no document view bound to a term was selected
         */
        private var m_currentHitExpressionValue:String;
        
        /**
         * Current document view that was hit by the mouse
         */
        private var m_currentHitDocumentView:DocumentView;
        
        /**
         * A copy of the selected text content with a button background on it.
         */
        private var m_currentHitTextAsButton:DisplayObject;
        
        /**
         * A blank identation where the selected text was located.
         */
        private var m_currentHitTextAsBlank:Sprite;
        
        /**
         * Need to keep track of the image representing the text as a button because we
         * need to dispose of to free up texture memory.
         */
        private var m_currentTextAsLineTexture:Texture;
        
        /**
         * This function contains the logic that should be executed at the moment a dragged piece of
         * text was released by the mouse.
         */
        private var m_onReleaseCallback:Function = defaultReleaseText;
        
        // These are used when you click on a selectable object in the text and it wiggle.
        // We need a reference to properly interuppt this animation
        private var m_wiggleLeftTween:Tween = new Tween(null, 0);
        private var m_wiggleRightTween:Tween = new Tween(null, 0);
        private var m_wiggleOriginalX:Number;
        private const m_currentMouseGlobalBuffer:Point = new Point();
        
        public function TextToCard(gameEngine:IGameEngine, 
                                   expressionCompiler:IExpressionTreeCompiler, 
                                   assetManager:AssetManager, 
                                   id:String)
        {
            super(gameEngine, expressionCompiler, assetManager, id);
        }
        
        /**
         * Set the logic that should be executed at the moment a dragged piece of
         * text was released by the mouse.
         * 
         * Example usage, we want to wait to show the text until after some other animation (like discovering terms)
         * has finished. The text might also need to be grayed out afterwards.
         * 
         * params are:
         * the display object representing the button form of the text
         * the display object representing the blank indentation
         * the original view in the text area that was clicked
         */
        public function setOnReleaseCallback(callback:Function):void
        {
            m_onReleaseCallback = callback;
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            if (m_ready)
            {
                m_gameEngine.removeEventListener(GameEvent.END_DRAG_TERM_WIDGET, bufferEvent);
                m_gameEngine.removeEventListener(GameEvent.PRESS_TEXT_AREA, onPressText);
                m_gameEngine.removeEventListener(GameEvent.START_DRAG_TEXT_AREA, onStartDragFromText);
                m_gameEngine.removeEventListener(GameEvent.RELEASE_TEXT_AREA, onReleaseText);   
                if (value)
                {
                    m_gameEngine.addEventListener(GameEvent.END_DRAG_TERM_WIDGET, bufferEvent);
                    m_gameEngine.addEventListener(GameEvent.PRESS_TEXT_AREA, onPressText);
                    m_gameEngine.addEventListener(GameEvent.START_DRAG_TEXT_AREA, onStartDragFromText);
                    m_gameEngine.addEventListener(GameEvent.RELEASE_TEXT_AREA, onReleaseText);
                }
                else
                {
                    // Make sure the visual elements are disposed of propery
                    if (m_currentHitTextAsButton != null)
                    {
                        m_currentHitTextAsButton.removeFromParent(true);
                    }
                    
                    if (m_currentTextAsLineTexture != null)
                    {
                        m_currentTextAsLineTexture.dispose();
                        m_currentTextAsLineTexture = null;
                    }
                }
            }
        }
        
        override public function visit():int
        {
            if (super.m_ready)
            {
                // Deal with the dragging out items between components
                // 1.) Drag text to the model deck
                // 2.) Drag equation to the text area
                if (super.m_isActive)
                {
                    this.iterateThroughBufferedEvents();
                    
                    var mouseState:MouseState = super.m_gameEngine.getMouseState();
                    m_currentMouseGlobalBuffer.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
                    if (mouseState.leftMouseDraggedThisFrame)
                    {
                        if (m_draggedContentFromParagraph.viewCopy != null)
                        {
                            m_draggedContentFromParagraph.x = m_currentMouseGlobalBuffer.x;
                            m_draggedContentFromParagraph.y = m_currentMouseGlobalBuffer.y;
                        }
                    }
                }
                else
                {
                    // If not active should clear out any currently displayed visuals on the text, such as
                    // the blank space or button-like appearance when they click or drag the text
                    if (m_currentHitTextAsButton != null)
                    {
                        m_currentHitTextAsButton.removeFromParent(true);
                        m_currentHitTextAsButton = null;
                    }
                    
                    if (m_currentHitTextAsBlank != null)
                    {
                        m_currentHitTextAsBlank.removeFromParent(true);
                        m_currentHitTextAsBlank = null;
                    }
                    
                    if (m_currentHitDocumentView != null)
                    {
                        m_currentHitDocumentView.visible = true;
                        m_currentHitDocumentView = null;
                    }
                    
                    if (m_draggedContentFromParagraph.viewCopy != null)
                    {
                        m_draggedContentFromParagraph.reset();
                    }
                }
            }
            
            return ScriptStatus.FAIL;
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
			
            m_textArea = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            m_widgetDragSystem = this.getNodeById("WidgetDragSystem") as WidgetDragSystem;
            m_expressionSymbolMap = m_gameEngine.getExpressionSymbolResources();
            m_draggedContentFromParagraph = new DocumentViewToCardAnimation(
                m_expressionSymbolMap,
                m_assetManager,
                m_expressionCompiler.getVectorSpace()
            );
            
            this.setIsActive(m_isActive);
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == GameEvent.END_DRAG_TERM_WIDGET)
            {
                var releasedWidget:BaseTermWidget = param.widget;
                var releasedWidgetOrigin:DisplayObject = param.origin;    
                if (releasedWidgetOrigin == m_textArea)
                {
                    releasedWidget.removeFromParent();
                }
            }
        }
        
        private function onPressText(event:Event, params:Object):void
        {
            var view:DocumentView = params["view"];
            // We mark when we have hit an area and remember it when the drag starts
            // Do not do anything if something it snapping back though
            if (view != null && m_currentHitDocumentView == null)
            {
                // Search through all terms and check if the dragged content matches up with any of them
                // We want to attach term information to that text if there is a match
                // Each entity in the text component manager can bind to a single expression from the level script
                var components:Vector.<Component> = m_textArea.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
                var numComponents:int = components.length;
                var i:int;
                for (i = 0; i < numComponents; i++)
                {
                    var expressionComponent:ExpressionComponent = components[i] as ExpressionComponent;
                    var documentIdBoundToExpression:String = expressionComponent.entityId;
                    
                    if (m_textArea.getViewIsInContainer(view, documentIdBoundToExpression))
                    {
                        m_currentHitExpressionValue = expressionComponent.expressionString;
                        
                        // If the clicked view is part of a view that is bound to an expression
                        // we want to create a button like background surrounding the view
                        // From the current clicked view trace up until we get a view with the same id
                        while (view.node.id != documentIdBoundToExpression)
                        {
                            view = view.parentView
                        }
                        
                        break;
                    }
                }
                
                // Need to apply effects to each of the child views
                // We need to check whether the views are part of the same line of text
                // if they are then graphic needs to join the separate views in one
                // continuous pattern
                // We want to take the view contents and draw them onto a button background
                const outChildViews:Vector.<DocumentView> = new Vector.<DocumentView>();
                view.getDocumentViewLeaves(outChildViews);
                
                var resultBounds:Rectangle;
                var canvasToAddTo:DisplayObjectContainer = view.parent;
                var childView:DocumentView;
                var currentLineNumber:int = -1;
                var currentLineBounds:Rectangle = null;
                var lines:Vector.<Rectangle> = new Vector.<Rectangle>();
                
                // While determining the bounds we also want to create copies of the text content
                var lineButtonContainer:Sprite = new Sprite();
                for (i = 0; i < outChildViews.length; i++)
                {
                    // Determine the bounding dimensions of the content of each line.
                    // This will give us the necessary data to draw the background.
                    childView = outChildViews[i];
                    resultBounds = childView.getBounds(canvasToAddTo);
                    if (childView.lineNumber > currentLineNumber)
                    {
                        // Flush the previous contents
                        if (currentLineBounds != null)
                        {
                            lines.push(currentLineBounds);
                        }
                        
                        // Start a new line with the current contents
                        currentLineBounds = resultBounds;
                        currentLineNumber = childView.lineNumber;
                    }
                    else
                    {
                        // Create a union of all the bounds on the same line
                        currentLineBounds = currentLineBounds.union(resultBounds);
                    }
                    
                    // If the child view is text, it's color may blend in with the background
                    // Ex.) White text on white background is unreadable
                    // In this case we may want to change the color of it
                    // Since we are locked into the white card back we can just always make text black.
                    var alteredTextColor:Boolean = false;
                    var originalTextColor:uint = 0;
                    if (childView is TextView)
                    {
                        var childTextField:TextField = (childView as TextView).getTextField();
                        originalTextColor = childTextField.color;
                        var blue:uint = Color.getBlue(originalTextColor);
                        var green:uint = Color.getGreen(originalTextColor);
                        var red:uint = Color.getRed(originalTextColor);
                        const colorThreshold:uint = 100;
                        if (blue > colorThreshold && green > colorThreshold && red > colorThreshold)
                        {
                            childTextField.color = 0x000000;
                            alteredTextColor = true;
                        }
                    }
                    
                    // Create a copy of the child view, paste this on top
                    // of the button background texture.
                    var textAsLine:Image = TextureUtil.getImageFromDisplayObject(childView);
                    m_currentTextAsLineTexture = textAsLine.texture;
                    
                    var copyView:DisplayObject = textAsLine;
                    copyView.x = resultBounds.x;
                    copyView.y = resultBounds.y;
                    lineButtonContainer.addChild(copyView);
                    
                    // If we changed the color of the text, we need to switch it back
                    if (alteredTextColor)
                    {
                        (childView as TextView).getTextField().color = originalTextColor;
                    }
                }
                
                if (currentLineBounds != null)
                {
                    lines.push(currentLineBounds);
                }
                
                // If the selected view is already a card image there is no need to create a button background underneath
                // it nor play the animation where it transforms into a card. (Still create a blank background in any case
                // to indicate where a view was initially located)
                var selectedCard:Boolean = false;
                var doNotDrawButtonBackground:Boolean = (view.node is ImageNode && (view.node as ImageNode).src.type == "symbol");
                if (!doNotDrawButtonBackground)
                {
                    // Based on the bounds of each line, create a background image that fits under the content.
                    // The background image should only be displayed once the player drags the content off
                    for (i = 0; i < lines.length; i++)
                    {
                        currentLineBounds = lines[i];
                        
                        var padding:Number = 10;
                        var buttonTexture:Texture = m_assetManager.getTexture("card_background_square");
                        var nineTextureButton:Scale9Textures = new Scale9Textures(
                            buttonTexture,
                            new Rectangle(padding, padding, buttonTexture.width - 2 * padding, buttonTexture.height - 2 * padding)
                        );
                        var nineImageButton:Scale9Image = new Scale9Image(nineTextureButton);
                        nineImageButton.x = currentLineBounds.x - padding * 0.5;
                        nineImageButton.y = currentLineBounds.y;
                        nineImageButton.width = currentLineBounds.width + padding * 0.5;
                        nineImageButton.height = currentLineBounds.height;
                        lineButtonContainer.addChildAt(nineImageButton, 0);
                    }
                }
                
                // Make the hit portion look like a button
                // and save the blank line for later.
                canvasToAddTo.addChild(lineButtonContainer);
                m_currentHitTextAsButton = lineButtonContainer;
                
                // Per line should also create an indentation of where the line was initially.
                var lineBackgroundContainer:Sprite = new Sprite();
                for (i = 0; i < lines.length; i++)
                {
                    currentLineBounds = lines[i];
                    
                    var backgroundTexture:Texture = m_assetManager.getTexture("wildcard");
                    padding = 10;
                    var nineTextureBackground:Scale9Textures = new Scale9Textures(
                        backgroundTexture, 
                        new Rectangle(padding, padding, backgroundTexture.width - 2 * padding, backgroundTexture.height - 2 * padding)
                    );
                    var nineImageBackground:Scale9Image = new Scale9Image(nineTextureBackground);
                    nineImageBackground.x = currentLineBounds.x - padding * 0.5;
                    nineImageBackground.y = currentLineBounds.y - padding * 0.5;
                    nineImageBackground.width = currentLineBounds.width + padding;
                    nineImageBackground.height = currentLineBounds.height + padding;
                    
                    lineBackgroundContainer.addChild(nineImageBackground);
                    m_currentHitTextAsBlank = lineBackgroundContainer;
                }
                
                // Set the original view that was pressed, we may need to reference it later
                m_currentHitDocumentView = view;
                
                m_currentHitDocumentView.visible = false;
                
                Starling.juggler.remove(m_wiggleLeftTween);
                Starling.juggler.remove(m_wiggleRightTween);
                if (m_wiggleLeftTween.target != null)
                {
                    (m_wiggleLeftTween.target as DisplayObject).x = m_wiggleOriginalX;
                }
                
                // Quickly wiggle the selected view (used to help indicate there is something special about it)
                // Kill previous tweens if they were playing, need to reset the moved view to its original position
                // (This is only a problem for text pieces that area already cards)
                const wiggleDelta:Number = 8;
                m_wiggleOriginalX = m_currentHitTextAsButton.x;
                
                m_wiggleLeftTween.reset(m_currentHitTextAsButton, 0.07);
                m_wiggleLeftTween.reverse = true;
                m_wiggleLeftTween.repeatCount = 2;
                m_wiggleLeftTween.animate("x", m_currentHitTextAsButton.x - wiggleDelta);
                m_wiggleLeftTween.onComplete = function():void
                {
                    Starling.juggler.add(m_wiggleRightTween);
                };
                m_wiggleRightTween.reset(m_currentHitTextAsButton, 0.07);
                m_wiggleRightTween.reverse = true;
                m_wiggleRightTween.repeatCount = 2;
                m_wiggleRightTween.animate("x", m_currentHitTextAsButton.x + wiggleDelta);
                Starling.juggler.add(m_wiggleLeftTween);
                
                // Gather all possible document ids that the given is part of
                this.toggleMouseSelectedForView(view, true);
            }
        }
        
        private function onStartDragFromText(event:Event, args:Object):void
        {
            // Ignore attempts to drag text if current dragged text has not been cleared,
            // occurs when it has not finished its animation
            // Otherwise the old text gets stuck on screen
            var view:DocumentView = args.documentView;
            
            // Once drag starts we pull the document view that was selected
            // If the dragged view is not already a card then we want to have an animation
            // of the view transforming into a card
            var draggedObjectIsCardAlready:Boolean = m_currentHitDocumentView is ImageView && (m_currentHitDocumentView.node as ImageNode).src.type == "symbol";
            if (m_draggedContentFromParagraph.viewCopy == null && 
                m_currentHitDocumentView != null)
            {
                var audioDriver:Audio = Audio.instance;
                audioDriver.playSfx("text2card");
                
                // Immediately start dragging, but keep the dragged part invisible so as not to obscure the
                // animation
                if (m_currentHitExpressionValue != null)
                {
                    
                    m_widgetDragSystem.selectAndStartDrag(
                        new ExpressionNode(m_expressionCompiler.getVectorSpace(), m_currentHitExpressionValue), 
                        m_currentMouseGlobalBuffer.x, 
                        m_currentMouseGlobalBuffer.y,
                        m_textArea,
                        null
                    );
                    if (m_widgetDragSystem.getWidgetSelected())
                    {
                        m_widgetDragSystem.getWidgetSelected().alpha = 0.0;
                    }
                }
                
                if (draggedObjectIsCardAlready)
                {
                    onAnimationComplete();
                }
                else
                {
                    m_draggedContentFromParagraph.setView(
                        m_currentHitTextAsButton, 
                        m_currentHitExpressionValue, 
                        m_textArea.stage,
                        m_currentMouseGlobalBuffer,
                        onAnimationComplete
                    );
                }
                
                function onAnimationComplete():void
                {
                    // Make sure dragged part is visible
                    if (m_widgetDragSystem.getWidgetSelected())
                    {
                        m_widgetDragSystem.getWidgetSelected().alpha = 1.0;
                    }
                }
                
                // Note that we want the indentation to appear on top of the background of a document node
                // if the background exists. Always assume background image is at the lowest index of
                // the display hierarchy.
                var indexToAddBlankTo:int = 0;
                if (m_currentHitTextAsButton.parent is DocumentView)
                {
                    var parentDocumentView:DocumentView = m_currentHitTextAsButton.parent as DocumentView;
                    indexToAddBlankTo = (parentDocumentView.node.backgroundImage != null) ? 1 : 0;
                }
                m_currentHitTextAsButton.parent.addChildAt(m_currentHitTextAsBlank, indexToAddBlankTo);
                
                // Remove the image of the text as a button, it is no longer needed in any case
                m_currentHitTextAsButton.removeFromParent();
                m_currentTextAsLineTexture.dispose();
                m_currentTextAsLineTexture = null;
            }
            
            if (m_currentHitDocumentView != null)
            {
                // On drag, the original view always becomes not visible
                m_currentHitDocumentView.visible = false;
            }
        }
        
        private function onReleaseText(event:Event, params:Object):void
        {
            var view:DocumentView = params["view"];
            // Clear data in the mouse interaction component
            this.toggleMouseSelectedForView(view, false);
            
            // TODO: By default play a smoother animation and the text returning
            // It should be possible to reconfigure what happens at this point via a callback
            // (i.e. other scripts can override what happens when a dragged text is released,
            // necessary if the behavior requires more context than what is provided here. For
            // example if the dragged object was a card and it was dropped onto the deck it should
            // disappear completely from the text. In other cases it should pop back)
            if (m_draggedContentFromParagraph.viewCopy != null)
            {
                m_draggedContentFromParagraph.reset();
            }
            
            // On release without a drag, we remove the button background on the selected text
            if (m_currentHitDocumentView != null)
            {
                m_onReleaseCallback(m_currentHitTextAsButton, m_currentHitTextAsBlank, m_currentHitDocumentView);
            }
            
            // Kill the global member variables, external scripts are responsible for maintaining
            m_currentHitDocumentView = null;
            m_currentHitTextAsBlank = null;
            m_currentHitTextAsButton = null;
            m_currentHitExpressionValue = null;
            
            if (m_currentTextAsLineTexture != null)
            {
                m_currentTextAsLineTexture.dispose();
                m_currentTextAsLineTexture = null;
            }
        }
        
        /**
         * Default behavior when text is released, it will immediately remove the blank indentation
         * and restore the visibility of the original view
         * 
         * This function should be replaced with something else.
         */
        private function defaultReleaseText(buttonDisplay:DisplayObject, 
                                            blankIndentDisplay:DisplayObject, 
                                            originalView:DocumentView):void
        {
            originalView.visible = true;
            buttonDisplay.removeFromParent(true);
            blankIndentDisplay.removeFromParent(true);
        }
        
        /**
         * Helper function that marks the mouse component for a view with an id to have been
         * selected or unselected. This is needed so external scripts can check whether a particular
         * part of the text content has been selected.
         */
        private function toggleMouseSelectedForView(view:DocumentView, 
                                                    isSelected:Boolean):void
        {
            var viewIds:Vector.<String> = new Vector.<String>();
            this.getIdsContainingView(view, viewIds);
            
            var i:int;
            var mouseComponent:MouseInteractableComponent;
            for (i = 0; i < viewIds.length; i++)
            {
                mouseComponent = m_textArea.componentManager.getComponentFromEntityIdAndType(
                    viewIds[i], 
                    MouseInteractableComponent.TYPE_ID
                ) as MouseInteractableComponent;
                
                if (mouseComponent != null)
                {
                    mouseComponent.selectedThisFrame = isSelected;
                }
            }
        }
        
        private function getIdsContainingView(view:DocumentView, 
                                              outIds:Vector.<String>):void
        {
            var currentView:DocumentView = view;
            
            while (currentView != null)
            {
                if (currentView.node.id != null)
                {
                    outIds.push(currentView.node.id);
                }
                currentView = currentView.parentView;
            }
        }
    }
}