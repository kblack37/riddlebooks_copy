package wordproblem.engine.barmodel.model;

import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;

import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.expression.SymbolData;

/**
 * This class packs all the data that represents the bar model.
 * 
 * Functions that modify individual parts of the data are included so there is a centralized space
 * to send signals when data has been modified.
 */
class BarModelData
{
    /**
     * Reference to the data model of all of the bars to be drawn
     */
    public var barWholes : Array<BarWhole>;
    
    /**
     * List all vertical labels that span across multiple rows of bars
     */
    public var verticalBarLabels : Array<BarLabel>;
    
    /**
     * Mapping from an element's id to its original value that was overwritten on
     * a call to
     */
    private var m_elementIdToOldValueRestoreMap : Dynamic;
    
    public function new()
    {
        this.barWholes = new Array<BarWhole>();
        this.verticalBarLabels = new Array<BarLabel>();
    }
    
    public function clear() : Void
    {
		barWholes = new Array<BarWhole>();
		verticalBarLabels = new Array<BarLabel>();
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
    public function replaceAllAliasValues(aliasToTermMap : Dynamic) : Void
    {
        m_elementIdToOldValueRestoreMap = { };
        
        // Data values we care about are only contained in the labels and bar comparison
        var i : Int = 0;
        for (i in 0...barWholes.length){
            var barWhole : BarWhole = barWholes[i];
            var barLabels : Array<BarLabel> = barWhole.barLabels;
            var j : Int = 0;
            for (j in 0...barLabels.length){
                var barLabel : BarLabel = barLabels[j];
                var labelValue : String = barLabel.value;
                if (Reflect.hasField(aliasToTermMap, labelValue)) 
                {
					Reflect.setField(m_elementIdToOldValueRestoreMap, barLabel.id, labelValue);
                    barLabel.value = Reflect.field(aliasToTermMap, labelValue);
                }
            }
            
            var barComparison : BarComparison = barWhole.barComparison;
            if (barComparison != null) 
            {
                var comparisonValue : String = barComparison.value;
                if (Reflect.hasField(aliasToTermMap, comparisonValue)) 
                {
					Reflect.setField(m_elementIdToOldValueRestoreMap, barComparison.id, comparisonValue);
                    barComparison.value = Reflect.field(aliasToTermMap, comparisonValue);
                }
            }
        }
        
        for (i in 0...verticalBarLabels.length){
            var barLabel = verticalBarLabels[i];
            var labelValue = barLabel.value;
            if (Reflect.hasField(aliasToTermMap, labelValue)) 
            {
				Reflect.setField(m_elementIdToOldValueRestoreMap, barLabel.id, labelValue);
				barLabel.value = Reflect.field(aliasToTermMap, labelValue);
            }
        }
    }
    
    /**
     * This function undoes all the changes performed by the most recent call to replace
     */
    public function restoreAliasValues() : Void
    {
        if (m_elementIdToOldValueRestoreMap != null) 
        {
            var i : Int = 0;
            for (i in 0...barWholes.length){
                var barWhole : BarWhole = barWholes[i];
                var barLabels : Array<BarLabel> = barWhole.barLabels;
                var j : Int = 0;
                for (j in 0...barLabels.length){
                    var barLabel : BarLabel = barLabels[j];
                    if (Reflect.hasField(m_elementIdToOldValueRestoreMap, barLabel.id)) 
                    {
						barLabel.value = Reflect.field(m_elementIdToOldValueRestoreMap, barLabel.id);
                    }
                }
                
                var barComparison : BarComparison = barWhole.barComparison;
                if (barComparison != null) 
                {
                    var comparisonValue : String = barComparison.value;
                    if (Reflect.hasField(m_elementIdToOldValueRestoreMap, barComparison.id)) 
                    {
						barComparison.value = Reflect.field(m_elementIdToOldValueRestoreMap, barComparison.id);
                    }
                }
            }
            
            for (i in 0...verticalBarLabels.length){
                var barLabel = verticalBarLabels[i];
                if (Reflect.hasField(m_elementIdToOldValueRestoreMap, barLabel.id)) 
                {
					barLabel.value = Reflect.field(m_elementIdToOldValueRestoreMap, barLabel.id);
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
    public function getBarSegmentById(barSegmentId : String, outIndices : Array<Int> = null) : BarSegment
    {
        var matchingBarSegment : BarSegment = null;
        var numBarWholes : Int = barWholes.length;
        var barWhole : BarWhole = null;
        var i : Int = 0;
        for (i in 0...numBarWholes){
            barWhole = barWholes[i];
            var j : Int = 0;
            var numBarSegments : Int = barWhole.barSegments.length;
            var barSegment : BarSegment = null;
            for (j in 0...numBarSegments){
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
                    outIndices.push(i);
                    outIndices.push(j);
                    
                }
                break;
            }
        }
        
        return matchingBarSegment;
    }
    
    public function getHorizontalBarLabelsByValue(value : String, outBarLabels : Array<BarLabel> = null) : Array<BarLabel>
    {
        if (outBarLabels == null) 
        {
            outBarLabels = new Array<BarLabel>();
        }
        
        for (barWhole in barWholes)
        {
            for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EField(EIdent(barWhole),barLabels) type: null */ in barWhole.barLabels)
            {
                if (barLabel.value == value) 
                {
                    outBarLabels.push(barLabel);
                }
            }
        }
        
        return outBarLabels;
    }
    
    public function getVerticalBarLabelsByValue(value : String, outBarLabels : Array<BarLabel> = null) : Array<BarLabel>
    {
        if (outBarLabels == null) 
        {
            outBarLabels = new Array<BarLabel>();
        }
        
        for (barLabel in verticalBarLabels)
        {
            if (barLabel.value == value) 
            {
                outBarLabels.push(barLabel);
            }
        }
        
        return outBarLabels;
    }
    
    public function getBarLabelById(barLabelId : String) : BarLabel
    {
        var matchingBarLabel : BarLabel = null;
        var numBarWholes : Int = barWholes.length;
        var barWhole : BarWhole = null;
        var i : Int = 0;
        for (i in 0...numBarWholes){
            barWhole = barWholes[i];
            var j : Int = 0;
            var numBarLabels : Int = barWhole.barLabels.length;
            var barLabel : BarLabel = null;
            for (j in 0...numBarLabels){
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
    
    public function getBarWholeById(barWholeId : String) : BarWhole
    {
        var matchingBarWhole : BarWhole = null;
        var numBarWholes : Int = barWholes.length;
        var barWhole : BarWhole = null;
        var i : Int = 0;
        for (i in 0...numBarWholes){
            barWhole = barWholes[i];
            if (barWhole.id == barWholeId) 
            {
                matchingBarWhole = barWhole;
                break;
            }
        }
        
        return matchingBarWhole;
    }
    
    public function getMaxBarUnitValue() : Float
    {
        var numBarWholes : Int = this.barWholes.length;
        var i : Int = 0;
        var maxBarUnitValue : Float = 0;
        for (i in 0...numBarWholes){
            var barWhole : BarWhole = this.barWholes[i];
            var barValue : Float = barWhole.getValue();
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
    public function replaceLabelValuesWithVisibleNames(expressionSymbolMap : ExpressionSymbolMap) : Void
    {
        var i : Int = 0;
        var barWhole : BarWhole = null;
        var numBarWholes : Int = barWholes.length;
		function replaceNameForLabel(barLabel : BarLabel) : Void
        {
            var symbolDataForValue : SymbolData = expressionSymbolMap.getSymbolDataFromValue(barLabel.value);
            if (symbolDataForValue.abbreviatedName != null || symbolDataForValue.abbreviatedName != "") 
            {
                barLabel.value = symbolDataForValue.abbreviatedName;
            }
        };
		
        for (i in 0...numBarWholes){
            barWhole = barWholes[i];
            var numLabels : Int = barWhole.barLabels.length;
            var j : Int = 0;
            for (j in 0...numLabels){
                replaceNameForLabel(barWhole.barLabels[j]);
            }
        }
        
        var numVerticalBarLabels : Int = verticalBarLabels.length;
        for (i in 0...numVerticalBarLabels){
            replaceNameForLabel(verticalBarLabels[i]);
        }
    }
    
    /**
     * The primary usage of cloning the data is for something like keeping an undo stack
     * and for the use of a preview.
     */
    public function clone() : BarModelData
    {
        var barModelDataClone : BarModelData = new BarModelData();
        
        // Copy the whole bars
        var i : Int = 0;
        var barWhole : BarWhole = null;
        var numBarWholes : Int = barWholes.length;
        for (i in 0...numBarWholes){
            barWhole = barWholes[i];
            barModelDataClone.barWholes.push(barWhole.clone());
        }  // Copy the vertical labels  
        
        
        
        var barLabel : BarLabel = null;
        var numVerticalBarLabels : Int = verticalBarLabels.length;
        for (i in 0...numVerticalBarLabels){
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
    public function serialize() : Dynamic
    {
        var i : Int = 0;
        var serializedBarWholes : Array<Dynamic> = [];
        var numBarWholes : Int = this.barWholes.length;
        for (i in 0...numBarWholes){
            serializedBarWholes.push(this.barWholes[i].serialize());
        }
        
        var serializedBarWholeLabels : Array<Dynamic> = [];
        var numBarWholeLabels : Int = this.verticalBarLabels.length;
        for (i in 0...numBarWholeLabels){
            serializedBarWholeLabels.push(this.verticalBarLabels[i].serialize());
        }
        
        var serializedObject : Dynamic = {
            bwl : serializedBarWholes,
            vll : serializedBarWholeLabels,
        };
        
        return serializedObject;
    }
    
    public function deserialize(data : Dynamic) : Void
    {
        if (Reflect.hasField(data, "bwl")) 
        {
            var barWholesData : Array<Dynamic> = data.bwl;
            var i : Int = 0;
            var numBarWholes : Int = barWholesData.length;
            for (i in 0...numBarWholes){
                var barWhole : BarWhole = new BarWhole(false);
                barWhole.deserialize(barWholesData[i]);
                this.barWholes.push(barWhole);
            }
        }
        
        if (Reflect.hasField(data, "vll")) 
        {
            var verticalLabelsData : Array<Dynamic> = data.vll;
            var numVerticalLabels : Int = verticalLabelsData.length;
            for (i in 0...numVerticalLabels){
                var barLabel : BarLabel = new BarLabel("", 0, 0, false, true, BarLabel.BRACKET_STRAIGHT, null);
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
    public function getMinimumValueSegment() : BarSegment
    {
        var barSegmentWithMinValue : BarSegment = null;
        var minValue : Float = Math.pow(2, 30);
        for (i in 0...this.barWholes.length){
            var barWhole : BarWhole = this.barWholes[i];
            var barSegments : Array<BarSegment> = barWhole.barSegments;
            for (j in 0...barSegments.length){
                var barSegment : BarSegment = barSegments[j];
                var currentSegmentValue : Float = barSegment.getValue();
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
