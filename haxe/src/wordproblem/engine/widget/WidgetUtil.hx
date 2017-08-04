package wordproblem.engine.widget;


import flash.geom.Rectangle;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

import dragonbox.common.util.XColor;

import starling.display.Button;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;

import wordproblem.display.Scale9CompositeImage;
import wordproblem.engine.text.GameFonts;
import wordproblem.resource.AssetManager;

/**
 * A collection of static classes to create various feather ui components
 * 
 * HACK: Alot of these are just parameterization
 */
class WidgetUtil
{
    public static function createGenericColoredButton(assetManager : AssetManager,
            color : Int,
            label : String,
            textFormatDefault : TextFormat,
            textFormatHover : TextFormat = null,
            isToggle : Bool = false) : Button
    {
        var scaleNineRect : Rectangle = new Rectangle(8, 8, 16, 16);
        var buttonBackground : Texture = assetManager.getTexture("button_white.png");
        var buttonOutline : Texture = assetManager.getTexture("button_outline_white.png");
        var defaultSkin : Image = new Image(Texture.fromTexture(buttonBackground, scaleNineRect));
        
		var compositeArray = new Array<Image>();
        var hoverBackground : Image = new Image(Texture.fromTexture(buttonBackground, scaleNineRect));
        var hoverOutline : Image = new Image(Texture.fromTexture(buttonOutline, scaleNineRect));
		compositeArray.push(hoverBackground);
		compositeArray.push(hoverOutline);
        var hoverSkin : Sprite = new Scale9CompositeImage(compositeArray);
		
		compositeArray = new Array<Image>();
        
        var downBackground : Image = new Image(Texture.fromTexture(buttonBackground, scaleNineRect));
        var downOutline : Image = new Image(Texture.fromTexture(buttonOutline, scaleNineRect));
        downOutline.color = 0x000000;
		compositeArray.push(downBackground);
		compositeArray.push(downOutline);
        var downSkin : Sprite = new Scale9CompositeImage(compositeArray);
        
        var button : Button = WidgetUtil.createButtonFromImages(defaultSkin,
                downSkin, null, hoverSkin, label, textFormatDefault, textFormatHover, isToggle);
        changeColorForGenericButton(button, color);
        return button;
    }
    
    /**
     * Change the color of any button created with a call to createGenericColoredButton
     */
    public static function changeColorForGenericButton(genericButton : Button, color : Int) : Void
    {
        var defaultSkin : Image = try cast(genericButton.upState, Image) catch(e:Dynamic) null;
        defaultSkin.color = color;
        
        var hoverSkin : Image = try cast((try cast(genericButton.overState, Sprite) catch(e:Dynamic) null).getChildAt(0), Image) catch(e:Dynamic) null;
        hoverSkin.color = XColor.shadeColor(color, 0.2);
        
        var downSkin : Image = try cast((try cast(genericButton.downState, Sprite) catch(e:Dynamic) null).getChildAt(0), Image) catch(e:Dynamic) null;
        downSkin.color = XColor.shadeColor(color, -0.2);
    }
    
    /**
     *
     * @param nineSlice
     *      Pass in how a texture should be sliced if we want nine slice scaling
     */
    public static function createButton(assetManager : AssetManager,
            defaultSkinName : String,
            downSkinName : String,
            disabledSkinName : String,
            hoverSkinName : String,
            label : String,
            textFormatDefault : TextFormat,
            textFormatHover : TextFormat = null,
            nineSlice : Rectangle = null,
            isToggle : Bool = false) : Button
    {
		function createSkin(textureName : String, nineSlice : Rectangle) : DisplayObject
        {
            var useNineSlice : Bool = (nineSlice != null);
            var skin : DisplayObject = null;
            var texture : Texture = assetManager.getTexture(textureName);
            if (useNineSlice) 
            {
                skin = new Image(Texture.fromTexture(texture, nineSlice));
            }
            else 
            {
                skin = new Image(texture);
            }
            
            return skin;
        };
		
        var defaultSkin : DisplayObject = createSkin(defaultSkinName, nineSlice);
        
		var downSkin : DisplayObject = null;
        if (downSkinName != null) 
        {
            downSkin = createSkin(downSkinName, nineSlice);
        }
        
		var disabledSkin : DisplayObject = null;
        if (disabledSkinName != null) 
        {
            disabledSkin = createSkin(disabledSkinName, nineSlice);
        }
        
		var hoverSkin : DisplayObject = null;
        if (hoverSkinName != null) 
        {
            hoverSkin = createSkin(hoverSkinName, nineSlice);
        }
		
		return createButtonFromImages(defaultSkin, downSkin, disabledSkin, hoverSkin, label, textFormatDefault, textFormatHover, isToggle);
    }
    
    public static function createButtonFromImages(defaultSkin : DisplayObject,
            downSkin : DisplayObject,
            disabledSkin : DisplayObject,
            hoverSkin : DisplayObject,
            label : String,
            textFormatDefault : TextFormat,
            textFormatHover : TextFormat = null,
            isToggle : Bool = false) : Button
    {
		// TODO: uncomment once ToggleButton is designed
		//
        var button : Button = /*((isToggle)) ? new ToggleButton() : */new Button(
			try cast(defaultSkin, Texture) catch (e : Dynamic) null,
			label,
			try cast(downSkin, Texture) catch (e : Dynamic) null,
			try cast(hoverSkin, Texture) catch (e : Dynamic) null,
			try cast(disabledSkin, Texture) catch (e : Dynamic) null
		);
        
		// TODO: uncomment once buttons need to be figured out
        if (textFormatDefault != null) 
        {
            //button.defaultLabelProperties.textFormat = textFormatDefault;
            //button.defaultLabelProperties.wordWrap = true;
            
            //button.labelFactory = function() : ITextRenderer
                    //{
                        //var textRenderer : TextFieldTextRenderer = new TextFieldTextRenderer();
                        //textRenderer.embedFonts = GameFonts.getFontIsEmbedded(textFormatDefault.font);
                        //if (textFormatDefault.align == null) 
                        //{
                            //textFormatDefault.align = TextFormatAlign.CENTER;
                        //}
                        //textRenderer.textFormat = textFormatDefault;
                        //
                        //// Need to set the width otherwise the label is set to some small value
                        //if (button.width > 0) 
                        //{
                            //textRenderer.width = button.width;
                        //}
                        //
                        //return textRenderer;
                    //};
        }
		
		// Have an optional text format for over
        if (textFormatHover != null) 
        {
            //button.hoverLabelProperties.textFormat = textFormatHover;
            //button.downLabelProperties.textFormat = textFormatHover;
        }
        
        return button;
    }
    
    /**
     * Create arrow pointing left or right, used as a button skin
     */
    public static function createPointingArrow(arrowTexture : Texture,
            pointLeft : Bool,
            scaleFactor : Float,
            color : Int = 0xFFFFFF) : Image
    {
        var arrowImage : Image = new Image(arrowTexture);
        arrowImage.scaleX = arrowImage.scaleY = scaleFactor;
        if (pointLeft) 
        {
            arrowImage.scaleX *= -1;
            arrowImage.pivotX = arrowTexture.width;
        }
        arrowImage.color = color;
        return arrowImage;
    }
    
	// TODO: uncomment when scrollbars are redesigned
    //public static function createScrollbar(assetManager : AssetManager) : IScrollBar
    //{
        //var scrollbar : ScrollBar = new ScrollBar();
        //scrollbar.thumbFactory = function() : Button
                //{
                    //var thumbButton : Button = new Button();
                    //thumbButton.defaultSkin = new Image(getTexture("scrollbar_button.png"));
                    //thumbButton.downSkin = new Image(getTexture("scrollbar_button_click.png"));
                    //thumbButton.hoverSkin = new Image(getTexture("scrollbar_button_mouseover.png"));
                    //return thumbButton;
                //};
        //
        //scrollbar.decrementButtonFactory = function() : Button
                //{
                    //var decrementButton : Button = new Button();
                    //decrementButton.defaultSkin = new Image(getTexture("scrollbar_up.png"));
                    //decrementButton.downSkin = new Image(getTexture("scrollbar_up_click.png"));
                    //return decrementButton;
                //};
        //
        //scrollbar.incrementButtonFactory = function() : Button
                //{
                    //var incrementButton : Button = new Button();
                    //incrementButton.defaultSkin = new Image(getTexture("scrollbar_down.png"));
                    //incrementButton.downSkin = new Image(getTexture("scrollbar_down_click.png"));
                    //return incrementButton;
                //};
        //
        //scrollbar.minimumTrackFactory = function() : Button
                //{
                    //var trackButton : Button = new Button();
                    //trackButton.defaultSkin = new Image(getTexture("scrollbar_track.png"));
                    //return trackButton;
                //};
        //
        //scrollbar.minimum = 0;
        //scrollbar.maximum = 1.0;
        //scrollbar.step = 0.05;  // Increment amount when pressing increment buttons or slowly moving thumb  
        //scrollbar.value = 0.0;
        //scrollbar.page = 0.1;    // Increment amount when pressing on the track?  ;
        //scrollbar.trackLayoutMode = ScrollBar.TRACK_LAYOUT_MODE_SINGLE;
        //scrollbar.direction = ScrollBar.DIRECTION_VERTICAL;
        ///*scrollbar.addEventListener(Event.CHANGE, function onChange(event:Event):void
        //{
        //const target:IScrollBar = event.currentTarget as IScrollBar;
        //const ratio:Number = target.value;
        //});*/
        //
        //return scrollbar;
    //}
    //
	// TODO: uncomment once layouts are redesigned
    //public static function layoutInList(displayObjects : Array<DisplayObject>,
            //itemWidth : Float,
            //itemHeight : Float,
            //viewportWidth : Float,
            //viewportHeight : Float,
            //yOffset : Float,
            //gap : Float = 10) : Void
    //{
        //var viewportBounds : ViewPortBounds = new ViewPortBounds();
        //viewportBounds.explicitHeight = viewportHeight;
        //viewportBounds.explicitWidth = viewportWidth;
        //viewportBounds.y = yOffset;
        //
        //var verticalLayout : VerticalLayout = new VerticalLayout();
        //verticalLayout.typicalItemHeight = itemHeight;
        //verticalLayout.typicalItemWidth = itemWidth;
        //verticalLayout.padding = 0;
        //verticalLayout.gap = gap;
        //verticalLayout.horizontalAlign = VerticalLayout.HORIZONTAL_ALIGN_CENTER;
        //verticalLayout.verticalAlign = VerticalLayout.VERTICAL_ALIGN_MIDDLE;
        //verticalLayout.useVirtualLayout = false;
        //verticalLayout.layout(displayObjects, viewportBounds);
    //}

    public function new()
    {
    }
}
