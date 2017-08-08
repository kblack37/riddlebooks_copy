package wordproblem.scripts.deck;


import flash.geom.Rectangle;
import flash.text.TextFormat;

import cgs.internationalization.StringTable;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.ui.MouseState;
import dragonbox.common.util.XColor;

import starling.display.Button;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Quad;
import starling.events.Event;
import starling.text.TextField;

import wordproblem.display.Layer;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.expression.SymbolData;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.widget.DeckWidget;
import wordproblem.engine.widget.KeyboardWidget;
import wordproblem.engine.widget.NumberpadWidget;
import wordproblem.engine.widget.WidgetUtil;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;

/**
 * Script to handle the behavior where the player clicks on a special button to create a new card.
 * 
 * NOTE: Since the gestures for this will conflict with those for the normal deck interactions
 * this should be placed before the deck controller script.
 * The reason is that clicking on a card in this script might bring back up the change number prompt.
 */
class EnterNewCard extends BaseGameScript
{
    /**
     * Reference to the button that will trigger a popup to enter a new card number
     */
    private var m_enterNewCardButton : DisplayObject;
    
    /**
     * Reference to the deck since this is where new cards will be appended to.
     * 
     * The button to enter a new card is added
     */
    private var m_deckWidget : DeckWidget;
    
    /**
     * If true, the keyboard ui is the input method.
     * If false, the numberpad ui is the input method.
     */
    private var m_useKeyboard : Bool;
    
    /**
     * Ui for creating new numbers
     */
    private var m_numberpadWidget : NumberpadWidget;
    
    /**
     * Ui for creating new words
     */
    private var m_keyboardWidget : KeyboardWidget;
    
    /**
     * This is the layer to paste on top to show the number pad as well as any instructions
     */
    private var m_canvas : DisplayObjectContainer;
    
    /**
     * Need a button that triggers the close of the number pad
     */
    private var m_closeButton : Button;
    
    /**
     * A description of what the created widget should do
     */
    private var m_description : TextField;
    
    /*
     * TODO: Place an outline on cards that the player added as a custom object.
     * Press on the custom card to change its value again.
     */
    private var m_globalBoundsBuffer : Rectangle;
    
    /**
     * Keep track of the values in the deck that were custom added. This is
     * important since we want clicks on those cards to retrigger the number pad to edit the number.
     */
    private var m_addedCardValues : Array<String>;
    
    /**
     * The widget in the render list that was pressed on.
     * The action we care about has a release.
     */
    private var m_termWidgetPressedOn : BaseTermWidget;
    
    /**
     * If not null then opening the number pad and submitting a value should modify
     * the an existing card instead of adding a new one
     */
    private var m_existingValueToEdit : String;
    
    /**
     * Have a limit on the number of new values that can be added.
     * If less than zero, there should be no limit.
     * If the limit is positive and we reach it, we should overwrite previous values
     */
    private var m_maximumNewCards : Int;
    
    /**
     *
     * @param useKeyboard
     *      If true a keyboard with letters should be the input method
     */
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            useKeyboard : Bool,
            maximumNewCards : Int,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        var screenWidth : Float = 800;
        var screenHeight : Float = 600;
        m_canvas = new Layer();
        var disablingQuad : Quad = new Quad(screenWidth, screenHeight, 0x000000);
        disablingQuad.alpha = 0.5;
        m_canvas.addChild(disablingQuad);
        
        m_numberpadWidget = new NumberpadWidget(assetManager, 
                function(value : Float) : Void
                {
                    m_canvas.removeFromParent();
                    
                    // Do not allow adding of zero, it will have no effect on any equation
                    if (value != 0) 
                    {
                        attemptAddNewValueToDeck(value + "");
                    }
                }, 
                false, false, 5);
        m_keyboardWidget = new KeyboardWidget(assetManager, 
                function() : Void
                {
                    m_canvas.removeFromParent();
                    attemptAddNewValueToDeck(m_keyboardWidget.getText());
                });
        
        // Pick whether the ui with letters or just numbers should be used
        var uiToUse : DisplayObject = null;
        m_useKeyboard = useKeyboard;
        if (m_useKeyboard) 
        {
            uiToUse = m_keyboardWidget;
        }
        else 
        {
            uiToUse = m_numberpadWidget;
        }
        uiToUse.x = (screenWidth - uiToUse.width) * 0.5;
        uiToUse.y = (screenHeight - uiToUse.height) * 0.5;
        m_canvas.addChild(uiToUse);
        
        var nineSliceGrid : Rectangle = new Rectangle(8, 8, 16, 16);
        m_closeButton = WidgetUtil.createGenericColoredButton(
                        assetManager,
                        XColor.ROYAL_BLUE,
                        null,
                        new TextFormat(GameFonts.DEFAULT_FONT_NAME, 26, 0xFFFFFF),
                        null
                        );
        var closeDimensions : Float = 50;
        var closeIcon : Image = new Image(assetManager.getTexture("wrong"));
        closeIcon.scaleX = closeIcon.scaleY = (closeDimensions * 0.8) / closeIcon.width;
        m_closeButton.upState = closeIcon.texture;
        m_closeButton.width = m_closeButton.height = closeDimensions;
        m_closeButton.x = uiToUse.x + uiToUse.width - m_closeButton.width;
        m_closeButton.y = uiToUse.y;
        m_canvas.addChild(m_closeButton);
        
		// TODO: uncomment when cgs library is finished
        m_description = new TextField(450, 60, "" /*StringTable.lookup("create_number")*/, GameFonts.DEFAULT_FONT_NAME, 32, 0xFFFFFF);
        m_description.x = (screenWidth - m_description.width) * 0.5;
        m_description.y = uiToUse.y - m_description.height;
        m_canvas.addChild(m_description);
        m_addedCardValues = new Array<String>();
        
        m_globalBoundsBuffer = new Rectangle();
        m_termWidgetPressedOn = null;
        setMaximumNewCards(maximumNewCards);
    }
    
    public function setMaximumNewCards(value : Int) : Void
    {
        m_maximumNewCards = value;
        
        // May need to do some pruning if the current number of cards exceeds the new set limit
        // Delete stuff from the deck and redraw it
        if (m_addedCardValues.length > m_maximumNewCards) 
        {
            var numExtraCardsToDelete : Int = m_addedCardValues.length - m_maximumNewCards;
        }
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.FAIL;
        
        if (m_ready && m_isActive && !Layer.getDisplayObjectIsInInactiveLayer(m_deckWidget)) 
        {
            var mouseState : MouseState = m_gameEngine.getMouseState();
            
            if (mouseState.leftMousePressedThisFrame) 
            {
                var baseTermWidget : BaseTermWidget = try cast(m_deckWidget.getObjectUnderPoint(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y), BaseTermWidget) catch(e:Dynamic) null;
                if (baseTermWidget != null) 
                {
                    // Check if we pressed on either the button to add a new card
                    // OR a card that was added
                    if (baseTermWidget.getNode().data == "NEW" || Lambda.indexOf(m_addedCardValues, baseTermWidget.getNode().data) >= 0) 
                    {
                        m_termWidgetPressedOn = baseTermWidget;
                    }
                }
            }
            else if (mouseState.leftMouseDraggedThisFrame && m_termWidgetPressedOn != null) 
            {
                // DO NOT ALLOW THE DRAGGING OF THE NEW BUTTON IN ANY CIRCUMSTANCE!
                if (m_termWidgetPressedOn.getNode().data == "NEW") 
                {
                    status = ScriptStatus.SUCCESS;
                }
                else 
                {
                    // Cancel the press, allows player to drag the custom card
                    m_termWidgetPressedOn = null;
                }
            }
            else if (mouseState.leftMouseReleasedThisFrame && m_termWidgetPressedOn != null) 
            {
                m_termWidgetPressedOn.getBounds(m_termWidgetPressedOn.stage, m_globalBoundsBuffer);
                if (m_globalBoundsBuffer.contains(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y)) 
                {
                    var baseTermWidget = m_termWidgetPressedOn;
                    var expressionValue : String = baseTermWidget.getNode().data;
                    if (expressionValue == "NEW") 
                    {
                        if (m_useKeyboard) 
                        {
                            m_keyboardWidget.setText("");
                        }
                        else 
                        {
                            m_numberpadWidget.value = 0;
                        }
                        
                        m_existingValueToEdit = null;
                        m_gameEngine.getSprite().addChild(m_canvas);
                    }
                    else 
                    {
                        // We want to check for clicks on any custom numbers that the player had added
                        // Allow the player to edit these values
                        // Allow for edit of an existing numeric value
                        m_existingValueToEdit = expressionValue;
                        
                        if (m_useKeyboard) 
                            { }
                        else 
                        {
                            m_numberpadWidget.value = Std.parseInt(expressionValue);
                        }
                        m_gameEngine.getSprite().addChild(m_canvas);
                    }
                }
                
                status = ScriptStatus.SUCCESS;
                m_termWidgetPressedOn = null;
            }
        }
        
        return status;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_numberpadWidget.dispose();
        m_keyboardWidget.dispose();
        m_canvas.removeFromParent(true);
        m_deckWidget.removeEventListener(DeckWidget.EVENT_REFRESH, onDeckBoundsRefresh);
        m_closeButton.removeEventListener(Event.TRIGGERED, onCloseClicked);
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        // HACK: Special rendering parameters for the card used to add additional values to the deck
        // We reserve a value for the card adding portion
        var newSymbolData : SymbolData = new SymbolData(
			"NEW", 
			"Add New Card", 
			"NEW", 
			null, 
			"assets/card/blank_card.png", 
			0xFFFFFF, 
			GameFonts.DEFAULT_FONT_NAME
        );
        newSymbolData.fontColor = 0xFFFFFF;
        newSymbolData.fontSize = 14;
        m_gameEngine.getExpressionSymbolResources().addSymbol(newSymbolData);
        
        // The button to enter a new card should appear at the very edge of the last visible widget
        // (Note that it must reposition itself each time)
        m_deckWidget = try cast(m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null;
        m_deckWidget.addEventListener(DeckWidget.EVENT_REFRESH, onDeckBoundsRefresh);
        
        // Bind a listener to the button to trigger adding new card
        m_closeButton.addEventListener(Event.TRIGGERED, onCloseClicked);
        
        // We need to maintain the correct order of the expressions as they are shown to the player
        // The only way to do this is to look at how the display objects are ordered
        var deckExpressionsToSetTo : Array<String> = new Array<String>();
        var isHiddenToSetTo : Array<Bool> = new Array<Bool>();
        var renderComponents : Array<DisplayObject> = m_deckWidget.getObjects();
        var numRenderComponents : Int = renderComponents.length;
        var i : Int = 0;
        for (i in 0...numRenderComponents){
            // We assume everything in the deck is a term widget that ties to some expression value
            var baseTermWidget : BaseTermWidget = try cast(renderComponents[i], BaseTermWidget) catch(e:Dynamic) null;
            var expressionNode : ExpressionNode = baseTermWidget.getNode();
            deckExpressionsToSetTo.push(expressionNode.data);
            isHiddenToSetTo.push(expressionNode.hidden);
        }
        
        deckExpressionsToSetTo.push("NEW");
        isHiddenToSetTo.push(false);
        
        m_gameEngine.setDeckAreaContent(deckExpressionsToSetTo, isHiddenToSetTo, true);
    }
    
    private function onCloseClicked() : Void
    {
        m_canvas.removeFromParent();
    }
    
    private function attemptAddNewValueToDeck(value : String) : Void
    {
        var doAddNewValue : Bool = true;
        var newData : String = value + "";
        
        // If we are at the limit, then we cannot add a new card.
        // Instead replace one of the existing added values instead
        if (m_maximumNewCards >= 0 && m_addedCardValues.length >= m_maximumNewCards &&
            m_addedCardValues.length > 0 && m_existingValueToEdit == null) 
        {
            m_existingValueToEdit = m_addedCardValues[0];
        }  // If the value is already there, then we have no need to add it again  
        
        
        
        var currentValuesInDeck : Array<String> = new Array<String>();
        var currentHiddenValuesInDeck : Array<Bool> = new Array<Bool>();
        var renderComponents : Array<DisplayObject> = m_deckWidget.getObjects();
        var numComponents : Int = renderComponents.length;
        var i : Int = 0;
        for (i in 0...numComponents){
            var baseTermWidget : BaseTermWidget = try cast(renderComponents[i], BaseTermWidget) catch(e:Dynamic) null;
            var expressionValue : String = baseTermWidget.getNode().data;
            
            // Do not add the widget representing adding a new card yet, this should go at the very end
            if (expressionValue != "NEW") 
            {
                // If editing an existing value, we do not re-add the old value, instead add the new
                // modified value in the same location.
                if (m_existingValueToEdit != null &&
                    m_existingValueToEdit == expressionValue) 
                {
                    currentValuesInDeck.push(newData);
                    currentHiddenValuesInDeck.push(false);
                    m_addedCardValues[Lambda.indexOf(m_addedCardValues, expressionValue)] = newData;
                }
                else 
                {
                    currentValuesInDeck.push(expressionValue);
                    currentHiddenValuesInDeck.push(baseTermWidget.getNode().hidden);
                }
            }
            
            if (expressionValue == newData) 
            {
                doAddNewValue = false;
            }
        }
        
        if (doAddNewValue) 
        {
            // Add new card
            if (m_existingValueToEdit == null) 
            {
                currentValuesInDeck.push(newData);
                currentHiddenValuesInDeck.push(false);
                m_addedCardValues.push(newData);
            }  // Add the back the button that creates new cards at the very end  
            
            
            
            currentValuesInDeck.push("NEW");
            currentHiddenValuesInDeck.push(false);
            
            m_gameEngine.setDeckAreaContent(currentValuesInDeck, currentHiddenValuesInDeck, true);
        }
    }
    
    private function onDeckBoundsRefresh() : Void
    {
    }
}
