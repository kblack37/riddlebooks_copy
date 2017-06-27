package wordproblem.engine.barmodel.model
{
    import dragonbox.common.system.Identifiable;

    /**
     * Defines the data associated with a single segment that is to be placed inside a row.
     * A bar segment's value is a really a ratio when compared to some unit value.
     * 
     * Note: The x and y positions are implicit in the index of segment within the whole bar.
     * We also assume segments lined up end to end in a single row.
     */
    public class BarSegment
    {
        /**
         * Unique id
         */
        public var id:String;
        
        /**
         * The color that this segment should be shaded with.
         */
        public var color:uint;
        
        /**
         * The numerator of this segment's value relative to some unit length.
         * 
         * Separated to maintain precision.
         */
        public var numeratorValue:Number;
        
        /**
         * The denominator of this segment's value relative to some unit length.
         * 
         * Separated to maintain precision.
         */
        public var denominatorValue:Number;
        
        /**
         * Indicator if this segment is currently a placeholder for another expected value.
         * (We want hidden segments to be drawn differently)
         * If null, then the segment is not hidden.
         */
        public var hiddenValue:String;
        
        public function BarSegment(numeratorValue:Number, 
                                   denominatorValue:Number, 
                                   color:uint, 
                                   hiddenValue:String, 
                                   id:String=null)
        {
            if (isNaN(numeratorValue) || isNaN(denominatorValue))
            {
                throw new Error("Failed segment");
            }
            this.numeratorValue = numeratorValue;
            this.denominatorValue = denominatorValue;
            this.color = color;
            this.hiddenValue = hiddenValue;
            
            this.id = (id == null) ? Identifiable.getId(1).toString() : id;
        }
        
        /**
         * Get back the value of the segment. The value is the ratio between the values intended 'length'
         * vs the length of some predefined unit value.
         * 
         * So a returned value of 1 would mean this segment is equivalent to the unit length.
         */
        public function getValue():Number
        {
            return numeratorValue / denominatorValue;
        }
        
        public function clone():BarSegment
        {
            var barSegmentClone:BarSegment = new BarSegment(
                this.numeratorValue, 
                this.denominatorValue, 
                this.color, 
                this.hiddenValue,
                this.id
            );
            return barSegmentClone;
        }
        
        /**
         * For data logging purposes we want to serialize a segment in a json like object
         * that can be easily be logged.
         * 
         * @return
         *      A compact data object representing this segment
         */
        public function serialize():Object
        {
            var serializedObject:Object = {
                id:this.id,
                n:this.numeratorValue,
                d:this.denominatorValue,
                color:'0x' + color.toString(16)
            };
            return serializedObject;
        }
        
        public function deserialize(data:Object):void
        {
            if (data.hasOwnProperty("id"))
            {
                this.id = data.id;
            }
            
            if (data.hasOwnProperty("n"))
            {
                this.numeratorValue = data.n;
            }
            
            if (data.hasOwnProperty("d"))
            {
                this.denominatorValue = data.d;
            }
        }
    }
}