package gameconfig.versions.brainpop;


import gameconfig.commonresource.AudioBundle;
import gameconfig.commonresource.EmbeddedBarModelResources;
import gameconfig.commonresource.EmbeddedBundle1X;
import gameconfig.commonresource.EmbeddedEggStills;
import gameconfig.commonresource.EmbeddedLevelSelectResources;
import gameconfig.commonresource.EmbededOperatorAtlasBundle;
import gameconfig.versions.brainpop.ConfigurationBundle;

import levelscripts.barmodel.tutorials.LSAddBarA;
import levelscripts.barmodel.tutorials.LSAddComparisonA;
import levelscripts.barmodel.tutorials.LSAddLabelA;
import levelscripts.barmodel.tutorials.LSAddSegmentsA;
import levelscripts.barmodel.tutorials.LSEquationFromBarA;
import levelscripts.barmodel.tutorials.LSFractionEnterCardA;
import levelscripts.barmodel.tutorials.LSMultiplyBarA;
import levelscripts.barmodel.tutorials.LSSplitCopyA;
import levelscripts.barmodel.tutorials.LSTextDiscoverA;
import levelscripts.barmodel.tutorials.LSTwoStepA;
import levels.brainpop.LSBrainpopAddBothSides;
import levels.brainpop.LSBrainpopAddition;
import levels.brainpop.LSBrainpopIntro;
import levels.tutorials.LSDivideTutorial;
import levels.tutorials.LSMultiplyTutorial;
import levels.tutorials.LSParenthesisTutorial;
import levels.tutorials.LSSubtractTutorial;

import wordproblem.AlgebraAdventureConfig;
import wordproblem.WordProblemGameBrainpop;
import wordproblem.resource.bundles.ResourceBundle;
import wordproblem.scripts.level.GenericBarModelLevelScript;

class GameConfig extends AlgebraAdventureConfig
{
    public function new()
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
    
    override private function instantiateResourceBundles() : Void
    {
        super.instantiateResourceBundles();
        
        m_nameToBundleList["config"] = [new ConfigurationBundle()];
        
        var resourceBundles : Array<ResourceBundle> = new Array<ResourceBundle>();
        resourceBundles.push(new AudioBundle());
        resourceBundles.push(new EmbeddedBrainPopData());
        resourceBundles.push(new EmbeddedBundle1X());
        resourceBundles.push(new EmbededOperatorAtlasBundle());
        resourceBundles.push(new EmbeddedLevelSelectResources());
        resourceBundles.push(new EmbeddedEggStills());
        resourceBundles.push(new EmbeddedBarModelResources());
        m_nameToBundleList["allResources"] = resourceBundles;
    }
    
    override public function getMainGameApplication() : Class<Dynamic>
    {
        return WordProblemGameBrainpop;
    }
}
