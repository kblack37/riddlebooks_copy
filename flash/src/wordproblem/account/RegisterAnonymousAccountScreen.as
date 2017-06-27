package wordproblem.account
{
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    
    import cgs.CgsApi;
    import cgs.server.IntegrationDataService;
    import cgs.server.challenge.ChallengeService;
    import cgs.server.responses.CgsResponseStatus;
    import cgs.user.CgsUserProperties;
    import cgs.user.ICgsUser;
    
    import dragonbox.common.dispose.IDisposable;
    import dragonbox.common.ui.LoadingSpinner;
    
    import fl.controls.Button;
    import fl.controls.ComboBox;
    import fl.controls.TextInput;
    import fl.data.DataProvider;
    
    import wordproblem.AlgebraAdventureConfig;
    
    /**
     * This is the display object used to register an anonymous user to an authenticated
     * account.
     */
    public class RegisterAnonymousAccountScreen extends Sprite implements IDisposable
    {
        private static const MIN_USERNAME_LENGTH:int = 3;
        private static const MAX_USERNAME_LENGTH:int = 30;
        
        private static const GRADES:Array = new Array(
            {label:"", data:-1},
            {label:"1st", data:1}, 
            {label:"2nd", data:2}, 
            {label:"3rd", data:3}, 
            {label:"4th", data:4}, 
            {label:"5th", data:5}, 
            {label:"6th", data:6}, 
            {label:"7th", data:7},
            {label:"8th", data:8}, 
            {label:"9th", data:9}, 
            {label:"10th", data:10}, 
            {label:"11th", data:11}, 
            {label:"12th", data:12}
        );
        
        private static const GENDERS:Array = new Array(
            {label:"", data:-1},
            {label:"Girl", data:1},
            {label:"Boy", data:2}
        );
        
        /* Factory functions that should be overwritten to customize the appearance of this screen */
        
        /** Function to be called to create a background container */
        public var backgroundFactory:Function;
        /** Function to create some generic description graphic about what this screen is*/
        public var descriptionFactory:Function;
        /** Function to create title above the entire screen */
        public var titleLabelFactory:Function;
        /** Function for username label */
        public var userNameLabelFactory:Function;
        /** Function to create the username input */
        public var userNameInputFactory:Function;
        /** Function to create error notice for username */
        public var userNameErrorLabelFactory:Function;
        /** Function to create the icon that a name is acceptable*/
        public var userNameAcceptableIconFactory:Function;
        /** Function to create the icon that a name is not acceptable*/
        public var userNameNotAcceptableIconFactory:Function;
        /** Function to create the progress animation while checking username validity*/
        public var userNameLoadingSpinnerFactory:Function;
        /** Function to create the grade label */
        public var gradeLabelFactory:Function;
        /** Function to create the grade combo box */
        public var gradeComboBoxFactory:Function;
        /** Function to create the gender label */
        public var genderLabelFactory:Function;
        /** Function to create the gender combo box */
        public var genderComboBoxFactory:Function;
        /** Function to create the register button */
        public var registerButtonFactory:Function;
        /** Function to create the cancel button */
        public var cancelButtonFactory:Function;
        /** Function to create the message text if registration fails */
        public var registerFailMessageFactory:Function;
        
        /** Function to position and resize all elements */
        public var layoutFunction:Function;
        
        /**
         * The anonymous user that we want to register.
         * 
         * If null, then this screen is just a normal registration.
         */
        private var m_anonymousUser:ICgsUser;
        
        private var m_config:AlgebraAdventureConfig;
        
        /**
         * This service checks the username for us
         */
        private var m_userNameCheckService:IntegrationDataService;
        
        /**
         * This screen will need to communicate with the server in several places.
         * The api is required to send those messages.
         */
        private var m_cgsApi:CgsApi;
        
        /**
         * This class will control the messages to record information about challenge.
         * Need this to register new users with a challenge.
         */
        private var m_challengeService:ChallengeService;
        
        /**
         * Logging config properties
         */
        private var m_userLoggingProperties:CgsUserProperties;
        
        /**
         * Flag whether a request to check whether a user name is available is currently in progress
         */
        private var m_userNameAvailableInProgress:Boolean;
        
        /**
         * Need flag to keep track whether the last call to check the username returned that it
         * was available.
         */
        private var m_userNameAvailable:Boolean;
        
        /**
         * The username that is waiting to be sent later
         */
        private var m_userNameQueued:String;
        
        /**
         * Callback that is triggered if the user attempts to register. Need to wait for
         * a response from server.
         */
        private var m_registerStartCallback:Function;
        
        /**
         * Callback that is triggered if the user is able to successfully register.
         * 
         * param is the new user created
         */
        private var m_registerSuccessCallback:Function;
        
        /**
         * Callback that is triggered if the user was not able to register
         */
        private var m_registerFailCallback:Function;
        
        /**
         * Callback that is triggered if the user wants to cancel without registering
         */
        private var m_cancelCallback:Function;
        
        /* Components */
        
        /** The background image */
        private var m_background:DisplayObject;
        
        /** Title of the screen */
        private var m_titleLabel:TextField;
        
        /** 
         * Description says something like this is the registration screen, create an account
         * to earn a prize
         */
        private var m_description:DisplayObject;
        
        /** Describe the username */
        private var m_userNameLabel:TextField;
        
        /**
         * Input for player to enter a desired username
         */
        private var m_userNameInput:TextInput;
        
        /** Text to show username does not pass constraints*/
        private var m_userNameErrorLabel:TextField;
        
        /** Icon next to username input to indicate it is ok */
        private var m_userNameAcceptableIcon:DisplayObject;
        
        /** Icon next to grade box if it has a proper value */
        private var m_gradeSelectedIcon:DisplayObject;
        
        private var m_gradeNotSelectedIcon:DisplayObject;
        
        /** Icon next to gender box if it has a proper value */
        private var m_genderSelectedIcon:DisplayObject;
        
        private var m_genderNotSelectedIcon:DisplayObject;
        
        /** Icon next to username input to indicate it cannot be used*/
        private var m_userNameNotAcceptableIcon:DisplayObject;
        
        /**
         * The loading spinner that will indicate that we are in the middle
         * of checking whether a name is valid.
         */
        private var m_userNameLoadingSpinner:LoadingSpinner;
        
        /** Describe the grade combo box */
        private var m_gradeLabel:TextField;
        
        /**
         * A selector for player to input their grade.
         */
        private var m_gradeComboBox:ComboBox;
        
        /** Describe the gender combo box */
        private var m_genderLabel:TextField;
        
        /**
         * A selector for player to input their gender.
         */
        private var m_genderComboBox:ComboBox;
        
        /**
         * Button to submit credentials
         */
        private var m_registerButton:Button;
        
        /**
         * Button to cancel and exit this screen without registering.
         */
        private var m_cancelButton:Button;
        
        /**
         * Textfield explaining the account failed to be created
         */
        private var m_registerFailMessage:TextField;
        
        /**
         *
         * @param registerSuccessCallback
         *      callback(user:ICgsUser)
         */
        public function RegisterAnonymousAccountScreen(anonymousUser:ICgsUser,
                                                       config:AlgebraAdventureConfig,
                                                       cgsApi:CgsApi,
                                                       challengeService:ChallengeService,
                                                       userLoggingProperties:CgsUserProperties,
                                                       registerStartCallback:Function,
                                                       registerSuccessCallback:Function, 
                                                       registerFailCallback:Function, 
                                                       cancelCallback:Function)
        {
            super();
            
            m_anonymousUser = anonymousUser;
            m_config = config;
            m_userNameCheckService = cgsApi.createIntegrationDataService(userLoggingProperties);
            m_cgsApi = cgsApi;
            m_challengeService = challengeService;
            m_userLoggingProperties = userLoggingProperties;
            m_registerStartCallback = registerStartCallback;
            m_registerSuccessCallback = registerSuccessCallback;
            m_registerFailCallback = registerFailCallback;
            m_cancelCallback = cancelCallback;
            
            m_userNameAvailableInProgress = false;
            m_userNameQueued = null;
        }
        
        public function dispose():void
        {
            while (this.numChildren > 0)
            {
                this.removeChildAt(0);
            }
        }
        
        /**
         * Tell the screen to draw all the components and lay them out
         */
        public function drawAndLayout():void
        {
            m_background = backgroundFactory();
            
            m_titleLabel = titleLabelFactory();
            
            m_description = descriptionFactory();
            
            m_userNameLabel = userNameLabelFactory();
            
            m_userNameInput = userNameInputFactory();
            m_userNameInput.addEventListener(Event.CHANGE, onUserNameChanged);
            
            m_userNameErrorLabel = userNameErrorLabelFactory();
            
            m_userNameAcceptableIcon = userNameAcceptableIconFactory();
            m_userNameNotAcceptableIcon = userNameNotAcceptableIconFactory();
            m_userNameLoadingSpinner = userNameLoadingSpinnerFactory();
            
            m_gradeLabel = gradeLabelFactory();
            m_gradeComboBox = gradeComboBoxFactory();
            m_gradeComboBox.dataProvider = new DataProvider(GRADES);
            m_gradeComboBox.addEventListener(Event.CHANGE, onComboBoxChange);
            m_gradeSelectedIcon = userNameAcceptableIconFactory();
            m_gradeNotSelectedIcon = userNameNotAcceptableIconFactory();
            
            m_genderLabel = genderLabelFactory();
            m_genderComboBox = genderComboBoxFactory();
            m_genderComboBox.dataProvider = new DataProvider(GENDERS);
            m_genderComboBox.addEventListener(Event.CHANGE, onComboBoxChange);
            m_genderSelectedIcon = userNameAcceptableIconFactory();
            m_genderNotSelectedIcon = userNameNotAcceptableIconFactory();
            
            m_registerButton = registerButtonFactory();
            m_registerButton.addEventListener(MouseEvent.CLICK, onRegisterClick);
            m_registerButton.enabled = false;
            
            m_cancelButton = cancelButtonFactory();
            m_cancelButton.addEventListener(MouseEvent.CLICK, onCancelClick);
            
            m_registerFailMessage = registerFailMessageFactory();
            
            layoutFunction(
                m_background,
                m_titleLabel,
                m_description,
                m_userNameLabel, 
                m_userNameInput,
                m_userNameAcceptableIcon,
                m_userNameNotAcceptableIcon,
                m_userNameLoadingSpinner,
                m_userNameErrorLabel, 
                m_gradeLabel, 
                m_gradeComboBox,
                m_gradeSelectedIcon,
                m_gradeNotSelectedIcon,
                m_genderLabel,
                m_genderComboBox,
                m_genderSelectedIcon,
                m_genderNotSelectedIcon,
                m_registerButton,
                m_cancelButton,
                m_registerFailMessage
            );
        }

        private function onUserNameChanged(event:Event):void
        {
            var nameToCheck:String = m_userNameInput.text;
            if (!m_userNameAvailableInProgress)
            {
                // On every change of the user name send a request to check if that
                // name has already been taken.
                m_userNameAvailableInProgress = true;
                addChild(m_userNameLoadingSpinner);
                
                if (m_config.getTeacherCode() == null)
                {
                    m_userNameCheckService.checkUserNameAvailable(nameToCheck, onUserNameResponse);
                }
                else
                {
                    m_userNameCheckService.checkStudentNameAvailable(nameToCheck, null, m_config.getTeacherCode(), onUserNameResponse);
                }
            }
            // Only want one request at a time, so keep a queue of pending requests
            // If multiple requests waiting only need to send the most recent one
            else
            {
                m_userNameQueued = nameToCheck;
            }
            
            // On every request keep the register button locked
            checkRegisterEnabled();
        }
        
        private function onUserNameResponse(response:CgsResponseStatus):void
        {
            // Check that the name fits certain constraints, which are:
            // Has it been taken already
            // Is it between the minimum and maximum allowable lengths
            // Show error if it fails either of these
            m_userNameAvailable = response.success
            
            // If a username was already queued, we immediately send another request
            if (m_userNameQueued != null)
            {
                if (m_config.getTeacherCode() == null)
                {
                    m_userNameCheckService.checkUserNameAvailable(m_userNameQueued, onUserNameResponse);
                }
                else
                {
                    m_userNameCheckService.checkStudentNameAvailable(m_userNameQueued, null, m_config.getTeacherCode(), onUserNameResponse);
                }
                m_userNameQueued = null;
            }
            else
            {
                m_userNameAvailableInProgress = false;
                removeChild(m_userNameLoadingSpinner);
                checkRegisterEnabled();
            }
        }
        
        /**
         * Only enable the register button if all ui pieces have valid values
         */
        private function checkRegisterEnabled():void
        {
            // Remove all old icons
            var iconsToRemove:Vector.<DisplayObject> = new Vector.<DisplayObject>();
            iconsToRemove.push(m_userNameAcceptableIcon, m_userNameNotAcceptableIcon, m_gradeSelectedIcon, m_gradeNotSelectedIcon, m_genderSelectedIcon, m_genderNotSelectedIcon);
            for each (var iconToRemove:DisplayObject in iconsToRemove)
            {
                if (iconToRemove.parent)
                {
                    iconToRemove.parent.removeChild(iconToRemove);
                }
            }
            
            // Add icon whether a valid grade was selected
            // Check that grade is ok
            var gradeSelected:Boolean = (m_gradeComboBox.selectedItem.data > -1);
            var gradeIcon:DisplayObject = (gradeSelected) ? m_gradeSelectedIcon : m_gradeNotSelectedIcon;
            addChild(gradeIcon);
            
            // Add icon whether a valid gender was selected
            // Check that gender is ok
            var genderSelected:Boolean = (m_genderComboBox.selectedItem.data > -1);
            var genderIcon:DisplayObject = (genderSelected) ? m_genderSelectedIcon : m_genderNotSelectedIcon;
            addChild(genderIcon);
            
            // Keep disabled if any of the following conditions are met
            // username too short
            // username too long
            // waiting for username check
            // username taken
            var nameOk:Boolean = false;
            var errorText:String = "";
            var nameToCheck:String = m_userNameInput.text;
            if (nameToCheck.length < MIN_USERNAME_LENGTH)
            {
                errorText = "Username must be at least " + MIN_USERNAME_LENGTH + " characters long!";
            }
            else if (nameToCheck.length > MAX_USERNAME_LENGTH)
            {
                errorText = "Username must be less than " + MAX_USERNAME_LENGTH + " characters long!";
            }
            else if (m_userNameAvailableInProgress)
            {
            }
            else if (!m_userNameAvailable)
            {
                // Username was already taken, keep the register button locked
                errorText = "Username is not available!";
            }
            else
            {
                // Name is available
                // Also make sure that grade and gender are also selected
                nameOk = true;
            }
            
            // Set up the icon indicating a username is usable
            if (nameOk)
            {
                addChild(m_userNameAcceptableIcon);
            }
            else if (!m_userNameAvailableInProgress)
            {
                addChild(m_userNameNotAcceptableIcon);
            }
            
            m_userNameErrorLabel.text = errorText;
            m_registerButton.enabled = (nameOk && gradeSelected && genderSelected);
        }
        
        private function onRegisterClick(event:MouseEvent):void
        {
            // On a register, submit the desired username, password, and grade
            var userName:String = m_userNameInput.text;
            
            // Since we don't want the player to enter a password we automatically set it
            // the same as their username
            var password:String = userName;
            
            // If teacher code is used then register as a student
            // Get the grade and gender information
            var teacherCode:String = m_config.getTeacherCode();
            var grade:int = m_gradeComboBox.selectedItem.data;
            var gender:int = m_genderComboBox.selectedItem.data;
            
            // Note that it is possible the username was taken so a register might fail.
            if (m_anonymousUser != null)
            {
                // Bind account information to an existing user
                m_anonymousUser.createAccount(userName, null, null, grade, gender, teacherCode, onRegisterResponse);
            }
            else
            {
                if (teacherCode != null)
                {
                    m_anonymousUser = m_cgsApi.registerStudent(m_userLoggingProperties, userName, m_config.getTeacherCode(), grade, onRegisterResponse, gender);
                }
                else
                {
                    m_anonymousUser = m_cgsApi.registerUser(m_userLoggingProperties, userName, password, null, onRegisterResponse);
                }
            }
            
            if (m_registerStartCallback != null)
            {
                m_registerStartCallback();
            }
        }
        
        private function onRegisterResponse(response:CgsResponseStatus):void
        {
            // If response was successful then the new user should have replaced the anonymous one.
            if (response.success)
            {
                // Get the grade and gender information
                var grade:int = m_gradeComboBox.selectedItem.data;
                var gender:int = m_genderComboBox.selectedItem.data;
                
                // Register the account with a challenge
                if (m_challengeService != null)
                {
                    // Register the new user with a challenge so equations now become logged.
                    m_challengeService.registerMember(grade, onChallengeRegisterResponse);
                }
                else
                {
                    m_registerSuccessCallback(m_anonymousUser);
                }
            }
            else
            {
                // Show error force player to try creating an account again
                if (m_registerFailCallback != null)
                {
                    m_registerFailCallback();
                }
                
                // Re-check username
                onUserNameChanged(null);
                m_registerFailMessage.text = "Register failed, please try again!";
            }
        }
        
        private function onChallengeRegisterResponse(responseStatus:CgsResponseStatus):void
        {
            if (responseStatus.success)
            {
                m_registerSuccessCallback(m_anonymousUser);
            }
            else
            {
                // Show error
                m_registerFailMessage.text = "Register failed, please try again!";
            }
        }
        
        private function onCancelClick(event:MouseEvent):void
        {
            if (m_cancelCallback != null)
            {
                m_cancelCallback();
            }
        }
        
        private function onComboBoxChange(event:Event):void
        {
            this.checkRegisterEnabled();
        }
    }
}