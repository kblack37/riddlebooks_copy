package wordproblem.creator
{
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.events.Event;
    import flash.events.FocusEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import flash.text.TextFieldType;
    import flash.text.TextFormat;
    
    import dragonbox.common.time.Time;
    
    import feathers.display.Scale9Image;
    import feathers.textures.Scale9Textures;
    
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.textures.Texture;
    
    import wordproblem.display.Layer;
    import wordproblem.engine.text.GameFonts;
    import wordproblem.engine.text.MeasuringTextField;
    import wordproblem.resource.AssetManager;
    
    /**
     * The editable text consists of a stage3d display and a flash display which
     * is necessary to get the native flash textfield to function.
     */
    public class EditableTextArea extends Layer
    {
        private var m_globalPointBuffer:Point;
        private var m_localPointBuffer:Point;
        private var m_whiteSpaceRegex:RegExp;
        
        /**
         * Need to specify the bounds of this area because the dimensions of the content
         * are constantly changing and might not show any bounds. Want this value to be fixed.
         */
        private var m_constraints:Rectangle;
        
        private var m_editModeOn:Boolean;
        
        /**
         * Since we are using the native flash textfield, we need to paste it onto the flash stage
         * for it to display correctly.
         */
        private var m_flashStage:Stage;
        
        private var m_assetManager:AssetManager;
        
        /**
         * Content should be segmented into separate text blocks which can be sized and positioned independently
         * of one another.
         * 
         * The native flash text field has all the functionality that we would for the editable portion
         * of the text.
         * 
         * Keep in mind that this will appear ontop of ALL stage3d content so we need to properly swap it
         * with stage3d version so it appears with the correct layering.
         */
        private var m_textBlocks:Vector.<TextField>;
        private var m_textBlockInitialEditableSettings:Vector.<Boolean>;
        
        /**
         * This container should mirror the position and dimensions of the overall text area, it is used
         * as the canvas to place native flash textfields
         */
        private var m_textBlockLayer:flash.display.Sprite;
        
        /**
         * When we want the text area contents to layer correctly with the stage3d content, we
         * need to use this texture (a snapshot of the text) and paste it in place of the textfield.
         */
        private var m_textAreaStaticImage:Image;
        
        /**
         * This is the layer to add the custom highlights to, it needs to appear below everything
         */
        private var m_highlightCanvas:starling.display.Sprite;
        
        /**
         * A collection of data related to spanning highlight
         * The key is
         * id: Unique id binding to the highlight
         * 
         * The value is another object
         * Each object here has properties
         * start: index of the starting character
         * end: index of the last character
         * color: color of the highlight
         * display: Vector.<DisplayObject> that compose the highlight
         * blockIndex: index of the block containing the highlighted content
         */
        private var m_highlightedTextObjects:Object;
        
        /**
         * If true then the current highlighting of words within a text block needs to
         * be updated.
         * 
         * Each index links to a text block and contains a boolean value.
         * The number of elements in this list MUST match the the number of text blocks
         */
        private var m_refreshHighlightPending:Vector.<Boolean>;
        
        /**
         * The number of seconds that need to elapse before a refresh
         * of the word highlighting is executed.
         * 
         * If at zero, the refresh should occur at that very moment.
         */
        private var m_refreshCountdownSeconds:Vector.<Number>;
        private const REFRESH_TIME:Number = 0.25;
        
        /**
         * The texture from which all the highlight backgrounds should sample from
         */
        private var m_textBackgroundTexture:Scale9Textures;
        
        /**
         * We have two types of highlighting, one usage is to highlight every line
         */
        private var m_textEmphasizeTexture:Scale9Textures;
        
        /**
         * When dealing with the whole event buffering scripts there is a situation where on its update
         * function a script will call a function that fires an event that many scripts want to buffer.
         * This occurs instantaneously, if scripts are in a list then the ones before the target one that ran the function
         * will not see the event until the next frame. HOWEVER, scripts afterwards will immediately buffer then
         * process the event on that very frame. This completely messes up the ordering of event process as scripts higher
         * in priority do not process the event first.
         * 
         * The solution is to buffer dispatches so they are sent on the on the start of this update loop
         */
        private var m_pendingEventsToDispatch:Vector.<String>;
        
        /**
         * The common text style properties to apply to all blocks
         */
        private var m_currentTextFormat:TextFormat;
        
        /**
         * At any given point in time, keep track of the text display component
         * that the user has manually focused on. This is a short cut to allow us 
         */
        private var m_textBlockInFocus:TextField;
        
        public function EditableTextArea(flashStage:Stage, 
                                         assetManager:AssetManager, 
                                         startingFontName:String, 
                                         startingFontSize:int, 
                                         startingFontColor:uint)
        {
            super();
            
            m_globalPointBuffer = new Point();
            m_localPointBuffer = new Point();
            m_flashStage = flashStage;
            m_assetManager = assetManager;
            m_constraints = new Rectangle();
            
            this.addEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage);
            this.addEventListener(starling.events.Event.REMOVED_FROM_STAGE, onRemovedFromStage);
            
            // Need to make it easy to customize
            m_currentTextFormat = new TextFormat(startingFontName, startingFontSize, startingFontColor);
            m_textBlocks = new Vector.<TextField>();
            m_textBlockInitialEditableSettings = new Vector.<Boolean>();
            m_refreshHighlightPending = new Vector.<Boolean>();
            m_refreshCountdownSeconds = new Vector.<Number>();
            
            m_textBlockLayer = new flash.display.Sprite();
            
            if (this.stage != null)
            {
                m_flashStage.addChild(m_textBlockLayer);
            }
            
            m_highlightCanvas = new starling.display.Sprite();
            addChild(m_highlightCanvas);
            
            m_highlightedTextObjects = {};
            m_whiteSpaceRegex = /[\s\r\n]/;
            
            m_textBackgroundTexture = new Scale9Textures(assetManager.getTexture("card_background_square"), new Rectangle(8, 8, 16, 16));
            
            var scale9Delta:Number = 2;
            var emphasizeTexture:Texture = assetManager.getTexture("halo");
            m_textEmphasizeTexture = new Scale9Textures(emphasizeTexture, new Rectangle(
                (emphasizeTexture.width - scale9Delta) * 0.5,
                (emphasizeTexture.height - scale9Delta) * 0.5,
                scale9Delta,
                scale9Delta
            ));
            m_pendingEventsToDispatch = new Vector.<String>();
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            this.removeEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage);
            this.removeEventListener(starling.events.Event.REMOVED_FROM_STAGE, onRemovedFromStage);
            
            // Destroy all the textblocks and the static image
            for each (var textBlock:TextField in m_textBlocks)
            {
                textBlock.addEventListener(flash.events.Event.CHANGE, onTextChange);
            }
        }
        
        /**
         * Add a new chunk of text that can either take in new initial content
         * (MUST BE CALLED AT LEAST ONCE for any content to be showed)
         * 
         * @param editable
         *      If true, the user should be able to modify the contents of the block
         * @param selectable
         *      If true, the user can select parts of the text which is key for highlighting.
         *      This essentially controls whether the block can be highlighted by the user.
         */
        public function addTextBlock(maxWidth:Number, maxHeight:Number, editable:Boolean, selectable:Boolean):void
        {
            var newTextBlock:TextField = new TextField();
            newTextBlock.width = maxWidth;
            newTextBlock.height = maxHeight;
            newTextBlock.type = (editable) ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
            newTextBlock.selectable = selectable;
            newTextBlock.wordWrap = true;
            newTextBlock.multiline = true;
            newTextBlock.border = true;
            newTextBlock.borderColor = 0xFFFFFF;
            
            // TODO: Need to figure out  how many characters should fit in this block
            newTextBlock.maxChars = getMaxCharacterThatCanFitInBlock(maxWidth, maxHeight, m_currentTextFormat);
            
            newTextBlock.embedFonts = GameFonts.getFontIsEmbedded(m_currentTextFormat.font);
            newTextBlock.addEventListener(flash.events.Event.CHANGE, onTextChange);
            newTextBlock.addEventListener(flash.events.FocusEvent.FOCUS_IN, onTextFocusIn);
            newTextBlock.addEventListener(flash.events.FocusEvent.FOCUS_OUT, onTextFocusOut);
            newTextBlock.defaultTextFormat = m_currentTextFormat;
            
            // TODO: What is the position of the text block?
            m_textBlocks.push(newTextBlock);
            m_textBlockInitialEditableSettings.push(editable);
            m_textBlockLayer.addChild(newTextBlock);
            
            m_refreshHighlightPending.push(false);
            m_refreshCountdownSeconds.push(-1);
        }
        
        public function layoutTextBlocks():void
        {
            var yOffset:Number = 0;
            for each (var textBlock:TextField in m_textBlocks)
            {
                textBlock.y = yOffset;
                yOffset += textBlock.height;
            }
        }
        
        /**
         * This function is exposed for the instances where we want the text area to show some
         * intial content. (Like when we want to show an example word problem.)
         * 
         * @param blockIndex
         *      Which block should the given text be added to
         */
        public function setText(value:String, blockIndex:int):void
        {
            var targetTextBlock:TextField = m_textBlocks[blockIndex];
            targetTextBlock.text = value;
        }
        
        /**
         * HACK: The only reason this object is exposed is so other scripts are
         * able to figure out what parts of the text have been already tagged.
         * 
         * DO NOT modify the contents of the returned object
         * 
         * @return
         *      An object mapping from highlight id to another object with properties about
         *      the highlight.
         */
        public function getHighlightTextObjects():Object
        {
            return m_highlightedTextObjects;
        }
        
        /**
         * For a given highlight id get the text content that is covered
         * 
         * @return
         *      null if the highlight id doesn't match to an existing highlight
         */
        public function getTextContentForId(highlightId:String):String
        {
            var content:String = null;
            if (m_highlightedTextObjects.hasOwnProperty(highlightId))
            {
                var highlightTextObject:Object = m_highlightedTextObjects[highlightId];
                var blockIndex:int = highlightTextObject["blockIndex"];
                
                if (m_textBlocks.length > 0 && m_textBlocks.length > blockIndex)
                {
                    var totalContent:String = m_textBlocks[blockIndex].text;
                    content = totalContent.substring(highlightTextObject.start, highlightTextObject.end + 1);
                }
            }
            
            return content;
        }
        
        /**
         * Delete a named highlight from the text, removes its display and property information.
         * 
         * @param dispatchRefresh
         *      HACKY: Used by external scripts, if the delete is part of an isolated action then a refresh
         *      event should be dispatched and it should be true.
         *      When used internally it is usually part of a batch of changes and the refresh is sent only at
         *      the end, which is the normal case when it is false.
         */
        public function deleteHighlight(id:String, dispatchRefresh:Boolean=false):void
        {
            if (m_highlightedTextObjects.hasOwnProperty(id))
            {
                var highlightObjectToDelete:Object = m_highlightedTextObjects[id];
                disposeHighlightsInObject(highlightObjectToDelete);
                delete m_highlightedTextObjects[id];
                
                if (dispatchRefresh)
                {
                    m_pendingEventsToDispatch.push(ProblemCreateEvent.HIGHLIGHT_REFRESHED);
                }
            }
        }
        
        /**
         * Since this component contains both stage3d and regular flash stage content, we actually have
         * two parts we need to re-arrange.
         * 
         * The native text area needs to be shifted around in the global space.
         */
        public function setPosition(x:Number, y:Number):void
        {
            this.x = x;
            this.y = y;
            
            m_localPointBuffer.x = 0;
            m_localPointBuffer.y = 0;
            this.localToGlobal(m_localPointBuffer, m_globalPointBuffer);
            
            // Since the text block layer must be added to the stage, it is
            // part of the global reference frame
            m_textBlockLayer.x = m_globalPointBuffer.x;
            m_textBlockLayer.y = m_globalPointBuffer.y;
        }
        
        public function setFontColor(value:uint):void
        {
            // Note that setting the format changes existing text, while change the defaul affect new text
            setTextFormatProperties(value, m_currentTextFormat.size as int, m_currentTextFormat.font);
        }
        
        public function setFontSize(value:int):void
        {
            setTextFormatProperties(m_currentTextFormat.color as uint, value, m_currentTextFormat.font);
        }
        
        public function setFontFamily(value:String):void
        {
            setTextFormatProperties(m_currentTextFormat.color as uint, m_currentTextFormat.size as int, value);
        }
        
        /**
         * Get the current text format (useful to other text parts that match
         * the same style as the content in this component)
         */
        public function getTextFormat():TextFormat
        {
            return m_currentTextFormat;
        }
        
        public function setTextFormatProperties(color:uint, fontSize:int, fontFamily:String):void
        {
            var fontColorChanged:Boolean = m_currentTextFormat.color as uint != color;
            var fontSizeChanged:Boolean = m_currentTextFormat.size as int != fontSize;
            var fontFamilyChanged:Boolean = m_currentTextFormat.font != fontFamily;
            if (fontColorChanged || fontSizeChanged || fontFamilyChanged)
            {
                for each (var textBlock:TextField in m_textBlocks)
                {
                    var newFormat:TextFormat = new TextFormat(fontFamily, fontSize, color);
                    textBlock.setTextFormat(newFormat);
                    textBlock.defaultTextFormat = newFormat;
                    textBlock.embedFonts = GameFonts.getFontIsEmbedded(newFormat.font);
                    var maxChars:int = getMaxCharacterThatCanFitInBlock(textBlock.width, textBlock.height, newFormat);
                }
                m_currentTextFormat.color = color;
                m_currentTextFormat.size = fontSize;
                m_currentTextFormat.font = fontFamily;
                redrawHighlightsAtCurrentIndices();
                
                // If the static image is present, need to refresh it to show the
                // new text style.
                // Delete old texture and replace it with new one sampled from the modified text
                if (m_textAreaStaticImage != null)
                {
                    m_textAreaStaticImage.removeFromParent(true);
                    m_textAreaStaticImage.texture.dispose();
                    
                    var extraSpacingForBorder:Number = 5;
                    var bitmapData:BitmapData = new BitmapData(getConstraints().width + extraSpacingForBorder, getConstraints().height + extraSpacingForBorder, true, 0x000000);
                    bitmapData.draw(m_textBlockLayer);
                    
                    m_textAreaStaticImage = new Image(Texture.fromBitmapData(bitmapData, false));
                    addChild(m_textAreaStaticImage);
                }
                
                // If font name or font size has changed, the highlight display may need to be redrawn
                if (fontSizeChanged || fontFamilyChanged)
                {
                    redrawHighlightsAtCurrentIndices();
                }
            }
        }
        
        public function getConstraints():Rectangle
        {
            return m_constraints;
        }
        
        /**
         * Set the maximum boundaries of the content that fits in this component
         */
        public function setConstraints(width:Number, height:Number):void
        {
            m_constraints.width = width;
            m_constraints.height = height;
        }
        
        /**
         * One major problem with using the native flash textfield is that it appears ontop of any
         * stage3d content. This means if we have a dragged icon, it would appear underneath the text.
         * 
         * The solution would be to render a snapshot of the text to a starling texture and toggle off the
         * visibility of the text area. The text itself would become static at this stage but the layering
         * would be correct.
         * 
         * Thus the text area will need to know to switch between an editing and a view mode.
         * 
         * @param editModeOn
         *      If true then the user should be able to freely modify the text
         */
        public function toggleEditMode(editModeOn:Boolean):void
        {
            m_editModeOn = editModeOn;
            if (m_editModeOn && m_textAreaStaticImage != null)
            {
                m_textAreaStaticImage.removeFromParent(true);
                m_textAreaStaticImage.texture.dispose();
                m_textAreaStaticImage = null;
            }
            else if (!m_editModeOn)
            {
                // Draw the native textfield to a bitmap
                var extraSpacingForBorder:Number = 5;
                var bitmapData:BitmapData = new BitmapData(getConstraints().width + extraSpacingForBorder, getConstraints().height + extraSpacingForBorder, true, 0x000000);
                bitmapData.draw(m_textBlockLayer);
                
                m_textAreaStaticImage = new Image(Texture.fromBitmapData(bitmapData, false));
                addChild(m_textAreaStaticImage);
            }
            
            // Toggle visibility of the text field so it looks invisible, still needs
            // to show up
            m_textBlockLayer.alpha = (m_editModeOn) ? 1 : 0.01;
            
            // Make sure the selection area is cleared on the switch
            for each (var textBlock:TextField in m_textBlocks)
            {
                var previousEndSelection:int = textBlock.selectionEndIndex;
                textBlock.setSelection(previousEndSelection, previousEndSelection);
            }
            
            // Toggle the ability to edit all the text blocks
            for (var i:int = 0; i < m_textBlocks.length; i++)
            {
                textBlock = m_textBlocks[i];
                if (m_textBlockInitialEditableSettings[i])
                {
                    textBlock.type = (m_editModeOn) ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
                }
            }
        }
        
        public function update(time:Time):void
        {
            // Dispatch buffered events at the start of the update for synchronization purposes
            if (m_pendingEventsToDispatch.length > 0)
            {
                while (m_pendingEventsToDispatch.length > 0)
                {
                    dispatchEventWith(m_pendingEventsToDispatch.pop());
                }
            }
            
            var secondsElapsed:Number = time.currentDeltaSeconds;
            var numBlocks:int = m_textBlocks.length;
            var blockIndex:int;
            for (blockIndex = 0; blockIndex < numBlocks; blockIndex++)
            {
                if (m_refreshHighlightPending[blockIndex])
                {
                    m_refreshCountdownSeconds[blockIndex] -= secondsElapsed;
                    if (m_refreshCountdownSeconds[blockIndex] <= 0)
                    {
                        // Break the new content down into words
                        // The goal is to recalculate the new start and end CHARACTER indices by attempting
                        // to use the previous start and end WORD indices and applying them to the new content.
                        var wordProperties:Vector.<Object> = this.divideContentsIntoWordIndices(blockIndex);
                        var orderedHighlightIds:Vector.<String> = new Vector.<String>();
                        for (var highlightId:String in m_highlightedTextObjects)
                        {
                            if (m_highlightedTextObjects[highlightId].blockIndex == blockIndex)
                            {
                                orderedHighlightIds.push(highlightId);
                            }
                        }
                        
                        // TODO: This is ignoring what block index a highlight belongs to.
                        
                        var highlightIdsToDelete:Object = {};
                        var i:int;
                        var numHighlights:int = orderedHighlightIds.length;
                        for (i = 0; i < numHighlights; i++)
                        {
                            highlightId = orderedHighlightIds[i];
                            var highlightObject:Object = m_highlightedTextObjects[highlightId];
                            var prevWordStartIndex:int = highlightObject.startWordIndex;
                            var prevWordEndIndex:int = highlightObject.endWordIndex;
                            
                            // If the previous start word index now passes the total number of words now,
                            // the highlight no longer starts in a visible place so it should be deleted
                            if (prevWordStartIndex >= wordProperties.length)
                            {
                                // DELETE
                                highlightIdsToDelete[highlightId] = true;
                            }
                            // If the new end index no longer ends in a visible place, it needs to be
                            // shortened
                            else if (prevWordEndIndex >= wordProperties.length)
                            {
                                prevWordEndIndex = wordProperties.length - 1;
                                highlightObject.endWordIndex = prevWordEndIndex;
                            }
                            
                            // Check if any overlap occurs between the highlight we are examining now
                            // and the ones we have already modified before
                            // If we find any, we need to trim the to start and ends
                            // If this highlight becomes fully contained in another, then it must be deleted completely
                            var j:int;
                            for (j = 0; j < i; j++)
                            {
                                var otherHighlightId:String = orderedHighlightIds[j];
                                if (!highlightIdsToDelete.hasOwnProperty(otherHighlightId))
                                {
                                    var otherHighlightObject:Object = m_highlightedTextObjects[otherHighlightId];
                                    
                                    // The start is wedged between an existing highlight, must be shifted to the right
                                    if (otherHighlightObject.endWordIndex >= highlightObject.startWordIndex &&
                                        otherHighlightObject.startWordIndex <= highlightObject.startWordIndex)
                                    {
                                        highlightObject.startWordIndex = otherHighlightObject.endWordIndex + 1;
                                    }
                                    
                                    // The end is wedged between an existing highlight, must be shifted to the left
                                    if (otherHighlightObject.startWordIndex <= highlightObject.endWordIndex &&
                                        otherHighlightObject.endWordIndex >= highlightObject.endWordIndex)
                                    {
                                        highlightObject.endWordIndex = otherHighlightObject.startWordIndex - 1;   
                                    }
                                    
                                    // If after shifting the end is now before the start, then we could not
                                    // easily resolve the overlap. Just delete this highlight
                                    // Also occurs if any of the indices do not fall inside a valid bounds
                                    if (highlightObject.startWordIndex > highlightObject.endWordIndex || highlightObject.startWordIndex < 0 ||
                                        highlightObject.endWordIndex >= wordProperties.length)
                                    {
                                        highlightIdsToDelete[highlightId] = true;
                                        break;
                                    }
                                }
                            }
                        }
                        
                        // Discard highlights marked for delete
                        for (var highlightIdToDelete:String in highlightIdsToDelete)
                        {
                            deleteHighlight(highlightIdToDelete);
                        }
                        
                        // After the new parameters have been determined we can now go about redrawing everything
                        for (highlightId in m_highlightedTextObjects)
                        {
                            if (m_highlightedTextObjects[highlightId].blockIndex == blockIndex)
                            {
                                // Remove old highlights
                                highlightObject = m_highlightedTextObjects[highlightId];
                                var displays:Vector.<DisplayObject> = highlightObject.display;
                                for each (var display:DisplayObject in displays)
                                {
                                    display.removeFromParent(true);
                                }
                                
                                // Refresh to fit new locations
                                var newStartCharacterIndex:int = wordProperties[highlightObject.startWordIndex].start;
                                var newEndCharacterIndex:int = wordProperties[highlightObject.endWordIndex].end;
                                highlightObject.start = newStartCharacterIndex;
                                highlightObject.end = newEndCharacterIndex;
                                displays.length = 0;
                                drawHighlight(newStartCharacterIndex, newEndCharacterIndex, highlightObject.color, highlightObject.blockIndex, m_textBackgroundTexture, displays);
                            }
                        }
                        m_pendingEventsToDispatch.push(ProblemCreateEvent.HIGHLIGHT_REFRESHED);
                        m_refreshHighlightPending[blockIndex] = false;
                    }
                }
            }
        }
        
        public function getHtmlText():String
        {
            // For each text block create a temporary textfield
            // This data is not stored within the original text field since we do not want to contaminate
            // the original. The extra textfield is used to create the transitory html tagged version
            // of the text that other scripts can fetch to apply transformations to it.
            var i:int;
            var temporaryTextBlocks:Vector.<TextField> = new Vector.<TextField>();
            var numTextBlocks:int = m_textBlocks.length;
            for (i = 0; i < numTextBlocks; i++)
            {
                var temporaryBlock:TextField = new TextField();
                temporaryBlock.multiline = true;
                temporaryBlock.wordWrap = true;
                temporaryTextBlocks.push(temporaryBlock);
                temporaryBlock.htmlText = m_textBlocks[i].htmlText
            }
            
            // Inject the 'highlighted' portions directly into the text
            for (var highlightId:String in m_highlightedTextObjects)
            {
                var textObject:Object = m_highlightedTextObjects[highlightId];
                var startIndex:int = textObject.start;
                var endIndex:int = textObject.end;
                temporaryBlock = temporaryTextBlocks[textObject.blockIndex];
                temporaryBlock.setTextFormat(new TextFormat(null, null, null, null, null, null, highlightId), startIndex, endIndex + 1);
            }
            
            // Aggregate all the text blocks into a single bundle of text
            var totalTextContent:String = "";
            for (i = 0; i < numTextBlocks; i++)
            {
                totalTextContent += temporaryTextBlocks[i].htmlText;
            }
            
            return totalTextContent;
        }
        
        /**
         * Get whether there is any text that is directly underneath the given point
         * 
         * @param outData
         *      If not null, fill this object with properties of the block index and character index
         *      that was hit.
         *      key-values are
         *      blockIndex: int of the text block, -1 if not found
         *      charIndex: int of the character the point is under, -1 if not found
         */
        public function getIsTextUnderPoint(localX:Number, localY:Number, outData:Object=null):Boolean
        {
            if (outData != null)
            {
                outData.blockIndex = -1;
                outData.charIndex = -1;
            }
            
            var textUnderPoint:Boolean = false;
            var i:int;
            var numTextBlocks:int = m_textBlocks.length;
            for (i = 0; i < numTextBlocks; i++)
            {
                var textBlock:TextField = m_textBlocks[i];
                
                // Note the coordinates for this function is relative to the textfield itself
                // Need to transform the starting coordinates to the textfield coordinate space
                var localXInBlock:Number = localX - textBlock.x - m_textBlockLayer.x;
                var localYInBlock:Number = localY - textBlock.y - m_textBlockLayer.y;
                var characterIndexAtPoint:int = textBlock.getCharIndexAtPoint(localXInBlock, localYInBlock);
                if (characterIndexAtPoint > -1)
                {
                    // We have an issue where the character index can be received even when the point is not within
                    // the bounds of that character. Seems to occur when the text field is larger that the text, the
                    // last line of text has an area stretching to the bottom of the text field where the getCharIndexAtPoint
                    // returns a valid index.
                    var charBounds:Rectangle = textBlock.getCharBoundaries(characterIndexAtPoint);
                    if (charBounds.contains(localXInBlock, localYInBlock))
                    {
                        textUnderPoint = true;
                        if (outData != null)
                        {
                            outData.blockIndex = i;
                            outData.charIndex = characterIndexAtPoint;
                        }
                    }
                    break;
                }
            }
            
            return textUnderPoint;
        }

        /**
         * Highlight a single word at the given mouse point (coordinates relative to this
         * text area, so (0, 0) would be the top left of the total text area)
         */
        public function highlightWordAtPoint(localX:Number, localY:Number, color:uint, id:String):void
        {
            // Need to figure out which text block is hit by the given coordinates
            var outData:Object = {};
            if (getIsTextUnderPoint(localX, localY, outData))
            {
                var blockIndex:int = outData.blockIndex;
                var charIndex:int = outData.charIndex;
                if (blockIndex >= 0 && charIndex >= 0)
                {
                    highlightWordsAtIndices(charIndex, charIndex + 1, color, id, blockIndex, true);
                }
            }
        }
        
        /**
         * HACKY: this relies on the built in functionality of the textfield to handle selection
         * of characters (i.e. click and drag causes a black colored highlight to appear over
         * dragged characters)
         */
        public function highlightWordsAtCurrentSelection(color:uint, id:String, modifyOverlappingHighlights:Boolean):void
        {
            // Get the text block that is in focus
            var textBlock:TextField = m_textBlockInFocus;
            var blockIndex:int = m_textBlocks.indexOf(textBlock);
            
            // Ignore if the text area is empty
            if (textBlock != null && textBlock.text != "")
            {
                // To get the word encompassed by the selection
                // and right from the end until we reach white space. Everything in between
                var startIndex:int = textBlock.selectionBeginIndex;
                var endIndex:int = textBlock.selectionEndIndex;
                highlightWordsAtIndices(startIndex, endIndex, color, id, blockIndex, modifyOverlappingHighlights);
            }
        }
        
        /**
         * Highlight the words in the text area that fall within the given start and end character indices
         * 
         * @param modifyOverlappingHighlights
         *      If true then the new highlight specified should adjust other highlights that it overlaps.
         *      In the end no highlights should overlap.
         */
        public function highlightWordsAtIndices(startIndex:int, 
                                                endIndex:int, 
                                                color:uint, 
                                                id:String, 
                                                textBlockIndex:int, 
                                                modifyOverlappingHighlights:Boolean):void
        {
            // HACK: To prevent timing issue, if a refresh is pending do not allow a highlight to occur
            if (m_refreshHighlightPending[textBlockIndex])
            {
                return;
            }
            
            var textBlock:TextField = m_textBlocks[textBlockIndex];
            var content:String = textBlock.text;
            
            // If every character in the selection is whitespace, don't do anything
            // Doesn't make sense to highlight anything
            // Otherwise we get a bug where the space along with the first characters before and after the space
            // are highlighted
            var allWhiteSpaceInSelection:Boolean = true;
            for (i = startIndex; i <= endIndex; i++)
            {
                if (content.charAt(i).search(m_whiteSpaceRegex) == -1)
                {
                    allWhiteSpaceInSelection = false;
                    break;
                }
            }
            
            if (allWhiteSpaceInSelection)
            {
                return;
            }
            
            var totalCharacters:int = content.length;
            
            // Keep going left from the start until reach whitespace character
            var characterAtLeftEdge:String = content.charAt(startIndex);
            while (characterAtLeftEdge.search(m_whiteSpaceRegex) == -1 && startIndex > 0)
            {
                startIndex--;
                characterAtLeftEdge = content.charAt(startIndex);
            }
            
            // For cases where we start at whitespace (or where we
            while (characterAtLeftEdge.search(m_whiteSpaceRegex) != -1 && startIndex < totalCharacters - 1)
            {
                startIndex++;
                characterAtLeftEdge = content.charAt(startIndex);
            }
            
            var characterAtRightEdge:String = content.charAt(endIndex);
            while (characterAtRightEdge.search(m_whiteSpaceRegex) == -1 && endIndex < totalCharacters - 1)
            {
                endIndex++;
                characterAtRightEdge = content.charAt(endIndex);
            }
            
            while (characterAtRightEdge.search(m_whiteSpaceRegex) != -1 && endIndex > 0)
            {
                endIndex--;
                characterAtRightEdge = content.charAt(endIndex);
            }
            
            // Edge case is drag selection starts at the end,
            // since the highlight requires inclusive end index
            if (endIndex == totalCharacters)
            {
                endIndex = totalCharacters - 1;
            }
            
            // Delete previous highlight for the same id
            var redrawHighlight:Boolean = true;
            for (var highlightId:String in m_highlightedTextObjects)
            {
                if (highlightId == id )
                {
                    var highlightObject:Object = m_highlightedTextObjects[highlightId];
                    
                    // If the highlight covers the same range of characters there is no need to redraw it
                    disposeHighlightsInObject(highlightObject);
                }
            }
            
            // With the proper index bounds set we can now highlight the appropriate portion of
            // text
            var outDisplayObjects:Vector.<DisplayObject> = new Vector.<DisplayObject>();
            drawHighlight(startIndex, endIndex, color, textBlockIndex, m_textBackgroundTexture, outDisplayObjects);
            
            // Figure out the start and end word indices
            // This is necessary in case we need to re-adjust the highlights if the user
            // modifies the text.
            var wordProperties:Vector.<Object> = divideContentsIntoWordIndices(textBlockIndex);
            var numWords:int = wordProperties.length;
            var i:int;
            var startWordIndex:int = 0;
            var endWordIndex:int = 0;
            for (i = 0; i < numWords; i++)
            {
                var wordProperty:Object = wordProperties[i];
                if (wordProperty.start == startIndex)
                {
                    startWordIndex = i;
                }
                
                if (wordProperty.end == endIndex)
                {
                    endWordIndex = i;
                }
            }
            
            var newHighlightObject:Object = {
                start: startIndex,
                end: endIndex,
                color: color,
                display: outDisplayObjects,
                startWordIndex: startWordIndex,
                endWordIndex: endWordIndex,
                blockIndex: textBlockIndex
            };
            m_highlightedTextObjects[id] = newHighlightObject;
            
            // Need to resolve case where the new highlight might overlap with old ones in the same block
            // Overlap occurs if the start and/or end word indices of the existing highlight
            // fall in between the start and end of the existing highlight
            if (modifyOverlappingHighlights)
            {
                for (highlightId in m_highlightedTextObjects)
                {
                    var otherHighlightTextObject:Object = m_highlightedTextObjects[highlightId];
                    if (otherHighlightTextObject.blockIndex == textBlockIndex && highlightId != id)
                    {
                        var existingHighlightObject:Object = m_highlightedTextObjects[highlightId];
                        var otherStartWordIndex:int = existingHighlightObject.startWordIndex;
                        var otherEndWordIndex:int = existingHighlightObject.endWordIndex;
                        
                        var otherStartWordContainedInNew:Boolean = otherStartWordIndex >= startWordIndex && otherStartWordIndex <= endWordIndex;
                        var otherEndWordContainedInNew:Boolean = otherEndWordIndex >= startWordIndex && otherEndWordIndex <= endWordIndex;
                        
                        var newStartWordContainedInOther:Boolean = startWordIndex >= otherStartWordIndex && startWordIndex <= otherEndWordIndex;
                        var newEndWordContainedInOther:Boolean = endWordIndex >= otherStartWordIndex && endWordIndex <= otherEndWordIndex;
                        
                        // If the existing highlight is fully contained in the new one just delete it outright
                        if (otherStartWordContainedInNew && otherEndWordContainedInNew)
                        {
                            deleteHighlight(highlightId);
                        }
                        // Need to perform some trimming to the left or the right
                        else if (newStartWordContainedInOther || newEndWordContainedInOther)
                        {
                            // The rule to trimming is we will try to leave as many words as possible
                            // for the trimming with ties being broken total characters in the words and
                            // then defaulting to the left side if it is tied again
                            
                            // We just calculate what the new spans would be trimming to the left and to the right
                            var startLeftTrimmed:int = otherStartWordIndex;
                            var endLeftTrimmed:int = startWordIndex - 1;
                            var numWordsLeftTrim:int = endLeftTrimmed - startLeftTrimmed + 1;
                            
                            // Calculate
                            var startRightTrimmed:int = endWordIndex + 1;
                            var endRightTrimmed:int = otherEndWordIndex;
                            var numWordsRightTrim:int = endRightTrimmed - startRightTrimmed + 1;
                            
                            var useLeftTrim:Boolean = (newStartWordContainedInOther && numWordsLeftTrim >= numWordsRightTrim);
                            var selectedTrimmedStart:int = (useLeftTrim) ? startLeftTrimmed : startRightTrimmed;
                            var selectedTrimmedEnd:int = (useLeftTrim) ? endLeftTrimmed : endRightTrimmed;
                            
                            // Adjust the word and character indices and redraw highligh
                            existingHighlightObject.startWordIndex = selectedTrimmedStart;
                            existingHighlightObject.endWordIndex = selectedTrimmedEnd;
                            existingHighlightObject.start = wordProperties[selectedTrimmedStart].start;
                            existingHighlightObject.end = wordProperties[selectedTrimmedEnd].end;
                            disposeHighlightsInObject(existingHighlightObject);
                            drawHighlight(existingHighlightObject.start, existingHighlightObject.end, existingHighlightObject.color,
                                textBlockIndex,
                                m_textBackgroundTexture,
                                existingHighlightObject.display);
                        }
                    }
                }
            }
            
            m_pendingEventsToDispatch.push(ProblemCreateEvent.HIGHLIGHT_REFRESHED);
        }
        
        private var m_highlightsAlreadyAdded:Boolean = false;
        private var m_blinkTweens:Vector.<Tween> = new Vector.<Tween>();
        
        /**
         * Add blink highlight to the entirety of the text
         */
        public function addEmphasisToAllText():void
        {
            // Need to be able to easily control the add/removal of the highlights as well
            // as an animation so it looks like it is pulsing
            if (!m_highlightsAlreadyAdded)
            {
                var outHighlights:Vector.<DisplayObject> = new Vector.<DisplayObject>();
                var numBlocks:int = m_textBlocks.length;
                var i:int;
                for (i = 0; i < numBlocks; i++)
                {
                    var textBlock:TextField = m_textBlocks[i];
                    if (textBlock.text.length > 0)
                    {
                        drawHighlight(0, textBlock.text.length - 1, 0xFFFFFF, i, m_textEmphasizeTexture, outHighlights);
                    }
                }
                
                for each (var highlight:DisplayObject in outHighlights)
                {
                    var blinkTween:Tween = new Tween(highlight, 1);
                    blinkTween.fadeTo(0.2);
                    blinkTween.repeatCount = 0;
                    blinkTween.reverse = true;
                    Starling.juggler.add(blinkTween);
                    
                    m_blinkTweens.push(blinkTween);
                }
                
                m_highlightsAlreadyAdded = true;
            }
        }
        
        /**
         * Remove the blink highlight from the whole text.
         */
        public function removeEmphasisFromAllText():void
        {
            for each (var tween:Tween in m_blinkTweens)
            {
                Starling.juggler.remove(tween);
                (tween.target as DisplayObject).removeFromParent(true);
            }
            m_blinkTweens.length = 0;
            
            m_highlightsAlreadyAdded = false;
        }
        
        /**
         *
         * @param startIndex
         *      The index of the starting character to span from inclusive
         * @param endIndex
         *      The index of the ending character to span to inclusive
         */
        private function drawHighlight(startIndex:int, 
                                       endIndex:int, 
                                       color:uint,
                                       textBlockIndex:int,
                                       texture:Scale9Textures,
                                       outDisplayObjects:Vector.<DisplayObject>=null):void
        {
            // The highlight may be composed of multiple parts depending on if the content
            // spans multiple lines.
            var textBlock:TextField = m_textBlocks[textBlockIndex];
            var startLineIndex:int = textBlock.getLineIndexOfChar(startIndex);
            var endLineIndex:int = textBlock.getLineIndexOfChar(endIndex);
            var contents:String = textBlock.text;
            
            // For each line we draw a box (there is always at least one line)
            // IMPORTANT a line might contain whitespace at the very start or end
            // DO NOT include that whitespace, we adjust indices if they are on white space
            var i:int;
            for (i = startLineIndex; i <= endLineIndex; i++)
            {
                var validLineToHighlight:Boolean = true;
                var knownFirstCharIndexInLine:int = textBlock.getLineOffset(i);
                var knownLastCharIndexInLine:int = knownFirstCharIndexInLine + textBlock.getLineLength(i) - 1;
                
                var firstCharIndexInLine:int = (i == startLineIndex) ?
                    startIndex : knownFirstCharIndexInLine;
                while (contents.charAt(firstCharIndexInLine).search(m_whiteSpaceRegex) != -1)
                {
                    firstCharIndexInLine++;
                    if (firstCharIndexInLine > knownLastCharIndexInLine)
                    {
                        validLineToHighlight = false;
                        break;
                    }
                }
                
                var lastCharIndexInLine:int = (i == endLineIndex) ?
                    endIndex : knownLastCharIndexInLine;
                while (contents.charAt(lastCharIndexInLine).search(m_whiteSpaceRegex) != -1)
                {
                    lastCharIndexInLine--;
                    if (lastCharIndexInLine < knownFirstCharIndexInLine)
                    {
                        validLineToHighlight = false;
                        break;
                    }
                }
                
                if (validLineToHighlight)
                {
                    // Create the bounds from the first and last characters in the line to form
                    // a rectangular background
                    var firstCharacterBounds:Rectangle = textBlock.getCharBoundaries(firstCharIndexInLine);
                    var lastCharacterBounds:Rectangle = textBlock.getCharBoundaries(lastCharIndexInLine);
                    var backgroundBounds:Rectangle = firstCharacterBounds.union(lastCharacterBounds);
                    var backgroundImage:Scale9Image = new Scale9Image(texture);
                    
                    // Since the highlight has a black border, need to add padding everything so the border does not
                    // interfere with the text.
                    var extraPadding:Number = 3;
                    backgroundImage.width = backgroundBounds.width + extraPadding * 2;
                    backgroundImage.height = backgroundBounds.height + extraPadding * 2;
                    backgroundImage.color = color;
                    
                    // Need to swap between the frame of reference to position the highlight
                    backgroundImage.x = backgroundBounds.x + textBlock.x - extraPadding;
                    backgroundImage.y = backgroundBounds.y + textBlock.y - extraPadding;
                    m_highlightCanvas.addChild(backgroundImage);
                    
                    if (outDisplayObjects != null)
                    {
                        outDisplayObjects.push(backgroundImage);
                    }
                }
            }
        }
        
        /**
         * If a highlight is present on the screen, alterations to the text format require a redraw
         * as the boundaries of the character might shift.
         * 
         * IMPORTANT: This should not be used during instance where the content (and there positions of characters) have
         * been altered since the last redraw was done.
         */
        public function redrawHighlightsAtCurrentIndices():void
        {
            for (var textObjectId:String in m_highlightedTextObjects)
            {
                // The start and end indices should only span entire words
                var textObject:Object = m_highlightedTextObjects[textObjectId];
                var startIndex:int = textObject.start;
                var endIndex:int = textObject.end;
                
                // Remove all previous display objects
                var displayPieces:Vector.<DisplayObject> = textObject.display;
                var j:int;
                for (j = 0; j < displayPieces.length; j++)
                {
                    var displayPiece:DisplayObject = displayPieces[j];
                    displayPiece.removeFromParent(true);
                }
                
                displayPieces.length = 0;
                
                // Redraw new highlight objects at the same word indices
                drawHighlight(startIndex, endIndex, textObject.color, textObject.blockIndex, m_textBackgroundTexture, displayPieces);
            }
        }
        
        /**
         * Helper function to segment the current contents of the text area into
         * words. Each word has a start and end character index
         */
        private function divideContentsIntoWordIndices(blockIndex:int):Vector.<Object>
        {
            var wordProperties:Vector.<Object> = new Vector.<Object>();
            var currentWordObject:Object = {};
            
            var contents:String = m_textBlocks[blockIndex].text;
            var numCharacters:int = contents.length;
            var i:int;
            var lastCharacterIsWhiteSpace:Boolean = true;
            for (i = 0; i < numCharacters; i++)
            {
                var character:String = contents.charAt(i);
                
                // Current character is whitespace
                var currentCharacterIsWhitespace:Boolean = character.search(m_whiteSpaceRegex) != -1;
                if (currentCharacterIsWhitespace)
                {
                    // If last character was not white space, then we are at the end
                    // of the last word
                    if (!lastCharacterIsWhiteSpace && i > 0)
                    {
                        currentWordObject.end = i - 1;
                        wordProperties.push(currentWordObject);
                        currentWordObject = {};
                    }
                }
                // Current character is a valid word character
                else
                {
                    // If last character was spaces or the start then we
                    // are at the start of a new word
                    if (lastCharacterIsWhiteSpace)
                    {
                        currentWordObject.start = i;
                    }
                }
                
                lastCharacterIsWhiteSpace = currentCharacterIsWhitespace;
            }
            
            // Edge case where the last word ends at the very last character
            if (currentWordObject.hasOwnProperty("start") && !currentWordObject.hasOwnProperty("end"))
            {
                currentWordObject.end = i - 1;
                wordProperties.push(currentWordObject);   
            }
            
            return wordProperties;
        }
        
        
        private function onAddedToStage(event:starling.events.Event):void
        {
            m_flashStage.addChild(m_textBlockLayer);
            
            setPosition(this.x, this.y);
        }
        
        private function onRemovedFromStage(event:starling.events.Event):void
        {
            if (m_textBlockLayer.parent != null)
            {
                m_textBlockLayer.parent.removeChild(m_textBlockLayer);
            }
        }
        
        private function disposeHighlightsInObject(highlightObject:Object):void
        {
            if (highlightObject.hasOwnProperty("display"))
            {
                var highlights:Vector.<DisplayObject> = highlightObject.display;
                for each (var highlight:DisplayObject in highlights)
                {
                    highlight.removeFromParent(true);
                }
                highlights.length = 0;
            }
        }
        
        private function onTextFocusIn(event:flash.events.FocusEvent):void
        {
            m_textBlockInFocus = event.currentTarget as TextField;
        }
        
        private function onTextFocusOut(event:flash.events.FocusEvent):void
        {
            var textFieldOutOfFocus:TextField = event.currentTarget as TextField;
            if (m_textBlockInFocus == textFieldOutOfFocus)
            {
                m_textBlockInFocus = null;
            }
        }
        
        private function onTextChange(event:flash.events.Event):void
        {
            var textBlockChanged:TextField = event.currentTarget as TextField;
            var blockIndex:int = m_textBlocks.indexOf(textBlockChanged);
            
            // Whenever the text changes we need to adjust the highlights
            // as the bounds that we used when initially drawing them may not even
            // contain the right characters anymore
            var numHighlights:int = 0;
            for (var id:String in m_highlightedTextObjects)
            {
                numHighlights++;
            }
            
            if (numHighlights > 0)
            {
                // We are checking if the indices specified for the existing highlight
                // still span over complete words
                // On each change we start a slight delay time that gets reset each time
                // the text changes
                m_refreshHighlightPending[blockIndex] = true;
                m_refreshCountdownSeconds[blockIndex] = REFRESH_TIME;
            }
        }
        
        private function getMaxCharacterThatCanFitInBlock(blockWidth:Number, blockHeight:Number, textFormat:TextFormat):int
        {
            // Figure out how many characters can fit in one line.
            // Then figure out how many lines can fit into the block.
            // This should give a rough approximation of the character
            var measuringTextField:MeasuringTextField = new MeasuringTextField();
            measuringTextField.defaultTextFormat = textFormat;
            measuringTextField.text = "W";
            var singleCharacterMaxWidth:Number = measuringTextField.textWidth;
            var singleCharacterMaxHeight:Number = measuringTextField.textHeight;
            var numCharactersInRow:int = Math.floor(blockWidth / singleCharacterMaxWidth);
            var numCharactersInColumn:int = Math.floor(blockHeight / singleCharacterMaxHeight);
            
            return numCharactersInRow * numCharactersInColumn;
        }
    }
}