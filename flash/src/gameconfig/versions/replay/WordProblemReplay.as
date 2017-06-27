package gameconfig.versions.replay
{
    import cgs.server.logging.LoggingDataService;
    import cgs.server.logging.data.QuestData;
    
    import gameconfig.versions.replay.events.ReplayEvents;
    import gameconfig.versions.replay.state.ReplayGameState;
    import gameconfig.versions.replay.state.ReplayTitleState;
    
    import starling.events.Event;
    
    import wordproblem.WordProblemGameBase;
    import wordproblem.engine.GameEngine;
    import wordproblem.engine.level.WordProblemLevelData;
    import wordproblem.engine.scripting.ScriptParser;
    import wordproblem.engine.text.TextParser;
    import wordproblem.player.PlayerStatsAndSaveData;
    import wordproblem.saves.DummyCache;
    
    public class WordProblemReplay extends WordProblemGameBase
    {
        private var m_loggingDataService:LoggingDataService;
        private var m_lastRequestedQuestData:QuestData;

        public function WordProblemReplay()
        {
            super();
        }
        
        override protected function onStartingResourcesLoaded():void
        {
            var replayTitleState:ReplayTitleState = new ReplayTitleState(m_stateMachine, m_assetManager);
            replayTitleState.addEventListener(ReplayEvents.GO_TO_REPLAY_FOR_DQID, onGoToReplayForDqid);
            m_stateMachine.register(replayTitleState);
            
            var replayGameState:ReplayGameState = new ReplayGameState(
                m_stateMachine, this.gameEngine as GameEngine, m_expressionCompiler, m_assetManager, m_expressionSymbolMap);
            replayGameState.addEventListener(ReplayEvents.EXIT_REPLAY, onExitReplay);
            m_stateMachine.register(replayGameState);
            
            m_stateMachine.changeState(replayTitleState);
            
            var loggingDataService:LoggingDataService = m_logger.getCgsApi().createLoggingDataService(m_logger.getCgsUserProperties(false, null));
            m_loggingDataService = loggingDataService;
            
            m_playerStatsAndSaveData = new PlayerStatsAndSaveData(new DummyCache());
            m_scriptParser = new ScriptParser(this.gameEngine, m_expressionCompiler, m_assetManager, m_playerStatsAndSaveData);
            m_textParser = new TextParser();
        }
        
        private function onGoToReplayForDqid(event:Event, params:Object):void
        {
            var targetDqid:String = params.dqid;
            onLaunchReplayForDqid(targetDqid);
        }
        
        private function onExitReplay():void
        {
            m_stateMachine.changeState(ReplayTitleState);
        }
        
        private function onLaunchReplayForDqid(targetDqid:String):void
        {
            m_loggingDataService.requestQuestData(targetDqid, function(questData:QuestData, failed:Boolean):void
            {
                if (!failed && questData != null && questData.startData != null)
                {
                    m_lastRequestedQuestData = questData;
                    var questId:int = m_lastRequestedQuestData.questId;
                    
                    // The quest id for this replayed level must map to actual level content
                    m_gameServerRequester.getLevelDataFromId(questId.toString(), onGetLevelDataCallback);
                }
                else
                {
                    trace("Failed to retreive the level information.");
                }
            });
        }
        
        /*
        How to start a level with replay:
        The replay game state should be passed in the QuestData and the xml level that should be launched.
        */
        
        /**
         * Once level data is recieved we can launch the game.
         */
        private function onGetLevelDataCallback(success:Boolean, data:Object):void
        {
            if (success)
            {
                var levelName:String = "level_" + data.qid;
                if (data != null)
                {
                    var dataType:String = data["data_type"];
                    if (dataType == "url")
                    {
                        var fileLocation:String = data["cached_file_path"];
                        m_assetManager.enqueueWithName(fileLocation, levelName);
                        m_assetManager.loadQueue(function onProgress(ratio:Number):void
                        {
                            if (ratio == 1.0)
                            {
                                startReplayLevel(levelName);
                            }
                        });
                    }
                    else
                    {
                        var problemXml:XML = m_levelCreator.generateLevelFromData(
                            data.qid, 
                            data.bar_model_type, 
                            data.context, 
                            data.problem_text, 
                            data.background_id, 
                            data.additional_details
                        );
                        m_assetManager.addXml(levelName, problemXml);
                        startReplayLevel(levelName);
                    }
                }
            }
        }
        
        private function startReplayLevel(levelName:String):void
        {
            var problemXml:XML = m_assetManager.getXml(levelName);
            var levelData:WordProblemLevelData = m_levelCompiler.compileWordProblemLevel(
                problemXml, levelName, 0, 0, "", m_config, m_scriptParser, m_textParser);
            
            // Load the images specific to this problem into the asset manager.
            // Note that these images need to be later cleared out on the exit of a level
            // If several levels share common images it might be a good idea just to keep the textures cached.
            var extraResourcesLoaded:Boolean = false;
            var numExtraResources:int = 0;
            var imagesToLoad:Vector.<String> = levelData.getImagesToLoad();
            
            // For now we will use the source exactly as the id to fetch the images
            // this will free the id for images from naming restrictions and allow us
            // to easily detect if an image was already loaded
            for each (var imageSourceName:String in imagesToLoad)
            {
                if (m_assetManager.getTexture(imageSourceName) == null)
                {
                    numExtraResources++;
                    m_assetManager.enqueueWithName(imageSourceName, imageSourceName);
                }
            }
            
            // Texture atlas and audio can be directly loaded via starling's built-in asset manager functionality
            for each (var audioDataPart:Object in levelData.getAudioData())
            {
                // Only load the audio if it is of a url type
                if (audioDataPart.type == "url")
                {
                    var audioUrl:String = audioDataPart.src;
                    numExtraResources++;
                    m_assetManager.enqueue(audioUrl);    
                }
            }
            
            for each (var atlasList:Vector.<String> in levelData.getTextureAtlasesToLoad())
            {
                numExtraResources++;
                m_assetManager.enqueue(atlasList[0], atlasList[1]);
            }
            
            if (numExtraResources > 0)
            {
                m_assetManager.loadQueue(function(ratio:Number):void
                {
                    if (ratio == 1.0)
                    {
                        extraResourcesLoaded = true;
                        resourceBatchLoaded();
                    }
                });
            }
            else
            {
                extraResourcesLoaded = true;
                resourceBatchLoaded();
            }
            
            function resourceBatchLoaded():void
            {
                if (extraResourcesLoaded)
                {
                    m_stateMachine.changeState(ReplayGameState, Vector.<Object>([levelData, m_lastRequestedQuestData]));
                }
            }
        }
    }
}