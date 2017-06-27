package wordproblem.creator
{
    import flash.display.Stage;
    import flash.geom.Rectangle;
    import flash.text.TextFormat;
    
    import cgs.Audio.Audio;
    
    import dragonbox.common.state.BaseState;
    import dragonbox.common.state.IStateMachine;
    import dragonbox.common.time.Time;
    import dragonbox.common.ui.MouseState;
    
    import feathers.controls.Button;
    import feathers.core.PopUpManager;
    import feathers.display.Scale9Image;
    import feathers.textures.Scale9Textures;
    
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.filters.ColorMatrixFilter;
    import starling.textures.Texture;
    
    import wordproblem.AlgebraAdventureConfig;
    import wordproblem.creator.scripts.ChangeAliasScript;
    import wordproblem.creator.scripts.ChangeBarModelArea;
    import wordproblem.creator.scripts.ChangeMouseOnHighlightActive;
    import wordproblem.creator.scripts.ChangeTextAppearanceScript;
    import wordproblem.creator.scripts.HighlightProblemPartsScript;
    import wordproblem.creator.scripts.PickElementFromBarModel;
    import wordproblem.creator.scripts.PrepopulateTextScript;
    import wordproblem.creator.scripts.ShowBarModelPartDescription;
    import wordproblem.creator.scripts.ShowExampleProblemScript;
    import wordproblem.creator.scripts.SubmitProblemScript;
    import wordproblem.creator.scripts.TestProblemScript;
    import wordproblem.engine.barmodel.BarModelTypeDrawer;
    import wordproblem.engine.barmodel.BarModelTypeDrawerProperties;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.ComponentManager;
    import wordproblem.engine.component.RenderableComponent;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.level.CardAttributes;
    import wordproblem.engine.level.LevelCompiler;
    import wordproblem.engine.scripting.graph.ScriptNode;
    import wordproblem.engine.scripting.graph.selector.ConcurrentSelector;
    import wordproblem.engine.systems.CalloutSystem;
    import wordproblem.engine.systems.HighlightSystem;
    import wordproblem.engine.text.GameFonts;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.engine.widget.WidgetUtil;
    import wordproblem.event.CommandEvent;
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.log.GameServerRequester;
    import wordproblem.player.ButtonColorData;
    import wordproblem.player.PlayerStatsAndSaveData;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.layering.Layering;
    import wordproblem.settings.OptionButton;
    import wordproblem.settings.OptionsScreen;
    
    /**
     * This state shows up when the player is in the mode to create their own wordproblems.
     * 
     * The main components are the text area, the bar model area, the pieces to tag
     * 
     * TODO: The bar model area should be made interactable.
     * The list of pieces should be deleted
     */
    public class WordProblemCreateState extends BaseState
    {
        /**
         * This is analogous to the level data available to the game engine to render the word problem
         */
        private var m_problemCreateData:ProblemCreateData;
        
        private var m_assetManager:AssetManager;
        
        /**
         * This class is used for the saving of level information such that it can be viewable to multiple clients
         */
        private var m_gameServerRequester:GameServerRequester;
        private var m_mouseState:MouseState;
        
        /**
         * Timer mainly used by the text edit component to figure out when it needs
         * to refresh the highlights
         */
        private var m_time:Time;
        
        /**
         * The logic for interacting with all of the components
         */
        private var m_scriptRoot:ScriptNode;
        
        /**
         * Mapping from a string id to a RenderComponent holding the view to the actual component
         */
        private var m_uiComponentManager:ComponentManager;
        
        private var m_editableTextArea:EditableTextArea;
        
        /**
         * The preview showing the bar model the player is trying to create a new problem for.
         */
        private var m_barModelArea:BarModelAreaWidget;
        
        /**
         * Utility class to draw the template model in the preview bar model view
         */
        private var m_barModelTypeDrawer:BarModelTypeDrawer;
        
        private var m_nativeFlashStage:Stage;
        
        /**
         * Clicking on this option will pause the game and open up an options overlay
         */
        private var m_optionsButton:OptionButton;
        private var m_buttonColorData:ButtonColorData;
        private var m_optionsScreen:OptionsScreen;
        
        private var m_config:AlgebraAdventureConfig;
        private var m_playerStatsAndSaveData:PlayerStatsAndSaveData;
        private var m_levelCompiler:LevelCompiler;
        
        public function WordProblemCreateState(stateMachine:IStateMachine, 
                                               flashStage:Stage, 
                                               mouseState:MouseState, 
                                               assetManager:AssetManager,
                                               gameServerRequester:GameServerRequester,
                                               levelCompiler:LevelCompiler,
                                               config:AlgebraAdventureConfig,
                                               playerStatsAndSaveData:PlayerStatsAndSaveData,
                                               buttonColorData:ButtonColorData)
        {
            super(stateMachine);
            
            m_nativeFlashStage = flashStage;
            m_assetManager = assetManager;
            m_gameServerRequester = gameServerRequester;
            m_mouseState = mouseState;
            m_buttonColorData = buttonColorData;
            
            m_config = config;
            m_playerStatsAndSaveData = playerStatsAndSaveData;
            m_levelCompiler = levelCompiler;
            
            m_time = new Time();
            m_barModelTypeDrawer = new BarModelTypeDrawer();
        }
        
        public function getCurrentLevel():ProblemCreateData
        {
            return m_problemCreateData;
        }
        
        override public function enter(fromState:Object, params:Vector.<Object>=null):void
        {
            Audio.instance.playMusic("bg_level_music");
            
            m_uiComponentManager = new ComponentManager();
            m_editableTextArea = new EditableTextArea(m_nativeFlashStage, m_assetManager, GameFonts.DEFAULT_FONT_NAME, 24, 0xFFFFFF);
            addUiComponent("editableTextArea", m_editableTextArea);
            
            m_scriptRoot = new ConcurrentSelector(-1);
            
            // Extra logic that should be constantly running while a level is active
            // (like highlighting parts of the level or displaying callouts on different pieces)
            var systems:ConcurrentSelector = new ConcurrentSelector(-1);
            var highlightSystem:HighlightSystem = new HighlightSystem(m_assetManager);
            systems.pushChild(highlightSystem);
            var calloutSystem:CalloutSystem = new CalloutSystem(m_assetManager, this.getSprite(), m_mouseState);
            systems.pushChild(calloutSystem);
            m_scriptRoot.pushChild(systems);
            
            // Script to control disabling ui from mouse events when components are layered on top of each other
            m_scriptRoot.pushChild(new Layering(this, m_mouseState));
            
            // When the key board for the alias script is running, we disable all other interactions
            var actionScripts:ConcurrentSelector = new ConcurrentSelector(-1);
            actionScripts.pushChild(new ChangeMouseOnHighlightActive(this, m_assetManager, m_mouseState, "ChangeMouseOnHighlightActive"));
            actionScripts.pushChild(new PickElementFromBarModel(this, m_assetManager, m_mouseState, "PickElementFromBarModel"));
            actionScripts.pushChild(new ShowBarModelPartDescription(this, m_assetManager, "ShowBarModelPartDescription"));
            actionScripts.pushChild(new HighlightProblemPartsScript(this, m_mouseState, m_assetManager, "HighlightProblemPartsScript"));
            actionScripts.pushChild(new ChangeTextAppearanceScript(this, m_assetManager, "ChangeTextAppearanceScript"));
            actionScripts.pushChild(new SubmitProblemScript(this, m_assetManager, m_gameServerRequester, "SubmitCreateProblemScript"));
            actionScripts.pushChild(new ChangeAliasScript(this, m_mouseState, m_assetManager, "ChangeAliasScript"));
            actionScripts.pushChild(new ChangeBarModelArea(this, "ChangeBarModelArea"));
            actionScripts.pushChild(new ShowExampleProblemScript(this, m_barModelTypeDrawer, m_assetManager, "ShowExampleProblemScript"));
            actionScripts.pushChild(new TestProblemScript(this, m_assetManager, m_mouseState, m_time, m_levelCompiler, m_config, m_playerStatsAndSaveData, "TestProblemScript"));
            actionScripts.pushChild(new PrepopulateTextScript(this));
            m_scriptRoot.pushChild(actionScripts);
            
            m_problemCreateData = params[0] as ProblemCreateData;
            
            var screenWidth:Number = 800;
            var screenHeight:Number = 600;
            
            m_optionsButton = new OptionButton(m_assetManager, m_buttonColorData.getUpButtonColor(), onOptionsClicked);
            m_optionsButton.x = 0;
            m_optionsButton.y = screenHeight - m_optionsButton.height;
            
            var sidePadding:Number = 100;
            var textAreaWidth:Number = screenWidth - 2 * sidePadding;
            var textAreaHeight:Number = 270;
            m_editableTextArea.setConstraints(textAreaWidth, textAreaHeight);
            
            var topPadding:Number = 50;
            var textAreaX:Number = (screenWidth - m_editableTextArea.getConstraints().width) * 0.5;
            var textAreaY:Number = topPadding;
            m_editableTextArea.setPosition(textAreaX , textAreaY);
            addChild(m_editableTextArea);
            
            // The example text area
            var exampleWordproblemTextArea:EditableTextArea = new EditableTextArea(
                m_nativeFlashStage, m_assetManager, GameFonts.DEFAULT_FONT_NAME, 24, 0xFFFFFF
            );
            exampleWordproblemTextArea.setConstraints(textAreaWidth, textAreaHeight);
            exampleWordproblemTextArea.setPosition(textAreaX, textAreaY);
            addUiComponent("exampleTextArea", exampleWordproblemTextArea);
            
            // The bottom frame should be a background image (note that there is some transparency at the
            // top of the image)
            var lowerUiContainer:Sprite = new Sprite();
            var transparencyPaddingOnImage:Number = 10;
            var bottomUiBackgroundTexture:Texture = m_assetManager.getTexture("ui_background");
            var bottomUiPadding:Number = 16;
            var bottomUiImage:Scale9Image = new Scale9Image(new Scale9Textures(bottomUiBackgroundTexture, new Rectangle(
                bottomUiPadding, bottomUiPadding, bottomUiBackgroundTexture.width - 2 * bottomUiPadding, bottomUiBackgroundTexture.height - 2 * bottomUiPadding
            )));
            bottomUiImage.width = screenWidth;
            bottomUiImage.height = screenHeight - m_editableTextArea.getConstraints().height - m_editableTextArea.y + transparencyPaddingOnImage;
            lowerUiContainer.y = m_editableTextArea.y + m_editableTextArea.getConstraints().height - transparencyPaddingOnImage;
            lowerUiContainer.addChild(bottomUiImage);
            addUiComponent("uiContainer", lowerUiContainer);
            addChild(lowerUiContainer);
            
            // Create an empty bar model to be later filled in with the template
            var barModelData:BarModelData = new BarModelData();
            var expressionSymbolMap:ExpressionSymbolMap = new ExpressionSymbolMap(m_assetManager);
            expressionSymbolMap.setConfiguration(CardAttributes.DEFAULT_CARD_ATTRIBUTES);
            
            var barModelAllowedWidth:Number = screenWidth - 2 * sidePadding;
            var barModelAllowedHeight:Number = 220;
            var padding:Number = 10;
            m_barModelArea = new BarModelAreaWidget(expressionSymbolMap, m_assetManager, 50, 40, 
                padding, padding, padding, padding, 10);
            m_barModelArea.setDimensions(barModelAllowedWidth, barModelAllowedHeight);
            lowerUiContainer.addChild(m_barModelArea);
            addUiComponent("barModelArea", m_barModelArea);
            
            // Attach bar model parts to the effects systems
            highlightSystem.addComponentManager(m_barModelArea.componentManager);
            calloutSystem.addComponentManager(m_barModelArea.componentManager);
            
            // Create a set of picker objects that allow the user to alter various appearence setting
            // for the text. (Need to be able to set the dimensions of the picker, right now the script is)
            // For the picker list need to reset the canvas from which the popup menu is derived from
            PopUpManager.root = this;
            var backgroundPicker:ScrollOptionsPicker = new ScrollOptionsPicker(m_assetManager, null);
            addUiComponent("backgroundPicker", backgroundPicker);

            // Layout the ui for highlight and changing the alias/value of parts of the bar model
            var barModelType:String = m_problemCreateData.barModelType;
            
            // We want labels using the card like image to have the same color as is defined for
            // the default style for the bar model type
            var expressionStyles:Object = m_barModelTypeDrawer.getStyleObjectForType(barModelType);
            var partNames:Vector.<String> = new Vector.<String>();
            for (var idForPart:String in expressionStyles)
            {
                // Alter the card colors to match with the colors in the style info
                var styleForPart:BarModelTypeDrawerProperties = expressionStyles[idForPart];
                //var symbolData:SymbolData = expressionSymbolMap.getSymbolDataFromValue(idForPart);   
                //symbolData.backgroundColor = styleForPart.color;
                
                // Can perform pre-processing of views since it will not change
                // once the state has loaded
                partNames.push(idForPart);
                
                // Instantiate the data
                m_problemCreateData.elementIdToDataMap[idForPart] = {
                    value: "",
                    highlighted: false  
                };
            }
            
            // Orient the bar model area such that it is below the text area and to the right of the toggle
            m_barModelArea.x = sidePadding;
            m_barModelArea.y = 20;
            
            // The button to submit the tagged contents
            // (Appears just below the example container)
            var disabledSubmitImage:Image = new Image(m_assetManager.getTexture("button_check_bar_model_up"));
            var greyScaleFilter:ColorMatrixFilter = new ColorMatrixFilter();
            greyScaleFilter.adjustSaturation(-1);
            disabledSubmitImage.filter = greyScaleFilter;
            var submitButtonWidthAndHeight:Number = 80;
            var submitButton:Button = WidgetUtil.createButtonFromImages(
                new Image(m_assetManager.getTexture("button_check_bar_model_up")),
                new Image(m_assetManager.getTexture("button_check_bar_model_down")),
                disabledSubmitImage,
                new Image(m_assetManager.getTexture("button_check_bar_model_over")), null, null);
            submitButton.width = submitButton.height = submitButtonWidthAndHeight;
            submitButton.pivotX = submitButton.width * 0.5;
            submitButton.pivotY = submitButton.height * 0.5;
            lowerUiContainer.addChild(submitButton);
            
            // Position to the left of the bar model and in the middle of the empty space
            var rightEdgeOfBarModel:Number = m_barModelArea.x + m_barModelArea.getConstraints().width;
            submitButton.x = rightEdgeOfBarModel + (screenWidth - rightEdgeOfBarModel) * 0.5;
            submitButton.y = m_barModelArea.y + submitButton.pivotY;
            addUiComponent("submitButton", submitButton);
            
            // Create a button of the margins on the side where the player can
            // press to view an example
            var buttonColor:uint = m_buttonColorData.getUpButtonColor();
            var showExampleWordProblemButton:Button = WidgetUtil.createGenericColoredButton(
                m_assetManager,
                buttonColor,
                "Show Example",
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0xFFFFFF),
                null
            );
            showExampleWordProblemButton.width = 90;
            showExampleWordProblemButton.height = 60;
            showExampleWordProblemButton.x = m_editableTextArea.x + m_editableTextArea.getConstraints().width;
            showExampleWordProblemButton.y = submitButton.y + submitButton.pivotY + 10;
            lowerUiContainer.addChild(showExampleWordProblemButton);
            addUiComponent("showExampleButton", showExampleWordProblemButton);
            
            // Create screen of options that pauses the game
            var optionsButtonWidth:Number = 150;
            var optionsButtonHeight:Number = 40;
            m_optionsScreen = new OptionsScreen(screenWidth, screenHeight, optionsButtonWidth, optionsButtonHeight, false, true,
                buttonColor, m_assetManager, onResume, onRestart, onSkip, forwardEvent, onExitToMainMenu);
            
            // Add options to the top
            addChild(m_optionsButton);
            
            // Button to launch a test version of the just created level
            var testProblemButton:Button = WidgetUtil.createGenericColoredButton(
                m_assetManager,
                buttonColor,
                "Test Problem",
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0xFFFFFF),
                null
            );
            testProblemButton.width = 90;
            testProblemButton.height = 60;
            testProblemButton.x = showExampleWordProblemButton.x;
            testProblemButton.y = showExampleWordProblemButton.y + showExampleWordProblemButton.height + 10;
            addUiComponent("testProblemButton", testProblemButton);
            
            lowerUiContainer.addChild(testProblemButton);
            
            this.dispatchEventWith(ProblemCreateEvent.PROBLEM_CREATE_INIT);
        }
        
        override public function exit(toState:Object):void
        {
            // Need to clean up all possible widgets and scripts
            var renderComponents:Vector.<Component> = m_uiComponentManager.getComponentListForType(RenderableComponent.TYPE_ID);
            for each (var renderComponent:RenderableComponent in renderComponents)
            {
                if (renderComponent.view)
                {
                    renderComponent.view.removeFromParent(true);
                }
            }
            m_uiComponentManager.clear();
            
            this.removeChildren(0, -1, true);
            m_scriptRoot.dispose();
        }
        
        override public function update(time:Time, mouseState:MouseState):void
        {
            m_time.update();
            
            // Clicking outside the wooden box for options should close the option
            if (m_optionsScreen.parent != null)
            {
                if (mouseState.leftMousePressedThisFrame)
                {
                    // Check for hit outside the wood box
                    var mouseX:Number = mouseState.mousePositionThisFrame.x;
                    var mouseY:Number = mouseState.mousePositionThisFrame.y;
                    var optionsBackground:DisplayObject = m_optionsScreen.getChildAt(1);
                    var rightEdge:Number = optionsBackground.width + optionsBackground.x;
                    var bottomEdge:Number = optionsBackground.height + optionsBackground.y;
                    if (mouseX < optionsBackground.x || mouseY < optionsBackground.y || mouseX > rightEdge || mouseY > bottomEdge)
                    {
                        closeOptions();
                    }
                }
            }
            else
            {
                m_editableTextArea.update(m_time);
                
                m_scriptRoot.visit();
            }
        }
        
        public function getWidgetFromId(id:String):DisplayObject
        {
            var widget:DisplayObject = null;
            var renderComponent:RenderableComponent = m_uiComponentManager.getComponentFromEntityIdAndType(
                id, RenderableComponent.TYPE_ID) as RenderableComponent;
            if (renderComponent != null)
            {
                widget = renderComponent.view;   
            }
            
            return widget;
        }
        
        private function addUiComponent(name:String, uiComponent:DisplayObject):void
        {
            var renderComponent:RenderableComponent = new RenderableComponent(name);
            renderComponent.view = uiComponent;
            m_uiComponentManager.addComponentToEntity(renderComponent);
        }
        
        private function onResume():void
        {
            var loggingDetails:Object = {buttonName:"ResumeButton"};
            dispatchEventWith(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, false, loggingDetails);
            
            closeOptions();
        }
        
        private function onRestart():void
        {
        }
        
        private function onSkip():void
        {
        }
        
        private function forwardEvent(event:Event, params:Object):void
        {
            dispatchEventWith(event.type, params);
        }
        
        private function onExitToMainMenu():void
        {
            dispatchEventWith(CommandEvent.LEVEL_QUIT_BEFORE_COMPLETION);
        }
        
        private function onOptionsClicked():void
        {
            Audio.instance.playSfx("button_click");
            var loggingDetails:Object = {buttonName:"OptionsButton"};
            dispatchEventWith(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, false, loggingDetails);
            
            // One important caveat since we have flash text fields that always appear on top, must make
            // sure the text areas are set to non-edit mode while the options screen is displayed
            m_editableTextArea.toggleEditMode(false);
            addChild(m_optionsScreen);
        }
        
        private function closeOptions():void
        {
            m_editableTextArea.toggleEditMode(true);
            m_optionsScreen.removeFromParent();  
        }
    }
}