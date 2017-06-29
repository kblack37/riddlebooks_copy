package gameconfig.versions.debug;


import gameconfig.commonresource.AudioBundle;
import gameconfig.commonresource.EmbeddedBarModelResources;
import gameconfig.commonresource.EmbeddedBundle1X;
import gameconfig.commonresource.EmbeddedEggStills;
import gameconfig.commonresource.EmbeddedLevelSelectResources;
import gameconfig.commonresource.EmbeddedProblemCreateExamples;
import gameconfig.commonresource.EmbededOperatorAtlasBundle;
import gameconfig.versions.debug.EmbeddedDebugData;

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

import wordproblem.AlgebraAdventureConfig;
import wordproblem.WordProblemGameDefault;
import wordproblem.creator.WordProblemGameCreateTemp;
import wordproblem.resource.bundles.ResourceBundle;
import wordproblem.scripts.level.GenericBarModelLevelScript;

class GameConfig extends AlgebraAdventureConfig
{
    public function new()
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
    
    override private function instantiateResourceBundles() : Void
    {
        super.instantiateResourceBundles();
        
        m_nameToBundleList["config"] = [new ConfigurationBundle()];
        
        var resourceBundles : Array<ResourceBundle> = new Array<ResourceBundle>();
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
    
    override public function getMainGameApplication() : Class<Dynamic>
    {
        return WordProblemGameDefault;
    }
}
