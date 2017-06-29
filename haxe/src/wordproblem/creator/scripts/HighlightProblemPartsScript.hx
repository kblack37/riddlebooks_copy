package wordproblem.creator.scripts;


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
class HighlightProblemPartsScript extends BaseProblemCreateScript
{
    private var m_mouseState : MouseState;
    
    private var m_globalPointBuffer : Point;
    private var m_localPointBuffer : Point;
    private var m_boundsBuffer : Rectangle;
    
    private var m_editableTextArea : EditableTextArea;
    
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
    private var m_activeHighlightId : String;
    
    /**
     * After the user activated the toggle, did they press somewhere in the text area
     * to start a highlight
     */
    private var m_startedHighlightInTextArea : Bool;
    
    /**
     * To fix this timing issue
     * Problem: Click on button, then click on another, both get set to unselected at the end
     * 
     * Each object is a pair {button:<button that was selected>, isSelected:<was button set at that click}
     */
    private var m_bufferedToggleChangeEvents : Array<Dynamic>;
    
    /**
     * We want to blink the active highlight when the user is coloring the text, however since a redraw may
     * cause the display for the highlight to be recreated we cannot apply a tween to just display directly.
     * Instead we adjust the alpha property in this object and set the current highlight display to that
     * property
     */
    private var m_highlightTransparencyData : Dynamic;
    private var m_highlightBlinkTween : Tween;
    
    public function new(wordproblemCreateState : WordProblemCreateState,
            mouseState : MouseState,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(wordproblemCreateState, assetManager, id, isActive);
        
        m_mouseState = mouseState;
        
        m_globalPointBuffer = new Point();
        m_localPointBuffer = new Point();
        m_boundsBuffer = new Rectangle();
        m_bufferedToggleChangeEvents = new Array<Dynamic>();
        
        m_activeHighlightId = null;
        m_highlightTransparencyData = {
                    alpha : 1.0

                };
    }
    
    override private function onLevelReady() : Void
    {
        // TODO: We have a timing dependency, on prepopulating the text we want to immediately modify the text list with predefined highlights
        // At that point however, the list elements may not exist. Thus we only want to apply the highlights AFTER the list elements have been created.
        super.onLevelReady();
        
        m_editableTextArea = try cast(m_createState.getWidgetFromId("editableTextArea"), EditableTextArea) catch(e:Dynamic) null;
        setIsActive(m_isActive);
    }
    
    override public function setIsActive(value : Bool) : Void
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
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == ProblemCreateEvent.SELECT_BAR_ELEMENT) 
        {
            if (param.exists("id")) 
            {
                var selectedId : String = param.id;
                
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
            
            m_bufferedToggleChangeEvents.push({
                        id : m_activeHighlightId

                    });
        }
        else if (eventType == ProblemCreateEvent.HIGHLIGHT_REFRESHED) 
        {
            // Re-adjust the model to mark elements as highlighted
            var highlights : Dynamic = m_editableTextArea.getHighlightTextObjects();
            var partsInBarModel : Dynamic = m_createState.getCurrentLevel().elementIdToDataMap;
            for (partName in Reflect.fields(partsInBarModel))
            {
                Reflect.setField(partsInBarModel, partName, highlights.exists(partName)).highlighted;
            }
        }
    }
    
    override public function visit() : Int
    {
        m_globalPointBuffer.x = m_mouseState.mousePositionThisFrame.x;
        m_globalPointBuffer.y = m_mouseState.mousePositionThisFrame.y;
        
        var editableTextArea : EditableTextArea = m_editableTextArea;
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
            var currentMousePointInTextArea : Bool = m_boundsBuffer.containsPoint(m_localPointBuffer);
            
            super.visit();
            
            if (m_bufferedToggleChangeEvents.length > 0) 
            {
                for (bufferedToggleChange in m_bufferedToggleChangeEvents)
                {
                    toggleBarModelTransparency();
                    
                    if (m_activeHighlightId != null) 
                    {
                        m_createState.dispatchEventWith(ProblemCreateEvent.USER_HIGHLIGHT_STARTED, false, {
                                    id : m_activeHighlightId

                                });
                        editableTextArea.addEmphasisToAllText();
                    }
                    else 
                    {
                        m_createState.dispatchEventWith(ProblemCreateEvent.USER_HIGHLIGHT_CANCELLED, false, null);
                        editableTextArea.removeEmphasisFromAllText();
                    }
                }
                
                as3hx.Compat.setArrayLength(m_bufferedToggleChangeEvents, 0);
            }
            else 
            {
                // If one of the toggle highlight parts is selected, we need to check if the user has
                // pressed and released over a section of the text.
                // (Must be the case that the toggle button and the text area don't overlap since there is
                // timing issue between the event detecting toggle change and the mouse event in this frame)
                if (m_activeHighlightId != null) 
                {
                    var isCursorOverText : Bool = editableTextArea.getIsTextUnderPoint(m_localPointBuffer.x, m_localPointBuffer.y);
                    var partName : String = m_activeHighlightId;
                    var styleObject : Dynamic = m_createState.getCurrentLevel().currentlySelectedBackgroundData;
                    var colorForPartName : Int = ((styleObject != null && styleObject.exists("highlightColors"))) ? 
                    Reflect.field(Reflect.field(styleObject, "highlightColors"), partName) : 0xFFFFFF;
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
                            }  // When the cursor is over the text, the highlight should register and be finished  
                            
                            
                            
                            if (isCursorOverText) 
                            {
                                // This will deactivate the highlight mode
                                m_activeHighlightId = null;
                                
                                editableTextArea.highlightWordsAtCurrentSelection(colorForPartName, partName, true);
                                
                                // Delete the visualizations related to highlighting the selected portion
                                editableTextArea.removeEmphasisFromAllText();
                                
                                // NOTE: It is possible the user highlighted whitespace, in which case the highlight
                                // does not exist, still counts as a change
                                m_createState.dispatchEventWith(ProblemCreateEvent.USER_HIGHLIGHT_FINISHED, false, {
                                            id : partName

                                        });
                            }
                            // If the user has released outside a part of the text, the highlight should be canceled and restarted
                            else 
                            { };
                            
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
    
    private function toggleBarModelTransparency() : Void
    {
        var partId : String = m_activeHighlightId;
        var elementIds : Array<String> = ((partId != null)) ? 
        m_createState.getCurrentLevel().getPartNameToIdsMap()[partId] : [];
        var matchedViewsForPart : Array<DisplayObject> = new Array<DisplayObject>();
        var allViewsInModel : Array<DisplayObject> = new Array<DisplayObject>();
        
        // When a button is active, we emphasize the parts in the bar model that they are
        // trying to tag. Look through the list of ids and grab the view corresponding to it.
        // Iterate through every view element to check for a match
        var barModelArea : BarModelView = try cast(m_createState.getWidgetFromId("barModelArea"), BarModelView) catch(e:Dynamic) null;
        var barWholeViews : Array<BarWholeView> = barModelArea.getBarWholeViews();
        for (i in 0...barWholeViews.length){
            var barWholeView : BarWholeView = barWholeViews[i];
            var barSegmentViews : Array<BarSegmentView> = barWholeView.segmentViews;
            var j : Int;
            for (j in 0...barSegmentViews.length){
                var barSegmentView : BarSegmentView = barSegmentViews[j];
                if (Lambda.indexOf(elementIds, barSegmentView.data.id) >= 0) 
                {
                    matchedViewsForPart.push(barSegmentView);
                }
                allViewsInModel.push(barSegmentView);
            }
            
            var barLabelViews : Array<BarLabelView> = barWholeView.labelViews;
            for (j in 0...barLabelViews.length){
                var barLabelView : BarLabelView = barLabelViews[j];
                if (Lambda.indexOf(elementIds, barLabelView.data.id) >= 0) 
                {
                    matchedViewsForPart.push(barLabelView);
                }
                allViewsInModel.push(barLabelView);
            }
            
            var comparisonView : BarComparisonView = barWholeView.comparisonView;
            if (comparisonView != null) 
            {
                if (Lambda.indexOf(elementIds, comparisonView.data.id) >= 0) 
                {
                    matchedViewsForPart.push(comparisonView);
                }
                allViewsInModel.push(comparisonView);
            }
        }
        
        var verticalBarLabels : Array<BarLabelView> = barModelArea.getVerticalBarLabelViews();
        for (i in 0...verticalBarLabels.length){
            var verticalBarLabel : BarLabelView = verticalBarLabels[i];
            if (Lambda.indexOf(elementIds, verticalBarLabel.data.id) >= 0) 
            {
                matchedViewsForPart.push(verticalBarLabel);
            }
            allViewsInModel.push(verticalBarLabel);
        }  // be reset to opaque)    // (Except for case where there is no active highlight id, meaning everything should    // Set all views to transparent  
        
        
        
        
        
        
        
        for (barElementView in allViewsInModel)
        {
            barElementView.alpha = ((partId != null)) ? 0.3 : 1.0;
        }  // For each matched view just add a steady blink  
        
        
        
        for (matchedView in matchedViewsForPart)
        {
            matchedView.alpha = 1.0;
        }
    }
    
    /**
     * HACK: Make sure the active toggle button has not been set to null already
     */
    private function setHighlightsToCurrentTransparency() : Void
    {
        var highlightAlpha : Float = m_highlightTransparencyData.alpha;
        var highlightTextObjects : Dynamic = m_editableTextArea.getHighlightTextObjects();
        var partName : String = m_activeHighlightId;
        
        if (highlightTextObjects.exists(partName)) 
        {
            var displays : Array<DisplayObject> = Reflect.field(highlightTextObjects, partName).display;
            for (highlightDisplay in displays)
            {
                highlightDisplay.alpha = highlightAlpha;
            }
        }
    }
}
