package wordproblem.engine.component
{
    /**
     * The component represents a collection of possible 'states' that an entity's 
     * appearance can take. Each object it contains describes what texture should be
     * used when rendering at a certain state.
     */
    public class TextureCollectionComponent extends Component
    {
        public static const TYPE_ID:String = "TextureCollectionComponent";
        
        /**
         * List of ways the entity can be drawn.
         * 
         * Either a single static image, a static image from an atlas, or an
         * animated image built from a single atlas.
         * 
         * {type:SpriteSheetAnimated, 
         * textureName:<name of spritesheet>, 
         * subtexturePrefix:<the stuff before frame numbers>, 
         * totalFrames:<Can be calculated from sheet>, 
         * delay:<seconds before looping back>
         * }
         * 
         * {type:SpriteSheetStatic
         * textureName:<name of spritesheet>
         * subtexture:<full name of part of spritesheet to sample>,
         * crop:<object with x,y,width,height properties that define how much to further crop the texture>
         * }
         * 
         * {type:ImageStatic
         * textureName:<name of single texture>,
         * scale:<amount the image should be scaled from original size>,
         * color:<string hex color that should be applied to the texture>
         * }
         */
        public var textureCollection:Vector.<Object>;
        
        public function TextureCollectionComponent(entityId:String)
        {
            super(entityId, TYPE_ID);
            
            this.textureCollection = new Vector.<Object>();
        }
        
        override public function deserialize(data:Object):void
        {
            var objects:Array = data.objects;
            var numObjects:int = objects.length;
            var i:int;
            var object:Object;
            for (i = 0; i < numObjects; i++)
            {
                this.textureCollection.push(objects[i]);
            }
        }
    }
}