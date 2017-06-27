package wordproblem.engine.barmodel
{
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarWhole;

    public class BarModelDataUtil
    {
        public function BarModelDataUtil()
        {
        }
        
        /**
         * Change all horizontal brackets in the given model to stretch out to fit all the segments within
         * the row it is in.
         */
        public static function stretchHorizontalBrackets(barModelData:BarModelData):void
        {
            var barWholes:Vector.<BarWhole> = barModelData.barWholes;
            var i:int;
            for (i = 0; i < barWholes.length; i++)
            {
                var barWhole:BarWhole = barWholes[i];
                var barLabels:Vector.<BarLabel> = barWhole.barLabels;
                var j:int;
                for (j = 0; j < barLabels.length; j++)
                {
                    var barLabel:BarLabel = barLabels[j];
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
        public static function stretchVerticalBrackets(barModelData:BarModelData):void
        {
            var numBarWholes:int = barModelData.barWholes.length;
            var verticalLabels:Vector.<BarLabel> = barModelData.verticalBarLabels;
            var i:int;
            for (i = 0; i < verticalLabels.length; i++)
            {
                var verticalLabel:BarLabel = verticalLabels[i];
                verticalLabel.startSegmentIndex = 0;
                verticalLabel.endSegmentIndex = numBarWholes - 1;
            }
        }
    }
}