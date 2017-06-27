package wordproblem.playercollections.items
{
    import flash.geom.Rectangle;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    
    import dragonbox.common.util.XColor;
    import dragonbox.common.util.XTextField;
    
    import feathers.display.Scale9Image;
    import feathers.textures.Scale9Textures;
    
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.text.TextField;
    
    import wordproblem.engine.text.GameFonts;
    import wordproblem.resource.AssetManager;
    
    /**
     * Simple button representing a cateogry for a collection item.
     */
    public class PlayerCollectionCategoryButton extends Sprite
    {
        private var m_categoryInformationObject:Object;
        
        private var m_normalBackground:Scale9Image;
        private var m_selectedBackground:Scale9Image;
        
        public function PlayerCollectionCategoryButton(categoryInformationObject:Object, 
                                                       assetManager:AssetManager, 
                                                       width:Number, 
                                                       height:Number, 
                                                       upColor:uint)
        {
            super();
            
            m_categoryInformationObject = categoryInformationObject;
            
            var scale9Texture:Scale9Textures = new Scale9Textures(
                assetManager.getTexture("button_white"),
                new Rectangle(8, 8, 16, 16)
            );
            m_normalBackground = new Scale9Image(scale9Texture);
            m_normalBackground.color = upColor;
            
            m_selectedBackground = new Scale9Image(scale9Texture);
            m_selectedBackground.color = XColor.shadeColor(upColor, 0.3);
            
            var totalWidth:Number = width;
            var totalHeight:Number = height;
            m_normalBackground.width = totalWidth;
            m_normalBackground.height = totalHeight;
            m_selectedBackground.width = totalWidth;
            m_selectedBackground.height = totalHeight;
            this.selected = false;
            
            var categoryNameImage:Image = XTextField.createWordWrapTextfield(
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 28, 0xFFFFFF, null, null, null, null, null, TextFormatAlign.CENTER), 
                categoryInformationObject.id, 
                width * 0.5, height, true
            );
            addChild(categoryNameImage);
            
            var itemsEarned:int = categoryInformationObject.numItemsEarned;
            var itemsTotal:int = categoryInformationObject.itemIds.length;
            var categoryProgressTextfield:TextField = new TextField(170, height, itemsEarned + "/" + itemsTotal, GameFonts.DEFAULT_FONT_NAME, 32, 0xFFFFFF);
            categoryProgressTextfield.x = categoryNameImage.x + categoryNameImage.width;
            addChild(categoryProgressTextfield);
        }
        
        public function getCategoryInformationObject():Object
        {
            return m_categoryInformationObject;
        }
        
        public function set selected(value:Boolean):void
        {
            m_normalBackground.removeFromParent();
            m_selectedBackground.removeFromParent();
            
            var backgroundToUse:DisplayObject = (value) ? m_selectedBackground : m_normalBackground;
            addChildAt(backgroundToUse, 0);
        }
        
        override public function dispose():void
        {
            // Clear out the background textures
            m_normalBackground.removeFromParent(true);
            m_selectedBackground.removeFromParent(true);
            
            super.dispose();
        }
    }
}