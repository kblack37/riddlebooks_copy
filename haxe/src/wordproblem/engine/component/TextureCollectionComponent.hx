package wordproblem.engine.component;


/**
 * The component represents a collection of possible 'states' that an entity's 
 * appearance can take. Each object it contains describes what texture should be
 * used when rendering at a certain state.
 */
class TextureCollectionComponent extends Component
{
    public static inline var TYPE_ID : String = "TextureCollectionComponent";
    
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
    public var textureCollection : Array<Dynamic>;
    
    public function new(entityId : String)
    {
        super(entityId, TYPE_ID);
        
        this.textureCollection = new Array<Dynamic>();
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        var objects : Array<Dynamic> = data.objects;
        var numObjects : Int = objects.length;
        var i : Int;
        var object : Dynamic;
        for (i in 0...numObjects){
            this.textureCollection.push(objects[i]);
        }
    }
}
