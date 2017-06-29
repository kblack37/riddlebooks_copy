package gameconfig.versions.replay.scripts;


import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import starling.display.DisplayObject;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;
import wordproblem.scripts.barmodel.SwitchBetweenBarAndEquationModel;

/**
 * Script containing the additional logic necessary to make a bar model level functional
 * in terms of just seeing the replay.
 * 
 * This may include altering the behavior of some of the ui components
 */
class ReplayBarModelLevel extends BaseGameScript
{
    private var m_switchModelScript : SwitchBetweenBarAndEquationModel;
    private var m_uiSetUp : Bool;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        // Make sure the bar model area has slid up and allow the user viewing the replay to freely
        // transition in between bar modeling and equation modeling
        var switchModelScript : SwitchBetweenBarAndEquationModel = new SwitchBetweenBarAndEquationModel(m_gameEngine, m_expressionCompiler, m_assetManager, null);
        super.pushChild(switchModelScript);
        m_switchModelScript = switchModelScript;
        
        m_uiSetUp = false;
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
    }
    
    override public function visit() : Int
    {
        if (m_isActive && m_ready) 
        {
            if (!m_uiSetUp) 
            {
                // Ui container
                var originalYLocation : Float = 270;
                var uiContainer : DisplayObject = m_gameEngine.getUiEntity("deckAndTermContainer");
                m_switchModelScript.setContainerOriginalY(originalYLocation);
                uiContainer.y = originalYLocation;
                
                m_uiSetUp = true;
            }
        }
        return ScriptStatus.SUCCESS;
    }
}
