package wordproblem.display
{
    import flash.geom.Point;
    import flash.text.TextFormat;
    
    import dragonbox.common.math.util.MathUtil;
    
    import starling.display.Sprite;
    import starling.text.TextField;
    
    import wordproblem.engine.text.MeasuringTextField;
    
    /**
     * Draw some text that loops around a curve.
     * 
     * All control points should be relative to the coordinate system of this canvas
     */
    public class CurvedText extends Sprite
    {
        /**
         * Maintain a list of textfields for each character as we will need to orient each one manually
         * along the curve. A null entry indicates additional spacing should be used.
         * 
         * HACK:
         * We want the normals of the curve to eminate AWAY from some central point
         */
        private var m_textFieldsForCharacters:Vector.<TextField>;
        
        public function CurvedText(text:String, 
                                   textFormat:TextFormat, 
                                   controlPointA:Point, 
                                   controlPointB:Point, 
                                   controlPointC:Point, 
                                   controlPointD:Point)
        {
            super();
            
            m_textFieldsForCharacters = new Vector.<TextField>();
            
            // Measure how wide a character should be, use that as the spacing when
            // laying out objects in a curve.
            var measuringTextField:MeasuringTextField = new MeasuringTextField();
            measuringTextField.defaultTextFormat = textFormat;
            measuringTextField.text = "W";
            var widthForSingleCharacter:Number = measuringTextField.textWidth;
            var heightForSingleCharacter:Number = measuringTextField.textHeight + 3;
            
            var xOffsets:Vector.<Number> = new Vector.<Number>();
            
            // Target text needs to be decomposed into individual characters and manually
            // repositioned along the curve
            var i:int;
            var numCharacters:int = text.length;
            var xOffset:Number = 0.0;
            var totalCharacterWidth:Number = 0;
            for (i = 0; i < numCharacters; i++)
            {
                var character:String = text.charAt(i);
                var textField:TextField = null;
                measuringTextField.text = character;
                
                if (character != " ")
                {
                    textField = new TextField(
                        widthForSingleCharacter + 6, 
                        heightForSingleCharacter, 
                        character, 
                        textFormat.font, 
                        textFormat.size as Number, 
                        textFormat.color as uint,
                        true
                    );
                    textField.pivotX = textField.width * 0.5;
                    textField.pivotY = textField.height * 0.5;
                }
                
                xOffsets.push(xOffset);
                m_textFieldsForCharacters.push(textField);
                xOffset += widthForSingleCharacter;
                totalCharacterWidth += widthForSingleCharacter;
            }
            
            // We approximate the length of the curve and compare to total character width
            var curveLength:Number = MathUtil.calculateCubicBezierLength(controlPointA, controlPointB, controlPointC, controlPointD, 50);
            var deltaLength:Number = curveLength - totalCharacterWidth;
            var startingOffsetPropotion:Number = (deltaLength * 0.5) / curveLength;
            
            // We want to perform a mapping of the position of each character when laid out in a straight line
            // to a value between 0-1.0. This gives a t value which tells us the position on the curve
            var pointLocation:Point = new Point();
            for (i = 0; i < xOffsets.length; i++)
            {
                xOffset = xOffsets[i];
                var t:Number = xOffset / curveLength + startingOffsetPropotion;
                MathUtil.calculateCubicBezierPoint(t, controlPointA, controlPointB, controlPointC, controlPointD, pointLocation);
                
                textField = m_textFieldsForCharacters[i];
                if (textField != null)
                {
                    textField.x = pointLocation.x;
                    textField.y = pointLocation.y;
                    addChild(textField);
                    
                    // Need to rotate the text properly
                    // Take a normal vector on the curve and calculate the angle from that and the vertical vector(0, -1)
                    var normalY:Number = MathUtil.calculateNormalSlopeToCubicBezierPoint(t, controlPointA, controlPointB, controlPointC, controlPointD);
                    var normalX:Number = 1;
                    var cosa:Number = (-1 * normalY) / Math.sqrt(normalY * normalY + normalX * normalX);
                    
                    // Avoid getting any letters that flip upside down
                    var angle:Number = Math.acos(cosa);
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
        
        override public function dispose():void
        {
            super.dispose();
            
            var i:int;
            for (i = 0; i < m_textFieldsForCharacters.length; i++)
            {
                var textField:TextField = m_textFieldsForCharacters[i];
                if (textField != null)
                {
                    textField.removeFromParent(true);
                }
            }
            
            m_textFieldsForCharacters.length = 0;
        }
    }
}