package wordproblem.engine.component
{
	public class NameComponent extends Component
	{
		public static const TYPE_ID:String = "NameComponent";
		
		public var name:String;
		
		public function NameComponent(entityId:String, name:String)
		{
			super(entityId, TYPE_ID);
            
            this.name = name;
		}
        
        override public function deserialize(data:Object):void
        {
            this.name = data.name;
        }
	}
}