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
        var contentWidth : Float = ((Reflect.hasField(param, "width"))) ? param.width : 100;
        var contentHeight : Float = ((Reflect.hasField(param, "height"))) ? param.height : 50;
        
        // Must choose between a regualr text field vs xml formatted text
        var calloutMainDisplay : DisplayObject = null;
        if (Reflect.hasField(param, "text")) 
        {
            if (!Reflect.hasField(param, "height")) 
            {
                contentHeight = -1;
            }
            var fontColor : Int = ((Reflect.hasField(param, "color"))) ? 
            param.color : 0x000000;
            calloutMainDisplay = this.createDefaultCalloutText(param.text, contentWidth, contentHeight, fontColor);
        }
        else if (Reflect.hasField(param, "dialog")) 
        {
            calloutMainDisplay = TextParserUtil.createTextViewFromXML(param.dialog, param.styleObject, contentWidth, m_textParser, m_textViewFactory);
        }
        else if (Reflect.hasField(param, "content")) 
        {
            calloutMainDisplay = try cast(param.content, DisplayObject) catch(e:Dynamic) null;
        }
        calloutComponent.display = calloutMainDisplay;
        
        var backgroundTextureName : String = ((Reflect.hasField(param, "backgroundTexture"))) ? 
        param.backgroundTexture : "button_white";
        calloutComponent.backgroundTexture = backgroundTextureName;
        
        var backgroundColor : Int = ((Reflect.hasField(param, "backgroundColor"))) ? 
        param.backgroundColor : 0xFF9900;
        calloutComponent.backgroundColor = backgroundColor;
        
        var padding : Int = 10;
        if (Reflect.hasField(param, "padding")) 
        {
            padding = param.padding;
        }
        calloutComponent.edgePadding = padding;
        
        if (Reflect.hasField(param, "direction")) 
        {
            calloutComponent.directionFromOrigin = param.direction;
        }
        
        if (Reflect.hasField(param, "animationPeriod")) 
        {
            calloutComponent.arrowAnimationPeriod = param.animationPeriod;
        }
        
        if (!Reflect.hasField(param, "noArrow")) 
        {
            calloutComponent.arrowTexture = "callout_arrow";
        }
        
        if (Reflect.hasField(param, "xOffset")) 
        {
            calloutComponent.xOffset = param.xOffset;
        }
        
        if (Reflect.hasField(param, "yOffset")) 
        {
            calloutComponent.yOffset = param.yOffset;
        }
        
        if (Reflect.hasField(param, "closeOnTouchOutside")) 
        {
            calloutComponent.closeOnTouchOutside = param.closeOnTouchOutside;
        }
        
        if (Reflect.hasField(param, "closeOnTouchInside")) 
        {
            calloutComponent.closeOnTouchInside = param.closeOnTouchInside;
        }
        
        if (Reflect.hasField(param, "closeCallback")) 
        {
            calloutComponent.closeCallback = param.closeCallback;
        }
        
        return calloutComponent;
    }
}
