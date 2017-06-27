package levelscripts.barmodel.tutorials
{
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import feathers.controls.Callout;
    
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.textures.Texture;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.component.HighlightComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.scripting.graph.action.CustomVisitNode;
    import wordproblem.engine.scripting.graph.selector.PrioritySelector;
    import wordproblem.engine.scripting.graph.selector.SequenceSelector;
    import wordproblem.engine.text.view.DocumentView;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.engine.widget.DeckWidget;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.hints.CustomFillLogicHint;
    import wordproblem.hints.HintScript;
    import wordproblem.hints.scripts.HelpController;
    import wordproblem.player.PlayerStatsAndSaveData;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.barmodel.AddNewBar;
    import wordproblem.scripts.barmodel.AddNewHorizontalLabel;
    import wordproblem.scripts.barmodel.AddNewUnitBar;
    import wordproblem.scripts.barmodel.BarToCard;
    import wordproblem.scripts.barmodel.RemoveBarSegment;
    import wordproblem.scripts.barmodel.RemoveHorizontalLabel;
    import wordproblem.scripts.barmodel.RemoveLabelOnSegment;
    import wordproblem.scripts.barmodel.ResetBarModelArea;
    import wordproblem.scripts.barmodel.ResizeHorizontalBarLabel;
    import wordproblem.scripts.barmodel.ShowBarModelHitAreas;
    import wordproblem.scripts.barmodel.SwitchBetweenBarAndEquationModel;
    import wordproblem.scripts.barmodel.UndoBarModelArea;
    import wordproblem.scripts.barmodel.ValidateBarModelArea;
    import wordproblem.scripts.deck.DeckController;
    import wordproblem.scripts.deck.EnterNewCard;
    import wordproblem.scripts.expression.AddTerm;
    import wordproblem.scripts.expression.PressToChangeOperator;
    import wordproblem.scripts.level.BaseCustomLevelScript;
    import wordproblem.scripts.level.util.LevelCommonUtil;
    import wordproblem.scripts.level.util.ProgressControl;
    import wordproblem.scripts.level.util.TemporaryTextureControl;
    import wordproblem.scripts.level.util.TextReplacementControl;
    import wordproblem.scripts.model.ModelSpecificEquation;
    import wordproblem.scripts.expression.ResetTermArea;
    import wordproblem.scripts.expression.UndoTermArea;
    
    /**
     * Tutorial introducing approach to basic ratio and fractions problems.
     * 
     * Also introduces the notion of entering the value for a custom card.
     */
    public class LS_FractionEnterCardA extends BaseCustomLevelScript
    {
        private var m_progressControl:ProgressControl;
        private var m_textReplacementControl:TextReplacementControl;
        private var m_temporaryTextureControl:TemporaryTextureControl;
        
        private var m_validation:ValidateBarModelArea;
        private var m_barModelArea:BarModelAreaWidget;
        private var m_hintController:HelpController;
        
        /**
         * Script controlling swapping between bar model and equation model.
         */
        private var m_switchModelScript:SwitchBetweenBarAndEquationModel;
        
        private var m_itemOptions:Vector.<String>;
        private var m_selectedItem:String;
        private var m_itemValueToPluralName:Object;
        
        // Hints to get working
        private var m_barModelIsSetup:Boolean = false;
        private var m_addFirstLabelHint:HintScript;
        private var m_resizeFirstLabelHint:HintScript;
        private var m_addSecondLabelHint:HintScript;
        private var m_resizeSecondLabelHint:HintScript;
        private var m_createNewCardHint:HintScript;
        
        public function LS_FractionEnterCardA(gameEngine:IGameEngine, 
                                              expressionCompiler:IExpressionTreeCompiler, 
                                              assetManager:AssetManager, 
                                              playerStatsAndSaveData:PlayerStatsAndSaveData, 
                                              id:String=null, 
                                              isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, playerStatsAndSaveData, id, isActive);
            
            // Control of deck
            var deckGestures:PrioritySelector = new PrioritySelector("DeckGestures");
            deckGestures.pushChild(new DeckController(m_gameEngine, m_expressionCompiler, m_assetManager, "DeckController"));
            super.pushChild(deckGestures);
            
            // Player is supposed to add a new bar into a blank space
            var prioritySelector:PrioritySelector = new PrioritySelector("BarModelDragGestures");
            prioritySelector.pushChild(new AddNewHorizontalLabel(gameEngine, expressionCompiler, assetManager, 2, "AddNewHorizontalLabel", false));
            prioritySelector.pushChild(new AddNewUnitBar(gameEngine, expressionCompiler, assetManager, 1, "AddNewUnitBar", false));
            prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewHorizontalLabel", "ShowAddNewHorizontalLabelHitAreas"));
            prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewUnitBar", "ShowAddNewUnitBarHitAreas"));
            prioritySelector.pushChild(new AddNewBar(gameEngine, expressionCompiler, assetManager, 1, "AddNewBar"));
            prioritySelector.pushChild(new ShowBarModelHitAreas(gameEngine, expressionCompiler, assetManager, "AddNewBar"));
            super.pushChild(prioritySelector);
            
            // Remove gestures are a child
            var modifyGestures:PrioritySelector = new PrioritySelector("BarModelModifyGestures");
            modifyGestures.pushChild(new ResizeHorizontalBarLabel(gameEngine, expressionCompiler, assetManager));
            modifyGestures.pushChild(new BarToCard(gameEngine, expressionCompiler, assetManager, true, "BarToCardModelMode", false));
            var removeGestures:PrioritySelector = new PrioritySelector("BarModelRemoveGestures");
            removeGestures.pushChild(new RemoveLabelOnSegment(gameEngine, expressionCompiler, assetManager, "RemoveLabelOnSegment", false));
            removeGestures.pushChild(new RemoveBarSegment(gameEngine, expressionCompiler, assetManager, "RemoveBarSegment"));
            removeGestures.pushChild(new RemoveHorizontalLabel(gameEngine, expressionCompiler, assetManager));
            modifyGestures.pushChild(removeGestures);
            super.pushChild(modifyGestures);
            
            m_switchModelScript = new SwitchBetweenBarAndEquationModel(gameEngine, expressionCompiler, assetManager, null, "SwitchBetweenBarAndEquationModel", false);
            m_switchModelScript.targetY = 80;
            super.pushChild(m_switchModelScript);
            super.pushChild(new ResetBarModelArea(gameEngine, expressionCompiler, assetManager, "ResetBarModelArea"));
            super.pushChild(new UndoBarModelArea(gameEngine, expressionCompiler, assetManager, "UndoBarModelArea"));
            super.pushChild(new UndoTermArea(gameEngine, expressionCompiler, assetManager, "UndoTermArea", false));
            super.pushChild(new ResetTermArea(gameEngine, expressionCompiler, assetManager, "ResetTermArea", false));
            
            // Add logic to only accept the model of a particular equation
            super.pushChild(new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation"));
            // Add logic to handle adding new cards (only active after all cards discovered)
            super.pushChild(new AddTerm(gameEngine, expressionCompiler, assetManager, "AddTerm", false));
            super.pushChild(new PressToChangeOperator(m_gameEngine, m_expressionCompiler, m_assetManager));
            
            m_validation = new ValidateBarModelArea(gameEngine, expressionCompiler, assetManager, "ValidateBarModelArea");
            super.pushChild(m_validation);
            
            m_itemOptions = Vector.<String>(["apple", "cheese", "cotton_candy", "cookie", "dog_biscuit", "pretzel"]);
            m_itemValueToPluralName = {
                  apple: "apples",
                  cookie: "cookies",
                  dog_biscuit: "dog treats",
                  pretzel: "pretzels"
            };
            
            m_addFirstLabelHint = new CustomFillLogicHint(showAddFirstLabel, null, null, null, hideAddFirstLabel, null, true);
            m_addSecondLabelHint = new CustomFillLogicHint(showAddSecondLabel, null, null, null, hideAddSecondLabel, null, true);
            m_resizeFirstLabelHint = new CustomFillLogicHint(showResizeFirstLabel, null, null, null, hideResizeFirstLabel, null, true);
            m_resizeSecondLabelHint = new CustomFillLogicHint(showResizeSecondLabel, null, null, null, hideResizeSecondLabel, null, true);
            m_createNewCardHint = new CustomFillLogicHint(showCreateCard, null, null, null, hideCreateCard, null, true);
        }
        
        override public function visit():int
        {
            // Custom logic needed to deal with controlling when hints not bound to the hint screen
            // are activated or deactivated
            if (m_ready)
            {
                // Highlight the split button
                if (m_progressControl.getProgress() == 1 && m_barModelIsSetup)
                {
                    // Check if added appropriate labels
                    var addedFirstLabel:Boolean = false;
                    var addedSecondLabel:Boolean = false;
                    var resizedFirstLabel:Boolean = false;
                    var resizedSecondLabel:Boolean = false;
                    var barWholes:Vector.<BarWhole> = m_barModelArea.getBarModelData().barWholes;
                    if (barWholes.length > 0)
                    {
                        var labels:Vector.<BarLabel> = barWholes[0].barLabels;
                        var numLabels:int = labels.length;
                        for (var i:int = 0; i < numLabels; i++)
                        {
                            var label:BarLabel = labels[i];
                            var labelLength:Number = label.endSegmentIndex - label.startSegmentIndex + 1;
                            if (label.value == "6")
                            {
                                addedFirstLabel = true;
                                if (labelLength == 2)
                                {
                                    resizedFirstLabel = true;
                                }
                            }
                            else if (label.value == "no_grow")
                            {
                                addedSecondLabel = true;
                                if (labelLength == 3)
                                {
                                    resizedSecondLabel = true;
                                }
                            }
                        }
                    }
                    
                    // Did everything, remove all hints
                    if (resizedFirstLabel && resizedSecondLabel && m_hintController.getCurrentlyShownHint() != null)
                    {
                        m_hintController.manuallyRemoveAllHints();
                    }
                    
                    // Need to add first label
                    if (!addedFirstLabel && m_hintController.getCurrentlyShownHint() != m_addFirstLabelHint)
                    {
                        m_hintController.manuallyShowHint(m_addFirstLabelHint);
                    }
                    
                    // Need to resize first label
                    if (addedFirstLabel && !resizedFirstLabel && m_hintController.getCurrentlyShownHint() != m_resizeFirstLabelHint)
                    {
                        m_hintController.manuallyShowHint(m_resizeFirstLabelHint);
                    }
                    
                    if (resizedFirstLabel && !addedSecondLabel && m_hintController.getCurrentlyShownHint() != m_addSecondLabelHint)
                    {
                        m_hintController.manuallyShowHint(m_addSecondLabelHint);
                    }
                    
                    if (resizedFirstLabel && addedSecondLabel && !resizedSecondLabel && m_hintController.getCurrentlyShownHint() != m_resizeSecondLabelHint)
                    {
                        m_hintController.manuallyShowHint(m_resizeSecondLabelHint);
                    }
                }
                else if (m_progressControl.getProgress() == 2)
                {
                    // Check if a 3 was created in the deck
                    var createdCard:Boolean = false;
                    var deckArea:DeckWidget = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
                    for each (var termInDeck:BaseTermWidget in deckArea.getObjects())
                    {
                        if (termInDeck != null && termInDeck.getNode().data == "3")
                        {
                            createdCard = true;
                            break;
                        }
                    }
                    
                    if (!createdCard && m_hintController.getCurrentlyShownHint() != m_createNewCardHint)
                    {
                        m_hintController.manuallyShowHint(m_createNewCardHint);
                    }
                    
                    if (createdCard && m_hintController.getCurrentlyShownHint() != null)
                    {
                        m_hintController.manuallyRemoveAllHints();
                    }
                }
            }
            return super.visit();
        }
        
        override public function getNumCopilotProblems():int
        {
            return 5;
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.BAR_MODEL_INCORRECT, bufferEvent);
            m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
            m_barModelArea.removeEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
            
            m_temporaryTextureControl.dispose();
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            disablePrevNextTextButtons();
            
            var uiContainer:DisplayObject = m_gameEngine.getUiEntity("deckAndTermContainer");
            var startingUiContainerY:Number = uiContainer.y;
            m_switchModelScript.setContainerOriginalY(startingUiContainerY);
            
            // Bind events
            m_gameEngine.addEventListener(GameEvent.BAR_MODEL_CORRECT, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.BAR_MODEL_INCORRECT, bufferEvent);
            m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
            m_barModelArea = m_gameEngine.getUiEntity("barModelArea") as BarModelAreaWidget;
            m_barModelArea.unitHeight = 60;
            m_barModelArea.unitLength = 300;
            m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
            
            m_progressControl = new ProgressControl();
            m_textReplacementControl = new TextReplacementControl(m_gameEngine, m_assetManager, m_playerStatsAndSaveData, m_textParser);
            m_temporaryTextureControl = new TemporaryTextureControl(m_assetManager);
            
            var sequenceSelector:SequenceSelector = new SequenceSelector();
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 1));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:650}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:350}));
            sequenceSelector.pushChild(new CustomVisitNode(goToPageIndex, {pageIndex:1}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    refreshSecondPage();
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.3}));
            sequenceSelector.pushChild(new CustomVisitNode(clickToContinue, {x:450, y:350}));
            sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {id:"deckAndTermContainer", time:0.3, y:275}));
            sequenceSelector.pushChild(new CustomVisitNode(
                function(param:Object):int
                {
                    setupBarModel();
                    return ScriptStatus.SUCCESS;
                }, null));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 2));
            
            sequenceSelector.pushChild(new CustomVisitNode(m_progressControl.getProgressEquals, 3));
            sequenceSelector.pushChild(new CustomVisitNode(levelSolved, null));
            sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.3}));
            sequenceSelector.pushChild(new CustomVisitNode(levelComplete, null));
            super.pushChild(sequenceSelector);
            
            // Special tutorial hints
            var hintController:HelpController = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager, "HintController", false);
            super.pushChild(hintController);
            hintController.overrideLevelReady();
            m_hintController = hintController;
            
            setupItemSelectModel();
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == GameEvent.BAR_MODEL_CORRECT)
            {
                if (m_progressControl.getProgress() == 0)
                {
                    m_progressControl.incrementProgress();
                    
                    // Get the selected tree type
                    var targetBarWhole:BarWhole = m_barModelArea.getBarModelData().barWholes[0];
                    m_selectedItem = targetBarWhole.barLabels[0].value;
                    
                    // Clear the bar model
                    (this.getNodeById("ResetBarModelArea") as ResetBarModelArea).setStartingModel(null);
                    (this.getNodeById("UndoBarModelArea") as UndoBarModelArea).resetHistory();
                    m_barModelArea.getBarModelData().clear();
                    m_barModelArea.redraw();
                    
                    // Replace all the areas in the text with the new items
                    var contentA:XML = <span></span>;
                    var itemName:String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(m_selectedItem).name;
                    contentA.appendChild(itemName);
                    var contentB:XML = <span></span>;
                    if (m_itemValueToPluralName.hasOwnProperty(m_selectedItem))
                    {
                        itemName = m_itemValueToPluralName[m_selectedItem];
                    }
                    contentB.appendChild(itemName);
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["item_select_a", "item_select_b"]),
                        Vector.<XML>([contentA, contentB]), 0);
                    refreshFirstPage();
                    
                    m_textReplacementControl.replaceContentAtDocumentIdsAtPageIndex(Vector.<String>(["item_select_c"]),
                        Vector.<XML>([contentA]), 1);
                    
                    setDocumentIdVisible({id:"hidden_a", visible:true});
                }
                else if (m_progressControl.getProgress() == 1)
                {
                    m_progressControl.incrementProgress();
                    
                    // Hide validate button
                    m_gameEngine.getUiEntity("validateButton").visible = false;
                    
                    setupEquation();
                }
            }
            else if (eventType == GameEvent.EQUATION_MODEL_SUCCESS)
            {
                if (m_progressControl.getProgress() == 2)
                {
                    m_progressControl.incrementProgress();
                }
            }
            else if (eventType == GameEvent.BAR_MODEL_AREA_REDRAWN)
            {
            }
        }
        
        private function setupItemSelectModel():void
        {
            m_gameEngine.setDeckAreaContent(m_itemOptions, super.getBooleanList(m_itemOptions.length, false), false);
            
            LevelCommonUtil.setReferenceBarModelForPickem("anything", null, m_itemOptions, m_validation);
            
            refreshFirstPage();
        }
        
        private function setupBarModel():void
        {
            m_barModelIsSetup = true;
            
            var deck:Vector.<String> = Vector.<String>(["6", "no_grow"]);
            m_gameEngine.setDeckAreaContent(deck, super.getBooleanList(deck.length, false), false);
            
            // Activate the unit bar and label adding gestures
            this.getNodeById("AddNewHorizontalLabel").setIsActive(true);
            this.getNodeById("AddNewUnitBar").setIsActive(true);
            
            // Do not allow removal of bar segments
            this.getNodeById("RemoveBarSegment").setIsActive(false);
            
            var referenceModel:BarModelData = new BarModelData();
            var barWhole:BarWhole = new BarWhole(false);
            var i:int;
            var numerator:int = 2;
            var numParts:int = 5;
            for (i = 0; i < numParts; i++)
            {
                barWhole.barSegments.push(new BarSegment(1, 1, 0, null));
            }
            barWhole.barLabels.push(new BarLabel("6", 0, numerator - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
            barWhole.barLabels.push(new BarLabel("no_grow", numerator, numParts - 1, true, false, BarLabel.BRACKET_STRAIGHT, null));
            referenceModel.barWholes.push(barWhole);
            m_validation.setReferenceModels(Vector.<BarModelData>([referenceModel]));
            
            barWhole = new BarWhole(false);
            for (i = 0; i < numParts; i++)
            {
                barWhole.barSegments.push(new BarSegment(1, 1, 0xFFFFFF, null));
            }
            m_barModelArea.getBarModelData().barWholes.push(barWhole);
            m_barModelArea.redraw(false);
            
            (this.getNodeById("ResetBarModelArea") as ResetBarModelArea).setStartingModel(m_barModelArea.getBarModelData());
        }
        
        private function setupEquation():void
        {
            // Disable all bar model actions
            this.getNodeById("BarModelDragGestures").setIsActive(false);
            this.getNodeById("BarModelModifyGestures").setIsActive(false);
            
            // Disable reset+undo on the bar model
            this.getNodeById("ResetBarModelArea").setIsActive(false);
            this.getNodeById("UndoBarModelArea").setIsActive(false);
            m_validation.setIsActive(false);
            
            // Allow add new number
            this.getNodeById("AddTerm").setIsActive(true);
            
            // Activate the switch
            m_switchModelScript.setIsActive(true);
            m_switchModelScript.onSwitchModelClicked();
            
            // Player needs to create a 3 and add that to the existing equation
            var leftStartingExpression:String = "no_grow";
            m_gameEngine.setTermAreaContent("leftTermArea", leftStartingExpression);
            var rightStartingExpression:String = "6/2";
            m_gameEngine.setTermAreaContent("rightTermArea", rightStartingExpression);
            
            // Activate reset+undo for equation
            var undoTermAreaScript:UndoTermArea = this.getNodeById("UndoTermArea") as UndoTermArea;
            undoTermAreaScript.setIsActive(true);
            undoTermAreaScript.resetHistory(true);
            var resetTermAreaScript:ResetTermArea = this.getNodeById("ResetTermArea") as ResetTermArea;
            resetTermAreaScript.setIsActive(true);
            resetTermAreaScript.setStartingExpressions(Vector.<String>([
                leftStartingExpression,
                rightStartingExpression
            ]));
            
            // We need to introduce the enter new card piece
            // Tooltip over it that says need to make a 3
            var cardCreator:EnterNewCard = new EnterNewCard(m_gameEngine, m_expressionCompiler, m_assetManager, false, 2, "EnterNewCard");
            this.getNodeById("DeckGestures").pushChild(cardCreator, 0);
            cardCreator.overrideLevelReady();
            
            /*
            Some problems will allow you to create a new number to solve the problem, use it to create
            and add a three.
            */
            
            // Set up equation
            var modelSpecificEquationScript:ModelSpecificEquation = this.getNodeById("ModelSpecificEquation") as ModelSpecificEquation;
            modelSpecificEquationScript.addEquation("1", "no_grow=6/2*3", false, true);
        }
        
        private function refreshFirstPage():void
        {
            var textArea:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            m_textReplacementControl.drawDisposableTextureAtDocId("copper", m_temporaryTextureControl, textArea, "character_container_a", 0, -1, 200);
            
            m_textReplacementControl.addUnderlineToBlankSpacePlaceholders(textArea);
        }
        
        private function refreshSecondPage():void
        {
            var textArea:TextAreaWidget = m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
            var documentViews:Vector.<DocumentView> = textArea.getDocumentViewsByClass("item", null, 1);
            var itemTexture:Texture = m_temporaryTextureControl.getDisposableTexture(m_selectedItem);
            for each (var documentView:DocumentView in documentViews)
            {
                var itemImage:Image = new Image(itemTexture);
                itemImage.pivotX = itemTexture.width;
                itemImage.pivotY = itemTexture.height;
                var scaleBaseAmount:Number = itemTexture.width;
                if (itemTexture.height > itemTexture.width)
                {
                    scaleBaseAmount = itemTexture.height;   
                }
                itemImage.scaleX = itemImage.scaleY = 40 / scaleBaseAmount;
                itemImage.rotation = Math.PI * 0.1;
                documentView.removeChildren(0, -1, true);
                documentView.addChild(itemImage);
            }
        }
        
        /*
        Logic for hints
        */
        private function showAddFirstLabel():void
        {
            showAddLabel("6");
        }
        
        private function hideAddFirstLabel():void
        {
            hideAddLabel("6");
        }
        
        private function showAddSecondLabel():void
        {
            showAddLabel("no_grow");
        }
        
        private function hideAddSecondLabel():void
        {
            hideAddLabel("no_grow");
        }
        
        private function showResizeFirstLabel():void
        {
            // Highlight the number in the deck and say player should drag it onto the bar below
            // Find the label with 6
            showResizeLabel("6", "Drag the ends to resize to fit 2 boxes");
        }
        
        private function hideResizeFirstLabel():void
        {
            removeDialogForBaseWidget({
                id:m_currentLabelIdInHint, widgetId:"barModelArea" 
            });
        }
        
        private function showResizeSecondLabel():void
        {
            showResizeLabel("no_grow", "Drag the ends to resize to fit 3 boxes");
        }
        
        private function hideResizeSecondLabel():void
        {
            removeDialogForBaseWidget({
                id:m_currentLabelIdInHint, widgetId:"barModelArea" 
            });
        }
        
        private var m_currentLabelIdInHint:String;
        private function showResizeLabel(labelValue:String, text:String):void
        {
            var barLabels:Vector.<BarLabel> = m_barModelArea.getBarModelData().barWholes[0].barLabels;
            var numLabels:int = barLabels.length;
            for (var i:int = 0; i < numLabels; i++)
            {
                var barLabel:BarLabel = barLabels[i];
                if (barLabel.value == labelValue)
                {
                    break;
                }
            }
            
            var id:String = barLabel.id;
            m_barModelArea.addOrRefreshViewFromId(id);
            showDialogForBaseWidget({
                id:id, widgetId:"barModelArea", text:text,
                color:0xFFFFFF, direction:Callout.DIRECTION_DOWN, width:200, height:70, animationPeriod:1
            });
            m_currentLabelIdInHint = id;
        }
        
        private function showAddLabel(deckId:String):void
        {
            // Highlight the number in the deck and say player should drag it onto the bar below
            var deckArea:DeckWidget = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
            deckArea.componentManager.addComponentToEntity(new HighlightComponent(deckId, 0xFF0000, 2));
            showDialogForBaseWidget({
                id:deckId, widgetId:"deckArea", text:"Put under the boxes",
                color:0xFFFFFF, direction:Callout.DIRECTION_UP, width:200, height:70, animationPeriod:1
            });
        }
        
        private function hideAddLabel(deckId:String):void
        {
            var deckArea:DeckWidget = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
            if (deckArea != null)
            {
                deckArea.componentManager.removeComponentFromEntity(deckId, HighlightComponent.TYPE_ID);
                removeDialogForBaseWidget({
                    id:deckId, widgetId:"deckArea"
                });
            }
        }
        
        private function showCreateCard():void
        {
            showDialogForBaseWidget({
                id:"NEW", widgetId:"deckArea", text:"Make a new 3 to solve the equation.",
                color:0xFFFFFF, direction:Callout.DIRECTION_DOWN, width:200, height:70, animationPeriod:1
            });
        }
        
        private function hideCreateCard():void
        {
            removeDialogForBaseWidget({
                id:"NEW", widgetId:"deckArea"
            });
        }
    }
}