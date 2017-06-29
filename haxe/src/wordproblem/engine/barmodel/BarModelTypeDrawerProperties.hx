package wordproblem.engine.barmodel;


/**
 * This is a struct-like class storing the necessary properties needed to visualize an exemplar
 * instance of a bar model type.
 * 
 * (Mainly used to provide documentation to all of the various kinds of properties)
 */
class BarModelTypeDrawerProperties
{
    public var color : Int;
    
    /**
     * This represents the backing data value of the given part.
     * For example, a number here can specifiy the number of boxes or
     * the relative length of a single box depending on the context of the element.
     * 
     * Also can describe a label name, necessary for instances where we want
     * more customization control over how the model is created.
     * 
     * For example the element 'a' we may instead want to appear as 'total' within
     * a bar model drawing.
     */
    public var value : String;
    
    /**
     * The alias is an placeholder value.
     * 
     * Suppose there is an element representing a box with a label on it. The value of the element is
     * a number used to determine the length of the box. However we do not necessarily want to have that
     * same value to be displayed on the label of that box, maybe instead of the number we want to show the
     * element name.
     */
    public var alias : String;
    
    /**
     * There are a few select elements in the model that may need extra textual information
     * displayed to the user explaining what it is.
     * 
     * The field gives the text content for such a label.
     */
    public var desc : String;
    
    /**
     * Elements may have several restrictions to possible values it can map to in a concrete
     * word problem.
     * For example, elements that refer to the number of parts can only be whole numbers.
     * 
     * For boolean values if a property doesn't exist, then you can assume
     * its value is false
     * Properties that are allowed:
     * type: an actual class reference to int, Number, or String
     * min: smallest allowable number
     * max: largest allowable number
     * lt: the other string element id that THIS element id should be less than
     * gt: the other string element id that THIS element id should be greater than 
     */
    public var restrictions : Dynamic;
    
    /**
     * If true then the visual representation of this bar element should be visible.
     * The only reason this would be false would be for the functionality of creating a partially
     * completed model for scaffolding purposes.
     */
    public var visible : Bool;
    
    /**
     * For now this value is used to express that bar elements associated with the part name
     * (a, b, c, ?) are of greater importance when it comes to selection.
     * Ex.) In a bar model, a bar segment might be associated with total groups a unit. A higher priority
     * on the part name for a unit will allow us to say that the shared segment should be for a unit
     */
    public var priority : Int;
    
    public function new()
    {
        this.color = 0;
        this.value = null;
        this.desc = null;
        this.alias = null;
        this.restrictions = { };
        this.visible = true;
        this.priority = -1;
    }
    
    public function clone() : BarModelTypeDrawerProperties
    {
        var clone : BarModelTypeDrawerProperties = new BarModelTypeDrawerProperties();
        clone.color = this.color;
        clone.value = this.value;
        clone.desc = this.desc;
        clone.alias = this.alias;
        clone.restrictions = this.restrictions;
        clone.visible = this.visible;
        clone.priority = this.priority;
        return clone;
    }
}
