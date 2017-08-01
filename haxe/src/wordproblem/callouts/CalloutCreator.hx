package wordproblem.callouts;


import flash.text.TextFormat;

import starling.display.DisplayObject;
import starling.text.TextField;

import wordproblem.engine.component.CalloutComponent;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.text.MeasuringTextField;
import wordproblem.engine.text.TextParser;
import wordproblem.engine.text.TextParserUtil;
import wordproblem.engine.text.TextViewFactory;

/**
 * Logic that handles creation of new callout components.
 * Centralized in one place to several different scripts have access to the same behavior.
 */
class CalloutCreator
{
    private var m_textParser : TextParser;
    private var m_textViewFactory : TextViewFactory;
    
    public function new(textParser : TextParser,
            textViewFactory : TextViewFactory)
    {
        m_textParser = textParser;
        m_textViewFactory = textViewFactory;
    }
    
    public function createDefaultCalloutText(text : String,
            width : Float,
            height : Float = -1,
            color : Int = 0x000000,
            fontSize : Int = 18) : DisplayObject
    {
        var defaultFontFamily : String = "Verdana";  //GameFonts.DEFAULT_FONT_NAME;  
        var contentHeight : Float = height;
        if (height < 0) 
        {
            var calloutMeasuringTextField : MeasuringTextField = new MeasuringTextField();
            calloutMeasuringTextField.wordWrap = true;
            var calloutTextFormat : TextFormat = new TextFormat();
            calloutTextFormat.font = defaultFontFamily;
            calloutTextFormat.size = fontSize;
            calloutMeasuringTextField.width = width;
            calloutMeasuringTextField.defaultTextFormat = calloutTextFormat;
            calloutMeasuringTextField.text = text;
            contentHeight = calloutMeasuringTextField.textHeight + 10;
        }
        
        return new TextField(Std.int(width), Std.int(contentHeight), text, defaultFontFamily, fontSize, color);
    }
    
    /**
     * Generate a callout component from a set of parameters
     * 
     * TODO: Document params
     * The heaviest lifting this piece does is create a textfield
     * Otherwise it really just fills in the needed params
     */
    public function createCalloutComponentFromText(param : Dynamic) : CalloutComponent
    {
        var calloutComponent : CalloutComponent = new CalloutComponent(param.id);
        var contentWidth : Float = ((param.exists("width"))) ? param.width : 100;
        var contentHeight : Float = ((param.exists("height"))) ? param.height : 50;
        
        // Must choose between a regualr text field vs xml formatted text
        var calloutMainDisplay : DisplayObject = null;
        if (param.exists("text")) 
        {
            if (!param.exists("height")) 
            {
                contentHeight = -1;
            }
            var fontColor : Int = ((param.exists("color"))) ? 
            param.color : 0x000000;
            calloutMainDisplay = this.createDefaultCalloutText(param.text, contentWidth, contentHeight, fontColor);
        }
        else if (param.exists("dialog")) 
        {
            calloutMainDisplay = TextParserUtil.createTextViewFromXML(param.dialog, param.styleObject, contentWidth, m_textParser, m_textViewFactory);
        }
        else if (param.exists("content")) 
        {
            calloutMainDisplay = try cast(param.content, DisplayObject) catch(e:Dynamic) null;
        }
        calloutComponent.display = calloutMainDisplay;
        
        var backgroundTextureName : String = ((param.exists("backgroundTexture"))) ? 
        param.backgroundTexture : "button_white";
        calloutComponent.backgroundTexture = backgroundTextureName;
        
        var backgroundColor : Int = ((param.exists("backgroundColor"))) ? 
        param.backgroundColor : 0xFF9900;
        calloutComponent.backgroundColor = backgroundColor;
        
        var padding : Int = 10;
        if (param.exists("padding")) 
        {
            padding = param.padding;
        }
        calloutComponent.edgePadding = padding;
        
        if (param.exists("direction")) 
        {
            calloutComponent.directionFromOrigin = param.direction;
        }
        
        if (param.exists("animationPeriod")) 
        {
            calloutComponent.arrowAnimationPeriod = param.animationPeriod;
        }
        
        if (!param.exists("noArrow")) 
        {
            calloutComponent.arrowTexture = "callout_arrow";
        }
        
        if (param.exists("xOffset")) 
        {
            calloutComponent.xOffset = param.xOffset;
        }
        
        if (param.exists("yOffset")) 
        {
            calloutComponent.yOffset = param.yOffset;
        }
        
        if (param.exists("closeOnTouchOutside")) 
        {
            calloutComponent.closeOnTouchOutside = param.closeOnTouchOutside;
        }
        
        if (param.exists("closeOnTouchInside")) 
        {
            calloutComponent.closeOnTouchInside = param.closeOnTouchInside;
        }
        
        if (param.exists("closeCallback")) 
        {
            calloutComponent.closeCallback = param.closeCallback;
        }
        
        return calloutComponent;
    }
}
