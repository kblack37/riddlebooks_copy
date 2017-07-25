package wordproblem.engine.barmodel.model;


import dragonbox.common.system.Identifiable;


/**
 * Defines the data associated with a label that is to be displayed
 * spanning some number of segments within a bar. Labels can be positioned anywhere,
 * either horizontal or vertical.
 */
class BarLabel
{
    public var displayedName(never, set) : String;

    /**
     * No bracket, the label name or image should be pasted right on top of the segment.
     * Only works if the label is on a single segment
     */
    public static inline var BRACKET_NONE : String = "none";
    
    /**
     * A bracket with straight edges
     */
    public static inline var BRACKET_STRAIGHT : String = "straight";
    
    /**
     * Unique id
     */
    public var id : String;
    
    /**
     * The value that the span contained within the label bounds represents.
     * Note this slightly differs from a name since this value is what is actually used in crafting
     * the expression, for example a variable might have the name 'x' but name 'chickens and ducks'
     */
    public var value : String;
    
    /**
     * The index of the segment/item the label bracket starts at.
     */
    public var startSegmentIndex : Int;
    
    /**
     * The index of the segment/item the label bracket ends at.
     */
    public var endSegmentIndex : Int;
    
    /**
     * If true the label should be oriented in a horizontal fashion
     */
    public var isHorizontal : Bool;
    
    /**
     * If true the label should lie on top or to the left of the bar
     * If false it should lie on the bottom or the right of the bar
     */
    public var isAboveSegment : Bool;
    
    /**
     * Specifies how a bracket should be drawn
     * (Look at the const values in the BarLabel class)
     */
    public var bracketStyle : String;
    
    /**
     * Indicator if this label is a placeholder for another value.
     * (Useful if we want hidden values to be drawn differently)
     * If null the label should not be hidden
     */
    public var hiddenValue : String;
    
    /**
     * This is a special case where we want a single contiguous segment to have a label represented by several pictures of items
     * For example we have a single segment with the value 4 and the label is 4 apples. This value is 4 to indicate the label
     * should actually produce 4 separate apple images.
     */
    public var numImages : Int;
    
    /**
     * Extra tint to apply to the bracket.
     */
    public var color : Int;
    
    /**
     * For logging purposes, this will show the label name that was visible to the user at the given moment.
     * Currently, only a write only field
     * 
     * IMPORTANT: Since we are attaching a dependency to the view logic, we need to make sure that the view has redrawn
     * itself BEFORE serialization so this property can be set.
     */
    private var m_displayedName : String;
    
    public function new(value : String,
            startSegmentIndex : Int,
            endSegmentIndex : Int,
            isHorizontal : Bool,
            isTop : Bool,
            bracketStyle : String,
            hiddenValue : String,
            id : String = null,
            color : Int = 0xFFFFFF)
    {
        this.value = value;
        this.startSegmentIndex = startSegmentIndex;
        this.endSegmentIndex = endSegmentIndex;
        this.isHorizontal = isHorizontal;
        this.isAboveSegment = isTop;
        this.bracketStyle = bracketStyle;
        this.hiddenValue = hiddenValue;
        this.numImages = 1;
        
        this.id = ((id == null)) ? Std.string(Identifiable.getId()) : id;
        this.color = color;
        m_displayedName = value;
    }
    
    public function clone() : BarLabel
    {
        var barLabelClone : BarLabel = new BarLabel(
        this.value, 
        this.startSegmentIndex, 
        this.endSegmentIndex, 
        this.isHorizontal, 
        this.isAboveSegment, 
        this.bracketStyle, 
        this.hiddenValue, 
        this.id
        );
        barLabelClone.numImages = this.numImages;
        return barLabelClone;
    }
    
    private function set_displayedName(value : String) : String
    {
        m_displayedName = value;
        return value;
    }
    
    /**
     * For data logging purposes we want to serialize a label in a json like object
     * that can be easily be logged.
     * 
     * @return
     *      A compact data object representing this label
     */
    public function serialize() : Dynamic
    {
        var orientation : String = ((this.bracketStyle == BarLabel.BRACKET_NONE)) ? "top" : "bottom";
        var serializedObject : Dynamic = {
            id : this.id,
            v : this.value,
            s : this.startSegmentIndex,
            e : this.endSegmentIndex,
            o : orientation,
            dn : m_displayedName,

        };
        return serializedObject;
    }
    
    public function deserialize(data : Dynamic) : Void
    {
        this.id = data.id;
        this.value = data.v;
        this.startSegmentIndex = data.s;
        this.endSegmentIndex = data.e;
        
        var orientation : String = data.o;
        if (orientation == "top") 
        {
            this.bracketStyle = BarLabel.BRACKET_NONE;
        }
        else 
        {
            this.bracketStyle = BarLabel.BRACKET_STRAIGHT;
        }
        
        if (data.exists("dn")) 
        {
            m_displayedName = data.dn;
        }
    }
}
