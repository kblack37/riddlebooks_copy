package wordproblem.engine.component;


/**
 * This component exists if an entity has an animation that should be played whenever
 * it completes a stage and is ready to transition to the next one.
 * 
 * Just contains a list of texture data objects with the indixes 
 * 
 * Re-uses the texture data object
 */
class StageChangeAnimationComponent extends Component
{
    public static inline var TYPE_ID : String = "StageChangeAnimationComponent";
    
    /**
     * Collections of objects that define the animations the entity should take
     */
    public var animationObjectCollection : Array<Dynamic>;
    
    public function new(entityId : String)
    {
        super(entityId, StageChangeAnimationComponent.TYPE_ID);
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        this.animationObjectCollection = new Array<Dynamic>();
        
        var objects : Array<Dynamic> = data.objects;
        var numObjects : Int = objects.length;
        var i : Int;
        var object : Dynamic;
        for (i in 0...numObjects){
            this.animationObjectCollection.push(objects[i]);
        }
    }
}
