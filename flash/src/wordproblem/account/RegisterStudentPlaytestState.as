package wordproblem.account
{
    import com.gskinner.motion.GTween;
    
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    
    import cgs.CgsApi;
    import cgs.Audio.Audio;
    import cgs.server.challenge.ChallengeService;
    import cgs.user.CgsUserProperties;
    import cgs.user.ICgsUser;
    
    import dragonbox.common.dispose.IDisposable;
    import dragonbox.common.ui.LoadingSpinner;
    
    import fl.controls.Button;
    import fl.controls.ComboBox;
    import fl.controls.TextInput;
    
    import wordproblem.AlgebraAdventureConfig;
    import wordproblem.engine.text.GameFonts;
    import gameconfig.commonresource.EmbeddedBundle1X;
    import wordproblem.state.TitleScreenState;
    
    /**
     * This object encapsulates all the different screens used to display the register account
     * state.
     * 
     * The screens to show in order are:
     * Area to input new account info
     * Prize screen showing them they earned a new prize
     */
    public class RegisterStudentPlaytestState extends Sprite implements IDisposable
    {
        private var m_width:Number = 800;
        private var m_height:Number = 600;
        
        /**
         * The screen where the player must enter information to create a new account
         */
        private var m_registerAccountScreen:RegisterAnonymousAccountScreen;
        
        /**
         * The screen where the player must accept a tos to continue playing
         */
        private var m_registerTosScreen:RegisterTosScreen;
        
        /**
         * The screen telling the player that they earned a new reward
         */
        private var m_registerRewardScreen:RegisterRewardScreen;
        
        /**
         * Callback that is triggered when the player cancels the sequence
         */
        private var m_onCancelCallback:Function;
        
        /**
         * Callback that is triggered when the player is completely finished with the whole
         * registration process.
         */
        private var m_onCompleteCallback:Function;
        
        /**
         * While waiting for register to finish, put up a loading screen to block player from
         * making any more changes.
         */
        private var m_loadingScreen:Sprite;
        
        /**
         * A message box indicating that registration failed
         */
        private var m_errorScreen:Sprite;
        
        /**
         * When a player creates an account after logging in anonymously we may want the text
         * to say something different
         */
        private var m_descriptionText:String;
        
        /**
         * For playtest we give the player a predefined username
         */
        private var m_playtestAssignedUsername:String;
        
        /**
         *
         * @param onCompleteCallback
         *      callback(user:ICgsUser)
         */
        public function RegisterStudentPlaytestState(anonymousUser:ICgsUser,
                                                     config:AlgebraAdventureConfig,
                                                     cgsApi:CgsApi,
                                                     challengeService:ChallengeService,
                                                     userLoggingProperties:CgsUserProperties,
                                                     onCancelCallback:Function,
                                                     onCompleteCallback:Function,
                                                     playtestAssignedUsername:String,
                                                     descriptionText:String=null)
        {
            super();
            
            // Create a loading screen that blocks progress
            m_loadingScreen = new Sprite();
            m_loadingScreen.graphics.beginFill(0x000000, 0.5);
            m_loadingScreen.graphics.drawRect(0, 0, m_width, m_height);
            m_loadingScreen.graphics.endFill();
            m_descriptionText = descriptionText;
            
            var loadingSpinner:LoadingSpinner = new LoadingSpinner(12, 20, 0x193D0C, 0x42A321);
            loadingSpinner.x = m_width * 0.5;
            loadingSpinner.y = m_height * 0.5;
            m_loadingScreen.addChild(loadingSpinner);
            
            m_playtestAssignedUsername = playtestAssignedUsername;
            
            m_registerAccountScreen = new RegisterAnonymousAccountScreen(
                anonymousUser, 
                config,
                cgsApi, 
                challengeService, 
                userLoggingProperties,
                onRegisterStart,
                onRegisterSuccess,
                onRegisterFail,
                onCancelCallback
            );
            m_registerAccountScreen.layoutFunction = function defaultLayout(background:DisplayObject,
                                                                            titleLabel:TextField,
                                                                            description:DisplayObject,
                                                                            userNameLabel:TextField,
                                                                            userNameInput:TextInput,
                                                                            userNameAcceptableIcon:DisplayObject,
                                                                            userNameNotAcceptableIcon:DisplayObject,
                                                                            userNameLoadingSpinner:LoadingSpinner,
                                                                            userNameErrorLabel:TextField,
                                                                            gradeLabel:TextField,
                                                                            gradeComboBox:ComboBox,
                                                                            gradeSelectedIcon:DisplayObject,
                                                                            gradeNotSelectedIcon:DisplayObject,
                                                                            genderLabel:TextField,
                                                                            genderComboBox:ComboBox,
                                                                            genderSelectedIcon:DisplayObject,
                                                                            genderNotSelectedIcon:DisplayObject,
                                                                            registerButton:Button, 
                                                                            cancelButton:Button, 
                                                                            registerFailMessage:TextField):void
            {
                m_registerAccountScreen.addChild(background);
                
                userNameInput.text = m_playtestAssignedUsername;
                
                titleLabel.x = (background.width - titleLabel.width) * 0.5;
                titleLabel.y = 34;
                m_registerAccountScreen.addChild(titleLabel);
                
                description.x = 34;
                description.y = 130;
                m_registerAccountScreen.addChild(description);
                
                var inputHorizontalLine:Number = 295
                gradeLabel.x = inputHorizontalLine;
                gradeLabel.y = 150;
                m_registerAccountScreen.addChild(gradeLabel);
                
                gradeComboBox.move(inputHorizontalLine + 170, gradeLabel.y);
                m_registerAccountScreen.addChild(gradeComboBox);
                
                gradeSelectedIcon.x = gradeComboBox.x + gradeComboBox.width;
                gradeSelectedIcon.y = gradeComboBox.y;
                m_registerAccountScreen.addChild(gradeSelectedIcon);
                
                gradeNotSelectedIcon.x = gradeSelectedIcon.x;
                gradeNotSelectedIcon.y = gradeSelectedIcon.y;
                
                genderLabel.x = inputHorizontalLine;
                genderLabel.y = gradeLabel.y + gradeLabel.height;
                m_registerAccountScreen.addChild(genderLabel);
                
                genderComboBox.move(inputHorizontalLine + 170, genderLabel.y);
                m_registerAccountScreen.addChild(genderComboBox);
                
                genderSelectedIcon.x = genderComboBox.x + genderComboBox.width;
                genderSelectedIcon.y = genderComboBox.y;
                m_registerAccountScreen.addChild(genderSelectedIcon);
                
                genderNotSelectedIcon.x = genderSelectedIcon.x;
                genderNotSelectedIcon.y = genderSelectedIcon.y;
                
                registerButton.x = background.width * 0.5 - 90;
                registerButton.y = (background.height - 80);
                registerButton.label = "Start";
                registerButton.enabled = true;
                m_registerAccountScreen.addChild(registerButton);
            };
            
            m_registerAccountScreen.backgroundFactory = function defaultBackgroundFactory():DisplayObject
            {
                var background:DisplayObject = new EmbeddedBundle1X.summary_background();
                background.width = 700;
                background.height = 480;
                return background;
            };
            
            m_registerAccountScreen.titleLabelFactory = function defaultTitleLabelFactory():TextField
            {
                var title:TextField = new TextField();
                title.selectable = false;
                title.embedFonts = true;
                title.defaultTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 40, 0xD38AE3, null, null, true);
                title.text = "CREATE NEW ACCOUNT";
                title.width = title.textWidth * 1.1;
                return title;
            };
            
            m_registerAccountScreen.descriptionFactory = function defaultDescriptionFactory():DisplayObject
            {
                var description:Sprite = new Sprite();
                var text:TextField = new TextField();
                text.embedFonts = true;
                text.defaultTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 28, 0xFFFFFF, null, null, null, null, null, TextFormatAlign.CENTER);
                text.text = m_descriptionText;
                text.wordWrap = true;
                text.selectable = false;
                text.width = 200;
                text.height = 200;
                description.addChild(text);
                
                var prizeBox:MovieClip = new Art_PrizeFishBowl();
                prizeBox.stop();
                prizeBox.scaleX = prizeBox.scaleY = 0.6;
                description.addChild(prizeBox);
                prizeBox.x = text.x + text.width * 0.5;
                prizeBox.y = text.y + text.textHeight + prizeBox.height * 0.5;
                description.addChild(prizeBox);
                
                return description;
            };
            
            m_registerAccountScreen.gradeComboBoxFactory = defaultGradeComboBox;
            function defaultGradeComboBox():ComboBox
            {
                var comboBox:ComboBox = new ComboBox();
                comboBox.dropdownWidth = 200;
                comboBox.width = 200;
                comboBox.selectedIndex = 0;
                
                comboBox.textField.setStyle("textFormat", new TextFormat(GameFonts.DEFAULT_INPUT_FONT_NAME, 22, 0x000000, null, null, null, null, null, TextFormatAlign.CENTER));          // Text format of main button
                comboBox.dropdown.setRendererStyle("textFormat", new TextFormat(GameFonts.DEFAULT_INPUT_FONT_NAME, 18, 0x000000, null, null, null, null, null, TextFormatAlign.CENTER));   // Text format of drop down list
                comboBox.setStyle("textPadding", 10);
                comboBox.setSize(100, 50);
                
                return comboBox;
            };
            
            m_registerAccountScreen.genderComboBoxFactory = defaultGradeComboBox;
            m_registerAccountScreen.genderLabelFactory = function defaultGenderLabelFactory():TextField
            {
                var label:TextField = new TextField();
                label.width = 120;
                label.selectable = false;
                label.embedFonts = true;
                label.defaultTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 28, 0xFFFFFF);
                label.text = "I am a...";
                return label;
            };
            
            m_registerAccountScreen.userNameLabelFactory = function defaultUserNameLabelFactory():TextField
            {
                var label:TextField = new TextField();
                label.width = 120;
                label.selectable = false;
                label.embedFonts = true;
                label.defaultTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 28, 0xFFFFFF);
                label.text = "Username";
                return label;
            };
            
            m_registerAccountScreen.gradeLabelFactory = function defaultGradeLabelFactory():TextField
            {
                var label:TextField = new TextField();
                label.width = 120;
                label.selectable = false;
                label.embedFonts = true;
                label.defaultTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 28, 0xFFFFFF);
                label.text = "Grade";
                return label;
            };
            
            m_registerAccountScreen.userNameInputFactory = function defaultUserNameInputFactory():TextInput
            {
                var input:TextInput = new TextInput();
                input.setSize(200, 36);
                input.setStyle("upSkin", TitleScreenState.text_input_background);
                input.setStyle("textFormat", new TextFormat(GameFonts.DEFAULT_INPUT_FONT_NAME, 24, 0, null, null, null, null, null, "center"));
                input.setStyle("embedFonts", false);
                input.text = "";
                return input;
            };
            
            m_registerAccountScreen.userNameLoadingSpinnerFactory = function defaultUserNameLoadingSpinnerFactory():LoadingSpinner
            {
                var loadingSpinner:LoadingSpinner = new LoadingSpinner(8, 12, 0xCCFFCC, 0xCCFFCC);
                return loadingSpinner;
            };
            
            m_registerAccountScreen.userNameErrorLabelFactory = defaultUserNameErrorLabelFactory;
            
            function defaultUserNameErrorLabelFactory():TextField
            {
                var label:TextField = new TextField();
                label.width = 310;
                label.height = 30;
                label.selectable = false;
                label.embedFonts = true;
                label.defaultTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0xFF0000);
                label.text = "";
                return label;
            }
            
            m_registerAccountScreen.registerButtonFactory = defaultButtonFactory;
            m_registerAccountScreen.cancelButtonFactory = defaultButtonFactory;
            function defaultButtonFactory():Button
            {
                var button:Button = new Button();
                button.setStyle("upSkin", TitleScreenState.button_purple_up);
                button.setStyle("overSkin", TitleScreenState.button_purple_over);
                button.setStyle("downSkin", TitleScreenState.button_purple_over);
                
                button.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void
                {
                    Audio.instance.playSfx("button_click"); 
                });
                
                var textFormat:TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0);
                button.setStyle("textFormat", textFormat);
                button.setStyle("disabledTextFormat", textFormat);
                button.setStyle("embedFonts", true);
                button.width = 200;
                button.height = 50;
                return button;
            }
            
            m_registerAccountScreen.registerFailMessageFactory = defaultUserNameErrorLabelFactory;
            
            m_registerAccountScreen.userNameAcceptableIconFactory = function():DisplayObject
            {
                return new EmbeddedBundle1X.correct();
            };
            m_registerAccountScreen.userNameNotAcceptableIconFactory = function():DisplayObject
            {
                return new EmbeddedBundle1X.wrong();  
            };
            m_registerAccountScreen.drawAndLayout();
            m_registerAccountScreen.x = (m_width - m_registerAccountScreen.width) * 0.5;
            m_registerAccountScreen.y = (m_height - m_registerAccountScreen.height) * 0.5;
            addChild(m_registerAccountScreen);
            
            m_onCancelCallback = onCancelCallback;
            m_onCompleteCallback = onCompleteCallback;
        }
        
        public function dispose():void
        {
            (m_loadingScreen.getChildAt(0) as LoadingSpinner).dispose();
            
            if (m_registerAccountScreen != null)
            {
                m_registerAccountScreen.dispose();
            }
            
            if (m_registerRewardScreen != null)
            {
                m_registerRewardScreen.dispose();
            }
            
            while (this.numChildren > 0)
            {
                this.removeChildAt(0);
            }
        }
        
        private function onRegisterStart():void
        {
            addChild(m_loadingScreen);
        }
        
        private function onRegisterSuccess(user:ICgsUser):void
        {
            // If required, show tos to the user
            if (user.tosRequired)
            {
                m_registerTosScreen = new RegisterTosScreen(user, tosAccepted, m_width, m_height);
                addChild(m_registerTosScreen);
            }
            else
            {
                tosAccepted();
            }
            
            // Remove loading screen
            if (m_loadingScreen.parent)
            {
                removeChild(m_loadingScreen);
            }
            
            function tosAccepted():void
            {
                // Remove tos screen if it was required
                if (m_registerTosScreen != null && m_registerTosScreen.parent)
                {
                    m_registerTosScreen.dispose();
                    removeChild(m_registerTosScreen);
                }
                
                // When registration is successfully completed then transition to the screen
                // where the reward is given to the player.
                // We rely on the word problem game to know when rewards should be given for dragonbox milestones
                
                // Hide the registration screen and show the reward screen
                m_registerAccountScreen.parent.removeChild(m_registerAccountScreen);
                
                m_registerRewardScreen = new RegisterRewardScreen(m_onCompleteCallback, user);
                
                m_registerRewardScreen.backgroundFactory = function defaultBackgroundFactory():DisplayObject
                {
                    var background:DisplayObject = new EmbeddedBundle1X.summary_background();
                    return background;
                };
                
                m_registerRewardScreen.animationFactory = function defaultAnimationFactory():MovieClip
                {
                    var animation:MovieClip = new Art_PrizeFishBowl();
                    animation.stop();
                    return animation;
                };
                
                m_registerRewardScreen.descriptionTextFactory = function defaultDescriptionTextFactory():TextField
                {
                    var descriptionText:TextField = new TextField();
                    descriptionText.selectable = false;
                    descriptionText.wordWrap = true;
                    descriptionText.width = 400;
                    descriptionText.height = 150;
                    descriptionText.embedFonts = true;
                    descriptionText.defaultTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 28, 0xFFFFFF, null, null, null, null, null, TextFormatAlign.CENTER);
                    descriptionText.text = "Thank you for signing up. Your prize is on the bookshelf.";
                    return descriptionText;
                };
                
                m_registerRewardScreen.okButtonFactory = function defaultOkButtonFactory():Button
                {
                    var okButton:Button = new Button();
                    okButton.label = "OK";
                    okButton.setStyle("upSkin", TitleScreenState.button_purple_up);
                    okButton.setStyle("overSkin", TitleScreenState.button_purple_over);
                    okButton.setStyle("downSkin", TitleScreenState.button_purple_over);
                    
                    okButton.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void
                    {
                        Audio.instance.playSfx("button_click"); 
                    });
                    
                    var textFormat:TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 28, 0);
                    okButton.setStyle("textFormat", textFormat);
                    okButton.setStyle("disabledTextFormat", textFormat);
                    okButton.setStyle("embedFonts", true);
                    okButton.width = 150;
                    okButton.height = 40;
                    return okButton;
                }
                
                m_registerRewardScreen.layoutFunction = function defaultLayout(background:DisplayObject,
                                                                               animation:MovieClip, 
                                                                               descriptionText:TextField, 
                                                                               okButton:Button):void
                {
                    background.x = 0;
                    background.y = 0;
                    m_registerRewardScreen.addChild(background);
                    
                    animation.x = (background.width - animation.width) * 0.75;
                    animation.y = animation.height - 50;
                    m_registerRewardScreen.addChild(animation);
                    
                    // Wait for a short time before playing the animation
                    var delayTween:GTween = new GTween(null, 0.5, null, {onComplete:function(tween:GTween):void
                    {
                        animation.play();
                        
                        Audio.instance.playSfx("reward");
                        
                        var animationPlayTween:GTween = new GTween(null, 2.3, null, {onComplete:function(tween:GTween):void
                        {
                            animation.stop();
                            
                            descriptionText.alpha = 0.0;
                            var desciptionTween:GTween = new GTween(descriptionText, 1, {alpha:1.0});
                            m_registerRewardScreen.addChild(descriptionText);
                            
                            okButton.alpha = 0.0;
                            var buttonTween:GTween = new GTween(okButton, 1, {alpha:1.0});
                            m_registerRewardScreen.addChild(okButton);
                        }});
                    }});
                    
                    // Wait for animation to finish before zooming in the text and ok button
                    okButton.x = (background.width - okButton.width) * 0.5;
                    okButton.y = (background.height - okButton.height * 1.5);
                    
                    descriptionText.x = (background.width - descriptionText.width) * 0.5;
                    descriptionText.y = okButton.y - descriptionText.textHeight - 20;
                    
                    m_registerRewardScreen.x = (m_width - background.width) * 0.5;
                    m_registerRewardScreen.y = (m_height - background.height) * 0.5;
                }
                
                m_registerRewardScreen.drawAndLayout();
                
                addChild(m_registerRewardScreen);
            }
        }
        
        private function onRegisterFail():void
        {
            removeChild(m_loadingScreen);
        }
    }
}