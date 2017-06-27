package wordproblem.engine.component
{
    /**
     * Used for items belonging to a player, this component just has a single value what
     * stage that an entity is in. VERY IMPORTANT the stage value is reused as the index to
     * fetch the texture to use in the TextureCollectionComponent
     */
    public class CurrentGrowInStageComponent extends Component
    {
        public static const TYPE_ID:String = "CurrentGrowInStageComponent";
        
        public var currentStage:int;
        
        public function CurrentGrowInStageComponent(entityId:String)
        {
            super(entityId, TYPE_ID);
        }
        
        override public function serialize():Object
        {
            var data:Object = {
                typeId:TYPE_ID,
                data:{currentStage:currentStage}
            };
            return data;
        }
        
        override public function deserialize(data:Object):void
        {
            this.currentStage = data.currentStage;
        }
    }
}