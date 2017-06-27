package dragonbox.common.system
{
	public class Stack
	{
		public var stack:Vector.<Object>;
		
		public function Stack()
		{
			this.stack = new Vector.<Object>();
		}
		
		public function get objectList():Vector.<Object>
		{
			return this.stack;
		}
		
		public function get count():int
		{
			return this.stack.length;
		}
		
		public function getAt(index:int):*
		{
			return this.stack[index];
		}
		
		public function push(object:*):void
		{
			this.stack.push(object);
		}
		
		public function pop():*
		{
			return this.stack.pop();
		}
		
		/**
		 * Pop items up until a given object id
		 * 
		 * @return
		 * 		List of popped items (not including the item with the given id)
		 */
		public function popTo(id:int):Vector.<Object>
		{
			const popped:Vector.<Object> = new Vector.<Object>();
			
			var object:*;
			while(peek().id != id)
			{
				object = pop();
				popped.push(object);
			}
			
			return popped;
		}
		
		public function peek():*
		{
			return this.stack[this.stack.length-1];
		}
	}
}