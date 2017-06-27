package wordproblem.engine.component
{
    /**
     * This component indicates that an item will only change stages if some
     * number of levels have been completed per stage.
     */
    public class LevelsCompletedPerStageComponent extends Component
    {
        public static const TYPE_ID:String = "LevelsCompletedPerStageComponent";
        
        /**
         * This list treats the index as the value of the stage an item can be at and the
         * value is the number of levels that must be completed to advance from that stage
         * to the next.
         * 
         * As such it's length should be one less than the total number of stages an item
         * can be at.
         */
        public var stageToLevelsCompleted:Vector.<int>;
        
        public function LevelsCompletedPerStageComponent(entityId:String)
        {
            super(entityId, TYPE_ID);
            
            stageToLevelsCompleted = new Vector.<int>();
        }
        
        override public function deserialize(data:Object):void
        {
            var stagesArray:Array = data.stageToLevelsCompleted;
            for (var i:int = 0; i < stagesArray.length; i++)
            {
                this.stageToLevelsCompleted.push(stagesArray[i]);
            }
        }
    }
}