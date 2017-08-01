package wordproblem.engine.barmodel.model;


import dragonbox.common.system.Identifiable;

/**
 * Defines a singular whole bar.
 * 
 * A whole bar is made up of a collection of segments and labels on those segments.
 * It is the data object that user will spend most of the time manipulating to formulate a
 * correct system.
 * 
 * An important restriction we may want to maintain is the fact that all logic to draw
 * this bar should be handled in a separate class. This simply provides an interface to the
 * underlying data of the bar model.
 */
class BarWhole
{
    /**
     * Unique id
     */
    public var id : String;
    
    /**
     * Get the segments composing the entire bar
     */
    public var barSegments : Array<BarSegment>;
    
    /**
     * Get the labels to be placed on the bar
     */
    public var barLabels : Array<BarLabel>;
    
    /**
     * Assuming a bar can have at most one comparison.
     * Null if the bar has none.
     */
    public var barComparison : BarComparison;
    
    /**
     * This value indicates that this bar is part of a larger collection of bars. This is used
     * only if a collection of bars should have some shared properties.
     */
    public var groupId : String;
    
    /**
     * There are times where we have hidden segments but do not want to show the divisions in them.
     * I.e. just have a single whole bar representing all the different segments that are hidden.
     * 
     * True if hidden segments should appear as their own division, false if all hidden should be
     * grouped together as one.
     */
    public var displayHiddenSegments : Bool = true;
    
    public function new(displayHiddenSegments : Bool, id : String = null)
    {
        this.barSegments = new Array<BarSegment>();
        this.barLabels = new Array<BarLabel>();
        this.displayHiddenSegments = displayHiddenSegments;
        
        this.id = ((id == null)) ? Std.string(Identifiable.getId()) : id;
    }
    
    /**
     * Get value of the bar from some index range
     * 
     * @param startSegmentIndex
     *      The start index of the search inclusive, if negative start at zero
     * @param endSegmentIndex
     *      The end index of the search inclusive, if negative end at last index
     * @return
     *      The combined value of all the segments in the range
     */
    public function getValue(startSegmentIndex : Int = 0, endSegmentIndex : Int = -1) : Float
    {
        if (startSegmentIndex < 0) 
        {
            startSegmentIndex = 0;
        }
        
        if (endSegmentIndex < 0) 
        {
            endSegmentIndex = barSegments.length - 1;
        }
        
        var i : Int = 0;
        var barSegment : BarSegment = null;
        var totalValue : Float = 0;
        for (i in startSegmentIndex...endSegmentIndex + 1){
            barSegment = barSegments[i];
            totalValue += barSegment.getValue();
        }
        
        return totalValue;
    }
    
    public function clone() : BarWhole
    {
        var barWholeClone : BarWhole = new BarWhole(this.displayHiddenSegments, this.id);
        var i : Int = 0;
        var numSegments : Int = this.barSegments.length;
        var barSegment : BarSegment = null;
        for (i in 0...numSegments){
            barSegment = this.barSegments[i];
            barWholeClone.barSegments.push(barSegment.clone());
        }
        
        var numLabels : Int = this.barLabels.length;
        var barLabel : BarLabel = null;
        for (i in 0...numLabels){
            barLabel = this.barLabels[i];
            barWholeClone.barLabels.push(barLabel.clone());
        }
        
        if (this.barComparison != null) 
        {
            barWholeClone.barComparison = this.barComparison.clone();
        }
        
        return barWholeClone;
    }
    
    /**
     * For data logging purposes we want to serialize a bar whole in a json like object
     * that can be easily be logged.
     * 
     * @return
     *      A compact data object representing this bar whole (containing segments, labels, and a comparison)
     */
    public function serialize() : Dynamic
    {
        var serializedSegments : Array<Dynamic> = [];
        var i : Int = 0;
        var numSegments : Int = this.barSegments.length;
        for (i in 0...numSegments){
            serializedSegments.push(this.barSegments[i].serialize());
        }
        
        var serializedLabels : Array<Dynamic> = [];
        var numLabels : Int = this.barLabels.length;
        for (i in 0...numLabels){
            serializedLabels.push(this.barLabels[i].serialize());
        }
        
        var serializedObject : Dynamic = {
            id : this.id,
            s : serializedSegments,
            l : serializedLabels,
        };
        
        if (this.barComparison != null) 
        {
            serializedObject.c = this.barComparison.serialize();
        }
        
        return serializedObject;
    }
    
    public function deserialize(data : Dynamic) : Void
    {
        var segmentData : Array<Dynamic> = data.s;
        var i : Int = 0;
        var numSegments : Int = segmentData.length;
        for (i in 0...numSegments){
            var barSegment : BarSegment = new BarSegment(0, 0, 0xFFFFFF, null);
            barSegment.deserialize(segmentData[i]);
            this.barSegments.push(barSegment);
        }
        
        var labelData : Array<Dynamic> = data.l;
        var numLabels : Int = labelData.length;
        for (i in 0...numLabels){
            var barLabel : BarLabel = new BarLabel("", 0, 0, true, false, BarLabel.BRACKET_NONE, null);
            barLabel.deserialize(labelData[i]);
            this.barLabels.push(barLabel);
        }
        
        if (Reflect.hasField(data, "c")) 
        {
            var barComparison : BarComparison = new BarComparison("", "", 0);
            barComparison.deserialize(data.c);
            this.barComparison = barComparison;
        }
        
        this.id = data.id;
    }
}
