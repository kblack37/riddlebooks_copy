package wordproblem.playercollections.items
{
    import flash.text.TextFormat;
    
    import dragonbox.common.util.XTextField;
    
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.textures.Texture;
    
    import wordproblem.engine.text.GameFonts;
    import wordproblem.engine.text.MeasuringTextField;
    import wordproblem.resource.AssetManager;
    
    /**
     * This is a simple screen that shows details about a single item
     */
    public class PlayerCollectionItemScreen extends Sprite
    {
        private var m_nameImage:Image;
        private var m_descriptionImage:Image;
        
        public function PlayerCollectionItemScreen(textureName:String, 
                                                   itemName:String, 
                                                   itemDescription:String,
                                                   width:Number,
                                                   height:Number,
                                                   assetManager:AssetManager)
        {
            super();
            
            var imageContainerWidth:Number = 250;
            var imageContainerHeight:Number = 300;
            
            // Stretch the item so it fits one of the minimum bounds
            var minimumWidth:Number = 200;
            var minimumHeight:Number = 200;
            var scaleFactor:Number = 1.0;
            var texture:Texture = assetManager.getTexture(textureName);
            if (texture.width < minimumWidth && texture.height < minimumHeight)
            {
                var horizontalScaleFactor:Number = minimumWidth / texture.width;
                var verticalScaleFactor:Number = minimumHeight / texture.height;
                scaleFactor = Math.max(horizontalScaleFactor, verticalScaleFactor);
            }
            
            var textFormat:TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 32, 0xFFFFFF);
            var measuringTextField:MeasuringTextField = new MeasuringTextField();
            measuringTextField.defaultTextFormat = textFormat;
            measuringTextField.text = itemName;
            var nameImage:Image = XTextField.createWordWrapTextfield(
                textFormat, 
                itemName, measuringTextField.textWidth + 15, 60
            );
            nameImage.x = (width - nameImage.width) * 0.5;
            nameImage.y = 0;
            addChild(nameImage);
            m_nameImage = nameImage;
            
            var image:Image = new Image(texture);
            image.scaleX = image.scaleY = scaleFactor;
            image.x = (width - image.width) * 0.5;//(imageContainerWidth - image.width) * 0.5;
            image.y = (imageContainerHeight - image.height) * 0.5 + nameImage.height + nameImage.y;
            addChild(image);
            
            var descriptionImage:Image = XTextField.createWordWrapTextfield(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 28, 0xFFFFFF), itemDescription, 300, 300);
            descriptionImage.x = Math.max(imageContainerWidth, image.width);
            descriptionImage.y = nameImage.height + 10;
            //addChild(descriptionImage);
            m_descriptionImage = descriptionImage;
        }
        
        override public function dispose():void
        {
            // Get rid of dynamically created texture
            m_descriptionImage.removeFromParent(true);
            m_descriptionImage.texture.dispose();
            
            m_nameImage.removeFromParent(true);
            m_nameImage.texture.dispose();
            
            super.dispose();
        }
    }
}