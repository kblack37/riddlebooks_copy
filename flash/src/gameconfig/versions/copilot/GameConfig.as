package gameconfig.versions.copilot
{
    import gameconfig.commonresource.AudioBundle;
    import gameconfig.commonresource.EmbeddedBarModelResources;
    import gameconfig.commonresource.EmbeddedBundle1X;
    import gameconfig.commonresource.EmbeddedDefaultItemsChapterCharacterData;
    import gameconfig.commonresource.EmbededOperatorAtlasBundle;
    import gameconfig.versions.debug.ConfigurationBundle;
    
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
    import levels.tutorials.LS_divide_tutorial;
    import levels.tutorials.LS_multiply_tutorial;
    import levels.tutorials.LS_parenthesis_tutorial;
    import levels.tutorials.LS_subtract_tutorial;
    
    import wordproblem.AlgebraAdventureConfig;
    import wordproblem.resource.bundles.ResourceBundle;
    import wordproblem.scripts.level.GenericBarModelLevelScript;
    import wordproblem.scripts.level.GenericModelLevelScript;

    public class GameConfig extends AlgebraAdventureConfig
    {
        [Embed(source="config_copilot.xml", mimeType="application/octet-stream")] 
        private static const CONFIG:Class;
        
        public function GameConfig()
        {
            GenericModelLevelScript;
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
            
            LS_subtract_tutorial;
            LS_multiply_tutorial;
            LS_divide_tutorial;
            LS_parenthesis_tutorial;
            
            LS_subtract_tutorial;
            LS_multiply_tutorial;
            LS_divide_tutorial;
            LS_parenthesis_tutorial;
        }
        
        public function getConfigString():String
        {
            return new CONFIG().toString();
        }
        
        override protected function instantiateResourceBundles():void
        {
            super.instantiateResourceBundles();
            
            m_nameToBundleList["config"] = Vector.<ResourceBundle>([new ConfigurationBundle()]);            
            
            var resourceBundles:Vector.<ResourceBundle> = new Vector.<ResourceBundle>();
            resourceBundles.push(new AudioBundle());
            resourceBundles.push(new EmbeddedBundle1X());
            resourceBundles.push(new EmbededOperatorAtlasBundle());
            resourceBundles.push(new EmbeddedBarModelResources());
            resourceBundles.push(new EmbeddedCopilotBarModelBundle());
            resourceBundles.push(new EmbeddedDefaultItemsChapterCharacterData());
            m_nameToBundleList["allResources"] = resourceBundles;
        }
        
        override public function getMainGameApplication():Class
        {
            return WordProblemGameCopilot;
        }
    }
}