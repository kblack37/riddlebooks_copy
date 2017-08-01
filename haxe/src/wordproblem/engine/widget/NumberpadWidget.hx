package wordproblem.engine.widget;


import flash.geom.Rectangle;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

import dragonbox.common.util.XColor;

import haxe.Constraints.Function;

import starling.display.Button;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;

import wordproblem.display.Layer;
import wordproblem.engine.text.GameFonts;
import wordproblem.resource.AssetManager;

/**
 * This widget allows for a player to punch in a numeric answer manually.
 */
class NumberpadWidget extends Layer
{
    public var value(never, set) : Float;

    /**
     * Total characters allowed in a typed number
     */
    private var m_characterLimit : Int;
    
    /**
     * Display showing the current number
     */
	// TODO: uncomment when a text input replacement is found
    //private var m_numberDisplay : TextInput;
    
    /**
     * Null entries can be 
     */
    private var m_buttons : Array<Button>;
    
    /**
     * Function that gets triggered if the user has pressed ok,
     * callback accepts single parameter of the number that was entered
     */
    private var m_okCallback : Function;
    
    /**
     * Layer containing all the buttons
     */
    private var m_buttonContainer : Sprite;
    
    /**
     * Container for display and buttons
     */
    private var m_mainDisplayContainer : Sprite;
    
    /**
     *
     * @param okCallback
     *      signature callback(enteredNumber:Number):void
     */
    public function new(assetManager : AssetManager,
            okCallback : Function,
            showDecimal : Bool,
            showNegative : Bool,
            characterLimit : Int = 10)
    {
        super();
        
        m_characterLimit = characterLimit;
        
        // Create the number buttons
        var i : Int = 0;
        var buttonWidth : Float = 64;
        var buttonHeight : Float = 64;
        var buttonPadding : Float = 4;
        var columns : Int = 3;
        
        m_mainDisplayContainer = new Sprite();
        
		// TODO: uncomment when a text input replacement is found
        //m_numberDisplay = new TextInput();
        //m_numberDisplay.maxChars = m_characterLimit;
        //m_numberDisplay.restrict = "0-9";
        //m_numberDisplay.addEventListener(FeathersEventType.FOCUS_OUT, onTextInputOutOfFocus);
        //m_numberDisplay.textEditorFactory = function() : ITextEditor
                //{
                    //var editor : TextFieldTextEditor = new TextFieldTextEditor();
                    //editor.textFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 28, 0xFFFFFF, null, null, null, null, null, TextFormatAlign.CENTER);
                    //editor.embedFonts = true;
                    //return editor;
                //};
        //
        //var numberBackground : Scale9Image = new Scale9Image(new Scale9Textures(assetManager.getTexture("button_white"), new Rectangle(8, 8, 16, 16)));
        //numberBackground.color = 0x000000;
        //numberBackground.width = m_numberDisplay.width;
        //numberBackground.height = m_numberDisplay.height;
        //m_numberDisplay.backgroundSkin = numberBackground;
        //m_numberDisplay.width = buttonWidth * (columns + 1) + buttonPadding * columns;
        //m_numberDisplay.height = 72;
        //m_mainDisplayContainer.addChild(m_numberDisplay);
        
		// TODO: uncomment when a text input replacement is found
        m_buttons = new Array<Button>();
        m_buttonContainer = new Sprite();
        //m_buttonContainer.y = m_numberDisplay.y + m_numberDisplay.height + 10;
        
        // Create the bottom most row which contains
        // a zero, a decimal, and a button to switch between positive and negative
        // A null entry means the space in the grid should be blank
        var decimalLabel : String = ((showDecimal)) ? "." : null;
        var negativeLabel : String = ((showNegative)) ? "+/-" : null;
        var buttonLabels : Array<String> = [
                decimalLabel, "0", negativeLabel, "1", "2", "3", "4", "5", "6", "7", "8", "9", "Clear", "Back", "OK"]; 
		
		// Create all of the buttons
        for (i in 0...buttonLabels.length){
            var button : Button = null;
            if (buttonLabels[i] != null) 
            {
                button = WidgetUtil.createButton(
                                assetManager,
                                "button_white",
                                "button_white",
                                null,
                                null,
                                buttonLabels[i],
                                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 24, 0xFFFFFF),
                                null,
                                new Rectangle(8, 8, 16, 16)
                                );
				// TODO: starling buttons use textures, not images, and so you can't change the color like this
                //(try cast(button.defaultSkin, Scale9Image) catch(e:Dynamic) null).color = XColor.ROYAL_BLUE;
                //(try cast(button.downSkin, Scale9Image) catch(e:Dynamic) null).color = XColor.BRIGHT_ORANGE;
                button.width = buttonWidth;
                button.height = buttonHeight;
                button.addEventListener(Event.TRIGGERED, onButtonClick);
                m_buttonContainer.addChild(button);
            }
            
            m_buttons.push(button);
        }  
		
		// Layout the number buttons in a numeric grid (everything except the last three)  
        for (i in 0...m_buttons.length - 3){
            var buttonX : Float = (i % columns) * (buttonWidth + buttonPadding);
            var buttonY : Float = (columns * buttonHeight + (columns - 1) * buttonPadding) - Math.floor(i / columns) * (buttonHeight + buttonPadding);
            
            if (m_buttons[i] != null) 
            {
                var button = m_buttons[i];
                button.x = buttonX;
                button.y = buttonY;
            }
        }  // Final column of buttons are for clear, back, and okay we want to size them a bit differently  
        
        
        
        var finalColumnButtonHeight : Float = 4 * buttonHeight / 3;
        for (i in m_buttons.length - 3...m_buttons.length){
            var button = m_buttons[i];
            button.height = finalColumnButtonHeight;
            button.x = columns * (buttonWidth + buttonPadding);
            button.y = Math.floor(i % 3) * (buttonPadding + finalColumnButtonHeight);
        }
        
        m_mainDisplayContainer.addChild(m_buttonContainer);
        addChild(m_mainDisplayContainer);
        
		// TODO: uncomment when a text input replacement is found
        var backgroundImage : Image = new Image(assetManager.getTexture("summary_background"));
        backgroundImage.width = m_buttonContainer.width + 50;
        //backgroundImage.height = m_numberDisplay.height + m_buttonContainer.height + 50;
        m_mainDisplayContainer.x = (backgroundImage.width - m_mainDisplayContainer.width) * 0.5;
        m_mainDisplayContainer.y = (backgroundImage.height - m_mainDisplayContainer.height) * 0.5;
        addChildAt(backgroundImage, 0);
        
        m_okCallback = okCallback;
        
        // Numberpad always starts at zero
        this.value = 0;
    }
    
    /**
     * HACK: Only works if this widget was constructed with the decimal in the first place
     */
    public function setDecimalButtonVisible(visible : Bool) : Void
    {
        var i : Int = 0;
        var numButtons : Int = m_buttons.length;
        for (i in 0...numButtons){
            var button : Button = m_buttons[i];
            if (button.text == ".") 
            {
                button.visible = visible;
                break;
            }
        }
    }
    
    /**
     * Set the number display to show a current numeric value
     */
    private function set_value(value : Float) : Float
    {
		// TODO: uncomment when a text input replacement is found
        //m_numberDisplay.text = "" + value;
        return value;
    }
    
    override public function dispose() : Void
    {
        var numButtons : Int = m_buttons.length;
        var i : Int = 0;
        for (i in 0...numButtons){
            var button : Button = m_buttons[i];
            if (button != null) 
            {
                button.removeEventListener(Event.TRIGGERED, onButtonClick);
                button.removeFromParent(true);
            }
        }
        
		// TODO: uncomment when a text input replacement is found
        //m_numberDisplay.removeEventListener(FeathersEventType.FOCUS_OUT, onTextInputOutOfFocus);
        
        super.dispose();
    }
    
    private function onButtonClick(event : Event) : Void
    {
        var targetButton : Button = try cast(event.currentTarget, Button) catch(e:Dynamic) null;
        var numButtons : Int = m_buttons.length;
        var i : Int = 0;
		// TODO: uncomment when a text input replacement is found
        //for (i in 0...numButtons){
            //if (targetButton == m_buttons[i]) 
            //{
                //var startingText : String = m_numberDisplay.text;
                //// If clear button pressed then delete all the contents
                //if (targetButton.label == "Clear") 
                //{
                    //m_numberDisplay.text = "0";
                //}
                //// If back press then remove the most recently entered character
                //else if (targetButton.label == "Back") 
                //{
                    //
                    //if (startingText.length == 1 || (startingText.length == 2 && startingText.charAt(0) == "-1")) 
                    //{
                        //m_numberDisplay.text = "0";
                    //}
                    //else 
                    //{
                        //m_numberDisplay.text = startingText.substr(0, startingText.length - 1);
                    //}
                //}
                //// If ok button pressed then submit the answer
                //else if (targetButton.label == "OK") 
                //{
                    //var enteredNumber : Float = parseFloat(startingText);
                    //
                    //if (Math.isNaN(enteredNumber)) 
                    //{
                        //enteredNumber = 0;
                    //}
                    //
                    //if (m_okCallback != null) 
                    //{
                        //m_okCallback(enteredNumber);
                    //}
                //}
                //// If positive/negative button clicked toggle between the signs
                //else if (targetButton.label == "+") 
                //{
                    //if (startingText != "0") 
                    //{
                        //if (startingText.charAt(0) == "-") 
                        //{
                            //m_numberDisplay.text = startingText.substring(1, startingText.length);
                        //}
                        //else 
                        //{
                            //m_numberDisplay.text = "-" + startingText;
                        //}
                    //}
                //}
                //else if (m_numberDisplay.text.length < m_characterLimit) 
                //{
                    //if (startingText == "0") 
                    //{
                        //if (targetButton.label == ".") 
                        //{
                            //m_numberDisplay.text += targetButton.label;
                        //}
                        //else if (targetButton.label != "0") 
                        //{
                            //// If the display has just a zero replace it with a number
                            //// unless it is the decimal in which case a leading zero is ok
                            //m_numberDisplay.text = targetButton.label;
                        //}
                    //}
                    //else 
                    //{
                        //// Do not add multiple decimals
                        //if (targetButton.label != "." || startingText.indexOf(".") == -1) 
                        //{
                            //m_numberDisplay.text += targetButton.label;
                        //}
                    //}
                //}
            //}
        //}
    }
    
    /**
     * We need to add restrictions when the user is typing. We perform the clean up after 
     */
    private function onTextInputOutOfFocus() : Void
    {
		// TODO: uncomment when a text input replacement is found
        //var startingText : String = m_numberDisplay.text;
        //
        //// Always show a zero instead of an empty string
        //if (startingText == "") 
        //{
            //m_numberDisplay.text = "0";
        //}
        //// Strip off leading zeros unless they are right of a decimal or the first zero
        //// to the left of the decimal
        //else if (startingText.length > 1) 
        //{
            //var leadingZeroEndIndex : Int = -1;
            //var i : Int = 0;
            //var numChars : Int = startingText.length;
            //for (i in 0...numChars){
                //var currentChar : String = startingText.charAt(i);
                //if (currentChar == "0") 
                //{
                    //leadingZeroEndIndex = i;
                //}
                //else 
                //{
                    //// Just completely ignore leading zeroes if there is a decimal
                    //if (currentChar == ".") 
                    //{
                        //leadingZeroEndIndex = -1;
                    //}
                    //break;
                //}
            //}
            //
            //if (leadingZeroEndIndex > -1) 
            //{
                //m_numberDisplay.text = startingText.substr(leadingZeroEndIndex + 1);
            //}
        //}
    }
}
