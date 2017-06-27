package wordproblem.scripts.level.util
{
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.scripts.barmodel.ValidateBarModelArea;

    /**
     * A bit of a hack class storing common functions used by several tutorial levels
     */
    public class LevelCommonUtil
    {
        public static function setReferenceBarModelForPickem(labelOnBarValue:String, 
                                                             bracketValue:String, 
                                                             aliasForLabelOnBar:Vector.<String>, 
                                                             validationScript:ValidateBarModelArea):void
        {
            // The correct model will allow for every choice to be right
            var referenceBarModels:Vector.<BarModelData> = new Vector.<BarModelData>();
            var correctModel:BarModelData = new BarModelData();
            var correctBarWhole:BarWhole = new BarWhole(true);
            correctBarWhole.barSegments.push(new BarSegment(1, 1, 0xFFFFFFFF, null));
            correctBarWhole.barLabels.push(new BarLabel(labelOnBarValue, 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            if (bracketValue != null)
            {
                correctBarWhole.barLabels.push(new BarLabel(bracketValue, 0, correctBarWhole.barSegments.length - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
            }
            correctModel.barWholes.push(correctBarWhole);
            referenceBarModels.push(correctModel);
            
            validationScript.setReferenceModels(referenceBarModels);
            
            if (aliasForLabelOnBar != null)
            {
                validationScript.setTermValueAliases(labelOnBarValue, aliasForLabelOnBar);
            }
        }
    }
}