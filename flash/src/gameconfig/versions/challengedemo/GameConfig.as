package gameconfig.versions.challengedemo
{
    import gameconfig.commonresource.AudioBundle;
    import gameconfig.commonresource.EmbeddedBarModelResources;
    import gameconfig.commonresource.EmbeddedBundle1X;
    import gameconfig.commonresource.EmbeddedEggStills;
    import gameconfig.commonresource.EmbeddedLevelSelectResources;
    import gameconfig.commonresource.EmbededOperatorAtlasBundle;
    
    import levelscripts.barmodel.tutorialsv2.IntroAddLabel;
    import levelscripts.barmodel.tutorialsv2.IntroAddLabelEasy;
    import levelscripts.barmodel.tutorialsv2.IntroAdvancedMultDiv;
    import levelscripts.barmodel.tutorialsv2.IntroCreateEquation;
    import levelscripts.barmodel.tutorialsv2.IntroDivision;
    import levelscripts.barmodel.tutorialsv2.IntroFractionsSimple;
    import levelscripts.barmodel.tutorialsv2.IntroMultiplication;
    import levelscripts.barmodel.tutorialsv2.IntroPickText;
    import levelscripts.barmodel.tutorialsv2.IntroPickTextEasy;
    import levelscripts.barmodel.tutorialsv2.IntroSubtraction;
    import levelscripts.barmodel.tutorialsv2.IntroTwoStepNoGroups;
    
    import wordproblem.AlgebraAdventureConfig;
    import wordproblem.resource.bundles.ResourceBundle;
    import wordproblem.scripts.level.GenericBarModelLevelScript;
    import wordproblem.scripts.level.GenericModelLevelScript;
    
    public class GameConfig extends AlgebraAdventureConfig
    {
        //[Embed(source="/../assets/strings/locales/es.xml", mimeType="application/octet-stream")] 
        //private static const LOCALE_STRINGS:Class;
        
        public function GameConfig()
        {
            super();
            
            GenericModelLevelScript;
            GenericBarModelLevelScript;
            
            IntroAddLabel;
            IntroCreateEquation;
            IntroDivision;
            IntroAdvancedMultDiv;
            IntroMultiplication;
            IntroSubtraction;
            IntroFractionsSimple;
            IntroTwoStepNoGroups;
            IntroPickText;
            
            // Easier tutorials for lower grade levels
            IntroAddLabelEasy;
            IntroPickTextEasy;
        }
        
        override protected function instantiateResourceBundles():void
        {
            super.instantiateResourceBundles();
            
            m_nameToBundleList["config"] = Vector.<ResourceBundle>([new ConfigurationBundle()]);  
            
            var resourceBundles:Vector.<ResourceBundle> = new Vector.<ResourceBundle>();
            resourceBundles.push(new AudioBundle());
            resourceBundles.push(new EmbeddedData());
            resourceBundles.push(new EmbeddedBundle1X());
            resourceBundles.push(new EmbeddedBarModelResources());
            resourceBundles.push(new EmbededOperatorAtlasBundle());
            resourceBundles.push(new EmbeddedLevelSelectResources());
            resourceBundles.push(new EmbeddedEggStills());
            m_nameToBundleList["allResources"] = resourceBundles;
        }
        
        override public function getMainGameApplication():Class
        {
            return WordProblemGameChallengeDemo;
        }
        /*
        override public function getLocalizationClassForStringTable():Class
        {
            return LOCALE_STRINGS;
        }
        */
    }
}