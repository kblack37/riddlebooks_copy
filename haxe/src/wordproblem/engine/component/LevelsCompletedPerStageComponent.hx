package wordproblem.engine.component;


/**
 * This component indicates that an item will only change stages if some
 * number of levels have been completed per stage.
 */
class LevelsCompletedPerStageComponent extends Component
{
    public static inline var TYPE_ID : String = "LevelsCompletedPerStageComponent";
    
    /**
     * This list treats the index as the value of the stage an item can be at and the
     * value is the number of levels that must be completed to advance from that stage
     * to the next.
     * 
     * As such it's length should be one less than the total number of stages an item
     * can be at.
     */
    public var stageToLevelsCompleted : Array<Int>;
    
    public function new(entityId : String)
    {
        super(entityId, TYPE_ID);
        
        stageToLevelsCompleted = new Array<Int>();
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        var stagesArray : Array<Dynamic> = data.stageToLevelsCompleted;
        for (i in 0...stagesArray.length){
            this.stageToLevelsCompleted.push(stagesArray[i]);
        }
    }
}
