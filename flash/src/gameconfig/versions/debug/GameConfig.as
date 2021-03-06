package gameconfig.versions.debug
{
    import gameconfig.commonresource.AudioBundle;
    import gameconfig.commonresource.EmbeddedBarModelResources;
    import gameconfig.commonresource.EmbeddedBundle1X;
    import gameconfig.commonresource.EmbeddedEggStills;
    import gameconfig.commonresource.EmbeddedLevelSelectResources;
    import gameconfig.commonresource.EmbeddedProblemCreateExamples;
    import gameconfig.commonresource.EmbededOperatorAtlasBundle;
    import gameconfig.versions.debug.EmbeddedDebugData;
    
    import levelscripts.barmodel.tutorials.LS_AddBarA;
    import levelscripts.barmodel.tutorials.LS_AddComparisonA;
    import levelscripts.barmodel.tutorials.LS_AddLabelA;
    import levelscripts.barmodel.tutorials.LS_AddSegmentsA;
    import levelscripts.barmodel.tutorials.LS_AddVerticalLabelA;
    import levelscripts.barmodel.tutorials.LS_EquationFromBarA;
    import levelscripts.barmodel.tutorials.LS_FractionEnterCardA;
    import levelscripts.barmodel.tutorials.LS_MultiplyBarA;
    import levelscripts.barmodel.tutorials.LS_SplitCopyA;
    import levelscripts.barmodel.tutorials.LS_TextDiscoverA;
    import levelscripts.barmodel.tutorials.LS_TwoStepA;
    
    import wordproblem.AlgebraAdventureConfig;
    import wordproblem.WordProblemGameDefault;
    import wordproblem.creator.WordProblemGameCreateTemp;
    import wordproblem.resource.bundles.ResourceBundle;
    import wordproblem.scripts.level.GenericBarModelLevelScript;

    public class GameConfig extends AlgebraAdventureConfig
    {
        public function GameConfig()
        {
            super();
            
            GenericBarModelLevelScript;
            
            LS_AddBarA;
            LS_AddLabelA;
            LS_AddSegmentsA;
            LS_EquationFromBarA;
            LS_TextDiscoverA;
            LS_AddComparisonA;
            LS_AddVerticalLabelA;
            LS_MultiplyBarA;
            LS_SplitCopyA;
            LS_FractionEnterCardA;
            LS_TwoStepA;
        }
        
        override protected function instantiateResourceBundles():void
        {
            super.instantiateResourceBundles();
            
            m_nameToBundleList["config"] = Vector.<ResourceBundle>([new ConfigurationBundle()]);            
            
            var resourceBundles:Vector.<ResourceBundle> = new Vector.<ResourceBundle>();
            resourceBundles.push(new AudioBundle());
            resourceBundles.push(new EmbeddedDebugData());
            resourceBundles.push(new EmbeddedBundle1X());
            resourceBundles.push(new EmbeddedBarModelResources());
            resourceBundles.push(new EmbededOperatorAtlasBundle());
            resourceBundles.push(new EmbeddedLevelSelectResources());
            resourceBundles.push(new EmbeddedEggStills());
            
            resourceBundles.push(new EmbeddedProblemCreateExamples());
            m_nameToBundleList["allResources"] = resourceBundles;
        }
        
        override public function getMainGameApplication():Class
        {
            return WordProblemGameDefault;//WordProblemGameCreateTemp;//
        }
    }
}