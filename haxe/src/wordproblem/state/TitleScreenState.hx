package wordproblem.state;


import flash.display.DisplayObject;
import flash.display.Stage;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFormat;

import cgs.CgsApi;
import cgs.audio.Audio;
import cgs.login.LoginPopup;
import cgs.server.responses.CgsUserResponse;
import cgs.user.ICgsUser;

import dragonbox.common.expressiontree.compile.LatexCompiler;
import dragonbox.common.math.vectorspace.RealsVectorSpace;
import dragonbox.common.state.BaseState;
import dragonbox.common.state.IStateMachine;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;
import dragonbox.common.ui.TextButton;
import dragonbox.common.util.XColor;

import fl.controls.Button;
import fl.controls.TextInput;

import starling.animation.Juggler;
import starling.display.Image;
import starling.display.Quad;
import starling.textures.Texture;

import wordproblem.AlgebraAdventureConfig;
import wordproblem.account.RegisterAccountState;
import wordproblem.account.RegisterTosScreen;
import wordproblem.credits.CreditsWidget;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentFactory;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.systems.HelperCharacterRenderSystem;
import wordproblem.engine.text.GameFonts;
import wordproblem.event.CommandEvent;
import wordproblem.log.AlgebraAdventureLogger;
import wordproblem.resource.AssetManager;
import wordproblem.settings.OptionsWidget;

/**
 * This is the first page that the player sees when they first load up the application.
 * 
 * This screen contains the login prompt and will force the user to go through the
 * authentication process before they are allowed to continue.
 * 
 * THIS IS IMPORTANT:
 * Player specific information may be important for other parts of the game to set up properly
 * 
 * A piece of this that is tricky is that the login popup relies on flash display objects, meaning that they can only be
 * added onto the flash stage. This means that the login popup will always appear on top of all the Stage3D content.
 */
class TitleScreenState extends BaseState
{
    /*
    A consequence of need flash display resources is that the raw image classes needed to style the
    popup are not naturally accessible through the asset manager. We need to embed them directly into this class.
    */
    @:meta(Embed(source="/../assets/ui/login/button_disabled.png"))

    public static var button_disabled : Class<Dynamic>;
    @:meta(Embed(source="/../assets/ui/login/button_purple_up.png"))

    public static var button_purple_up : Class<Dynamic>;
    @:meta(Embed(source="/../assets/ui/login/button_purple_over.png"))

    public static var button_purple_over : Class<Dynamic>;
    @:meta(Embed(source="/../assets/ui/login/button_green_up.png"))

    public static var button_green_up : Class<Dynamic>;
    @:meta(Embed(source="/../assets/ui/login/button_green_hover.png"))

    public static var button_green_hover : Class<Dynamic>;
    @:meta(Embed(source="/../assets/ui/login/text_input_background.png"))

    public static var text_input_background : Class<Dynamic>;
    
    /**
     * Fetch image texture to be placed on the Stage3D layer.
     */
    private var m_assetManager : AssetManager;
    
    /**
     * This is the primary interface from which the player
     */
    private var m_logger : AlgebraAdventureLogger;
    
    /**
     * The login ui components are flash based, meaning they must be added to the flash stage.
     */
    private var m_flashStage : flash.display.Stage;
    
    /**
     * Need to hold reference to a popup since need to properly dispose it during potentially separate
     * frames of execution.
     */
    private var m_loginPopup : LoginPopup;
    
    /**
     * Mainly need this to get at logging settings
     */
    private var m_config : AlgebraAdventureConfig;
    
    /**
     * Registration becomes easier if we assume there is an existing anonymous user in which we can bind
     * the account to. If a player attempts to register a new account we create the dummy user.
     * 
     * Re-use this if they back out and select play now. However, this gets discarded if they login with a real account
     */
    private var m_dummyAnonymousUser : ICgsUser;
    
    /**
     * If true, the game should automatically try to login as soon as it enters this screen
     */
    private var m_autoLogin : Bool;
    
    /**
     * Username if the player should automatically login
     */
    private var m_autoLoginUsername : String;
    
    /**
     * Password if the player should automatically login, can be null if login requires no password
     */
    private var m_autoLoginPassword : String;
    
    /**
     * This is the sequence of screens the player must navigate through to finish the account registration process
     */
    private var m_registerAccountState : RegisterAccountState;
    
    /*
    Extra ui pieces
    */
    
    /**
     * Options to adjust audio and view credits
     */
    private var m_options : OptionsWidget;
    
    /**
     * Keep reference to extra ui pieces added to flash stage
     */
    private var m_flashStageObjects : Array<Dynamic>;
    
    /**
     * Button for the player to create a new account
     */
    private var m_signUpButton : fl.controls.Button;
    
    /**
     * Button for the player to start playing without an account
     */
    private var m_playNowButton : TextButton;
    
    /**
     * Screen to show credits
     */
    private var m_credits : CreditsWidget;
    
    /*
    Objects for the helper characters 
    */
    private var m_componentManager : ComponentManager;
    private var m_helpRenderSystem : HelperCharacterRenderSystem;
    
    /**
     * This setting toggle whether the player is allowed to play as a guest
     */
    private var m_allowGuest : Bool;
    
    /**
     * This setting toggles whether the player should be allowed to go through the manual sign up process
     */
    private var m_allowSignup : Bool;
    
    /**
     * The initial value to put in the username textfield (used to simplify login for playtest)
     * Null if nothing should be used
     */
    private var m_usernamePrefix : String;
    
    /**
     * Have a custom juggler that animates all spritesheets in this screen
     * (Right now just the hamster characters)
     */
    private var m_spritesheetJuggler : Juggler;
    
    /**
     *
     * @param logger
     *      The login process has a dependency on the cgs master accounts and the common api as a result
     * @param flashStage
     *      The ui components for the login can only be added to the flash stage since they are based on
     *      flash display components.
     */
    public function new(stateMachine : IStateMachine,
            assetManager : AssetManager,
            logger : AlgebraAdventureLogger,
            config : AlgebraAdventureConfig,
            flashStage : flash.display.Stage,
            autoLogin : Bool,
            autoLoginUsername : String,
            autoLoginPassword : String,
            allowGuest : Bool,
            allowSignup : Bool,
            usernamePrefix : String)
    {
        super(stateMachine);
        
        m_assetManager = assetManager;
        m_logger = logger;
        m_config = config;
        m_flashStage = flashStage;
        
        m_autoLogin = autoLogin;
        m_autoLoginUsername = autoLoginUsername;
        m_autoLoginPassword = autoLoginPassword;
        
        m_allowGuest = allowGuest;
        m_allowSignup = allowSignup;
        m_usernamePrefix = usernamePrefix;
        
        m_componentManager = new ComponentManager();
        
        var componentFactory : ComponentFactory = new ComponentFactory(new LatexCompiler(new RealsVectorSpace()));
        var characterData : Dynamic = assetManager.getObject("characters");
        componentFactory.createAndAddComponentsForItemList(m_componentManager, characterData.charactersTitle);
        
        m_spritesheetJuggler = new Juggler();
        m_helpRenderSystem = new HelperCharacterRenderSystem(assetManager, m_spritesheetJuggler, this.getSprite());
    }
    
    override public function enter(fromState : Dynamic, params : Array<Dynamic> = null) : Void
    {
        var cgsApi : CgsApi = m_logger.getCgsApi();
        
        showLoginPopup();
        
        var firstTimePlayText : TextField = new TextField();
        firstTimePlayText.defaultTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF, null, null, false);
        firstTimePlayText.embedFonts = true;
        firstTimePlayText.selectable = false;
        firstTimePlayText.text = "First time playing?";
        firstTimePlayText.x = 255;
        firstTimePlayText.y = 180;
        firstTimePlayText.width = firstTimePlayText.textWidth + 10;
        firstTimePlayText.height = firstTimePlayText.textHeight;
        m_flashStage.addChild(firstTimePlayText);
        
        var signUpHereText : TextField = new TextField();
        signUpHereText.defaultTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 32, 0xD38AE3, null, null, false);
        signUpHereText.embedFonts = true;
        signUpHereText.selectable = false;
        signUpHereText.text = "Sign Up Here!";
        signUpHereText.x = 257;
        signUpHereText.y = 207;
        signUpHereText.width = signUpHereText.textWidth + 15;
        signUpHereText.height = signUpHereText.textHeight;
        m_flashStage.addChild(signUpHereText);
        
        m_signUpButton = new fl.controls.Button();
        m_signUpButton.setStyle("upSkin", TitleScreenState.button_green_up);
        m_signUpButton.setStyle("overSkin", TitleScreenState.button_green_hover);
        m_signUpButton.setStyle("downSkin", TitleScreenState.button_green_hover);
        //button.setStyle("disabledSkin", button_disabled);
        m_signUpButton.setStyle("textFormat", new TextFormat(GameFonts.DEFAULT_FONT_NAME, 32, 0x000000, null, null, false));
        m_signUpButton.setStyle("embedFonts", true);
        m_signUpButton.label = "START";
        m_signUpButton.width = 170;
        m_signUpButton.height = 66;
        m_signUpButton.x = 283;
        m_signUpButton.y = 251;
        m_signUpButton.addEventListener(MouseEvent.CLICK, onSignUpButtonClick);
        m_flashStage.addChild(m_signUpButton);
        if (!m_allowSignup) 
        {
            m_signUpButton.enabled = false;
        }
        
        m_playNowButton = new TextButton();
        m_playNowButton.textFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, 0x5CBFF8, null, null, false);
        m_playNowButton.hoverTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, 0xFFFFFF, null, null, true);
        m_playNowButton.embedFonts = true;
        m_playNowButton.x = m_loginPopup.x;
        m_playNowButton.y = m_loginPopup.y + m_loginPopup.height * 0.5;
        m_flashStage.addChild(m_playNowButton);
        if (m_allowGuest) 
        {
            m_playNowButton.text = "Skip & Play as Guest";
            m_playNowButton.addEventListener(MouseEvent.CLICK, onPlayNowClick);
        }
        else 
        {
            m_playNowButton.mouseChildren = false;
            m_playNowButton.mouseEnabled = false;
        }
        
        m_flashStageObjects = [firstTimePlayText, signUpHereText, m_loginPopup, m_signUpButton, m_playNowButton];
        
        // Play background music
        Audio.instance.playMusic("bg_home_music");
        
        // Create the options on top
        var optionsWidget : OptionsWidget = new OptionsWidget(
        m_assetManager, 
        [OptionsWidget.OPTION_MUSIC, OptionsWidget.OPTION_SFX, OptionsWidget.OPTION_CREDITS], 
        function() : Void
        {
            // Since flash display objects appear on top, make them not visible while credits open
            var i : Int;
            for (i in 0...m_flashStageObjects.length){
                m_flashStageObjects[i].visible = false;
            }
            
            addChild(m_credits);
        }, 
        null, 
        XColor.ROYAL_BLUE, 
        );
        optionsWidget.y = 600 - optionsWidget.height;
        addChild(optionsWidget);
        m_options = optionsWidget;
        
        // Show credits
        m_credits = new CreditsWidget(
                800, 
                600, 
                m_assetManager, 
                function() : Void
                {
                    // Re-enable visibility of flash stage objects
                    var i : Int;
                    for (i in 0...m_flashStageObjects.length){
                        m_flashStageObjects[i].visible = true;
                    }
                }, 
                XColor.ROYAL_BLUE, 
                );
        
        var bgTexture : Texture = ((m_autoLogin)) ? 
        m_assetManager.getTexture("login_background") : m_assetManager.getTexture("login_background_with_ui");
        addChildAt(new Image(bgTexture), 0);
        
        if (m_autoLogin) 
        {
            // On autologin remove all ui pieces from view as they are not
            // interactable anyways
            var i : Int;
            for (i in 0...m_flashStageObjects.length){
                m_flashStageObjects[i].visible = false;
            }
            optionsWidget.visible = false;
            
            if (m_autoLoginUsername != null) 
            {
                m_loginPopup.username = m_autoLoginUsername;
                m_loginPopup.password = m_autoLoginPassword;
                m_loginPopup.attemptLogin();
                
                dispatchEventWith(CommandEvent.WAIT_SHOW);
            }
            else 
            {
                loginAnonymousUser();
            }
        }
    }
    
    override public function exit(toState : Dynamic) : Void
    {
        m_signUpButton.removeEventListener(MouseEvent.CLICK, onSignUpButtonClick);
        m_playNowButton.removeEventListener(MouseEvent.CLICK, onPlayNowClick);
        m_flashStage.removeChild(m_signUpButton);
        m_flashStage.removeChild(m_playNowButton);
        
        for (flashStageObject in m_flashStageObjects)
        {
            if (flashStageObject != null && flashStageObject.parent) 
            {
                flashStageObject.parent.removeChild(flashStageObject);
            }
        }
        
        while (numChildren > 0)
        {
            removeChildAt(0);
        }  // Kill the characters  
        
        
        
        var renderComponents : Array<Component> = m_componentManager.getComponentListForType(RenderableComponent.TYPE_ID);
        var renderComponent : RenderableComponent;
        var i : Int;
        var components : Int = renderComponents.length;
        for (i in 0...components){
            renderComponent = try cast(renderComponents[i], RenderableComponent) catch(e:Dynamic) null;
            if (renderComponent.view != null) 
            {
                renderComponent.view.removeFromParent();
            }
        }
    }
    
    override public function update(time : Time,
            mouseState : MouseState) : Void
    {
        // Advance juggler timer
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
    
    /**
     * Display the common login dialog for the game.
     */
    private function showLoginPopup() : Void
    {
        var cgsApi : CgsApi = m_logger.getCgsApi();
        var loginPopup : LoginPopup = cgsApi.createUserLoginDialog(
                m_logger.getCgsUserProperties(m_config.getSaveDataToServer(), m_config.getSaveDataKey()),
                onUserLoginSucceed,
                true,
                onLoginCancel
                );
        loginPopup.teacherCode = m_config.getTeacherCode();
        loginPopup.setLoginFailCallback(onUserLoginFail);
        loginPopup.usernameAsPassword = m_config.getUsernameAsPassword();
        loginPopup.showCreateStudentDialogOnFail = false;
        
        // When the user selects login, some unknown period of time may elapse until we get a response
        // from the server. During that time a waiting screen should appear
        loginPopup.setLoginButtonFactory(function() : fl.controls.Button
                {
                    var button : fl.controls.Button = buttonFactory();
                    button.addEventListener(MouseEvent.CLICK, function(event : MouseEvent) : Void
                            {
                                Audio.instance.playSfx("button_click");
                                dispatchEventWith(CommandEvent.WAIT_SHOW);
                            });
                    return button;
                });
        loginPopup.setCancelButtonFactory(buttonFactory);
        function buttonFactory() : fl.controls.Button
        {
            var button : fl.controls.Button = new fl.controls.Button();
            button.setStyle("upSkin", TitleScreenState.button_purple_up);
            button.setStyle("overSkin", TitleScreenState.button_purple_over);
            button.setStyle("downSkin", TitleScreenState.button_purple_over);
            button.setStyle("textFormat", new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0x000000, null, null, false));
            button.setStyle("embedFonts", true);
            button.width = 110;
            button.height = 27;
            return button;
        };
        
        loginPopup.setTitleFactory(function() : TextField
                {
                    var title : TextField = new TextField();
                    title.defaultTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF, null, null, false);
                    title.embedFonts = true;
                    title.selectable = false;
                    title.width = 289;
                    title.height = 106;
                    return title;
                });
        
        // Set styles for the labels next to the text inputs
        loginPopup.setInputLabelFactory(function() : TextField
                {
                    var inputLabel : TextField = new TextField();
                    inputLabel.selectable = false;
                    inputLabel.defaultTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF);
                    inputLabel.embedFonts = true;
                    inputLabel.width = 188;
                    inputLabel.height = 50;
                    return inputLabel;
                });
        
        // Set styles for the text input fields
        loginPopup.setInputFactory(function() : TextInput
                {
                    var input : TextInput = new TextInput();
                    input.setStyle("upSkin", text_input_background);
                    input.setStyle("textFormat", new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0, null, null, null, null, null, "center"));
                    input.setStyle("embedFonts", false);
                    input.width = 180;
                    input.height = 27;
                    return input;
                });
        
        // Set the background image
        loginPopup.setBackgroundFactory(function() : DisplayObject
                {
                    return null;
                });
        
        // Provide custom layout of the components
        loginPopup.setLayoutFunction(function(logo : DisplayObject,
                        titleText : TextField,
                        usernameText : TextField,
                        usernameInput : TextInput,
                        passwordText : TextField,
                        passwordInput : TextInput,
                        loginButton : fl.controls.Button,
                        cancelButton : fl.controls.Button,
                        errorText : TextField,
                        background : DisplayObject,
                        allowCancel : Bool,
                        passwordEnabled : Bool) : Void
                {
                    while (this.numChildren > 0)
                    {
                        this.removeChildAt(0);
                    }
                    
                    var boxWidth : Float = 280;
                    titleText.x = (boxWidth - titleText.width) * 0.5;
                    titleText.y = 0;
                    titleText.text = "Already have an account?";
                    this.addChild(titleText);
                    
                    var userNameX : Float = 0;
                    var userNameY : Float = titleText.y + 30;
                    
                    usernameInput.x = userNameX;
                    usernameInput.y = userNameY;
                    
                    if (m_usernamePrefix != null) 
                    {
                        usernameInput.text = m_usernamePrefix;
                    }
                    
                    this.addChild(usernameInput);
                    
                    errorText.x = userNameX;
                    errorText.y = usernameInput.y + usernameInput.height;
                    this.addChild(errorText);
                    
                    loginButton.x = usernameInput.x + usernameInput.width + 15;
                    loginButton.y = usernameInput.y;
                    loginButton.label = "Resume";
                    this.addChild(loginButton);
                });
        
        // Call the draw function to make sure our own style properties are applied to the
        // popup
        loginPopup.drawAndLayout();
        
        // Add to the flash stage
        loginPopup.x = (800 - loginPopup.width) * 0.5;
        loginPopup.y = (600 - loginPopup.height) * 0.72;
        m_flashStage.addChild(loginPopup);
        
        m_loginPopup = loginPopup;
    }
    
    /**
     * Log in a user without any account credentials
     */
    private function loginAnonymousUser() : Void
    {
        // Anonymous users are initialized instantaneously.
        // Re-use the user object if they attempted to register a new account
        var anonymousUser : ICgsUser = ((m_dummyAnonymousUser != null)) ? 
        m_dummyAnonymousUser : m_logger.getCgsApi().initializeUser(
                m_logger.getCgsUserProperties(m_config.getSaveDataToServer(), m_config.getSaveDataKey()));
        handleCgsUserCreated(anonymousUser);
    }
    
    /**
     * Callback fired once an exisiting user has been successfully authenticated
     */
    private function onUserLoginSucceed(response : CgsUserResponse) : Void
    {
        // If a dummy user exists, remove it
        if (m_dummyAnonymousUser != null) 
        {
            m_logger.getCgsApi().removeUser(m_dummyAnonymousUser);
        }
        
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
            
            var cgsUser : ICgsUser = response.cgsUser;
            handleCgsUserCreated(cgsUser);
        }
    }
    
    private function handleCgsUserCreated(user : ICgsUser) : Void
    {
        // As soon as the player logs in, whether anonymously or with a real account, we need to bind
        // the user to a challenge service. We always want to record data about levels played
        var cgsApi : CgsApi = m_logger.getCgsApi();
        var challengeId : Int = m_config.getChallengeId();
        
        // For authenticated users, need to now fetch their dragonbox information if dragonbox category is active
        if (user.username != null) 
        {
            onUserInformationLoaded(user);
        }
        // For anonymous users immediately send out authenticated signal
        else 
        {
            dispatchEventWith(CommandEvent.WAIT_HIDE);
            dispatchEventWith(CommandEvent.USER_AUTHENTICATED);
        }
    }
    
    private function onUserInformationLoaded(user : ICgsUser) : Void
    {
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
            dispatchEventWith(CommandEvent.USER_AUTHENTICATED, false);
        }
    }
    
    /**
     * Callback fired once an existing user has failed the authentication process
     */
    private function onUserLoginFail(response : CgsUserResponse) : Void
    {
        // Hide the waiting screen
        dispatchEventWith(CommandEvent.WAIT_HIDE);
    }
    
    /**
     * Callback fired if the player presses cancel on the login popup
     */
    private function onLoginCancel() : Void
    {
        Audio.instance.playSfx("button_click");
    }
    
    private function onSignUpButtonClick(event : MouseEvent) : Void
    {
        // Signal to launch another screen containing input for new account
        // This is actually a sequence of screens, which is the information registration,
        // the terms of service, and reward notice screen.
        Audio.instance.playSfx("button_click");
        
        // Create an anonymous user for the purpose of registration
        if (m_dummyAnonymousUser == null) 
        {
            m_dummyAnonymousUser = m_logger.getCgsApi().initializeUser(
                            m_logger.getCgsUserProperties(m_config.getSaveDataToServer(), m_config.getSaveDataKey()));
        }  // Attach another layer to block out Stage3d mouse events  
        
        
        
        var disableQuad : Quad = new Quad(800, 600, 0x000000);
        disableQuad.alpha = 0.7;
        addChild(disableQuad);
        
        m_registerAccountState = new RegisterAccountState(
                m_dummyAnonymousUser, 
                m_config, 
                m_logger.getCgsApi(), 
                m_logger.getChallengeService(), 
                m_logger.getCgsUserProperties(m_config.getSaveDataToServer(), m_config.getSaveDataKey()), 
                onCancel, 
                onComplete, 
                "Create an account to earn a prize!", 
                );
        m_flashStage.addChild(m_registerAccountState);
        
        function onCancel() : Void
        {
            // Clear out the register screens
            removeChild(disableQuad);
            m_registerAccountState.dispose();
            m_flashStage.removeChild(m_registerAccountState);
        };
        
        function onComplete() : Void
        {
            // Clear out the register screens and start the game
            onCancel();
            
            // During the creation of a new user, we may end up with the initial dummy anonymous user
            // and the authenticated one which is bad since we want to assume just one user
            var cgsApi : CgsApi = m_logger.getCgsApi();
            if (cgsApi.userManager.userList.length > 1) 
            {
                cgsApi.removeUser(cgsApi.userManager.userList[0]);
            }  // Show wait screen because we need to login to dragonbox  
            
            
            
            dispatchEventWith(CommandEvent.WAIT_SHOW);
            
            handleCgsUserCreated(m_dummyAnonymousUser);
        };
    }
    
    private function onPlayNowClick(event : MouseEvent) : Void
    {
        Audio.instance.playSfx("button_click");
        
        loginAnonymousUser();
    }
}
