package gameconfig.versions.challenge0114;


import gameconfig.commonresource.AudioBundle;
import gameconfig.commonresource.EmbeddedBarModelResources;
import gameconfig.commonresource.EmbeddedBundle1X;
import gameconfig.commonresource.EmbeddedEggStills;
import gameconfig.commonresource.EmbeddedLevelSelectResources;
import gameconfig.commonresource.EmbededOperatorAtlasBundle;
import gameconfig.versions.challenge0316.WordProblemGameChallenge0316;

import levelscripts.barmodel.tutorials.LSAddBarA;
import levelscripts.barmodel.tutorials.LSAddComparisonA;
import levelscripts.barmodel.tutorials.LSAddLabelA;
import levelscripts.barmodel.tutorials.LSAddSegmentsA;
import levelscripts.barmodel.tutorials.LSAddVerticalLabelA;
import levelscripts.barmodel.tutorials.LSEquationFromBarA;
import levelscripts.barmodel.tutorials.LSFractionEnterCardA;
import levelscripts.barmodel.tutorials.LSMultiplyBarA;
import levelscripts.barmodel.tutorials.LSSplitCopyA;
import levelscripts.barmodel.tutorials.LSTextDiscoverA;
import levelscripts.barmodel.tutorials.LSTwoStepA;
import levels.tutorials.LSDivideTutorial;
import levels.tutorials.LSMultiplyTutorial;
import levels.tutorials.LSParenthesisTutorial;
import levels.tutorials.LSSubtractTutorial;

import wordproblem.AlgebraAdventureConfig;
import wordproblem.resource.bundles.ResourceBundle;
import wordproblem.scripts.level.GenericBarModelLevelScript;
import wordproblem.scripts.level.GenericModelLevelScript;

class GameConfig extends AlgebraAdventureConfig
{
    public function new()
    {
        super();
        
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
    }
    
    override private function instantiateResourceBundles() : Void
    {
        super.instantiateResourceBundles();
        
        m_nameToBundleList["config"] = [new ConfigurationBundle()];
        
        var resourceBundles : Array<ResourceBundle> = new Array<ResourceBundle>();
        resourceBundles.push(new AudioBundle());
        resourceBundles.push(new EmbeddedChallenge0114Data());
        resourceBundles.push(new EmbeddedBundle1X());
        resourceBundles.push(new EmbeddedBarModelResources());
        resourceBundles.push(new EmbededOperatorAtlasBundle());
        resourceBundles.push(new EmbeddedLevelSelectResources());
        resourceBundles.push(new EmbeddedEggStills());
        m_nameToBundleList["allResources"] = resourceBundles;
    }
    
    override public function getMainGameApplication() : Class<Dynamic>
    {
        return WordProblemGameChallenge0316;
    }
}
