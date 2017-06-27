package wordproblem.engine.component
{
    /**
     * This component is bound to entities that use spritesheets to model a character
     * and it's various animation states.
     * 
     * It is used for the very specific case of modeling characters and requires that
     * the sheet textures are laid out in the same fashion.
     */
    public class RenderSpriteSheetComponent extends RenderableComponent
    {
        public static const TYPE_ID:String = "RenderSpriteSheetComponent";
        
        /**
         * Name of the texture representing the sprite sheet
         */
        public var spriteSheetName:String;
        
        /**
         * Width of a sub sample of the sprite sheet texture
         */
        public var subsampleWidth:Number;
        
        /**
         * Height of a sub sample of the sprite sheet texture
         */
        public var subsampleHeight:Number;
        
        public function RenderSpriteSheetComponent(entityId:String, 
                                                   spriteSheetName:String)
        {
            super(entityId, RenderSpriteSheetComponent.TYPE_ID);
            
            this.spriteSheetName = spriteSheetName;
            this.subsampleWidth = 0;
            this.subsampleHeight = 0;
        }
    }
}