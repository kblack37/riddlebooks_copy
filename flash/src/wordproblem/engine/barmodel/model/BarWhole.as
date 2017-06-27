package wordproblem.engine.barmodel.model
{
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
    public class BarWhole
    {
        /**
         * Unique id
         */
        public var id:String;
        
        /**
         * Get the segments composing the entire bar
         */
        public var barSegments:Vector.<BarSegment>;
        
        /**
         * Get the labels to be placed on the bar
         */
        public var barLabels:Vector.<BarLabel>;
        
        /**
         * Assuming a bar can have at most one comparison.
         * Null if the bar has none.
         */
        public var barComparison:BarComparison;
        
        /**
         * This value indicates that this bar is part of a larger collection of bars. This is used
         * only if a collection of bars should have some shared properties.
         */
        public var groupId:String;
        
        /**
         * There are times where we have hidden segments but do not want to show the divisions in them.
         * I.e. just have a single whole bar representing all the different segments that are hidden.
         * 
         * True if hidden segments should appear as their own division, false if all hidden should be
         * grouped together as one.
         */
        public var displayHiddenSegments:Boolean = true;
        
        public function BarWhole(displayHiddenSegments:Boolean, id:String=null)
        {
            this.barSegments = new Vector.<BarSegment>();
            this.barLabels = new Vector.<BarLabel>();
            this.displayHiddenSegments = displayHiddenSegments;
            
            this.id = (id == null) ? Identifiable.getId(1).toString() : id;
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
        public function getValue(startSegmentIndex:int=0, endSegmentIndex:int=-1):Number
        {
            if (startSegmentIndex < 0) 
            {
                startSegmentIndex = 0;    
            }
            
            if (endSegmentIndex < 0)
            {
                endSegmentIndex = barSegments.length - 1;
            }
            
            var i:int;
            var barSegment:BarSegment;
            var totalValue:Number = 0;
            for (i = startSegmentIndex; i <= endSegmentIndex; i++)
            {
                barSegment = barSegments[i];
                totalValue += barSegment.getValue();
            }
            
            return totalValue;
        }
        
        public function clone():BarWhole
        {
            var barWholeClone:BarWhole = new BarWhole(this.displayHiddenSegments, this.id);
            var i:int;
            var numSegments:int = this.barSegments.length;
            var barSegment:BarSegment;
            for (i = 0; i < numSegments; i++)
            {
                barSegment = this.barSegments[i];
                barWholeClone.barSegments.push(barSegment.clone());
            }
            
            var numLabels:int = this.barLabels.length;
            var barLabel:BarLabel;
            for (i = 0; i < numLabels; i++)
            {
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
        public function serialize():Object
        {
            var serializedSegments:Array = [];
            var i:int;
            var numSegments:int = this.barSegments.length;
            for (i = 0; i < numSegments; i++)
            {
                serializedSegments.push(this.barSegments[i].serialize());
            }
            
            var serializedLabels:Array = [];
            var numLabels:int = this.barLabels.length;
            for (i = 0; i < numLabels; i++)
            {
                serializedLabels.push(this.barLabels[i].serialize());
            }
            
            var serializedObject:Object = {
                id:this.id,
                s:serializedSegments,
                l:serializedLabels
            };
            
            if (this.barComparison != null)
            {
                serializedObject.c = this.barComparison.serialize();
            }
            
            return serializedObject;
        }
        
        public function deserialize(data:Object):void
        {
            var segmentData:Array = data.s;
            var i:int;
            var numSegments:int = segmentData.length;
            for (i = 0; i < numSegments; i++)
            {
                var barSegment:BarSegment = new BarSegment(0, 0, 0xFFFFFF, null);
                barSegment.deserialize(segmentData[i]);
                this.barSegments.push(barSegment);
            }
            
            var labelData:Array = data.l;
            var numLabels:int = labelData.length;
            for (i = 0; i < numLabels; i++)
            {
                var barLabel:BarLabel = new BarLabel("", 0, 0, true, false, BarLabel.BRACKET_NONE, null);
                barLabel.deserialize(labelData[i]);
                this.barLabels.push(barLabel);
            }
            
            if (data.hasOwnProperty("c"))
            {
                var barComparison:BarComparison = new BarComparison("", "", 0);
                barComparison.deserialize(data.c);
                this.barComparison = barComparison;
            }
            
            this.id = data.id;
        }
    }
}