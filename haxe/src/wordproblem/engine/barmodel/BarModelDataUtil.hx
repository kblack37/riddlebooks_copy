package wordproblem.engine.barmodel;


import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarWhole;

class BarModelDataUtil
{
    public function new()
    {
    }
    
    /**
     * Change all horizontal brackets in the given model to stretch out to fit all the segments within
     * the row it is in.
     */
    public static function stretchHorizontalBrackets(barModelData : BarModelData) : Void
    {
        var barWholes : Array<BarWhole> = barModelData.barWholes;
        var i : Int;
        for (i in 0...barWholes.length){
            var barWhole : BarWhole = barWholes[i];
            var barLabels : Array<BarLabel> = barWhole.barLabels;
            var j : Int;
            for (j in 0...barLabels.length){
                var barLabel : BarLabel = barLabels[j];
                if (barLabel.bracketStyle == BarLabel.BRACKET_STRAIGHT) 
                {
                    barLabel.startSegmentIndex = 0;
                    barLabel.endSegmentIndex = barWhole.barSegments.length - 1;
                }
            }
        }
    }
    
    /**
     * Change all vertical brackets in the given model to stretch out to fit all rows
     */
    public static function stretchVerticalBrackets(barModelData : BarModelData) : Void
    {
        var numBarWholes : Int = barModelData.barWholes.length;
        var verticalLabels : Array<BarLabel> = barModelData.verticalBarLabels;
        var i : Int;
        for (i in 0...verticalLabels.length){
            var verticalLabel : BarLabel = verticalLabels[i];
            verticalLabel.startSegmentIndex = 0;
            verticalLabel.endSegmentIndex = numBarWholes - 1;
        }
    }
}
