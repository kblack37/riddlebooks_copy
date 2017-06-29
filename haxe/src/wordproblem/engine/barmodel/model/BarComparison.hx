package wordproblem.engine.barmodel.model;


import dragonbox.common.system.Identifiable;

/**
 * Defines a span covering an empty space within a bar.
 * 
 * It is used for comparison between two bars, namely to label a difference.
 * It differs from a label in that it does not reference a span of segments
 */
class BarComparison
{
    /**
     * Unique id
     */
    public var id : String;
    
    /**
     * The id of another bar which this comparison is targeting
     */
    public var barWholeIdComparedTo : String;
    
    /**
     * The index of the segment in the bar to compare against
     * that this comparison should snap to. (Snap to the right edge)
     */
    public var segmentIndexComparedTo : Int;
    
    /**
     * Some numeric value indicating how much the line should span.
     */
    public var value : String;
    
    /**
     * The tint to apply to the comparison arrow
     */
    public var color : Int;
    
    public function new(value : String, barWholeIdComparedTo : String, segmentIndexComparedTo : Int, id : String = null, color : Int = 0xFFFFFF)
    {
        this.value = value;
        this.barWholeIdComparedTo = barWholeIdComparedTo;
        this.segmentIndexComparedTo = segmentIndexComparedTo;
        
        this.id = ((id == null)) ? Std.string(Identifiable.getId(1)) : id;
        this.color = color;
    }
    
    public function clone() : BarComparison
    {
        var barComparison : BarComparison = new BarComparison(
        this.value, 
        this.barWholeIdComparedTo, 
        this.segmentIndexComparedTo, 
        this.id, 
        );
        return barComparison;
    }
    
    /**
     * For data logging purposes we want to serialize a comparison in a json like object
     * that can be easily be logged.
     * 
     * @return
     *      A compact data object representing this comparison
     */
    public function serialize() : Dynamic
    {
        var serializedObject : Dynamic = {
            id : this.id,
            v : this.value,
            bid : this.barWholeIdComparedTo,
            i : this.segmentIndexComparedTo,

        };
        return serializedObject;
    }
    
    public function deserialize(data : Dynamic) : Void
    {
        this.id = data.id;
        this.value = data.v;
        this.barWholeIdComparedTo = data.bid;
        this.segmentIndexComparedTo = data.i;
    }
}
