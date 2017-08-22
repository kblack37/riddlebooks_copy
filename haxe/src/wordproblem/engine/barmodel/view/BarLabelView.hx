package wordproblem.engine.barmodel.view;

import dragonbox.common.util.XColor;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import wordproblem.display.PivotSprite;
import wordproblem.engine.barmodel.view.ResizeableBarPieceView;

import openfl.text.TextFormat;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.text.TextField;

import wordproblem.display.DottedRectangle;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.component.RigidBodyComponent;
import wordproblem.engine.text.MeasuringTextField;

/**
 * Note that a label can be positioned both vertically and horizontally.
 * It might also appear pasted directly on a segment
 */
class BarLabelView extends ResizeableBarPieceView
{
    /**
     * The backing label data the view is trying to draw
     */
    public var data : BarLabel;
    
    /**
     * The bounds of the view relative to the bar area widget.
     * (This is actually the bounds of just the line graphics)
     */
    public var rigidBody : RigidBodyComponent;
    
    /**
     * The is the container holding the graphics for the lines and ticks for the label.
     */
    public var lineGraphicDisplayContainer : DisplayObjectContainer;
    
    // Pieces to create a bracket that scales in size
    private var m_bracketLineA : DisplayObject;
    private var m_bracketLineB : DisplayObject;
    private var m_bracketMiddle : DisplayObject;
    private var m_bracketEdgeA : DisplayObject;
    private var m_bracketEdgeB : DisplayObject;
    
    /**
     * Piece to use if the length is smaller than the combined width of the unscaled portions
     */
    private var m_unscaledBracketImage : DisplayObject;
    
    /**
     * Container to store all the pieces of a bracket
     */
    private var m_bracketContainer : PivotSprite;
    
    /**
     * Used to display the name of the label as plain text
     */
    private var m_descriptionTextfield : DisplayObject;
    
    private var m_edgeAResizeButton : Bitmap;
    private var m_edgeBResizeButton : Bitmap;
    
    private var m_fontName : String;
    private var m_fontColor : Int;
    
    /**
     * Used if we want to show an image rather than text when describing the label
     * (Maybe use this is combination)
     */
    private var m_descriptionImage : PivotSprite;
    
    /**
     * The image to use if the label is marked as hidden.
     * (Right now do not hide the bracket, just the name or image otherwise it looks
     * too much like the hidden segment)
     */
    private var m_hiddenImage : DottedRectangle;
    
    /**
     * Used to measure out the proper dimensions for a bit of text
     */
    private var m_measuringTextfield : MeasuringTextField;
    
    /**
     * Textual name to display
     */
    private var m_name : String;
    
    private var m_useImageInsteadOfTextForNoBracket : Bool;
    
    /**
     * Note that a separate call to draw must be made
     */
    public function new(barLabel : BarLabel,
            fontName : String,
            fontColor : Int,
            bracketEdgeLeftBitmapData : BitmapData,
            bracketEdgeRightBitmapData : BitmapData,
            bracketMiddleBitmapData : BitmapData,
            unscaledBracketBitmapData : BitmapData,
            name : String,
            descriptionImage : DisplayObject,
            useImageInsteadOfTextForNoBracket : Bool,
            hiddenImage : DottedRectangle)
    {
        super();
		
        // If the label length is below some threshold, use the unscaled texture
        var bracketColor : Int = barLabel.color;
        m_unscaledBracketImage = new Bitmap(unscaledBracketBitmapData);
		m_unscaledBracketImage.transform.colorTransform.concat(XColor.rgbToColorTransform(bracketColor));
        
        this.data = barLabel;
        this.rigidBody = new RigidBodyComponent(barLabel.id);
        this.lineGraphicDisplayContainer = new Sprite();
        m_bracketContainer = new PivotSprite();
        this.lineGraphicDisplayContainer.addChild(m_bracketContainer);
        addChild(lineGraphicDisplayContainer);
        
        // If label is on top, the text description or icon needs to be above the
        // bracket image. Otherwise it should appear below
        // The length of the view might affect the size of the text
        if (barLabel.bracketStyle != BarLabel.BRACKET_NONE) 
        {
            // The default orientation of the textures has the bracket going horizontally with
            // the open end on the bottom
            var edgeAImage : Bitmap = new Bitmap(bracketEdgeLeftBitmapData);
			edgeAImage.transform.colorTransform.concat(XColor.rgbToColorTransform(bracketColor));
            var edgeBImage : Bitmap = new Bitmap(bracketEdgeRightBitmapData);
			edgeBImage.transform.colorTransform.concat(XColor.rgbToColorTransform(bracketColor));
            var midImage : Bitmap = new Bitmap(bracketMiddleBitmapData);
			midImage.transform.colorTransform.concat(XColor.rgbToColorTransform(bracketColor));
            
            // For now we draw a very thin line
			var lineA : Bitmap = new Bitmap(new BitmapData(1, 5, false, bracketColor));
			var lineB : Bitmap = new Bitmap(new BitmapData(1, 5, false, bracketColor));
            
            m_bracketEdgeA = edgeAImage;
            m_bracketEdgeB = edgeBImage;
            m_bracketMiddle = midImage;
            m_bracketLineA = lineA;
            m_bracketLineB = lineB;
        }  
		
		// The description image is a pivot sprite or a collection of pivot sprites,
		// either way we need to set the pivots to 0 to align the label
		if (Std.is(descriptionImage, PivotSprite)) {
			var castedDescriptionImage : PivotSprite = try cast(descriptionImage, PivotSprite) catch (e : Dynamic) null;
			castedDescriptionImage.pivotX = castedDescriptionImage.pivotY = 0;
			m_descriptionImage = castedDescriptionImage;
		} else if (Std.is(descriptionImage, Sprite)) {
			var castedDescriptionImage : Sprite = try cast(descriptionImage, Sprite) catch (e : Dynamic) null;
			for (i in 0...castedDescriptionImage.numChildren) {
				var castedChild = cast(castedDescriptionImage.getChildAt(i), PivotSprite);
				castedChild.pivotX = castedChild.pivotY = 0;
			}
			m_descriptionImage = new PivotSprite();
			m_descriptionImage.addChild(descriptionImage);
		}
        
		// Determine whether an image should be used instead of text to mark the label
        m_useImageInsteadOfTextForNoBracket = useImageInsteadOfTextForNoBracket;
        m_hiddenImage = hiddenImage;
        
        // TODO: Do not try setting up the text yet
        // Figure out the proper parameters for the text
        m_name = name;
        m_fontName = fontName;
        m_fontColor = fontColor;
        if (m_name != null) 
        {
            m_measuringTextfield = new MeasuringTextField();
            m_measuringTextfield.defaultTextFormat = new TextFormat(fontName, 18, fontColor);
            m_measuringTextfield.text = m_name;
        }
    }
    
    /**
     * In its current render state get back the display object that shows
     * the description of this label (NOT the bracket)
     */
    public function getDescriptionDisplay() : DisplayObject
    {
        var labelDescriptionDisplayObject : DisplayObject = null;
        if (this.data.hiddenValue != null) 
        {
            labelDescriptionDisplayObject = m_hiddenImage;
        }
        else if (m_descriptionImage != null && m_descriptionImage.parent != null) 
        {
            labelDescriptionDisplayObject = m_descriptionImage;
        }
        else 
        {
            labelDescriptionDisplayObject = m_descriptionTextfield;
        }
        
        return labelDescriptionDisplayObject;
    }
    
    /**
     * Change the length of the label. The length only affects one axis.
     * This really just a layout function
     * 
     * (NOTE: The scale for every item should have already been set up before this call)
     */
    override public function resizeToLength(newLength : Float) : Void
    {
        if (data.bracketStyle != BarLabel.BRACKET_NONE) 
        {
            this.pixelLength = newLength;
            
            m_bracketContainer.removeChildren();
            var lineLength : Float = (newLength - (m_bracketEdgeA.width + m_bracketEdgeB.width + m_bracketMiddle.width)) * 0.5;
            var minimumLengthThreshold : Float = m_bracketEdgeA.width + m_bracketEdgeB.width + m_bracketMiddle.width;
            
            // Pick the display graphic that should be appearing next to the bracket
            var labelDescriptionDisplayObject : DisplayObject = null;
            if (this.data.hiddenValue != null) 
            {
                labelDescriptionDisplayObject = m_hiddenImage;
            }
            else if (m_descriptionImage != null) 
            {
                labelDescriptionDisplayObject = m_descriptionImage;
            }
            else if (m_descriptionTextfield != null) 
            {
                labelDescriptionDisplayObject = m_descriptionTextfield;
            }
            else 
            {
                labelDescriptionDisplayObject = new Sprite();
            }
            
            if (newLength < minimumLengthThreshold) 
            {
                m_unscaledBracketImage.width = newLength;
                m_bracketContainer.addChild(m_unscaledBracketImage);
            }
            else 
            {
                // Position each piece properly in the label
                // HACK: After rotation there is sometimes a very small space between the lines
                // and the mid point, adding extra pixels of padding to various places to cover it.
                m_bracketLineA.width = Math.floor(lineLength) + 1;
                m_bracketLineB.width = Math.floor(lineLength) + 1;
                
                m_bracketMiddle.x = Math.floor((newLength - m_bracketMiddle.width) * 0.5);
                m_bracketEdgeA.x = 0;
                m_bracketEdgeB.x = Math.floor(newLength - m_bracketEdgeB.width);
                m_bracketLineA.x = m_bracketEdgeA.x + m_bracketEdgeA.width - 1;
                m_bracketLineB.x = m_bracketMiddle.x + m_bracketMiddle.width;
                
                m_bracketEdgeA.y = 0;
                m_bracketEdgeB.y = 0;
                m_bracketLineA.y = m_bracketEdgeA.height - m_bracketLineA.height;
                m_bracketLineB.y = m_bracketLineA.y;
                m_bracketMiddle.y = m_bracketEdgeA.height - m_bracketLineA.height;
                
                m_bracketContainer.addChild(m_bracketLineA);
                m_bracketContainer.addChild(m_bracketLineB);
                m_bracketContainer.addChild(m_bracketMiddle);
                m_bracketContainer.addChild(m_bracketEdgeA);
                m_bracketContainer.addChild(m_bracketEdgeB);
            }
            
            
            if (data.isHorizontal) 
            {
                if (data.isAboveSegment) 
                {
                    // rotate each of the edges by pi radians and swap them
                    m_bracketContainer.rotation = Math.PI;
                    m_bracketContainer.pivotX = this.lineGraphicDisplayContainer.width;
                    m_bracketContainer.pivotY = this.lineGraphicDisplayContainer.height;
                    
                    var bracketOffset : Float = ((m_descriptionImage != null)) ? m_descriptionImage.height : m_descriptionTextfield.height;
                    this.lineGraphicDisplayContainer.y = bracketOffset;
                }
                else 
                {
                    labelDescriptionDisplayObject.y = this.lineGraphicDisplayContainer.height;
                } 
				
				// Resize the scaling lines and reposition the pieces of the bracket  
                labelDescriptionDisplayObject.x = (newLength - labelDescriptionDisplayObject.width) * 0.5;
            }
            else 
            {
                // rotate by -pi/2 radians and shift over by the width
                // (Remember some of the properties of the image DO NOT re-align with
                // the axis on rotate, an exception is x,y)
                m_bracketContainer.rotation = Math.PI * -0.5;
                m_bracketContainer.y = m_bracketContainer.height;
                
                labelDescriptionDisplayObject.x = this.lineGraphicDisplayContainer.width;
                labelDescriptionDisplayObject.y = (newLength - labelDescriptionDisplayObject.height) * 0.5;
            }
            
            addChild(labelDescriptionDisplayObject);
            
            // Set up extra buttons used to drag or remove this label (logic is in outside scripts)
            repositionButtons();
        }
        else 
        {
            // Repositioning a label without brackets occurs in a separate call
            if (m_descriptionImage != null && m_useImageInsteadOfTextForNoBracket) 
            {
                addChild(m_descriptionImage);
            }
            else 
            {
                addChild(m_descriptionTextfield);
            }
        }
    }
    
    /**
     * This function differs from the resize in that it will attempt to scale the various pieces first.
     * 
     * A label that has no bracket exists in the case where it spans horizontally over a single segment
     * This is a special one-off case in which the label text or image can only be positioned after the segments
     * have been created
     * 
     * @param boundingWidth
     *      The maximal allowable width of the label (if negative there is no bound)
     * @param boundingHeight
     *      The maximal allowable height of the label (if negative there is no bound)
     * @param scaleX
     *      Horizontal scaling factor
     * @param scaleY
     *      Vertical scaling factor
     */
    public function rescaleAndRedraw(boundingWidth : Float,
            boundingHeight : Float,
            scaleX : Float,
            scaleY : Float) : Void
    {
        if (m_descriptionTextfield != null) 
        {
			if (m_descriptionTextfield.parent != null) m_descriptionTextfield.parent.removeChild(m_descriptionTextfield);
            m_descriptionTextfield = null;
        }
        
		if (m_hiddenImage.parent != null) {
			if (m_hiddenImage.parent != null) m_hiddenImage.parent.removeChild(m_hiddenImage);
		}
        
        // The orientation of the bar determines which of the parameters are useful.
        // For example, a horizontal bar does not care about scaleX since it length should
        // solely be determined by the bounding width
        var lengthToResizeTo : Float = 0.0;
        if (this.data.bracketStyle != BarLabel.BRACKET_NONE) 
        {
            // Text/image size of a label with brackets is affected by the scale factor.
            // If the scale is at one, both stay at default size regardless of the bounds value.
            // (Text/image scaling ignores the bounds)
            
            // Everything should scale proportionally only along one axis
            // I.e. we do not want things to be stretched out
            var imageScaleFactor : Float = 0;
            var bracketScaleFactor : Float = 0;
            if (this.data.isHorizontal) 
            {
                // Scale all the bracket pieces by the y scale factor
                lengthToResizeTo = boundingWidth;
                bracketScaleFactor = scaleY;
                imageScaleFactor = scaleY;
            }
            else 
            {
                // Scale all the bracket pieces by the x scale factor
                lengthToResizeTo = boundingHeight;
                bracketScaleFactor = scaleX;
                imageScaleFactor = scaleX;
            }
            
            m_bracketEdgeA.scaleX = m_bracketEdgeA.scaleY = bracketScaleFactor;
            m_bracketEdgeB.scaleX = m_bracketEdgeB.scaleY = bracketScaleFactor;
            m_bracketLineA.scaleX = m_bracketLineA.scaleY = bracketScaleFactor;
            m_bracketLineB.scaleX = m_bracketLineB.scaleY = bracketScaleFactor;
            m_bracketMiddle.scaleX = m_bracketMiddle.scaleY = bracketScaleFactor;
            m_unscaledBracketImage.scaleX = m_unscaledBracketImage.scaleY = bracketScaleFactor;
            
            // Size up the hidden image (need to use the original height of the image
            if (this.data.hiddenValue != null) 
            {
                m_descriptionImage.scaleX = m_descriptionImage.scaleY = 1.0;
                m_hiddenImage.resize(m_descriptionImage.width, m_descriptionImage.height, 2, 2);
            }
            
            if (m_descriptionImage != null) 
            {
                m_descriptionImage.scaleX = m_descriptionImage.scaleY = imageScaleFactor;
            }
        }
        else 
        {
            // We don't always want text without brackets, sometimes we just
            // want an image ontop
            if (m_descriptionImage != null && m_useImageInsteadOfTextForNoBracket) 
            {
                // We need to space out the images if there is no bracket
                if (Std.is(m_descriptionImage, DisplayObjectContainer) && (try cast(m_descriptionImage, DisplayObjectContainer) catch(e:Dynamic) null).numChildren > 1) 
                {
                    var descriptionImageContainer : DisplayObjectContainer = try cast(m_descriptionImage, DisplayObjectContainer) catch(e:Dynamic) null;
                    var sampleImage : DisplayObject = descriptionImageContainer.getChildAt(0);
                    var imageWidth : Float = sampleImage.width;
                    var imageHeight : Float = sampleImage.height;
                    
                    var totalSpanningWidth : Float = imageWidth * descriptionImageContainer.numChildren;
                    var targetScale : Float = Math.min(
							Math.min(
								totalSpanningWidth / imageWidth,
								boundingHeight / imageHeight
                            ), 1.0);
                    imageWidth *= targetScale;
                    imageHeight *= targetScale;
                    
                    // Scale each individual image and calculate the gap between images such that all is evenly spaced
                    var imageGap : Float = (boundingWidth - totalSpanningWidth * targetScale) / (descriptionImageContainer.numChildren + 1);
                    var i : Int = 0;
                    var imageY : Float = boundingHeight * 0.5;
                    for (i in 0...descriptionImageContainer.numChildren){
                        sampleImage = descriptionImageContainer.getChildAt(i);
                        sampleImage.scaleX = sampleImage.scaleY = targetScale;
                        sampleImage.x = imageGap * (i + 1) + imageWidth * i + imageWidth * 0.5;
                        sampleImage.y = imageY;
                    }
                    
                    descriptionImageContainer.x = 0;
                    descriptionImageContainer.y = 0;
                }
                else 
                {
                    m_descriptionImage.scaleX = m_descriptionImage.scaleY = Math.min(
											Math.min(
												boundingWidth / m_descriptionImage.width,
												boundingHeight / m_descriptionImage.height
                                            ), 1.0);
                    m_descriptionImage.x = (boundingWidth - m_descriptionImage.width) * 0.5;
                    m_descriptionImage.y = (boundingHeight - m_descriptionImage.height) * 0.5;
                }
            }
            // No bracket hidden label doesn't really make sense
            else if (m_name != null) 
            {
                var nameToShow : String = m_name;
                
                // With no bracket, label size is purely dependent on the bounding width and height
                // We are implicitly assuming these bounds have already had the scale factor
                // applied to them so we just use the bounds as they are.
                // Dimensions of the text purely depends on the bounds
                var hackExtraWidthPadding : Float = 8;
                var fontSize : Int = Std.int(m_measuringTextfield.resizeToDimensions(boundingWidth, boundingHeight, nameToShow));
                var prevTextformat : TextFormat = m_measuringTextfield.defaultTextFormat;
                prevTextformat.size = fontSize;
                m_measuringTextfield.text = nameToShow;
                m_measuringTextfield.setTextFormat(prevTextformat);
                
                var minFontSize : Int = 8;
                var descriptionTextFieldWidth : Float = m_measuringTextfield.textWidth + hackExtraWidthPadding;
                if (descriptionTextFieldWidth > boundingWidth && fontSize <= minFontSize) 
                {
                    // If there is still overflow perform some pruning on the name to show
                    // If the value is a number, just show the number since we expect those to
                    // be fairly short anyways
                    var isValueANumber : Bool = !Math.isNaN(Std.parseFloat(this.data.value));
                    if (isValueANumber) 
                    {
                        nameToShow = this.data.value;
                    }
                    else 
                    {
                        // For variables going for a dumb/simple solution
                        // If the name has spaces, pick the first 'word' otherwise
                        // cut the word in half
                        if (m_name.indexOf(" ") >= 0) 
                        {
                            var words : Array<Dynamic> = m_name.split(" ");
                            if (words.length > 0) 
                            {
                                nameToShow = words[0];
                            }
                        }
                        else 
                        {
                            nameToShow = m_name.substr(0, Math.floor(m_name.length * 0.5));
                        }
                    }  // Scaling up is messed up, so reset font size  
                    
                    fontSize = Std.int(m_measuringTextfield.resizeToDimensions(boundingWidth, boundingHeight, nameToShow));
                    prevTextformat.size = fontSize;
                    m_measuringTextfield.text = nameToShow;
                    m_measuringTextfield.setTextFormat(prevTextformat);
                }
                
                descriptionTextFieldWidth = m_measuringTextfield.textWidth + hackExtraWidthPadding;
                var descriptionTextField : TextField = new TextField();
                descriptionTextField.width = descriptionTextFieldWidth + 6;
                descriptionTextField.height = m_measuringTextfield.textHeight + 5;
                descriptionTextField.text = nameToShow;
                descriptionTextField.setTextFormat(new TextFormat(
					m_measuringTextfield.defaultTextFormat.font, 
					fontSize, 
					m_measuringTextfield.defaultTextFormat.color
                ));
				descriptionTextField.selectable = false;
                m_descriptionTextfield = descriptionTextField;
                m_descriptionTextfield.x = (boundingWidth - m_descriptionTextfield.width) * 0.5;
                m_descriptionTextfield.y = (boundingHeight - m_descriptionTextfield.height) * 0.5;
                
                // Modify displayed name to match the textfield
                this.data.displayedName = nameToShow;
            }
        }
        
        resizeToLength(lengthToResizeTo);
    }
    
    /**
     * Hack so the transparency of the bracket and description image is changed without
     * affecting the buttons that were added later
     */
    public function setBracketAndDescriptionAlpha(alpha : Float) : Void
    {
        this.lineGraphicDisplayContainer.alpha = alpha;
        if (m_descriptionImage != null && m_descriptionImage.parent != null) 
        {
            m_descriptionImage.alpha = alpha;
        }
        
        if (m_descriptionTextfield != null && m_descriptionTextfield.parent != null) 
        {
            m_descriptionTextfield.alpha = alpha;
        }
    }
    
    /**
     * A hacky way to add the resize buttons to the label after they have been drawn
     */
    public function addButtonImagesToEdges(buttonBitmapData : BitmapData) : Void
    {
        // Add two button images to the edges
        // Need to add the button on the edges of the label
        var edgeAButton : Bitmap = getButtonImageFromPool(buttonBitmapData);
        m_edgeAResizeButton = edgeAButton;
        var edgeBButton : Bitmap = getButtonImageFromPool(buttonBitmapData);
        m_edgeBResizeButton = edgeBButton;
        repositionButtons();
    }
    
    public function removeButtonImagesFromEdges() : Void
    {
        if (m_edgeAResizeButton != null) 
        {
            if (m_edgeAResizeButton.parent != null) m_edgeAResizeButton.parent.removeChild(m_edgeAResizeButton);
            m_resizeEdgeButtonPool.push(m_edgeAResizeButton);
            m_edgeAResizeButton = null;
        }
        
        if (m_edgeBResizeButton != null) 
        {
            if (m_edgeBResizeButton.parent != null) m_edgeBResizeButton.parent.removeChild(m_edgeBResizeButton);
            m_resizeEdgeButtonPool.push(m_edgeBResizeButton);
            m_edgeBResizeButton = null;
        }
    }
    
    /**
     * Get the image for the small button used to resize a label. Needed for tutorial
     * help messages so we can apply effects directly to them.
     * 
     * @param getEdgeA
     *      If true get the left/top resize button depending on the label orientation
     */
    public function getButtonImage(getEdgeA : Bool) : Bitmap
    {
        return ((getEdgeA)) ? m_edgeAResizeButton : m_edgeBResizeButton;
    }
    
    /**
     * A hacky way to color one of the buttons on the edges to indicate they are dragged or pressed
     */
    public function colorEdgeButton(edgeA : Bool, color : Int, alpha : Float) : Void
    {
        var edgeButtonToUse : Bitmap = ((edgeA)) ? m_edgeAResizeButton : m_edgeBResizeButton;
        if (edgeButtonToUse != null) 
        {
			edgeButtonToUse.transform.colorTransform.concat(XColor.rgbToColorTransform(color));
            edgeButtonToUse.alpha = alpha;
        }
    }
    
    /**
     * Reposition all of the various button elements
     */
    private function repositionButtons() : Void
    {
        if (m_edgeAResizeButton != null && m_edgeBResizeButton != null) 
        {
            if (this.data.isHorizontal) 
            {
                m_edgeAResizeButton.x = -m_edgeAResizeButton.width * 0.3;
                m_edgeBResizeButton.x = ((m_bracketEdgeB.parent != null)) ? 
                        m_bracketEdgeB.x + m_bracketEdgeB.width - m_edgeBResizeButton.width * 0.7 : 
                        m_unscaledBracketImage.width - m_edgeBResizeButton.width * 0.7;
                
                if (this.data.isAboveSegment) 
                {
                    m_edgeAResizeButton.y = this.lineGraphicDisplayContainer.y + this.lineGraphicDisplayContainer.height - m_edgeAResizeButton.height;
                    m_edgeBResizeButton.y = m_edgeAResizeButton.y;
                }
                else 
                {
                    m_edgeAResizeButton.y = 0;
                    m_edgeBResizeButton.y = m_edgeAResizeButton.y;
                }
            }
            else 
            {
                m_edgeAResizeButton.x = 0;
                m_edgeAResizeButton.y = 0;
                m_edgeBResizeButton.x = m_edgeAResizeButton.x;
                m_edgeBResizeButton.y = this.lineGraphicDisplayContainer.height - m_edgeBResizeButton.height;
            }
            
            addChildAt(m_edgeAResizeButton, 0);
            addChildAt(m_edgeBResizeButton, 0);
        }
    }
    
    private var m_resizeEdgeButtonPool : Array<Bitmap> = new Array<Bitmap>();
    private function getButtonImageFromPool(buttonBitmapData : BitmapData) : Bitmap
    {
        // TODO: On discard return the image to the pool
        var buttonImage : Bitmap = null;
        if (m_resizeEdgeButtonPool.length == 0) 
        {
            buttonImage = new Bitmap(buttonBitmapData);
            buttonImage.scaleX = buttonImage.scaleY = 0.4;
            buttonImage.alpha = 0.5;
            m_resizeEdgeButtonPool.push(buttonImage);
        }
        
        buttonImage = m_resizeEdgeButtonPool.pop();
		buttonImage.transform.colorTransform.concat(XColor.rgbToColorTransform(0xFFFFFF));
        return buttonImage;
    }
	
	override public function dispose() {
		if (m_hiddenImage != null) m_hiddenImage.dispose();
		if (m_bracketContainer != null) m_bracketContainer.dispose();
	}
}
