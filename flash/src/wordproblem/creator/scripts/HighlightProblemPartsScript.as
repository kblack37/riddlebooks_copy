package wordproblem.creator.scripts
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import dragonbox.common.ui.MouseState;
    
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    
    import wordproblem.creator.EditableTextArea;
    import wordproblem.creator.ProblemCreateEvent;
    import wordproblem.creator.WordProblemCreateState;
    import wordproblem.display.Layer;
    import wordproblem.engine.barmodel.view.BarComparisonView;
    import wordproblem.engine.barmodel.view.BarLabelView;
    import wordproblem.engine.barmodel.view.BarModelView;
    import wordproblem.engine.barmodel.view.BarSegmentView;
    import wordproblem.engine.barmodel.view.BarWholeView;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.resource.AssetManager;
    
    /**
     * This script controls all the logic related to the player clicking on various toggle
     * buttons to highlight certain portions of the text.
     */
    public class HighlightProblemPartsScript extends BaseProblemCreateScript
    {
        private var m_mouseState:MouseState;
        
        private var m_globalPointBuffer:Point;
        private var m_localPointBuffer:Point;
        private var m_boundsBuffer:Rectangle;
        
        private var m_editableTextArea:EditableTextArea;
        
        /**
         * The active bar model id selected by the player that indicates the part of the
         * bar model that is to be highlighted in the text.
         * 
         * We do our own book keeping to keep track of which item is currently selected.
         * The problem is that the feathers list component seems to require at least one element to
         * be marked as selected.
         * 
         * If null, nothing is selected
         */
        private var m_activeHighlightId:String;
        
        /**
         * After the user activated the toggle, did they press somewhere in the text area
         * to start a highlight
         */
        private var m_startedHighlightInTextArea:Boolean;
        
        /**
         * To fix this timing issue
         * Problem: Click on button, then click on another, both get set to unselected at the end
         * 
         * Each object is a pair {button:<button that was selected>, isSelected:<was button set at that click}
         */
        private var m_bufferedToggleChangeEvents:Vector.<Object>;
        
        /**
         * We want to blink the active highlight when the user is coloring the text, however since a redraw may
         * cause the display for the highlight to be recreated we cannot apply a tween to just display directly.
         * Instead we adjust the alpha property in this object and set the current highlight display to that
         * property
         */
        private var m_highlightTransparencyData:Object;
        private var m_highlightBlinkTween:Tween;
        
        public function HighlightProblemPartsScript(wordproblemCreateState:WordProblemCreateState,
                                                    mouseState:MouseState,
                                                    assetManager:AssetManager,
                                                    id:String=null, 
                                                    isActive:Boolean=true)
        {
            super(wordproblemCreateState, assetManager, id, isActive);
            
            m_mouseState = mouseState;
            
            m_globalPointBuffer = new Point();
            m_localPointBuffer = new Point();
            m_boundsBuffer = new Rectangle();
            m_bufferedToggleChangeEvents = new Vector.<Object>();

            m_activeHighlightId = null;
            m_highlightTransparencyData = {alpha:1.0};
        }
        
        override protected function onLevelReady():void
        {
            // TODO: We have a timing dependency, on prepopulating the text we want to immediately modify the text list with predefined highlights
            // At that point however, the list elements may not exist. Thus we only want to apply the highlights AFTER the list elements have been created.
            super.onLevelReady();
            
            m_editableTextArea = m_createState.getWidgetFromId("editableTextArea") as EditableTextArea;
            setIsActive(m_isActive);
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            if (m_isReady)
            {
                m_createState.removeEventListener(ProblemCreateEvent.SELECT_BAR_ELEMENT, bufferEvent);
                m_editableTextArea.removeEventListener(ProblemCreateEvent.HIGHLIGHT_REFRESHED, bufferEvent);
                if (value)
                {
                    m_createState.addEventListener(ProblemCreateEvent.SELECT_BAR_ELEMENT, bufferEvent);
                    m_editableTextArea.addEventListener(ProblemCreateEvent.HIGHLIGHT_REFRESHED, bufferEvent);
                }
            }
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == ProblemCreateEvent.SELECT_BAR_ELEMENT)
            {
                if (param.hasOwnProperty("id"))
                {
                    var selectedId:String = param.id;
                    
                    // Note that the list always has something as selected even though for our usage it should be possible for
                    // nothing to be selected.
                    // we keep track for ourselves what was marked as selected
                    if (m_activeHighlightId == null)
                    {
                        // Going from unselected to selected
                        m_activeHighlightId = selectedId;
                    }
                    else
                    {
                        // If we had tracked that something was already selected, then either the user pressed the
                        // same item to unselect it OR they selected a brand new item
                        if (selectedId == m_activeHighlightId)
                        {
                            m_activeHighlightId = null;
                        }
                        else
                        {
                            m_activeHighlightId = selectedId;
                        }
                    }
                }
                
                m_bufferedToggleChangeEvents.push({id: m_activeHighlightId});
            }
            else if (eventType == ProblemCreateEvent.HIGHLIGHT_REFRESHED)
            {
                // Re-adjust the model to mark elements as highlighted
                var highlights:Object = m_editableTextArea.getHighlightTextObjects();
                var partsInBarModel:Object = m_createState.getCurrentLevel().elementIdToDataMap;
                for (var partName:String in partsInBarModel)
                {
                    partsInBarModel[partName].highlighted = highlights.hasOwnProperty(partName);
                }
            }
        }
        
        override public function visit():int
        {
            m_globalPointBuffer.x = m_mouseState.mousePositionThisFrame.x;
            m_globalPointBuffer.y = m_mouseState.mousePositionThisFrame.y;
            
            var editableTextArea:EditableTextArea = m_editableTextArea;
            if (Layer.getDisplayObjectIsInInactiveLayer(editableTextArea))
            {
                return ScriptStatus.FAIL;
            }
            
            editableTextArea.getBounds(editableTextArea.stage, m_boundsBuffer);
            
            // Current limits to show the arrows 0 at the top
            // if scroll position exceeds zero, show the top arrow
            // if scroll position is less than ?, show the bottom arrow
            
            if (editableTextArea.parent != null)
            {
                editableTextArea.parent.globalToLocal(m_globalPointBuffer, m_localPointBuffer);
                m_boundsBuffer.x = editableTextArea.x;
                m_boundsBuffer.y = editableTextArea.y;
                m_boundsBuffer.width = editableTextArea.getConstraints().width;
                m_boundsBuffer.height = editableTextArea.getConstraints().height;
                var currentMousePointInTextArea:Boolean = m_boundsBuffer.containsPoint(m_localPointBuffer);
    
                super.visit();
                
                if (m_bufferedToggleChangeEvents.length > 0)
                {
                    for each (var bufferedToggleChange:Object in m_bufferedToggleChangeEvents)
                    {
                        toggleBarModelTransparency();
                        
                        if (m_activeHighlightId != null)
                        {
                            m_createState.dispatchEventWith(ProblemCreateEvent.USER_HIGHLIGHT_STARTED, false, {id: m_activeHighlightId});
                            editableTextArea.addEmphasisToAllText();
                        }
                        else
                        {
                            m_createState.dispatchEventWith(ProblemCreateEvent.USER_HIGHLIGHT_CANCELLED, false, null);
                            editableTextArea.removeEmphasisFromAllText();
                        }
                    }
                    
                    m_bufferedToggleChangeEvents.length = 0;
                }
                else
                {
                    // If one of the toggle highlight parts is selected, we need to check if the user has
                    // pressed and released over a section of the text.
                    // (Must be the case that the toggle button and the text area don't overlap since there is
                    // timing issue between the event detecting toggle change and the mouse event in this frame)
                    if (m_activeHighlightId != null)
                    {
                        var isCursorOverText:Boolean = editableTextArea.getIsTextUnderPoint(m_localPointBuffer.x, m_localPointBuffer.y);
                        var partName:String = m_activeHighlightId;
                        var styleObject:Object = m_createState.getCurrentLevel().currentlySelectedBackgroundData;
                        var colorForPartName:uint = (styleObject != null && styleObject.hasOwnProperty("highlightColors")) ?
                            styleObject["highlightColors"][partName] : 0xFFFFFF; 
                        if (m_mouseState.leftMousePressedThisFrame && currentMousePointInTextArea)
                        {
                            m_startedHighlightInTextArea = true;
                            editableTextArea.toggleEditMode(false);
                            
                            // Even without dragging, highlight the word that was pressed
                            editableTextArea.highlightWordAtPoint(m_localPointBuffer.x, m_localPointBuffer.y, colorForPartName, partName);
                            
                            // Start the blink animation
                            if (m_highlightBlinkTween != null)
                            {
                                Starling.juggler.remove(m_highlightBlinkTween);
                            }
                            m_highlightBlinkTween = new Tween(m_highlightTransparencyData, 1.0);
                            m_highlightTransparencyData.alpha = 1.0;
                            m_highlightBlinkTween.animate("alpha", 0.4);
                            m_highlightBlinkTween.repeatCount = 0;
                            m_highlightBlinkTween.reverse = true;
                            Starling.juggler.add(m_highlightBlinkTween);
                        }
                        else if (m_mouseState.leftMouseDraggedThisFrame && m_startedHighlightInTextArea)
                        {
                            // Based on the toggle we set a new id and color for the highlight
                            if (isCursorOverText)
                            {
                                editableTextArea.highlightWordsAtCurrentSelection(colorForPartName, partName, false);
                            }
                            // If cursor is not over some text, the highlight should be removed
                            else
                            {
                                editableTextArea.deleteHighlight(partName, false);
                            }
                        }
                        else if (m_mouseState.leftMouseReleasedThisFrame)
                        {
                            // A release after starting a highlight should deactivate the currently active
                            // toggle as wee assume the player is done with the highlight at this point
                            if (m_startedHighlightInTextArea)
                            {
                                if (m_highlightBlinkTween != null)
                                {
                                    m_highlightTransparencyData.alpha = 1.0;
                                    setHighlightsToCurrentTransparency();
                                    Starling.juggler.remove(m_highlightBlinkTween);
                                    m_highlightBlinkTween = null;
                                } 
                                
                                // When the cursor is over the text, the highlight should register and be finished
                                if (isCursorOverText)
                                {
                                    // This will deactivate the highlight mode
                                    m_activeHighlightId = null;
                                    
                                    editableTextArea.highlightWordsAtCurrentSelection(colorForPartName, partName, true);
                                    
                                    // Delete the visualizations related to highlighting the selected portion
                                    editableTextArea.removeEmphasisFromAllText();
                                    
                                    // NOTE: It is possible the user highlighted whitespace, in which case the highlight
                                    // does not exist, still counts as a change
                                    m_createState.dispatchEventWith(ProblemCreateEvent.USER_HIGHLIGHT_FINISHED, false, {id:partName});
                                }
                                // If the user has released outside a part of the text, the highlight should be canceled and restarted
                                else
                                {
                                    
                                }
                                
                                editableTextArea.toggleEditMode(true);
                                m_startedHighlightInTextArea = false;
                                
                            }
                        }
                        
                        if (m_highlightBlinkTween != null)
                        {
                            setHighlightsToCurrentTransparency();
                        }
                    }
                }
            }
            
            return ScriptStatus.RUNNING;
        }
        
        private function toggleBarModelTransparency():void
        {
            var partId:String = m_activeHighlightId;
            var elementIds:Vector.<String> = (partId != null) ?
                m_createState.getCurrentLevel().getPartNameToIdsMap()[partId] : Vector.<String>([]);
            var matchedViewsForPart:Vector.<DisplayObject> = new Vector.<DisplayObject>();
            var allViewsInModel:Vector.<DisplayObject> = new Vector.<DisplayObject>();
            
            // When a button is active, we emphasize the parts in the bar model that they are
            // trying to tag. Look through the list of ids and grab the view corresponding to it.
            // Iterate through every view element to check for a match
            var barModelArea:BarModelView = m_createState.getWidgetFromId("barModelArea") as BarModelView;
            var barWholeViews:Vector.<BarWholeView> = barModelArea.getBarWholeViews();
            for (var i:int = 0; i < barWholeViews.length; i++)
            {
                var barWholeView:BarWholeView = barWholeViews[i];
                var barSegmentViews:Vector.<BarSegmentView> = barWholeView.segmentViews;
                var j:int;
                for (j = 0; j < barSegmentViews.length; j++)
                {
                    var barSegmentView:BarSegmentView = barSegmentViews[j];
                    if (elementIds.indexOf(barSegmentView.data.id) >= 0)
                    {
                        matchedViewsForPart.push(barSegmentView);
                    }
                    allViewsInModel.push(barSegmentView);
                }
                
                var barLabelViews:Vector.<BarLabelView> = barWholeView.labelViews;
                for (j = 0; j < barLabelViews.length; j++)
                {
                    var barLabelView:BarLabelView = barLabelViews[j];
                    if (elementIds.indexOf(barLabelView.data.id) >= 0)
                    {
                        matchedViewsForPart.push(barLabelView);
                    }
                    allViewsInModel.push(barLabelView);
                }
                
                var comparisonView:BarComparisonView = barWholeView.comparisonView;
                if (comparisonView != null)
                {
                    if (elementIds.indexOf(comparisonView.data.id) >= 0)
                    {
                        matchedViewsForPart.push(comparisonView);
                    }
                    allViewsInModel.push(comparisonView);
                }
            }
            
            var verticalBarLabels:Vector.<BarLabelView> = barModelArea.getVerticalBarLabelViews();
            for (i = 0; i < verticalBarLabels.length; i++)
            {
                var verticalBarLabel:BarLabelView = verticalBarLabels[i];
                if (elementIds.indexOf(verticalBarLabel.data.id) >= 0)
                {
                    matchedViewsForPart.push(verticalBarLabel);
                }
                allViewsInModel.push(verticalBarLabel);
            }
            
            // Set all views to transparent
            // (Except for case where there is no active highlight id, meaning everything should
            // be reset to opaque)
            for each (var barElementView:DisplayObject in allViewsInModel)
            {
                barElementView.alpha = (partId != null) ? 0.3 : 1.0;
            }
            
            // For each matched view just add a steady blink
            for each (var matchedView:DisplayObject in matchedViewsForPart)
            {
                matchedView.alpha = 1.0;
            }
        }
        
        /**
         * HACK: Make sure the active toggle button has not been set to null already
         */
        private function setHighlightsToCurrentTransparency():void
        {
            var highlightAlpha:Number = m_highlightTransparencyData.alpha;
            var highlightTextObjects:Object = m_editableTextArea.getHighlightTextObjects();
            var partName:String = m_activeHighlightId;
            
            if (highlightTextObjects.hasOwnProperty(partName))
            {
                var displays:Vector.<DisplayObject> = highlightTextObjects[partName].display;
                for each (var highlightDisplay:DisplayObject in displays)
                {
                    highlightDisplay.alpha = highlightAlpha;
                }
            }
        }
    }
}