package wordproblem.state;


import openfl.display.Bitmap;
import openfl.display.DisplayObject;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.filters.GlowFilter;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

import cgs.CgsApi;
import cgs.audio.Audio;
import cgs.login.LoginPopup;
import cgs.server.responses.CgsUserResponse;
import cgs.user.ICgsUser;

import dragonbox.common.state.BaseState;
import dragonbox.common.state.IStateMachine;

import wordproblem.display.LabelButton;
import openfl.display.Sprite;
import openfl.text.TextField;

import wordproblem.account.RegisterTosScreen;
import wordproblem.engine.text.GameFonts;
import wordproblem.event.CommandEvent;
import wordproblem.log.AlgebraAdventureLogger;
import wordproblem.resource.AssetManager;

/**
 * The login state for challenges.
 * 
 * If some teacher code is assigned to the application then we treat the executing client as a student
 * and only require a username to login.
 * 
 * If no teacher code is set, the regular username and password are required.
 */
class ChallengeTitleScreenState extends BaseState
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
     * If not null, the screen should treat the user as a student trying to login.
     * 
     */
    private var m_teacherCode : String;
    private var m_saveDataKey : String;
    private var m_saveDataToServer : Bool;
    private var m_challengeId : Int;
    
    /**
     * The login ui components are flash based, meaning they must be added to the flash stage.
     */
    private var m_flashStage : flash.display.Stage;
    
    private var m_logger : AlgebraAdventureLogger;
    
    /**
     * The login popup that uses common
     */
    private var m_loginPopup : LoginPopup;
    
    private var m_background : Sprite;
    
    public function new(stateMachine : IStateMachine,
            teacherCode : String,
            challengeId : Int,
            flashStage : flash.display.Stage,
            logger : AlgebraAdventureLogger,
            assetManager : AssetManager)
    {
        super(stateMachine);
        
        m_teacherCode = teacherCode;
        m_challengeId = challengeId;
        m_flashStage = flashStage;
        m_logger = logger;
        
        m_background = new Sprite();
        m_background.addChild(new Bitmap(assetManager.getBitmapData("login_background")));
        var boxBackground : Bitmap = new Bitmap(assetManager.getBitmapData("summary_background"));
        boxBackground.width = 450;
        boxBackground.height = 280;
        boxBackground.x = (m_background.width - boxBackground.width) * 0.5;
        boxBackground.y = (m_background.height - boxBackground.height) * 0.5;
        m_background.addChild(boxBackground);
    }
    
    override public function enter(fromState : Dynamic, params : Array<Dynamic> = null) : Void
    {
        addChild(m_background);
        showLoginPopup();
    }
    
    override public function exit(toState : Dynamic) : Void
    {
        if (m_background.parent != null) m_background.parent.removeChild(m_background);
        
        if (m_loginPopup != null && m_loginPopup.parent != null) 
        {
            if (m_loginPopup.parent != null) m_loginPopup.parent.removeChild(m_loginPopup);
        }
    }
    
    /**
     * Display the common login dialog for the game.
     */
    private function showLoginPopup() : Void
    {
        var cgsApi : CgsApi = m_logger.getCgsApi();
		// TODO: uncomment once cgs library is finished
        var loginPopup : LoginPopup = null;/*cgsApi.createUserLoginDialog(
            m_logger.getCgsUserProperties(m_saveDataToServer, m_saveDataKey),
            onUserLoginSucceed,
            true,
            null
        );*/
        loginPopup.teacherCode = m_teacherCode;
        loginPopup.setLoginFailCallback(onUserLoginFail);
        loginPopup.usernameAsPassword = false;
        loginPopup.showCreateStudentDialogOnFail = false;
        
        // When the user selects login, some unknown period of time may elapse until we get a response
        // from the server. During that time a waiting screen should appear
		// TODO: redesign this with the openfl asset management
		//function buttonFactory() : Button
        //{
            //var button : Button = new Button(TitleScreenState.button_purple_up,
				//null,
				//TitleScreenState.button_purple_over,
				//TitleScreenState.button_purple_over
			//);
			//// TODO: uncomment when a suitable button replacement is found
            ////button.setStyle("textFormat", new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0x000000, null, null, false));
            ////button.setStyle("embedFonts", true);
            //button.width = 150;
            //button.height = 50;
            //return button;
        //};
		//
        //loginPopup.setLoginButtonFactory(function() : Button
                //{
                    //var button : Button = buttonFactory();
                    //button.addEventListener(MouseEvent.CLICK, function(event : MouseEvent) : Void
                            //{
                                //Audio.instance.playSfx("button_click");
                                //dispatchEvent(CommandEvent.WAIT_SHOW);
                            //});
                    //return button;
                //});
        //loginPopup.setCancelButtonFactory(buttonFactory);
        
        //loginPopup.setTitleFactory(function() : TextField
                //{
                    //var title : TextField = new TextField(289, 46, null, GameFonts.DEFAULT_FONT_NAME, 32, 0xCC66FF);
					//title.hAlign = TextFormatAlign.CENTER;
					//title.vAlign = TextFormatAlign.CENTER;
                    //return title;
                //});
		
        // Set styles for the labels next to the text inputs
        //loginPopup.setInputLabelFactory(function() : TextField
                //{
                    //var inputLabel : TextField = new TextField(128, 30, "", GameFonts.DEFAULT_FONT_NAME, 26, 0xFFFFFF);
                    //inputLabel.nativeFilters = [new GlowFilter(0x000000, 1, 2, 2)];
                    //return inputLabel;
                //});
        
        // Set styles for the text input fields
		// TODO: uncomment when a text input replacement is found
        //loginPopup.setInputFactory(function() : TextInput
                //{
                    //var input : TextInput = new TextInput();
                    //input.setStyle("upSkin", text_input_background);
                    //input.setStyle("textFormat", new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0, null, null, null, null, null, "center"));
                    //input.setStyle("embedFonts", false);
                    //input.width = 180;
                    //input.height = 27;
                    //return input;
                //});
        
        // Set the background image
        loginPopup.setBackgroundFactory(function() : DisplayObject
                {
                    return null;
                });
        
        // Provide custom layout of the components
		// TODO: uncomment when a text input replacement is found
        //loginPopup.setLayoutFunction(function(logo : DisplayObject,
                        //titleText : TextField,
                        //usernameText : TextField,
                        //usernameInput : TextInput,
                        //passwordText : TextField,
                        //passwordInput : TextInput,
                        //loginButton : fl.controls.Button,
                        //cancelButton : fl.controls.Button,
                        //errorText : TextField,
                        //background : DisplayObject,
                        //allowCancel : Bool,
                        //passwordEnabled : Bool) : Void
                //{
                    //while (this.numChildren > 0)
                    //{
                        //this.removeChildAt(0);
                    //}
                    //
                    //var boxWidth : Float = 280;
                    //titleText.x = (boxWidth - titleText.width) * 0.5;
                    //titleText.y = 0;
                    //titleText.text = "Login";
                    //this.addChild(titleText);
                    //
                    //var userNameX : Float = 0;
                    //var userNameY : Float = titleText.y + titleText.height;
                    //
                    //usernameText.x = userNameX;
                    //usernameText.y = userNameY;
                    //usernameText.text = "username";
                    //this.addChild(usernameText);
                    //
                    //usernameInput.x = userNameX + usernameText.width;
                    //usernameInput.y = userNameY;
                    //this.addChild(usernameInput);
                    //
                    //if (m_teacherCode == null) 
                    //{
                        //var passwordX : Float = 0;
                        //var passwordY : Float = usernameInput.y + usernameInput.height + 10;
                        //
                        //passwordText.text = "password";
                        //passwordText.x = passwordX;
                        //passwordText.y = passwordY;
                        //this.addChild(passwordText);
                        //
                        //passwordInput.x = passwordX + passwordText.width;
                        //passwordInput.y = passwordY;
                        //this.addChild(passwordInput);
                    //}
                    //
                    //errorText.x = userNameX;
                    //errorText.y = ((m_teacherCode == null)) ? passwordInput.y + passwordInput.height : usernameInput.y + usernameInput.height;
                    //this.addChild(errorText);
                    //
                    //var loginButtonX : Float = (boxWidth - loginButton.width) * 0.5;
                    //var loginButtonY : Float = errorText.y + errorText.height + 7;
                    //loginButton.x = loginButtonX;
                    //loginButton.y = loginButtonY;
                    //loginButton.label = "OK";
                    //this.addChild(loginButton);
                //});
        
        // Call the draw function to make sure our own style properties are applied to the
        // popup
        loginPopup.drawAndLayout();
        
        // Add to the flash stage
        loginPopup.x = (800 - loginPopup.width) * 0.5;
        loginPopup.y = (600 - loginPopup.height) * 0.5;
        m_flashStage.addChild(loginPopup);
        
        m_loginPopup = loginPopup;
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
            
            var cgsUser : ICgsUser = response.cgsUser;
            handleCgsUserCreated(cgsUser);
        }
    }
    
    private function handleCgsUserCreated(user : ICgsUser) : Void
    {
        // As soon as the player logs in, whether anonymously or with a real account, we need to bind
        // the user to a challenge service. We always want to record data about levels played
        var cgsApi : CgsApi = m_logger.getCgsApi();
        
        // For authenticated users, need to now fetch their dragonbox information if dragonbox category is active
        if (user.username != null) 
        {
            onUserInformationLoaded(user);
        }
        // For anonymous users immediately send out authenticated signal
        else 
        {
            dispatchEvent(new Event(CommandEvent.WAIT_HIDE));
            dispatchEvent(new Event(CommandEvent.USER_AUTHENTICATED));
        }
    }
    
    private function onUserInformationLoaded(user : ICgsUser) : Void
    {
        // See if the user still needs to accept a tos
        if (user.tosRequired && !user.tosStatus.accepted) 
        {
			var tosScreen : RegisterTosScreen = null;
            tosScreen = new RegisterTosScreen(
				user, 
				function() : Void
				{
					tosScreen.dispose();
					m_flashStage.removeChild(tosScreen);
					dispatchEvent(new Event(CommandEvent.WAIT_HIDE));
					dispatchEvent(new Event(CommandEvent.USER_AUTHENTICATED));
				}, 
				800, 
				600
            );
            m_flashStage.addChild(tosScreen);
        }
        else 
        {
            // On login, if the user is not anonymous and we are linked to dragonbox
            // Then we may need to poll the player's dragonbox save data to fetch information
            // that should be imported over to this game. For example rewards.
            dispatchEvent(new Event(CommandEvent.WAIT_HIDE));
            dispatchEvent(new Event(CommandEvent.USER_AUTHENTICATED));
        }
    }
    
    /**
     * Callback fired once an existing user has failed the authentication process
     */
    private function onUserLoginFail(response : CgsUserResponse) : Void
    {
        // Hide the waiting screen
        dispatchEvent(new Event(CommandEvent.WAIT_HIDE));
    }
}
