package wordproblem.engine.component
{
    /**
     * This component exists if an entity has an animation that should be played whenever
     * it completes a stage and is ready to transition to the next one.
     * 
     * Just contains a list of texture data objects with the indixes 
     * 
     * Re-uses the texture data object
     */
    public class StageChangeAnimationComponent extends Component
    {
        public static const TYPE_ID:String = "StageChangeAnimationComponent";
        
        /**
         * Collections of objects that define the animations the entity should take
         */
        public var animationObjectCollection:Vector.<Object>;
        
        public function StageChangeAnimationComponent(entityId:String)
        {
            super(entityId, StageChangeAnimationComponent.TYPE_ID);
        }
        
        override public function deserialize(data:Object):void
        {
            this.animationObjectCollection = new Vector.<Object>();
            
            var objects:Array = data.objects;
            var numObjects:int = objects.length;
            var i:int;
            var object:Object;
            for (i = 0; i < numObjects; i++)
            {
                this.animationObjectCollection.push(objects[i]);
            }
        }
    }
}