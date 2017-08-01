package dragonbox.common.system;


class Stack
{
    public var objectList(get, never) : Array<Dynamic>;
    public var count(get, never) : Int;

    public var stack : Array<Dynamic>;
    
    public function new()
    {
        this.stack = new Array<Dynamic>();
    }
    
    private function get_objectList() : Array<Dynamic>
    {
        return this.stack;
    }
    
    private function get_count() : Int
    {
        return this.stack.length;
    }
    
    public function getAt(index : Int) : Dynamic
    {
        return this.stack[index];
    }
    
    public function push(object : Dynamic) : Void
    {
        this.stack.push(object);
    }
    
    public function pop() : Dynamic
    {
        return this.stack.pop();
    }
    
    /**
		 * Pop items up until a given object id
		 * 
		 * @return
		 * 		List of popped items (not including the item with the given id)
		 */
    public function popTo(id : Int) : Array<Dynamic>
    {
        var popped : Array<Dynamic> = new Array<Dynamic>();
        
        var object : Dynamic = null;
        while (peek().id != id)
        {
            object = pop();
            popped.push(object);
        }
        
        return popped;
    }
    
    public function peek() : Dynamic
    {
        return this.stack[this.stack.length - 1];
    }
}
