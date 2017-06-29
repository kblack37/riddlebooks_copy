package gameconfig.versions.brainpopturk;


import cgs.levelprogression.nodes.ICgsLevelNode;
import cgs.levelprogression.nodes.ICgsLevelPack;

import dragonbox.common.console.IConsole;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.state.IStateMachine;

import wordproblem.AlgebraAdventureConfig;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.level.WordProblemLevelData;
import wordproblem.level.controller.WordProblemCgsLevelManager;
import wordproblem.level.nodes.ChapterLevelPack;
import wordproblem.level.nodes.WordProblemLevelLeaf;
import wordproblem.player.ButtonColorData;
import wordproblem.resource.AssetManager;
import wordproblem.state.WordProblemGameState;

class WordProblemGameStateBrainpopTurk extends WordProblemGameState
{
    public function new(stateMachine : IStateMachine,
            gameEngine : IGameEngine,
            assetManager : AssetManager,
            compiler : IExpressionTreeCompiler,
            expressionSymbolMap : ExpressionSymbolMap,
            config : AlgebraAdventureConfig,
            console : IConsole,
            buttonColorData : ButtonColorData,
            levelManager : WordProblemCgsLevelManager)
    {
        super(stateMachine, gameEngine, assetManager, compiler, expressionSymbolMap, config, console, buttonColorData, levelManager);
    }
    
    override private function getLevelDescriptor(levelData : WordProblemLevelData) : String
    {
        var currentLevelId : String = levelData.getName();
        
        // Extract all level nodes, treat it as a linear progression
        var levelLabel : String = "";
        if (m_levelManager.currentLevelProgression) 
        {
            var currentLevelNode : WordProblemLevelLeaf = try cast(m_levelManager.getNodeByName(currentLevelId), WordProblemLevelLeaf) catch(e:Dynamic) null;
            var outChapterNodes : Array<ChapterLevelPack> = new Array<ChapterLevelPack>();
            getChapterNodes(outChapterNodes, m_levelManager.currentLevelProgression);
            var i : Int;
            var indexOfCurrentSetInSequence : Int = -1;
            var numSetsToShow : Int = outChapterNodes.length;
            for (i in 0...numSetsToShow){
                var chapter : ChapterLevelPack = outChapterNodes[i];
                if (isLevelInPack(chapter, currentLevelNode)) 
                {
                    indexOfCurrentSetInSequence = i + 1;
                    break;
                }
            }
            
            levelLabel = "Problem Set " + indexOfCurrentSetInSequence + " of " + numSetsToShow;
        }
        
        return levelLabel;
    }
    
    private function getChapterNodes(outChapterNodes : Array<ChapterLevelPack>, levelNode : ICgsLevelNode) : Void
    {
        if (levelNode != null) 
        {
            if (Std.is(levelNode, ChapterLevelPack)) 
            {
                outChapterNodes.push(levelNode);
            }
            else if (Std.is(levelNode, ICgsLevelPack)) 
            {
                var children : Array<ICgsLevelNode> = (try cast(levelNode, ICgsLevelPack) catch(e:Dynamic) null).nodes;
                var numChildren : Int = children.length;
                var i : Int;
                for (i in 0...numChildren){
                    getChapterNodes(outChapterNodes, children[i]);
                }
            }
        }
    }
    
    private function isLevelInPack(levelPack : ICgsLevelPack, level : WordProblemLevelLeaf) : Bool
    {
        var levelInPack : Bool = false;
        var i : Int;
        var numLevelsInPack : Int = levelPack.nodes.length;
        for (i in 0...numLevelsInPack){
            var childNode : ICgsLevelNode = levelPack.nodes[i];
            if (Std.is(childNode, ICgsLevelPack)) 
            {
                levelInPack = isLevelInPack(try cast(childNode, ICgsLevelPack) catch(e:Dynamic) null, level);
            }
            else if (Std.is(childNode, WordProblemLevelLeaf)) 
            {
                levelInPack = (level == childNode);
            }
            
            if (levelInPack) 
            {
                break;
            }
        }
        return levelInPack;
    }
}
