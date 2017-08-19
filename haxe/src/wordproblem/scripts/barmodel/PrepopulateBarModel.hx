package wordproblem.scripts.barmodel;


import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import starling.display.DisplayObject;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.BarModelTypeDrawer;
import wordproblem.engine.barmodel.BarModelTypeDrawerProperties;
import wordproblem.engine.barmodel.BarModelTypes;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.level.LevelStatistics;
import wordproblem.engine.widget.BarModelAreaWidget;
import wordproblem.engine.widget.TextAreaWidget;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.resource.AssetManager;

/**
 * This script handles pre-populating the bar model area with some predefined
 * answers. This is used for scaffolding purposes, instead of building the entire
 * model from scratch, we give them part of the correct answer.
 * 
 * It is tricky to force the game to say that the starting elements cannot be modified so
 * the user can choose to remove those elements all over again.
 * 
 * However, resetting should show the starting model.
 */
class PrepopulateBarModel extends BaseBarModelScript
{
    /**
     * Mapping from document id to an expression/term value
     * Relies on fact that document ids in a level can be directly mapped to elements in a
     * template of a bar model type. For example the doc id 'b1' refers to the number of
     * groups in any type 3a model.
     * 
     * Same construct as used in the ShowHintOnBarModelMistake script
     */
    private var m_documentIdToExpressionMap : Dynamic;
    
    private var m_playerStatsAndSaveData : PlayerStatsAndSaveData;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            playerStatsAndSaveData : PlayerStatsAndSaveData,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_playerStatsAndSaveData = playerStatsAndSaveData;
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_ready) 
        {
            m_gameEngine.removeEventListener(GameEvent.LEVEL_SOLVED, onLevelSolved);
            if (value) 
            {
                m_gameEngine.addEventListener(GameEvent.LEVEL_SOLVED, onLevelSolved);
            }
        }
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        setIsActive(m_isActive);
        
        m_documentIdToExpressionMap = { };
        
        // Whether or not this script is even used depends on external logic that figures out
        // if user needs more assistance than usual
        var degreeOfCompletion : Int = m_playerStatsAndSaveData.getPartialBarCompletionDegree();
        
        var textAreas : Array<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TextAreaWidget);
        var barModelViews : Array<DisplayObject> = m_gameEngine.getUiEntitiesByClass(BarModelAreaWidget);
        if (textAreas.length > 0 && barModelViews.length > 0 && degreeOfCompletion > 0) 
        {
            // Create a mapping so we know the concrete values that should be fitting into any partially
            // completed bar models.
            var textArea : TextAreaWidget = try cast(textAreas[0], TextAreaWidget) catch(e:Dynamic) null;
            var barModelArea : BarModelAreaWidget = try cast(barModelViews[0], BarModelAreaWidget) catch(e:Dynamic) null;
            var expressionComponents : Array<Component> = textArea.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
            var i : Int = 0;
            var documentIdToExpressionMap : Dynamic = { };
            for (i in 0...expressionComponents.length){
                var expressionComponent : ExpressionComponent = try cast(expressionComponents[i], ExpressionComponent) catch(e:Dynamic) null;
                m_documentIdToExpressionMap[expressionComponent.entityId] = expressionComponent.expressionString;
            }  // Each document id will exactly match some part of the style object    // renders the correct names    // The goal will be to modify the style object so that the draw function    // The text deals with keys 'a1...an', b1...bn', 'c', and 'unk'    // The style object deals with keys 'a', 'b', 'c', and '?'    // Looking for implicit mappings    // We don't know which ones exist until we actually look through the map    // For several types, the a and b should be stripped out and replaced with properties like 'a1' or 'b1'  
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            var barModelType : String = m_gameEngine.getCurrentLevel().getBarModelType();
            var barModelDrawer : BarModelTypeDrawer = new BarModelTypeDrawer();
            var defaultStyleObject : Dynamic = barModelDrawer.getStyleObjectForType(barModelType);
            var docIdToStyleKey : Dynamic = {
                a1 : "a",
                b1 : "b",
                c : "c",
                unk : "?",

            };
            
            // Bar model type 1 and 2 replace 'a' and 'b' drawer styles because problems of those type
            // can have an unbounded number of additional parts with that prefix.
            var stylePropertiesToReplace : Array<String> = new Array<String>();
            if (barModelType == BarModelTypes.TYPE_1A || barModelType == BarModelTypes.TYPE_2A ||
                barModelType == BarModelTypes.TYPE_2B) 
            {
                stylePropertiesToReplace.push("a");
                stylePropertiesToReplace.push("b");
                
            }
            else if (barModelType == BarModelTypes.TYPE_1B || barModelType == BarModelTypes.TYPE_2D ||
                barModelType == BarModelTypes.TYPE_2E) 
            {
                stylePropertiesToReplace.push("a");
            }
            else if (barModelType == BarModelTypes.TYPE_2C) 
            {
                stylePropertiesToReplace.push("b");
            }
            
            for (docId in Reflect.fields(m_documentIdToExpressionMap))
            {
                var expression : String = Reflect.field(m_documentIdToExpressionMap, docId);
                
                // For the terms that can be composed of multiple parts
                // add the part to the style with a copy of the original
                // ex.) 'a1' is added with a new property object matching 'a'
                // This behavior is applicable only for a subset of types
                var matchedWithPrefix : Bool = false;
                for (prefix in stylePropertiesToReplace)
                {
                    if (docId.indexOf(prefix) == 0) 
                    {
                        var originalProperties : BarModelTypeDrawerProperties = Reflect.field(defaultStyleObject, prefix);
                        var copiedProperties : BarModelTypeDrawerProperties = originalProperties.clone();
                        copiedProperties.value = expression;
                        copiedProperties.alias = expression;
                        Reflect.setField(defaultStyleObject, docId, copiedProperties);
                        matchedWithPrefix = true;
                    }
                }  // expressions outlined by the document ids    // Maintain the same bar drawing style keys, just adjust the properties to match the  
                
                
                
                
                
                if (!matchedWithPrefix && docIdToStyleKey.exists(docId)) 
                {
                    var styleKeyAssociatedWithDocId : String = Reflect.field(docIdToStyleKey, docId);
                    var propertiesForElement : BarModelTypeDrawerProperties = Reflect.field(defaultStyleObject, styleKeyAssociatedWithDocId);
                    propertiesForElement.value = expression;
                    propertiesForElement.alias = expression;
                }
            }  // If the prefixes are used, then the original bar drawing style keys need to be removed  
            
            
            
            for (prefix in stylePropertiesToReplace)
            {
                ;
            }
            
            function addIdsMatchingPrefix(prefix : String,
                    styleObject : Dynamic,
                    outIds : Array<String>) : Void
            {
                for (styleId in Reflect.fields(styleObject))
                {
                    if (styleId.indexOf(prefix) == 0) 
                    {
                        outIds.push(styleId);
                    }
                }
            }  // type, we determine which elements should be visible on the draw.    // Using the 'degree' of which the model should be completed along with the bar model    // TODO: Need to define what the degree of completion means  ;
            
            
            
            
            
            
            
            var elementsToHide : Array<String> = new Array<String>();
            switch (barModelType)
            {
                case BarModelTypes.TYPE_1A:
                // Style object for this should reference the expressions that start with 'a' and 'b'
                elementsToHide.push("?");
                case BarModelTypes.TYPE_1B:
                // TODO: Several elements are composed of multiple parts for these types need to gather
                // all the prefix ids
                addIdsMatchingPrefix("b", defaultStyleObject, elementsToHide);
                case BarModelTypes.TYPE_2A:
                    elementsToHide.push("?");
                case BarModelTypes.TYPE_2B:
                    elementsToHide.push("?");
                case BarModelTypes.TYPE_2C:
                    addIdsMatchingPrefix("a", defaultStyleObject, elementsToHide);
                case BarModelTypes.TYPE_2D:
                    addIdsMatchingPrefix("b", defaultStyleObject, elementsToHide);
                case BarModelTypes.TYPE_2E:
                    addIdsMatchingPrefix("b", defaultStyleObject, elementsToHide);
                case BarModelTypes.TYPE_3A:
                    elementsToHide.push("a");
                    elementsToHide.push("?");
                    
                case BarModelTypes.TYPE_3B:
                    elementsToHide.push("?");
                    elementsToHide.push("b");
                    
                case BarModelTypes.TYPE_3C:
                case BarModelTypes.TYPE_4A:
                    elementsToHide.push("?");
                    elementsToHide.push("a");
                    
                case BarModelTypes.TYPE_4B:
                    elementsToHide.push("?");
                    elementsToHide.push("a");
                    
                case BarModelTypes.TYPE_4C:
                    elementsToHide.push("?");
                    elementsToHide.push("a");
                    
                case BarModelTypes.TYPE_4D:
                    elementsToHide.push("?");
                    elementsToHide.push("a");
                    
                case BarModelTypes.TYPE_4E:
                    elementsToHide.push("?");
                    elementsToHide.push("a");
                    
                case BarModelTypes.TYPE_4F:
                    elementsToHide.push("?");
                    elementsToHide.push("a");
                    
                case BarModelTypes.TYPE_4G:
                case BarModelTypes.TYPE_5A:
                    elementsToHide.push("?");
                    elementsToHide.push("b");
                    
                case BarModelTypes.TYPE_5B:
                    elementsToHide.push("?");
                    elementsToHide.push("b");
                    
                case BarModelTypes.TYPE_5C:
                    elementsToHide.push("?");
                    elementsToHide.push("b");
                    
                case BarModelTypes.TYPE_5D:
                    elementsToHide.push("?");
                    elementsToHide.push("b");
                    
                case BarModelTypes.TYPE_5E:
                    elementsToHide.push("?");
                    elementsToHide.push("a");
                    
                case BarModelTypes.TYPE_5F:
                    elementsToHide.push("?");
                    elementsToHide.push("a");
                    
                case BarModelTypes.TYPE_5G:
                    elementsToHide.push("?");
                    elementsToHide.push("a");
                    
                case BarModelTypes.TYPE_5H:
                    elementsToHide.push("?");
                    elementsToHide.push("a");
                    
                case BarModelTypes.TYPE_5I:
                    elementsToHide.push("?");
                    elementsToHide.push("a");
                    
                case BarModelTypes.TYPE_5J:
                    elementsToHide.push("?");
                    elementsToHide.push("a");
                    
                case BarModelTypes.TYPE_5K:
                    elementsToHide.push("?");
                    elementsToHide.push("a");
                    
                case BarModelTypes.TYPE_6A:
                    elementsToHide.push("?");
                    elementsToHide.push("b");
                    
                case BarModelTypes.TYPE_6B:
                    elementsToHide.push("?");
                    elementsToHide.push("b");
                    
                case BarModelTypes.TYPE_6C:
                    elementsToHide.push("?");
                    elementsToHide.push("b");
                    
                case BarModelTypes.TYPE_6D:
                    elementsToHide.push("?");
                    elementsToHide.push("b");
                    
                case BarModelTypes.TYPE_7A:
                    elementsToHide.push("?");
                    elementsToHide.push("b");
                    
                case BarModelTypes.TYPE_7B:
                    elementsToHide.push("?");
                    elementsToHide.push("b");
                    
                case BarModelTypes.TYPE_7C:
                    elementsToHide.push("?");
                    elementsToHide.push("b");
                    
                case BarModelTypes.TYPE_7D_1:
                    elementsToHide.push("?");
                    elementsToHide.push("b");
                    
                case BarModelTypes.TYPE_7D_2:
                    elementsToHide.push("?");
                    elementsToHide.push("b");
                    
                case BarModelTypes.TYPE_7E:
                    elementsToHide.push("?");
                    elementsToHide.push("b");
                    
                case BarModelTypes.TYPE_7F_1:
                    elementsToHide.push("?");
                    elementsToHide.push("b");
                    
                case BarModelTypes.TYPE_7F_2:
                    elementsToHide.push("?");
                    elementsToHide.push("b");
                    
                case BarModelTypes.TYPE_7G:
                    elementsToHide.push("?");
                    elementsToHide.push("b");
                    
            }  // Set the appropriate elements to not visible to hide  
            
            
            
            for (elementToHide in elementsToHide)
            {
                var drawerProperties : BarModelTypeDrawerProperties = Reflect.field(defaultStyleObject, elementToHide);
                drawerProperties.visible = false;
            }  // After styles have been altered, draw the partial style object  
            
            
            
            barModelDrawer.drawBarModelIntoViewFromType(barModelType, barModelArea, defaultStyleObject);
            barModelArea.redraw(false);
        }
    }
    
    private function onLevelSolved() : Void
    {
        // Once a level has been completed we look through the performance metrics and determine whether
        // the player would benefit from having a partially completed bar model
        var performanceStatistics : LevelStatistics = m_gameEngine.getCurrentLevel().statistics;
        var nextCompletionDegree : Int = 0;
        if (performanceStatistics.barModelFails > 8) 
        {
            nextCompletionDegree = 2;
        }
        else if (performanceStatistics.barModelFails > 5) 
        {
            nextCompletionDegree = 1;
        }
        m_playerStatsAndSaveData.setPartialBarCompletionDegree(nextCompletionDegree);
    }
}
