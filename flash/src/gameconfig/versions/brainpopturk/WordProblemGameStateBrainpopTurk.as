package gameconfig.versions.brainpopturk
{
    import cgs.levelProgression.nodes.ICgsLevelNode;
    import cgs.levelProgression.nodes.ICgsLevelPack;
    
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
    
    public class WordProblemGameStateBrainpopTurk extends WordProblemGameState
    {
        public function WordProblemGameStateBrainpopTurk(stateMachine:IStateMachine, 
                                                         gameEngine:IGameEngine, 
                                                         assetManager:AssetManager, 
                                                         compiler:IExpressionTreeCompiler, 
                                                         expressionSymbolMap:ExpressionSymbolMap,
                                                         config:AlgebraAdventureConfig, 
                                                         console:IConsole, 
                                                         buttonColorData:ButtonColorData, 
                                                         levelManager:WordProblemCgsLevelManager)
        {
            super(stateMachine, gameEngine, assetManager, compiler, expressionSymbolMap, config, console, buttonColorData, levelManager);
        }
        
        override protected function getLevelDescriptor(levelData:WordProblemLevelData):String
        {
            var currentLevelId:String = levelData.getName();
            
            // Extract all level nodes, treat it as a linear progression
            var levelLabel:String = "";
            if (m_levelManager.currentLevelProgression)
            {
                var currentLevelNode:WordProblemLevelLeaf = m_levelManager.getNodeByName(currentLevelId) as WordProblemLevelLeaf;
                var outChapterNodes:Vector.<ChapterLevelPack> = new Vector.<ChapterLevelPack>();
                getChapterNodes(outChapterNodes, m_levelManager.currentLevelProgression);
                var i:int;
                var indexOfCurrentSetInSequence:int = -1;
                var numSetsToShow:int = outChapterNodes.length;
                for (i = 0; i < numSetsToShow; i++)
                {
                    var chapter:ChapterLevelPack = outChapterNodes[i];
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
        
        private function getChapterNodes(outChapterNodes:Vector.<ChapterLevelPack>, levelNode:ICgsLevelNode):void
        {
            if (levelNode != null)
            {
                if (levelNode is ChapterLevelPack)
                {
                    outChapterNodes.push(levelNode);
                }
                else if (levelNode is ICgsLevelPack)
                {
                    var children:Vector.<ICgsLevelNode> = (levelNode as ICgsLevelPack).nodes;
                    var numChildren:int = children.length;
                    var i:int;
                    for (i = 0; i < numChildren; i++)
                    {
                        getChapterNodes(outChapterNodes, children[i]);
                    }
                }
            }
        }
        
        private function isLevelInPack(levelPack:ICgsLevelPack, level:WordProblemLevelLeaf):Boolean
        {
            var levelInPack:Boolean = false;
            var i:int;
            var numLevelsInPack:int = levelPack.nodes.length;
            for (i = 0; i < numLevelsInPack; i++)
            {
                var childNode:ICgsLevelNode = levelPack.nodes[i];
                if (childNode is ICgsLevelPack)
                {
                    levelInPack = isLevelInPack(childNode as ICgsLevelPack, level);
                }
                else if (childNode is WordProblemLevelLeaf)
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
}