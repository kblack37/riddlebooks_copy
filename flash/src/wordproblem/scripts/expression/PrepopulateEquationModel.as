package wordproblem.scripts.expression
{
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.BarModelTypes;
    import wordproblem.engine.level.LevelRules;
    import wordproblem.engine.level.WordProblemLevelData;
    import wordproblem.engine.widget.TermAreaWidget;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.resource.AssetManager;
    
    public class PrepopulateEquationModel extends BaseTermAreaScript
    {
        public function PrepopulateEquationModel(gameEngine:IGameEngine, 
                                                 expressionCompiler:IExpressionTreeCompiler, 
                                                 assetManager:AssetManager, 
                                                 id:String=null, 
                                                 isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            // TODO: The correct time to add this should be when we first transition to the bar model mode
            
            // When the level starts we need to check if there is some data that is
            // asking for the equation model to be partially or completely
            // filled in (assume that the partial completion is a property of the instance)
            
            // Get the appropriate side of the equation and add the right values to it
            // Also ensure that those parts cannot be removed

            var problemData:WordProblemLevelData = m_gameEngine.getCurrentLevel();
            if (problemData.prepopulateEquationData != null && problemData.prepopulateEquationData.hasOwnProperty("side"))
            {
                var termAreaNameToPopulate:String = "";
                var side:String = problemData.prepopulateEquationData["side"];
                
                // The type of value that can be added is either a number or a variable
                var valueType:String = (problemData.prepopulateEquationData.hasOwnProperty("value")) ?
                    problemData.prepopulateEquationData["value"] : "number";
                if (side == "left")
                {
                    termAreaNameToPopulate = "leftTermArea";
                }
                else if (side == "right")
                {
                    termAreaNameToPopulate = "rightTermArea";
                }
                else
                {
                    termAreaNameToPopulate = (Math.random() > 0.5) ? "leftTermArea" : "rightTermArea";
                }
                
                var termsUsed:Vector.<String> = new Vector.<String>();
                var partialExpression:String = getPartialExpressionFromType(problemData.getBarModelType(), termsUsed, valueType);
                m_gameEngine.setTermAreaContent(termAreaNameToPopulate, partialExpression);
                
                (m_gameEngine.getUiEntity(termAreaNameToPopulate) as TermAreaWidget).isInteractable = false;
                
                // The equation undo and reset buttons shouls return to this initial state
                // This assumes that from the start of the level to when the user actually performs
                // the equation modeling, no other script is altering the reset/undo history
                var undoTermArea:UndoTermArea = getNodeById("UndoTermArea") as UndoTermArea;
                undoTermArea.resetHistory(true);
                
                var resetExpression:Vector.<String> = new Vector.<String>();
                if (side == "left")
                {
                    resetExpression.push(partialExpression, null);
                }
                else
                {
                    resetExpression.push(null, partialExpression);
                }
                var resetTermArea:ResetTermArea = getNodeById("ResetTermArea") as ResetTermArea;
                resetTermArea.setStartingExpressions(resetExpression);
            }
        }
        
        private function getPartialExpressionFromType(barModelType:String, outTermsUsed:Vector.<String>, valueType:String):String
        {
            var textArea:TextAreaWidget = m_gameEngine.getUiEntitiesByClass(TextAreaWidget)[0] as TextAreaWidget;
            var documentIdToExpressionMap:Object = textArea.getDocumentIdToExpressionMap();
            
            var partialExpression:String = null;
            if (barModelType == BarModelTypes.TYPE_0A)
            {
                var docIdToUse:String = (valueType == "variable") ? "unk" : "a1";
                partialExpression = documentIdToExpressionMap[docIdToUse];
                outTermsUsed.push(documentIdToExpressionMap[docIdToUse]);
            }
            else if (barModelType == BarModelTypes.TYPE_1A || barModelType == BarModelTypes.TYPE_2B)
            {
                for (var docId:String in documentIdToExpressionMap)
                {
                    if (valueType == "number")
                    {
                        if (docId.indexOf("a") == 0 || docId.indexOf("b") == 0)
                        {
                            outTermsUsed.push(documentIdToExpressionMap[docId]);
                            
                            if (partialExpression == null)
                            {
                                partialExpression = documentIdToExpressionMap[docId];
                            }
                            else
                            {
                                partialExpression += "+" + documentIdToExpressionMap[docId];
                            }
                        }
                    }
                    else if (valueType == "variable" && docId.indexOf("unk") == 0)
                    {
                        outTermsUsed.push(documentIdToExpressionMap[docId]);
                        partialExpression = documentIdToExpressionMap[docId];
                    }
                }
            }
            else if (barModelType == BarModelTypes.TYPE_2A || barModelType == BarModelTypes.TYPE_1B)
            {
                if (valueType == "number")
                {
                    var largerPartial:String = null;
                    var termsInLarger:int = 0;
                    var smallerPartial:String = null;
                    var termsInSmaller:int = 0;
                    for (docId in documentIdToExpressionMap)
                    {
                        var expressionValue:String = documentIdToExpressionMap[docId];
                        if (docId.indexOf("b") == 0)
                        {
                            termsInLarger++;
                            outTermsUsed.push(expressionValue);
                            
                            if (largerPartial == null)
                            {
                                largerPartial = expressionValue;
                            }
                            else
                            {
                                largerPartial += "+" + expressionValue;
                            }
                        }
                        else if (docId.indexOf("a") == 0)
                        {
                            termsInSmaller++;
                            outTermsUsed.push(expressionValue);
                            
                            if (smallerPartial == null)
                            {
                                smallerPartial = expressionValue;
                            }
                            else
                            {
                                smallerPartial += "+" + expressionValue;
                            }
                        }
                    }
                    
                    if (termsInLarger > 1)
                    {
                        largerPartial = "(" + largerPartial + ")";
                    }
                    
                    if (termsInSmaller > 1)
                    {
                        smallerPartial = "(" + smallerPartial + ")";
                    }
                    
                    partialExpression = largerPartial + "-" + smallerPartial;
                }
                else if (valueType == "variable")
                {
                    outTermsUsed.push(documentIdToExpressionMap["unk"]);
                    partialExpression = documentIdToExpressionMap["unk"];
                }
            }
            return partialExpression;
        }
    }
}