package dragonbox.common.system
{
	import flash.utils.Dictionary;

	/**
	 * A simple implementation of a hash-map like construct.
	 */
	public class Map
	{
		private var m_backingStructure:Dictionary;
		private var m_size:int;
		
		public function Map()
		{
			m_backingStructure = new Dictionary();
			m_size = 0;
		}
		
		public function put(key:*, value:*):void
		{
			if (!contains(key))
			{
				m_size++;
			}
			
			m_backingStructure[key] = value;
		}
		
        /**
         * @return
         *      Null if the key was not assigned
         */
		public function get(key:*):*
		{
			return (m_backingStructure.hasOwnProperty(key)) ?
                m_backingStructure[key] : null;
		}
		public function contains(key:*):Boolean
		{
			var hasValue:Boolean = m_backingStructure.hasOwnProperty(key);
			return hasValue;
		}
		
        public function clear():void
        {
            for (var key:String in m_backingStructure)
            {
                delete m_backingStructure[key];
            }
            
            m_size = 0;
        }
        
		public function remove(key:*):void
		{
			if (contains(key))
			{
				m_size--;
				delete m_backingStructure[key];
			}
		}
        
        public function size():int
        {
            return m_size;
        }
		
		public function getKeys():Array
		{
			var keys:Array = new Array();
			for (var key:* in m_backingStructure)
			{
				keys.push(key);
			}
			
			return keys;
		}
		
		public function getValues():Array
		{
			var values:Array = new Array();
			for (var key:* in m_backingStructure)
			{
				values.push(m_backingStructure[key]);
			}
			
			return values;
		}
	}
}