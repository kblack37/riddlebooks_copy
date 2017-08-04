package wordproblem.creator.scripts;


import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextFormat;
import starling.textures.Texture;

import cgs.internationalization.StringTable;

import dragonbox.common.ui.MouseState;
import dragonbox.common.util.TextToNumber;
import dragonbox.common.util.XColor;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Quad;
import starling.display.Sprite;
import starling.text.TextField;

import wordproblem.creator.EditableTextArea;
import wordproblem.creator.ProblemCreateData;
import wordproblem.creator.ProblemCreateEvent;
import wordproblem.creator.WordProblemCreateState;
import wordproblem.creator.WordProblemCreateUtil;
import wordproblem.display.Layer;
import wordproblem.engine.barmodel.BarModelTypeDrawer;
import wordproblem.engine.barmodel.BarModelTypeDrawerProperties;
import wordproblem.engine.barmodel.view.BarModelView;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.text.MeasuringTextField;
import wordproblem.engine.widget.ConfirmationWidget;
import wordproblem.engine.widget.KeyboardWidget;
import wordproblem.engine.widget.NumberpadWidget;
import wordproblem.resource.AssetManager;

/**
 * When the user tags/highlights elements in the word problem, they could be any arbitrary word or phrase.
 * This is not useful with respect to the mathematical model as we those elements
 * to map to actual numbers in most cases in addition to variables.
 * 
 * This script handles the logic of asking for and remembering alias names to the elements
 * they have highlighted.
 */
class ChangeAliasScript extends BaseProblemCreateScript
{
    private inline var MAX_VARIABLE_LENGTH : Int = 10;
    
    private var m_mouseState : MouseState;
    
    private var m_globalPointBuffer : Point;
    private var m_localPointBuffer : Point;
    
    /**
     * The hit area to bring up the alias widget takes up a large portion of the highlight
     * toggle button. We want it to only show up if they press and release at the same
     * spot to prevent it from showing when they are just pressing to scroll.
     */
    private var m_globalPointLastLocation : Point;
    private var m_boundsBuffer : Rectangle;
    
    private var m_keyboardWidget : KeyboardWidget;
    private var m_numberpadWidget : NumberpadWidget;
    
    /**
     * This notification popup is used to show the errors that come up if a a restriction
     * for a value of the bar model has not been satsified. For example, tell the user
     * that a value highlighted needs to be a number.
     * 
     * Null if no error is displayed
     */
    private var m_errorNotificationWidget : ConfirmationWidget;
    
    /**
     * On a previous frame did the user press outside the bounds of a widget.
     * If true then a release also outside should be treated as a click
     */
    private var m_pressedOutsideWidgetBounds : Bool;
    
    /**
     * A covering component to disable clicks on all other parts of the screen.
     */
    private var m_disablingQuad : Layer;
    
    /**
     * This contains the graphic to replicate the text contents that were highlighted.
     * Since the disabling quad obscures the text area, having a reference to the highlighted text
     * might be useful when thinking of the number or name it should be
     */
    private var m_highlightedElementContents : Sprite;
    private var m_expressionContainer : Sprite;
    
    /**
     * Element id that the user is currently creating an alias for, if null
     * no alias is being created or modified
     */
    private var m_elementIdInFocus : String;
    
    private var m_styleAndDataForBarModel : Dynamic;
    
    /**
     * If the user enters a value that does not fit the restrictions allowed for an element,
     * we want to display an error indicating why the value was not accepted.
     */
    private var m_errorText : TextField;
    
    /**
     * Need to extract number value from whatever string that was highlighted
     */
    private var m_textToNumber : TextToNumber;
    
    private var m_editableTextArea : EditableTextArea;
    
    /**
     * We want to constantly monitor changes to assigned values to each bar model part.
     * To do so, we keep track of what user assigned value is linked to each of the required
     * bar part ids on the previous frame. On each new frame we check for changes in the value.
     * Any thing that is detected should trigger an event to let other scripts know a change has occured
     */
    private var m_previousPartIdToValueMap : Dynamic;
    
    private var m_dummyCard : DisplayObject;
    
    public function new(createState : WordProblemCreateState,
            mouseState : MouseState,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(createState, assetManager, id, isActive);
        
        m_mouseState = mouseState;
        
        m_globalPointBuffer = new Point();
        m_localPointBuffer = new Point();
        m_globalPointLastLocation = new Point();
        m_boundsBuffer = new Rectangle();
        
        var screenWidth : Float = 800;
        var screenHeight : Float = 600;
        m_keyboardWidget = new KeyboardWidget(assetManager, onAcceptKeyboardValue, MAX_VARIABLE_LENGTH);
        m_keyboardWidget.x = (screenWidth - m_keyboardWidget.width) * 0.5;
        m_numberpadWidget = new NumberpadWidget(assetManager, null, true, false, 6);
        m_numberpadWidget.x = (screenWidth - m_numberpadWidget.width) * 0.5;
        m_disablingQuad = new Layer();
        var quad : Quad = new Quad(screenWidth, screenHeight, 0);
        quad.alpha = 0.7;
        m_disablingQuad.addChild(quad);
        
        m_errorText = new TextField(screenWidth, 150, "", GameFonts.DEFAULT_FONT_NAME, 32, 0xFF0000);
        m_textToNumber = new TextToNumber();
        m_previousPartIdToValueMap = { };
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_isReady) 
        {
            m_editableTextArea.removeEventListener(ProblemCreateEvent.HIGHLIGHT_REFRESHED, bufferEvent);
            m_createState.removeEventListener(ProblemCreateEvent.USER_HIGHLIGHT_FINISHED, bufferEvent);
            m_createState.removeEventListener(ProblemCreateEvent.USER_HIGHLIGHT_STARTED, bufferEvent);
            
            if (value) 
            {
                m_editableTextArea.addEventListener(ProblemCreateEvent.HIGHLIGHT_REFRESHED, bufferEvent);
                m_createState.addEventListener(ProblemCreateEvent.USER_HIGHLIGHT_FINISHED, bufferEvent);
                m_createState.addEventListener(ProblemCreateEvent.USER_HIGHLIGHT_STARTED, bufferEvent);
            }
        }
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        // Get general data about the bar model type the application is asking the user
        // to make a problem for, this is necessary to get info to restrict the allowable
        // alias values for an element id.
        var problemData : ProblemCreateData = m_createState.getCurrentLevel();
        var barModelTypeDrawer : BarModelTypeDrawer = new BarModelTypeDrawer();
        m_styleAndDataForBarModel = barModelTypeDrawer.getStyleObjectForType(problemData.barModelType);
        
        // Need to listen for all changes in the highlights in the text
        // These types of changes may impact the values since they may alter the number
        // in the highlighted text or remove it entirely
        m_editableTextArea = try cast(m_createState.getWidgetFromId("editableTextArea"), EditableTextArea) catch(e:Dynamic) null;
        
        // Initialize the map of element to user values to be the same as the starting values when the level
        // first loads.
        for (partId in Reflect.fields(problemData.elementIdToDataMap))
        {
            Reflect.setField(m_previousPartIdToValueMap, partId, problemData.elementIdToDataMap[partId]);
        }
        
        setIsActive(m_isActive);
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.FAIL;
        if (m_isActive && m_isReady) 
        {
            status = super.visit();
            
            // Compare the mappings of bar part to user assigned name from this frame and the last frame
            var mapForCurrent : Dynamic = m_createState.getCurrentLevel().elementIdToDataMap;
            var foundDifferenceInMaps : Bool = false;
            for (partId in Reflect.fields(m_previousPartIdToValueMap))
            {
                var prevValueForPart : String = Reflect.field(m_previousPartIdToValueMap, partId);
                if (mapForCurrent.exists(partId)) 
                {
                    var currentValueForPart : String = Reflect.field(mapForCurrent, partId).value;
                    if (currentValueForPart != prevValueForPart) 
                    {
                        foundDifferenceInMaps = true;
                    }
                }
                else 
                {
                    foundDifferenceInMaps = true;
                }
            }
            
            if (foundDifferenceInMaps) 
            {
                m_createState.dispatchEventWith(ProblemCreateEvent.BAR_PART_VALUE_CHANGED, false, null);
            }  // Have the prev values now match the current ones for the next frame  
            
            
            
            for (partId in Reflect.fields(m_previousPartIdToValueMap))
            {
                m_previousPartIdToValueMap[partId] = mapForCurrent[partId].value;
            }
            
            m_globalPointBuffer.x = m_mouseState.mousePositionThisFrame.x;
            m_globalPointBuffer.y = m_mouseState.mousePositionThisFrame.y;
            
            // Tapping outside the bounds of the widget should dismiss it without saving any
            // changes in the value
            if (m_numberpadWidget.stage != null || m_keyboardWidget.stage != null) 
            {
                var widgetToUse : DisplayObject = ((m_numberpadWidget.stage != null)) ? 
                m_numberpadWidget : m_keyboardWidget;
                widgetToUse.getBounds(widgetToUse.stage, m_boundsBuffer);
                
                var pointNotInWidget : Bool = !m_boundsBuffer.containsPoint(m_globalPointBuffer);
                
                if (m_mouseState.leftMousePressedThisFrame) 
                {
                    m_pressedOutsideWidgetBounds = pointNotInWidget;
                }
                else if (m_mouseState.leftMouseReleasedThisFrame) 
                {
                    // Dismiss the widget
                    if (pointNotInWidget && m_pressedOutsideWidgetBounds) 
                    {
                        removeAliasInput();
                    }
                    m_pressedOutsideWidgetBounds = false;
                }
            }
            else 
            {
                // Add listener to the alias name button
                if (m_mouseState.leftMousePressedThisFrame) 
                {
                    m_globalPointLastLocation.x = m_globalPointBuffer.x;
                    m_globalPointLastLocation.y = m_globalPointBuffer.y;
                }
                else if (m_mouseState.leftMouseReleasedThisFrame) 
                {
                    // Only trigger the change alias widget if the user hasn't move the mouse on the click
                    // The reason for this condition is the user could just want to scroll and hitting the
                    // button is incidental.
                    if (m_globalPointBuffer.x == m_globalPointLastLocation.x &&
                        m_globalPointBuffer.y == m_globalPointLastLocation.y) 
                        { }
                }
                
                m_pressedOutsideWidgetBounds = false;
            }
        }
        return status;
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == ProblemCreateEvent.USER_HIGHLIGHT_FINISHED) 
        {
            // Do not trigger if keyboard or numpad is already open
            // (HACK: This situation should not be happening, a displayed widget should block out the selection of
            // text underneath it)
            if (m_numberpadWidget.stage == null && m_keyboardWidget.stage == null) 
            {
                // When a highlight is added or redrawn check if we need to modify the alias
                // to better fit with the newly tagged piece of text
                var barPartNameJustHighlighted : String = param.id;
                var styleAndDataForPart : BarModelTypeDrawerProperties = Reflect.field(m_styleAndDataForBarModel, barPartNameJustHighlighted);
                var typeClass : Class<Dynamic> = styleAndDataForPart.restrictions.type;
                var textForElement : String = m_editableTextArea.getTextContentForId(barPartNameJustHighlighted);
                if (typeClass == String) 
                {
                    if (textForElement.length > MAX_VARIABLE_LENGTH) 
                    {
                        openAliasEditorForElement(barPartNameJustHighlighted);
                    }
                    else 
                    {
                        m_createState.getCurrentLevel().elementIdToDataMap[barPartNameJustHighlighted].value = textForElement;
                    }
                }
                else if (typeClass == Int || typeClass == Float) 
                {
                    var errors : Dynamic = { };
                    var extractedNumberFromText : Float = m_textToNumber.textToNumber(textForElement);
                    var valueValid : Bool = WordProblemCreateUtil.checkValueValid(styleAndDataForPart, Std.string(extractedNumberFromText), errors);
                    if (valueValid) 
                    {
                        m_createState.getCurrentLevel().elementIdToDataMap[barPartNameJustHighlighted].value = Std.string(extractedNumberFromText);
                    }
                    else 
                    {
                        var errorDescription : String = "";
                        var errorStrings : Array<Dynamic> = Reflect.field(errors, "errors");
                        for (errorString in errorStrings)
                        {
                            errorDescription += errorString;
                        }  // on top of the warning message    // When showing the error ui, the flash textfield needs to be hidden away, otherwise it will appear  
                        
                        
                        
                        
                        
                        m_editableTextArea.toggleEditMode(false);
                        m_errorNotificationWidget = new ConfirmationWidget(800, 600, 
                                function() : DisplayObject
                                {
                                    return new TextField(300, 200, errorDescription, GameFonts.DEFAULT_FONT_NAME, 20, 0xFFFFFF);
                                }, 
                                function() : Void
                                {
                                    m_errorNotificationWidget.removeFromParent(true);
                                    m_editableTextArea.toggleEditMode(true);
                                }, null, m_assetManager, XColor.ROYAL_BLUE, StringTable.lookup("ok"), null, true);
                        m_createState.addChild(m_errorNotificationWidget);
                        
                        // The highlight is not valid so it should immediately be deleted
                        m_editableTextArea.deleteHighlight(barPartNameJustHighlighted);
                    }
                }
            }
        }
        // TODO: Highlight Refresh occurs even when attempting a preview
        // These cases should trigger for changes not related to explicit user highlights
        // All the logic below should be moved to the spot where we can detect a change in one of the values
        else if (eventType == ProblemCreateEvent.HIGHLIGHT_REFRESHED) 
        {
            // The changing of highlights might affect the alias value,
            // deleted highlights should revert the value back to empty value
            var highlightObjectForPart : Dynamic = m_editableTextArea.getHighlightTextObjects();
            for (importantBarPartName in Reflect.fields(m_styleAndDataForBarModel))
            {
                // The highlight for a bar part does not exist
                if (!highlightObjectForPart.exists(importantBarPartName) && m_createState.getCurrentLevel().elementIdToDataMap[importantBarPartName].value != "") 
                {
                    m_createState.getCurrentLevel().elementIdToDataMap[importantBarPartName].value = "";
                }
                // If it does exist, then for any numbers make sure that the value that is highlighted matches
                // the current value
                else 
                { };
            }
        }
    }
    
    private function openAliasEditorForElement(elementId : String) : Void
    {
        m_createState.addChild(m_disablingQuad);
        m_elementIdInFocus = elementId;
        
        var problemData : ProblemCreateData = m_createState.getCurrentLevel();
        var existingValueForElement : String = problemData.elementIdToDataMap[elementId].value;
        
        var propertiesForElement : BarModelTypeDrawerProperties = Reflect.field(m_styleAndDataForBarModel, elementId);
        var restrictions : Dynamic = propertiesForElement.restrictions;
        var inputWidgetToUse : DisplayObject = null;
        var usingNumberPadAsInput : Bool = true;
        if (restrictions.type == Int || restrictions.type == Float) 
        {
            // Allow decimals for floating point numbers
            m_numberpadWidget.setDecimalButtonVisible(restrictions.type == Float);
            
            // Set the number pad to zero or the existing value if it was set before
            m_numberpadWidget.value = ((existingValueForElement != "")) ? 
                    parseFloat(existingValueForElement) : 0;
            m_createState.addChild(m_numberpadWidget);
            
            inputWidgetToUse = m_numberpadWidget;
        }
        //restrictions.type == String
        else 
        {
            m_createState.addChild(m_keyboardWidget);
            
            m_keyboardWidget.setText(existingValueForElement);
            
            inputWidgetToUse = m_keyboardWidget;
            
            usingNumberPadAsInput = false;
        }
        
        if (m_expressionContainer != null) 
        {
            m_expressionContainer.removeFromParent(true);
        }  // make it clear that element is supposed to equal the entered in value    // The card should appear right next to the entry along with an equals sign to try to  
        
        
        
        
        
        var expressionSymbolMap : ExpressionSymbolMap = (try cast(m_createState.getWidgetFromId("barModelArea"), BarModelView) catch(e:Dynamic) null).getExpressionSymbolMap();
        m_expressionContainer = new Sprite();
        var cardForElement : DisplayObject = expressionSymbolMap.getCardFromSymbolValue(elementId);
        cardForElement.scaleX = cardForElement.scaleY = 1.25;
        cardForElement.x = cardForElement.width * 0.5;
        cardForElement.y = cardForElement.height * 0.5;
        m_expressionContainer.addChild(cardForElement);
        
        var equals : Image = new Image(m_assetManager.getTexture("equal"));
        equals.scaleX = equals.scaleY = 1.2;
        equals.x = cardForElement.width + (cardForElement.x - cardForElement.width * 0.5) + 10;
        equals.y = (cardForElement.height - equals.height) * 0.5 + (cardForElement.y - cardForElement.height * 0.5);
        m_expressionContainer.addChild(equals);
        
        // The editable text would appear on top, so we need to make sure it is hidden
        // until the input component has been dismissed
        var editableTextArea : EditableTextArea = try cast(m_createState.getWidgetFromId("editableTextArea"), EditableTextArea) catch(e:Dynamic) null;
        editableTextArea.toggleEditMode(false);
        
        inputWidgetToUse.y = (m_disablingQuad.height - inputWidgetToUse.height) * 0.5;
        
        // If the element has a highlight then we show a copy of the text as a reminder to the player of what
        // they are binding the value of. It should appear on top of the widget that changes the value and stand out out
        var highlightForElement : Dynamic = editableTextArea.getHighlightTextObjects()[elementId];
        if (highlightForElement != null) 
        {
            var textForElement : String = editableTextArea.getTextContentForId(elementId);
            var color : Int = highlightForElement.color;
            var measuringText : MeasuringTextField = new MeasuringTextField();
            var textFormat : TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 24, 0x000000);
            measuringText.defaultTextFormat = textFormat;
            
            // TODO: The size of the text should depend on the amount of space
            var topSpaceLeft : Float = inputWidgetToUse.y;
            var targetFontSize : Float = measuringText.resizeToDimensions(400, topSpaceLeft * 0.5, textForElement);
            textFormat.size = targetFontSize;
            measuringText.defaultTextFormat = textFormat;
            measuringText.text = textForElement;
            
            m_highlightedElementContents = new Sprite();
            var measuredTextWidth : Float = measuringText.textWidth + 10;
            var measuredTextHeight : Float = measuringText.textHeight + 5;
            var textFieldForElement : TextField = new TextField(measuredTextWidth, measuredTextHeight, 
            textForElement, textFormat.font, Std.parseInt(textFormat.size), try cast(textFormat.color, Int) catch(e:Dynamic) null);
            var highlightBackground : Image = new Image(Texture.fromTexture(m_assetManager.getTexture("button_white"), 
				new Rectangle(8, 8, 16, 16)));
            highlightBackground.color = color;
            highlightBackground.width = measuredTextWidth;
            highlightBackground.height = measuredTextHeight;
            m_highlightedElementContents.addChild(highlightBackground);
            m_highlightedElementContents.addChild(textFieldForElement);
            m_highlightedElementContents.x = (m_disablingQuad.width - m_highlightedElementContents.width) * 0.5;
            
            // Put the text in the space between the widget and the top of the screen
            m_highlightedElementContents.y = (topSpaceLeft - m_highlightedElementContents.height) * 0.5;
            m_createState.addChild(m_highlightedElementContents);
        }
        
        if (usingNumberPadAsInput) 
        {
            m_expressionContainer.x = m_numberpadWidget.x - m_expressionContainer.width;
            m_expressionContainer.y = m_numberpadWidget.y + 30;
        }
        else 
        {
            m_expressionContainer.x = m_keyboardWidget.x - 20;
            m_expressionContainer.y = m_keyboardWidget.y + 40;
        }
        m_createState.addChild(m_expressionContainer);
    }
    
    private function onAcceptKeyboardValue() : Void
    {
        var enteredKeyboardValue : String = m_keyboardWidget.getText();
        
        if (enteredKeyboardValue != "") 
        {
            var problemData : ProblemCreateData = m_createState.getCurrentLevel();
            problemData.elementIdToDataMap[m_elementIdInFocus].value = enteredKeyboardValue;
            removeAliasInput();
        }
        // Do not allow for empty string, show prompt to tell user to enter actual value
        // The name cannot conflict with an existing name
        else 
        {
            m_errorText.text = "The name cannot be blank.";
            m_errorText.y = m_keyboardWidget.y + m_keyboardWidget.height;
            m_createState.addChild(m_errorText);
        }
    }
    
    private function removeAliasInput() : Void
    {
        m_keyboardWidget.removeFromParent();
        m_numberpadWidget.removeFromParent();
        
        var editableTextArea : EditableTextArea = try cast(m_createState.getWidgetFromId("editableTextArea"), EditableTextArea) catch(e:Dynamic) null;
        editableTextArea.toggleEditMode(true);
        
        if (m_highlightedElementContents != null) 
        {
            m_highlightedElementContents.removeFromParent(true);
            m_highlightedElementContents = null;
        }
        
        if (m_expressionContainer != null) 
        {
            m_expressionContainer.removeFromParent(true);
            m_expressionContainer = null;
        }
        
        m_disablingQuad.removeFromParent();
        m_elementIdInFocus = null;
        
        if (m_errorText.parent != null) 
        {
            m_errorText.removeFromParent();
        }
    }
    
    private function onAliasClicked() : Void
    {
        m_elementIdInFocus = null;
        
        // Open the editor for the given element id
        openAliasEditorForElement(m_elementIdInFocus);
    }
}
