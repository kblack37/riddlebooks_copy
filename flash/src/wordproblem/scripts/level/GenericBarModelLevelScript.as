package wordproblem.scripts.level
{
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.time.Time;
    import dragonbox.common.util.PM_PRNG;
    import dragonbox.common.util.XColor;
    
    import starling.core.Starling;
    import starling.display.DisplayObject;
    
    import wordproblem.callouts.CalloutCreator;
    import wordproblem.characters.HelperCharacterController;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.analysis.BarModelClassifier;
    import wordproblem.engine.barmodel.model.BarComparison;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.SymbolData;
    import wordproblem.engine.level.LevelRules;
    import wordproblem.engine.level.WordProblemLevelData;
    import wordproblem.engine.scripting.graph.ScriptNode;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.scripting.graph.action.CustomVisitNode;
    import wordproblem.engine.scripting.graph.selector.PrioritySelector;
    import wordproblem.engine.scripting.graph.selector.SequenceSelector;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.hints.HintCommonUtil;
    import wordproblem.hints.HintScript;
    import wordproblem.hints.HintSelectorNode;
    import wordproblem.hints.ai.AiPolicyHintSelector;
    import wordproblem.hints.scripts.HelpController;
    import wordproblem.hints.scripts.HighlightHintButtonScript;
    import wordproblem.hints.scripts.ShowTipFromLink;
    import wordproblem.hints.selector.ExpressionModelHintSelector;
    import wordproblem.hints.selector.HighlightTextHintSelector;
    import wordproblem.hints.selector.ShowHintOnBarModelMistake;
    import wordproblem.level.controller.WordProblemCgsLevelManager;
    import wordproblem.player.PlayerStatsAndSaveData;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.barmodel.AddNewBar;
    import wordproblem.scripts.barmodel.AddNewBarComparison;
    import wordproblem.scripts.barmodel.AddNewBarSegment;
    import wordproblem.scripts.barmodel.AddNewHorizontalLabel;
    import wordproblem.scripts.barmodel.AddNewLabelOnSegment;
    import wordproblem.scripts.barmodel.AddNewUnitBar;
    import wordproblem.scripts.barmodel.AddNewVerticalLabel;
    import wordproblem.scripts.barmodel.BarToCard;
    import wordproblem.scripts.barmodel.CardOnSegmentEdgeRadialOptions;
    import wordproblem.scripts.barmodel.CardOnSegmentRadialOptions;
    import wordproblem.scripts.barmodel.HoldToCopy;
    import wordproblem.scripts.barmodel.IRemoveBarElement;
    import wordproblem.scripts.barmodel.MultiplyBarSegments;
    import wordproblem.scripts.barmodel.RemoveBarComparison;
    import wordproblem.scripts.barmodel.RemoveBarSegment;
    import wordproblem.scripts.barmodel.RemoveHorizontalLabel;
    import wordproblem.scripts.barmodel.RemoveLabelOnSegment;
    import wordproblem.scripts.barmodel.RemoveVerticalLabel;
    import wordproblem.scripts.barmodel.ResetBarModelArea;
    import wordproblem.scripts.barmodel.ResizeBarComparison;
    import wordproblem.scripts.barmodel.ResizeHorizontalBarLabel;
    import wordproblem.scripts.barmodel.ResizeVerticalBarLabel;
    import wordproblem.scripts.barmodel.RestrictCardsInBarModel;
    import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
    import wordproblem.scripts.barmodel.SplitBarSegment;
    import wordproblem.scripts.barmodel.SwitchBetweenBarAndEquationModel;
    import wordproblem.scripts.barmodel.UndoBarModelArea;
    import wordproblem.scripts.barmodel.ValidateBarModelArea;
    import wordproblem.scripts.deck.DeckCallout;
    import wordproblem.scripts.deck.DeckController;
    import wordproblem.scripts.deck.DiscoverTerm;
    import wordproblem.scripts.deck.EnterNewCard;
    import wordproblem.scripts.equationtotext.EquationToText;
    import wordproblem.scripts.expression.AddAndChangeParenthesis;
    import wordproblem.scripts.expression.AddTerm;
    import wordproblem.scripts.expression.PrepopulateEquationModel;
    import wordproblem.scripts.expression.PressToChangeOperator;
    import wordproblem.scripts.expression.RemoveTerm;
    import wordproblem.scripts.expression.ResetTermArea;
    import wordproblem.scripts.expression.UndoTermArea;
    import wordproblem.scripts.expression.systems.SaveEquationInSystem;
    import wordproblem.scripts.layering.DisableInLayer;
    import wordproblem.scripts.level.util.ChangeTextStyleAndSelectabilityControl;
    import wordproblem.scripts.model.ModelSpecificEquation;
    import wordproblem.scripts.text.DragText;
    import wordproblem.scripts.text.HighlightTextForCard;
    import wordproblem.scripts.text.TextToCard;
    import wordproblem.scripts.ui.ShiftResetAndUndoButtons;
    
    /**
     * This script represents a generic level for the bar modeling mechanic
     */
    public class GenericBarModelLevelScript extends BaseCustomLevelScript
    {
        /**
         * External time tick that can be shared amongst several level scripts
         */
        private var m_time:Time;
        
        /**
         * List of the usuable values that go in the deck.
         * (Since we no longer force the player to find all the pieces first, this is not useful)
         */
        private var m_deckValues:Vector.<String>;
        private var m_documentIds:Vector.<String>;
        private var m_documentIdCardValues:Vector.<String>;
        
        /**
         * When the player creates a bar segment from a non-numeric piece it still needs to
         * map to some unit value so the segment gets the appropriate size.
         * 
         * This maps from the value of the piece to the unit ratio all segments created from that
         * piece value.
         */
        private var m_termValueToBarValue:Object;
        
        /**
         * When using the 'new unit bar' action when the player initially drops a number,
         * an equal number of segments needs to be created. Each segment needs some unit
         * value to define how wide it is visually.
         */
        private var m_defaultUnitValue:Number;
        
        private var m_referenceModels:Vector.<BarModelData>;
        
        /**
         * If the xml does not assign an id to each equation, we auto assign an id
         * with a 1 based index dependent on the order it appears.
         */
        private var m_equationIdCounter:int = 1;
        
        /**
         * Mapping from id to an equation string. This is data pulled from the raw xml
         */
        private var m_idToDecompiledEquation:Object;
        
        /**
         * In order to complete a level of this type, the player needs to complete all of the
         * equations contained in a set. Each element is a list of equation ids.
         */
        private var m_equationIdSets:Vector.<Vector.<String>>;
        
        /**
         * This script handles validating all target bar models
         */
        protected var m_validateBarModelAreaScript:ValidateBarModelArea;
        
        /**
         * This normalizing factor means that a card with this same value equals 100 pixels in width,
         * scales up and down proportionately.
         */
        private var m_barNormalizingFactor:Number;
        
        /**
         * This script has state that keeps track of whether the user is in the bar model or equation modeling mode.
         */
        protected var m_switchModelScript:SwitchBetweenBarAndEquationModel;
        
        /**
         * Script handles shifting down the undo and reset buttons to the expression area
         */
        protected var m_shiftResetAndUndo:ShiftResetAndUndoButtons;
        
        /**
         * If level has them, this is the block of data for custom hints.
         * The HintXMLStorage class is what does the parsing of it
         */
        private var m_customHintsXMLBlock:XML;
        
        /*
         * Needed to get KOfNProficient for ai hint system
         */
        private var m_levelManager:WordProblemCgsLevelManager;
        
        public function GenericBarModelLevelScript(gameEngine:IGameEngine, 
                                                   expressionCompiler:IExpressionTreeCompiler, 
                                                   assetManager:AssetManager,
                                                   playerStatsAndSaveData:PlayerStatsAndSaveData,
                                                   levelManager:WordProblemCgsLevelManager,
                                                   id:String=null, 
                                                   isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, playerStatsAndSaveData, id, isActive);
            
            m_time = new Time();
            
            // Add testing scripts
            var deckGestures:PrioritySelector = new PrioritySelector("DeckGestures");
            deckGestures.pushChild(new DeckController(m_gameEngine, m_expressionCompiler, m_assetManager, "DeckController"));
            super.pushChild(deckGestures);
            super.pushChild(new DeckCallout(m_gameEngine, m_expressionCompiler, m_assetManager));
            
            m_switchModelScript = new SwitchBetweenBarAndEquationModel(gameEngine, expressionCompiler, assetManager, onSwitchModelClicked, "SwitchBetweenBarAndEquationModel");
            super.pushChild(m_switchModelScript);
            
            m_shiftResetAndUndo = new ShiftResetAndUndoButtons(gameEngine, expressionCompiler, assetManager);
            
            super.pushChild(new DragText(gameEngine, expressionCompiler, assetManager, "DragText"));
            super.pushChild(new TextToCard(gameEngine, expressionCompiler, assetManager, "TextToCard"));
            super.pushChild(new ResetBarModelArea(gameEngine, expressionCompiler, assetManager, "ResetBarModelArea"));
            super.pushChild(new UndoBarModelArea(gameEngine, expressionCompiler, assetManager, "UndoBarModelArea"));
            
            super.pushChild(new RestrictCardsInBarModel(gameEngine, expressionCompiler, assetManager, "RestrictCardsInBarModel"));
            super.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, false, "BarToCard", false));
            
            super.pushChild(new UndoTermArea(gameEngine, expressionCompiler, assetManager, "UndoTermArea", false));
            super.pushChild(new ResetTermArea(gameEngine, expressionCompiler, assetManager, "ResetTermArea", false));
            super.pushChild(new EquationToText(m_gameEngine, m_expressionCompiler, m_assetManager));
            
            // Resize gestures
            var modifyExistingBarGestures:PrioritySelector = new PrioritySelector("ModifyExistingBarGestures");
            modifyExistingBarGestures.pushChild(new ResizeHorizontalBarLabel(gameEngine, expressionCompiler, assetManager, "ResizeHorizontalBarLabel"));
            modifyExistingBarGestures.pushChild(new ResizeVerticalBarLabel(gameEngine, expressionCompiler, assetManager, "ResizeVerticalBarLabel"));
            modifyExistingBarGestures.pushChild(new ResizeBarComparison(gameEngine, expressionCompiler, assetManager, "ResizeBarComparison"));
            
            // Remember this has an implicit dependency on removing elements since they both interact with the exact same parts
            var holdToCopy:HoldToCopy = new HoldToCopy(
                gameEngine, 
                expressionCompiler, 
                assetManager, 
                m_time, 
                assetManager.getBitmapData("glow_yellow"),
                "HoldToCopy");
            modifyExistingBarGestures.pushChild(holdToCopy);
            
            // Remove gestures are a child of the hold to copy script
            var removeBarModelPartsScripts:Vector.<IRemoveBarElement> = Vector.<IRemoveBarElement>([
                new RemoveBarSegment(m_gameEngine, m_expressionCompiler, m_assetManager),
                new RemoveHorizontalLabel(m_gameEngine, m_expressionCompiler, m_assetManager),
                new RemoveVerticalLabel(m_gameEngine, m_expressionCompiler, m_assetManager),
                new RemoveLabelOnSegment(m_gameEngine, m_expressionCompiler, m_assetManager),
                new RemoveBarComparison(m_gameEngine, m_expressionCompiler, m_assetManager)
            ]);
            for each (var removeScript:IRemoveBarElement in removeBarModelPartsScripts)
            {
                holdToCopy.addRemoveScript(removeScript);
            }
            
            super.pushChild(modifyExistingBarGestures);
            
            // Drag gestures
            var maxBarWholesAllowed:int = 5;
            var orderedGestures:PrioritySelector = new PrioritySelector("BarModelDragGestures");
            super.pushChild(orderedGestures);
            orderedGestures.pushChild(new CardOnSegmentEdgeRadialOptions(gameEngine, expressionCompiler, assetManager, "CardOnSegmentEdgeRadialOptions"));
            orderedGestures.pushChild(new CardOnSegmentRadialOptions(gameEngine, expressionCompiler, assetManager, "CardOnSegmentRadialOptions"));
            orderedGestures.pushChild(new AddNewHorizontalLabel(gameEngine, expressionCompiler, assetManager, -1, "AddNewHorizontalLabel"));
            orderedGestures.pushChild(new AddNewVerticalLabel(gameEngine, expressionCompiler, assetManager, -1, "AddNewVerticalLabel"));
            orderedGestures.pushChild(new AddNewUnitBar(gameEngine, expressionCompiler, assetManager, maxBarWholesAllowed, "AddNewUnitBar"));
            orderedGestures.pushChild(new MultiplyBarSegments(gameEngine, expressionCompiler, assetManager, maxBarWholesAllowed, "MultiplyBarSegments"));
            orderedGestures.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, maxBarWholesAllowed, "AddNewBar"));
            orderedGestures.pushChild(new ShowBarModelHitAreas(m_gameEngine, m_expressionCompiler, m_assetManager, "CardOnSegmentEdgeRadialOptions"));
            orderedGestures.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewHorizontalLabel"));
            orderedGestures.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewVerticalLabel"));
            orderedGestures.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "MultiplyBarSegments"));
            orderedGestures.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewUnitBar"));
            orderedGestures.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBar"));
            
            // Add logic to only accept the model of a particular equation
            super.pushChild(new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation", false));
            // Add logic to handle adding new cards (only active after all cards discovered)
            super.pushChild(new AddTerm(gameEngine, expressionCompiler, assetManager, "AddTerm"));
            // Other scripts to get the game to function
            super.pushChild(new DiscoverTerm(m_gameEngine, m_assetManager, "DiscoverTerm"));
            super.pushChild(new HighlightTextForCard(m_gameEngine, m_assetManager));
            
            // Extra script that saves just ONE additional equation in a buffer for simple systems
            super.pushChild(new SaveEquationInSystem(m_gameEngine, expressionCompiler, m_assetManager));
            
            // Extra script to partially complete a goal equation (some versions should not have this)
            super.pushChild(new PrepopulateEquationModel(m_gameEngine, expressionCompiler, m_assetManager));
            
            super.pushChild(new ShowTipFromLink(m_gameEngine, expressionCompiler, m_assetManager));
            
            var termAreaPrioritySelector:PrioritySelector = new PrioritySelector("TermAreaScripts");
            super.pushChild(termAreaPrioritySelector);
            termAreaPrioritySelector.pushChild(new AddAndChangeParenthesis(gameEngine, expressionCompiler, assetManager, "AddAndChangeParenthesis", false));
            termAreaPrioritySelector.pushChild(new PressToChangeOperator(m_gameEngine, m_expressionCompiler, m_assetManager));
            termAreaPrioritySelector.pushChild(new RemoveTerm(m_gameEngine, m_expressionCompiler, m_assetManager, "RemoveTerm"));
            
            m_deckValues = new Vector.<String>();
            m_documentIds = new Vector.<String>();
            m_documentIdCardValues = new Vector.<String>();
            m_termValueToBarValue = {};
            m_barNormalizingFactor = 1.0;
            m_defaultUnitValue = -1;
            m_referenceModels = new Vector.<BarModelData>();
            m_levelManager = levelManager;
            
            m_validateBarModelAreaScript = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea");
            m_idToDecompiledEquation = {};
            m_equationIdSets = new Vector.<Vector.<String>>();
            super.pushChild(m_validateBarModelAreaScript);
        }
        
        override public function getNumCopilotProblems():int
        {
            // The two problems are doing one bar model and doing one equation model
            return 2;
        }
        
        override public function visit():int
        {
            m_time.update();
            return super.visit();
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
        }
        
        override public function setExtraData(data:Object):void
        {
            // For this intro script the extra data we input are the pages for the dynamic dialog
            var extraXMLList:XMLList = data as XMLList;
            var numElements:int = extraXMLList.length();
            
            var i:int; var j:int; var k:int; var m:int;
            var elementXML:XML;
            for (i = 0; i < numElements; i++)
            {
                elementXML = extraXMLList[i];
                if (elementXML.name() == "deck")
                {
                    var deckValue:String = elementXML.@value;
                    m_deckValues.push(deckValue);
                }
                else if (elementXML.name() == "documentToCard")
                {
                    var documentId:String = elementXML.@documentId;
                    m_documentIds.push(documentId);
                    var documentIdCardValue:String = elementXML.@value;
                    m_documentIdCardValues.push(documentIdCardValue);
                }
                else if (elementXML.name() == "barNormalizingFactor")
                {
                    m_barNormalizingFactor = parseFloat(elementXML.@value);
                }
                else if (elementXML.name() == "referenceModel")
                {
                    var referenceModel:BarModelData = new BarModelData();
                    var referenceModelElements:XMLList = elementXML.children();
                    for(j = 0; j < referenceModelElements.length(); j++) 
                    {
                        var newBarLabel:BarLabel;
                        var referenceModelElement:XML = referenceModelElements[j];
                        if (referenceModelElement.name() == "barWhole") 
                        {
                            var barWholeElements:XMLList = referenceModelElement.children();
                            var barWholeId:String = (referenceModelElement.hasOwnProperty("@id")) ? referenceModelElement.@id : null;
                            var barWhole:BarWhole = new BarWhole(true, barWholeId);
                            for(k = 0; k < barWholeElements.length(); k++) 
                            {
                                var barWholeElement:XML = barWholeElements[k];
                                if (barWholeElement.name() == "barSegment") 
                                {
                                    var numSegments:int = 1;
                                    if (barWholeElement.hasOwnProperty("@repeat")) 
                                    {
                                        numSegments = barWholeElement.@repeat;                                        
                                    }
                                    
                                    for (m = 0; m < numSegments; m++) 
                                    {
                                        var barSegmentValue:Number = (barWholeElement.hasOwnProperty("@value")) ? parseFloat(barWholeElement.@value) : 1;
                                        var newBarSegment:BarSegment = new BarSegment(barSegmentValue, m_barNormalizingFactor, 0xFFFFFFFF, null);
                                        barWhole.barSegments.push(newBarSegment); 
                                        if (barWholeElement.hasOwnProperty("@label")) 
                                        {
                                            var barSegmentIndex:int = barWhole.barSegments.length - 1;
                                            newBarLabel = new BarLabel(barWholeElement.@label, barSegmentIndex, barSegmentIndex, true, false, BarLabel.BRACKET_NONE, null);
                                            barWhole.barLabels.push(newBarLabel);                                        
                                        }
                                    }
                                }
                                else if (barWholeElement.name() == "bracket") 
                                {
                                    newBarLabel = new BarLabel(barWholeElement.@value, 
                                        int(barWholeElement.@start), int(barWholeElement.@end), true, false, BarLabel.BRACKET_STRAIGHT, null);
                                    barWhole.barLabels.unshift(newBarLabel);
                                }
                                else if (barWholeElement.name() == "barCompare") 
                                {
                                    var newBarComp:BarComparison = new BarComparison(barWholeElement.@value, barWholeElement.@compTo, 0);
                                    barWhole.barComparison = newBarComp;
                                }
                            }
                            referenceModel.barWholes.push(barWhole);
                        }
                        else if (referenceModelElement.name() == "verticalBracket") 
                        {
                            newBarLabel = new BarLabel(referenceModelElement.@value, 
                                int(referenceModelElement.@start), int(referenceModelElement.@end), false, false, BarLabel.BRACKET_STRAIGHT, null);
                            referenceModel.verticalBarLabels.push(newBarLabel);                                    
                        }
                    }
                    m_referenceModels.push(referenceModel);
                    
                    // Default, any bar comparisons in a reference will need to point to the end of the bar
                    var barWholesInReference:Vector.<BarWhole> = referenceModel.barWholes;
                    for (j = 0; j < barWholesInReference.length; j++)
                    {
                        barWhole = barWholesInReference[j];
                        if (barWhole.barComparison != null)
                        {
                            newBarComp = barWhole.barComparison;
                            var barWholeToCompare:BarWhole = referenceModel.getBarWholeById(newBarComp.barWholeIdComparedTo);
                            if (barWholeToCompare)
                            {
                                newBarComp.segmentIndexComparedTo = barWholeToCompare.barSegments.length - 1;
                            }
                            
                        }
                    }
                }
                else if (elementXML.name() == "equation") 
                {
                    var equationId:String = (elementXML.hasOwnProperty("@id")) ?
                        elementXML.@id : m_equationIdCounter + "";
                    var equationValue:String = elementXML.@value;
                    m_idToDecompiledEquation[equationId] = equationValue;
                    m_equationIdCounter++;
                }
                else if (elementXML.name() == "equationSet") 
                {
                    var eqsXMLList:XMLList = elementXML.children();
                    var equationIdSet:Vector.<String> = new Vector.<String>();
                    for(j = 0; j < eqsXMLList.length(); j++) 
                    {
                        if (eqsXMLList[j].name() == "equation") 
                        {  
                            equationId = eqsXMLList[j].@id;
                            equationIdSet.push(equationId);
                        }
                    }
                    m_equationIdSets.push(equationIdSet);
                }
                else if (elementXML.name() == "termValueToBarValue")
                {
                    var termValue:String = elementXML.@termValue;
                    var barValue:Number = parseFloat(elementXML.@barValue);
                    m_termValueToBarValue[termValue] = barValue;
                }
                else if (elementXML.name() == "defaultUnitValue")
                {
                    var unitValue:String = elementXML.@unitValue;
                    m_defaultUnitValue = parseFloat(unitValue);
                }
                else if (elementXML.name() == "customHints")
                {
                    // The hint storage is responsible for parsing xml, we just save a copy
                    m_customHintsXMLBlock = elementXML.copy();
                }
            }
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            // Map custom card rendering data to terms
            var currentLevel:WordProblemLevelData = m_gameEngine.getCurrentLevel();
            var symbolBindings:Vector.<SymbolData> = currentLevel.getSymbolsData();
            m_gameEngine.getExpressionSymbolResources().bindSymbolsToAtlas(symbolBindings);
            
            // Have fixed colors for bars in a problem. We can do this by using the problem id as a seed to
            // randomly pick the colors
            var levelId:int = currentLevel.getId();
            var colorPicker:PM_PRNG = new PM_PRNG(levelId);
            var barColors:Vector.<uint> = XColor.getCandidateColorsForSession();
            for each (var cardValue:String in m_documentIdCardValues)
            {
                var dataForCard:SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(cardValue);
                if (!dataForCard.useCustomBarColor)
                {
                    // To make sure colors look distinct, we pick from a list of predefined list and avoid duplicates
                    if (barColors.length > 0)
                    {
                        var colorIndex:int = colorPicker.nextIntRange(0, barColors.length - 1);
                        dataForCard.customBarColor = barColors[colorIndex];
                        barColors.splice(colorIndex, 1);
                    }
                    else
                    {
                        // In the unlikely case we have too many terms that use up all the colors, we just randomly
                        // pick one from a palette.
                        dataForCard.customBarColor = XColor.getDistributedHsvColor(colorPicker.nextDouble());
                    }
                    dataForCard.useCustomBarColor = true;
                }
            }
            
            // Apply the custom colors to the reference models
            for each (var referenceModel:BarModelData in m_referenceModels)
            {
                var segmentValueToColorMap:Object = {};
                for each (var barWhole:BarWhole in referenceModel.barWholes)
                {
                    // Equal sized boxes may not have a single label on them to define their color, like the fraction problem
                    // The color to use is that of the number of equal boxes
                    var segmentValueToOccurencesMap:Object = {};
                    for each (var barSegment:BarSegment in barWhole.barSegments)
                    {
                        var segmentValue:String = barSegment.getValue().toString();
                        if (segmentValueToOccurencesMap.hasOwnProperty(segmentValue))
                        {
                            segmentValueToOccurencesMap[segmentValue]++;
                        }
                        else
                        {
                            segmentValueToOccurencesMap[segmentValue] = 1;
                        }
                    }
                    
                    for (segmentValue in segmentValueToOccurencesMap)
                    {
                        var numOccurrencesForValue:int = segmentValueToOccurencesMap[segmentValue];
                        if (numOccurrencesForValue > 1)
                        {
                            dataForCard = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(numOccurrencesForValue.toString());
                            if (dataForCard.useCustomBarColor)
                            {
                                segmentValueToColorMap[segmentValue] = dataForCard.customBarColor;
                            }
                        }
                    }
                    
                    for each (var barLabel:BarLabel in barWhole.barLabels)
                    {
                        dataForCard = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(barLabel.value);
                        if (dataForCard.useCustomBarColor && barLabel.bracketStyle == BarLabel.BRACKET_NONE)
                        {
                            var targetSegment:BarSegment = barWhole.barSegments[barLabel.startSegmentIndex];
                            segmentValueToColorMap[targetSegment.getValue().toString()] = dataForCard.customBarColor;
                        }
                    }
                    
                    // Apply the appropriate colors to the segments in the reference model
                    for each (barSegment in barWhole.barSegments)
                    {
                        segmentValue = barSegment.getValue().toString();
                        if (segmentValueToColorMap.hasOwnProperty(segmentValue))
                        {
                            barSegment.color = segmentValueToColorMap[segmentValue];
                        }
                    }
                    
                }
            }
            
            // Add hints that would be applicable to every possible bar model level
            var helperCharacterController:HelperCharacterController = new HelperCharacterController(
                m_gameEngine.getCharacterComponentManager(),
                new CalloutCreator(m_textParser, m_textViewFactory));
            
            var helpController:HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager);
            super.pushChild(helpController);
            helpController.overrideLevelReady();

            var highlightHintButton:HighlightHintButtonScript = new HighlightHintButtonScript(m_gameEngine, m_expressionCompiler, m_assetManager, helpController, m_time);
            super.pushChild(highlightHintButton);
            highlightHintButton.overrideLevelReady();
            
            var hintSelector:HintSelectorNode = new HintSelectorNode();
            hintSelector.setCustomGetHintFunction(function():HintScript
            {
                var hint:HintScript = highlighTextHintSelect.getHint();
                //trace(classifier.getClassification(model));
                
                if (hint == null)
                {
                    if (HintCommonUtil.getLevelStillNeedsBarModelToSolve(m_gameEngine))
                    {
                        hint = showHintOnBarModelMistake.getHint();
                    }
                    else
                    {
                        hint = expressionModelHint.getHint();
                    }
                }
				
				if (m_playerStatsAndSaveData.useAiHints && HintCommonUtil.getLevelStillNeedsBarModelToSolve(m_gameEngine) && policySelector != null) 
				{
                    var aiHint:HintScript = policySelector.getHintUsingOld(hint);
					if (aiHint != null)
						hint = aiHint
				}
                
                return hint;
            }, null);
            
            var highlighTextHintSelect:HighlightTextHintSelector = new HighlightTextHintSelector(m_gameEngine, 
                m_assetManager,
                m_validateBarModelAreaScript, helperCharacterController, m_textParser, m_textViewFactory
            );
            hintSelector.addChild(highlighTextHintSelect);
            
            // Hints about constructing the equation
            var modelSpecificEquationScript:ModelSpecificEquation = this.getNodeById("ModelSpecificEquation") as ModelSpecificEquation;
            var expressionModelHint:ExpressionModelHintSelector = new ExpressionModelHintSelector(m_gameEngine, m_assetManager, helperCharacterController, m_expressionCompiler, modelSpecificEquationScript,
                200, 350
            );
            hintSelector.addChild(expressionModelHint);
            
            // Read in the user configuration of whether custom hints should be used
            var customHintsXML:XML = (m_playerStatsAndSaveData.useCustomHints) ? m_customHintsXMLBlock : null;
			
			var barModelType:String =  m_gameEngine.getCurrentLevel().getBarModelType();
			
            // If the bar model portion has not been solved yet
            var showHintOnBarModelMistake:ShowHintOnBarModelMistake = new ShowHintOnBarModelMistake(
                m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_validateBarModelAreaScript, 
                helperCharacterController, m_textParser, m_textViewFactory, barModelType, customHintsXML);
            hintSelector.addChild(showHintOnBarModelMistake);
			
            if(m_playerStatsAndSaveData.useAiHints &&  BarModelClassifier.isValidLevelType(barModelType)) {
                var policySelector:AiPolicyHintSelector = new AiPolicyHintSelector(m_gameEngine, m_validateBarModelAreaScript, 
                barModelType, m_gameEngine.getCurrentLevel().getId(), m_helperCharacterController, 
                m_textViewFactory, m_assetManager, m_textParser, m_levelManager, m_playerStatsAndSaveData);
                hintSelector.addChild(policySelector);
            }
            
            helpController.setRootHintSelectorNode(hintSelector);
            
            // Set up the target equations and equation sets needed to be solved
            if (modelSpecificEquationScript != null)
            {
                for (var equationId:String in m_idToDecompiledEquation)
                {
                    var equationString:String = m_idToDecompiledEquation[equationId];
                    modelSpecificEquationScript.addEquation(equationId, equationString, false);
                }
                
                // By default if no equation set is specified, every defined equation goes into
                // one large set (i.e. player needs to solve all of the defined equations
                if (m_equationIdSets.length == 0)
                {
                    var defaultEquationIdSet:Vector.<String> = new Vector.<String>();
                    for (equationId in m_idToDecompiledEquation)
                    {
                        defaultEquationIdSet.push(equationId);
                    }
                    m_equationIdSets.push(defaultEquationIdSet);
                }
                
                // Specify the valid equation sets the player needs to model to finish this level
                var numEquationSets:int = m_equationIdSets.length;
                for (i = 0; i < numEquationSets; i++)
                {
                    modelSpecificEquationScript.addEquationSet(m_equationIdSets[i]);
                }
            }
            
            // Map parts of text to terms
            var i:int;
            for (i = 0; i < m_documentIds.length; i++)
            {
                m_gameEngine.addTermToDocument(m_documentIdCardValues[i], m_documentIds[i]);
            }
            
            var barModelWidget:BarModelAreaWidget = m_gameEngine.getUiEntity("barModelArea") as BarModelAreaWidget;
            barModelWidget.normalizingFactor = m_barNormalizingFactor;
            
            // Set up the target bar models and use those to determine the proper unit length
            // By default we pick the biggest one
            m_validateBarModelAreaScript.setReferenceModels(m_referenceModels);
            
            var maxUnitLength:Number = 0;
            for (i = 0; i < m_referenceModels.length; i++)
            {
                var desiredUnitLength:Number = barModelWidget.getUnitValueFromBarModelData(m_referenceModels[i], barModelWidget.getConstraints().width * 0.15);
                if (desiredUnitLength > maxUnitLength)
                {
                    maxUnitLength = desiredUnitLength;
                }
            }
            
            if (maxUnitLength > 0)
            {
                barModelWidget.unitLength = maxUnitLength;
            }
            barModelWidget.alwaysAutoCalculateUnitLength = true;
            
            // After level initialization, we add special script to block logic in the bar model press event from
            // executing if they are in a disabled layer (for example another screen is on top of it)
            var disableInLayer:DisableInLayer = new DisableInLayer(barModelWidget, m_gameEngine, m_expressionCompiler, m_assetManager);
            disableInLayer.overrideLevelReady();
            this.getNodeById("ModifyExistingBarGestures").pushChild(disableInLayer, 0);
            
            // Modeling the actual equation ends the game
            m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
            
            currentLevel.termValueToBarModelValue = m_termValueToBarValue;
            currentLevel.defaultUnitValue = m_defaultUnitValue;
            
            // Don't allow switching at the start
            m_switchModelScript.setIsActive(false);
            
            // Hide the parenthesis button
            m_gameEngine.getUiEntity("parenthesisButton").visible = false;
            
            // Go through level rules and disable the appropriate gestures
            var levelRules:LevelRules = currentLevel.getLevelRules();
            
            var addNewLabelOnSegment:AddNewLabelOnSegment = new AddNewLabelOnSegment(m_gameEngine, m_expressionCompiler, m_assetManager);
            if (levelRules.allowSplitBar)
            {
                // Override needs to be called after the nodes are added to the graph since some of the ready function trace up the
                // parent pointers to find other script nodes.
                var splitBarSegment:SplitBarSegment = new SplitBarSegment(m_gameEngine, m_expressionCompiler, m_assetManager, "SplitBarSegment");
                (getNodeById("CardOnSegmentRadialOptions") as CardOnSegmentRadialOptions).addGesture(addNewLabelOnSegment);
                (getNodeById("CardOnSegmentRadialOptions") as CardOnSegmentRadialOptions).addGesture(splitBarSegment);
                splitBarSegment.overrideLevelReady();
            }
            else
            {
                // Currently if there is no splitting then there is no need for the radial menu
                // Just add the label script directly
                this.getNodeById("BarModelDragGestures").pushChild(addNewLabelOnSegment, 1);
            }
            addNewLabelOnSegment.overrideLevelReady();
            
            this.getNodeById("ResizeHorizontalBarLabel").setIsActive(levelRules.allowResizeBrackets);
            this.getNodeById("ResizeVerticalBarLabel").setIsActive(levelRules.allowResizeBrackets);
            this.getNodeById("ResizeBarComparison").setIsActive(levelRules.allowResizeBrackets);
            
            // Disable the portion of the hold to copy script that performs the actual copy.
            // The removal scripts it uses in addition to the behavior of picking up the deleted element
            // should still work
            var holdToCopyScript:HoldToCopy = getNodeById("HoldToCopy") as HoldToCopy;
            holdToCopyScript.allowCopy = levelRules.allowCopyBar;
            
            if (levelRules.allowAddNewSegments)
            {
                var addNewBarSegment:AddNewBarSegment = new AddNewBarSegment(m_gameEngine, m_expressionCompiler, m_assetManager, "AddNewBarSegment");
                (getNodeById("CardOnSegmentEdgeRadialOptions") as CardOnSegmentEdgeRadialOptions).addGesture(addNewBarSegment);
                addNewBarSegment.overrideLevelReady();
            }
            
            if (levelRules.allowAddBarComparison)
            {
                var addNewBarComparison:AddNewBarComparison = new AddNewBarComparison(m_gameEngine, m_expressionCompiler, m_assetManager, "AddNewBarComparison");
                (getNodeById("CardOnSegmentEdgeRadialOptions") as CardOnSegmentEdgeRadialOptions).addGesture(addNewBarComparison);
                addNewBarComparison.overrideLevelReady();
            }
            
            this.getNodeById("AddNewHorizontalLabel").setIsActive(levelRules.allowAddHorizontalLabels);
            this.getNodeById("AddNewVerticalLabel").setIsActive(levelRules.allowAddVerticalLabels);
            this.getNodeById("AddNewUnitBar").setIsActive(levelRules.allowAddUnitBar);
            this.getNodeById("MultiplyBarSegments").setIsActive(levelRules.allowAddUnitBar);
            
            // Modify the allowed number of rows after the level rules have been determined
            (this.getNodeById("AddNewBar") as AddNewBar).setMaxBarsAllowed(levelRules.maxBarRowsAllowed);
            (this.getNodeById("AddNewUnitBar") as AddNewUnitBar).setMaxBarsAllowed(levelRules.maxBarRowsAllowed);
            
            this.getNodeById("RestrictCardsInBarModel").setIsActive(levelRules.restrictCardsInBarModel);
            
            var changeTextSelectability:ChangeTextStyleAndSelectabilityControl = new ChangeTextStyleAndSelectabilityControl(m_gameEngine);
            changeTextSelectability.setOnlyClassNameAsSelectable();
            
            // Keep the ui part down until the first click (allows user to see more of the background as
            // an added benefit.
            var uiContainer:DisplayObject = m_gameEngine.getUiEntity("deckAndTermContainer");
            var startingUiContainerY:Number = uiContainer.y;
            m_switchModelScript.setContainerOriginalY(startingUiContainerY);
            uiContainer.y = 600;
            var otherSequence:SequenceSelector = new SequenceSelector();
            
            // Color for click to continue should match that of the paragraph
            var textStyle:Object = currentLevel.getCssStyleObject();
            var clickToContinueColor:uint = 0;
            if (textStyle != null && textStyle.hasOwnProperty("p"))
            {
                var paragraphStyle:Object = textStyle["p"];
                if (paragraphStyle.hasOwnProperty("color"))
                {
                    clickToContinueColor = paragraphStyle["color"];
                }
            }
            otherSequence.pushChild(new CustomVisitNode(clickToContinue, {x: 300, y: 300, color: clickToContinueColor}));
            otherSequence.pushChild(new CustomVisitNode(function(param:Object):int
            {
                Starling.juggler.tween(uiContainer, 0.3, {y: startingUiContainerY});
                deleteChild(otherSequence);
                return ScriptStatus.SUCCESS;
            }, {}));
            this.pushChild(otherSequence);
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == GameEvent.BAR_MODEL_CORRECT)
            {
                defaultDisableBarModel(function():void
                {
                    getNodeById("RestrictCardsInBarModel").setIsActive(false);
                    getNodeById("ModelSpecificEquation").setIsActive(true);
                    m_switchModelScript.onSwitchModelClicked();
                    m_shiftResetAndUndo.shift();
                });
            }
            else if (eventType == GameEvent.EQUATION_MODEL_SUCCESS)
            {
                // On equation model need to check that all equations in a valid set are
                // completed, if it is then immediately
                var modelSpecificEquationScript:ModelSpecificEquation = this.getNodeById("ModelSpecificEquation") as ModelSpecificEquation;
                if (modelSpecificEquationScript.getAtLeastOneSetComplete())
                {
                    // Disable all scripts that make changes to the equation area
                    this.getNodeById("AddTerm").setIsActive(false);
                    this.getNodeById("TermAreaScripts").setIsActive(false);
                    this.getNodeById("UndoTermArea").setIsActive(false);
                    this.getNodeById("ResetTermArea").setIsActive(false);
                    this.getNodeById("BarToCard").setIsActive(false);
                    
                    m_gameEngine.dispatchEventWith(GameEvent.LEVEL_SOLVED);
                    
                    // Wait for some short time before marking the level as totally complete
                    Starling.juggler.delayCall(function():void
                    {
                        m_gameEngine.dispatchEventWith(GameEvent.LEVEL_COMPLETE);
                    },
                        1.0
                    );
                }
            }
        }
        
        protected function defaultDisableBarModel(delayFunction:Function):void
        {
            // Deactivate delete button
            var copyScript:ScriptNode = this.getNodeById("BarModelModalCopy");
            if (copyScript != null)
            {
                copyScript.setIsActive(false);
            }
            
            m_switchModelScript.setIsActive(true);
            m_validateBarModelAreaScript.setIsActive(false);
            
            this.getNodeById("ResetBarModelArea").setIsActive(false);
            this.getNodeById("UndoBarModelArea").setIsActive(false);
            this.getNodeById("ResetTermArea").setIsActive(true);
            
            // Transition to equation modeling mode
            var undoTermArea:UndoTermArea = this.getNodeById("UndoTermArea") as UndoTermArea;
            undoTermArea.setIsActive(true);
            
            // Disable modifications to bar model after correct one is submitted
            this.getNodeById("BarModelDragGestures").setIsActive(false);
            this.getNodeById("ModifyExistingBarGestures").setIsActive(false);
            
            // Hide the bar model validate button
            m_gameEngine.getUiEntity("validateButton").visible = false;
            
            // Show the parenthesis button (only allowed for specific bar model types that have
            // complex enough equation to warrant)
            var currentLevel:WordProblemLevelData = m_gameEngine.getCurrentLevel();
            if (currentLevel.getLevelRules().allowParenthesis)
            {
                m_gameEngine.getUiEntity("parenthesisButton").visible = true;
                this.getNodeById("AddAndChangeParenthesis").setIsActive(true);
            }
            
            // Enter card only shows up after bar model created
            if (currentLevel.getLevelRules().allowCreateCard) 
            {
                var cardCreator:EnterNewCard = new EnterNewCard(m_gameEngine, m_expressionCompiler, m_assetManager, false, 3, "EnterNewCard");
                this.getNodeById("DeckGestures").pushChild(cardCreator, 0);
                cardCreator.overrideLevelReady();
            }
            
            Starling.juggler.delayCall(
                delayFunction,
                0.2
            );
        }
        
        private function onSwitchModelClicked(inBarModelMode:Boolean):void
        {
            if (inBarModelMode)
            {
                this.getNodeById("BarToCard").setIsActive(false);
            }
            else
            {
                this.getNodeById("BarToCard").setIsActive(true);
            }
        }
    }
}