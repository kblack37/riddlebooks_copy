package wordproblem.engine.scripting
{
	import flash.utils.getDefinitionByName;
	import gameconfig.versions.brainpopturk.WordProblemGameBrainpopTurk;
	import wordproblem.level.controller.WordProblemCgsLevelManager;
	
	import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
	
	import wordproblem.engine.IGameEngine;
	import wordproblem.engine.scripting.graph.ScriptNode;
	import wordproblem.engine.scripting.graph.selector.ConcurrentSelector;
	import wordproblem.engine.scripting.graph.selector.SequenceSelector;
	import wordproblem.player.PlayerStatsAndSaveData;
	import wordproblem.resource.AssetManager;
	import wordproblem.scripts.level.GenericModelLevelScript;

	public class ScriptParser
	{
		private static const GENERIC_BAR_MODEL_LEVEL_SCRIPT_NAME:String = "wordproblem.scripts.level.GenericBarModelLevelScript";
		
        private var m_engine:IGameEngine;
        private var m_compiler:IExpressionTreeCompiler;
        private var m_assetManager:AssetManager;
        private var m_playerStatsAndSaveData:PlayerStatsAndSaveData;
		private var m_levelManager:WordProblemCgsLevelManager;
        
		public function ScriptParser(engine:IGameEngine, 
                                     compiler:IExpressionTreeCompiler, 
                                     assetManager:AssetManager, 
                                     playerStatsAndSaveData:PlayerStatsAndSaveData,
									 levelManager:WordProblemCgsLevelManager=null)
		{
            m_engine = engine;
            m_compiler = compiler;
            m_assetManager = assetManager;
            m_playerStatsAndSaveData = playerStatsAndSaveData;
			m_levelManager = levelManager;
		}
		
        /**
         * Parse xml structured script sequence into a behavior tree.
         * 
         * @return 
         *      Root of the behavior tree representing the script
         */
        public function parse(xml:XML):ScriptNode
        {
            var rootScript:ScriptNode;
            
            var allNodeElements:XMLList = xml.elements();
            
            var nodeElement:XML;
            // This loop should really only ever fire once
            for each(nodeElement in allNodeElements)
            {
                rootScript = createNode(nodeElement);
            }
            
            return rootScript;
        }
        
		private function createNode(nodeElement:XML):ScriptNode
		{
			var rootNode:ScriptNode;
			var nodeType:String = nodeElement.name();
			
			// Figure out the type of node to construct, this will affect the location of the
			// children
			var isRegularSelectorNode:Boolean = false;
			if (nodeType == "concurrent")
			{
				isRegularSelectorNode = true;
                const failThreshold:int = (nodeElement.hasOwnProperty("@failThreshold")) ?
                    parseInt(nodeElement.attribute("failThreshold")) : -1;
				rootNode = new ConcurrentSelector(failThreshold);
			}
			else if (nodeType == "sequence")
			{
				isRegularSelectorNode = true;
				rootNode = new SequenceSelector();
			}
            // Extra condition that creates a specific class object that has a hardcoded script
            else if (nodeType == "code")
            {
                if (nodeElement.hasOwnProperty("@id"))
                {
                    var fullyQualifiedName:String = nodeElement.@id;   
					var scriptClass:Class = getDefinitionByName(fullyQualifiedName) as Class;
					//HACK: Pass in additional data to bar model level script
					if (fullyQualifiedName == GENERIC_BAR_MODEL_LEVEL_SCRIPT_NAME ) {
						rootNode = new scriptClass(m_engine, m_compiler, m_assetManager, m_playerStatsAndSaveData, m_levelManager) as ScriptNode;
					} else {
						rootNode = new scriptClass(m_engine, m_compiler, m_assetManager, m_playerStatsAndSaveData) as ScriptNode;
					}
                    
                    
                    // A custom level script might need to pass in extra data
                    // For example, dialog options for various characters.
                    if (nodeElement.elements().length() > 0)
                    {
                        var list:XMLList = nodeElement.elements();
                        rootNode.setExtraData(list);
                    }
                }
                else
                {
                    var dataElement:XML = nodeElement.elements("data")[0];
                    var data:Object = JSON.parse(dataElement.text());
                    
                    // Append hint data
                    var i:int;
                    const variableHints:Array = [];
                    const variableHintElements:XMLList = nodeElement.elements("variableHint");
                    for (i = 0; i < variableHintElements.length(); i++)
                    {
                        var variableHintElement:XML = variableHintElements[i];
                        variableHints.push(
                            {
                                "textContent":variableHintElement.children()[0],
                                "termValue":variableHintElement.@termValue,
                                "documentId":variableHintElement.@documentId
                            }
                        );
                    }
                    data["variableHints"] = variableHints;
                        
                    const expressionHints:Array = [];
                    const expressionHintElements:XMLList = nodeElement.elements("expressionHint");
                    for (i = 0; i < expressionHintElements.length(); i++)
                    {
                        var expressionHintElement:XML = expressionHintElements[i];
                        expressionHints.push(
                            {
                                "textContent":expressionHintElement.children()[0],
                                "expression":expressionHintElement.@expression
                            }
                        );
                    }
                    data["expressionHints"] = expressionHints;
                    
                    rootNode = new GenericModelLevelScript(data, m_engine, m_compiler, m_assetManager, m_playerStatsAndSaveData);
                }
            }
            else
            {
                throw new Error("Unknown level config script node:" + nodeType);
            }
			
			if (isRegularSelectorNode)
			{
				// Examine the children of the subroot and add them to the
				// tree structure
				for each (var childElement:XML in nodeElement.elements())
				{
					var childNode:ScriptNode = createNode(childElement);
					rootNode.pushChild(childNode);
				}
			}
			
			return rootNode;
		}
	}
}