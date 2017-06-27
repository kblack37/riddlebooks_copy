package wordproblem.callouts
{
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
    public class CalloutCreator
    {
        private var m_textParser:TextParser;
        private var m_textViewFactory:TextViewFactory;
        
        public function CalloutCreator(textParser:TextParser, 
                                       textViewFactory:TextViewFactory)
        {
            m_textParser = textParser;
            m_textViewFactory = textViewFactory;
        }
        
        public function createDefaultCalloutText(text:String, 
                                                 width:Number, 
                                                 height:Number=-1, 
                                                 color:uint=0x000000, 
                                                 fontSize:int=18):DisplayObject
        {
            var defaultFontFamily:String = "Verdana";//GameFonts.DEFAULT_FONT_NAME;
            var contentHeight:Number = height;
            if (height < 0)
            {
                var calloutMeasuringTextField:MeasuringTextField = new MeasuringTextField();
                calloutMeasuringTextField.wordWrap = true;
                var calloutTextFormat:TextFormat = new TextFormat()
                calloutTextFormat.font = defaultFontFamily;
                calloutTextFormat.size = fontSize;
                calloutMeasuringTextField.width = width;
                calloutMeasuringTextField.defaultTextFormat = calloutTextFormat;
                calloutMeasuringTextField.text = text;
                contentHeight = calloutMeasuringTextField.textHeight + 10;
            }
            
            return new TextField(width, contentHeight, text, defaultFontFamily, fontSize, color);
        }
        
        /**
         * Generate a callout component from a set of parameters
         * 
         * TODO: Document params
         * The heaviest lifting this piece does is create a textfield
         * Otherwise it really just fills in the needed params
         */
        public function createCalloutComponentFromText(param:Object):CalloutComponent
        {
            var calloutComponent:CalloutComponent = new CalloutComponent(param.id);
            var contentWidth:Number = (param.hasOwnProperty("width")) ? param.width : 100;
            var contentHeight:Number = (param.hasOwnProperty("height")) ? param.height : 50;
            
            // Must choose between a regualr text field vs xml formatted text
            var calloutMainDisplay:DisplayObject = null;
            if (param.hasOwnProperty("text"))
            {
                if (!param.hasOwnProperty("height"))
                {
                    contentHeight = -1
                }
                var fontColor:uint = (param.hasOwnProperty("color")) ?
                    param.color : 0x000000;
                calloutMainDisplay = this.createDefaultCalloutText(param.text, contentWidth, contentHeight, fontColor);
            }
            else if (param.hasOwnProperty("dialog"))
            {
                calloutMainDisplay = TextParserUtil.createTextViewFromXML(param.dialog, param.styleObject, contentWidth, m_textParser, m_textViewFactory);
            }
            else if (param.hasOwnProperty("content"))
            {
                calloutMainDisplay = param.content as DisplayObject;
            }
            calloutComponent.display = calloutMainDisplay;
            
            var backgroundTextureName:String = (param.hasOwnProperty("backgroundTexture")) ?
                param.backgroundTexture : "button_white";
            calloutComponent.backgroundTexture = backgroundTextureName;
            
            var backgroundColor:uint = (param.hasOwnProperty("backgroundColor")) ?
                param.backgroundColor : 0xFF9900;
            calloutComponent.backgroundColor = backgroundColor;
            
            var padding:int = 10;
            if (param.hasOwnProperty("padding"))
            {
                padding = param.padding;
            }
            calloutComponent.edgePadding = padding;
            
            if (param.hasOwnProperty("direction"))
            {
                calloutComponent.directionFromOrigin = param.direction;
            }
            
            if (param.hasOwnProperty("animationPeriod"))
            {
                calloutComponent.arrowAnimationPeriod = param.animationPeriod;
            }
            
            if (!param.hasOwnProperty("noArrow"))
            {
                calloutComponent.arrowTexture = "callout_arrow";
            }
            
            if (param.hasOwnProperty("xOffset"))
            {
                calloutComponent.xOffset = param.xOffset;
            }
            
            if (param.hasOwnProperty("yOffset"))
            {
                calloutComponent.yOffset = param.yOffset;
            }
            
            if (param.hasOwnProperty("closeOnTouchOutside"))
            {
                calloutComponent.closeOnTouchOutside = param.closeOnTouchOutside;
            }
            
            if (param.hasOwnProperty("closeOnTouchInside"))
            {
                calloutComponent.closeOnTouchInside = param.closeOnTouchInside;
            }
            
            if (param.hasOwnProperty("closeCallback"))
            {
                calloutComponent.closeCallback = param.closeCallback;
            }
            
            return calloutComponent;
        }
    }
}