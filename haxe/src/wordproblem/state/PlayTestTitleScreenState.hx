package wordproblem.state;


import flash.display.Stage;
import flash.geom.Rectangle;
import flash.text.TextFormat;

import cgs.CgsApi;
import cgs.login.LoginPopup;
import cgs.server.responses.CgsUserResponse;
import cgs.user.ICgsUser;

import dragonbox.common.expressiontree.compile.LatexCompiler;
import dragonbox.common.math.vectorspace.RealsVectorSpace;
import dragonbox.common.state.BaseState;
import dragonbox.common.state.IStateMachine;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

import feathers.controls.TextInput;
import feathers.controls.text.StageTextTextEditor;
import feathers.core.ITextEditor;

import starling.animation.Juggler;
import starling.display.Button;
import starling.display.Image;
import starling.events.Event;
import starling.textures.Texture;

import wordproblem.AlgebraAdventureConfig;
import wordproblem.account.RegisterStudentPlaytestState;
import wordproblem.account.RegisterTosScreen;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentFactory;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.systems.HelperCharacterRenderSystem;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.widget.WidgetUtil;
import wordproblem.event.CommandEvent;
import wordproblem.log.AlgebraAdventureLogger;
import wordproblem.resource.AssetManager;

/**
 * An extremely pruned down version of the title screen state.
 * 
 * At the very top left corner is a small area to enter the username, start logs in the player
 */
class PlayTestTitleScreenState extends BaseState
{
    private var m_assetManager : AssetManager;
    private var m_logger : AlgebraAdventureLogger;
    private var m_flashStage : Stage;
    private var m_config : AlgebraAdventureConfig;
    
    private var m_startButton : Button;
    private var m_textInput : TextInput;
    
    private var m_loginPopup : LoginPopup;
    
    /*
    Objects for the helper characters 
    */
    private var m_componentManager : ComponentManager;
    private var m_helpRenderSystem : HelperCharacterRenderSystem;
    
    private var m_registerAccountState : RegisterStudentPlaytestState;
    
    /**
     * Have a custom juggler that animates all spritesheets in this screen
     * (Right now just the hamster characters)
     */
    private var m_spritesheetJuggler : Juggler;
    
    public function new(stateMachine : IStateMachine,
            assetManager : AssetManager,
            logger : AlgebraAdventureLogger,
            flashStage : Stage,
            usernamePrefix : String,
            config : AlgebraAdventureConfig)
    {
        super(stateMachine);
        
        m_assetManager = assetManager;
        m_logger = logger;
        m_flashStage = flashStage;
        
        m_componentManager = new ComponentManager();
        
        var componentFactory : ComponentFactory = new ComponentFactory(new LatexCompiler(new RealsVectorSpace()));
        var characterData : Dynamic = assetManager.getObject("characters");
        componentFactory.createAndAddComponentsForItemList(m_componentManager, characterData.charactersTitle);
        
        m_spritesheetJuggler = new Juggler();
        m_helpRenderSystem = new HelperCharacterRenderSystem(assetManager, m_spritesheetJuggler, this.getSprite());
        
        m_startButton = WidgetUtil.createButton(
                        assetManager,
                        "button_green_up",
                        "button_green_over",
                        null,
                        "button_green_over",
                        "START",
                        new TextFormat(GameFonts.DEFAULT_FONT_NAME, 36, 0x000000),
                        null,
                        new Rectangle(16, 16, 36, 36)
                        );
        m_startButton.width = 250;
        m_startButton.height = 110;
        m_startButton.x = (800 - 250) * 0.5;
        m_startButton.y = 280;
        
        m_textInput = new TextInput();
        m_textInput.height = 70;
        m_textInput.width = 300;
        m_textInput.x = (800 - m_textInput.width) * 0.5;
        m_textInput.y = 200;
        
        var backgroundTexture : Texture = m_assetManager.getTexture("button_white");
        var padding : Float = 10;
        var textInputBackground : Image = new Image(Texture.fromTexture(backgroundTexture, 
			new Rectangle(padding, padding, backgroundTexture.width - 2 * padding, backgroundTexture.height - 2 * padding)));
        textInputBackground.color = 0x000000;
        m_textInput.backgroundSkin = textInputBackground;
        m_textInput.textEditorFactory = function() : ITextEditor
                {
                    var editor : StageTextTextEditor = new StageTextTextEditor();
                    editor.fontFamily = GameFonts.DEFAULT_FONT_NAME;
                    editor.fontSize = 36;
                    editor.color = 0xFFFFFF;
                    return editor;
                };
        if (usernamePrefix != null) 
        {
            m_textInput.text = usernamePrefix;
        }
        
        m_logger = logger;
        m_config = config;
    }
    
    override public function enter(fromState : Dynamic, params : Array<Dynamic> = null) : Void
    {
        var backgroundTexture : Texture = m_assetManager.getTexture("login_background");
        addChild(new Image(backgroundTexture));
        
        addChild(m_startButton);
        m_startButton.addEventListener(Event.TRIGGERED, onStartButtonClick);
        
        addChild(m_textInput);
        
        var cgsApi : CgsApi = m_logger.getCgsApi();
        var loginPopup : LoginPopup = cgsApi.createUserLoginDialog(
                m_logger.getCgsUserProperties(true, null),
                onUserLoginSucceed,
                true,
                null
                );
        loginPopup.teacherCode = m_config.getTeacherCode();
        loginPopup.setLoginFailCallback(onUserLoginFail);
        m_loginPopup = loginPopup;
    }
    
    override public function exit(toState : Dynamic) : Void
    {
        while (numChildren > 0)
        {
            removeChildAt(0);
        }  // Kill the characters  
        
        
        
        var renderComponents : Array<Component> = m_componentManager.getComponentListForType(RenderableComponent.TYPE_ID);
        var renderComponent : RenderableComponent = null;
        var i : Int = 0;
        var components : Int = renderComponents.length;
        for (i in 0...components){
            renderComponent = try cast(renderComponents[i], RenderableComponent) catch(e:Dynamic) null;
            if (renderComponent.view != null) 
            {
                renderComponent.view.removeFromParent();
            }
        }
        
        m_startButton.removeEventListener(Event.TRIGGERED, onStartButtonClick);
    }
    
    override public function update(time : Time,
            mouseState : MouseState) : Void
    {
        // Advance juggler timer
        m_spritesheetJuggler.advanceTime(time.currentDeltaSeconds);
        
        m_helpRenderSystem.update(m_componentManager);
    }
    
    private function onStartButtonClick() : Void
    {
        var loginName : String = m_textInput.text;
        m_loginPopup.username = loginName;
        m_loginPopup.password = "";
        m_loginPopup.attemptLogin();
        dispatchEventWith(CommandEvent.WAIT_SHOW);
    }
    
    /**
     * Callback fired once an exisiting user has been successfully authenticated
     */
    private function onUserLoginSucceed(response : CgsUserResponse) : Void
    {
        if (response.success) 
        {
            var dataLoaded : Bool = response.dataLoadSuccess;
            if (dataLoaded) 
                { }
            else 
            {
                // TODO:
                // If the save data fails to load, we should show an error message to the user
                
            }
            
            var user : ICgsUser = response.cgsUser;
            var cgsApi : CgsApi = m_logger.getCgsApi();
            
            // See if the user still needs to accept a tos
            if (user.tosRequired && !user.tosStatus.accepted) 
            {
                var tosScreen : RegisterTosScreen = new RegisterTosScreen(
                user, 
                function() : Void
                {
                    tosScreen.dispose();
                    m_flashStage.removeChild(tosScreen);
                    dispatchEventWith(CommandEvent.WAIT_HIDE);
                    dispatchEventWith(CommandEvent.USER_AUTHENTICATED);
                }, 
                800, 
                600, 
                );
                m_flashStage.addChild(tosScreen);
            }
            else 
            {
                // On login, if the user is not anonymous and we are linked to dragonbox
                // Then we may need to poll the player's dragonbox save data to fetch information
                // that should be imported over to this game. For example rewards.
                dispatchEventWith(CommandEvent.WAIT_HIDE);
                dispatchEventWith(CommandEvent.USER_AUTHENTICATED);
            }
        }
    }
    
    private function onUserLoginFail(response : CgsUserResponse) : Void
    {
        // On fail prompt the user to create an account
        // (However keep the username hidden)
        // Create the register state for playtest student (don't create dummy user
        var cgsApi : CgsApi = m_logger.getCgsApi();
        m_registerAccountState = new RegisterStudentPlaytestState(
                null, 
                m_config, 
                cgsApi, 
                m_logger.getChallengeService(), 
                m_logger.getCgsUserProperties(m_config.getSaveDataToServer(), m_config.getSaveDataKey()), 
                onRegisterCancel, 
                onRegisterComplete, 
                m_textInput.text, 
                "Create an account to earn a prize!", 
                );
        m_flashStage.addChild(m_registerAccountState);
    }
    
    private function onRegisterComplete(user : ICgsUser) : Void
    {
        m_logger.setCgsUser(user, -1);
        dispatchEventWith(CommandEvent.WAIT_HIDE);
        dispatchEventWith(CommandEvent.USER_AUTHENTICATED);
        
        m_flashStage.removeChild(m_registerAccountState);
        m_registerAccountState.dispose();
    }
    
    private function onRegisterCancel() : Void
    {
    }
}
