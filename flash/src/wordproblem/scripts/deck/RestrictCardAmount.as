package wordproblem.scripts.deck
{
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import starling.display.DisplayObject;
    import wordproblem.resource.AssetManager
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.widget.DeckWidget;
    import wordproblem.engine.widget.TermAreaWidget;
    import wordproblem.scripts.BaseGameScript;
    
    /**
     * This script is used to control the number of times that a particular card in the
     * deck can be added to one of the term areas.
     * 
     * Used primarily for tutorial levels, one example is we want the player to sum together
     * a few cards but want to ensure they can only pick distinct ones.
     */
    public class RestrictCardAmount extends BaseGameScript
    {
        /**
         * List of limits for each card.
         * 
         * Index needs to match with list of values
         */
        private var m_limits:Vector.<int>;
        
        /**
         * List of values that have restricted limits.
         * 
         * Index needs to match with the list of limits
         */
        private var m_values:Vector.<String>;
        
        private var m_termAreas:Vector.<TermAreaWidget>;
        
        /**
         * Temp buffer to get all cards in the existing term widgets
         */
        private var m_outWidgetLeaves:Vector.<BaseTermWidget>;
        
        public function RestrictCardAmount(gameEngine:IGameEngine, 
                                           expressionCompiler:IExpressionTreeCompiler, 
                                           assetManager:AssetManager, 
                                           id:String=null, 
                                           isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            
            m_limits = new Vector.<int>();
            m_values = new Vector.<String>();
            m_outWidgetLeaves = new Vector.<BaseTermWidget>();
        }
        
        override public function dispose():void
        {
            super.dispose();
            m_gameEngine.removeEventListener(GameEvent.TERM_AREAS_CHANGED, onTermAreasChanged);
        }
        
        public function setLimitForValue(limit:int, value:String):void
        {
            m_limits.push(limit);
            m_values.push(value);
        }
        
        /**
         * Remove all limits that had been set
         */
        public function resetAllLimits():void
        {
            m_limits.length = 0;
            m_values.length = 0;
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            // Get all term areas and listen for changes in their contents
            var termAreaDisplays:Vector.<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TermAreaWidget);
            m_termAreas = new Vector.<TermAreaWidget>();
            for each (var termAreaDisplay:DisplayObject in termAreaDisplays)
            {
                m_termAreas.push(termAreaDisplay as TermAreaWidget);
            }
            
            m_gameEngine.addEventListener(GameEvent.TERM_AREAS_CHANGED, onTermAreasChanged);
        }
        
        private function onTermAreasChanged():void
        {
            m_outWidgetLeaves.length = 0;
            
            var deckWidget:DeckWidget = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
            
            // First get all cards
            var i:int;
            var numTermAreas:int = m_termAreas.length;
            var termAreaWidget:TermAreaWidget;
            for (i = 0; i < numTermAreas; i++)
            {
                termAreaWidget = m_termAreas[i];
                termAreaWidget.getWidgetLeaves(m_outWidgetLeaves);
            }
            
            // Then search for each value with a limit and make sure the actual
            // number of cards with that same value do not exceed the limit.
            var numTotalCards:int = m_outWidgetLeaves.length;
            var numCardsWithLimit:int = m_values.length;
            var value:String;
            var limit:int;
            for (i = 0; i < numCardsWithLimit; i++)
            {
                value = m_values[i];
                limit = m_limits[i];
                
                var j:int;
                var baseTermWidget:BaseTermWidget;
                var numCardsWithSameValue:int = 0;
                for (j = 0; j < numTotalCards; j++)
                {
                    baseTermWidget = m_outWidgetLeaves[j];
                    if (baseTermWidget.getNode().data == value || baseTermWidget.getNode().getOppositeValue() == value)
                    {
                        numCardsWithSameValue++;
                    }
                }
                
                // Make sure card is hidden if it exceeds or is at the limit
                // Make sure it is visible if it is below
                if (numCardsWithSameValue >= limit)
                {
                    deckWidget.toggleSymbolEnabled(false, value);
                }
                else
                {
                    deckWidget.toggleSymbolEnabled(true, value);
                }
            }
        }
    }
}