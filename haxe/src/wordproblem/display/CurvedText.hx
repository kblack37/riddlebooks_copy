package wordproblem.display;


import openfl.geom.Point;
import openfl.text.TextFormat;

import dragonbox.common.math.util.MathUtil;

import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.text.TextField;

import wordproblem.engine.text.MeasuringTextField;

/**
 * Draw some text that loops around a curve.
 * 
 * All control points should be relative to the coordinate system of this canvas
 */
class CurvedText extends Sprite
{
    /**
     * Maintain a list of textfields for each character as we will need to orient each one manually
     * along the curve. A null entry indicates additional spacing should be used.
     * 
     * HACK:
     * We want the normals of the curve to eminate AWAY from some central point
     */
    private var m_textFieldsForCharacters : Array<DisplayObject>;
    
    public function new(text : String,
            textFormat : TextFormat,
            controlPointA : Point,
            controlPointB : Point,
            controlPointC : Point,
            controlPointD : Point)
    {
        super();
        
        m_textFieldsForCharacters = new Array<DisplayObject>();
        
        // Measure how wide a character should be, use that as the spacing when
        // laying out objects in a curve.
        var measuringTextField : MeasuringTextField = new MeasuringTextField();
        measuringTextField.defaultTextFormat = textFormat;
        measuringTextField.text = "W";
        var widthForSingleCharacter : Int = Std.int(measuringTextField.textWidth);
        var heightForSingleCharacter : Int = Std.int(measuringTextField.textHeight + 3);
        
        var xOffsets : Array<Float> = new Array<Float>();
        
        // Target text needs to be decomposed into individual characters and manually
        // repositioned along the curve
        var i : Int = 0;
        var numCharacters : Int = text.length;
        var xOffset : Float = 0.0;
        var totalCharacterWidth : Float = 0;
        for (i in 0...numCharacters){
            var character : String = text.charAt(i);
            var textField : PivotSprite = null;
            measuringTextField.text = character;
            
            if (character != " ") 
            {
                textField = new PivotSprite();
				var textFieldInContainer = new TextField();
                textFieldInContainer.width = widthForSingleCharacter + 6;
                textFieldInContainer.height = heightForSingleCharacter;
                textFieldInContainer.text = character;
                textFieldInContainer.setTextFormat(new TextFormat(textFormat.font, textFormat.size, textFormat.color, true));
                textField.pivotX = textFieldInContainer.width * 0.5;
                textField.pivotY = textFieldInContainer.height * 0.5;
				textField.addChild(textFieldInContainer);
            }
            
            xOffsets.push(xOffset);
            m_textFieldsForCharacters.push(textField);
            xOffset += widthForSingleCharacter;
            totalCharacterWidth += widthForSingleCharacter;
        }  
		
		// We approximate the length of the curve and compare to total character width  
        var curveLength : Float = MathUtil.calculateCubicBezierLength(controlPointA, controlPointB, controlPointC, controlPointD, 50);
        var deltaLength : Float = curveLength - totalCharacterWidth;
        var startingOffsetPropotion : Float = (deltaLength * 0.5) / curveLength;
        
        // We want to perform a mapping of the position of each character when laid out in a straight line
        // to a value between 0-1.0. This gives a t value which tells us the position on the curve
        var pointLocation : Point = new Point();
        for (i in 0...xOffsets.length){
            xOffset = xOffsets[i];
            var t : Float = xOffset / curveLength + startingOffsetPropotion;
            MathUtil.calculateCubicBezierPoint(t, controlPointA, controlPointB, controlPointC, controlPointD, pointLocation);
            
            var textField = m_textFieldsForCharacters[i];
            if (textField != null) 
            {
                textField.x = pointLocation.x;
                textField.y = pointLocation.y;
                addChild(textField);
                
                // Need to rotate the text properly
                // Take a normal vector on the curve and calculate the angle from that and the vertical vector(0, -1)
                var normalY : Float = MathUtil.calculateNormalSlopeToCubicBezierPoint(t, controlPointA, controlPointB, controlPointC, controlPointD);
                var normalX : Float = 1;
                var cosa : Float = (-1 * normalY) / Math.sqrt(normalY * normalY + normalX * normalX);
                
                // Avoid getting any letters that flip upside down
                var angle : Float = Math.acos(cosa);
                if (angle > Math.PI * 0.5) 
                {
                    angle -= Math.PI;
                }  
				
				// HACK: If the normal is completely vertical, then there should not be any angle.  
                // The calculation handles this case incorrectly so we manually override it.  
                if (normalY == -1) 
                {
                    angle = 0;
                }
                textField.rotation = angle;
            }
        }
    }
    
    public function dispose() : Void
    {
        var i : Int = 0;
        for (i in 0...m_textFieldsForCharacters.length){
            var textField : DisplayObject = m_textFieldsForCharacters[i];
            if (textField != null) 
            {
				if (textField.parent != null) textField.parent.removeChild(textField);
				textField = null;
            }
        }
        
		m_textFieldsForCharacters = new Array<DisplayObject>();
    }
}
