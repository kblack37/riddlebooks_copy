package wordproblem.engine.barmodel.view;

import wordproblem.engine.barmodel.view.ResizeableBarPieceView;

import flash.geom.Rectangle;
import flash.text.TextFormat;

import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Sprite;
import starling.text.TextField;
import starling.textures.Texture;

import wordproblem.engine.barmodel.model.BarComparison;
import wordproblem.engine.component.RigidBodyComponent;
import wordproblem.engine.text.MeasuringTextField;

class BarComparisonView extends ResizeableBarPieceView
{
    public var data : BarComparison;
    
    public var rigidBody : RigidBodyComponent;
    
    /**
     * This is the container holding the main line graphics that get resized
     */
    public var lineGraphicDisplayContainer : DisplayObjectContainer;
    
    /**
     * The image that can scale without stretching/distorting. It is sliced into three parts
     */
    private var m_scaledArrowImage : Image;
    
    /**
     * The image with all pieces already pieces together
     */
    private var m_fullArrowImage : Image;
    
    /**
     * The image for the descriptor
     * 
     * Can be a textfield or the card image
     */
    private var m_descriptionImage : DisplayObject;
    
    /**
     *
     * @param symbolImage
     *      If null, then show text without background
     */
    public function new(data : BarComparison,
            length : Float,
            labelName : String,
            fontName : String,
            fontColor : Int,
            symbolImage : DisplayObject,
            threeSliceTexture : Texture,
            fullTexture : Texture)
    {
        super();
        
        this.data = data;
        this.rigidBody = new RigidBodyComponent(data.id);
        this.lineGraphicDisplayContainer = new Sprite();
        addChild(lineGraphicDisplayContainer);
        
        var color : Int = data.color;
        m_scaledArrowImage = new Image(threeSliceTexture);
        m_scaledArrowImage.color = color;
        m_fullArrowImage = new Image(fullTexture);
        m_fullArrowImage.color = color;
        
        if (symbolImage == null) 
        {
            var measuringTextField : MeasuringTextField = new MeasuringTextField();
            measuringTextField.defaultTextFormat = new TextFormat(fontName, 22, fontColor);
            measuringTextField.text = labelName;
            
            var descriptionTextField : TextField = new TextField(
            Std.int(measuringTextField.textWidth + 15), 
            Std.int(measuringTextField.textHeight + 5), 
            labelName, 
            fontName, 
            measuringTextField.defaultTextFormat.size, 
            fontColor
            );
            m_descriptionImage = descriptionTextField;
        }
        else 
        {
            m_descriptionImage = symbolImage;
        }
        
        addChild(m_descriptionImage);
        
        resizeToLength(length);
    }
    
    override public function resizeToLength(newLength : Float) : Void
    {
        this.lineGraphicDisplayContainer.removeChildren();
        this.pixelLength = newLength;
        
        var canScaleImage : Bool = newLength > (m_scaledArrowImage.texture.nativeWidth * 2);
        if (canScaleImage) 
        {
            this.lineGraphicDisplayContainer.addChild(m_scaledArrowImage);
            m_scaledArrowImage.width = newLength;
        }
        else 
        {
            this.lineGraphicDisplayContainer.addChild(m_fullArrowImage);
            m_fullArrowImage.width = newLength;
        }
        
        m_descriptionImage.y = 0;
        m_descriptionImage.x = (newLength - m_descriptionImage.width) * 0.5;
        
        if (canScaleImage) 
        {
            m_scaledArrowImage.y = m_descriptionImage.y + m_descriptionImage.height;
        }
        else 
        {
            m_fullArrowImage.y = m_descriptionImage.y + m_descriptionImage.height;
        }
    }
    
    /**
     * Get the right arrow bounds relative to whatever frame of reference the rigid body bounds was set to.
     * Normally this is the bar model area.
     */
    public function getRightBounds(outBounds : Rectangle) : Void
    {
        var targetBounds : Rectangle = this.rigidBody.boundingRectangle;
        
        // Figure out which image is being used and determine what the bound is
        if (m_scaledArrowImage.parent != null) 
        {
            // Figure out scale amount indirectly applied
            var scaleAmount : Float = targetBounds.width / m_scaledArrowImage.width;
			// TODO: this image was replaced from the feathers library and will probably
			// need to be fixed
            var endLength : Float = m_scaledArrowImage.texture.width * scaleAmount;
            
            // Shift rectangle over to the middle bounds
            outBounds.setTo(
                    targetBounds.x + targetBounds.width - endLength,
                    targetBounds.y,
                    endLength,
                    targetBounds.height
                    );
        }
        else if (m_fullArrowImage.parent != null) 
        {
            // Each arrow is ~26 pixels long, total is ~72 pixels (middle is 20 pixels)
            var arrowWidth : Float = 26;
            var scaleAmount = m_fullArrowImage.width / targetBounds.width;
            
            outBounds.setTo((targetBounds.x + targetBounds.width - arrowWidth) * scaleAmount,
                    targetBounds.y,
                    arrowWidth,
                    targetBounds.height * scaleAmount
                    );
        }
    }
}
