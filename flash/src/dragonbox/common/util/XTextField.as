package dragonbox.common.util
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import starling.display.Image;
	import starling.textures.Texture;
	
	import wordproblem.engine.text.GameFonts;
	import wordproblem.engine.text.MeasuringTextField;

	public class XTextField
	{
		public static function resizeDynamicText(textField:TextField, textToReplace:String):void
		{
			textField.selectable = false;
			const originalTextWidth:Number = textField.width;
			
			textField.text = textToReplace;
			var nextTextFieldWidth:Number = textField.textWidth + 5;
			textField.width = nextTextFieldWidth;
			
			if (textField.width > originalTextWidth)
			{
				const scaleFactor:Number = originalTextWidth / textField.width;
				textField.scaleX *= scaleFactor;
				textField.scaleY *= scaleFactor;
			}
		}
		
		public static function createTextField(text:String, size:Number = 60, color:uint = 0xFFCC00):TextField
		{			
			var textFormat:TextFormat = new TextFormat("Urban Brush 32", size, color);
			textFormat.align = TextFormatAlign.CENTER;
			
			const textField:TextField = new TextField();
			textField.defaultTextFormat = textFormat;
			textField.embedFonts = true;
			textField.selectable = false;
			textField.embedFonts = true;
			textField.text = text;
			
			// For some reason part of the text gets cutoff without this padding
			textField.height = textField.textHeight + 10;
			textField.width = textField.textWidth + 5;
			
			return textField;
		}
        
        public static function createWordWrapTextfield(textFormat:TextFormat, text:String, width:Number, height:Number, verticalAlign:Boolean=false):Image
        {
            var descriptionMeasuringTextField:MeasuringTextField = new MeasuringTextField();
            descriptionMeasuringTextField.embedFonts = GameFonts.getFontIsEmbedded(textFormat.font);
            descriptionMeasuringTextField.wordWrap = true;
            descriptionMeasuringTextField.defaultTextFormat = textFormat;
            descriptionMeasuringTextField.width = width;
            descriptionMeasuringTextField.text = text;
            descriptionMeasuringTextField.height = height;
            
            var ty:Number = (verticalAlign) ? (height - descriptionMeasuringTextField.textHeight) * 0.5 : 0;
            
            var textBitmapData:BitmapData = new BitmapData(descriptionMeasuringTextField.width, descriptionMeasuringTextField.height, true, 0xFF0000);
            textBitmapData.draw(descriptionMeasuringTextField, new Matrix(1, 0, 0, 1, 0, ty));
            
            var textFieldTexture:Texture = Texture.fromBitmapData(textBitmapData, false);
            var wordWrapTextfield:Image = new Image(textFieldTexture);
            return wordWrapTextfield;
        }
	}
}