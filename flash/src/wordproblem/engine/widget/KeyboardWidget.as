package wordproblem.engine.widget
{
    import flash.geom.Rectangle;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    
    import dragonbox.common.util.XColor;
    
    import feathers.controls.Button;
    import feathers.controls.TextInput;
    import feathers.controls.text.TextFieldTextEditor;
    import feathers.core.ITextEditor;
    import feathers.display.Scale9Image;
    import feathers.events.FeathersEventType;
    import feathers.textures.Scale9Textures;
    
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
    public class KeyboardWidget extends Layer
    {
        private var buttonWidth:Number = 50;
        private var buttonHeight:Number = 50;
        private var buttonGap:Number = 1;
        
        private const DEFAULT_MAX_CHARACTERS:int = 15;
        
        private var m_assetManager:AssetManager;
        
        private var m_textInput:TextInput;
        
        /**
         * Buttons for lower case characters that can be used
         */
        private var m_lowerCaseButtons:Vector.<Vector.<DisplayObject>>;
        
        /**
         * Buttons for upper case characters that can be used
         */
        private var m_upperCaseButtons:Vector.<Vector.<DisplayObject>>;
        
        /**
         * Common buttons not tied to characters (back, enter, space)
         */
        private var m_backButton:Button;
        private var m_acceptButton:Button;
        private var m_spaceButton:Button;
        private var m_shiftButton:Button;
        
        /**
         * Canvas storing all of the buttons
         */
        private var m_buttonsContainer:Sprite;
        
        /**
         * Function triggered when accept is clicked
         */
        private var m_acceptCallback:Function;
        
        public function KeyboardWidget(assetManager:AssetManager, acceptCallback:Function, maxCharacters:int=DEFAULT_MAX_CHARACTERS)
        {
            super();
            
            var totalWidth:Number = 550;
            
            m_buttonsContainer = new Sprite();
            addChild(m_buttonsContainer);
            
            m_assetManager = assetManager;
            m_acceptCallback = acceptCallback;
            
            m_textInput = new TextInput();
            m_textInput.maxChars = maxCharacters;
            m_textInput.restrict = "A-Z a-z";
            m_textInput.textEditorFactory = function():ITextEditor
            {
                var editor:TextFieldTextEditor = new TextFieldTextEditor();
                editor.textFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 36, 0xFFFFFF, null, null, null, null, null, TextFormatAlign.CENTER);
                editor.embedFonts = true;
                return editor;
            };
            var textInputTexture:Texture = assetManager.getTexture("button_white");
            var backgroundPadding:Number = 8;
            var textInputBackground:Scale9Image = new Scale9Image(new Scale9Textures(textInputTexture, 
                new Rectangle(backgroundPadding, backgroundPadding, textInputTexture.width - 2 * backgroundPadding, textInputTexture.height - 2 * backgroundPadding)));
            textInputBackground.color = 0xD09919;
            m_textInput.backgroundSkin = textInputBackground;
            m_textInput.addEventListener(FeathersEventType.ENTER, onTextInputEnter);
            m_textInput.addEventListener(Event.CHANGE, onTextChange);
            addChild(m_textInput);
            m_lowerCaseButtons = new Vector.<Vector.<DisplayObject>>();
            
            var lowerCaseCharacterRows:Vector.<Vector.<String>> = new Vector.<Vector.<String>>();
            lowerCaseCharacterRows.push(Vector.<String>(["q" , "w", "e", "r", "t", "y", "u", "i", "o", "p"]));
            lowerCaseCharacterRows.push(Vector.<String>(["a", "s", "d", "f", "g", "h", "j", "k", "l"]));
            lowerCaseCharacterRows.push(Vector.<String>(["z", "x", "c", "v", "b", "n", "m"]));
            m_lowerCaseButtons = this.createListsOfButtonsRows(lowerCaseCharacterRows, buttonWidth, buttonHeight);
            
            var upperCaseCharacterRows:Vector.<Vector.<String>> = new Vector.<Vector.<String>>();
            upperCaseCharacterRows.push(Vector.<String>(["Q" , "W", "E", "R", "T", "Y", "U", "I", "O", "P"]));
            upperCaseCharacterRows.push(Vector.<String>(["A", "S", "D", "F", "G", "H", "J", "K", "L"]));
            upperCaseCharacterRows.push(Vector.<String>(["Z", "X", "C", "V", "B", "N", "M"]));
            m_upperCaseButtons = this.createListsOfButtonsRows(upperCaseCharacterRows, buttonWidth, buttonHeight);
            
            this.layoutButtonRows(m_lowerCaseButtons, buttonWidth, buttonHeight, buttonGap);
            
            // Create shift, back, space, and accept buttons and lay them out
            var shiftButton:Button = WidgetUtil.createButton(
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
            (shiftButton.defaultSkin as Scale9Image).color = XColor.ROYAL_BLUE;
            (shiftButton.hoverSkin as Scale9Image).color = XColor.BRIGHT_ORANGE;
            (shiftButton.downSkin as Scale9Image).color = XColor.BRIGHT_ORANGE;
            shiftButton.addEventListener(Event.TRIGGERED, onShiftClicked);
            shiftButton.width = buttonWidth * 1.5 + buttonGap;
            shiftButton.height = buttonHeight;
            var thirdCharacterRow:Vector.<DisplayObject> = m_lowerCaseButtons[2];
            shiftButton.x = thirdCharacterRow[thirdCharacterRow.length - 1].x + buttonWidth + buttonGap;
            shiftButton.y = thirdCharacterRow[0].y;
            m_buttonsContainer.addChild(shiftButton);
            m_shiftButton = shiftButton;
            
            var backButton:Button = WidgetUtil.createButton(
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
            (backButton.defaultSkin as Scale9Image).color = XColor.ROYAL_BLUE;
            (backButton.hoverSkin as Scale9Image).color = XColor.BRIGHT_ORANGE;
            (backButton.downSkin as Scale9Image).color = XColor.BRIGHT_ORANGE;
            var backIcon:Image = new Image(assetManager.getTexture("arrow_rotate"));
            backIcon.scaleX = backIcon.scaleY = (buttonHeight / backIcon.height);
            backButton.defaultIcon = backIcon;
            backButton.addEventListener(Event.TRIGGERED, onBackClicked);
            backButton.width = buttonWidth * 1.5;
            backButton.height = buttonHeight;
            var firstCharacterRow:Vector.<DisplayObject> = m_lowerCaseButtons[0];
            backButton.x = firstCharacterRow[firstCharacterRow.length - 1].x + buttonWidth + buttonGap;
            backButton.y = firstCharacterRow[0].y;
            m_buttonsContainer.addChild(backButton);
            m_backButton = backButton;
            
            var acceptButton:Button = WidgetUtil.createButton(
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
            (acceptButton.defaultSkin as Scale9Image).color = XColor.ROYAL_BLUE;
            (acceptButton.hoverSkin as Scale9Image).color = XColor.BRIGHT_ORANGE;
            (acceptButton.downSkin as Scale9Image).color = XColor.BRIGHT_ORANGE;
            
            var acceptIcon:Image = new Image(assetManager.getTexture("correct"));
            acceptIcon.scaleX = acceptIcon.scaleY = (buttonHeight / acceptIcon.height);
            acceptButton.defaultIcon = acceptIcon;
            acceptButton.addEventListener(Event.TRIGGERED, onAcceptClicked);
            acceptButton.width = buttonWidth * 2;
            acceptButton.height = buttonHeight * 2 + buttonGap;
            var secondCharacterRow:Vector.<DisplayObject> = m_lowerCaseButtons[1];
            acceptButton.x = secondCharacterRow[secondCharacterRow.length - 1].x + buttonWidth + buttonGap;
            acceptButton.y = buttonHeight + buttonGap;
            m_buttonsContainer.addChild(acceptButton);
            m_acceptButton = acceptButton;
            
            // Space goes at the very bottom
            var spaceButton:Button = WidgetUtil.createButton(
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
            (spaceButton.defaultSkin as Scale9Image).color = XColor.ROYAL_BLUE;
            (spaceButton.hoverSkin as Scale9Image).color = XColor.BRIGHT_ORANGE;
            (spaceButton.downSkin as Scale9Image).color = XColor.BRIGHT_ORANGE;
            spaceButton.addEventListener(Event.TRIGGERED, onCharacterButtonClicked);
            spaceButton.width = buttonWidth * 5 + buttonGap * 4;
            spaceButton.height = buttonHeight;
            spaceButton.x = buttonWidth * 2.5;
            spaceButton.y = (buttonHeight + buttonGap) * m_lowerCaseButtons.length;
            m_buttonsContainer.addChild(spaceButton);
            m_spaceButton = spaceButton;
            
            var buttonsLeftPadding:Number = 28;
            var buttonsTotalWidth:Number = 11.5 * buttonWidth + 10 * buttonGap;
            
            m_textInput.width = buttonsTotalWidth * 0.75;
            m_textInput.height = 70;
            
            var backgroundImage:Image = new Image(assetManager.getTexture("summary_background"));
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
        
        public function getText():String
        {
            return m_textInput.text;
        }
        
        public function setText(value:String):void
        {
            m_textInput.text = value;
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_textInput.removeEventListener(FeathersEventType.ENTER, onTextInputEnter);
            m_textInput.removeEventListener(Event.CHANGE, onTextChange);
            m_textInput.removeFromParent(true);
            
            cleanButtonList(m_lowerCaseButtons);
            cleanButtonList(m_upperCaseButtons);
            
            // Clean out listeners on buttons
            function cleanButtonList(buttons:Vector.<Vector.<DisplayObject>>):void
            {
                var i:int;
                for (i = 0; i < buttons.length; i++)
                {
                    var charactersInRow:Vector.<DisplayObject> = buttons[i];
                    var j:int;
                    for (j = 0; j < charactersInRow.length; j++)
                    {
                        var button:Button = charactersInRow[j] as Button;
                        button.removeEventListener(Event.TRIGGERED, onCharacterButtonClicked);
                        button.removeFromParent(true);
                    }
                }
            }
            
            m_shiftButton.removeEventListener(Event.TRIGGERED, onShiftClicked);
            m_shiftButton.removeFromParent(true);
            
            m_backButton.removeEventListener(Event.TRIGGERED, onBackClicked);
            m_backButton.removeFromParent(true);
            
            m_acceptButton.removeEventListener(Event.TRIGGERED, onAcceptClicked);
            m_acceptButton.removeFromParent(true);
            
            m_spaceButton.removeEventListener(Event.TRIGGERED, onCharacterButtonClicked);
            m_spaceButton.removeFromParent(true);
        }
        
        private function createListsOfButtonsRows(characterRows:Vector.<Vector.<String>>, 
                                                  buttonWidth:Number, 
                                                  buttonHeight:Number):Vector.<Vector.<DisplayObject>>
        {
            var listOfButtonRows:Vector.<Vector.<DisplayObject>> = new Vector.<Vector.<DisplayObject>>();
            var i:int;
            for (i = 0; i < characterRows.length; i++)
            {
                // Create a virtual keyboard for all the buttons
                var outButtonList:Vector.<DisplayObject> = new Vector.<DisplayObject>();
                var characters:Vector.<String> = characterRows[i];
                var j:int;
                var numCharacters:int = characters.length;
                for (j = 0; j < numCharacters; j++)
                {
                    var character:String = characters[j];
                    var button:Button = WidgetUtil.createButton(
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
                    (button.defaultSkin as Scale9Image).color = XColor.ROYAL_BLUE;
                    (button.hoverSkin as Scale9Image).color = XColor.BRIGHT_ORANGE;
                    (button.downSkin as Scale9Image).color = XColor.BRIGHT_ORANGE;
                    button.addEventListener(Event.TRIGGERED, onCharacterButtonClicked);
                    button.width = buttonWidth;
                    button.height = buttonHeight;
                    outButtonList.push(button);
                }
                listOfButtonRows.push(outButtonList);
            }
            
            return listOfButtonRows;
        }
        
        private function layoutButtonRows(buttonRows:Vector.<Vector.<DisplayObject>>,
                                          buttonWidth:Number, 
                                          buttonHeight:Number, 
                                          buttonGap:Number):void
        {
            // Layout all of the character buttons
            var i:int
            var yOffset:Number = 0;
            for (i = 0; i < buttonRows.length; i++)
            {
                var buttonList:Vector.<DisplayObject> = buttonRows[i];
                var numButtons:int = buttonList.length;
                var xOffset:Number = i * (buttonWidth * 0.5);
                var j:int;
                for (j = 0; j < numButtons; j++)
                {
                    var button:Button = buttonList[j] as Button;
                    button.x = xOffset;
                    button.y = yOffset;
                    xOffset += buttonWidth + buttonGap;
                }
                
                yOffset += buttonHeight + buttonGap;
            }
        }
        
        private function showButtons(lowerCase:Boolean):void
        {
            var buttonsToAdd:Vector.<Vector.<DisplayObject>>;
            var buttonsToRemove:Vector.<Vector.<DisplayObject>>;
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
            
            var i:int;
            for (i = 0; i < buttonsToRemove.length; i++)
            {
                for each (var button:DisplayObject in buttonsToRemove[i])
                {
                    button.removeFromParent();
                }
            }
            
            this.layoutButtonRows(buttonsToAdd, buttonWidth, buttonHeight, buttonGap);
            for (i = 0; i < buttonsToAdd.length; i++)
            {
                for each (button in buttonsToAdd[i])
                {
                    m_buttonsContainer.addChild(button);
                }
            }
            
            // Change characters on the shift button
            m_shiftButton.label = (lowerCase) ?
                "A-Z" : "a-z";
        }
        
        private function onTextInputEnter():void
        {
            onAcceptClicked(null);
        }
        
        private function onTextChange():void
        {
            m_textInput.setFocus();
        }
        
        private function onCharacterButtonClicked(event:Event):void
        {
            var button:Button = event.target as Button;
            
            if (m_textInput.text.length < m_textInput.maxChars)
            {
                m_textInput.text += button.label;
            }
            m_textInput.setFocus();
        }
        
        private function onShiftClicked(event:Event):void
        {
            // Check if the lower case buttons are visible and toggle
            var lowerCaseVisible:Boolean = m_lowerCaseButtons[0][0].parent != null;
            showButtons(!lowerCaseVisible);
        }
        
        private function onAcceptClicked(event:Event):void
        {
            if (m_acceptCallback != null)
            {
                m_acceptCallback();
            }
        }
        
        private function onBackClicked(event:Event):void
        {
            var currentText:String = m_textInput.text;
            var numCharacters:int = currentText.length;
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
}