package wordproblem.state
{
    import flash.display.DisplayObject;
    import flash.display.Stage;
    import flash.events.MouseEvent;
    import flash.filters.GlowFilter;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    
    import cgs.CgsApi;
    import cgs.Audio.Audio;
    import cgs.login.LoginPopup;
    import cgs.server.responses.CgsUserResponse;
    import cgs.user.ICgsUser;
    
    import dragonbox.common.state.BaseState;
    import dragonbox.common.state.IStateMachine;
    
    import fl.controls.Button;
    import fl.controls.TextInput;
    
    import starling.display.Image;
    import starling.display.Sprite;
    
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
    public class ChallengeTitleScreenState extends BaseState
    {
        /*
        A consequence of need flash display resources is that the raw image classes needed to style the
        popup are not naturally accessible through the asset manager. We need to embed them directly into this class.
        */
        [Embed(source="/../assets/ui/login/button_disabled.png")]
        public static const button_disabled:Class;
        [Embed(source="/../assets/ui/login/button_purple_up.png")]
        public static const button_purple_up:Class;
        [Embed(source="/../assets/ui/login/button_purple_over.png")]
        public static const button_purple_over:Class;
        [Embed(source="/../assets/ui/login/button_green_up.png")]
        public static const button_green_up:Class;
        [Embed(source="/../assets/ui/login/button_green_hover.png")]
        public static const button_green_hover:Class;
        [Embed(source="/../assets/ui/login/text_input_background.png")]
        public static const text_input_background:Class;
        
        /**
         * If not null, the screen should treat the user as a student trying to login.
         * 
         */
        private var m_teacherCode:String;
        private var m_saveDataKey:String;
        private var m_saveDataToServer:Boolean;
        private var m_challengeId:int;
        
        /**
         * The login ui components are flash based, meaning they must be added to the flash stage.
         */
        private var m_flashStage:flash.display.Stage;
        
        private var m_logger:AlgebraAdventureLogger;
        
        /**
         * The login popup that uses common
         */
        private var m_loginPopup:LoginPopup;
        
        private var m_background:Sprite;
        
        public function ChallengeTitleScreenState(stateMachine:IStateMachine, 
                                                  teacherCode:String,
                                                  challengeId:int,
                                                  flashStage:flash.display.Stage, 
                                                  logger:AlgebraAdventureLogger,
                                                  assetManager:AssetManager)
        {
            super(stateMachine);
            
            m_teacherCode = teacherCode;
            m_challengeId = challengeId;
            m_flashStage = flashStage;
            m_logger = logger;
            
            m_background = new Sprite();
            m_background.addChild(new Image(assetManager.getTexture("login_background")));
            var boxBackground:Image = new Image(assetManager.getTexture("summary_background"));
            boxBackground.width = 450;
            boxBackground.height = 280;
            boxBackground.x = (m_background.width - boxBackground.width) * 0.5;
            boxBackground.y = (m_background.height - boxBackground.height) * 0.5;
            m_background.addChild(boxBackground);
        }
        
        override public function enter(fromState:Object, params:Vector.<Object>=null):void
        {
            addChild(m_background);
            showLoginPopup();
        }
        
        override public function exit(toState:Object):void
        {
            m_background.removeFromParent();
            
            if (m_loginPopup != null && m_loginPopup.parent != null)
            {
                m_loginPopup.parent.removeChild(m_loginPopup);
            }
        }
        
        /**
         * Display the common login dialog for the game.
         */
        private function showLoginPopup():void
        {
            const cgsApi:CgsApi = m_logger.getCgsApi();
            const loginPopup:LoginPopup = cgsApi.createUserLoginDialog(
                m_logger.getCgsUserProperties(m_saveDataToServer, m_saveDataKey),
                onUserLoginSucceed,
                true,
                null
            );
            loginPopup.teacherCode = m_teacherCode;
            loginPopup.setLoginFailCallback(onUserLoginFail);
            loginPopup.usernameAsPassword = false;
            loginPopup.showCreateStudentDialogOnFail = false;
            
            // When the user selects login, some unknown period of time may elapse until we get a response
            // from the server. During that time a waiting screen should appear
            loginPopup.setLoginButtonFactory(function():fl.controls.Button
            {
                const button:fl.controls.Button = buttonFactory();
                button.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void
                {
                    Audio.instance.playSfx("button_click");
                    dispatchEventWith(CommandEvent.WAIT_SHOW); 
                });
                return button;
            });
            loginPopup.setCancelButtonFactory(buttonFactory);
            function buttonFactory():fl.controls.Button
            {
                const button:fl.controls.Button = new fl.controls.Button();
                button.setStyle("upSkin", TitleScreenState.button_purple_up);
                button.setStyle("overSkin", TitleScreenState.button_purple_over);
                button.setStyle("downSkin", TitleScreenState.button_purple_over);
                button.setStyle("textFormat", new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0x000000, null, null, false));
                button.setStyle("embedFonts", true);
                button.width = 150;
                button.height = 50;
                return button;
            }
            
            loginPopup.setTitleFactory(function():TextField
            {
                const title:TextField = new TextField();
                title.defaultTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 32, 0xCC66FF, null, null, false);
                title.defaultTextFormat.align = TextFormatAlign.CENTER;
                title.embedFonts = true;
                title.selectable = false;
                title.width = 289;
                title.height = 46;
                return title;
            });
            
            // Set styles for the labels next to the text inputs
            loginPopup.setInputLabelFactory(function():TextField
            {
                const inputLabel:TextField = new TextField();
                inputLabel.selectable = false;
                inputLabel.defaultTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 26, 0xFFFFFF);
                inputLabel.embedFonts = true;
                inputLabel.width = 128;
                inputLabel.height = 30;
                inputLabel.filters = [new GlowFilter(0x000000, 1, 2, 2)];
                return inputLabel;
            });
            
            // Set styles for the text input fields
            loginPopup.setInputFactory(function():TextInput
            {
                const input:TextInput = new TextInput();
                input.setStyle("upSkin", text_input_background);
                input.setStyle("textFormat", new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0, null, null, null, null, null, "center"));
                input.setStyle("embedFonts", false);
                input.width = 180;
                input.height = 27;
                return input;
            });
            
            // Set the background image
            loginPopup.setBackgroundFactory(function():DisplayObject
            {
                return null;
            });
            
            // Provide custom layout of the components
            loginPopup.setLayoutFunction(function(logo:DisplayObject,
                                                  titleText:TextField, 
                                                  usernameText:TextField,
                                                  usernameInput:TextInput,
                                                  passwordText:TextField,
                                                  passwordInput:TextInput, 
                                                  loginButton:fl.controls.Button, 
                                                  cancelButton:fl.controls.Button, 
                                                  errorText:TextField, 
                                                  background:DisplayObject, 
                                                  allowCancel:Boolean, 
                                                  passwordEnabled:Boolean):void
            {
                while (this.numChildren > 0)
                {
                    this.removeChildAt(0);
                }
                
                const boxWidth:Number = 280;
                titleText.x = (boxWidth - titleText.width) * 0.5;
                titleText.y = 0;
                titleText.text = "Login"
                this.addChild(titleText);
                
                var userNameX:Number = 0;
                var userNameY:Number = titleText.y + titleText.height;
                
                usernameText.x = userNameX;
                usernameText.y = userNameY;
                usernameText.text = "username";
                this.addChild(usernameText);
                
                usernameInput.x = userNameX + usernameText.width;
                usernameInput.y = userNameY;
                this.addChild(usernameInput);
                
                if (m_teacherCode == null)
                {
                    var passwordX:Number = 0;
                    var passwordY:Number = usernameInput.y + usernameInput.height + 10;
                    
                    passwordText.text = "password";
                    passwordText.x = passwordX;
                    passwordText.y = passwordY;
                    this.addChild(passwordText);
                    
                    passwordInput.x = passwordX + passwordText.width;
                    passwordInput.y = passwordY;
                    this.addChild(passwordInput);
                }
                
                errorText.x = userNameX;
                errorText.y = (m_teacherCode == null) ? passwordInput.y + passwordInput.height : usernameInput.y + usernameInput.height;
                this.addChild(errorText);
                
                var loginButtonX:Number = (boxWidth - loginButton.width) * 0.5;
                var loginButtonY:Number = errorText.y + errorText.height + 7;
                loginButton.x = loginButtonX;
                loginButton.y = loginButtonY;
                loginButton.label = "OK";
                this.addChild(loginButton);
            });
            
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
        private function onUserLoginSucceed(response:CgsUserResponse):void
        {
            if(response.success)
            {
                const dataLoaded:Boolean = response.dataLoadSuccess;
                if (dataLoaded)
                {
                }
                else
                {
                    // TODO:
                    // If the save data fails to load, we should show an error message to the user
                }
                
                var cgsUser:ICgsUser = response.cgsUser;
                handleCgsUserCreated(cgsUser);
            }
        }
        
        private function handleCgsUserCreated(user:ICgsUser):void
        {
            // As soon as the player logs in, whether anonymously or with a real account, we need to bind
            // the user to a challenge service. We always want to record data about levels played
            var cgsApi:CgsApi = m_logger.getCgsApi();
            
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
        
        private function onUserInformationLoaded(user:ICgsUser):void
        {
            // See if the user still needs to accept a tos
            if (user.tosRequired && !user.tosStatus.accepted)
            {
                var tosScreen:RegisterTosScreen = new RegisterTosScreen(
                    user, 
                    function():void
                    {
                        tosScreen.dispose();
                        m_flashStage.removeChild(tosScreen);
                        dispatchEventWith(CommandEvent.WAIT_HIDE);
                        dispatchEventWith(CommandEvent.USER_AUTHENTICATED);
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
                dispatchEventWith(CommandEvent.WAIT_HIDE);
                dispatchEventWith(CommandEvent.USER_AUTHENTICATED, false);
            }
        }
        
        /**
         * Callback fired once an existing user has failed the authentication process
         */
        private function onUserLoginFail(response:CgsUserResponse):void
        {
            // Hide the waiting screen
            dispatchEventWith(CommandEvent.WAIT_HIDE);
        }
    }
}