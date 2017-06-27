package wordproblem
{
    import cgs.server.logging.CGSServerProps;
    
    import dragonbox.common.util.XString;
    
    import gameconfig.commonresource.LoadingScreenResources;
    
    import wordproblem.engine.level.LevelRules;
    import wordproblem.resource.bundles.ResourceBundle;

    /**
     * The configuration file for the game. In addition it holds a reference to default settings for attributes
     * like the widgets to use and rules. Levels can override these values.
     * 
     * A critically important part of this is that it holds a reference all resource bundles
     * that need to be loaded at startup.
     * 
     * From the perspective of the game, it will treat embedded vs dynamically loaded resources
     * as exactly the same. Stuff like level sequences or starting game images will all be
     * part of some resource bundle.
     */
    public class AlgebraAdventureConfig
    {
        // Default language localization file
        // The strings in the files are random bits of text tagged across various ui components
        // Translation of wordproblem content or item/achievement descriptions are contained in
        // other data files
        [Embed(source="/../assets/strings/en.xml", mimeType="application/octet-stream")] 
        private static const STRINGS_EN:Class;
        
        /*
        Debugging flags, if these are specified in the config xml they are overriden from their intial values
        */
        /** If we don't want the game to link into server for the logging set this to true */
        public var debugNoServerLogin:Boolean;
        
        /** Should all levels be unlocked at the start */
        public var unlockAllLevels:Boolean;
        
        public var showUserNameInSelectScreen:Boolean = true;
        
        /**
         * If true, then the user should be allowed to navigate to the level select screen
         * to replay unlocked levels.
         */
        public var allowLevelSelect:Boolean;
        
        public var overrideLevelSkippable:Boolean;
        public var overrideLevelSkippableValue:Boolean;
        
        /**
         * Mapping from a group name to a list of ResourceBundles
         */
        protected var m_nameToBundleList:Object;
        
        /**
         * Store data about logging
         */
        protected var m_versionId:int;
        protected var m_categoryId:int;
        protected var m_challengeId:int;
        protected var m_experimentId:int;
        protected var m_serverDeployment:String;
        protected var m_useHttps:Boolean;
        protected var m_enableABTesting:Boolean;
        protected var m_doLogQuests:Boolean;
        protected var m_useActiveServer:Boolean;
        
        protected var m_defaultLevelRules:LevelRules;
        protected var m_defaultTextStyle:String;
        
        protected var m_width:Number;
        protected var m_height:Number;
        protected var m_fps:Number;
        protected var m_usernameAsPassword:Boolean;
        protected var m_enableConsole:Boolean;
        protected var m_enableUnlockLevelsShortcut:Boolean;
        protected var m_lockAnonymousThreshold:int;
        protected var m_fakeTeacherUid:String;
        protected var m_teacherCode:String;
        
        /**
         * Used just for playtests where players have a preassigned username
         */
        protected var m_usernamePrefix:String;
        
        protected var m_defaultFontFamily:String;
        
        /**
         * Used by the asset manager if we want to force the relative paths of all dynamically
         * loaded resources to be a specific location.
         * 
         * Subclasses MUST set this to an initial value
         */
        protected var m_resourcePathBase:String;
        
        protected var m_saveDataKey:String;
        protected var m_saveDataToServer:Boolean;
        protected var m_allowResetData:Boolean;
        
        /**
         * Specify some value if the game should show terms of service before a new user is allowed to play.
         */
        protected var m_tosKey:String;
        
        public function AlgebraAdventureConfig()
        {
            m_nameToBundleList = {};
            instantiateResourceBundles();
            
            // The loading screen NEEDS these params even before the config might be loaded
            m_width = 800;
            m_height = 600;
            m_fps = 30;
        }
        
        /**
         * The setup of this configuration object occurs in multiple phases.
         * At start up there are some properties that need to be fixed (i.e. loading screen
         * resources and dimensions of the app). Everything else can be part of a separate data file
         * loading dynamically (late binding allows easier modificiation of app properties like
         * resource url or logging properties after release).
         * 
         * This function is used to finish populating the config data
         * 
         * @param data
         *      The contents of the xml file with configuration tags
         */
        public function readConfigFromData(configXml:XML):void
        {
            // Parse out logging options
            var loggingXml:XML = configXml.elements("logging")[0];
            m_versionId = parseInt(loggingXml.elements("versionId")[0].@value);
            m_categoryId = parseInt(loggingXml.elements("categoryId")[0].@value);
            m_challengeId = parseInt(loggingXml.elements("challengeId")[0].@value);
            m_experimentId = parseInt(loggingXml.elements("experimentId")[0].@value);
            m_useHttps = XString.stringToBool(getValueFromElementName(loggingXml, "useHttps", "false"));
            m_enableABTesting = XString.stringToBool(getValueFromElementName(loggingXml, "enableABTesting", "false"));
            var serverDeployment:String = loggingXml.elements("deployment")[0].@value;
            if (serverDeployment == "production")
            {
                serverDeployment = CGSServerProps.PRODUCTION_SERVER;
            }
            else if (serverDeployment == "local")
            {
                serverDeployment = CGSServerProps.LOCAL_SERVER;
            }
            else if (serverDeployment == "staging")
            {
                serverDeployment = CGSServerProps.STAGING_SERVER;   
            }
            else
            {
                serverDeployment = CGSServerProps.DEVELOPMENT_SERVER;   
            }
            m_serverDeployment = serverDeployment;
            
            m_doLogQuests = XString.stringToBool(getValueFromElementName(loggingXml, "doLogQuests", "true"));
            m_useActiveServer = XString.stringToBool(getValueFromElementName(loggingXml, "useActiveServer", "true"));
            
            // Parse out default text style options
            var styleAttributesXml:XML = configXml.elements("style")[0];
            m_defaultTextStyle = styleAttributesXml;
            
            // Parse out the settings
            var settingsXml:XML = configXml.elements("settings")[0];
            m_width = parseInt(settingsXml.elements("width")[0].@value);
            m_height = parseInt(settingsXml.elements("height")[0].@value);
            m_fps = parseInt(settingsXml.elements("fps")[0].@value);
            m_usernameAsPassword = XString.stringToBool(getValueFromElementName(settingsXml, "usernameAsPassword", "true"));
            m_enableConsole = XString.stringToBool(getValueFromElementName(settingsXml, "enableConsole", "true"));
            m_enableUnlockLevelsShortcut = XString.stringToBool(getValueFromElementName(settingsXml, "enableUnlockLevelsShortcut", "false"));
            m_lockAnonymousThreshold = parseInt(settingsXml.elements("lockAnonymousThreshold")[0].@value);
            m_fakeTeacherUid = getValueFromElementName(settingsXml, "fakeTeacherUid", null);
            m_teacherCode = getValueFromElementName(settingsXml, "teacherCode", null);
            m_tosKey = getValueFromElementName(settingsXml, "tosKey", null);
            
            // Treat empty string as null
            m_usernamePrefix = getValueFromElementName(settingsXml, "usernamePrefix", null);
            if (m_usernamePrefix == "")
            {
                m_usernamePrefix = null;
            }
            
            this.allowLevelSelect = XString.stringToBool(getValueFromElementName(settingsXml, "allowLevelSelect", "true"));
            this.overrideLevelSkippable = XString.stringToBool(getValueFromElementName(settingsXml, "overrideLevelSkippable", "false"));
            this.overrideLevelSkippableValue = XString.stringToBool(getValueFromElementName(settingsXml, "overrideLevelSkippableValue", "true"));
            
            m_defaultFontFamily = getValueFromElementName(settingsXml, "defaultFontFamily", "Bookworm");
            
            // Debug setting, if not present then use default
            debugNoServerLogin = XString.stringToBool(getValueFromElementName(settingsXml, "debugNoServerLogin", "false"));
            unlockAllLevels = XString.stringToBool(getValueFromElementName(settingsXml, "debugUnlockAllLevels", "false"));
            
            // Parse out default rules options
            var defaultRulesXml:XML = configXml.elements("defaultRules")[0];
            m_defaultLevelRules = LevelRules.createRulesFromXml(defaultRulesXml);
            
            m_resourcePathBase = getValueFromElementName(settingsXml, "resourcePathBase", null);
            if (m_resourcePathBase == "")
            {
                m_resourcePathBase = null;
            }
            
            m_saveDataKey = getValueFromElementName(settingsXml, "saveDataKey", "");
            m_saveDataToServer = XString.stringToBool(getValueFromElementName(settingsXml, "saveDataToServer", "true"));
            m_allowResetData = XString.stringToBool(getValueFromElementName(settingsXml, "allowResetData", "true"));
        }
        
        private function getValueFromElementName(xml:XML, elementName:String, defaultValue:String):String
        {
            var value:String = defaultValue;
            if (xml.elements(elementName).length() > 0)
            {
                value = xml.elements(elementName)[0].@value;
            }
            return value;
        }
        
        /**
         * Get back the xml localization file used to populate the string table.
         * (NOTE: the string table will not contain translations for text for data files
         * that are embedded or loaded separately, for example the level files)
         * 
         * A configuration should override this if it is using a separate language.
         */
        public function getLocalizationClassForStringTable():Class
        {
            return STRINGS_EN;
        }
        
        public function getDefaultFontFamily():String
        {
            return m_defaultFontFamily;
        }
        
        /**
         * Default rules to apply to a level
         */
        public function getDefaultLevelRules():LevelRules
        {
            return m_defaultLevelRules;
        }
        
        /**
         * Default style of the text elements when displaying a word problem.
         * 
         * @return
         *      A json string of the styling properties to apply
         */
        public function getDefaultTextStyle():String
        {
            return m_defaultTextStyle;
        }
        
        public function getWidth():Number
        {
            return m_width;
        }
        
        public function getHeight():Number
        {
            return m_height;
        }
        
        public function getFps():Number
        {
            return m_fps;
        }
        
        public function getUsernameAsPassword():Boolean
        {
            return m_usernameAsPassword;
        }
        
        /**
         * Get whether the dev console should appear
         */
        public function getEnableConsole():Boolean
        {
            return m_enableConsole;
        }
        
        /**
         * Get whether the keyboard shortcut to unlock all levels should be allowed
         * for this version.
         * 
         * @return
         *      true if user can make all levels plyable via the level select screen
         */
        public function getEnableUnlockLevelsShortcut():Boolean
        {
            return m_enableUnlockLevelsShortcut;
        }
        
        /**
         * Get the number of levels that an anonymous user can play before being prompted to
         * create an account.
         * 
         * @return
         *      A negative value indicates anonymous users should never be locked out.
         */
        public function getLockAnonymousThreshold():int
        {
            return m_lockAnonymousThreshold;
        }
        
        /**
         * Get the teacher uid that all brand new accounts should be bound.
         * This is purely a work around to handle the case where we want to save grade+gender
         * information for user where it didn't make sense for them to be in a classroom.
         * 
         * @return
         *      null if no fake teacher uid should be used
         */
        public function getFakeTeacherUid():String
        {
            return m_fakeTeacherUid;
        }
        
        /**
         * Get the teacher code that should be applied to the login and registration process.
         * If not null, all logins and new account will be bound to the teacher with the matching code.
         * 
         * @return
         *      null if no teacher code is to be used
         */
        public function getTeacherCode():String
        {
            return m_teacherCode;
        }
        
        /**
         * The teacher code might come from the url, if the loaded config file did not
         * set it then set to that value.
         * 
         * @param value
         *      New teacher code that is most likely pulled from url variable
         */
        public function setTeacherCode(value:String):void
        {
            m_teacherCode = value;   
        }
        
        /**
         * Get back a prefix to populate the login with. Used only for playtests where players already
         * have a username assigned to them
         * 
         * @return
         *      null if no username should be assigned
         */
        public function getUsernamePrefix():String
        {
            return m_usernamePrefix;
        }
        
        public function getLoggingCategoryId():int
        {
            return m_categoryId;
        }
        
        public function getLoggingVersionId():int
        {
            return m_versionId;
        }
        
        public function getChallengeId():int
        {
            return m_challengeId;
        }
        
        public function getServerDeployment():String
        {
            return m_serverDeployment;
        }
        
        public function getABExperimentId():int
        {
            return m_experimentId;
        }
        
        public function getUseHttps():Boolean
        {
            return m_useHttps;
        }
        
        public function getEnableABTesting():Boolean
        {
            return m_enableABTesting;
        }
        
        /**
         * Get whether game sessions for this version should even send any quest logs.
         * Used if we want to go offline and don't need to be be recording player actions.
         */
        public function getDoLogQuests():Boolean
        {
            return m_doLogQuests;
        }
        
        /**
         * The cgs server code for the dev and prd environments have a testing location and an active
         * deployment location. If true, then application communicates with the server code that is live
         * to other links on the internet.
         * 
         * Only false in the rare instances when we want to test if this app works with modified server
         */
        public function getUseActiveServer():Boolean
        {
            return m_useActiveServer;
        }
        
        /**
         * There are instances where we want to modify the relative path where the resources are loaded.
         * Ex.) The game is hosted on another web server that does not
         * have the resource files there. The paths need to be absolute.
         * 
         * @return
         *      If not null, all loaded resources should have relative paths to resolve to
         *      the given base.
         */
        public function getResourcePathBase():String
        {
            return m_resourcePathBase;
        }
        
        /**
         * If not null or not empty, the application should attempt to use the no sql data storage.
         * This key allows versioning of data with that storage.
         */
        public function getSaveDataKey():String
        {
            return m_saveDataKey;
        }
        
        /**
         *
         * @return
         *      false if save data should be stored locally, meaning a player changing browsers or machines
         *      will lose their progress.
         */
        public function getSaveDataToServer():Boolean
        {
            return m_saveDataToServer;
        }
        
        /**
         * If true, allow the user to reset the save data. Mostly this should be false for
         * releases, best used for testing purposes
         */
        public function getAllowResetData():Boolean
        {
            return m_allowResetData;
        }
        
        /**
         *
         * @return
         *      If null or empty string, game shouldn't show Terms of Service screen. Otherwise the value should
         *      map to key somewhere else in the CGS database with a list of TOS documents.
         */
        public function getTosKey():String
        {
            return m_tosKey;
        }
        
        /**
         * The application may need to load bundles at different points in time.
         * Will need to bind a name to the list of bundles.
         */
        public function getResourceBundlesByName(name:String):Vector.<ResourceBundle>
        {
            var bundleList:Vector.<ResourceBundle> = null;
            if (m_nameToBundleList.hasOwnProperty(name))
            {
                bundleList = m_nameToBundleList[name];
            }
            return bundleList;
        }
        
        /**
         * Get back the main application entry point class.
         * (In most cases we will use the default app)
         */
        public function getMainGameApplication():Class
        {
            return null;
        }

        /**
         * All subclasses should override this to fill in the resource bundles.
         * By default this includes the loading screen resources since every version
         * will probably need those assets
         */
        protected function instantiateResourceBundles():void
        {
            m_nameToBundleList["loadingScreen"] = Vector.<ResourceBundle>([
                new LoadingScreenResources()
            ]);
        }
    }
}