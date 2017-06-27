package wordproblem.engine.barmodel.model
{
    /**
     * Bar model data that has been broken down into data pieces used for comparison.
     * 
     * It exposes the number of times a segment that is proportional to the smallest segment
     * appears across the entire model and the amount of bar it covers.
     */
    public class DecomposedBarModelData
    {
        /**
         * Since we are dealing with floating point values, we may need some lee-way to account for
         * rounding oddities when comparing values.
         */
        private static const ERROR:Number = 0.00001;
        
        /**
         * Each element is a unique normalized bar segment that appeared in the given
         * bar model data.
         */
        public var normalizedBarSegmentValuesList:Vector.<Number>;
        
        /**
         * Each element is the number of times that a normalized bar segment value at
         * the same index as normalizedBarSegmentValuesList occured in the given bar model data
         */
        public var normalizedBarSegmentValueTally:Vector.<int>;
        
        /**
         * Map from string value of a label or comparison to an 'amount' of bar that each
         * structure spans. The 'amount' is normalized so it is actually a proportion of the
         * amount of the smallest segment
         */
        public var labelValueToNormalizedSegmentValue:Object;
        
        /**
         * When decomposing a model, it is possible that a label is used multiple times and maps to different
         * value. This automatically makes this model invalid so it is no longer useful.
         * 
         * Each element indicates a label has a contradiction in the amount a label defines, thus comparisons using it are not valid.
         * An empty list indicates no label conflicts exist
         */
        public var detectedLabelValueConflict:Vector.<String>;
        
        /**
         * Map from the value of a label to the type (h, v, n, or c)
         * Horizontal, Vertical, No Bracket, or Comparison
         */
        public var labelValueToType:Object;
        
        /**
         * Number of different bar wholes
         */
        public var numBarWholes:int;
        
        /**
         * Map from value of the label to the ratio of all total bar segments added together.
         * It is used to perform comparison where the tally of segments is not considered and only
         * propertions are checked.
         */
        public var labelToRatioOfTotalBoxes:Object;
        
        /**
         * Mapping
         * Key: term value of the label
         * Value: Another object whose keys are other term values of other labels and values are the proportions derived from
         * this term segment value / other term segment value
         */
        public var labelProportions:Object;
        
        public function DecomposedBarModelData(barModelData:BarModelData)
        {
            normalizedBarSegmentValuesList = new Vector.<Number>();
            normalizedBarSegmentValueTally = new Vector.<int>();
            labelValueToNormalizedSegmentValue = {};
            this.detectedLabelValueConflict = new Vector.<String>();
            this.labelValueToType = {};
            this.numBarWholes = 0;
            this.labelToRatioOfTotalBoxes = {};
            this.labelProportions = {};
            this.decomposeBarModelData(barModelData);
        }
        
        public function isEquivalent(otherDecomposedBarModelData:DecomposedBarModelData):Boolean
        {
            // Make sure both data objects have all the same labels
            // Check everything in the other is contained in this
            var labelsMatch:Boolean = true;
            for (var labelValue:String in otherDecomposedBarModelData.labelValueToNormalizedSegmentValue)
            {
                if (!this.labelValueToNormalizedSegmentValue.hasOwnProperty(labelValue))
                {
                    labelsMatch = false;
                    break;
                }
            }
            
            // Check everything in this is contained in the other
            for (labelValue in this.labelValueToNormalizedSegmentValue)
            {
                if (!otherDecomposedBarModelData.labelValueToNormalizedSegmentValue.hasOwnProperty(labelValue))
                {
                    labelsMatch = false;
                    break;
                }
            }
            
            if (labelsMatch)
            {
                
                for (labelValue in otherDecomposedBarModelData.labelToRatioOfTotalBoxes)
                {
                    var ratioInOther:Number = otherDecomposedBarModelData.labelToRatioOfTotalBoxes[labelValue];
                    var ratioInThis:Number = this.labelToRatioOfTotalBoxes[labelValue];
                    if (Math.abs(ratioInOther - ratioInThis) > ERROR)
                    {
                        labelsMatch = false;
                        break;
                    }
                }
                
                /*
                // Checking that just the labels have values that are proportional to one another.
                for (labelValue in otherDecomposedBarModelData.labelProportions)
                {
                    var thisProportions:Object = this.labelProportions[labelValue];
                    var otherProportions:Object = otherDecomposedBarModelData.labelProportions[labelValue];
                    for (var otherLabelValue:String in otherProportions)
                    {
                        if (Math.abs(thisProportions[otherLabelValue] - otherProportions[otherLabelValue]) > ERROR)
                        {
                            labelsMatch = false;
                            break;
                        }
                    }
                }
                */
            }
            return labelsMatch;
        }
        
        /**
         * Note: The numbers contributing to the score are really arbitrary right now.
         * 
         * return
         *      A non-negative value representing how similar this model is with another.
         *      A value of zero means the two model are exactly the same. The bigger this value is,
         *      the more different the two models are
         */
        public function getEquivalencyScore(otherModel:DecomposedBarModelData):uint
        {
            var equivalencyScore:Number = 0;
            var i:int;
            
            // Need to make a copy of the tallies in the other model, since
            // we will be modifying it need to keep track of of what things got consumed
            var otherSegmentValues:Vector.<Number> = otherModel.normalizedBarSegmentValuesList.concat();
            var otherSegmentTallies:Vector.<int> = otherModel.normalizedBarSegmentValueTally.concat();
            
            // For every bar segment in this:
            // find the closest equivalent value and continuously 'consume' tallies
            // if the values are not the same, the difference between the values contributes to score
            // if this model or the other does not have enough tallies, contribute a fixed value to the score
            // (the value of the missing segment is not important and it doesn't make sense just because a bar is bigger
            // that it makes a model more different than the other)
            var numSegments:int = this.normalizedBarSegmentValuesList.length;
            for (i = 0; i < numSegments; i++)
            {
                // Get each value and the tallies of that value in this segment
                var normalizedValue:Number = this.normalizedBarSegmentValuesList[i];
                var numTallies:int = this.normalizedBarSegmentValueTally[i];
                
                while (numTallies > 0)
                {
                    // Find the closest matching value
                    var j:int = 0;
                    var numOtherUniqueSegmentValues:int = otherSegmentValues.length;
                    var indexOfClosestValue:int = -1;
                    var smallestValueDelta:Number = 0;
                    for (j = 0; j < numOtherUniqueSegmentValues; j++)
                    {
                        if (otherSegmentTallies[j] > 0)
                        {
                            var otherSegmentValue:Number = otherSegmentValues[j];
                            var currentValueDelta:Number = Math.abs(otherSegmentValue - normalizedValue);
                            if (indexOfClosestValue == -1 || smallestValueDelta > currentValueDelta)
                            {
                                indexOfClosestValue = j;
                                smallestValueDelta = currentValueDelta;
                            }
                        }
                    }
                    
                    if (indexOfClosestValue != -1)
                    {
                        // If values are the same don't do anything with the score
                        // Otherwise the values do not exactly match, the difference should be added to the score
                        var talliesToConsume:int = Math.min(otherSegmentTallies[indexOfClosestValue], numTallies);
                        if (smallestValueDelta > DecomposedBarModelData.ERROR)
                        {
                            equivalencyScore += (talliesToConsume * smallestValueDelta)
                        }
                        
                        // Consume as much of the tallies as possible
                        var remainingTallies:int = (otherSegmentTallies[indexOfClosestValue] - talliesToConsume);
                        if (remainingTallies > 0)
                        {
                            otherSegmentTallies[indexOfClosestValue] = remainingTallies;
                        }
                        else
                        {
                            otherSegmentValues.splice(indexOfClosestValue, 1);
                            otherSegmentTallies.splice(indexOfClosestValue, 1);
                        }
                        
                        numTallies -= talliesToConsume;
                    }
                    else
                    {
                        // Only go into here if all the tallies in the other model were consumed
                        // Any found tallies are extra
                        equivalencyScore += numTallies;
                        numTallies = 0;
                    }
                }
            }
            
            // Check if there are any remaining segments in the other
            // These contribute to the score as a difference
            numOtherUniqueSegmentValues = otherSegmentTallies.length;
            for (i = 0; i < numOtherUniqueSegmentValues; i++)
            {
                equivalencyScore += otherSegmentTallies[i]
            }
            
            // For every label value in this:
            // if value is in the other, the difference between the values is added to the score
            // if a value is missing, add a fixed value to the score
            var labelValueToSegmentInOther:Object = {};
            for (var labelValue:String in otherModel.labelValueToNormalizedSegmentValue)
            {
                labelValueToSegmentInOther[labelValue] = otherModel.labelValueToNormalizedSegmentValue[labelValue];
            }
            
            for (labelValue in this.labelValueToNormalizedSegmentValue)
            {
                if (labelValueToSegmentInOther.hasOwnProperty(labelValue))
                {
                    var thisLabelSegmentValue:Number = this.labelValueToNormalizedSegmentValue[labelValue];
                    var otherLabelSegmentValue:Number = labelValueToSegmentInOther[labelValue];
                    currentValueDelta = Math.abs(thisLabelSegmentValue - otherLabelSegmentValue);
                    if (currentValueDelta > DecomposedBarModelData.ERROR)
                    {
                        equivalencyScore += currentValueDelta;   
                    }
                    
                    delete labelValueToSegmentInOther[labelValue];
                }
                else
                {
                    // Missing label in the other
                    equivalencyScore += 2;
                }
            }
            
            // Check remaining labels left in the other, these are missing values that should further contribute
            // to the difference metric
            for (labelValue in labelValueToSegmentInOther)
            {
                equivalencyScore += 2;
            }
            
            // Difference in number of whole bars
            var barWholeDelta:int = Math.abs(this.numBarWholes - otherModel.numBarWholes);
            equivalencyScore += barWholeDelta * 5;
            
            // Check for differences in the label types for MATCHING values
            for (labelValue in this.labelValueToType)
            {
                if (otherModel.labelValueToType.hasOwnProperty(labelValue) && 
                    otherModel.labelValueToType[labelValue] != this.labelValueToType[labelValue])
                {
                    equivalencyScore += 5;
                }
            }
            
            // Have a map from label value to the label type
            // Differentiation between horizontal, vertical, and comparison labels
            // (General equivalency check should not care about this since this is a structural property)
            return Math.ceil(equivalencyScore);
        }
        
        private function decomposeBarModelData(barModelData:BarModelData):void
        {
            this.numBarWholes = barModelData.barWholes.length;
            
            // Loop through all the segments and find the one with the smallest value.
            // this will act as a unit reference
            var segmentWithMinValue:BarSegment = barModelData.getMinimumValueSegment();
            
            // A bar model should be immediately flagged as invalid if a label points to 
            // two different values.
            
            // Once we figure out the min value we can figure out how all the parts of the model
            // fit relative to this value
            var barWholes:Vector.<BarWhole> = barModelData.barWholes;
            var i:int;
            for (i = 0; i < barWholes.length; i++)
            {
                var barWhole:BarWhole = barWholes[i];
                var barSegments:Vector.<BarSegment> = barWhole.barSegments;
                var j:int;
                for (j = 0; j < barSegments.length; j++)
                {
                    var barSegment:BarSegment = barSegments[j];
                    var normalizedValue:Number = (barSegment.numeratorValue * segmentWithMinValue.denominatorValue) / 
                        (barSegment.denominatorValue * segmentWithMinValue.numeratorValue);
                    
                    // Check if the normalized value is in the list
                    var k:int;
                    var numNormalizedValues:int = this.normalizedBarSegmentValuesList.length;
                    var foundExistingValue:Boolean = false;
                    for (k = 0; k < numNormalizedValues; k++)
                    {
                        // Found existing value, increment the tally
                        if (Math.abs(normalizedValue - this.normalizedBarSegmentValuesList[k]) < DecomposedBarModelData.ERROR)
                        {
                            foundExistingValue = true;
                            this.normalizedBarSegmentValueTally[k] = this.normalizedBarSegmentValueTally[k] + 1;
                        }
                    }
                    
                    // Add new value with starting tally of one if it wasn't found
                    if (!foundExistingValue)
                    {
                        this.normalizedBarSegmentValuesList.push(normalizedValue);
                        this.normalizedBarSegmentValueTally.push(1);
                    }
                }
                
                // Figure out how of the normalized segment does each label cover.
                var barLabels:Vector.<BarLabel> = barWhole.barLabels;
                for (j = 0; j < barLabels.length; j++)
                {
                    var barLabel:BarLabel = barLabels[j];
                    var labelSegmentValue:Number = barWhole.getValue(barLabel.startSegmentIndex, barLabel.endSegmentIndex);
                    
                    // Normalize the value
                    var normalizedLabelValue:Number = (labelSegmentValue * segmentWithMinValue.denominatorValue) / segmentWithMinValue.numeratorValue;
                    checkForLabelConflict(barLabel.value, normalizedLabelValue);
                    labelValueToNormalizedSegmentValue[barLabel.value] = normalizedLabelValue;
                    
                    if (barLabel.bracketStyle == BarLabel.BRACKET_NONE)
                    {
                        this.labelValueToType[barLabel.value] = "n";
                    }
                    else
                    {
                        this.labelValueToType[barLabel.value] = "h";
                    }
                }
                
                if (barWhole.barComparison != null)
                {
                    var barComparison:BarComparison = barWhole.barComparison;
                    var otherBarWhole:BarWhole = barModelData.getBarWholeById(barComparison.barWholeIdComparedTo);
                    if (otherBarWhole != null)
                    {
                        var comparisonSegmentValue:Number = otherBarWhole.getValue(0, barComparison.segmentIndexComparedTo) - barWhole.getValue();
                        
                        // Normalize the value
                        normalizedLabelValue = (comparisonSegmentValue * segmentWithMinValue.denominatorValue) / segmentWithMinValue.numeratorValue;
                        checkForLabelConflict(barComparison.value, normalizedLabelValue);
                        labelValueToNormalizedSegmentValue[barComparison.value] = normalizedLabelValue;
                        
                        this.labelValueToType[barComparison.value] = "c";
                    }
                }
            }
            
            // Check vertical labels in the reference
            // The total value for each of those labels is the sum of the values of the
            // entire bars contained within the bounds of that label bracket.
            var verticalBarLabels:Vector.<BarLabel> = barModelData.verticalBarLabels;
            for (i = 0; i < verticalBarLabels.length; i++)
            {
                var verticalLabel:BarLabel = verticalBarLabels[i];
                var startIndex:int = verticalLabel.startSegmentIndex;
                var endIndex:int = verticalLabel.endSegmentIndex;
                var totalValue:Number = 0;
                for (j = startIndex; j <= endIndex; j++)
                {
                    barWhole = barWholes[j];
                    totalValue += (barWhole.getValue() * segmentWithMinValue.denominatorValue) / segmentWithMinValue.numeratorValue;
                }
                
                checkForLabelConflict(verticalLabel.value, totalValue);
                labelValueToNormalizedSegmentValue[verticalLabel.value] = totalValue;
                
                this.labelValueToType[verticalLabel.value] = "v";
            }
            
            // HACK:
            // Used for new comparison, may want to delete all preceding code in the future
            decomposeBarModelDataIntoRatiosOfTotal(barModelData);
        }
        
        private function checkForLabelConflict(labelName:String, newNormalizedValue:Number):void
        {
            if (labelValueToNormalizedSegmentValue.hasOwnProperty(labelName))
            {
                var previousLabelValue:Number = labelValueToNormalizedSegmentValue[labelName];
                if (Math.abs(previousLabelValue - newNormalizedValue) > ERROR)
                {
                    this.detectedLabelValueConflict.push(labelName);
                }
            }
        }
        
        /**
         * New way to compare bar models, every label is a ratio of the sum of all the boxes.
         * Comparison simply requires checking that the ratio for each label matches between each bar model.
         * This allows us to ignore the number of boxes and concentrate soley on proportions.
         */
        private function decomposeBarModelDataIntoRatiosOfTotal(barModelData:BarModelData):void
        {
            // Sum together the value of all boxes in the model.
            // This will provide us with a normalizing factor, so we can now treat the value of any individual
            // segment or label simply as a percentage of this whole.
            // 
            var totalBarValue:Number = 0.0;
            var i:int;
            var barWholes:Vector.<BarWhole> = barModelData.barWholes;
            for each (var barWhole:BarWhole in barWholes)
            {
                totalBarValue += barWhole.getValue();
            }
            
            // Go through every labeled part and figure out what it's normalized ratio should be
            var labelTermNameToSegmentAmount:Object = {};
            for each (barWhole in barWholes)
            {
                for each (var barLabel:BarLabel in barWhole.barLabels)
                {
                    var labelSegmentAmount:Number = barWhole.getValue(barLabel.startSegmentIndex, barLabel.endSegmentIndex);
                    labelToRatioOfTotalBoxes[barLabel.value] = labelSegmentAmount / totalBarValue;
                    
                    labelTermNameToSegmentAmount[barLabel.value] = labelSegmentAmount;
                }
                
                var barComparison:BarComparison = barWhole.barComparison;
                if (barComparison != null)
                {
                    // The comparison spans from the end of the bar containing the comparison, to a segment index in the other bar
                    var otherBarWhole:BarWhole = barModelData.getBarWholeById(barComparison.barWholeIdComparedTo);
                    labelSegmentAmount = (otherBarWhole.getValue(0, barComparison.segmentIndexComparedTo) - barWhole.getValue());
                    labelToRatioOfTotalBoxes[barComparison.value] = labelSegmentAmount / totalBarValue;
                    
                    labelTermNameToSegmentAmount[barComparison.value] = labelSegmentAmount;
                }
            }
            
            for each (barLabel in barModelData.verticalBarLabels)
            {
                var totalLabelValue:Number = 0;
                for (var barWholeIndex:int = barLabel.startSegmentIndex; barWholeIndex <= barLabel.endSegmentIndex; barWholeIndex++)
                {
                    totalLabelValue += barWholes[barWholeIndex].getValue();
                }
                labelToRatioOfTotalBoxes[barLabel.value] = totalLabelValue / totalBarValue;
                
                labelTermNameToSegmentAmount[barLabel.value] = totalLabelValue;
            }
            
            // Calculate the proportion of the bar segment value of a label compared to every other label.
            for (var labelTermName:String in labelTermNameToSegmentAmount)
            {
                var otherLabelProportions:Object = {};
                
                for (var otherLabelTermName:String in labelTermNameToSegmentAmount)
                {
                    if (labelTermName != otherLabelTermName)
                    {
                        var proportion:Number = labelTermNameToSegmentAmount[labelTermName] / labelTermNameToSegmentAmount[otherLabelTermName];
                        otherLabelProportions[otherLabelTermName] = proportion;
                    }
                }
                
                this.labelProportions[labelTermName] = otherLabelProportions;
            }
        }
    }
}