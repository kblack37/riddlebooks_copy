package dragonbox.common.expressiontree;


import flash.geom.Vector3D;

import dragonbox.common.system.Identifiable;

class BaseNode extends Identifiable
{
    public static var UID_COUNTER : Int = 0;
    
    /**
     * A uid is created for every created node regardless of
     * whether it is a clone. Every node has this unique identifier.
     */
    public var UID : Int;
    
    /**
     * Unlike the uid, a node id may be potentially shared amongst multiple nodes.
     * For example if we create a clone of an expression tree, we may want to
     * have the cloned node share the same id as the original so we can easily fetch
     * a given value in both trees with just one value.
     */
    private static var ID_COUNTER : Int = 0;
    
    /**
     * The main value for this node
     */
    public var data : String;
    
    /**
     * Get the current location of this node. Used for rendering and any other
     * simulation for this node.
     */
    public var position : Vector3D;
    
    public function new(id : Int)
    {
        UID = UID_COUNTER;
        UID_COUNTER++;
        
        if (id < 0) 
        {
            id = generateId();
        }
        
        super(id);
    }
    
    public function generateId() : Int
    {
        var generatedId : Int = ID_COUNTER++;
        return generatedId;
    }
    
    /**
     * Get back the string representation for this node. This is very important for
     * decompiling an expression node subtree into a string format.
     * 
     * Should be overriden if the term value is not the same as its main data, for
     * example in the case of wild card nodes the value is a composite of a wildcard
     * prefix and its intended value.
     */
    public function toString() : String
    {
        return this.data;
    }
}
