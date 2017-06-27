package gameconfig.versions.replay.state
{
    import flash.geom.Rectangle;
    import flash.text.TextFormat;
    
    import cgs.server.logging.data.QuestData;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.state.BaseState;
    import dragonbox.common.state.IStateMachine;
    import dragonbox.common.time.Time;
    import dragonbox.common.ui.MouseState;
    import dragonbox.common.util.XColor;
    
    import feathers.controls.Button;
    import feathers.display.Scale9Image;
    
    import gameconfig.versions.replay.events.ReplayEvents;
    import gameconfig.versions.replay.scripts.ReplayBarModelLevel;
    import gameconfig.versions.replay.scripts.ReplayControllerScript;
    
    import starling.events.Event;
    
    import wordproblem.engine.GameEngine;
    import wordproblem.engine.component.ComponentManager;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.expression.SymbolData;
    import wordproblem.engine.level.CardAttributes;
    import wordproblem.engine.level.WordProblemLevelData;
    import wordproblem.engine.scripting.graph.ScriptNode;
    import wordproblem.engine.scripting.graph.selector.ConcurrentSelector;
    import wordproblem.engine.text.GameFonts;
    import wordproblem.engine.widget.WidgetUtil;
    import wordproblem.resource.AssetManager;
    
    /**
     * This is the main visualization screen for showing the replay of the game.
     */
    public class ReplayGameState extends BaseState
    {
        private var m_gameEngine:GameEngine;
        private var m_expressionCompiler:IExpressionTreeCompiler;
        private var m_assetManager:AssetManager;
        private var m_expressionSymbolMap:ExpressionSymbolMap;
        
        /**
         * Current information about the replay the player just started.
         */
        private var m_currentReplayData:QuestData;
        
        private var m_prebakedScripts:ScriptNode;
        
        private var m_exitButton:Button;
        
        public function ReplayGameState(stateMachine:IStateMachine, 
                                        gameEngine:GameEngine,
                                        expressionCompiler:IExpressionTreeCompiler,
                                        assetManager:AssetManager,
                                        expressionSymbolMap:ExpressionSymbolMap)
        {
            super(stateMachine);
            
            m_gameEngine = gameEngine;
            m_expressionCompiler = expressionCompiler;
            m_assetManager = assetManager;
            m_expressionSymbolMap = expressionSymbolMap;
            
            var buttonWidth:Number = 150;
            var buttonHeight:Number = 50;
            m_exitButton = WidgetUtil.createButton(
                m_assetManager,
                "button_white",
                "button_white",
                null,
                "button_white",
                "Exit",
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, 0xFFFFFF),
                null,
                new Rectangle(8, 8, 16, 16)
            );
            (m_exitButton.defaultSkin as Scale9Image).color = XColor.ROYAL_BLUE;
            (m_exitButton.hoverSkin as Scale9Image).color = XColor.BRIGHT_ORANGE;
            (m_exitButton.downSkin as Scale9Image).color = XColor.BRIGHT_ORANGE;
            m_exitButton.addEventListener(Event.TRIGGERED, onExitClicked);
            m_exitButton.width = buttonWidth;
            m_exitButton.height = buttonHeight;
        }
        
        override public function enter(fromState:Object, params:Vector.<Object>=null):void
        {
            addChild(m_gameEngine.getSprite());
            
            // The first element in the list should be the level data
            var levelData:WordProblemLevelData = params[0] as WordProblemLevelData;
            m_currentReplayData = params[1] as QuestData;
            var characterComponentManager:ComponentManager = new ComponentManager();
            
            const cardAttributes:CardAttributes = levelData.getCardAttributes();
            m_expressionSymbolMap.setConfiguration(
                cardAttributes
            );
            
            const symbolBindings:Vector.<SymbolData> = levelData.getSymbolsData();
            m_expressionSymbolMap.bindSymbolsToAtlas(symbolBindings);
            
            m_prebakedScripts = new ConcurrentSelector(-1);
            m_prebakedScripts.pushChild(new ReplayControllerScript(m_gameEngine, m_expressionCompiler, m_assetManager, m_currentReplayData));
            m_prebakedScripts.pushChild(new ReplayBarModelLevel(m_gameEngine, m_expressionCompiler, m_assetManager));
            
            m_gameEngine.enter(Vector.<Object>([levelData, characterComponentManager]));
            
            m_exitButton.y = 600 - m_exitButton.height;
            addChild(m_exitButton);
        }
        
        override public function exit(toState:Object):void
        {
            m_prebakedScripts.dispose();
            
            removeChild(m_gameEngine.getSprite());
            m_gameEngine.exit();
            m_expressionSymbolMap.clear();
            
            removeChild(m_exitButton);
        }
        
        override public function update(time:Time, mouseState:MouseState):void
        {
            m_prebakedScripts.visit();
            m_gameEngine.update(time, mouseState);
        }
        
        private function onExitClicked():void
        {
            dispatchEventWith(ReplayEvents.EXIT_REPLAY);
        }
    }
}