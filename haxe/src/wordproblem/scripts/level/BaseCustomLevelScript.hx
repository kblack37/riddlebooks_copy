package wordproblem.scripts.level;

import cgs.internationalization.StringTable;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.ui.MouseState;
import dragonbox.common.util.PMPRNG;
import dragonbox.common.util.XColor;

import haxe.xml.Fast;
import haxe.Constraints.Function;

import starling.animation.Tween;
import starling.core.Starling;
import starling.display.Button;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.events.EventDispatcher;
import starling.filters.BlurFilter;
import starling.filters.ColorMatrixFilter;
import starling.filters.FragmentFilter;
import starling.text.TextField;
import starling.utils.HAlign;

import wordproblem.callouts.CalloutCreator;
import wordproblem.characters.HelperCharacterController;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.CalloutComponent;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.SymbolData;
import wordproblem.engine.level.WordProblemLevelData;
import wordproblem.engine.objectives.BaseObjective;
import wordproblem.engine.objectives.FinishLevelObjective;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.scripting.graph.action.CustomVisitNode;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.text.TextParser;
import wordproblem.engine.text.TextViewFactory;
import wordproblem.engine.text.view.DocumentView;
import wordproblem.engine.widget.DeckWidget;
import wordproblem.engine.widget.ExpressionPickerWidget;
import wordproblem.engine.widget.IBaseWidget;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.engine.widget.TextAreaWidget;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;
import wordproblem.scripts.barmodel.BarModelAudio;
import wordproblem.scripts.expression.ExpressionModelAudio;

/**
 * All handcrafted levels with customized logic (mainly tutorials) should inherit from this class.
 * It contains generic functions used to do things like check if expression pickers
 * have the correct values. (? should helper functions be pushed even further up since something
 * like the hint script also needs to move the characters)
 */
class BaseCustomLevelScript extends BaseGameScript
{
    public var CALLOUT_TEXT_DEFAULT_COLOR : Int = 0x5082B9;
    private static inline var CONTINUE_TEXT_DEFAULT_COLOR : Int = 0x006633;
    
    private var m_continueTextDefaultHighlightFilter : FragmentFilter;
    
    /**
     * Default styling
     */
    private var styleObject : Dynamic = {
            p : {
                fontName : GameFonts.DEFAULT_FONT_NAME,
                fontSize : 22,
                color : "0xFFFFFF",

            }

        };
    
    /**
     * Parser used to help generated the dom tree for dynamically added text
     */
    private var m_textParser : TextParser;
    
    /**
     * Factory to create the views for dynamically added text.
     */
    private var m_textViewFactory : TextViewFactory;
    
    /**
     * Dynamically injected dialog is labeled with an id, it will map to the
     * xml element containing the dialog that is to be parsed and displayed during
     * the course of the level.
     */
    private var m_dialogIdToXMLMap : Map<String, Fast>;
    
    /**
     * Map from dialog id to the DialogWidget that is current visible.
     * This is only for dialog that aren't bound to an entity. I.e. things that are floating within the
     * text area.
     */
    //private var m_dialogIdToVisibleWidgetMap : Dictionary;
    
    /**
     * There are instances in a level where the player must click to continue.
     * We pop up a an indicator to the player to do so.
     */
    private var m_continueIndicator : TextField;
    
    /**
     * Need this to be able to control the data properties of the helper characters within a given level.
     */
    private var m_helperCharacterController : HelperCharacterController;
    
    /**
     * Use this for consistent logic for creating new callout components
     */
    private var m_calloutCreator : CalloutCreator;
    
    /**
     * The idea is that this blob can keep track of all the decisions the player has made
     * in previous levels with the idea that these decisions might affect how the level is configured.
     */
    private var m_playerStatsAndSaveData : PlayerStatsAndSaveData;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            playerStatsAndSaveData : PlayerStatsAndSaveData,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_childrenListModifyTypeBuffer = new Array<String>();
        m_childrenListModifyIndexBuffer = new Array<Int>();
        
        m_dialogIdToXMLMap = new Map<String, Fast>();
        //m_dialogIdToVisibleWidgetMap = new Dictionary();
		// TODO: uncomment once cgs library is finished
        m_continueIndicator = new TextField(200, 60, "", /*StringTable.lookup("click_to_continue"),*/ GameFonts.DEFAULT_FONT_NAME, 24, CONTINUE_TEXT_DEFAULT_COLOR);
        m_continueTextDefaultHighlightFilter = BlurFilter.createGlow(0xFFFFFF);
        m_continueIndicator.hAlign = HAlign.CENTER;
        m_playerStatsAndSaveData = playerStatsAndSaveData;
        
        // Bit of a hack, automatically bind audio for bar modeling so the tutorial levels
        // do not need to manually include them
        super.pushChild(new BarModelAudio(try cast(gameEngine, EventDispatcher) catch(e:Dynamic) null));
        super.pushChild(new ExpressionModelAudio(try cast(gameEngine, EventDispatcher) catch(e:Dynamic) null));
    }
    
    /**
     * Use so that custom level scripts can directly access character modification function
     * in the script sequence.
     */
    public function getCharacterController() : HelperCharacterController
    {
        return m_helperCharacterController;
    }
    
    /**
     * Get back a list of objectives the player should solve for this given level.
     * 
     * All subclasses should override this function to create their own objectives for a given level.
     * 
     * @param outObjectives
     *      A list buffer where objective for this level should be added
     */
    public function getObjectives(outObjectives : Array<BaseObjective>) : Void
    {
        outObjectives.push(new FinishLevelObjective());
    }
    
    /**
     * A level may have special details that only it knows about that should be logged at the start.
     * 
     * Custom scripts will want to override this function to put their own special details
     */
    public function getQuestStartDetails() : Dynamic
    {
        // Save the target equation if one exists (only the first one)
        // Assumes all equations are set at the start of the level
        var currentLevel : WordProblemLevelData = m_gameEngine.getCurrentLevel();
        var details : Dynamic = { };
        return details;
    }
    
    /**
     * A level may have special details that only it knows about that should be logged at the end.
     * 
     * Custom scripts will want to override this function to put their own special details
     */
    public function getQuestEndDetails() : Dynamic
    {
        var details : Dynamic = { };
        return details;
    }
    
    /**
     * In all versions that integrate with the copilot, we need to know at the start the number of 'problems'
     * contained in a wordproblem level.
     * 
     * (OVERRIDE if a custom level has special problem divisions)
     * 
     * The number of problems depend on the number of items or parts of a level we think can sensibly be graded as
     * right or wrong. One example is that each bar model piece is one problem and one equation model piece is another.
     */
    public function getNumCopilotProblems() : Int
    {
        return 1;
    }
    
    override public function setExtraData(data : Iterator<Fast>) : Void
    {
		for (xml in data) {
			if (xml.name == "dialog") {
				var dialogId : String = xml.att.id;
				Reflect.setField(m_dialogIdToXMLMap, dialogId, xml);
			}
		}
    }
    
    override public function visit() : Int
    {
        if (m_isActive && m_ready) 
        {
			m_childrenListModifyTypeBuffer = new Array<String>();
			m_childrenListModifyIndexBuffer = new Array<Int>();
            
            super.iterateThroughBufferedEvents();
            var numChildren : Int = m_children.length;
            var i : Int = 0;
            while (i < numChildren){
                m_children[i].visit();
                
                // Adjust the indices based on changes made to the child list while in the middle of visiting
                // the children.
                if (m_childrenListModifyTypeBuffer.length > 0) 
                {
                    var numChanges : Int = m_childrenListModifyTypeBuffer.length;
                    for (j in 0...numChanges){
                        var changeType : String = m_childrenListModifyTypeBuffer[j];
                        var changeIndex : Int = m_childrenListModifyIndexBuffer[j];
                        if (changeType == "add") 
                        {
                            if (changeIndex <= i) 
                            {
                                i += 1;
                            }
                        }
                        else if (changeType == "remove") 
                        {
                            if (changeIndex <= i) 
                            {
                                i -= 1;
                            }
                        }
                    }
                    
					m_childrenListModifyTypeBuffer = new Array<String>();
					m_childrenListModifyIndexBuffer = new Array<Int>();
                    numChildren = m_children.length;
                }
            }
        }
		
		// Must return running otherwise buffered events that are added AFTER the script  
		// has finished iterating through it's current buffer get reset by the parent selector
		// This occurs because the child script that dispatch events are visited afterwards,
        // after this function returns the parent select might call reset.
        return ScriptStatus.RUNNING;
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        m_textViewFactory = new TextViewFactory(m_assetManager, m_gameEngine.getExpressionSymbolResources());
        m_textParser = new TextParser();
        m_calloutCreator = new CalloutCreator(m_textParser, m_textViewFactory);
        m_helperCharacterController = new HelperCharacterController(
                m_gameEngine.getCharacterComponentManager(), m_calloutCreator);
    }
    
    /**
     * Helper function primarily used when setting the deck content and we need a list of booleans of whether
     * all symbols are hidden or visible
     */
    private function getBooleanList(size : Int, value : Bool) : Array<Bool>
    {
        var booleanList : Array<Bool> = new Array<Bool>();
        var i : Int = 0;
        for (i in 0...size){
            booleanList.push(value);
        }
        
        return booleanList;
    }
    
    /**
     * The hint and reset buttons are shared by scripts for bar modeling and equation modeling.
     * The disable and grey out logic cannot go in them, because one of them might be active while
     * the other is inactive.
     * 
     * It is up to the level to determine when they should be fully disabled
     */
    private function greyOutAndDisableButton(uiEntityId : String, disable : Bool) : Void
    {
        var targetButton : Button = try cast(m_gameEngine.getUiEntity(uiEntityId), Button) catch(e:Dynamic) null;
        if (targetButton != null) 
        {
            if (disable) 
            {
                // Set color to grey scale
                var colorMatrixFilter : ColorMatrixFilter = new ColorMatrixFilter();
                colorMatrixFilter.adjustSaturation(-1);
                targetButton.filter = colorMatrixFilter;
                targetButton.alpha = 0.5;
            }
            else 
            {
                // Set color to normal
                targetButton.filter = null;
                targetButton.alpha = 1.0;
            }
            targetButton.enabled = !disable;
        }
    }
    
    /**
     * Keep the next/prev buttons in the text from ever showing up
     */
    private function disablePrevNextTextButtons() : Void
    {
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch (e:Dynamic) null;
		function onGoToPage(pageIndex : Int) : Void
        {
            textArea.getNextPageButton().visible = false;
            textArea.getPrevPageButton().visible = false;
        };
        textArea.setOnGoToPageCallback(onGoToPage);
    }
    
    private function resetExpressionPickerOptions(pickerId : String, entryHeight : Float, maxItemsPerColumn : Int, options : Array<String>) : Void
    {
        var expressionPicker : ExpressionPickerWidget = try cast(m_gameEngine.getUiEntity(pickerId), ExpressionPickerWidget) catch(e:Dynamic) null;
        expressionPicker.removeAllExpressions();
        expressionPicker.setEntryHeight(entryHeight);
        expressionPicker.setNumItemsPerColumnLimit(maxItemsPerColumn);
        expressionPicker.addExpressions(options);
    }
    
    /**
     * @param param
     *      id:Name of ui entity
     *      text
     *      color
     *      direction
     *      animation period
     */
    private function showDialogForUi(param : Dynamic) : Int
    {
        m_gameEngine.getUiComponentManager().addComponentToEntity(m_calloutCreator.createCalloutComponentFromText(param));
        return ScriptStatus.SUCCESS;
    }
    
    private function removeDialogForUi(param : Dynamic) : Int
    {
        m_gameEngine.getUiComponentManager().removeComponentFromEntity(param.id, CalloutComponent.TYPE_ID);
        return ScriptStatus.SUCCESS;
    }
    
    /**
     * @param param
     *      Must include 'widgetId' that is the name of the ui entity.
     *      'id' maps to an entity contained in that ui part
     */
    private function showDialogForBaseWidget(param : Dynamic) : Int
    {
        var status : Int = ScriptStatus.FAIL;
        var widgetId : String = param.widgetId;
        var targetWidget : IBaseWidget = try cast(m_gameEngine.getUiEntity(widgetId), IBaseWidget) catch(e:Dynamic) null;
        if (targetWidget != null) 
        {
            var componentManager : ComponentManager = targetWidget.componentManager;
            componentManager.addComponentToEntity(m_calloutCreator.createCalloutComponentFromText(param));
            status = ScriptStatus.SUCCESS;
        }
        
        return status;
    }
    
    /**
     *
     * @param param
     *      Must include 'widgetId' that maps to the main ui entity and 'id', which is the
     *      sub-entity inside that ui.
     */
    private function removeDialogForBaseWidget(param : Dynamic) : Int
    {
        var status : Int = ScriptStatus.FAIL;
        var widgetId : String = param.widgetId;
        var targetWidget : IBaseWidget = try cast(m_gameEngine.getUiEntity(widgetId), IBaseWidget) catch(e:Dynamic) null;
        if (targetWidget != null) 
        {
            var componentManager : ComponentManager = targetWidget.componentManager;
            componentManager.removeComponentFromEntity(param.id, CalloutComponent.TYPE_ID);
            status = ScriptStatus.SUCCESS;
        }
        
        return status;
    }
    
    /**
     * Set whether the ui portions just for modeling, the term areas and model button, should be visible
     * and interactable. (I.e. while hidden cards should not be able to be added into it by the player)
     * 
     * @param param
     *      visible: should the model ui pieces should be visible
     */
    private function setModelEntitiesVisible(param : Dynamic) : Int
    {
        var visible : Bool = param.visible;
        var termAreas : Array<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TermAreaWidget);
        for (termArea in termAreas)
        {
            termArea.visible = visible;
            (try cast(termArea, TermAreaWidget) catch(e:Dynamic) null).isInteractable = visible;
        }
        
        var modelButton : DisplayObject = m_gameEngine.getUiEntity("modelEquationButton");
        modelButton.visible = visible;
        
        return ScriptStatus.SUCCESS;
    }
    
    /**
     * Get whether all cards currently in the deck have already been found
     */
    private function getAllCardsInDeckFound(param : Dynamic) : Int
    {
        var allFound : Bool = true;
        var deckComponentManager : ComponentManager = (try cast(m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null).componentManager;
        var expressionComponents : Array<Component> = deckComponentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
        var numComponents : Int = expressionComponents.length;
        var i : Int = 0;
        var expressionComponent : ExpressionComponent = null;
        for (i in 0...numComponents){
            expressionComponent = try cast(expressionComponents[i], ExpressionComponent) catch(e:Dynamic) null;
            if (!expressionComponent.hasBeenModeled) 
            {
                allFound = false;
                break;
            }
        }
        
        return ((allFound)) ? ScriptStatus.SUCCESS : ScriptStatus.FAIL;
    }
    
    /**
     * IMPORTANT-> At least one frame of delay must be between every call to this function otherwise
     * all of those calls will grab the same click on that frame.
     * 
     * @param param
     *      (Optional) x, y coordinates to put the click to continue indicator
     *      (Optional) parent- the parent display object to put the click text, default if the game engine sprite
     *      (Optional) color- hex color of the text
     *      (Optional) outlineColor- hex color of the outline
     */
    private function clickToContinue(param : Dynamic) : Int
    {
        // Show something on the screen to let the player know they need to click to continue
        var status : Int = ScriptStatus.FAIL;
        
        // Add indicator is not already there
        var parentContainer : DisplayObjectContainer = ((param.exists("parent"))) ? param.parent : m_gameEngine.getSprite();
        if (m_continueIndicator.parent == null) 
        {
            var x : Float = 350;
            var y : Float = 20;
            if (param != null) 
            {
                x = param.x;
                y = param.y;
            }
            
            m_continueIndicator.x = x;
            m_continueIndicator.y = y;
            parentContainer.addChild(m_continueIndicator);
        }  // Set color information for the text if applicable  
        
        
        
        m_continueIndicator.color = ((param.exists("color"))) ? Reflect.field(param, "color") : CONTINUE_TEXT_DEFAULT_COLOR;
        m_continueIndicator.filter = ((param.exists("outlineColor"))) ? BlurFilter.createGlow(Reflect.field(param, "outlineColor")) : m_continueTextDefaultHighlightFilter;
        
        var mouseState : MouseState = m_gameEngine.getMouseState();
        if (mouseState.leftMousePressedThisFrame) 
        {
            // On click remove the indicator
            m_continueIndicator.removeFromParent();
            status = ScriptStatus.SUCCESS;
            
            var loggingDetails : Dynamic = {
                buttonName : "ClickAnywhereToContinue",
                locationX : mouseState.mousePositionThisFrame.x,
                locationY : mouseState.mousePositionThisFrame.y,

            };
            m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.TUTORIAL_PROGRESS_EVENT, false, loggingDetails);
        }
        return status;
    }
    
    /**
     * If a hidden view simply had its visible property set to false we do not
     * need to do anything special with layout
     * 
     * However if hidden meant is once not added a child then any layout that was done after
     * the hidden object was removed will need to take into account the dimensions of the
     * revealed object. The only example right now is the layout of pages.
     * 
     * @param param
     *      id: document id
     *      visible: visibility boolean
     *      pageIndex: (optional) the index of the page the doc id is in
     */
    private function setDocumentIdVisible(param : Dynamic) : Int
    {
        var documentId : String = param.id;
        var visible : Bool = param.visible;
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntitiesByClass(TextAreaWidget)[0], TextAreaWidget) catch(e:Dynamic) null;
        
        // Get the view itself and its parent.
        // Add the target view to the parent
        var pageIndex : Int = ((param.exists("pageIndex"))) ? param.pageIndex : -1;
        var targetDocumentViews : Array<DocumentView> = textArea.getDocumentViewsAtPageIndexById(documentId, null, pageIndex);
        var i : Int = 0;
        for (i in 0...targetDocumentViews.length){
            var targetDocumentView : DocumentView = targetDocumentViews[i];
            if (targetDocumentView.node.getIsVisible() != visible) 
            {
                targetDocumentView.node.setIsVisible(visible);
                
                // Fade the content in or out with animation
                var fadeInDuration : Float = 1.0;
                var initialAlpha : Float = 0.0;
                var endAlpha : Float = 1.0;
                if (visible) 
                {
                    targetDocumentView.parentView.addChild(targetDocumentView);
                }
                else 
                {
                    targetDocumentView.parentView.removeChild(targetDocumentView);
                    initialAlpha = 1.0;
                    endAlpha = 0.0;
                }
                targetDocumentView.alpha = initialAlpha;
                Starling.current.juggler.tween(targetDocumentView, fadeInDuration, {
                            alpha : endAlpha

                        });
            }
        }  // In a node is made visible, then the bottom scroll limit might change  
        
        
        
        textArea.setBottomScrollLimit();
        
        return ScriptStatus.SUCCESS;
    }
    
    private function setDocumentIdsSelectable(ids : Array<String>,
            selectable : Bool,
            pageIndex : Int = -1) : Void
    {
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntitiesByClass(TextAreaWidget)[0], TextAreaWidget) catch(e:Dynamic) null;
        for (documentId in ids)
        {
            var targetDocumentViews : Array<DocumentView> = textArea.getDocumentViewsAtPageIndexById(documentId, null, pageIndex);
            var i : Int = 0;
            for (i in 0...targetDocumentViews.length){
                var targetDocumentView : DocumentView = targetDocumentViews[i];
                targetDocumentView.node.setSelectable(selectable, true);
            }
        }
    }
    
    /**
     * Go to a particular page in the text
     * 
     * @param param
     *      pageIndex:index to go to
     */
    private function goToPageIndex(param : Dynamic) : Int
    {
        var pageIndex : Int = param.pageIndex;
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntitiesByClass(TextAreaWidget)[0], TextAreaWidget) catch(e:Dynamic) null;
        textArea.showPageAtIndex(pageIndex);
        return ScriptStatus.SUCCESS;
    }
    
    /**
     * Check if player is at a certain page
     * 
     * @param param
     *      pageIndex:index it needs to be at
     */
    private function getAtPageIndex(param : Dynamic) : Int
    {
        var pageIndex : Int = param.pageIndex;
        
        var textArea : TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        return ((textArea.getCurrentPageIndex() == pageIndex)) ? ScriptStatus.SUCCESS : ScriptStatus.FAIL;
    }
    
    /**
     * By default, this script will wait until the move is finished before returning success.
     * 
     * @param param
     *      id
     *      time
     *      y
     *      waitToFinish: If true, wait for the move to complete before the script returns success.
     *      If false, return success immediately.
     */
    private function moveUiEntityTo(param : Dynamic) : Int
    {
        // Currently only adjust the y position
        var status : Int = ScriptStatus.FAIL;
        if (param.time > 0) 
        {
            var tween : Tween = new Tween(m_gameEngine.getUiEntity(param.id), param.time);
            tween.animate("y", param.y);
            tween.onComplete = function() : Void
                    {
                        Starling.current.juggler.remove(tween);
                        param.finished = true;
                    };
            Starling.current.juggler.add(tween);
        }
        else 
        {
            m_gameEngine.getUiEntity(param.id).y = param.y;
            status = ScriptStatus.SUCCESS;
        }
        
        if (param.exists("finished")) 
        {
            status = ScriptStatus.SUCCESS;
        }
        else if (param.exists("waitToFinish")) 
        {
            if (!param.waitToFinish) 
            {
                status = ScriptStatus.SUCCESS;
            }
        }
        
        return status;
    }
    
    /**
     * Really stupid if branch, pass in a global variable and an expected value and return
     * success only if they are equal
     * 
     * IMPORTANT: Since primitives are passed by copy, the given property is actually an object with
     * another value property. It is up to the script to properly reset the value each time.
     * Ex.) We want to check if a value is equal to one
     * param = {expected:1, given:{value:<some_variable>}}
     * The object that is keyed to given is what is written over by the level script. It is essentially a primitive wrapper.
     */
    private function variableEqualsValue(param : Dynamic) : Int
    {
        return ((param.expected == param.given.value)) ? ScriptStatus.SUCCESS : ScriptStatus.FAIL;
    }
    
    /**
     *
     * @param param
     *      value: value to set to
     *      variable: wrapper object that also has a value attribute that gets set to the
     *      other target value
     */
    private function setVariableEqualsValue(param : Dynamic) : Int
    {
        param.variable.value = param.value;
        return ScriptStatus.SUCCESS;
    }
    
    /**
     *
     * @param
     *      draggable: boolean of whether text is draggable
     */
    private function setTextDraggable(param : Dynamic) : Int
    {
        var dragTextNode : ScriptNode = this.getNodeById("DragText");
        dragTextNode.setIsActive(param.draggable);
        var textToCardNode : ScriptNode = this.getNodeById("TextToCard");
        textToCardNode.setIsActive(param.draggable);
        return ScriptStatus.SUCCESS;
    }
    
    /**
     * Signal that the player has successfully finished all important actions in the game.
     * (Needs to be called before completion)
     */
    private function levelSolved(param : Dynamic) : Int
    {
        m_gameEngine.dispatchEventWith(GameEvent.LEVEL_SOLVED);
        return ScriptStatus.SUCCESS;
    }
    
    /**
     * A terminate the level, it will immediately show the win screen.
     */
    private function levelComplete(param : Dynamic) : Int
    {
        m_gameEngine.dispatchEventWith(GameEvent.LEVEL_COMPLETE);
        m_gameEngine.setPaused(true);
        return ScriptStatus.SUCCESS;
    }
    
    private var colorPicker : PMPRNG;
    private var barColors : Array<Int> = XColor.getCandidateColorsForSession();
    private function assignColorToCardFromSeed(cardValue : String, seed : Int) : Void
    {
        if (colorPicker == null) 
        {
            colorPicker = new PMPRNG(seed);
        }
        
        var dataForCard : SymbolData = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(cardValue);
        if (!dataForCard.useCustomBarColor) 
        {
            // To make sure colors look distinct, we pick from a list of predefined list and avoid duplicates
            if (barColors.length > 0) 
            {
                var colorIndex : Int = colorPicker.nextIntRange(0, barColors.length - 1);
                dataForCard.customBarColor = barColors[colorIndex];
                barColors.splice(colorIndex, 1);
            }
            else 
            {
                // In the unlikely case we have too many terms that use up all the colors, we just randomly
                // pick one from a palette.
                dataForCard.customBarColor = XColor.getDistributedHsvColor(colorPicker.nextDouble());
            }
            dataForCard.useCustomBarColor = true;
        }
    }
    
    /*
    Convienence functions that batch together re-usable sequences of actions
    */
    private function addToSequenceEnableModelOnExpressionsFound(sequenceSelector : ScriptNode) : Void
    {
        sequenceSelector.pushChild(new CustomVisitNode(getAllCardsInDeckFound, null));
        sequenceSelector.pushChild(new CustomVisitNode(setTextDraggable, {
                    draggable : false

                }));
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    y : 360,
                    time : 0.3,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(setModelEntitiesVisible, {
                    visible : true

                }));
    }
    
    private function addToSequenceResetToNewProblem(sequenceSelector : ScriptNode, problemSetupFunction : Function) : Void
    {
        // Switch the game back to a 'find all expressions' state
        sequenceSelector.pushChild(new CustomVisitNode(setModelEntitiesVisible, {
                    visible : false

                }));
        sequenceSelector.pushChild(new CustomVisitNode(moveUiEntityTo, {
                    id : "deckAndTermContainer",
                    y : 500,
                    time : 0.3,

                }));
        sequenceSelector.pushChild(new CustomVisitNode(problemSetupFunction, null));
        sequenceSelector.pushChild(new CustomVisitNode(setTextDraggable, {
                    draggable : true

                }));
    }
}
