package gameconfig.versions.brainpop
{
    import gameconfig.commonresource.AudioBundle;
    import gameconfig.commonresource.EmbeddedBarModelResources;
    import gameconfig.commonresource.EmbeddedBundle1X;
    import gameconfig.commonresource.EmbeddedEggStills;
    import gameconfig.commonresource.EmbeddedLevelSelectResources;
    import gameconfig.commonresource.EmbededOperatorAtlasBundle;
    import gameconfig.versions.brainpop.ConfigurationBundle;
    
    import levelscripts.barmodel.tutorials.LS_AddBarA;
    import levelscripts.barmodel.tutorials.LS_AddComparisonA;
    import levelscripts.barmodel.tutorials.LS_AddLabelA;
    import levelscripts.barmodel.tutorials.LS_AddSegmentsA;
    import levelscripts.barmodel.tutorials.LS_EquationFromBarA;
    import levelscripts.barmodel.tutorials.LS_FractionEnterCardA;
    import levelscripts.barmodel.tutorials.LS_MultiplyBarA;
    import levelscripts.barmodel.tutorials.LS_SplitCopyA;
    import levelscripts.barmodel.tutorials.LS_TextDiscoverA;
    import levelscripts.barmodel.tutorials.LS_TwoStepA;
    import levels.brainpop.LS_BrainpopAddBothSides;
    import levels.brainpop.LS_BrainpopAddition;
    import levels.brainpop.LS_BrainpopIntro;
    import levels.tutorials.LS_divide_tutorial;
    import levels.tutorials.LS_multiply_tutorial;
    import levels.tutorials.LS_parenthesis_tutorial;
    import levels.tutorials.LS_subtract_tutorial;
    
    import wordproblem.AlgebraAdventureConfig;
    import wordproblem.WordProblemGameBrainpop;
    import wordproblem.resource.bundles.ResourceBundle;
    import wordproblem.scripts.level.GenericBarModelLevelScript;

    public class GameConfig extends AlgebraAdventureConfig
    {
        public function GameConfig()
        {
            super();
            
            // Need to reference all dynamic classes for the level scripts
            LS_BrainpopAddBothSides;
            LS_BrainpopAddition;
            LS_BrainpopIntro;
            
            LS_AddBarA;
            LS_AddComparisonA;
            LS_TextDiscoverA;
            LS_AddLabelA;
            LS_AddSegmentsA;
            LS_EquationFromBarA;
            LS_MultiplyBarA;
            LS_SplitCopyA;
            LS_TwoStepA;
            LS_FractionEnterCardA;
            
            LS_subtract_tutorial;
            LS_multiply_tutorial;
            LS_divide_tutorial;
            LS_parenthesis_tutorial;
            
            GenericBarModelLevelScript;
        }
        
        override protected function instantiateResourceBundles():void
        {
            super.instantiateResourceBundles();
            
            m_nameToBundleList["config"] = Vector.<ResourceBundle>([new ConfigurationBundle()]);            
            
            var resourceBundles:Vector.<ResourceBundle> = new Vector.<ResourceBundle>();
            resourceBundles.push(new AudioBundle());
            resourceBundles.push(new EmbeddedBrainPopData());
            resourceBundles.push(new EmbeddedBundle1X());
            resourceBundles.push(new EmbededOperatorAtlasBundle());
            resourceBundles.push(new EmbeddedLevelSelectResources());
            resourceBundles.push(new EmbeddedEggStills());
            resourceBundles.push(new EmbeddedBarModelResources());
            m_nameToBundleList["allResources"] = resourceBundles;
        }
        
        override public function getMainGameApplication():Class
        {
            return WordProblemGameBrainpop;
        }
    }
}