package wordproblem.engine.scripting;

import flash.errors.Error;
import haxe.xml.Fast;
//import wordproblem.engine.scripting.ScriptClass;


import gameconfig.versions.brainpopturk.WordProblemGameBrainpopTurk;
import wordproblem.level.controller.WordProblemCgsLevelManager;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.selector.ConcurrentSelector;
import wordproblem.engine.scripting.graph.selector.SequenceSelector;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.level.GenericBarModelLevelScript;
import wordproblem.scripts.level.GenericModelLevelScript;

class ScriptParser
{
    private static inline var GENERIC_BAR_MODEL_LEVEL_SCRIPT_NAME : String = "wordproblem.scripts.level.GenericBarModelLevelScript";
    
    private var m_engine : IGameEngine;
    private var m_compiler : IExpressionTreeCompiler;
    private var m_assetManager : AssetManager;
    private var m_playerStatsAndSaveData : PlayerStatsAndSaveData;
    private var m_levelManager : WordProblemCgsLevelManager;
    
    public function new(engine : IGameEngine,
            compiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            playerStatsAndSaveData : PlayerStatsAndSaveData,
            levelManager : WordProblemCgsLevelManager = null)
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
    public function parse(xml : Xml) : ScriptNode
    {
        var rootScript : ScriptNode = null;
        
        var allNodeElements = (new Fast(xml)).elements;
        
        // This loop should really only ever fire once
        for (nodeElement in allNodeElements)
        {
            rootScript = createNode(nodeElement);
        }
        
        return rootScript;
    }
    
    private function createNode(nodeElement : Fast) : ScriptNode
    {
        var rootNode : ScriptNode = null;
        var nodeType : String = nodeElement.name;
        
        // Figure out the type of node to construct, this will affect the location of the
        // children
        var isRegularSelectorNode : Bool = false;
        if (nodeType == "concurrent") 
        {
            isRegularSelectorNode = true;
            var failThreshold : Int = nodeElement.has.failThreshold ? 
				Std.parseInt(nodeElement.att.failThreshold) : -1;
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
            if (nodeElement.has.id) 
            {
                var fullyQualifiedName : String = nodeElement.att.id;
                var scriptClass = Type.resolveClass(fullyQualifiedName);
                //HACK: Pass in additional data to bar model level script
                if (fullyQualifiedName == GENERIC_BAR_MODEL_LEVEL_SCRIPT_NAME) {
                    rootNode = try cast(Type.createInstance(scriptClass, [m_engine, m_compiler, m_assetManager, m_playerStatsAndSaveData, m_levelManager, null, true]), ScriptNode) catch(e:Dynamic) null;
                }
                else {
                    rootNode = try cast(Type.createInstance(scriptClass, [m_engine, m_compiler, m_assetManager, m_playerStatsAndSaveData]), ScriptNode) catch(e:Dynamic) null;
                }
				
				// A custom level script might need to pass in extra data  
				// For example, dialog options for various characters.                
                if (nodeElement.elements.hasNext()) 
                {
					var list = nodeElement.elements;
					if (rootNode != null) rootNode.setExtraData(list);
                }
            }
            else 
            {
                var dataElement : Fast = nodeElement.node.data;
                var data : Dynamic = haxe.Json.parse(dataElement.innerData);
                
                // Append hint data
                var i : Int = 0;
                var variableHints : Array<Dynamic> = [];
                var variableHintElements = nodeElement.nodes.variableHint;
				for (variableHintElement in variableHintElements) {
                    variableHints.push(
                            {
                                textContent : variableHintElement.innerData,
                                termValue : variableHintElement.att.termValue,
                                documentId : variableHintElement.att.documentId,
                            });
                }
                Reflect.setField(data, "variableHints", variableHints);
                
                var expressionHints : Array<Dynamic> = [];
                var expressionHintElements = nodeElement.nodes.expressionHint;
				for (expressionHintElement in expressionHintElements) {
                    expressionHints.push(
                            {
                                textContent : expressionHintElement.innerData,
                                expression : expressionHintElement.att.expression,
                            });
                }
                Reflect.setField(data, "expressionHints", expressionHints);
                
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
            for (childElement in nodeElement.elements)
            {
                var childNode : ScriptNode = createNode(childElement);
                rootNode.pushChild(childNode);
            }
        }
        
        return rootNode;
    }
}
