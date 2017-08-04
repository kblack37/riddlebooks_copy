package gameconfig.versions.challengedemo;


import flash.display.Stage;
import flash.geom.Rectangle;
import flash.net.SharedObject;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

import cgs.CgsApi;
import cgs.audio.Audio;
import cgs.internationalization.StringTable;
import cgs.server.responses.CgsResponseStatus;
import cgs.server.responses.CgsUserResponse;
import cgs.user.CgsUserProperties;

import dragonbox.common.expressiontree.compile.LatexCompiler;
import dragonbox.common.math.vectorspace.RealsVectorSpace;
import dragonbox.common.state.BaseState;
import dragonbox.common.state.IStateMachine;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;
import dragonbox.common.util.XColor;

import feathers.controls.Button;
import feathers.controls.TextInput;
import feathers.controls.text.TextFieldTextEditor;
import feathers.core.ITextEditor;

import fl.controls.ComboBox;
import fl.data.DataProvider;

import starling.animation.Juggler;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Quad;
import starling.events.Event;
import starling.text.TextField;
import starling.textures.Texture;

import wordproblem.credits.CreditsWidget;
import wordproblem.engine.component.ComponentFactory;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.systems.HelperCharacterRenderSystem;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.widget.ConfirmationWidget;
import wordproblem.engine.widget.WidgetUtil;
import wordproblem.event.CommandEvent;
import wordproblem.log.AlgebraAdventureLogger;
import wordproblem.resource.AssetManager;
import wordproblem.settings.OptionsWidget;

/**
 * For the demo to be given to teachers, we do not care about persistent login since everything
 * will be unlocked anyways. We do care about a grade specification as problem contents will slightly
 * vary for each of the different grades. Have a ui piece for selecting a grade.
 * 
 * For simplicity just use the default flash drop down picker
 */
class WordProblemGameChallengeDemoLogin extends BaseState
{
    private static var GRADES : Array<Dynamic> = new Array<Dynamic>(
        {
            label : "1st",
            data : 1,

        }, 
        {
            label : "2nd",
            data : 2,

        }, 
        {
            label : "3rd",
            data : 3,

        }, 
        {
            label : "4th",
            data : 4,

        }, 
        {
            label : "5th",
            data : 5,

        }, 
        {
            label : "6th",
            data : 6,

        }, 
        {
            label : "7th",
            data : 7,

        }, 
        {
            label : "8th",
            data : 8,

        }, 
        {
            label : "9th",
            data : 9,

        }, 
        {
            label : "10th",
            data : 10,

        }, 
        {
            label : "11th",
            data : 11,

        }, 
        {
            label : "12th",
            data : 12,

        }, 
        );
    
    private var m_assetManager : AssetManager;
    
    private var m_logger : AlgebraAdventureLogger;
    
    /**
     * HACK: To test accounts
     */
    private var m_userNameInput : TextInput;
    
    private var m_continueGameButton : Button;
    
    /**
     * Start a brand new game using the username in the text if appropriate
     */
    private var m_newGameButton : Button;
    
    /**
     * Have a custom juggler that animates all spritesheets in this screen
     * (Right now just the hamster characters)
     */
    private var m_spritesheetJuggler : Juggler;
    
    /**
     * Components on the characters
     */
    private var m_componentManager : ComponentManager;
    
    /**
     * Drawing system for the characters
     */
    private var m_helpRenderSystem : HelperCharacterRenderSystem;
    
    private var m_options : OptionsWidget;
    
    /**
     * Screen to show credits
     */
    private var m_credits : CreditsWidget;
    
    /**
     * Since we want every player to be assigned as a student, we need some dummy teacher
     * that will link to them.
     */
    private var m_teacherCode : String;
    private var m_saveCacheKey : String;
    private var m_saveDataToServer : Bool;
    
    /**
     * Prompt user if they are ok with losing previous save data by starting a new game
     */
    private var m_newGameConfirmationWidget : ConfirmationWidget;
    
    /**
     * We keep a reference to the local storage.
     * 
     * "userData"->
     * uid
     */
    private var m_localSharedObject : SharedObject;
    
    /**
     * Used to override behavior when the user clicks to start a new game.
     */
    private var m_newGameCallback : Function;
    
    private var m_nativeFlashStage : Stage;
    private var m_gradeComboBox : ComboBox;
    
    public function new(stateMachine : IStateMachine,
            assetManager : AssetManager,
            teacherCode : String,
            saveCacheKey : String,
            saveDataToServer : Bool,
            logger : AlgebraAdventureLogger,
            nativeFlashStage : Stage,
            customOnNewGameCallback : Function = null)
    {
        super(stateMachine);
        
        m_assetManager = assetManager;
        m_teacherCode = teacherCode;
        m_saveCacheKey = saveCacheKey;
        m_saveDataToServer = saveDataToServer;
        m_logger = logger;
        m_nativeFlashStage = nativeFlashStage;
        
        m_newGameCallback = customOnNewGameCallback;
        
        m_localSharedObject = SharedObject.getLocal("wordproblem_user");
        
        m_userNameInput = new TextInput();
        m_userNameInput.textEditorFactory = function() : ITextEditor
                {
                    var editor : TextFieldTextEditor = new TextFieldTextEditor();
                    editor.textFormat = new TextFormat("Verdana", 14, 0x0, null, null, null, null, null, TextFormatAlign.CENTER);
                    editor.embedFonts = false;
                    return editor;
                };
        m_userNameInput.width = 100;
        m_userNameInput.height = 50;
        m_userNameInput.backgroundSkin = new Quad(m_userNameInput.width, m_userNameInput.height, 0xFFFFFF);
        
        m_componentManager = new ComponentManager();
        
        var componentFactory : ComponentFactory = new ComponentFactory(new LatexCompiler(new RealsVectorSpace()));
        var characterData : Dynamic = assetManager.getObject("characters");
        componentFactory.createAndAddComponentsForItemList(m_componentManager, characterData.charactersTitle);
        
        m_spritesheetJuggler = new Juggler();
        m_helpRenderSystem = new HelperCharacterRenderSystem(assetManager, m_spritesheetJuggler, this.getSprite());
        
        var screenWidth : Float = 800;
        var screenHeight : Float = 600;
        
        // Screen to show credits
        var creditsWidget : CreditsWidget = new CreditsWidget(
        screenWidth, 
        screenHeight, 
        m_assetManager, 
        function() : Void
        {
            m_gradeComboBox.visible = true;
        }, 
        XColor.ROYAL_BLUE, 
        );
        m_credits = creditsWidget;
        
        // Screen to confirm whether starting a new game is okay
        var confirmationWidget : ConfirmationWidget = new ConfirmationWidget(
        screenWidth, 
        screenHeight, 
        function() : DisplayObject
        {
            var contentTextField : TextField = new TextField(
            400, 
            200, 
            StringTable.lookup("start_new_warning"), 
            GameFonts.DEFAULT_FONT_NAME, 
            28, 
            0xFFFFFF, 
            );
            return contentTextField;
        }, 
        function() : Void
        {
            // Continue with starting new game
            removeChild(m_newGameConfirmationWidget);
            m_gradeComboBox.visible = true;
            m_newGameCallback();
        }, 
        function() : Void
        {
            // Decline
            removeChild(m_newGameConfirmationWidget);
            m_gradeComboBox.visible = true;
        }, 
        m_assetManager, XColor.ROYAL_BLUE, StringTable.lookup("yes"), StringTable.lookup("no"), 
        );
        m_newGameConfirmationWidget = confirmationWidget;
    }
    
    override public function enter(fromState : Dynamic, params : Array<Dynamic> = null) : Void
    {
        // Play background music
        Audio.instance.playMusic("bg_home_music");
        
        var maxWidth : Float = 800;
        var maxHeight : Float = 600;
        
        // Create the options on top
        var optionsWidget : OptionsWidget = new OptionsWidget(
        m_assetManager, 
        [OptionsWidget.OPTION_MUSIC, OptionsWidget.OPTION_SFX, OptionsWidget.OPTION_CREDITS], 
        onCreditsClicked, 
        null, 
        XColor.ROYAL_BLUE, 
        );
        optionsWidget.x = 0;
        optionsWidget.y = maxHeight - optionsWidget.height;
        addChild(optionsWidget);
        m_options = optionsWidget;
        
        var bgTexture : Texture = m_assetManager.getTexture("login_background_with_ui.png");
        addChildAt(new Image(bgTexture), 0);
        
        // Create a button to continue IF a user id was saved in the cache
        var baseContinueGameButtonTexture : Texture = m_assetManager.getTexture("button_green_up.png");
        var buttonTexturePadding : Float = 16;
        var nineSliceGrid : Rectangle = new Rectangle(
        buttonTexturePadding, 
        buttonTexturePadding, 
        baseContinueGameButtonTexture.width - 2 * buttonTexturePadding, 
        baseContinueGameButtonTexture.height - 2 * buttonTexturePadding, 
        );
        
        // Create a button to register as a new student that auto-assigns a username
        var baseNewGameButtonTexture : Texture = m_assetManager.getTexture("button_green_up.png");
        buttonTexturePadding = 16;
        nineSliceGrid = new Rectangle(
                buttonTexturePadding, 
                buttonTexturePadding, 
                baseNewGameButtonTexture.width - 2 * buttonTexturePadding, 
                baseNewGameButtonTexture.height - 2 * buttonTexturePadding, 
                );
        m_newGameButton = WidgetUtil.createButton(
                        m_assetManager,
                        "button_green_up",
                        "button_green_over",
                        null,
                        "button_green_over",
                        "Start",
                        new TextFormat(GameFonts.DEFAULT_FONT_NAME, 36, 0x000000),
                        null,
                        nineSliceGrid
                        );
        m_newGameButton.width = 330;
        m_newGameButton.addEventListener(Event.TRIGGERED, onNewGameClick);
        m_newGameButton.y = (maxHeight - baseContinueGameButtonTexture.height) * 0.5;
        m_newGameButton.x = (maxWidth - m_newGameButton.width) * 0.5;
        addChild(m_newGameButton);
        
        m_continueGameButton = WidgetUtil.createButton(
                        m_assetManager,
                        "button_green_up",
                        "button_green_over",
                        null,
                        "button_green_over",
                        "Continue",
                        new TextFormat(GameFonts.DEFAULT_FONT_NAME, 36, 0x000000),
                        null,
                        nineSliceGrid
                        );
        m_continueGameButton.width = 330;
        m_continueGameButton.addEventListener(Event.TRIGGERED, onContinue);
        m_continueGameButton.y = 0;
        m_continueGameButton.x = 0;
        addChild(m_continueGameButton);
        
        var gradeLabel : TextField = new TextField(100, 50, "Grade:", GameFonts.DEFAULT_FONT_NAME, 28, 0xFFFFFF);
        gradeLabel.x = 300;
        gradeLabel.y = 400;
        addChild(gradeLabel);
        
        var gradeComboBoxWidth : Float = 100;
        var comboBox : ComboBox = new ComboBox();
        comboBox.dataProvider = new DataProvider(GRADES);
        comboBox.dropdownWidth = gradeComboBoxWidth;
        comboBox.selectedIndex = 3;
        comboBox.x = gradeLabel.x + gradeLabel.width;
        comboBox.y = gradeLabel.y;
        
        var fontName : String = GameFonts.DEFAULT_INPUT_FONT_NAME;
        comboBox.textField.setStyle("textFormat", new TextFormat(fontName, 22, 0x000000, null, null, null, null, null, TextFormatAlign.CENTER));  // Text format of main button  
        comboBox.textField.setStyle("embedFonts", true);
        comboBox.dropdown.setRendererStyle("textFormat", new TextFormat(fontName, 18, 0x000000, null, null, null, null, null, TextFormatAlign.CENTER));  // Text format of drop down list  
        comboBox.dropdown.setRendererStyle("embedFonts", GameFonts.getFontIsEmbedded(fontName));
        comboBox.setStyle("textPadding", 10);
        comboBox.setStyle("embedFonts", GameFonts.getFontIsEmbedded(fontName));
        comboBox.dropdown.rowHeight = 30;
        comboBox.setSize(gradeComboBoxWidth, 50);
        m_gradeComboBox = comboBox;
        
        m_nativeFlashStage.addChild(comboBox);
        
        // HACK
        m_userNameInput.y = m_continueGameButton.y + 100;
        addChild(m_userNameInput);
    }
    
    override public function exit(toState : Dynamic) : Void
    {
        m_newGameButton.removeEventListener(Event.TRIGGERED, onNewGameClick);
        
        if (m_gradeComboBox != null && m_gradeComboBox.parent) 
        {
            m_gradeComboBox.parent.removeChild(m_gradeComboBox);
            m_gradeComboBox.close();
            m_gradeComboBox = null;
        }
        
        while (numChildren > 0)
        {
            removeChildAt(0);
        }
    }
    
    override public function update(time : Time,
            mouseState : MouseState) : Void
    {
        m_spritesheetJuggler.advanceTime(time.currentDeltaSeconds);
        m_helpRenderSystem.update(m_componentManager);
        
        // If click outside the bounds of the options, the options menu should close
        if (mouseState.leftMousePressedThisFrame && m_options.isOpen()) 
        {
            var optionBounds : Rectangle = m_options.getBounds(m_options.stage);
            if (!optionBounds.contains(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y)) 
            {
                m_options.toggleOptionsOpen(false);
            }
        }
    }
    
    private function onNewGameClick() : Void
    {
        Audio.instance.playSfx("button_click");
        
        // Create a new student user (need to fetch an available user id from the server and use that
        // to help create the dummy account)
        /*
        m_gradeComboBox.visible = false;
        var selectedGradeData:int = m_gradeComboBox.selectedItem.data;
        dispatchEventWith(CommandEvent.USER_AUTHENTICATED, false, {grade: selectedGradeData});
        */
        var cgsApi : CgsApi = m_logger.getCgsApi();
        var cgsUserProperties : CgsUserProperties = m_logger.getCgsUserProperties(m_saveDataToServer, m_saveCacheKey);
        m_logger.getCgsApi().registerStudent(cgsUserProperties, m_userNameInput.text, m_teacherCode, 0, onCreateAnonymousUserAccount);
    }
    
    private function onCreditsClicked() : Void
    {
        m_gradeComboBox.visible = false;
        addChild(m_credits);
    }
    /*
    The grade combo box is attached into the native flash stage, which means it will always
    appear on top of everything. Need to hide the combo box whenever another screen pops up.
    */
    private function onCreateAnonymousUserAccount(response : CgsResponseStatus) : Void
    {
        dispatchEventWith(CommandEvent.WAIT_HIDE);
        
        m_gradeComboBox.visible = false;
        var selectedGradeData : Int = m_gradeComboBox.selectedItem.data;
        dispatchEventWith(CommandEvent.USER_AUTHENTICATED, false, {
                    grade : selectedGradeData

                });
    }
    
    private function onContinue() : Void
    {
        var username : String = m_userNameInput.text;
        var password : String = null;
        
        var cgsApi : CgsApi = m_logger.getCgsApi();
        cgsApi.authenticateStudent(m_logger.getCgsUserProperties(m_saveDataToServer, m_saveCacheKey), username, m_teacherCode, password, 0, onAuthenticateStudent);
        dispatchEventWith(CommandEvent.WAIT_SHOW);
    }
    
    private function onAuthenticateStudent(userResponse : CgsUserResponse) : Void
    {
        if (userResponse.success) 
        {
            m_gradeComboBox.visible = false;
            var selectedGradeData : Int = m_gradeComboBox.selectedItem.data;
            dispatchEventWith(CommandEvent.USER_AUTHENTICATED, false, {
                        grade : selectedGradeData

                    });
        }
        else 
        {
            // Login failed
            
        }
        
        dispatchEventWith(CommandEvent.WAIT_HIDE);
    }
}



