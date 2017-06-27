package wordproblem.engine.text
{
    import flash.geom.Rectangle;
    import flash.text.TextFormat;
    
    import feathers.display.Scale3Image;
    import feathers.display.Scale9Image;
    import feathers.textures.Scale3Textures;
    import feathers.textures.Scale9Textures;
    
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.textures.Texture;
    
    import wordproblem.engine.constants.Alignment;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.text.model.DivNode;
    import wordproblem.engine.text.model.DocumentNode;
    import wordproblem.engine.text.model.ImageNode;
    import wordproblem.engine.text.model.ParagraphNode;
    import wordproblem.engine.text.model.SpanNode;
    import wordproblem.engine.text.model.TextNode;
    import wordproblem.engine.text.view.DocumentView;
    import wordproblem.engine.text.view.DummyTextView;
    import wordproblem.engine.text.view.ImageView;
    import wordproblem.engine.text.view.SpanView;
    import wordproblem.engine.text.view.TextView;
    import wordproblem.resource.AssetManager;

    /**
     * Factory responsible for converting the document node model into concrete views and
     * appriately laying out those views
     */
    public class TextViewFactory
    {
        private static const PUNCUATION_CHARACTERS:Array = [".", ",", "?", "!", ";"];
        private static const TEXT_HACK_HEIGHT:Number = 5; // Padding between the lines
        
        private var m_assetManager:AssetManager;
        private var m_expressionSymbolMap:ExpressionSymbolMap;
        private var m_measuringTextForWhitespace:MeasuringTextField;
        
        /**
         * Sort of hacky, we need some counter to keep track of whether views in a paragraph
         * are on the same line. The line number for each view gets set to this value.
         */
        private var m_currentLineNumber:int;
        
        /**
         *
         * @param assetManager
         *      Used to fetch all loaded textures
         * @param expressionSymbolMap
         *      Used to fetch the textures created dynamically to represent the cards
         */
        public function TextViewFactory(assetManager:AssetManager, 
                                        expressionSymbolMap:ExpressionSymbolMap)
        {
            m_assetManager = assetManager;
            m_expressionSymbolMap = expressionSymbolMap;
            m_measuringTextForWhitespace = new MeasuringTextField();
            m_measuringTextForWhitespace.text = " ";
        }
        
        public function createView(node:DocumentNode):DocumentView
        {
            var documentView:DocumentView = _createView(node, new Rectangle(), new Rectangle(node.width));
            
            // Remember original dimensions as its possible that post processing may modify
            // width and height
            documentView.totalHeight = documentView.height;
            documentView.totalWidth = documentView.width;
            documentView.x = node.x;
            documentView.y = node.y;
            
            // Call the post process rendering method on the root view
            // Perform post processing on the view mainly to handle visibility
            // of views. We remove them as children so they do not contribute to the
            // dimensions
            //documentView.visit();
            
            return documentView;
        }
        
        private function _createView(rootNode:DocumentNode, 
                                     floatLeftBounds:Rectangle, 
                                     floatRightBounds:Rectangle):DocumentView
        {
            // Any valid text format is one of div, paragraph, and image (remember page is just a div)
            // A div requires creating a new container and then recursing on all children
            // A paragraph requires using a special layout algorithm for text.
            // An image requires creating the node immediately
            var compositeView:DocumentView;
            if (rootNode is DivNode)
            {
                const divNode:DivNode = rootNode as DivNode;
                compositeView = createDivView(divNode);
            }
            else if (rootNode is ImageNode)
            {
                const imageNode:ImageNode = rootNode as ImageNode;
                compositeView = createImageView(imageNode);
            }
            else if (rootNode is ParagraphNode)
            {
                m_currentLineNumber = 1;
                
                const paragraphNode:ParagraphNode = rootNode as ParagraphNode;
                compositeView = createParagraphView(paragraphNode, floatLeftBounds, floatRightBounds);
            }
            
            if (rootNode.backgroundImage != null)
            {
                // The background image must scale to fit dimensions of the node
                var widthToSet:Number = (rootNode.width > -1) ? rootNode.width : compositeView.width;
                var heightToSet:Number = (rootNode.height > -1) ? rootNode.height : compositeView.height;
                widthToSet += rootNode.paddingLeft + rootNode.paddingRight;
                heightToSet += rootNode.paddingTop + rootNode.paddingBottom;
                
                const backgroundImage:DisplayObject = this.createImageFromProperties(widthToSet, heightToSet, rootNode.backgroundImage, rootNode.background9Slice);
                
                // Background images will ignore padding values.
                //backgroundImage.x -= rootNode.paddingLeft;
                //backgroundImage.y -= rootNode.paddingTop;
                compositeView.addChildAt(backgroundImage, 0);
            }
            
            return compositeView;
        }
        
        private function createDivView(divNode:DivNode):DocumentView
        {
            // The floating values for this div are completely self contained, they are to be
            // discarded as soon as the div has been created.
            const floatLeftBounds:Rectangle = new Rectangle(0, 0, 0, 0);
            const floatRightBounds:Rectangle = new Rectangle(divNode.width, 0, 0, 0);
            
            const divContainer:DocumentView = new DocumentView(divNode);
            const divChildren:Vector.<DocumentNode> = divNode.children;
            
            // Only gets incremented when non-floating components are added
            var xPosition:Number = 0;
            
            // For relative positioning this counter is essential is figuring out how to
            // properly list the items vertically. Only gets incremented when non-floating
            // components are added. It will determine the next yPosition for floating elements
            var yPosition:Number = 0;
            
            // Now we will need to layout the components within this div
            // Note that the coordinates of all direct children are relative to that of this div container.
            const layoutType:String = divNode.getLayout();
            for (var divIndex:int = 0; divIndex < divChildren.length; divIndex++)
            {
                
                // The float bounds are relative to the parent container of the floating object we need
                // to convert them so they become relative to the paragraphs frame of reference
                // to do this we need to know beforehand where the container has to go
                const divChild:DocumentNode = divChildren[divIndex];
                var divChildView:DocumentView = _createView(divChild, floatLeftBounds, floatRightBounds);
                var divChildViewWidth:Number = divChildView.width;
                const divChildViewHeight:Number = divChildView.height;
                
                if (layoutType == DivNode.LAYOUT_RELATIVE)
                {
                    // If the child view has a float property set we immediately attempt to append it as
                    // far left or right as we can within this container.
                    if (divChild.float == Alignment.LEFT)
                    {
                        divChildView.x = floatLeftBounds.right + divChild.paddingLeft;
                        divChildView.y = divChild.y + divChild.paddingTop;
                        
                        // Merge the existing float left bounds with new floated child
                        floatLeftBounds.width += divChildViewWidth + divChild.paddingRight + divChild.paddingLeft;
                        floatLeftBounds.height = Math.max(floatLeftBounds.height, divChildViewHeight);
                    }
                    else if (divChild.float == Alignment.RIGHT)
                    {
                        const rightFloatHorizontalWidth:Number = (divChildViewWidth + divChild.paddingRight + divChild.paddingLeft);
                        divChildView.x = floatRightBounds.left - rightFloatHorizontalWidth;
                        divChildView.y = divChild.y + divChild.paddingTop; 
                        
                        // Merge the existing float right bounds with the new floated child
                        floatRightBounds.width += rightFloatHorizontalWidth;
                        floatRightBounds.x -= rightFloatHorizontalWidth;
                        floatRightBounds.height = Math.max(floatRightBounds.height, divChildViewHeight);
                    }
                    else
                    {
                        // No float means we attempt to add the object to the normal
                        // document flow, which aligns each object verticaly
                        divChildView.x = divChild.paddingLeft;
                        divChildView.y = yPosition + divChild.paddingTop;
                        xPosition = divChildView.x + divChildViewWidth + divChild.paddingRight;
                        yPosition = divChildView.y + divChildViewHeight + divChild.paddingBottom;
                    }
                }
                    // Absolute layout mean we just put the child views in the coordinates specified in the file
                else
                {
                    divChildView.x = divChild.x;
                    divChildView.y = divChild.y;
                }
                
                divChildView.parentView = divContainer;
                divContainer.addChildView(divChildView);
            }
            
            // Handle padding with the div itself
            divContainer.pivotX -= divNode.paddingLeft;
            divContainer.pivotY -= divNode.paddingTop;
            
            return divContainer;
        }
        
        private function createImageView(imageNode:ImageNode):DocumentView
        {
            // View the correct path to fetch the image texture
            // Currently assuming that images have an id which links to the
            // asset manager
            // We assume that non-embedded images were loaded prior to the level start and
            // are available in the asset manager
            const image:DisplayObject = this.createImageFromProperties(imageNode.width, imageNode.height, imageNode.src);

            const viewWrapper:DocumentView = new ImageView(imageNode, image);
            return viewWrapper;
        }
        
        /**
         * Create a starling display object image from a set of properties as defined in
         * wordproblem.engine.text.TextParserUtil
         * 
         * @param width
         *      If non-negative, change the default width of the image
         * @param height
         *      If non-negative, change the default height of the image
         * @param imageProperties
         *      Details about how the image should be constructed
         * @param nineSlicePadding
         *      Padding list ordered top,right,bottom,left if we want to 9 slice the image
         */
        private function createImageFromProperties(width:int, 
                                                   height:int, 
                                                   imageProperties:Object, 
                                                   nineSlicePadding:Vector.<int>=null):DisplayObject
        {
            var image:DisplayObject
            
            const name:String = imageProperties.name;
            const type:String = imageProperties.type;
            if (type == "symbol")
            {
                image = m_expressionSymbolMap.getCardFromSymbolValue(name);
                
                // Move registration point back to top-left
                image.pivotX = 0;
                image.pivotY = 0;
            }
            else
            {
                const originalTexture:Texture = m_assetManager.getTexture(name);
                
                if (nineSlicePadding != null)
                {
                    const scale9Object:Object = imageProperties.nineSlice;
                    
                    // Create nine-slice texture and use that as the image
                    // Note nine-slice breaks if the width to change to is less than the width of the original
                    // texture. Same goes for height.
                    // If both height and width are smaller, don't use any slicing
                    var targetWidthSmaller:Boolean = (width < originalTexture.width);
                    var targetHeightSmaller:Boolean = (height < originalTexture.height);
                    
                    if (targetWidthSmaller && targetHeightSmaller)
                    {
                        image = new Image(originalTexture);
                    }
                    else if (targetHeightSmaller)
                    {
                        var scale3Texture:Scale3Textures = new Scale3Textures(originalTexture, nineSlicePadding[0], nineSlicePadding[2], "horizontal");
                        image = new Scale3Image(scale3Texture);
                    }
                    else if (targetWidthSmaller)
                    {
                        scale3Texture = new Scale3Textures(originalTexture, nineSlicePadding[1], nineSlicePadding[3], "vertical");
                        image = new Scale3Image(scale3Texture);
                    }
                    else
                    {
                        const scale9Texture:Scale9Textures = new Scale9Textures(originalTexture, new Rectangle(
                            nineSlicePadding[0],
                            nineSlicePadding[1],
                            originalTexture.width - nineSlicePadding[1] - nineSlicePadding[3],
                            originalTexture.height - nineSlicePadding[0] - nineSlicePadding[2]
                        ));
                        image = new Scale9Image(scale9Texture);
                    }
                }
                else
                {
                    image = new Image(originalTexture);
                }
            }
            
            // If only one of width or height set, uniformly scale to that size
            // If both set then fit those exact dimensions
            if (width != -1 && height != -1)
            {
                image.width = width;
                image.height = height;
            }
            else if (width != -1 || height != -1)
            {
                var scaleFactor:Number = (width != -1) ? 
                    width / image.width : height / image.height;
                image.scaleX = image.scaleY = scaleFactor;
            }
            
            return image;
        }
        
        private function createParagraphView(paragraphNode:ParagraphNode, 
                                             floatLeftBounds:Rectangle, 
                                             floatRightBounds:Rectangle):DocumentView
        {
            // Paragraph nodes are like a special layout case
            const paragraphContainer:DocumentView = new DocumentView(paragraphNode);
            const paragraphChildren:Vector.<DocumentNode> = paragraphNode.children;
            const textFormat:TextFormat = new TextFormat(
                paragraphNode.fontName, 
                paragraphNode.fontSize, 
                paragraphNode.fontColor
            );
            var outCreatedViews:Vector.<DocumentView> = new Vector.<DocumentView>();
            for (var childIndex:int = 0; childIndex < paragraphChildren.length; childIndex++)
            {
                const paragraphChild:DocumentNode = paragraphChildren[childIndex];
                createParagraphChildViews(paragraphChild, textFormat, outCreatedViews);
            }
            
            const outActualCreateViews:Vector.<DocumentView> = new Vector.<DocumentView>();
            const paragraphBounds:Rectangle = new Rectangle(paragraphNode.paddingLeft, paragraphNode.paddingTop, paragraphNode.width, 0);
            
            // As part of the layout phase a paragraph, we need to determine what spacing we want in between lines
            // The font style for the total paragraph will determine the default height pixel
            // By applying the multiplier we have a accurate pixel value that should separate each line.
            const measuringTextField:MeasuringTextField = new MeasuringTextField();
            measuringTextField.defaultTextFormat = textFormat;
            measuringTextField.text = "Text to Measure";
            
            const spaceBetweenTopsOfLines:Number = paragraphNode.lineHeight * measuringTextField.textHeight;
            layoutParagraphChildViews(outCreatedViews, outActualCreateViews, paragraphBounds, floatLeftBounds, floatRightBounds, spaceBetweenTopsOfLines + 5);
            
            outCreatedViews = new Vector.<DocumentView>();
            _revisedAttachParagraphChildViewsToSpans(paragraphNode, outActualCreateViews, outCreatedViews);
            
            var i:int = 0;
            for (i = 0; i < outCreatedViews.length; i++)
            {
                paragraphContainer.addChildView(outCreatedViews[i]);
            }
            
            return paragraphContainer;
        }
        
        /**
         * From the document node structure create initial placeholder views. The position and layering of these
         * views will need to be handled in a separate function.
         * 
         * @param node
         *      The node to create placeholder views for
         * @param textFormat
         *      The text style to apply to the given node (only here because text nodes don't have their style set)
         * @param outViews
         *      An output list of the views created, ordered the same as a left to right traversal of the leaf nodes.
         */
        private function createParagraphChildViews(node:DocumentNode,
                                                   textFormat:TextFormat,
                                                   outViews:Vector.<DocumentView>):void
        {
            
            if (node is ImageNode)
            {
                const imageView:DocumentView = this.createImageView(node as ImageNode);
                outViews.push(imageView);
            }
            else if (node is SpanNode)
            {
                // A span view is really just a display container, do not need to create
                // immediately. We first layout the images and text and then in a later
                // pass determine which views should be nested in the span
                const spanNode:SpanNode = node as SpanNode;
                
                // Create and add children of the span to the list
                const spanFormat:TextFormat = new TextFormat(
                    spanNode.fontName, 
                    spanNode.fontSize, 
                    spanNode.fontColor
                );
                
                var i:int;
                var numChildren:int = node.children.length;
                for (i = 0; i < numChildren; i++)
                {
                    createParagraphChildViews(node.children[i], spanFormat, outViews);
                }
            }
            else if (node is TextNode)
            {
                const textNode:TextNode = node as TextNode;
                const textView:DocumentView = new DummyTextView(textNode, textFormat);
                outViews.push(textView);
            }
            else
            {
                throw new Error("TextPageView::Invalid node type contained within a paragraph tag: " + node.id);
            }
        }
        
        /**
         * Layout created views of a paragraph, the coordinates are relative to the frame of the paragraph container.
         * 
         * IMPORTANT: This layout assumes a uniform distance between all lines the paragraph. Imagine a bunch of rectangles
         * stacked on top of each other to form the paragraph contents. The height of these rectangles will all be the same.
         * This means it is possible for contents of a line to leak over to other lines if the height is not
         * big enough. It is up to the data provider to specify a nice looking spacing.
         * 
         * @param views
         *      A list of text and image views. The ordering in the list exactly indicates the left to right, top to
         *      bottom layout of the objects
         * @param outViews
         *      Output of all the actual views that should be placed inside the paragraph
         * @param parentContentBounds
         *      The bounds of where content is allowed inside the view. Values relative to the parent view object.
         *      X is the starting point for each line, y is the top padding, width is the max allowed width of the container.
         */
        private function layoutParagraphChildViews(views:Vector.<DocumentView>,
                                                   outViews:Vector.<DocumentView>,
                                                   parentContentBounds:Rectangle,
                                                   floatLeftBounds:Rectangle, 
                                                   floatRightBounds:Rectangle, 
                                                   pixelSpaceBetweenLines:Number):void
        {
            // Used to measure width of text content
            const measuringTextField:MeasuringTextField = new MeasuringTextField();
            
            const centerInline:Boolean = true;                      // Should the content in a line be centered
            var currentLineTopY:Number = parentContentBounds.y;     // The top vertical bound of the current line
            var currentX:Number = yWithinRectangle(pixelSpaceBetweenLines, floatLeftBounds) ?
                floatLeftBounds.right : parentContentBounds.x;      // Acts like a caret to keep track of where to put the next content horizontally
            var i:int;
            var numViews:int = views.length;
            var view:DocumentView;
            for (i = 0; i < numViews; i++)
            {
                view = views[i];
                
                if (view is DummyTextView)
                {
                    // We need to look at each text view and figure out whether they need to be further segmented to
                    // correctly wrap around lines.
                    const textView:DummyTextView = view as DummyTextView;
                    const textNode:TextNode = view.node as TextNode;
                    const measuringTextFormat:TextFormat = textView.getTextFormat();
                    measuringTextField.defaultTextFormat = measuringTextFormat;
                    m_measuringTextForWhitespace.setTextFormat(measuringTextFormat);
                    
                    // Break up content into individual words, check how many can fit into the current line
                    const textContent:String = textNode.content;
                    const wordBuffer:Array = textContent.split(" ");
                    const numWords:int = wordBuffer.length;
                    var wordIndex:int;
                    var word:String;
                    // If the preceding view was an image add a space to the text 
                    var wordsForCurrentLine:String = (i - 1 > 0 && views[i - 1] is ImageView) ? " " : "";
                    var textMeasuredWidth:int;
                    var textMeasuredHeight:int;
                    var maxAllowedX:int = getMaxAllowedX(currentLineTopY, parentContentBounds, pixelSpaceBetweenLines, floatRightBounds);
                    for (wordIndex = 0; wordIndex < numWords; wordIndex++)
                    {
                        word = wordBuffer[wordIndex];
                        if (word == " " || word == "")
                        {
                            continue;
                        }
                        
                        measuringTextField.text = wordsForCurrentLine + word;
                        textMeasuredHeight = measuringTextField.textHeight + TEXT_HACK_HEIGHT;
                        
                        // If adding a new word overflows the horizontal bounds, then we create a new text view
                        // with that previous word removed. The content added should just fit within the allowable bounds
                        if (measuringTextField.textWidth + currentX > maxAllowedX)
                        {
                            var addedCurrentWordToPreviousLine:Boolean = false;
                            
                            // Puncuation marks should stay on the previous line
                            if (PUNCUATION_CHARACTERS.indexOf(word) >= 0)
                            {
                                wordsForCurrentLine += word;
                                addedCurrentWordToPreviousLine = true;
                            }
                            
                            if (wordsForCurrentLine.length > 0)
                            {
                                // Strip out the trailing space if it exists
                                if (wordsForCurrentLine.charAt(wordsForCurrentLine.length - 1) == " ")
                                {
                                    wordsForCurrentLine = wordsForCurrentLine.substr(0, wordsForCurrentLine.length - 1);
                                }
                                
                                measuringTextField.text = wordsForCurrentLine;
                                textMeasuredWidth = measuringTextField.textWidth + m_measuringTextForWhitespace.textWidth * 2.5;
                                var newTextView:TextView = this.createTextView(
                                    view.node,
                                    wordsForCurrentLine,
                                    measuringTextFormat,
                                    0, 0, textMeasuredWidth, textMeasuredHeight
                                );
                                positionView(newTextView, measuringTextField.textWidth, textMeasuredHeight);
                                newTextView.lineNumber = m_currentLineNumber++; 
                            }
                            
                            // Since the last word we added will not fit on the current line, we need to move to the
                            // start of the next line. Note that since we are not guaranteed that there was any content
                            // at all, we cannot rely on position view to do anything
                            // No content left on this line, we need to immediately shift downward
                            currentLineTopY += pixelSpaceBetweenLines;
                            currentX = yWithinRectangle(currentLineTopY + pixelSpaceBetweenLines, floatLeftBounds) ?
                                floatLeftBounds.right : parentContentBounds.x;
                            maxAllowedX = getMaxAllowedX(currentLineTopY, parentContentBounds, textMeasuredHeight, floatRightBounds);
                            
                            if (!addedCurrentWordToPreviousLine)
                            {
                                wordsForCurrentLine = word + " ";
                            }
                            else
                            {
                                wordsForCurrentLine = "";
                            }
                        }
                        // Add the new word and continue
                        else
                        {
                            wordsForCurrentLine = measuringTextField.text;
                            if (wordIndex < numWords - 1)
                            {
                                wordsForCurrentLine += " ";
                            }
                        }
                    }
                    
                    // In the previous loop we always added a space after every word. This is not correct in the
                    // case where the next view is more text and the starting character is a puncuation. In that case
                    // we strip out that last space.
                    // Get the next view and check that it is text. Then check if the first character is some puncuation
                    var addSpaceForNextView:Boolean = false;
                    if (i + 1 < numViews && views[i + 1] is DummyTextView)
                    {
                        const nextTextNode:TextNode = views[i + 1].node as TextNode;
                        if (nextTextNode.content.length > 0)
                        {
                            addSpaceForNextView = true;
                            const firstCharacter:String = nextTextNode.content.charAt(0);
                            var j:int;
                            for (j = 0; j < PUNCUATION_CHARACTERS.length; j++)
                            {
                                if (firstCharacter == PUNCUATION_CHARACTERS[j])
                                {
                                    // Strip out the trailing space if it exists
                                    if (wordsForCurrentLine.charAt(wordsForCurrentLine.length - 1) == " ")
                                    {
                                        wordsForCurrentLine = wordsForCurrentLine.substr(0, wordsForCurrentLine.length - 1);
                                    }
                                    
                                    addSpaceForNextView = false;
                                    break;
                                }
                            }
                        }                    
                    }
                    
                    // Also don't add a space if word already ends in a space
                    if (wordsForCurrentLine.charAt(wordsForCurrentLine.length - 1) == " ")
                    {
                        addSpaceForNextView = false;
                    }
                    
                    // Add the last chunk
                    measuringTextField.text = wordsForCurrentLine;
                    textMeasuredWidth = measuringTextField.textWidth + m_measuringTextForWhitespace.textWidth * 2.5;
                    textMeasuredHeight = measuringTextField.textHeight + TEXT_HACK_HEIGHT;
                    newTextView = this.createTextView(
                        view.node,
                        wordsForCurrentLine,
                        measuringTextFormat,
                        0, 0, textMeasuredWidth, textMeasuredHeight
                    );
                    
                    // The way xml is parsed, words that are separated by an element like
                    // left text <span>spanned</span> right text
                    // will not preserve the white space, no space after parsing after 'left text'
                    // or before 'right text'. Need to inject this space by repositioning things.
                    
                    var boundsOfCurrentTextToAdd:Number = measuringTextField.textWidth;
                    if (addSpaceForNextView)
                    {
                        boundsOfCurrentTextToAdd += m_measuringTextForWhitespace.textWidth
                    }
                    positionView(newTextView, boundsOfCurrentTextToAdd, textMeasuredHeight);
                    newTextView.lineNumber = m_currentLineNumber;
                }
                else if (view is ImageView)
                {
                    const imageView:ImageView = view as ImageView;
                    positionView(imageView, imageView.width, imageView.height);
                }
                else
                {
                    // Error: An invalid view type was added in the list
                    throw new Error("Invalid view type during layout: " + view.node.getTagName());
                }
                
                /**
                 * Internal functional that actually modifies the x and y values of a view to correctly
                 * position it.
                 * 
                 * @param measuredWidth
                 *      Bounding width to treat the view with
                 * @param measuredHeight
                 *      Bound height to treat the view with
                 */
                function positionView(view:DocumentView, measuredWidth:int, measuredHeight:int):void
                {
                    maxAllowedX = getMaxAllowedX(currentLineTopY, parentContentBounds, measuredHeight, floatRightBounds);
                    if (measuredWidth + currentX <= maxAllowedX)
                    {
                        
                    }
                    // For an image we wrap to the next line
                    // With the new line, the content sets the starting height bounds so it always fits vertically.
                    // No need to center in this case
                    else if (view is ImageView)
                    {
                        // Right now this only occurs for images
                        // If we have text that is wrapping that is handled in the text layout algorithm
                        currentX = yWithinRectangle(currentLineTopY + pixelSpaceBetweenLines, floatLeftBounds) ?
                            floatLeftBounds.right : parentContentBounds.x;
                        currentLineTopY += pixelSpaceBetweenLines;
                        
                        view.lineNumber = ++m_currentLineNumber;
                    }
                    
                    // Set coordinates of the given target view
                    view.x = currentX;
                    view.y = (centerInline) ? 
                        currentLineTopY + (pixelSpaceBetweenLines - measuredHeight) * 0.5 : currentLineTopY;
                    currentX += measuredWidth;
                    
                    // HACK: If image is the first part of a paragrah, space is not added at the end
                    // so that the bit of text butts up against it. Add extra padding
                    if (i == 0 && view is ImageView)
                    {
                        currentX += 5;
                    }
                    
                    outViews.push(view);
                }
            }
        }
        
        private function getMaxAllowedX(currentLineTopY:int, 
                                        parentContentBounds:Rectangle, 
                                        viewHeight:int,
                                        floatRightBounds:Rectangle):int
        {
            var isParagraphChildHittingFloat:Boolean = (this.yWithinRectangle(currentLineTopY, floatRightBounds) || 
                this.yWithinRectangle(currentLineTopY + viewHeight, floatRightBounds));
            var maxAllowedX:Number = (isParagraphChildHittingFloat && floatRightBounds.width > 0) ?
                floatRightBounds.left : parentContentBounds.width;
            return maxAllowedX;
        }
        
        /**
         * After all parts of a paragraph have been successfully created and positioned, we need to
         * recursively attach them to appropriate span containers as well as add the nodes to the paragraph.
         * If sets up the parent child view links
         * 
         * @param node
         *      The document node to fetch
         * @param views
         *      A list of all terminal views, either text or images that are part of the paragraph.
         * @param outViews
         *      The list of views that are associated the corresponding document node
         * @return
         *      The index of the next view in the given list to examine
         */
        private function _revisedAttachParagraphChildViewsToSpans(node:DocumentNode, 
                                                                  views:Vector.<DocumentView>,
                                                                  outViews:Vector.<DocumentView>):void
        {
            if (node.children == null || node.children.length == 0)
            {
                findViewsMatchingNode(node, views, outViews);
            }
            else
            {
                // For every non-terminal, which is just the root paragraph and spans,
                // create a buffer to store all views that should go inside of it.
                const outViewsForNonTerminal:Vector.<DocumentView> = new Vector.<DocumentView>();
                const childrenNodes:Vector.<DocumentNode> = node.children;
                const numChildren:int = childrenNodes.length;
                var i:int;
                var childNode:DocumentNode;
                for (i = 0; i < numChildren; i++)
                {
                    childNode = childrenNodes[i];
                    
                    // Get the view (or views for multiple text pieces) associated with the child node
                    // Note that this could also another span
                    _revisedAttachParagraphChildViewsToSpans(childNode, views, outViewsForNonTerminal);
                }
                
                
                if (node is SpanNode)
                {
                    // Create a span view and retroactively add all the image, text, and other span
                    // nodes inside of it.
                    const spanView:SpanView = new SpanView(node as SpanNode);
                    
                    // Add all views of the span children into the span container
                    var viewInSpan:DocumentView;
                    for (i = 0; i < outViewsForNonTerminal.length; i++)
                    {
                        viewInSpan = outViewsForNonTerminal[i];
                        
                        // The coordinates of the span matches those of its first children.
                        // We need to readjust the coordinates of the children from the reference of
                        // the parent to the reference of the span.
                        var spanX:int;
                        var spanY:int;
                        if (i == 0)
                        {
                            spanX = viewInSpan.x;
                            spanY = viewInSpan.y;
                            spanView.x = spanX;
                            spanView.y = spanY;
                        }
                        
                        viewInSpan.x -= spanX;
                        viewInSpan.y -= spanY;
                        
                        spanView.addChildView(viewInSpan);
                    }
                    outViews.push(spanView);
                }
                else
                {
                    // Dump everything as a child for the paragraph view
                    for (i = 0; i < outViewsForNonTerminal.length; i++)
                    {
                        outViews.push(outViewsForNonTerminal[i]);
                    }
                    outViewsForNonTerminal.length = 0;
                }
            }
        }
        
        /**
         * Find the views bound to a particular node from a given set of views
         */
        private function findViewsMatchingNode(node:DocumentNode, 
                                               views:Vector.<DocumentView>, 
                                               outViews:Vector.<DocumentView>):void
        {
            var i:int;
            var view:DocumentView;
            const numViews:int = views.length;
            for (i = 0; i < numViews; i++)
            {
                view = views[i];
                if (view.node == node)
                {
                    outViews.push(view);
                }
            }
        }
        
        private function createTextView(textNode:DocumentNode, 
                                        text:String,
                                        textFormat:TextFormat,
                                        x:Number, 
                                        y:Number, 
                                        width:Number, 
                                        height:Number):TextView
        {
            const textView:TextView = new TextView(textNode);
            textView.setTextContents(
                text, 
                width, 
                height, 
                textFormat.font, 
                textFormat.color as uint, 
                textFormat.size as int
            );
            textView.x = x;
            textView.y = y;
            
            return textView;
        }
        
        private function xWithinRange(x:Number, rectangle:Rectangle):Boolean
        {
            return (x >= rectangle.left && x <= rectangle.right);
        }
        
        private function yWithinRectangle(y:Number, rectangle:Rectangle):Boolean
        {
            return (y >= rectangle.top && y <= rectangle.bottom);
        }
    }
}