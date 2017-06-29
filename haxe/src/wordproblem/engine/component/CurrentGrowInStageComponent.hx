package wordproblem.engine.component;


/**
 * Used for items belonging to a player, this component just has a single value what
 * stage that an entity is in. VERY IMPORTANT the stage value is reused as the index to
 * fetch the texture to use in the TextureCollectionComponent
 */
class CurrentGrowInStageComponent extends Component
{
    public static inline var TYPE_ID : String = "CurrentGrowInStageComponent";
    
    public var currentStage : Int;
    
    public function new(entityId : String)
    {
        super(entityId, TYPE_ID);
    }
    
    override public function serialize() : Dynamic
    {
        var data : Dynamic = {
            typeId : TYPE_ID,
            data : {
                currentStage : currentStage

            },

        };
        return data;
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        this.currentStage = data.currentStage;
    }
}
