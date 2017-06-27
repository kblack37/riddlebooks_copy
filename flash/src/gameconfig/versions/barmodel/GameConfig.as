package gameconfig.versions.barmodel
{
    import gameconfig.commonresource.AudioBundle;
    import gameconfig.commonresource.EmbeddedBarModelData;
    import gameconfig.commonresource.EmbeddedBarModelResources;
    import gameconfig.commonresource.EmbeddedBundle1X;
    import gameconfig.commonresource.EmbeddedEggStills;
    import gameconfig.commonresource.EmbeddedLevelSelectResources;
    import gameconfig.commonresource.EmbededOperatorAtlasBundle;
    
    import levels.bar_model.tutorial.LS_combine_bar_A;
    import levels.bar_model.tutorial.LS_combine_bar_label_A;
    import levels.bar_model.tutorial.LS_combine_bar_label_B;
    import levels.bar_model.tutorial.LS_fill_bar_A;
    import levels.bar_model.tutorial.LS_fill_bar_generic;
    import levels.bar_model.tutorial.LS_fill_label_A;
    import levels.bar_model.tutorial.LS_remove_bar_A;
    import levels.tutorials.LS_code_cracker;
    import levels.tutorials.LS_divide_tutorial;
    import levels.tutorials.LS_intro_questions;
    import levels.tutorials.LS_multiply_tutorial;
    import levels.tutorials.LS_parenthesis_tutorial;
    import levels.tutorials.LS_say_cheese_p1;
    import levels.tutorials.LS_subtract_tutorial;
    import levels.tutorials.LS_zoo_escape;
    
    import wordproblem.AlgebraAdventureConfig;
    import wordproblem.WordProblemGameDefault;
    import wordproblem.resource.bundles.ResourceBundle;
    
    public class GameConfig extends AlgebraAdventureConfig
    {
        [Embed(source="config_barmodel.xml", mimeType="application/octet-stream")] 
        private static const CONFIG:Class;
        
        public function GameConfig()
        {
            super(new CONFIG().toString());
            
            // Custom level scripts used by this release
            LS_fill_bar_A;
            LS_fill_bar_generic;
            LS_combine_bar_A;
            LS_fill_label_A;
            LS_remove_bar_A;
            LS_combine_bar_label_A;
            LS_combine_bar_label_B;
            
            LS_intro_questions
            levels.tutorials.LS_say_cheese_p1;
            levels.tutorials.LS_code_cracker;
            levels.tutorials.LS_zoo_escape;
            
            LS_subtract_tutorial;
            LS_multiply_tutorial;
            LS_divide_tutorial;
            LS_parenthesis_tutorial;
        }
        
        override public function getResourceBundles():Vector.<ResourceBundle>
        {
            var resourceBundles:Vector.<ResourceBundle> = new Vector.<ResourceBundle>();
            resourceBundles.push(new AudioBundle());
            resourceBundles.push(new EmbeddedBarModelResources());
            resourceBundles.push(new EmbeddedBarModelData());
            resourceBundles.push(new EmbeddedBundle1X());
            resourceBundles.push(new EmbededOperatorAtlasBundle());
            resourceBundles.push(new EmbeddedLevelSelectResources());
            resourceBundles.push(new EmbeddedEggStills());
            return resourceBundles;
        }
        
        override public function getMainGameApplication():Class
        {
            return WordProblemGameDefault;
        }
    }
}