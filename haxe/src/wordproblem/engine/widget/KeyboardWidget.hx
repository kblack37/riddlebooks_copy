package wordproblem.engine.widget;


import flash.geom.Rectangle;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

import dragonbox.common.util.XColor;

import haxe.Constraints.Function;

import starling.display.Button;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;
import starling.textures.Texture;

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
    
	// TODO: uncomment when a suitable text input replacement is found
    //private var m_textInput : TextInput;
    
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
    private var m_backButton : Button;
    private var m_acceptButton : Button;
    private var m_spaceButton : Button;
    private var m_shiftButton : Button;
    
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
        //m_textInput = new TextInput();
        //m_textInput.maxChars = maxCharacters;
        //m_textInput.restrict = "A-Z a-z";
        //m_textInput.textEditorFactory = function() : ITextEditor
                //{
                    //var editor : TextFieldTextEditor = new TextFieldTextEditor();
                    //editor.textFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 36, 0xFFFFFF, null, null, null, null, null, TextFormatAlign.CENTER);
                    //editor.embedFonts = true;
                    //return editor;
                //};
        //var textInputTexture : Texture = getTexture("button_white.png");
        //var backgroundPadding : Float = 8;
        //var textInputBackground : Scale9Image = new Scale9Image(new Scale9Textures(textInputTexture, 
        //new Rectangle(backgroundPadding, backgroundPadding, textInputTexture.width - 2 * backgroundPadding, textInputTexture.height - 2 * backgroundPadding)));
        //textInputBackground.color = 0xD09919;
        //m_textInput.backgroundSkin = textInputBackground;
        //m_textInput.addEventListener(FeathersEventType.ENTER, onTextInputEnter);
        //m_textInput.addEventListener(Event.CHANGE, onTextChange);
        //addChild(m_textInput);
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
        var shiftButton : Button = WidgetUtil.createButton(
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
        //(try cast(shiftButton.defaultSkin, Scale9Image) catch(e:Dynamic) null).color = XColor.ROYAL_BLUE;
        //(try cast(shiftButton.hoverSkin, Scale9Image) catch(e:Dynamic) null).color = XColor.BRIGHT_ORANGE;
        //(try cast(shiftButton.downSkin, Scale9Image) catch(e:Dynamic) null).color = XColor.BRIGHT_ORANGE;
        shiftButton.addEventListener(Event.TRIGGERED, onShiftClicked);
        shiftButton.width = buttonWidth * 1.5 + buttonGap;
        shiftButton.height = buttonHeight;
        var thirdCharacterRow : Array<DisplayObject> = m_lowerCaseButtons[2];
        shiftButton.x = thirdCharacterRow[thirdCharacterRow.length - 1].x + buttonWidth + buttonGap;
        shiftButton.y = thirdCharacterRow[0].y;
        m_buttonsContainer.addChild(shiftButton);
        m_shiftButton = shiftButton;
        
        var backButton : Button = WidgetUtil.createButton(
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
        // TODO: starling buttons use textures, not images, and the color cannot be changed
		// like this
		//(try cast(backButton.defaultSkin, Scale9Image) catch(e:Dynamic) null).color = XColor.ROYAL_BLUE;
        //(try cast(backButton.hoverSkin, Scale9Image) catch(e:Dynamic) null).color = XColor.BRIGHT_ORANGE;
        //(try cast(backButton.downSkin, Scale9Image) catch(e:Dynamic) null).color = XColor.BRIGHT_ORANGE;
        var backIcon : Image = new Image(assetManager.getTexture("arrow_rotate.png"));
        backIcon.scaleX = backIcon.scaleY = (buttonHeight / backIcon.height);
        backButton.upState = backIcon.texture;
        backButton.addEventListener(Event.TRIGGERED, onBackClicked);
        backButton.width = buttonWidth * 1.5;
        backButton.height = buttonHeight;
        var firstCharacterRow : Array<DisplayObject> = m_lowerCaseButtons[0];
        backButton.x = firstCharacterRow[firstCharacterRow.length - 1].x + buttonWidth + buttonGap;
        backButton.y = firstCharacterRow[0].y;
        m_buttonsContainer.addChild(backButton);
        m_backButton = backButton;
        
        var acceptButton : Button = WidgetUtil.createButton(
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
		// TODO: starling buttons use textures, not images, and the color cannot be changed
		// like this
        //(try cast(acceptButton.defaultSkin, Scale9Image) catch(e:Dynamic) null).color = XColor.ROYAL_BLUE;
        //(try cast(acceptButton.hoverSkin, Scale9Image) catch(e:Dynamic) null).color = XColor.BRIGHT_ORANGE;
        //(try cast(acceptButton.downSkin, Scale9Image) catch(e:Dynamic) null).color = XColor.BRIGHT_ORANGE;
        
        var acceptIcon : Image = new Image(assetManager.getTexture("correct.png"));
        acceptIcon.scaleX = acceptIcon.scaleY = (buttonHeight / acceptIcon.height);
        acceptButton.upState = acceptIcon.texture;
        acceptButton.addEventListener(Event.TRIGGERED, onAcceptClicked);
        acceptButton.width = buttonWidth * 2;
        acceptButton.height = buttonHeight * 2 + buttonGap;
        var secondCharacterRow : Array<DisplayObject> = m_lowerCaseButtons[1];
        acceptButton.x = secondCharacterRow[secondCharacterRow.length - 1].x + buttonWidth + buttonGap;
        acceptButton.y = buttonHeight + buttonGap;
        m_buttonsContainer.addChild(acceptButton);
        m_acceptButton = acceptButton;
        
        // Space goes at the very bottom
        var spaceButton : Button = WidgetUtil.createButton(
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
		// TODO: starling buttons use textures, not images, and the color cannot be changed
		// like this
        //(try cast(spaceButton.defaultSkin, Scale9Image) catch(e:Dynamic) null).color = XColor.ROYAL_BLUE;
        //(try cast(spaceButton.hoverSkin, Scale9Image) catch(e:Dynamic) null).color = XColor.BRIGHT_ORANGE;
        //(try cast(spaceButton.downSkin, Scale9Image) catch(e:Dynamic) null).color = XColor.BRIGHT_ORANGE;
        spaceButton.addEventListener(Event.TRIGGERED, onCharacterButtonClicked);
        spaceButton.width = buttonWidth * 5 + buttonGap * 4;
        spaceButton.height = buttonHeight;
        spaceButton.x = buttonWidth * 2.5;
        spaceButton.y = (buttonHeight + buttonGap) * m_lowerCaseButtons.length;
        m_buttonsContainer.addChild(spaceButton);
        m_spaceButton = spaceButton;
        
        var buttonsLeftPadding : Float = 28;
        var buttonsTotalWidth : Float = 11.5 * buttonWidth + 10 * buttonGap;
        
		// TODO: uncomment when a suitable text input replacement is found
        //m_textInput.width = buttonsTotalWidth * 0.75;
        //m_textInput.height = 70;
        
        var backgroundImage : Image = new Image(assetManager.getTexture("summary_background.png"));
        backgroundImage.width = buttonsTotalWidth + 2 * buttonsLeftPadding;
        
		// TODO: uncomment when a suitable text input replacement is found
        //m_textInput.x = (backgroundImage.width - m_textInput.width) * 0.5;
        //m_textInput.y = 35;
        //m_buttonsContainer.y = m_textInput.height + m_textInput.y + 20;
        //m_buttonsContainer.x = buttonsLeftPadding;
        //backgroundImage.height = m_textInput.height + m_textInput.y + buttonWidth * 4 + buttonGap * 3 + 50;
        addChildAt(backgroundImage, 0);
        
        // Show lower case buttons first
        this.showButtons(true);
    }
    
    public function getText() : String
    {
		// TODO: uncomment when a suitable text input replacement is found
        //return m_textInput.text;
		return "";
    }
    
    public function setText(value : String) : Void
    {
		// TODO: uncomment when a suitable text input replacement is found
        //m_textInput.text = value;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
		// TODO: uncomment when a suitable text input replacement is found
        //m_textInput.removeEventListener(FeathersEventType.ENTER, onTextInputEnter);
        //m_textInput.removeEventListener(Event.CHANGE, onTextChange);
        //m_textInput.removeFromParent(true);
		
        // Clean out listeners on buttons
        function cleanButtonList(buttons : Array<Array<DisplayObject>>) : Void
        {
            var i : Int = 0;
            for (i in 0...buttons.length){
                var charactersInRow : Array<DisplayObject> = buttons[i];
                var j : Int = 0;
                for (j in 0...charactersInRow.length){
                    var button : Button = try cast(charactersInRow[j], Button) catch(e:Dynamic) null;
                    button.removeEventListener(Event.TRIGGERED, onCharacterButtonClicked);
                    button.removeFromParent(true);
                }
            }
        };
        cleanButtonList(m_lowerCaseButtons);
        cleanButtonList(m_upperCaseButtons);
        
        m_shiftButton.removeEventListener(Event.TRIGGERED, onShiftClicked);
        m_shiftButton.removeFromParent(true);
        
        m_backButton.removeEventListener(Event.TRIGGERED, onBackClicked);
        m_backButton.removeFromParent(true);
        
        m_acceptButton.removeEventListener(Event.TRIGGERED, onAcceptClicked);
        m_acceptButton.removeFromParent(true);
        
        m_spaceButton.removeEventListener(Event.TRIGGERED, onCharacterButtonClicked);
        m_spaceButton.removeFromParent(true);
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
                var button : Button = WidgetUtil.createButton(
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
				// TODO: starling buttons use textures, not images, and the color cannot be changed
				// like this
                //(try cast(button.upState, Image) catch(e:Dynamic) null).color = XColor.ROYAL_BLUE;
                //(try cast(button.overState, Image) catch(e:Dynamic) null).color = XColor.BRIGHT_ORANGE;
                //(try cast(button.downState, Image) catch(e:Dynamic) null).color = XColor.BRIGHT_ORANGE;
                button.addEventListener(Event.TRIGGERED, onCharacterButtonClicked);
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
                var button : Button = try cast(buttonList[j], Button) catch(e:Dynamic) null;
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
                button.removeFromParent();
            }
        }
        
        this.layoutButtonRows(buttonsToAdd, buttonWidth, buttonHeight, buttonGap);
        for (i in 0...buttonsToAdd.length){
            for (button in buttonsToAdd[i])
            {
                m_buttonsContainer.addChild(button);
            }
        }  // Change characters on the shift button  
        
        
        
        m_shiftButton.text = ((lowerCase)) ? 
                "A-Z" : "a-z";
    }
    
    private function onTextInputEnter() : Void
    {
        onAcceptClicked(null);
    }
    
    private function onTextChange() : Void
    {
		// TODO: uncomment when a suitable text input replacement is found
        //m_textInput.setFocus();
    }
    
    private function onCharacterButtonClicked(event : Event) : Void
    {
        var button : Button = try cast(event.target, Button) catch(e:Dynamic) null;
        
		// TODO: uncomment when a suitable text input replacement is found
        //if (m_textInput.text.length < m_textInput.maxChars) 
        //{
            //m_textInput.text += button.label;
        //}
        //m_textInput.setFocus();
    }
    
    private function onShiftClicked(event : Event) : Void
    {
        // Check if the lower case buttons are visible and toggle
        var lowerCaseVisible : Bool = m_lowerCaseButtons[0][0].parent != null;
        showButtons(!lowerCaseVisible);
    }
    
    private function onAcceptClicked(event : Event) : Void
    {
        if (m_acceptCallback != null) 
        {
            m_acceptCallback();
        }
    }
    
    private function onBackClicked(event : Event) : Void
    {
		// TODO: uncomment when a suitable text input replacement is found
        //var currentText : String = m_textInput.text;
        //var numCharacters : Int = currentText.length;
        //if (numCharacters > 0) 
        //{
            //if (numCharacters == 1) 
            //{
                //m_textInput.text = "";
            //}
            //else 
            //{
                //m_textInput.text = currentText.substr(0, numCharacters - 1);
            //}
        //}
    }
}
