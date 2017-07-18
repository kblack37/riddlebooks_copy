package wordproblem.engine.text;

import flash.errors.Error;

import flash.geom.Rectangle;
import flash.text.TextFormat;

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
class TextViewFactory
{
    private static var PUNCUATION_CHARACTERS : Array<Dynamic> = [".", ",", "?", "!", ";"];
    private static inline var TEXT_HACK_HEIGHT : Float = 5;  // Padding between the lines  
    
    private var m_assetManager : AssetManager;
    private var m_expressionSymbolMap : ExpressionSymbolMap;
    private var m_measuringTextForWhitespace : MeasuringTextField;
    
    /**
     * Sort of hacky, we need some counter to keep track of whether views in a paragraph
     * are on the same line. The line number for each view gets set to this value.
     */
    private var m_currentLineNumber : Int;
    
    /**
     *
     * @param assetManager
     *      Used to fetch all loaded textures
     * @param expressionSymbolMap
     *      Used to fetch the textures created dynamically to represent the cards
     */
    public function new(assetManager : AssetManager,
            expressionSymbolMap : ExpressionSymbolMap)
    {
        m_assetManager = assetManager;
        m_expressionSymbolMap = expressionSymbolMap;
        m_measuringTextForWhitespace = new MeasuringTextField();
        m_measuringTextForWhitespace.text = " ";
    }
    
    public function createView(node : DocumentNode) : DocumentView
    {
        var documentView : DocumentView = _createView(node, new Rectangle(), new Rectangle(node.width));
        
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
    
    private function _createView(rootNode : DocumentNode,
            floatLeftBounds : Rectangle,
            floatRightBounds : Rectangle) : DocumentView
    {
        // Any valid text format is one of div, paragraph, and image (remember page is just a div)
        // A div requires creating a new container and then recursing on all children
        // A paragraph requires using a special layout algorithm for text.
        // An image requires creating the node immediately
        var compositeView : DocumentView;
        if (Std.is(rootNode, DivNode)) 
        {
            var divNode : DivNode = try cast(rootNode, DivNode) catch(e:Dynamic) null;
            compositeView = createDivView(divNode);
        }
        else if (Std.is(rootNode, ImageNode)) 
        {
            var imageNode : ImageNode = try cast(rootNode, ImageNode) catch(e:Dynamic) null;
            compositeView = createImageView(imageNode);
        }
        else if (Std.is(rootNode, ParagraphNode)) 
        {
            m_currentLineNumber = 1;
            
            var paragraphNode : ParagraphNode = try cast(rootNode, ParagraphNode) catch(e:Dynamic) null;
            compositeView = createParagraphView(paragraphNode, floatLeftBounds, floatRightBounds);
        }
        
        if (rootNode.backgroundImage != null) 
        {
            // The background image must scale to fit dimensions of the node
            var widthToSet : Float = ((rootNode.width > -1)) ? rootNode.width : compositeView.width;
            var heightToSet : Float = ((rootNode.height > -1)) ? rootNode.height : compositeView.height;
            widthToSet += rootNode.paddingLeft + rootNode.paddingRight;
            heightToSet += rootNode.paddingTop + rootNode.paddingBottom;
            
            var backgroundImage : DisplayObject = this.createImageFromProperties(Std.int(widthToSet), Std.int(heightToSet), rootNode.backgroundImage, rootNode.background9Slice);
            
            // Background images will ignore padding values.
            //backgroundImage.x -= rootNode.paddingLeft;
            //backgroundImage.y -= rootNode.paddingTop;
            compositeView.addChildAt(backgroundImage, 0);
        }
        
        return compositeView;
    }
    
    private function createDivView(divNode : DivNode) : DocumentView
    {
        // The floating values for this div are completely self contained, they are to be
        // discarded as soon as the div has been created.
        var floatLeftBounds : Rectangle = new Rectangle(0, 0, 0, 0);
        var floatRightBounds : Rectangle = new Rectangle(divNode.width, 0, 0, 0);
        
        var divContainer : DocumentView = new DocumentView(divNode);
        var divChildren : Array<DocumentNode> = divNode.children;
        
        // Only gets incremented when non-floating components are added
        var xPosition : Float = 0;
        
        // For relative positioning this counter is essential is figuring out how to
        // properly list the items vertically. Only gets incremented when non-floating
        // components are added. It will determine the next yPosition for floating elements
        var yPosition : Float = 0;
        
        // Now we will need to layout the components within this div
        // Note that the coordinates of all direct children are relative to that of this div container.
        var layoutType : String = divNode.getLayout();
        for (divIndex in 0...divChildren.length){
            
            // The float bounds are relative to the parent container of the floating object we need
            // to convert them so they become relative to the paragraphs frame of reference
            // to do this we need to know beforehand where the container has to go
            var divChild : DocumentNode = divChildren[divIndex];
            var divChildView : DocumentView = _createView(divChild, floatLeftBounds, floatRightBounds);
            var divChildViewWidth : Float = divChildView.width;
            var divChildViewHeight : Float = divChildView.height;
            
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
                    var rightFloatHorizontalWidth : Float = (divChildViewWidth + divChild.paddingRight + divChild.paddingLeft);
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
        }  // Handle padding with the div itself  
        
        
        
        divContainer.pivotX -= divNode.paddingLeft;
        divContainer.pivotY -= divNode.paddingTop;
        
        return divContainer;
    }
    
    private function createImageView(imageNode : ImageNode) : DocumentView
    {
        // View the correct path to fetch the image texture
        // Currently assuming that images have an id which links to the
        // asset manager
        // We assume that non-embedded images were loaded prior to the level start and
        // are available in the asset manager
        var image : DisplayObject = this.createImageFromProperties(Std.int(imageNode.width), Std.int(imageNode.height), imageNode.src);
        
        var viewWrapper : DocumentView = new ImageView(imageNode, image);
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
    private function createImageFromProperties(width : Int,
            height : Int,
            imageProperties : Dynamic,
            nineSlicePadding : Array<Int> = null) : DisplayObject
    {
        var image : DisplayObject;
        
        var name : String = imageProperties.name;
        var type : String = imageProperties.type;
        if (type == "symbol") 
        {
            image = m_expressionSymbolMap.getCardFromSymbolValue(name);
            
            // Move registration point back to top-left
            image.pivotX = 0;
            image.pivotY = 0;
        }
        else 
        {
            var originalTexture : Texture = m_assetManager.getTexture(name);
            
            if (nineSlicePadding != null) 
            {
                var scale9Object : Dynamic = imageProperties.nineSlice;
                
                // Create nine-slice texture and use that as the image
                // Note nine-slice breaks if the width to change to is less than the width of the original
                // texture. Same goes for height.
                // If both height and width are smaller, don't use any slicing
                var targetWidthSmaller : Bool = (width < originalTexture.width);
                var targetHeightSmaller : Bool = (height < originalTexture.height);
                
                if (targetWidthSmaller && targetHeightSmaller) 
                {
                    image = new Image(originalTexture);
                }
				// TODO: these were replaced from the feathers library straight to the starling library;
				// images will probably need to be fixed later
                else if (targetHeightSmaller) 
                {
					// note: replaced from Scale3Texture from the feathers library
                    var starlingTexture : Texture = Texture.fromTexture(originalTexture, new Rectangle(
						0,
						nineSlicePadding[0],
						originalTexture.width,
						originalTexture.height - nineSlicePadding[0] - nineSlicePadding[2]));
                    image = new Image(starlingTexture);
                }
                else if (targetWidthSmaller) 
                {
					// note: replaced from scale3Texture from the feathers library
                    var starlingTexture : Texture = Texture.fromTexture(originalTexture, new Rectangle(
						nineSlicePadding[3],
						0,
						originalTexture.width - nineSlicePadding[1] - nineSlicePadding[3],
						originalTexture.height));
                    image = new Image(starlingTexture);
                }
                else 
                {
					// note: replaced from scale9Texture from the feathers library
                    var starlingTexture : Texture = Texture.fromTexture(originalTexture, new Rectangle(
                    nineSlicePadding[0], 
                    nineSlicePadding[1], 
                    originalTexture.width - nineSlicePadding[1] - nineSlicePadding[3], 
                    originalTexture.height - nineSlicePadding[0] - nineSlicePadding[2]
                    ));
                    image = new Image(starlingTexture);
                }
            }
            else 
            {
                image = new Image(originalTexture);
            }
        }  // If both set then fit those exact dimensions    // If only one of width or height set, uniformly scale to that size  
        
        
        
        
        
        if (width != -1 && height != -1) 
        {
            image.width = width;
            image.height = height;
        }
        else if (width != -1 || height != -1) 
        {
            var scaleFactor : Float = ((width != -1)) ? 
            width / image.width : height / image.height;
            image.scaleX = image.scaleY = scaleFactor;
        }
        
        return image;
    }
    
    private function createParagraphView(paragraphNode : ParagraphNode,
            floatLeftBounds : Rectangle,
            floatRightBounds : Rectangle) : DocumentView
    {
        // Paragraph nodes are like a special layout case
        var paragraphContainer : DocumentView = new DocumentView(paragraphNode);
        var paragraphChildren : Array<DocumentNode> = paragraphNode.children;
        var textFormat : TextFormat = new TextFormat(
        paragraphNode.fontName, 
        paragraphNode.fontSize, 
        paragraphNode.fontColor
        );
        var outCreatedViews : Array<DocumentView> = new Array<DocumentView>();
        for (childIndex in 0...paragraphChildren.length){
            var paragraphChild : DocumentNode = paragraphChildren[childIndex];
            createParagraphChildViews(paragraphChild, textFormat, outCreatedViews);
        }
        
        var outActualCreateViews : Array<DocumentView> = new Array<DocumentView>();
        var paragraphBounds : Rectangle = new Rectangle(paragraphNode.paddingLeft, paragraphNode.paddingTop, paragraphNode.width, 0);
        
        // As part of the layout phase a paragraph, we need to determine what spacing we want in between lines
        // The font style for the total paragraph will determine the default height pixel
        // By applying the multiplier we have a accurate pixel value that should separate each line.
        var measuringTextField : MeasuringTextField = new MeasuringTextField();
        measuringTextField.defaultTextFormat = textFormat;
        measuringTextField.text = "Text to Measure";
        
        var spaceBetweenTopsOfLines : Float = paragraphNode.lineHeight * measuringTextField.textHeight;
        layoutParagraphChildViews(outCreatedViews, outActualCreateViews, paragraphBounds, floatLeftBounds, floatRightBounds, spaceBetweenTopsOfLines + 5);
        
        outCreatedViews = new Array<DocumentView>();
        _revisedAttachParagraphChildViewsToSpans(paragraphNode, outActualCreateViews, outCreatedViews);
        
        var i : Int = 0;
        for (i in 0...outCreatedViews.length){
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
    private function createParagraphChildViews(node : DocumentNode,
            textFormat : TextFormat,
            outViews : Array<DocumentView>) : Void
    {
        
        if (Std.is(node, ImageNode)) 
        {
            var imageView : DocumentView = this.createImageView(try cast(node, ImageNode) catch(e:Dynamic) null);
            outViews.push(imageView);
        }
        else if (Std.is(node, SpanNode)) 
        {
            // A span view is really just a display container, do not need to create
            // immediately. We first layout the images and text and then in a later
            // pass determine which views should be nested in the span
            var spanNode : SpanNode = try cast(node, SpanNode) catch(e:Dynamic) null;
            
            // Create and add children of the span to the list
            var spanFormat : TextFormat = new TextFormat(
            spanNode.fontName, 
            spanNode.fontSize, 
            spanNode.fontColor
            );
            
            var i : Int;
            var numChildren : Int = node.children.length;
            for (i in 0...numChildren){
                createParagraphChildViews(node.children[i], spanFormat, outViews);
            }
        }
        else if (Std.is(node, TextNode)) 
        {
            var textNode : TextNode = try cast(node, TextNode) catch(e:Dynamic) null;
            var textView : DocumentView = new DummyTextView(textNode, textFormat);
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
    private function layoutParagraphChildViews(views : Array<DocumentView>,
            outViews : Array<DocumentView>,
            parentContentBounds : Rectangle,
            floatLeftBounds : Rectangle,
            floatRightBounds : Rectangle,
            pixelSpaceBetweenLines : Float) : Void
    {
        // Used to measure width of text content
        var measuringTextField : MeasuringTextField = new MeasuringTextField();
        
        var centerInline : Bool = true;  // Should the content in a line be centered  
        var currentLineTopY : Float = parentContentBounds.y;  // The top vertical bound of the current line  
        var currentX : Float = (yWithinRectangle(pixelSpaceBetweenLines, floatLeftBounds)) ? 
        floatLeftBounds.right : parentContentBounds.x;  // Acts like a caret to keep track of where to put the next content horizontally  
        var i : Int;
        var numViews : Int = views.length;
        var view : DocumentView;
		function positionView(view : DocumentView, measuredWidth : Int, measuredHeight : Int) : Void
            {
                var maxAllowedX = getMaxAllowedX(Std.int(currentLineTopY), parentContentBounds, measuredHeight, floatRightBounds);
                if (measuredWidth + currentX <= maxAllowedX) 
                    { }  // No need to center in this case    // With the new line, the content sets the starting height bounds so it always fits vertically.    // For an image we wrap to the next line  
                // Set coordinates of the given target view
                else if (Std.is(view, ImageView)) 
                {
                    // Right now this only occurs for images
                    // If we have text that is wrapping that is handled in the text layout algorithm
                    currentX = (yWithinRectangle(currentLineTopY + pixelSpaceBetweenLines, floatLeftBounds)) ? 
                            floatLeftBounds.right : parentContentBounds.x;
                    currentLineTopY += pixelSpaceBetweenLines;
                    
                    view.lineNumber = ++m_currentLineNumber;
                }
                
                
                
                view.x = currentX;
                view.y = ((centerInline)) ? 
                        currentLineTopY + (pixelSpaceBetweenLines - measuredHeight) * 0.5 : currentLineTopY;
                currentX += measuredWidth;
                
                // HACK: If image is the first part of a paragrah, space is not added at the end
                // so that the bit of text butts up against it. Add extra padding
                if (i == 0 && Std.is(view, ImageView)) 
                {
                    currentX += 5;
                }
                
                outViews.push(view);
            };
			
        for (i in 0...numViews){
            view = views[i];
            
            if (Std.is(view, DummyTextView)) 
            {
                // We need to look at each text view and figure out whether they need to be further segmented to
                // correctly wrap around lines.
                var textView : DummyTextView = try cast(view, DummyTextView) catch(e:Dynamic) null;
                var textNode : TextNode = try cast(view.node, TextNode) catch(e:Dynamic) null;
                var measuringTextFormat : TextFormat = textView.getTextFormat();
                measuringTextField.defaultTextFormat = measuringTextFormat;
                m_measuringTextForWhitespace.setTextFormat(measuringTextFormat);
                
                // Break up content into individual words, check how many can fit into the current line
                var textContent : String = textNode.content;
                var wordBuffer : Array<Dynamic> = textContent.split(" ");
                var numWords : Int = wordBuffer.length;
                var wordIndex : Int;
                var word : String;
                // If the preceding view was an image add a space to the text
                var wordsForCurrentLine : String = ((i - 1 > 0 && Std.is(views[i - 1], ImageView))) ? " " : "";
                var textMeasuredWidth : Int;
                var textMeasuredHeight : Int;
                var maxAllowedX : Int = getMaxAllowedX(Std.int(currentLineTopY), parentContentBounds, Std.int(pixelSpaceBetweenLines), floatRightBounds);
                for (wordIndex in 0...numWords){
                    word = wordBuffer[wordIndex];
                    if (word == " " || word == "") 
                    {
                        continue;
                    }
                    
                    measuringTextField.text = wordsForCurrentLine + word;
                    textMeasuredHeight = Std.int(measuringTextField.textHeight + TEXT_HACK_HEIGHT);
                    
                    // If adding a new word overflows the horizontal bounds, then we create a new text view
                    // with that previous word removed. The content added should just fit within the allowable bounds
                    if (measuringTextField.textWidth + currentX > maxAllowedX) 
                    {
                        var addedCurrentWordToPreviousLine : Bool = false;
                        
                        // Puncuation marks should stay on the previous line
                        if (Lambda.indexOf(PUNCUATION_CHARACTERS, word) >= 0) 
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
                            textMeasuredWidth = Std.int(measuringTextField.textWidth + m_measuringTextForWhitespace.textWidth * 2.5);
                            var newTextView : TextView = this.createTextView(
                                    view.node,
                                    wordsForCurrentLine,
                                    measuringTextFormat,
                                    0, 0, textMeasuredWidth, textMeasuredHeight
                                    );
                            positionView(newTextView, Std.int(measuringTextField.textWidth), textMeasuredHeight);
                            newTextView.lineNumber = m_currentLineNumber++;
                        }  // No content left on this line, we need to immediately shift downward    // at all, we cannot rely on position view to do anything    // start of the next line. Note that since we are not guaranteed that there was any content    // Since the last word we added will not fit on the current line, we need to move to the  
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        currentLineTopY += pixelSpaceBetweenLines;
                        currentX = (yWithinRectangle(currentLineTopY + pixelSpaceBetweenLines, floatLeftBounds)) ? 
                                floatLeftBounds.right : parentContentBounds.x;
                        maxAllowedX = getMaxAllowedX(Std.int(currentLineTopY), parentContentBounds, textMeasuredHeight, floatRightBounds);
                        
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
                }  // Get the next view and check that it is text. Then check if the first character is some puncuation    // we strip out that last space.    // case where the next view is more text and the starting character is a puncuation. In that case    // In the previous loop we always added a space after every word. This is not correct in the  
                
                
                
                
                
                
                
                
                
                var addSpaceForNextView : Bool = false;
                if (i + 1 < numViews && Std.is(views[i + 1], DummyTextView)) 
                {
                    var nextTextNode : TextNode = try cast(views[i + 1].node, TextNode) catch(e:Dynamic) null;
                    if (nextTextNode.content.length > 0) 
                    {
                        addSpaceForNextView = true;
                        var firstCharacter : String = nextTextNode.content.charAt(0);
                        var j : Int;
                        for (j in 0...PUNCUATION_CHARACTERS.length){
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
                }  // Also don't add a space if word already ends in a space  
                
                
                
                if (wordsForCurrentLine.charAt(wordsForCurrentLine.length - 1) == " ") 
                {
                    addSpaceForNextView = false;
                }  // Add the last chunk  
                
                
                
                measuringTextField.text = wordsForCurrentLine;
                textMeasuredWidth = Std.int(measuringTextField.textWidth + m_measuringTextForWhitespace.textWidth * 2.5);
                textMeasuredHeight = Std.int(measuringTextField.textHeight + TEXT_HACK_HEIGHT);
                var newTextView = this.createTextView(
                                view.node,
                                wordsForCurrentLine,
                                measuringTextFormat,
                                0, 0, textMeasuredWidth, textMeasuredHeight
                                );
                
                // The way xml is parsed, words that are separated by an element like
                // left text <span>spanned</span> right text
                // will not preserve the white space, no space after parsing after 'left text'
                // or before 'right text'. Need to inject this space by repositioning things.
                
                var boundsOfCurrentTextToAdd : Float = measuringTextField.textWidth;
                if (addSpaceForNextView) 
                {
                    boundsOfCurrentTextToAdd += m_measuringTextForWhitespace.textWidth;
                }
                positionView(newTextView, Std.int(boundsOfCurrentTextToAdd), textMeasuredHeight);
                newTextView.lineNumber = m_currentLineNumber;
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
            else if (Std.is(view, ImageView)) 
            {
                var imageView : ImageView = try cast(view, ImageView) catch(e:Dynamic) null;
                positionView(imageView, Std.int(imageView.width), Std.int(imageView.height));
            }
            else 
            {
                // Error: An invalid view type was added in the list
                throw new Error("Invalid view type during layout: " + view.node.getTagName());
            }
        }
    }
    
    private function getMaxAllowedX(currentLineTopY : Int,
            parentContentBounds : Rectangle,
            viewHeight : Int,
            floatRightBounds : Rectangle) : Int
    {
        var isParagraphChildHittingFloat : Bool = (this.yWithinRectangle(currentLineTopY, floatRightBounds) ||
        this.yWithinRectangle(currentLineTopY + viewHeight, floatRightBounds));
        var maxAllowedX : Float = ((isParagraphChildHittingFloat && floatRightBounds.width > 0)) ? 
        floatRightBounds.left : parentContentBounds.width;
        return Std.int(maxAllowedX);
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
    private function _revisedAttachParagraphChildViewsToSpans(node : DocumentNode,
            views : Array<DocumentView>,
            outViews : Array<DocumentView>) : Void
    {
        if (node.children == null || node.children.length == 0) 
        {
            findViewsMatchingNode(node, views, outViews);
        }
        else 
        {
            // For every non-terminal, which is just the root paragraph and spans,
            // create a buffer to store all views that should go inside of it.
            var outViewsForNonTerminal : Array<DocumentView> = new Array<DocumentView>();
            var childrenNodes : Array<DocumentNode> = node.children;
            var numChildren : Int = childrenNodes.length;
            var i : Int;
            var childNode : DocumentNode;
            for (i in 0...numChildren){
                childNode = childrenNodes[i];
                
                // Get the view (or views for multiple text pieces) associated with the child node
                // Note that this could also another span
                _revisedAttachParagraphChildViewsToSpans(childNode, views, outViewsForNonTerminal);
            }
            
            
            if (Std.is(node, SpanNode)) 
            {
                // Create a span view and retroactively add all the image, text, and other span
                // nodes inside of it.
                var spanView : SpanView = new SpanView(try cast(node, SpanNode) catch(e:Dynamic) null);
                
                // Add all views of the span children into the span container
                var viewInSpan : DocumentView;
                for (i in 0...outViewsForNonTerminal.length){
                    viewInSpan = outViewsForNonTerminal[i];
                    
                    // The coordinates of the span matches those of its first children.
                    // We need to readjust the coordinates of the children from the reference of
                    // the parent to the reference of the span.
                    var spanX : Int;
                    var spanY : Int;
                    if (i == 0) 
                    {
                        spanX = Std.int(viewInSpan.x);
                        spanY = Std.int(viewInSpan.y);
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
                for (i in 0...outViewsForNonTerminal.length){
                    outViews.push(outViewsForNonTerminal[i]);
                }
				outViewsForNonTerminal = new Array<DocumentView>();
            }
        }
    }
    
    /**
     * Find the views bound to a particular node from a given set of views
     */
    private function findViewsMatchingNode(node : DocumentNode,
            views : Array<DocumentView>,
            outViews : Array<DocumentView>) : Void
    {
        var i : Int;
        var view : DocumentView;
        var numViews : Int = views.length;
        for (i in 0...numViews){
            view = views[i];
            if (view.node == node) 
            {
                outViews.push(view);
            }
        }
    }
    
    private function createTextView(textNode : DocumentNode,
            text : String,
            textFormat : TextFormat,
            x : Float,
            y : Float,
            width : Float,
            height : Float) : TextView
    {
        var textView : TextView = new TextView(textNode);
        textView.setTextContents(
                text,
                width,
                height,
                textFormat.font,
                try cast(textFormat.color, Int) catch(e:Dynamic) null,
                textFormat.size
                );
        textView.x = x;
        textView.y = y;
        
        return textView;
    }
    
    private function xWithinRange(x : Float, rectangle : Rectangle) : Bool
    {
        return (x >= rectangle.left && x <= rectangle.right);
    }
    
    private function yWithinRectangle(y : Float, rectangle : Rectangle) : Bool
    {
        return (y >= rectangle.top && y <= rectangle.bottom);
    }
}
