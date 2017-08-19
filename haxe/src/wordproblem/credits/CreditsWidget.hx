package wordproblem.credits;


import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.MouseEvent;
import openfl.text.TextFormat;

import cgs.audio.Audio;
import cgs.internationalization.StringTable;

import haxe.Constraints.Function;

import wordproblem.display.LabelButton;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;

import wordproblem.engine.text.GameFonts;
import wordproblem.engine.text.MeasuringTextField;
import wordproblem.engine.widget.WidgetUtil;
import wordproblem.resource.AssetManager;

/**
 * A screen used to give credits to various parties for using their resources
 */
class CreditsWidget extends Sprite
{
    private var m_onCloseCallback : Function;
    
    public function new(width : Float,
            height : Float,
            assetManager : AssetManager,
            onCloseCallback : Function,
            buttonColor : Int)
    {
        super();
        
        m_onCloseCallback = onCloseCallback;
        
        // Add darkened background sprite
        var backgroundQuad : Bitmap = new Bitmap(new BitmapData(Std.int(width), Std.int(height), false, 0x000000));
        backgroundQuad.alpha = 0.5;
        addChild(backgroundQuad);
        
        // Add actual background image
        var backgroundContainer : Sprite = new Sprite();
        var backgroundContainerWidth : Float = 600;
        var backgroundContainerHeight : Float = 450;
        backgroundContainer.x = (width - backgroundContainerWidth) * 0.5;
        backgroundContainer.y = (height - backgroundContainerHeight) * 0.5;
        addChild(backgroundContainer);
        
        var backgroundImage : Bitmap = new Bitmap(assetManager.getBitmapData("summary_background"));
        backgroundImage.width = backgroundContainerWidth;
        backgroundImage.height = backgroundContainerHeight;
        backgroundContainer.addChild(backgroundImage);
        
        var measuringTextField : MeasuringTextField = new MeasuringTextField();
        var textFormat : TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0xFFFFFF);
        measuringTextField.defaultTextFormat = textFormat;
        
		// TODO: uncomment once cgs library is finished
        var titleText : String = ""; // StringTable.lookup("credits");
        var titleTextField : TextField = new TextField();
		titleTextField.width = 300;
		titleTextField.height = 70;
		titleTextField.text = titleText;
		titleTextField.setTextFormat(new TextFormat(textFormat.font, 36, 0x3399FF, null, null, true));
        titleTextField.x = (backgroundContainerWidth - titleTextField.width) * 0.5;
        titleTextField.y = 10;
        backgroundContainer.addChild(titleTextField);
        
        var centerForGameScienceText : String = "Produced by the Center for Game Science at the University of Washington";
        var centerForGameScienceTextField : TextField = new TextField();
		centerForGameScienceTextField.width = 450;
		centerForGameScienceTextField.height = 100; 
		centerForGameScienceTextField.text = centerForGameScienceText; 
		centerForGameScienceTextField.setTextFormat(new TextFormat(textFormat.font, 22, textFormat.color));
        centerForGameScienceTextField.x = (backgroundContainerWidth - centerForGameScienceTextField.width) * 0.5;
        centerForGameScienceTextField.y = 50;
        backgroundContainer.addChild(centerForGameScienceTextField);
        
        var cgsLogoBitmapData : BitmapData = assetManager.getBitmapData("cgs_logo");
        var cgsLogo : Bitmap = new Bitmap(cgsLogoBitmapData);
        cgsLogo.x = (backgroundContainerWidth - cgsLogoBitmapData.width) * 0.5;
        cgsLogo.y = centerForGameScienceTextField.y + centerForGameScienceTextField.height;
        backgroundContainer.addChild(cgsLogo);
        
        // Add button to close this screen
        var backButton : LabelButton = WidgetUtil.createGenericColoredButton(
                assetManager, buttonColor,
				// TODO: uncomment once cgs library is finished
                "", //StringTable.lookup("back"),
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 24, 0xFFFFFF),
                new TextFormat(GameFonts.DEFAULT_FONT_NAME, 24, 0xFFFFFF)
                );
        backButton.addEventListener(MouseEvent.CLICK, onTriggered);
        
        var backButtonWidth : Float = 200;
        backButton.width = backButtonWidth;
        backButton.x = (backgroundContainerWidth - backButtonWidth) * 0.5;
        backButton.y = backgroundContainerHeight - 70;
        backgroundContainer.addChild(backButton);
    }
    
    private function onTriggered(event : Dynamic) : Void
    {
        Audio.instance.playSfx("button_click");
        
        if (this.parent != null) this.parent.removeChild(this);
        
        if (m_onCloseCallback != null) 
        {
            m_onCloseCallback();
        }
    }
}
