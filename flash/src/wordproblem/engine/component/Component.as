package wordproblem.engine.component
{
    /**
     * Abstract base class for a component, which is nothing more than a collection of data which must be
     * bound to exactly one entity
     */
	public class Component
	{
		/**
		 * Every component needs to be attached to an entity, this field is intended to allow for quick
		 * lookup of other components bound to the entity.
		 * 
		 * Common usage would be to iterate through a specific set of components then try to find other components
		 * belong to that entity during the iteration.
		 */
		public var entityId:String;
        
        /**
         * The component type used to quickly differentiate one component from another as well as provide a ready
         * made lookup key.
         */
		public var typeId:String;
		
		public function Component(entityId:String, 
								  typeId:String)
		{
			this.entityId = entityId;
			this.typeId = typeId;
		}
		
		/**
		 * Components are themselves responsible for cleaning up their own data
		 * if necessary
		 */
		public function dispose():void
		{
		}
        
        /**
         * Convert the current state and data of this component into a json
         * formatted string that is more easily stored.
         * 
         * The resulting data should be capable of being passed later to the deserialize function after
         * it has been json parsed to restore state.
         * 
         * @return
         *      A json object of the form {"typeId":type_id, "data":{data_attributes}}
         */
        public function serialize():Object
        {
            return null;
        }
        
        /**
         * Pull data from a json formatted object into the data fields of this component
         * 
         * Subclasses should override this function
         */
        public function deserialize(data:Object):void
        {
        }
	}
}