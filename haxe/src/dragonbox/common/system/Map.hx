package dragonbox.common.system;


import flash.utils.Dictionary;

/**
	 * A simple implementation of a hash-map like construct.
	 */
class Map
{
    private var m_backingStructure : Dictionary<Dynamic, Dynamic>;
    private var m_size : Int;
    
    public function new()
    {
        m_backingStructure = new Dictionary();
        m_size = 0;
    }
    
    public function put(key : Dynamic, value : Dynamic) : Void
    {
        if (!contains(key)) 
        {
            m_size++;
        }
        
        Reflect.setField(m_backingStructure, Std.string(key), value);
    }
    
    /**
     * @return
     *      Null if the key was not assigned
     */
    public function get(key : Dynamic) : Dynamic
    {
        return ((m_backingStructure.exists(key))) ? 
        Reflect.field(m_backingStructure, Std.string(key)) : null;
    }
    public function contains(key : Dynamic) : Bool
    {
        var hasValue : Bool = m_backingStructure.exists(key);
        return hasValue;
    }
    
    public function clear() : Void
    {   
        m_size = 0;
    }
    
    public function remove(key : Dynamic) : Void
    {
        if (contains(key)) 
        {
            m_size--;
        }
    }
    
    public function size() : Int
    {
        return m_size;
    }
    
    public function getKeys() : Array<Dynamic>
    {
        var keys : Array<Dynamic> = new Array<Dynamic>();
        for (key in Reflect.fields(m_backingStructure))
        {
            keys.push(key);
        }
        
        return keys;
    }
    
    public function getValues() : Array<Dynamic>
    {
        var values : Array<Dynamic> = new Array<Dynamic>();
        for (key in Reflect.fields(m_backingStructure))
        {
            values.push(Reflect.field(m_backingStructure, key));
        }
        
        return values;
    }
}
