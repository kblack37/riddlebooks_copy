package dragonbox.common.system
{
	public class Identifiable
	{
        private static const ID_COUNTERS:Vector.<int> = Vector.<int>([1, 1]);
        
        /**
         * An entity in this case is a representation of any object that exsits in the game world.
         * 
         * This can include character, props, and even inventory items.
         * 
         * They are nothing more than a single id which is bounds to data held in components via the component
         * manager. They should not be instantiated since an entity by itself has no meaning.
         */
        public static function generateEntityId():String
        {
            return (new Date().time).toString();
        }
        
        /**
         * Get back a simple integer id
         * 
         * @param seed
         *      Used to pick an id from a set of counters, the idea is each set is used for different
         *      purposes.
         */
        public static function getId(seed:int=0):int
        {
            var value:int = ID_COUNTERS[seed];
            ID_COUNTERS[seed] = value + 1;
            return value;
        }
        
		private var m_id:int;
		
		public function Identifiable(id:int)
		{
			m_id = id;
		}
		
		public function get id():int
		{
			return m_id;
		}
		
		public function set id(value:int):void
		{
			m_id = value;
		}
	}
}