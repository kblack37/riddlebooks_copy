package levelscripts.barmodel.tutorials
{
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import feathers.controls.Callout;
    
    import starling.display.DisplayObject;
    import starling.display.Image;
    
    import wordproblem.callouts.CalloutCreator;
    import wordproblem.characters.HelperCharacterController;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.BarModelTypes;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.component.ExpressionComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.scripting.graph.action.CustomVisitNode;
    import wordproblem.engine.scripting.graph.selector.PrioritySelector;
    import wordproblem.engine.scripting.graph.selector.SequenceSelector;
    import wordproblem.engine.text.view.DocumentView;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.engine.widget.DeckWidget;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.hints.HintCommonUtil;
    import wordproblem.hints.HintScript;
    import wordproblem.hints.HintSelectorNode;
    import wordproblem.hints.scripts.HelpController;
    import wordproblem.hints.selector.ExpressionModelHintSelector;
    import wordproblem.hints.selector.ShowHintOnBarModelMistake;
    import wordproblem.player.PlayerStatsAndSaveData;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.barmodel.AddNewBar;
    import wordproblem.scripts.barmodel.AddNewBarSegment;
    import wordproblem.scripts.barmodel.AddNewHorizontalLabel;
    import wordproblem.scripts.barmodel.BarToCard;
    import wordproblem.scripts.barmodel.RemoveBarSegment;
    import wordproblem.scripts.barmodel.RemoveHorizontalLabel;
    import wordproblem.scripts.barmodel.ResizeHorizontalBarLabel;
    import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
    import wordproblem.scripts.barmodel.SwitchBetweenBarAndEquationModel;
    import wordproblem.scripts.barmodel.UndoBarModelArea;
    import wordproblem.scripts.barmodel.ValidateBarModelArea;
    import wordproblem.scripts.deck.DeckController;
    import wordproblem.scripts.deck.DiscoverTerm;
    import wordproblem.scripts.expression.AddTerm;
    import wordproblem.scripts.expression.RemoveTerm;
    import wordproblem.scripts.level.BaseCustomLevelScript;
    import wordproblem.scripts.level.util.LevelCommonUtil;
    import wordproblem.scripts.level.util.ProgressControl;
    import wordproblem.scripts.level.util.TemporaryTextureControl;
    import wordproblem.scripts.level.util.TextReplacementControl;
    import wordproblem.scripts.model.ModelSpecificEquation;
    import wordproblem.scripts.text.DragText;
    import wordproblem.scripts.text.HighlightTextForCard;
    import wordproblem.scripts.text.TextToCard;
    
    public class LS_TextDiscoverA extends BaseCustomLevelScript
    {
        private var m_progressControl:ProgressControl;
        private var m_textReplacementControl:TextReplacementControl;
        private var m_temporaryTextureControl:TemporaryTextureControl;
        
        /**
         * Script controlling correctness of bar models
         */
        private var m_validation:ValidateBarModelArea;
        
        /**
         * Script controlling swapping between bar model and equation model.
         */
        private var m_switchModelScript:SwitchBetweenBarAndEquationModel;
        
        /**
         * Create list of animal term values that the player can select from.
         * As a shortcut hack, we assume the term value for the animal is the same as the texture name
         */
        private var m_animalsList:Vector.<String>;
        
        private var m_animalA:String;
        private var m_animalB:String;
        private var m_match:String;
        
        private var m_matchTypesList:Vector.<String>;
        
        private var m_hintButtonClickedOnce:Boolean = false;
        
        public function LS_TextDiscoverA(gameEngine:IGameEngine, 
                                         expressionCompiler:IExpressionTreeCompiler, 
                                         assetManager:AssetManager, 
                                         playerStatsAndSaveData:PlayerStatsAndSaveData, 
                                         id:String=null, 
                                         isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, playerStatsAndSaveData, id, isActive);
            
            // Control of deck
            super.pushChild(new DeckController(gameEngine, expressionCompiler, assetManager, "DeckController"));
            
            var resizeGestures:PrioritySelector = new PrioritySelector("barModelClickGestures");
            resizeGestures.pushChild(new ResizeHorizontalBarLabel(gameEngine, expressionCompiler, assetManager));
            resizeGestures.pushChild(new RemoveBarSegment(gameEngine, expressionCompiler, assetManager));
            resizeGestures.pushChild(new RemoveHorizontalLabel(gameEngine, expressionCompiler, assetManager));
            super.pushChild(resizeGestures);
            
            var prioritySelector:PrioritySelector = new PrioritySelector("barModelDragGestures");
            prioritySelector.pushChild(new AddNewBarSegment(gameEngine, expressionCompiler, assetManager, "AddNewBarSegment", false));
            prioritySelector.pushChild(new AddNewHorizontalLabel(gameEngine, expressionCompiler, assetManager, 1, "AddNewHorizontalLabel", false));
            prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewHorizontalLabel", "ShowAddNewHorizontalLabelHitAreas"));
            prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBarSegment", "ShowAddNewBarSegmentHitAreas"));
            prioritySelector.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 1, "AddNewBar"));
            prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBar"));
            super.pushChild(prioritySelector);
            
            m_switchModelScript = new SwitchBetweenBarAndEquationModel(gameEngine, expressionCompiler, assetManager, onSwitchModelClicked, "SwitchBetweenBarAndEquationModel", false);
            m_switchModelScript.targetY = 80;
            super.pushChild(m_switchModelScript);
            super.pushChild(new UndoBarModelArea(gameEngine, expressionCompiler, assetManager, "UndoBarModelArea"));
            super.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, false, "BarToCard", false));
            
            // Add logic to only accept the model of a particular equation
            super.pushChild(new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation"));
            // Add logic to handle adding new cards (only active after all cards discovered)
            super.pushChild(new AddTerm(gameEngine, expressionCompiler, assetManager));
            super.pushChild(new RemoveTerm(m_gameEngine, m_expressionCompiler, m_assetManager, "RemoveTerm"));
            
            // Logic for text dragging + discovery
            super.pushChild(new DiscoverTerm(m_gameEngine, m_assetManager, "DiscoverTerm"));
            super.pushChild(new HighlightTextForCard(m_gameEngine, m_assetManager));
            super.pushChild(new DragText(m_gameEngine, null, m_assetManager, "DragText"));
            super.pushChild(new TextToCard(m_gameEngine, m_expressionCompiler, m_assetManager, "TextToCard"));
            
            m_validation = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea");
            super.pushChild(m_validation);
            
            m_animalsList = Vector.<String>(["alligator", "duck", "elephant", "hamster", "koala", "jellyfish", "monkey", "peacock", "turtle"]);
            m_matchTypesList = Vector.<String>(["staring", "swimming", "chess", "tickling"]);
        }
        
        override public function getNumCopilotProblems():int
        {
            return 5;
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_temporaryTextureControl.dispose();
            m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.HINT_BUTTON_SELECTED, bufferEvent);
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            disablePrevNextTextButtons();
            
            var uiContainer:DisplayObject = m_gameEngine.getUiEntity("deckAndTermContainer");
            var startingUiContainerY:Number = uiContainer.y;
            m_switchModelScript.setContainerOriginalY(startingUiContainerY);
            
            m_progressControl = new ProgressControl();
            m_textReplacementControl = new TextReplacementControl(m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_textParser);
            m_temporaryTextureControl = new TemporaryTextureControl(m_assetManager);
            m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.HINT_BUTTON_SELECTED, bufferEvent);
            
            // Need to enumerate all possible points in the text where a part of the document
            // tree is replaceable with another subtree. Mainly for simple replacement of words
            var sequenceSelector:SequenceSelector = new SequenceSelector();
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 3));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:650}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:130}));
            sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {pageIndex:1}));
            
            // At this point we want to pause the player and point out the hint button
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.3}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:230}));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:270}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    // Activate the the hint
                    getNodeById("HintController").setIsActive(true);
                    showDialogForUi({id:"hintButton", text:"Click to get hints.", width:200, height:60, direction:Callout.DIRECTION_RIGHT, color:0xFFFFFF});
                    
                    // Bind parts of text to the important terms
                    m_gameEngine.addTermToDocument("3", "3_piece");
                    m_gameEngine.addTermToDocument("4", "4_piece_b");
                    m_gameEngine.addTermToDocument("4", "4_piece_a");
                    m_gameEngine.addTermToDocument("matches", "var_piece");
                    
                    return ScriptStatus.SUCCESS;
                }, null));
            
            // Wait until they have clicked the hint button OR if they solved the bar model without needing hints
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    if (m_hintButtonClickedOnce)
                    {
                        removeDialogForUi({id:"hintButton"});
                    }
                    return (m_hintButtonClickedOnce || m_progressControl.getProgress() > 3) ? ScriptStatus.SUCCESS : ScriptStatus.FAIL;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 5));
            sequenceSelector.pushChild(new CustomVisitNode(levelSolved, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.3}));
            sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
            
            super.pushChild(sequenceSelector);
            
            var helperCharacterController:HelperCharacterController = new HelperCharacterController(
                m_gameEngine.getCharacterComponentManager(),
                new CalloutCreator(m_textParser, m_textViewFactory));
            
            // Special tutorial hints
            var hintController:HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, "HintController", false);
            super.pushChild(hintController);
            hintController.overrideLevelReady();

            var hintSelector:HintSelectorNode = new HintSelectorNode();
            var expressionModelHint:ExpressionModelHintSelector = new ExpressionModelHintSelector(
                m_gameEngine, m_assetManager, helperCharacterController, m_expressionCompiler, this.getNodeById("ModelSpecificEquation") as ModelSpecificEquation,
                200, 350
            );
            hintSelector.addChild(expressionModelHint);
            
            // If the bar model portion has not been solved yet
            var showHintOnBarModelMistake:ShowHintOnBarModelMistake = new ShowHintOnBarModelMistake(
                m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_validation, helperCharacterController, m_textParser, m_textViewFactory, BarModelTypes.TYPE_1A, null);
            hintSelector.addChild(showHintOnBarModelMistake);
            hintSelector.setCustomGetHintFunction(function():HintScript
            {
                // Check if all parts in the deck were selected
                var deckWidgets:Vector.<DisplayObject> = m_gameEngine.getUiEntitiesByClass(DeckWidget);
                if (deckWidgets.length > 0)
                {
                    var deckWidget:DeckWidget = deckWidgets[0] as DeckWidget;
                    if (deckWidget.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID).length < 3)
                    {
                        var textArea:TextAreaWidget = m_gameEngine.getUiEntitiesByClass(TextAreaWidget)[0] as TextAreaWidget;
                        var hintData:Object = {
                            descriptionContent: "These are the important names and numbers. Try dragging them.",
                            highlightDocIds: textArea.getAllDocumentIdsTiedToExpression()
                        };
                        var hint:HintScript = HintCommonUtil.createHintFromMismatchData(hintData,
                            helperCharacterController,
                            m_assetManager, m_gameEngine.getMouseState(), m_textParser, m_textViewFactory, textArea, 
                            m_gameEngine, 200, 300);
                    }
                    else if (HintCommonUtil.getLevelStillNeedsBarModelToSolve(m_gameEngine))
                    {
                        hint = showHintOnBarModelMistake.getHint();
                    }
                    else
                    {
                        hint = expressionModelHint.getHint();
                    }
                    
                }
                return hint;
            }, null);
            hintController.setRootHintSelectorNode(hintSelector);
            
            var barModelArea:BarModelAreaWidget = m_gameEngine.getUiEntity("barModelArea") as BarModelAreaWidget;
            barModelArea.unitHeight = 60;
            
            setupFirstModel();
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == GameEvent.BAR_MODEL_CORRECT)
            {
                var barModelArea:BarModelAreaWidget = m_gameEngine.getUiEntity("barModelArea") as BarModelAreaWidget;
                if (m_progressControl.getProgress() == 0)
                {
                    m_progressControl.incrementProgress();
                    
                    // Get the animal that was selected
                    var targetBarWhole:BarWhole = barModelArea.getBarModelData().barWholes[0];
                    m_animalA = targetBarWhole.barLabels[0].value;
                    
                    // Clear the bar model
                    (this.getNodeById("UndoBarModelArea") as UndoBarModelArea).resetHistory();
                    barModelArea.getBarModelData().clear();
                    barModelArea.redraw();
                    
                    // Replace the first question mark with text of the selected animal
                    var contentToReplace:XML = <span></span>;
                    contentToReplace.appendChild(m_animalA);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["animal_a_select_a"]),
                        Vector.<XML>([contentToReplace]));
                    
                    redrawFirstPage();
                    
                    setupSecondModel();
                }
                else if (m_progressControl.getProgress() == 1)
                {
                    m_progressControl.incrementProgress();
                    
                    // Get the animal that was selected
                    targetBarWhole = barModelArea.getBarModelData().barWholes[0];
                    m_animalB = targetBarWhole.barLabels[0].value;
                    
                    // Clear the bar model
                    (this.getNodeById("UndoBarModelArea") as UndoBarModelArea).resetHistory();
                    barModelArea.getBarModelData().clear();
                    barModelArea.redraw();
                    
                    // Replace the second question mark with the text of the selected animal
                    contentToReplace = <span></span>;
                    contentToReplace.appendChild(m_animalB);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["animal_b_select_a"]),
                        Vector.<XML>([contentToReplace]));
                    
                    redrawFirstPage();
                    
                    setupThirdModel();
                }
                else if (m_progressControl.getProgress() == 2)
                {
                    m_progressControl.incrementProgress();
                    
                    // Get the match that was selected
                    targetBarWhole = barModelArea.getBarModelData().barWholes[0];
                    m_match = targetBarWhole.barLabels[0].value;
                    
                    // Clear the bar model
                    (this.getNodeById("UndoBarModelArea") as UndoBarModelArea).resetHistory();
                    barModelArea.getBarModelData().clear();
                    barModelArea.redraw();
                    
                    // Replace the third question mark with the text of the selected match
                    contentToReplace = <span></span>;
                    contentToReplace.appendChild(m_match);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["match_select_a"]),
                        Vector.<XML>([contentToReplace]), 0);
                    
                    contentToReplace = <span></span>;
                    contentToReplace.appendChild(m_match);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["match_select_b"]),
                        Vector.<XML>([contentToReplace]), 1);
                    
                    redrawFirstPage();
                    
                    setupFourthModel();
                    redrawSecondPage();
                    
                    // Enable other actions finally
                    this.getNodeById("AddNewBarSegment").setIsActive(true);
                    this.getNodeById("AddNewHorizontalLabel").setIsActive(true);
                }
                else if (m_progressControl.getProgress() == 3)
                {
                    m_progressControl.incrementProgress();
                    
                    // Clear the bar model specific buttons
                    (this.getNodeById("UndoBarModelArea") as UndoBarModelArea).setIsActive(false);
                    
                    // Hide validate button
                    m_gameEngine.getUiEntity("validateButton").visible = false;
                    
                    // Activate the switch
                    m_switchModelScript.setIsActive(true);
                    m_switchModelScript.onSwitchModelClicked();
                    m_validation.setIsActive(false);
                }
            }
            else if (eventType == GameEvent.EQUATION_MODEL_SUCCESS)
            {
                if (m_progressControl.getProgress() == 4)
                {
                    m_progressControl.incrementProgress();
                }
            }
            else if (eventType == GameEvent.HINT_BUTTON_SELECTED)
            {
                m_hintButtonClickedOnce = true;
            }
        }
        
        private function setupFirstModel():void
        {
            m_gameEngine.setDeckAreaContent(m_animalsList, super.getBooleanList(m_animalsList.length, false), false);
            
            // The correct model will allow for any animal to be correct
            LevelCommonUtil.setReferenceBarModelForPickem("anything", null, m_animalsList, m_validation);
            
            redrawFirstPage();
        }
        
        private function setupSecondModel():void
        {
            // The second animal can be anything except the first
            var prunedAnimalList:Vector.<String> = new Vector.<String>();
            var i:int;
            for (i = 0; i < m_animalsList.length; i++)
            {
                if (m_animalsList[i] != m_animalA)
                {
                    prunedAnimalList.push(m_animalsList[i]);
                }
            }
            
            m_gameEngine.setDeckAreaContent(prunedAnimalList, super.getBooleanList(prunedAnimalList.length, false), false);
            
            // The previous reference bar model is fine.
            LevelCommonUtil.setReferenceBarModelForPickem("anything", null, null, m_validation);
        }
        
        private function setupThirdModel():void
        {
            m_gameEngine.setDeckAreaContent(m_matchTypesList, super.getBooleanList(m_matchTypesList.length, false), false);
            
            // Again we can reuse the same reference model, just remember to add the match type alias
            LevelCommonUtil.setReferenceBarModelForPickem("anything", null, m_matchTypesList, m_validation);
        }
        
        private function setupFourthModel():void
        {
            var deckValues:Vector.<String> = Vector.<String>([]);
            m_gameEngine.setDeckAreaContent(deckValues, super.getBooleanList(deckValues.length, false), false);
            
            var modelSpecificEquationScript:ModelSpecificEquation = this.getNodeById("ModelSpecificEquation") as ModelSpecificEquation;
            modelSpecificEquationScript.addEquation("1", "matches=3+4+4", false, true);
            
            // Correct model adds all three numbers together
            var referenceBarModels:Vector.<BarModelData> = new Vector.<BarModelData>();
            var correctModel:BarModelData = new BarModelData();
            var correctBarWhole:BarWhole = new BarWhole(true);
            correctBarWhole.barSegments.push(new BarSegment(3, 1, 0, null));
            correctBarWhole.barSegments.push(new BarSegment(4, 1, 0, null));
            correctBarWhole.barSegments.push(new BarSegment(4, 1, 0, null));
            correctBarWhole.barLabels.push(new BarLabel("3", 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            correctBarWhole.barLabels.push(new BarLabel("4", 1, 1, true, false, BarLabel.BRACKET_NONE, null));
            correctBarWhole.barLabels.push(new BarLabel("4", 2, 2, true, false, BarLabel.BRACKET_NONE, null));
            correctBarWhole.barLabels.push(new BarLabel("matches", 0, 2, true, false, BarLabel.BRACKET_STRAIGHT, null));
            correctModel.barWholes.push(correctBarWhole);
            referenceBarModels.push(correctModel);
            
            m_validation.setReferenceModels(referenceBarModels);
        }
        
        private function redrawFirstPage():void
        {
            // At the start, draw question marks in the spots where animals should be and fill in both question marks
            // with green color
            var textArea:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            var documentViews:Vector.<DocumentView> = new Vector.<DocumentView>();
            var drawQuestionInFirstSlot:Boolean = true;
            var drawQuestionInSecondSlot:Boolean = true;
            
            // If they picked one animal make sure the picture of the animal is filled into one part
            if (m_progressControl.getProgress() == 1)
            {
                drawQuestionInFirstSlot = false;
            }
            // They picked both animals
            else if (m_progressControl.getProgress() >= 2)
            {
                drawQuestionInFirstSlot = false;
                drawQuestionInSecondSlot = false;
            }
            
            documentViews.length = 0;
            textArea.getDocumentViewsAtPageIndexById("animal_a_container_a", documentViews);
            var maxImageHeight:Number = 100;
            if (!drawQuestionInFirstSlot)
            {
                var animalFirstSlot:Image = new Image(m_temporaryTextureControl.getDisposableTexture(m_animalA));
                animalFirstSlot.scaleX = animalFirstSlot.scaleY = maxImageHeight / animalFirstSlot.height;
                documentViews[0].addChild(animalFirstSlot);
            }
            
            documentViews.length = 0;
            textArea.getDocumentViewsAtPageIndexById("animal_b_container_a", documentViews);
            if (!drawQuestionInSecondSlot)
            {
                var animalSecondSlot:Image = new Image(m_temporaryTextureControl.getDisposableTexture(m_animalB));
                animalSecondSlot.scaleX = animalSecondSlot.scaleY = maxImageHeight / animalSecondSlot.height;
                documentViews[0].addChild(animalSecondSlot);
            }
            
            m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(textArea);
        }
        
        private function redrawSecondPage():void
        {
            // At this point all the choices made by the player have been found
            var documentIds:Vector.<String> = Vector.<String>(["animal_b_select_b", "animal_a_select_b", "match_select_b"]);
            var contentA:XML = <span></span>;
            contentA.appendChild(m_animalB);
            var contentB:XML = <span></span>;
            contentB.appendChild(m_animalA);
            var contentC:XML = <span></span>;
            contentC.appendChild(m_match);
            var replacementContent:Vector.<XML> = Vector.<XML>([contentA, contentB, contentC]);
            m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(documentIds, replacementContent, 1);
        }
        
        private function onSwitchModelClicked(inBarModelMode:Boolean):void
        {
            if (inBarModelMode)
            {
                this.getNodeById("barModelDragGestures").setIsActive(true);
                this.getNodeById("barModelClickGestures").setIsActive(true);
                this.getNodeById("BarToCard").setIsActive(false);
            }
            else
            {
                this.getNodeById("barModelDragGestures").setIsActive(false);
                this.getNodeById("barModelClickGestures").setIsActive(false);
                this.getNodeById("BarToCard").setIsActive(true);
            }
        }
    }
}