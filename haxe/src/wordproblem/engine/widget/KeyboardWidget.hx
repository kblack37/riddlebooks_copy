package wordproblem.engine.widget;


import dragonbox.common.util.XColor;

import haxe.Constraints.Function;

import openfl.display.Bitmap;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.TextEvent;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

import wordproblem.display.LabelButton;
import wordproblem.display.Layer;
import wordproblem.engine.text.GameFonts;
import wordproblem.resource.AssetManager;

/**
 * A keyboard where the player can enter custom words
 */
class KeyboardWidget extends Layer
{
    private var buttonWidth : Float = 50;
    private var buttonHeight : Float = 50;
    private var buttonGap : Float = 1;
    
    private inline static var DEFAULT_MAX_CHARACTERS : Int = 15;
    
    private var m_assetManager : AssetManager;
    
    private var m_textInput : TextField;
    
    /**
     * Buttons for lower case characters that can be used
     */
    private var m_lowerCaseButtons : Array<Array<DisplayObject>>;
    
    /**
     * Buttons for upper case characters that can be used
     */
    private var m_upperCaseButtons : Array<Array<DisplayObject>>;
    
    /**
     * Common buttons not tied to characters (back, enter, space)
     */
    private var m_backButton : LabelButton;
    private var m_acceptButton : LabelButton;
    private var m_spaceButton : LabelButton;
    private var m_shiftButton : LabelButton;
    
    /**
     * Canvas storing all of the buttons
     */
    private var m_buttonsContainer : Sprite;
    
    /**
     * Function triggered when accept is clicked
     */
    private var m_acceptCallback : Function;
    
    public function new(assetManager : AssetManager, acceptCallback : Function, maxCharacters : Int = DEFAULT_MAX_CHARACTERS)
    {
        super();
        
        var totalWidth : Float = 550;
        
        m_buttonsContainer = new Sprite();
        addChild(m_buttonsContainer);
        
        m_assetManager = assetManager;
        m_acceptCallback = acceptCallback;
        
		// TODO: uncomment when a suitable text input replacement is found
        m_textInput = new TextField();
        m_textInput.maxChars = maxCharacters;
        m_textInput.restrict = "A-Z a-z";
		m_textInput.setTextFormat(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 36, 0xFFFFFF, null, null, null, null, null, TextFormatAlign.CENTER));
		m_textInput.background = true;
		m_textInput.backgroundColor = 0xD09919;
        m_textInput.addEventListener(TextEvent.TEXT_INPUT, onTextInputEnter);
        m_textInput.addEventListener(Event.CHANGE, onTextChange);
        addChild(m_textInput);
        m_lowerCaseButtons = new Array<Array<DisplayObject>>();
        
        var lowerCaseCharacterRows : Array<Array<String>> = new Array<Array<String>>();
        lowerCaseCharacterRows.push(["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]);
        lowerCaseCharacterRows.push(["a", "s", "d", "f", "g", "h", "j", "k", "l"]);
        lowerCaseCharacterRows.push(["z", "x", "c", "v", "b", "n", "m"]);
        m_lowerCaseButtons = this.createListsOfButtonsRows(lowerCaseCharacterRows, buttonWidth, buttonHeight);
        
        var upperCaseCharacterRows : Array<Array<String>> = new Array<Array<String>>();
        upperCaseCharacterRows.push(["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]);
        upperCaseCharacterRows.push(["A", "S", "D", "F", "G", "H", "J", "K", "L"]);
        upperCaseCharacterRows.push(["Z", "X", "C", "V", "B", "N", "M"]);
        m_upperCaseButtons = this.createListsOfButtonsRows(upperCaseCharacterRows, buttonWidth, buttonHeight);
        
        this.layoutButtonRows(m_lowerCaseButtons, buttonWidth, buttonHeight, buttonGap);
        
        // Create shift, back, space, and accept buttons and lay them out
        var shiftButton : LabelButton = WidgetUtil.createButton(
                m_assetManager,
                "button_white",
                "button_white",
                null,
                "button_white",
                "Shift",
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, 0xFFFFFF),
                null,
                new Rectangle(8, 8, 16, 16)
                );
		// TODO: starling buttons use textures, not images, and the color cannot be changed
		// like this
		shiftButton.downState.transform.colorTransform = XColor.rgbToColorTransform(XColor.ROYAL_BLUE);
		shiftButton.overState.transform.colorTransform = XColor.rgbToColorTransform(XColor.BRIGHT_ORANGE);
		shiftButton.downState.transform.colorTransform = XColor.rgbToColorTransform(XColor.BRIGHT_ORANGE);
        shiftButton.addEventListener(MouseEvent.CLICK, onShiftClicked);
        shiftButton.width = buttonWidth * 1.5 + buttonGap;
        shiftButton.height = buttonHeight;
        var thirdCharacterRow : Array<DisplayObject> = m_lowerCaseButtons[2];
        shiftButton.x = thirdCharacterRow[thirdCharacterRow.length - 1].x + buttonWidth + buttonGap;
        shiftButton.y = thirdCharacterRow[0].y;
        m_buttonsContainer.addChild(shiftButton);
        m_shiftButton = shiftButton;
        
        var backButton : LabelButton = WidgetUtil.createButton(
                m_assetManager,
                "button_white",
                "button_white",
                null,
                "button_white",
                null,
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, 0xFFFFFF),
                null,
                new Rectangle(8, 8, 16, 16)
                );
		backButton.upState.transform.colorTransform = XColor.rgbToColorTransform(XColor.ROYAL_BLUE);
		backButton.overState.transform.colorTransform = XColor.rgbToColorTransform(XColor.BRIGHT_ORANGE);
		backButton.downState.transform.colorTransform = XColor.rgbToColorTransform(XColor.BRIGHT_ORANGE);
        var backIcon : Bitmap = new Bitmap(assetManager.getBitmapData("arrow_rotate"));
        backIcon.scaleX = backIcon.scaleY = (buttonHeight / backIcon.height);
        backButton.upState = backIcon;
        backButton.addEventListener(MouseEvent.CLICK, onBackClicked);
        backButton.width = buttonWidth * 1.5;
        backButton.height = buttonHeight;
        var firstCharacterRow : Array<DisplayObject> = m_lowerCaseButtons[0];
        backButton.x = firstCharacterRow[firstCharacterRow.length - 1].x + buttonWidth + buttonGap;
        backButton.y = firstCharacterRow[0].y;
        m_buttonsContainer.addChild(backButton);
        m_backButton = backButton;
        
        var acceptButton : LabelButton = WidgetUtil.createButton(
                m_assetManager,
                "button_white",
                "button_white",
                null,
                "button_white",
                null,
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, 0xFFFFFF),
                null,
                new Rectangle(8, 8, 16, 16)
                );		
		acceptButton.upState.transform.colorTransform = XColor.rgbToColorTransform(XColor.ROYAL_BLUE);
		acceptButton.overState.transform.colorTransform = XColor.rgbToColorTransform(XColor.BRIGHT_ORANGE);
		acceptButton.downState.transform.colorTransform = XColor.rgbToColorTransform(XColor.BRIGHT_ORANGE);
        
        var acceptIcon : Bitmap = new Bitmap(assetManager.getBitmapData("correct"));
        acceptIcon.scaleX = acceptIcon.scaleY = (buttonHeight / acceptIcon.height);
        acceptButton.upState = acceptIcon;
        acceptButton.addEventListener(MouseEvent.CLICK, onAcceptClicked);
        acceptButton.width = buttonWidth * 2;
        acceptButton.height = buttonHeight * 2 + buttonGap;
        var secondCharacterRow : Array<DisplayObject> = m_lowerCaseButtons[1];
        acceptButton.x = secondCharacterRow[secondCharacterRow.length - 1].x + buttonWidth + buttonGap;
        acceptButton.y = buttonHeight + buttonGap;
        m_buttonsContainer.addChild(acceptButton);
        m_acceptButton = acceptButton;
        
        // Space goes at the very bottom
        var spaceButton : LabelButton = WidgetUtil.createButton(
                m_assetManager,
                "button_white",
                "button_white",
                null,
                "button_white",
                " ",
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, 0xFFFFFF),
                null,
                new Rectangle(8, 8, 16, 16)
                );
		spaceButton.upState.transform.colorTransform = XColor.rgbToColorTransform(XColor.ROYAL_BLUE);
		spaceButton.overState.transform.colorTransform = XColor.rgbToColorTransform(XColor.BRIGHT_ORANGE);
		spaceButton.downState.transform.colorTransform = XColor.rgbToColorTransform(XColor.BRIGHT_ORANGE);
        spaceButton.addEventListener(MouseEvent.CLICK, onCharacterButtonClicked);
        spaceButton.width = buttonWidth * 5 + buttonGap * 4;
        spaceButton.height = buttonHeight;
        spaceButton.x = buttonWidth * 2.5;
        spaceButton.y = (buttonHeight + buttonGap) * m_lowerCaseButtons.length;
        m_buttonsContainer.addChild(spaceButton);
        m_spaceButton = spaceButton;
        
        var buttonsLeftPadding : Float = 28;
        var buttonsTotalWidth : Float = 11.5 * buttonWidth + 10 * buttonGap;
        
        m_textInput.width = buttonsTotalWidth * 0.75;
        m_textInput.height = 70;
        
        var backgroundImage : Bitmap = new Bitmap(assetManager.getBitmapData("summary_background"));
        backgroundImage.width = buttonsTotalWidth + 2 * buttonsLeftPadding;
        
        m_textInput.x = (backgroundImage.width - m_textInput.width) * 0.5;
        m_textInput.y = 35;
        m_buttonsContainer.y = m_textInput.height + m_textInput.y + 20;
        m_buttonsContainer.x = buttonsLeftPadding;
        backgroundImage.height = m_textInput.height + m_textInput.y + buttonWidth * 4 + buttonGap * 3 + 50;
        addChildAt(backgroundImage, 0);
        
        // Show lower case buttons first
        this.showButtons(true);
    }
    
    public function getText() : String
    {
        return m_textInput.text;
    }
    
    public function setText(value : String) : Void
    {
        m_textInput.text = value;
    }
    
    override public function dispose() : Void
    {
        m_textInput.removeEventListener(TextEvent.TEXT_INPUT, onTextInputEnter);
        m_textInput.removeEventListener(Event.CHANGE, onTextChange);
		if (m_textInput.parent != null) m_textInput.parent.removeChild(m_textInput);
		m_textInput = null;
		
        // Clean out listeners on buttons
        function cleanButtonList(buttons : Array<Array<DisplayObject>>) : Void
        {
            var i : Int = 0;
            for (i in 0...buttons.length){
                var charactersInRow : Array<DisplayObject> = buttons[i];
                var j : Int = 0;
                for (j in 0...charactersInRow.length){
                    var button : LabelButton = try cast(charactersInRow[j], LabelButton) catch(e:Dynamic) null;
                    button.removeEventListener(MouseEvent.CLICK, onCharacterButtonClicked);
					if (button.parent != null) button.parent.removeChild(button);
					button.dispose();
                }
            }
        };
        cleanButtonList(m_lowerCaseButtons);
        cleanButtonList(m_upperCaseButtons);
        
        m_shiftButton.removeEventListener(MouseEvent.CLICK, onShiftClicked);
		if (m_shiftButton.parent != null) m_shiftButton.parent.removeChild(m_shiftButton);
		m_shiftButton.dispose();
		m_shiftButton = null;
        
        m_backButton.removeEventListener(MouseEvent.CLICK, onBackClicked);
		if (m_backButton.parent != null) m_backButton.parent.removeChild(m_backButton);
		m_backButton.dispose();
		m_backButton = null;
        
        m_acceptButton.removeEventListener(MouseEvent.CLICK, onAcceptClicked);
		if (m_acceptButton.parent != null) m_acceptButton.parent.removeChild(m_acceptButton);
		m_acceptButton.dispose();
		m_acceptButton = null;
        
        m_spaceButton.removeEventListener(MouseEvent.CLICK, onCharacterButtonClicked);
        if (m_spaceButton.parent != null) m_spaceButton.parent.removeChild(m_spaceButton);
		m_spaceButton.dispose();
		m_spaceButton = null;
    }
    
    private function createListsOfButtonsRows(characterRows : Array<Array<String>>,
            buttonWidth : Float,
            buttonHeight : Float) : Array<Array<DisplayObject>>
    {
        var listOfButtonRows : Array<Array<DisplayObject>> = new Array<Array<DisplayObject>>();
        var i : Int = 0;
        for (i in 0...characterRows.length){
            // Create a virtual keyboard for all the buttons
            var outButtonList : Array<DisplayObject> = new Array<DisplayObject>();
            var characters : Array<String> = characterRows[i];
            var j : Int = 0;
            var numCharacters : Int = characters.length;
            for (j in 0...numCharacters){
                var character : String = characters[j];
                var button : LabelButton = WidgetUtil.createButton(
                        m_assetManager,
                        "button_white",
                        "button_white",
                        null,
                        "button_white",
                        character,
                        new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, 0xFFFFFF),
                        null,
                        new Rectangle(8, 8, 16, 16)
                        );
				button.upState.transform.colorTransform = XColor.rgbToColorTransform(XColor.ROYAL_BLUE);
				button.overState.transform.colorTransform = XColor.rgbToColorTransform(XColor.BRIGHT_ORANGE);
				button.downState.transform.colorTransform = XColor.rgbToColorTransform(XColor.BRIGHT_ORANGE);
                button.addEventListener(MouseEvent.CLICK, onCharacterButtonClicked);
                button.width = buttonWidth;
                button.height = buttonHeight;
                outButtonList.push(button);
            }
            listOfButtonRows.push(outButtonList);
        }
        
        return listOfButtonRows;
    }
    
    private function layoutButtonRows(buttonRows : Array<Array<DisplayObject>>,
            buttonWidth : Float,
            buttonHeight : Float,
            buttonGap : Float) : Void
    {
        // Layout all of the character buttons
        var i : Int = 0;
        var yOffset : Float = 0;
        for (i in 0...buttonRows.length){
            var buttonList : Array<DisplayObject> = buttonRows[i];
            var numButtons : Int = buttonList.length;
            var xOffset : Float = i * (buttonWidth * 0.5);
            var j : Int = 0;
            for (j in 0...numButtons){
                var button : LabelButton = try cast(buttonList[j], LabelButton) catch(e:Dynamic) null;
                button.x = xOffset;
                button.y = yOffset;
                xOffset += buttonWidth + buttonGap;
            }
            
            yOffset += buttonHeight + buttonGap;
        }
    }
    
    private function showButtons(lowerCase : Bool) : Void
    {
        var buttonsToAdd : Array<Array<DisplayObject>>;
        var buttonsToRemove : Array<Array<DisplayObject>>;
        if (lowerCase) 
        {
            buttonsToAdd = m_lowerCaseButtons;
            buttonsToRemove = m_upperCaseButtons;
        }
        else 
        {
            buttonsToAdd = m_upperCaseButtons;
            buttonsToRemove = m_lowerCaseButtons;
        }
        
        var i : Int = 0;
        for (i in 0...buttonsToRemove.length){
            for (button in buttonsToRemove[i])
            {
                if (button.parent != null) button.parent.removeChild(button);
            }
        }
        
        this.layoutButtonRows(buttonsToAdd, buttonWidth, buttonHeight, buttonGap);
        for (i in 0...buttonsToAdd.length){
            for (button in buttonsToAdd[i])
            {
                m_buttonsContainer.addChild(button);
            }
        } 
		
		// Change characters on the shift button  
        m_shiftButton.label = lowerCase ? 
                "A-Z" : "a-z";
    }
    
    private function onTextInputEnter(event : Dynamic) : Void
    {
        onAcceptClicked(null);
    }
    
    private function onTextChange(event : Dynamic) : Void
    {
		stage.focus = m_textInput;
    }
    
    private function onCharacterButtonClicked(event : Dynamic) : Void
    {
        var button : LabelButton = try cast(event.target, LabelButton) catch(e:Dynamic) null;
        
        if (m_textInput.text.length < m_textInput.maxChars) 
        {
            m_textInput.text += button.label;
        }
		stage.focus = m_textInput;
    }
    
    private function onShiftClicked(event : Dynamic) : Void
    {
        // Check if the lower case buttons are visible and toggle
        var lowerCaseVisible : Bool = m_lowerCaseButtons[0][0].parent != null;
        showButtons(!lowerCaseVisible);
    }
    
    private function onAcceptClicked(event : Dynamic) : Void
    {
        if (m_acceptCallback != null) 
        {
            m_acceptCallback();
        }
    }
    
    private function onBackClicked(event : Dynamic) : Void
    {
        var currentText : String = m_textInput.text;
        var numCharacters : Int = currentText.length;
        if (numCharacters > 0) 
        {
            if (numCharacters == 1) 
            {
                m_textInput.text = "";
            }
            else 
            {
                m_textInput.text = currentText.substr(0, numCharacters - 1);
            }
        }
    }
}
