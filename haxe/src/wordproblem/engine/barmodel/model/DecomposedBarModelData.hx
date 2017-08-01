package wordproblem.engine.barmodel.model;


/**
 * Bar model data that has been broken down into data pieces used for comparison.
 * 
 * It exposes the number of times a segment that is proportional to the smallest segment
 * appears across the entire model and the amount of bar it covers.
 */
class DecomposedBarModelData
{
    /**
     * Since we are dealing with floating point values, we may need some lee-way to account for
     * rounding oddities when comparing values.
     */
    private static inline var ERROR : Float = 0.00001;
    
    /**
     * Each element is a unique normalized bar segment that appeared in the given
     * bar model data.
     */
    public var normalizedBarSegmentValuesList : Array<Float>;
    
    /**
     * Each element is the number of times that a normalized bar segment value at
     * the same index as normalizedBarSegmentValuesList occured in the given bar model data
     */
    public var normalizedBarSegmentValueTally : Array<Int>;
    
    /**
     * Map from string value of a label or comparison to an 'amount' of bar that each
     * structure spans. The 'amount' is normalized so it is actually a proportion of the
     * amount of the smallest segment
     */
    public var labelValueToNormalizedSegmentValue : Dynamic;
    
    /**
     * When decomposing a model, it is possible that a label is used multiple times and maps to different
     * value. This automatically makes this model invalid so it is no longer useful.
     * 
     * Each element indicates a label has a contradiction in the amount a label defines, thus comparisons using it are not valid.
     * An empty list indicates no label conflicts exist
     */
    public var detectedLabelValueConflict : Array<String>;
    
    /**
     * Map from the value of a label to the type (h, v, n, or c)
     * Horizontal, Vertical, No Bracket, or Comparison
     */
    public var labelValueToType : Dynamic;
    
    /**
     * Number of different bar wholes
     */
    public var numBarWholes : Int;
    
    /**
     * Map from value of the label to the ratio of all total bar segments added together.
     * It is used to perform comparison where the tally of segments is not considered and only
     * propertions are checked.
     */
    public var labelToRatioOfTotalBoxes : Dynamic;
    
    /**
     * Mapping
     * Key: term value of the label
     * Value: Another object whose keys are other term values of other labels and values are the proportions derived from
     * this term segment value / other term segment value
     */
    public var labelProportions : Dynamic;
    
    public function new(barModelData : BarModelData)
    {
        normalizedBarSegmentValuesList = new Array<Float>();
        normalizedBarSegmentValueTally = new Array<Int>();
        labelValueToNormalizedSegmentValue = { };
        this.detectedLabelValueConflict = new Array<String>();
        this.labelValueToType = { };
        this.numBarWholes = 0;
        this.labelToRatioOfTotalBoxes = { };
        this.labelProportions = { };
        this.decomposeBarModelData(barModelData);
    }
    
    public function isEquivalent(otherDecomposedBarModelData : DecomposedBarModelData) : Bool
    {
        // Make sure both data objects have all the same labels
        // Check everything in the other is contained in this
        var labelsMatch : Bool = true;
        for (labelValue in Reflect.fields(otherDecomposedBarModelData.labelValueToNormalizedSegmentValue))
        {
            if (!this.labelValueToNormalizedSegmentValue.exists(labelValue)) 
            {
                labelsMatch = false;
                break;
            }
        }  // Check everything in this is contained in the other  
        
        
        
        for (labelValue in Reflect.fields(this.labelValueToNormalizedSegmentValue))
        {
            if (!otherDecomposedBarModelData.labelValueToNormalizedSegmentValue.exists(labelValue)) 
            {
                labelsMatch = false;
                break;
            }
        }
        
        if (labelsMatch) 
        {
            
            for (labelValue in Reflect.fields(otherDecomposedBarModelData.labelToRatioOfTotalBoxes))
            {
                var ratioInOther : Float = otherDecomposedBarModelData.labelToRatioOfTotalBoxes[Std.parseInt(labelValue)];
                var ratioInThis : Float = this.labelToRatioOfTotalBoxes[Std.parseInt(labelValue)];
                if (Math.abs(ratioInOther - ratioInThis) > ERROR) 
                {
                    labelsMatch = false;
                    break;
                }
            }  /*
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
    public function getEquivalencyScore(otherModel : DecomposedBarModelData) : Int
    {
        var equivalencyScore : Float = 0;
        var i : Int = 0;
        
        // Need to make a copy of the tallies in the other model, since
        // we will be modifying it need to keep track of of what things got consumed
        var otherSegmentValues : Array<Float> = otherModel.normalizedBarSegmentValuesList.concat(new Array<Float>());
        var otherSegmentTallies : Array<Int> = otherModel.normalizedBarSegmentValueTally.concat(new Array<Int>());
        
        // For every bar segment in this:
        // find the closest equivalent value and continuously 'consume' tallies
        // if the values are not the same, the difference between the values contributes to score
        // if this model or the other does not have enough tallies, contribute a fixed value to the score
        // (the value of the missing segment is not important and it doesn't make sense just because a bar is bigger
        // that it makes a model more different than the other)
        var numSegments : Int = this.normalizedBarSegmentValuesList.length;
        for (i in 0...numSegments){
            // Get each value and the tallies of that value in this segment
            var normalizedValue : Float = this.normalizedBarSegmentValuesList[i];
            var numTallies : Int = this.normalizedBarSegmentValueTally[i];
            
            while (numTallies > 0)
            {
                // Find the closest matching value
                var j : Int = 0;
                var numOtherUniqueSegmentValues : Int = otherSegmentValues.length;
                var indexOfClosestValue : Int = -1;
                var smallestValueDelta : Float = 0;
                for (j in 0...numOtherUniqueSegmentValues){
                    if (otherSegmentTallies[j] > 0) 
                    {
                        var otherSegmentValue : Float = otherSegmentValues[j];
                        var currentValueDelta : Float = Math.abs(otherSegmentValue - normalizedValue);
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
                    var talliesToConsume : Int = Std.int(Math.min(otherSegmentTallies[indexOfClosestValue], numTallies));
                    if (smallestValueDelta > DecomposedBarModelData.ERROR) 
                    {
                        equivalencyScore += (talliesToConsume * smallestValueDelta);
                    }  // Consume as much of the tallies as possible  
                    
                    
                    
                    var remainingTallies : Int = (otherSegmentTallies[indexOfClosestValue] - talliesToConsume);
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
        var numOtherUniqueSegmentValues = otherSegmentTallies.length;
        for (i in 0...numOtherUniqueSegmentValues){
            equivalencyScore += otherSegmentTallies[i];
        }
		
		// For every label value in this:  
		// if value is in the other, the difference between the values is added to the score
        // if a value is missing, add a fixed value to the score
        var labelValueToSegmentInOther : Dynamic = { };
        for (labelValue in Reflect.fields(otherModel.labelValueToNormalizedSegmentValue))
        {
            Reflect.setField(labelValueToSegmentInOther, labelValue, otherModel.labelValueToNormalizedSegmentValue[Std.parseInt(labelValue)]);
        }
        
        for (labelValue in Reflect.fields(this.labelValueToNormalizedSegmentValue))
        {
            if (labelValueToSegmentInOther.exists(labelValue)) 
            {
                var thisLabelSegmentValue : Float = this.labelValueToNormalizedSegmentValue[Std.parseInt(labelValue)];
                var otherLabelSegmentValue : Float = labelValueToSegmentInOther[Std.parseInt(labelValue)];
                var currentValueDelta = Math.abs(thisLabelSegmentValue - otherLabelSegmentValue);
                if (currentValueDelta > DecomposedBarModelData.ERROR) 
                {
                    equivalencyScore += currentValueDelta;
                }
                
                ;
            }
            else 
            {
                // Missing label in the other
                equivalencyScore += 2;
            }
        }  // to the difference metric    // Check remaining labels left in the other, these are missing values that should further contribute  
        
        
        
        
        
        for (labelValue in Reflect.fields(labelValueToSegmentInOther))
        {
            equivalencyScore += 2;
        }  // Difference in number of whole bars  
        
        
        
        var barWholeDelta : Int = Std.int(Math.abs(this.numBarWholes - otherModel.numBarWholes));
        equivalencyScore += barWholeDelta * 5;
        
        // Check for differences in the label types for MATCHING values
        for (labelValue in Reflect.fields(this.labelValueToType))
        {
            if (otherModel.labelValueToType.exists(labelValue) &&
                otherModel.labelValueToType[Std.parseInt(labelValue)] != this.labelValueToType[Std.parseInt(labelValue)]) 
            {
                equivalencyScore += 5;
            }
        } 
		
		// Have a map from label value to the label type  
		// Differentiation between horizontal, vertical, and comparison labels
        // (General equivalency check should not care about this since this is a structural property)
        return Math.ceil(equivalencyScore);
    }
    
    private function decomposeBarModelData(barModelData : BarModelData) : Void
    {
        this.numBarWholes = barModelData.barWholes.length;
        
        // Loop through all the segments and find the one with the smallest value.
        // this will act as a unit reference
        var segmentWithMinValue : BarSegment = barModelData.getMinimumValueSegment();
        
        // A bar model should be immediately flagged as invalid if a label points to
        // two different values.
        
        // Once we figure out the min value we can figure out how all the parts of the model
        // fit relative to this value
        var barWholes : Array<BarWhole> = barModelData.barWholes;
        var i : Int = 0;
        for (i in 0...barWholes.length){
            var barWhole : BarWhole = barWholes[i];
            var barSegments : Array<BarSegment> = barWhole.barSegments;
            var j : Int = 0;
            for (j in 0...barSegments.length){
                var barSegment : BarSegment = barSegments[j];
                var normalizedValue : Float = (barSegment.numeratorValue * segmentWithMinValue.denominatorValue) /
                (barSegment.denominatorValue * segmentWithMinValue.numeratorValue);
                
                // Check if the normalized value is in the list
                var k : Int = 0;
                var numNormalizedValues : Int = this.normalizedBarSegmentValuesList.length;
                var foundExistingValue : Bool = false;
                for (k in 0...numNormalizedValues){
                    // Found existing value, increment the tally
                    if (Math.abs(normalizedValue - this.normalizedBarSegmentValuesList[k]) < DecomposedBarModelData.ERROR) 
                    {
                        foundExistingValue = true;
                        this.normalizedBarSegmentValueTally[k] = this.normalizedBarSegmentValueTally[k] + 1;
                    }
                }  // Add new value with starting tally of one if it wasn't found  
                
                
                
                if (!foundExistingValue) 
                {
                    this.normalizedBarSegmentValuesList.push(normalizedValue);
                    this.normalizedBarSegmentValueTally.push(1);
                }
            }
			
			// Figure out how of the normalized segment does each label cover.  
            var barLabels : Array<BarLabel> = barWhole.barLabels;
            for (j in 0...barLabels.length){
                var barLabel : BarLabel = barLabels[j];
                var labelSegmentValue : Float = barWhole.getValue(barLabel.startSegmentIndex, barLabel.endSegmentIndex);
                
                // Normalize the value
                var normalizedLabelValue : Float = (labelSegmentValue * segmentWithMinValue.denominatorValue) / segmentWithMinValue.numeratorValue;
                checkForLabelConflict(barLabel.value, normalizedLabelValue);
                labelValueToNormalizedSegmentValue[Std.parseInt(barLabel.value)] = normalizedLabelValue;
                
                if (barLabel.bracketStyle == BarLabel.BRACKET_NONE) 
                {
                    this.labelValueToType[Std.parseInt(barLabel.value)] = "n";
                }
                else 
                {
                    this.labelValueToType[Std.parseInt(barLabel.value)] = "h";
                }
            }
            
            if (barWhole.barComparison != null) 
            {
                var barComparison : BarComparison = barWhole.barComparison;
                var otherBarWhole : BarWhole = barModelData.getBarWholeById(barComparison.barWholeIdComparedTo);
                if (otherBarWhole != null) 
                {
                    var comparisonSegmentValue : Float = otherBarWhole.getValue(0, barComparison.segmentIndexComparedTo) - barWhole.getValue();
                    
                    // Normalize the value
                    var normalizedLabelValue = (comparisonSegmentValue * segmentWithMinValue.denominatorValue) / segmentWithMinValue.numeratorValue;
                    checkForLabelConflict(barComparison.value, normalizedLabelValue);
                    labelValueToNormalizedSegmentValue[Std.parseInt(barComparison.value)] = normalizedLabelValue;
                    
                    this.labelValueToType[Std.parseInt(barComparison.value)] = "c";
                }
            }
        }
		
		// Check vertical labels in the reference  
       	// The total value for each of those labels is the sum of the values of the 
        // entire bars contained within the bounds of that label bracket.
        var verticalBarLabels : Array<BarLabel> = barModelData.verticalBarLabels;
        for (i in 0...verticalBarLabels.length){
            var verticalLabel : BarLabel = verticalBarLabels[i];
            var startIndex : Int = verticalLabel.startSegmentIndex;
            var endIndex : Int = verticalLabel.endSegmentIndex;
            var totalValue : Float = 0;
            for (j in startIndex...endIndex + 1){
                var barWhole = barWholes[j];
                totalValue += (barWhole.getValue() * segmentWithMinValue.denominatorValue) / segmentWithMinValue.numeratorValue;
            }
            
            checkForLabelConflict(verticalLabel.value, totalValue);
            labelValueToNormalizedSegmentValue[Std.parseInt(verticalLabel.value)] = totalValue;
            
            this.labelValueToType[Std.parseInt(verticalLabel.value)] = "v";
        }  // Used for new comparison, may want to delete all preceding code in the future    // HACK:  
        
        
        
        
        
        decomposeBarModelDataIntoRatiosOfTotal(barModelData);
    }
    
    private function checkForLabelConflict(labelName : String, newNormalizedValue : Float) : Void
    {
        if (labelValueToNormalizedSegmentValue.exists(labelName)) 
        {
            var previousLabelValue : Float = Reflect.field(labelValueToNormalizedSegmentValue, labelName);
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
    private function decomposeBarModelDataIntoRatiosOfTotal(barModelData : BarModelData) : Void
    {
        // Sum together the value of all boxes in the model.
        // This will provide us with a normalizing factor, so we can now treat the value of any individual
        // segment or label simply as a percentage of this whole.
        //
        var totalBarValue : Float = 0.0;
        var i : Int = 0;
        var barWholes : Array<BarWhole> = barModelData.barWholes;
        for (barWhole in barWholes)
        {
            totalBarValue += barWhole.getValue();
        }  // Go through every labeled part and figure out what it's normalized ratio should be  
        
        
        
        var labelTermNameToSegmentAmount : Dynamic = { };
        for (barWhole in barWholes)
        {
            for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EField(EIdent(barWhole),barLabels) type: null */ in barWhole.barLabels)
            {
                var labelSegmentAmount : Float = barWhole.getValue(barLabel.startSegmentIndex, barLabel.endSegmentIndex);
                labelToRatioOfTotalBoxes[Std.parseInt(barLabel.value)] = labelSegmentAmount / totalBarValue;
                
                labelTermNameToSegmentAmount[Std.parseInt(barLabel.value)] = labelSegmentAmount;
            }
            
            var barComparison : BarComparison = barWhole.barComparison;
            if (barComparison != null) 
            {
                // The comparison spans from the end of the bar containing the comparison, to a segment index in the other bar
                var otherBarWhole : BarWhole = barModelData.getBarWholeById(barComparison.barWholeIdComparedTo);
                var labelSegmentAmount = (otherBarWhole.getValue(0, barComparison.segmentIndexComparedTo) - barWhole.getValue());
                labelToRatioOfTotalBoxes[Std.parseInt(barComparison.value)] = labelSegmentAmount / totalBarValue;
                
                labelTermNameToSegmentAmount[Std.parseInt(barComparison.value)] = labelSegmentAmount;
            }
        }
        
        for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EField(EIdent(barModelData),verticalBarLabels) type: null */ in barModelData.verticalBarLabels)
        {
            var totalLabelValue : Float = 0;
            for (barWholeIndex in barLabel.startSegmentIndex...barLabel.endSegmentIndex + 1){
                totalLabelValue += barWholes[barWholeIndex].getValue();
            }
            labelToRatioOfTotalBoxes[Std.parseInt(barLabel.value)] = totalLabelValue / totalBarValue;
            
            labelTermNameToSegmentAmount[Std.parseInt(barLabel.value)] = totalLabelValue;
        }  // Calculate the proportion of the bar segment value of a label compared to every other label.  
        
        
        
        for (labelTermName in Reflect.fields(labelTermNameToSegmentAmount))
        {
            var otherLabelProportions : Dynamic = { };
            
            for (otherLabelTermName in Reflect.fields(labelTermNameToSegmentAmount))
            {
                if (labelTermName != otherLabelTermName) 
                {
                    var proportion : Float = Reflect.field(labelTermNameToSegmentAmount, labelTermName) / Reflect.field(labelTermNameToSegmentAmount, otherLabelTermName);
                    Reflect.setField(otherLabelProportions, otherLabelTermName, proportion);
                }
            }
            
            this.labelProportions[Std.parseInt(labelTermName)] = otherLabelProportions;
        }
    }
}
