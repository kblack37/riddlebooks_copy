package wordproblem.engine.scripting;

import flash.errors.Error;
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
    public function parse(xml : FastXML) : ScriptNode
    {
        var rootScript : ScriptNode;
        
        var allNodeElements : FastXMLList = xml.node.elements.innerData();
        
        var nodeElement : FastXML;
        // This loop should really only ever fire once
        for (nodeElement in allNodeElements)
        {
            rootScript = createNode(nodeElement);
        }
        
        return rootScript;
    }
    
    private function createNode(nodeElement : FastXML) : ScriptNode
    {
        var rootNode : ScriptNode;
        var nodeType : String = nodeElement.node.name.innerData();
        
        // Figure out the type of node to construct, this will affect the location of the
        // children
        var isRegularSelectorNode : Bool = false;
        if (nodeType == "concurrent") 
        {
            isRegularSelectorNode = true;
            var failThreshold : Int = ((nodeElement.node.exists.innerData("@failThreshold"))) ? 
            parseInt(nodeElement.node.attribute.innerData("failThreshold")) : -1;
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
            if (nodeElement.node.exists.innerData("@id")) 
            {
                var fullyQualifiedName : String = nodeElement.att.id;
                var scriptClass : Class<Dynamic> = Type.getClass(Type.resolveClass(fullyQualifiedName));
                //HACK: Pass in additional data to bar model level script
                if (fullyQualifiedName == GENERIC_BAR_MODEL_LEVEL_SCRIPT_NAME) {
                    rootNode = try cast(Type.createInstance(scriptClass, [m_engine, m_compiler, m_assetManager, m_playerStatsAndSaveData, m_levelManager]), ScriptNode) catch(e:Dynamic) null;
                }
                else {
                    rootNode = try cast(Type.createInstance(scriptClass, [m_engine, m_compiler, m_assetManager, m_playerStatsAndSaveData]), ScriptNode) catch(e:Dynamic) null;
                }  // For example, dialog options for various characters.    // A custom level script might need to pass in extra data  
                
                
                
                
                
                
                if (nodeElement.node.elements.innerData().length() > 0) 
                {
                    var list : FastXMLList = nodeElement.node.elements.innerData();
                    rootNode.setExtraData(list);
                }
            }
            else 
            {
                var dataElement : FastXML = nodeElement.nodes.elements("data")[0];
                var data : Dynamic = haxe.Json.parse(dataElement.node.text.innerData());
                
                // Append hint data
                var i : Int;
                var variableHints : Array<Dynamic> = [];
                var variableHintElements : FastXMLList = nodeElement.node.elements.innerData("variableHint");
                for (i in 0...variableHintElements.length()){
                    var variableHintElement : FastXML = variableHintElements.get(i);
                    variableHints.push(
                            {
                                textContent : variableHintElement.nodes.children()[0],
                                termValue : variableHintElement.att.termValue,
                                documentId : variableHintElement.att.documentId,

                            });
                    variableHints.push(
                            );
                    
                }
                Reflect.setField(data, "variableHints", variableHints);
                
                var expressionHints : Array<Dynamic> = [];
                var expressionHintElements : FastXMLList = nodeElement.node.elements.innerData("expressionHint");
                for (i in 0...expressionHintElements.length()){
                    var expressionHintElement : FastXML = expressionHintElements.get(i);
                    expressionHints.push(
                            {
                                textContent : expressionHintElement.nodes.children()[0],
                                expression : expressionHintElement.att.expression,

                            });
                    expressionHints.push(
                            );
                    
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
            for (childElement/* AS3HX WARNING could not determine type for var: childElement exp: ECall(EField(EIdent(nodeElement),elements),[]) type: null */ in nodeElement.nodes.elements())
            {
                var childNode : ScriptNode = createNode(childElement);
                rootNode.pushChild(childNode);
            }
        }
        
        return rootNode;
    }
}
