package wordproblem.creator.scripts
{
    import wordproblem.creator.ProblemCreateData;
    import wordproblem.creator.ProblemCreateEvent;
    import wordproblem.creator.WordProblemCreateState;
    import wordproblem.engine.barmodel.BarModelTypeDrawer;
    import wordproblem.engine.barmodel.BarModelTypeDrawerProperties;
    import wordproblem.engine.barmodel.view.BarModelView;
    import wordproblem.engine.expression.SymbolData;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    
    /**
     * Whenever the user applies new highlight and changes what the value is of a part of
     * the bar model, we update the bar model view to reflect that new value within that structure.
     * 
     * IMPORTANT:
     * This class is performing texture disposal, which has the potential to cause several problems
     * in other parts of the application if we are not careful.
     */
    public class ChangeBarModelArea extends BaseProblemCreateScript
    {
        /**
         * Keep track of the colors per element since the last refresh.
         * Use this to determine if a texture refresh for that element is necessary
         */
        private var m_elementIdToCurrentColor:Object;
        
        /**
         * Keep track of the abbreviated name on the card per element
         * Use this to determine if a texture refresh for that element is necessary
         */
        private var m_elementIdToCurrentAbbreviatedName:Object;
        
        private var m_barModelTypeDrawer:BarModelTypeDrawer;
        
        public function ChangeBarModelArea(createState:WordProblemCreateState,
                                           id:String=null, 
                                           isActive:Boolean=true)
        {
            super(createState, null, id, isActive);
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            
            if (m_isReady)
            {
                m_createState.removeEventListener(ProblemCreateEvent.BAR_PART_VALUE_CHANGED, bufferEvent);
                m_createState.removeEventListener(ProblemCreateEvent.BACKGROUND_AND_STYLES_CHANGED, bufferEvent);
                if (value)
                {
                    m_createState.addEventListener(ProblemCreateEvent.BAR_PART_VALUE_CHANGED, bufferEvent);
                    m_createState.addEventListener(ProblemCreateEvent.BACKGROUND_AND_STYLES_CHANGED, bufferEvent);
                }
            }
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            m_barModelTypeDrawer = new BarModelTypeDrawer();
            
            m_elementIdToCurrentColor = {};
            m_elementIdToCurrentAbbreviatedName = {};
            
            var problemData:ProblemCreateData = m_createState.getCurrentLevel();
            var highlightColors:Object = (problemData.currentlySelectedBackgroundData != null) ?
                problemData.currentlySelectedBackgroundData.highlightColors : null;
            
            var elementToUserAssignedValue:Object = problemData.elementIdToDataMap;
            for (var elementId:String in elementToUserAssignedValue)
            {
                m_elementIdToCurrentAbbreviatedName[elementId] = elementToUserAssignedValue[elementId].value;
                if (highlightColors != null && highlightColors.hasOwnProperty(elementId))
                {
                    m_elementIdToCurrentColor[elementId] = highlightColors[elementId];
                }
                else
                {
                    m_elementIdToCurrentColor[elementId] = 0;
                }
            }
            
            refreshBarModelArea();            
            setIsActive(m_isActive);
        }
        
        override public function visit():int
        {
            if (m_isActive && m_isReady)
            {
                super.visit();
            }
            return ScriptStatus.FAIL;
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == ProblemCreateEvent.BAR_PART_VALUE_CHANGED || eventType == ProblemCreateEvent.BACKGROUND_AND_STYLES_CHANGED)
            {
                refreshBarModelArea();
            }
        }
        
        private function refreshBarModelArea():void
        {
            // This entire function block should be made into a common function
            var problemData:ProblemCreateData = m_createState.getCurrentLevel();
            var highlightColors:Object = (problemData.currentlySelectedBackgroundData != null) ?
                problemData.currentlySelectedBackgroundData.highlightColors : null;
            var styleForType:Object = m_barModelTypeDrawer.getStyleObjectForType(problemData.barModelType, highlightColors);
            
            var barModelArea:BarModelView = m_createState.getWidgetFromId("barModelArea") as BarModelView;
            barModelArea.getBarModelData().clear();
            barModelArea.redraw(false, false);
            
            var elementToUserAssignedValue:Object = problemData.elementIdToDataMap;
            for (var elementId:String in elementToUserAssignedValue)
            {
                // This type drawer property is what will set the values for drawing the bar model
                var stylesForElement:BarModelTypeDrawerProperties = styleForType[elementId];
                // For bar model labels, make sure that by default the elements are always
                // representative of 'a', 'b', 'c', '?' 
                stylesForElement.alias = elementId;
                var userAssignedValueForElementId:String = elementToUserAssignedValue[elementId].value;
                if (userAssignedValueForElementId != null && userAssignedValueForElementId != "")
                {
                    // the expression symbol map should be producing the right card
                    stylesForElement.value = userAssignedValueForElementId;
                }
                
                // If the color or abbreviated name of an element has been changed, its appearance will be changed.
                // Dispose the old texture
                if (highlightColors[elementId] != m_elementIdToCurrentColor[elementId] || 
                    userAssignedValueForElementId != m_elementIdToCurrentAbbreviatedName[elementId])
                {
                    m_elementIdToCurrentColor[elementId] = highlightColors[elementId];
                    m_elementIdToCurrentAbbreviatedName[elementId] = userAssignedValueForElementId;
                    barModelArea.getExpressionSymbolMap().resetTextureForValue(elementId);
                }
                
                var symbolDataForElement:SymbolData = barModelArea.getExpressionSymbolMap().getSymbolDataFromValue(elementId);
                symbolDataForElement.backgroundColor = styleForType[elementId].color;
                
                // Assigning this value determines what the user will actually see on the screen
                symbolDataForElement.abbreviatedName = (userAssignedValueForElementId != null && userAssignedValueForElementId != "") ?
                    userAssignedValueForElementId : elementId;
            }
            
            // Completely redraw the bar model on any change
            var outElementIdsToBarModelIds:Object = {};
            
            m_barModelTypeDrawer.drawBarModelIntoViewFromType(problemData.barModelType, barModelArea, styleForType, outElementIdsToBarModelIds);
            problemData.setPartNameToIdsMap(outElementIdsToBarModelIds);
            barModelArea.redraw(false, true);
        }
    }
}