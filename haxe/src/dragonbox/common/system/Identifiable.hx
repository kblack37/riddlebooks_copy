package dragonbox.common.system;


class Identifiable
{
    public var id(get, set) : Int;

    private static var ID_COUNTERS : Array<Int> = [1, 1];
    
    /**
     * An entity in this case is a representation of any object that exsits in the game world.
     * 
     * This can include character, props, and even inventory items.
     * 
     * They are nothing more than a single id which is bounds to data held in components via the component
     * manager. They should not be instantiated since an entity by itself has no meaning.
     */
    public static function generateEntityId() : String
    {
        return Std.string((Date.now().time));
    }
    
    /**
     * Get back a simple integer id
     * 
     * @param seed
     *      Used to pick an id from a set of counters, the idea is each set is used for different
     *      purposes.
     */
    public static function getId(seed : Int = 0) : Int
    {
        var value : Int = ID_COUNTERS[seed];
        ID_COUNTERS[seed] = value + 1;
        return value;
    }
    
    private var m_id : Int;
    
    public function new(id : Int)
    {
        m_id = id;
    }
    
    private function get_id() : Int
    {
        return m_id;
    }
    
    private function set_id(value : Int) : Int
    {
        m_id = value;
        return value;
    }
}
