package wordproblem.log
{
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    
    import wordproblem.AlgebraAdventureConfig;

    /**
     * There are several requests that do not fit in with the cgs common architecture and
     * require a separate server application interface. This class encapsulates communication
     * with that interface that handles commands that are specific only to this game.
     * 
     * For example the command to save a user created bar model
     */
    public class GameServerRequester
    {
        /*
        All game commands
        */
        private static const SAVE_CREATED_BAR_MODEL:String = "save_bar_model";
        private static const GET_LEVEL:String = "get_level";
        private static const GET_ALL_BAR_MODEL_LEVELS:String = "get_all_bar_model_levels";
        
        // TODO: This target url needs to change depending on whether this should target
        // local, dev, or production
        private static var SERVER_INTERFACE_URL:String;
        private static const LOCAL_INTERFACE_URL:String = "http://localhost/wordproblem/index.php";
        private static const DEV_INTERFACE_URL:String = "http://cgs-dev.cs.washington.edu/riddlebooks/server/index.php";
        
        /**
         * After the common command requester has gotten a response, we want to
         * return the command
         */
        private var m_mostRecentCommandCallback:Function;
        
        /*
        The return value of the requests need to be well defined, this is the lowest level
        interface
        */
        
        
        public function GameServerRequester(config:AlgebraAdventureConfig)
        {
            if (config != null)
            {
                if (config.getServerDeployment() == "local")
                {
                    SERVER_INTERFACE_URL = LOCAL_INTERFACE_URL;
                }
                else if (config.getServerDeployment() == "dev")
                {
                    SERVER_INTERFACE_URL = DEV_INTERFACE_URL;
                }
                else
                {
                    SERVER_INTERFACE_URL = DEV_INTERFACE_URL;
                }
            }
            else
            {
                SERVER_INTERFACE_URL = LOCAL_INTERFACE_URL;
            }
        }
        
        /**
         * Get back all information necessary for the application to run a playable level.
         * The information recieved could be a url to load the real level file or a bundle of
         * data such that the app can generate a psuedo level file.
         * 
         * @param id
         *      The id of the problem as stored on the db
         * @param callback
         *      Signature callback(success:Boolean, data:Object)
         *      data will be a json object recieved from the server
         * 
         */
        public function getLevelDataFromId(id:String, 
                                           callback:Function):void
        {
            var details:Object = {
                problem_id: id  
            };
            sendCustomCommand(GET_LEVEL, details, false, function(success:Boolean, responseData:*):void 
            {
                var details:Object = JSON.parse(responseData).details;
                callback(success, details);
            });
        }
        
        /**
         *
         * @param callback
         *      Signature callback(success:Boolean)
         */
        public function saveLevel(text:String, 
                                  barModelType:String, 
                                  backgroundId:String, 
                                  callback:Function):void
        {
            var details:Object = {
                text: text,
                type: barModelType,
                background_id: backgroundId
            };
            sendCustomCommand(SAVE_CREATED_BAR_MODEL, details, true, function(success:Boolean, responseData:*):void
            {
                callback(success, responseData);
            });  
        }
        
        /**
         *
         * @param callback
         *      Signature callback(success:Boolean, levelList:Array)
         */
        public function getAllBarModelLevels(callback:Function):void
        {
            sendCustomCommand(GET_ALL_BAR_MODEL_LEVELS, null, false, function(success:Boolean, responseData:*):void
            {
                var levelList:Array = JSON.parse(responseData).details;
                callback(success, levelList);
            });
        }
        
        /**
         * 
         * @param callback
         *      Signature callback(success:Boolean, responseData:*):void
         */
        private function sendCustomCommand(commandName:String, 
                                           details:Object, 
                                           isPost:Boolean, 
                                           callback:Function):void
        {
            m_mostRecentCommandCallback = callback;
            
            var urlLoader:URLLoader = new URLLoader();
            urlLoader.addEventListener(flash.events.Event.COMPLETE, onComplete);
            urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
            
            // Due to the way the server is set up, the command name must
            // always be appended at the end of the url
            var serverUrl:String = SERVER_INTERFACE_URL + "?command=" + commandName;
            if (!isPost)
            {
                serverUrl += "&";
            }
            
            // Send all the important information that define a word problem
            // The variable names must up in here and in the remote code that actually saves the
            // information.
            var variables:URLVariables = new URLVariables();
            variables["details"] = JSON.stringify(details);
            
            var submitProblemRequest:URLRequest = new URLRequest(serverUrl);
            submitProblemRequest.data = variables;
            submitProblemRequest.method = (isPost) ? URLRequestMethod.POST : URLRequestMethod.GET;
            
            urlLoader.load(submitProblemRequest);
        }
        
        private function onComplete(event:Event):void
        {
            // Get back the return
            var urlLoader:URLLoader = event.target as URLLoader;
            var rawData:String = urlLoader.data;
            
            disposeLoader(event.target as URLLoader);
            
            m_mostRecentCommandCallback(true, rawData);
        }
        
        private function onIoError(event:Event):void
        {
            disposeLoader(event.target as URLLoader);
            
            m_mostRecentCommandCallback(false, null);
        }
        
        private function disposeLoader(urlLoader:URLLoader):void
        {
            urlLoader.removeEventListener(flash.events.Event.COMPLETE, onComplete);
        }
    }
}