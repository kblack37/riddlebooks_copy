package gameconfig.versions.barmodel;

import gameconfig.versions.barmodel.CONFIG;

import gameconfig.commonresource.AudioBundle;
import gameconfig.commonresource.EmbeddedBarModelData;
import gameconfig.commonresource.EmbeddedBarModelResources;
import gameconfig.commonresource.EmbeddedBundle1X;
import gameconfig.commonresource.EmbeddedEggStills;
import gameconfig.commonresource.EmbeddedLevelSelectResources;
import gameconfig.commonresource.EmbededOperatorAtlasBundle;

import levels.bar_model.tutorial.LSCombineBarA;
import levels.bar_model.tutorial.LSCombineBarLabelA;
import levels.bar_model.tutorial.LSCombineBarLabelB;
import levels.bar_model.tutorial.LSFillBarA;
import levels.bar_model.tutorial.LSFillBarGeneric;
import levels.bar_model.tutorial.LSFillLabelA;
import levels.bar_model.tutorial.LSRemoveBarA;
import levels.tutorials.LSCodeCracker;
import levels.tutorials.LSDivideTutorial;
import levels.tutorials.LSIntroQuestions;
import levels.tutorials.LSMultiplyTutorial;
import levels.tutorials.LSParenthesisTutorial;
import levels.tutorials.LSSayCheeseP1;
import levels.tutorials.LSSubtractTutorial;
import levels.tutorials.LSZooEscape;

import wordproblem.AlgebraAdventureConfig;
import wordproblem.WordProblemGameDefault;
import wordproblem.resource.bundles.ResourceBundle;

class GameConfig extends AlgebraAdventureConfig
{
    @:meta(Embed(source="config_barmodel.xml",mimeType="application/octet-stream"))

    private static var CONFIG : Class<Dynamic>;
    
    public function new()
    {
        super(Std.string(Type.createInstance(CONFIG, [])));
        
        // Custom level scripts used by this release
        LS_fill_bar_A;
        LS_fill_bar_generic;
        LS_combine_bar_A;
        LS_fill_label_A;
        LS_remove_bar_A;
        LS_combine_bar_label_A;
        LS_combine_bar_label_B;
        
        LS_intro_questions;
        levels.tutorials.LS_say_cheese_p1;
        levels.tutorials.LS_code_cracker;
        levels.tutorials.LS_zoo_escape;
        
        LS_subtract_tutorial;
        LS_multiply_tutorial;
        LS_divide_tutorial;
        LS_parenthesis_tutorial;
    }
    
    override public function getResourceBundles() : Array<ResourceBundle>
    {
        var resourceBundles : Array<ResourceBundle> = new Array<ResourceBundle>();
        resourceBundles.push(new AudioBundle());
        resourceBundles.push(new EmbeddedBarModelResources());
        resourceBundles.push(new EmbeddedBarModelData());
        resourceBundles.push(new EmbeddedBundle1X());
        resourceBundles.push(new EmbededOperatorAtlasBundle());
        resourceBundles.push(new EmbeddedLevelSelectResources());
        resourceBundles.push(new EmbeddedEggStills());
        return resourceBundles;
    }
    
    override public function getMainGameApplication() : Class<Dynamic>
    {
        return WordProblemGameDefault;
    }
}
