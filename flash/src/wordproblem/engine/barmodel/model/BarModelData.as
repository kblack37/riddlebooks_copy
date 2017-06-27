package wordproblem.engine.barmodel.model
{
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.expression.SymbolData;

    /**
     * This class packs all the data that represents the bar model.
     * 
     * Functions that modify individual parts of the data are included so there is a centralized space
     * to send signals when data has been modified.
     */
    public class BarModelData
    {
        /**
         * Reference to the data model of all of the bars to be drawn
         */
        public var barWholes:Vector.<BarWhole>;
        
        /**
         * List all vertical labels that span across multiple rows of bars
         */
        public var verticalBarLabels:Vector.<BarLabel>;
        
        /**
         * Mapping from an element's id to its original value that was overwritten on
         * a call to
         */
        private var m_elementIdToOldValueRestoreMap:Object;
        
        public function BarModelData()
        {
            this.barWholes = new Vector.<BarWhole>();
            this.verticalBarLabels = new Vector.<BarLabel>();
        }
        
        public function clear():void
        {
            this.barWholes.length = 0;
            this.verticalBarLabels.length = 0;
        }
        
        /**
         * Go through the bar model and identify and term values that are actually
         * aliases for another term. Replace the data value with the original term.
         * Used for instance where the player picks their own noun, visually each alias may look
         * different but when check we just care that they picked from a group of known nouns.
         * 
         * Note: this function saves extra state so it is possible to restore the values that were replaced later
         * 
         * @param aliasToTermMap
         *      Mapping from alias value to the original value it should be replaced with
         */
        public function replaceAllAliasValues(aliasToTermMap:Object):void
        {
            m_elementIdToOldValueRestoreMap = {};
            
            // Data values we care about are only contained in the labels and bar comparison
            var i:int;
            for (i = 0; i < barWholes.length; i++)
            {
                var barWhole:BarWhole = barWholes[i];
                var barLabels:Vector.<BarLabel> = barWhole.barLabels;
                var j:int;
                for (j = 0; j < barLabels.length; j++)
                {
                    var barLabel:BarLabel = barLabels[j];
                    var labelValue:String = barLabel.value;
                    if (aliasToTermMap.hasOwnProperty(labelValue))
                    {
                        m_elementIdToOldValueRestoreMap[barLabel.id] = labelValue;
                        barLabel.value = aliasToTermMap[labelValue];
                    }
                }
                
                var barComparison:BarComparison = barWhole.barComparison;
                if (barComparison != null)
                {
                    var comparisonValue:String = barComparison.value;
                    if (aliasToTermMap.hasOwnProperty(comparisonValue))
                    {
                        m_elementIdToOldValueRestoreMap[barComparison.id] = comparisonValue;
                        barComparison.value = aliasToTermMap[comparisonValue];
                    }
                }
            }
            
            for (i = 0; i < verticalBarLabels.length; i++)
            {
                barLabel = verticalBarLabels[i];
                labelValue = barLabel.value;
                if (aliasToTermMap.hasOwnProperty(labelValue))
                {
                    m_elementIdToOldValueRestoreMap[barLabel.id] = labelValue;
                    barLabel.value = aliasToTermMap[labelValue];
                }
            }
        }
        
        /**
         * This function undoes all the changes performed by the most recent call to replace
         */
        public function restoreAliasValues():void
        {
            if (m_elementIdToOldValueRestoreMap != null)
            {
                var i:int;
                for (i = 0; i < barWholes.length; i++)
                {
                    var barWhole:BarWhole = barWholes[i];
                    var barLabels:Vector.<BarLabel> = barWhole.barLabels;
                    var j:int;
                    for (j = 0; j < barLabels.length; j++)
                    {
                        var barLabel:BarLabel = barLabels[j];
                        if (m_elementIdToOldValueRestoreMap.hasOwnProperty(barLabel.id))
                        {
                            barLabel.value = m_elementIdToOldValueRestoreMap[barLabel.id];
                        }
                    }
                    
                    var barComparison:BarComparison = barWhole.barComparison;
                    if (barComparison != null)
                    {
                        var comparisonValue:String = barComparison.value;
                        if (m_elementIdToOldValueRestoreMap.hasOwnProperty(barComparison.id))
                        {
                            barComparison.value = m_elementIdToOldValueRestoreMap[barComparison.id];
                        }
                    }
                }
                
                for (i = 0; i < verticalBarLabels.length; i++)
                {
                    barLabel = verticalBarLabels[i];
                    if (m_elementIdToOldValueRestoreMap.hasOwnProperty(barLabel.id))
                    {
                        barLabel.value = m_elementIdToOldValueRestoreMap[barLabel.id];
                    }
                }
            }
        }
        
        /**
         *
         * @param outIndices
         *      If a vector is specified, if a segment is found then the index of the bar
         *      and the index of the segment in the bar are stored in that order
         */
        public function getBarSegmentById(barSegmentId:String, outIndices:Vector.<int>=null):BarSegment
        {
            var matchingBarSegment:BarSegment = null;
            var numBarWholes:int = barWholes.length;
            var barWhole:BarWhole;
            var i:int;
            for (i = 0; i < numBarWholes; i++)
            {
                barWhole = barWholes[i];
                var j:int;
                var numBarSegments:int = barWhole.barSegments.length;
                var barSegment:BarSegment;
                for (j = 0; j < numBarSegments; j++)
                {
                    barSegment = barWhole.barSegments[j];
                    if (barSegment.id == barSegmentId)
                    {
                        matchingBarSegment = barSegment;
                        break;
                    }
                }
                
                if (matchingBarSegment != null)
                {
                    if (outIndices != null)
                    {
                        outIndices.push(i, j);
                    }
                    break;
                }
            }
            
            return matchingBarSegment;
        }
        
        public function getHorizontalBarLabelsByValue(value:String, outBarLabels:Vector.<BarLabel>=null):Vector.<BarLabel>
        {
            if (outBarLabels == null)
            {
                outBarLabels = new Vector.<BarLabel>();
            }
            
            for each (var barWhole:BarWhole in barWholes)
            {
                for each (var barLabel:BarLabel in barWhole.barLabels)
                {
                    if (barLabel.value == value)
                    {
                        outBarLabels.push(barLabel);
                    }
                }
            }
            
            return outBarLabels;
        }
        
        public function getVerticalBarLabelsByValue(value:String, outBarLabels:Vector.<BarLabel>=null):Vector.<BarLabel>
        {
            if (outBarLabels == null)
            {
                outBarLabels = new Vector.<BarLabel>();
            }
            
            for each (var barLabel:BarLabel in verticalBarLabels)
            {
                if (barLabel.value == value)
                {
                    outBarLabels.push(barLabel);
                }
            }
            
            return outBarLabels;
        }
        
        public function getBarLabelById(barLabelId:String):BarLabel
        {
            var matchingBarLabel:BarLabel = null;
            var numBarWholes:int = barWholes.length;
            var barWhole:BarWhole;
            var i:int;
            for (i = 0; i < numBarWholes; i++)
            {
                barWhole = barWholes[i];
                var j:int
                var numBarLabels:int = barWhole.barLabels.length;
                var barLabel:BarLabel;
                for (j = 0; j < numBarLabels; j++)
                {
                    barLabel = barWhole.barLabels[j];
                    if (barLabel.id == barLabelId)
                    {
                        matchingBarLabel = barLabel;
                        break;
                    }
                }
                
                if (matchingBarLabel != null)
                {
                    break;
                }
            }
            
            return matchingBarLabel;
        }
        
        public function getBarWholeById(barWholeId:String):BarWhole
        {
            var matchingBarWhole:BarWhole = null;
            var numBarWholes:int = barWholes.length;
            var barWhole:BarWhole;
            var i:int;
            for (i = 0; i < numBarWholes; i++)
            {
                barWhole = barWholes[i];
                if (barWhole.id == barWholeId)
                {
                    matchingBarWhole = barWhole;
                    break;
                }
            }
            
            return matchingBarWhole;
        }
        
        public function getMaxBarUnitValue():Number
        {
            var numBarWholes:int = this.barWholes.length;
            var i:int;
            var maxBarUnitValue:Number = 0;
            for (i = 0; i < numBarWholes; i++)
            {
                var barWhole:BarWhole = this.barWholes[i];
                var barValue:Number = barWhole.getValue();
                if (barValue > maxBarUnitValue)
                {
                    maxBarUnitValue = barValue;
                }
            }
            
            return maxBarUnitValue;
        }
        
        /**
         * Used for the copilot:
         * When render snapshots of the bar model in the copilot, the user will want to see the labels
         * in the model with the same name as they see in the game. The backing expression values
         * normally used may not have the same name
         * 
         * WARNING: This modifies the data. Should only be used on cloned copies.
         */
        public function replaceLabelValuesWithVisibleNames(expressionSymbolMap:ExpressionSymbolMap):void
        {
            var i:int;
            var barWhole:BarWhole;
            var numBarWholes:int = barWholes.length;
            for (i = 0; i < numBarWholes; i++)
            {
                barWhole = barWholes[i];
                var numLabels:int = barWhole.barLabels.length;
                var j:int;
                for (j = 0; j < numLabels; j++)
                {
                    replaceNameForLabel(barWhole.barLabels[j]);
                    
                }
            }
            
            var numVerticalBarLabels:int = verticalBarLabels.length;
            for (i = 0; i < numVerticalBarLabels; i++)
            {
                replaceNameForLabel(verticalBarLabels[i]);
            }
            
            function replaceNameForLabel(barLabel:BarLabel):void
            {
                var symbolDataForValue:SymbolData = expressionSymbolMap.getSymbolDataFromValue(barLabel.value);
                if (symbolDataForValue.abbreviatedName != null || symbolDataForValue.abbreviatedName != "")
                {
                    barLabel.value = symbolDataForValue.abbreviatedName;
                }
            }
        }
        
        /**
         * The primary usage of cloning the data is for something like keeping an undo stack
         * and for the use of a preview.
         */
        public function clone():BarModelData
        {
            var barModelDataClone:BarModelData = new BarModelData();
            
            // Copy the whole bars
            var i:int;
            var barWhole:BarWhole;
            var numBarWholes:int = barWholes.length;
            for (i = 0; i < numBarWholes; i++)
            {
                barWhole = barWholes[i];
                barModelDataClone.barWholes.push(barWhole.clone());
            }
            
            // Copy the vertical labels
            var barLabel:BarLabel;
            var numVerticalBarLabels:int = verticalBarLabels.length;
            for (i = 0; i < numVerticalBarLabels; i++)
            {
                barLabel = verticalBarLabels[i];
                barModelDataClone.verticalBarLabels.push(barLabel.clone());
            }
            
            return barModelDataClone;
        }
        
        /**
         * For data logging purposes we want to serialize a bar model in a json like object
         * that can be easily be logged.
         * 
         * @return
         *      A compact data object representing this bar model (containing bar wholes and bar whole labels)
         */
        public function serialize():Object
        {
            var i:int;
            var serializedBarWholes:Array = [];
            var numBarWholes:int = this.barWholes.length;
            for (i = 0; i < numBarWholes; i++)
            {
                serializedBarWholes.push(this.barWholes[i].serialize());
            }
            
            var serializedBarWholeLabels:Array = [];
            var numBarWholeLabels:int = this.verticalBarLabels.length;
            for (i = 0; i < numBarWholeLabels; i++)
            {
                serializedBarWholeLabels.push(this.verticalBarLabels[i].serialize());
            }
            
            var serializedObject:Object = {
                bwl:serializedBarWholes,
                vll:serializedBarWholeLabels
            };
                
            return serializedObject;
        }
        
        public function deserialize(data:Object):void
        {
            if (data.hasOwnProperty("bwl"))
            {
                var barWholesData:Array = data.bwl;
                var i:int;
                var numBarWholes:int = barWholesData.length;
                for (i = 0; i < numBarWholes; i++)
                {
                    var barWhole:BarWhole = new BarWhole(false);
                    barWhole.deserialize(barWholesData[i]);
                    this.barWholes.push(barWhole);
                }
            }
            
            if (data.hasOwnProperty("vll"))
            {
                var verticalLabelsData:Array = data.vll;
                var numVerticalLabels:int = verticalLabelsData.length;
                for (i = 0; i < numVerticalLabels; i++)
                {
                    var barLabel:BarLabel = new BarLabel("", 0, 0, false, true, BarLabel.BRACKET_STRAIGHT, null);
                    barLabel.deserialize(verticalLabelsData[i]);
                    this.verticalBarLabels.push(barLabel);
                }
            }
        }
        
        /**
         * The main purpose of extracting the bar segment value is that you use this as a sort of normalizing
         * value.
         * 
         * When comparing the segments in a bar model, you just really care about the relative proportions,
         * like this segment over here is twice as big as this not. The fact that its pixel length is 200 and the other 100
         * is not useful. We want to strictly enfore
         */
        public function getMinimumValueSegment():BarSegment
        {
            var barSegmentWithMinValue:BarSegment = null;
            var minValue:Number = int.MAX_VALUE;
            for (var i:int = 0; i < this.barWholes.length; i++)
            {
                var barWhole:BarWhole = this.barWholes[i];
                var barSegments:Vector.<BarSegment> = barWhole.barSegments;
                for (var j:int = 0; j < barSegments.length; j++)
                {
                    var barSegment:BarSegment = barSegments[j];
                    var currentSegmentValue:Number = barSegment.getValue();
                    if (barSegmentWithMinValue == null || currentSegmentValue < minValue)
                    {
                        minValue = currentSegmentValue;
                        barSegmentWithMinValue = barSegment;
                    }
                }
            }
            
            return barSegmentWithMinValue;
        }
    }
}