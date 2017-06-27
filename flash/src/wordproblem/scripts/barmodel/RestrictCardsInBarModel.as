package wordproblem.scripts.barmodel
{
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import starling.display.DisplayObject;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.ExpressionComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.text.view.DocumentView;
    import wordproblem.engine.widget.DeckWidget;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.resource.AssetManager;
    
    /**
     * Script to handle disabling certain cards from being usable in the bar model area.
     * For example, supose we only want a term value to only be used once. If it has been
     * placed already, it should no longer be draggable from either the deck or the text.
     */
    public class RestrictCardsInBarModel extends BaseBarModelScript
    {
        private var m_termValuesAndNamesUsedBuffer:Vector.<String>;
        private var m_outUiEntityBuffer:Vector.<DisplayObject>;
        private var m_outDocumentViewsBuffer:Vector.<DocumentView>;
        
        /**
         * For tutorial/custom levels, we want to disable a term if it is used as a bar multiplier
         * or bar split value. List contains terms that should be disabled even if they don't explicitly
         * appear as a value in the bar model (i.e. its name does not appear)
         */
        private var m_termValuesManuallyDisabled:Vector.<String>;
        
        /**
         * This script has the side effect of automatically setting parts to be selectable anytime
         * the bar model has changed.
         */
        private var m_termValuesToIgnore:Vector.<String>;
        
        public function RestrictCardsInBarModel(gameEngine:IGameEngine, 
                                                expressionCompiler:IExpressionTreeCompiler, 
                                                assetManager:AssetManager, 
                                                id:String=null, 
                                                isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            m_termValuesAndNamesUsedBuffer = new Vector.<String>();
            m_outUiEntityBuffer = new Vector.<DisplayObject>();
            m_outDocumentViewsBuffer = new Vector.<DocumentView>();
            m_termValuesManuallyDisabled = new Vector.<String>();
            m_termValuesToIgnore = new Vector.<String>();
        }
        
        /**
         * This will clear all previously set term values.
         */
        public function setTermValuesManuallyDisabled(termValues:Vector.<String>):void
        {
            m_termValuesManuallyDisabled.length = 0;
            
            if (termValues != null)
            {
                for each (var termValue:String in termValues)
                {
                    m_termValuesManuallyDisabled.push(termValue);
                }
                checkValuesToApplyRestrictions(false);
            }
        }
        
        /**
         * In some tutorials we do not want this script to be automatically adjusting whether terms are selectable.
         * Add the values here to they are ignored
         * 
         * @termValues
         *      Note that the list will overwrite previous values
         */
        public function setTermValuesToIgnore(termValues:Vector.<String>):void
        {
            m_termValuesToIgnore.length = 0;
            
            if (termValues != null)
            {
                for each (var termValue:String in termValues)
                {
                    m_termValuesToIgnore.push(termValue);
                }
                checkValuesToApplyRestrictions(false);
            }
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            if (m_ready)
            {
                if (value)
                {
                    m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
                }
                else
                {
                    m_barModelArea.removeEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
                    
                    // Disable all active effects of the restrictions
                    // Problem if some other script did these changes, this would overwrite all these things
                    checkValuesToApplyRestrictions(true, false);
                }
            }
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            this.setIsActive(m_isActive);
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == GameEvent.BAR_MODEL_AREA_REDRAWN)
            {
                checkValuesToApplyRestrictions(false);
            }
        }
        
        /**
         *
         * @param forceSetToValue
         *      If true, we force the restrictions to automatically update to a particular value
         */
        private function checkValuesToApplyRestrictions(forceSetToValue:Boolean, forceValue:Boolean=false):void
        {
            // Iterate through the labels that have been used
            m_termValuesAndNamesUsedBuffer.length = 0;
            
            if (m_barModelArea == null)
            {
                return;
            }
            
            var barWholes:Vector.<BarWhole> = m_barModelArea.getBarModelData().barWholes;
            for each (var barWhole:BarWhole in barWholes)
            {
                for each (var barLabel:BarLabel in barWhole.barLabels)
                {
                    if (m_termValuesAndNamesUsedBuffer.indexOf(barLabel.value) < 0)
                    {
                        m_termValuesAndNamesUsedBuffer.push(barLabel.value);
                    }
                }
                
                if (barWhole.barComparison != null)
                {
                    if (m_termValuesAndNamesUsedBuffer.indexOf(barWhole.barComparison.value) < 0)
                    {
                        m_termValuesAndNamesUsedBuffer.push(barWhole.barComparison.value);
                    }
                }
            }
            var verticalLabels:Vector.<BarLabel> = m_barModelArea.getBarModelData().verticalBarLabels;
            for each (barLabel in verticalLabels)
            {
                if (m_termValuesAndNamesUsedBuffer.indexOf(barLabel.value) < 0)
                {
                    m_termValuesAndNamesUsedBuffer.push(barLabel.value);
                }
            }
            
            // Add in the manually restricted elements
            for each (var manuallyRestrictedTerm:String in m_termValuesManuallyDisabled)
            {
                m_termValuesAndNamesUsedBuffer.push(manuallyRestrictedTerm);
            }
            
            // If an expression is in the deck and is used somewhere in the bar model as a name, disable it
            // Otherwise re-enable it
            m_outUiEntityBuffer.length = 0;
            m_gameEngine.getUiEntitiesByClass(DeckWidget, m_outUiEntityBuffer);
            if (m_outUiEntityBuffer.length > 0 && m_outUiEntityBuffer[0] is DeckWidget)
            {
                var deckWidget:DeckWidget = m_outUiEntityBuffer[0] as DeckWidget;
                var expressionComponents:Vector.<Component> = deckWidget.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
                for (var i:int = 0; i < expressionComponents.length; i++)
                {
                    var expressionComponent:ExpressionComponent = expressionComponents[i] as ExpressionComponent;
                    var expressionUsedInBarModel:Boolean = m_termValuesAndNamesUsedBuffer.indexOf(expressionComponent.expressionString) >= 0;
                    if (forceSetToValue)
                    {
                        expressionUsedInBarModel = forceValue;
                    }
                    deckWidget.toggleSymbolEnabled(!expressionUsedInBarModel, expressionComponent.expressionString);
                }
            }
            
            // If an expression is draggable from the text and is used somewhere in the bar model as a name,
            // then disable it. Otherwise re-enable it
            m_outUiEntityBuffer.length = 0;
            m_gameEngine.getUiEntitiesByClass(TextAreaWidget, m_outUiEntityBuffer);
            if (m_outUiEntityBuffer.length > 0 && m_outUiEntityBuffer[0] is TextAreaWidget)
            {
                var textAreaWidget:TextAreaWidget = m_outUiEntityBuffer[0] as TextAreaWidget;
                expressionComponents = textAreaWidget.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
                for (i = 0; i < expressionComponents.length; i++)
                {
                    expressionComponent = expressionComponents[i] as ExpressionComponent;
                    
                    var expressionValue:String = expressionComponent.expressionString;
                    if (m_termValuesToIgnore.indexOf(expressionValue) < 0)
                    {
                        expressionUsedInBarModel = m_termValuesAndNamesUsedBuffer.indexOf(expressionValue) >= 0;
                        if (forceSetToValue)
                        {
                            expressionUsedInBarModel = forceValue;
                        }
                        m_outDocumentViewsBuffer.length = 0;
                        textAreaWidget.getDocumentViewsAtPageIndexById(expressionComponent.entityId, m_outDocumentViewsBuffer);
                        for each (var documentView:DocumentView in m_outDocumentViewsBuffer)
                        {
                            documentView.node.setSelectable(!expressionUsedInBarModel, true);
                            documentView.node.setTextDecoration((expressionUsedInBarModel) ? "line-through" : null);
                            documentView.alpha = (expressionUsedInBarModel) ? 0.3 : 1.0;
                        }
                    }
                }
            }
        }
    }
}