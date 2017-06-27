package wordproblem.engine.component
{
    /**
     * Component has a short summary that talks about the entity in more detail.
     */
    public class DescriptionComponent extends Component
    {
        public static const TYPE_ID:String = "DescriptionComponent";
        
        public var desc:String;
        
        public function DescriptionComponent(entityId:String)
        {
            super(entityId, DescriptionComponent.TYPE_ID);
        }
        
        override public function deserialize(data:Object):void
        {
            this.desc = data.desc;
        }
    }
}