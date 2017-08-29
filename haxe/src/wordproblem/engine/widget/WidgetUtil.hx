package wordproblem.engine.widget;


import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import wordproblem.display.PivotSprite;
import wordproblem.display.Scale9Image;

import dragonbox.common.util.XColor;

import wordproblem.display.LabelButton;
import openfl.display.DisplayObject;
import openfl.display.Sprite;

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
            isToggle : Bool = false) : LabelButton
    {
        var scaleNineRect : Rectangle = new Rectangle(8, 8, 16, 16);
        var buttonBackground : BitmapData = assetManager.getBitmapData("button_white");
        var buttonOutline : BitmapData = assetManager.getBitmapData("button_outline_white");
        var defaultSkin : Scale9Image = new Scale9Image(buttonBackground, scaleNineRect);
        
		var compositeArray = new Array<DisplayObject>();
        var hoverBackground : Scale9Image = new Scale9Image(buttonBackground, scaleNineRect);
        var hoverOutline : Scale9Image = new Scale9Image(buttonOutline, scaleNineRect);
		compositeArray.push(hoverBackground);
		compositeArray.push(hoverOutline);
        var hoverSkin : Sprite = new Scale9CompositeImage(compositeArray);
		
		compositeArray = new Array<DisplayObject>();
        
        var downBackground : Scale9Image = new Scale9Image(buttonBackground, scaleNineRect);
        var downOutline : Scale9Image = new Scale9Image(buttonOutline, scaleNineRect);
		downOutline.transform.colorTransform = XColor.rgbToColorTransform(0x000000);
		compositeArray.push(downBackground);
		compositeArray.push(downOutline);
        var downSkin : Sprite = new Scale9CompositeImage(compositeArray);
        
        var button : LabelButton = WidgetUtil.createButtonFromImages(defaultSkin,
                downSkin, null, hoverSkin, label, textFormatDefault, textFormatHover, isToggle);
        changeColorForGenericButton(button, color);
        return button;
    }
    
    /**
     * Change the color of any button created with a call to createGenericColoredButton
     */
    public static function changeColorForGenericButton(genericButton : LabelButton, color : Int) : Void
    {
        var defaultSkin : DisplayObject = try cast(genericButton.upState, DisplayObject) catch (e:Dynamic) null;
		defaultSkin.transform.colorTransform = XColor.rgbToColorTransform(color);
        
        var hoverSkin : DisplayObject = try cast(genericButton.overState, DisplayObject) catch (e:Dynamic) null;
		hoverSkin.transform.colorTransform = XColor.rgbToColorTransform(XColor.shadeColor(color, 0.2));
        
        var downSkin : DisplayObject = try cast(genericButton.downState, DisplayObject) catch (e:Dynamic) null;
		downSkin.transform.colorTransform = XColor.rgbToColorTransform(XColor.shadeColor(color, -0.2));
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
            isToggle : Bool = false) : LabelButton
    {
		function createSkin(bitmapDataName : String, nineSlice : Rectangle) : DisplayObject
        {
            var useNineSlice : Bool = (nineSlice != null);
            var bitmapData : BitmapData = assetManager.getBitmapData(bitmapDataName);
			var skin :DisplayObject = null;
			if (nineSlice != null) {
				skin = new Scale9Image(bitmapData, nineSlice);
			} else {
				skin = new Bitmap(bitmapData);
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
            isToggle : Bool = false) : LabelButton
    {
		// TODO: uncomment once ToggleButton is designed
		// TODO: replace with a better button class; we can't add labels unless we
		// merge the skins with a text field object somewhere
        var button : LabelButton = /*((isToggle)) ? new ToggleButton() : */new LabelButton(
			defaultSkin,
			hoverSkin,
			downSkin,
			disabledSkin
		);
		
		if (label != null) button.label = label;
        
        if (textFormatDefault != null) 
        {
			button.textFormatDefault = textFormatDefault;
        }
		
		// Have an optional text format for over
        if (textFormatHover != null) 
        {
			button.textFormatHover = textFormatHover;
        }
        
        return button;
    }
    
    /**
     * Create arrow pointing left or right, used as a button skin
     */
    public static function createPointingArrow(arrowBitmapData : BitmapData,
            pointLeft : Bool,
            scaleFactor : Float,
            color : Int = 0xFFFFFF) : DisplayObject
    {
        var arrowImage : PivotSprite = new PivotSprite();
		arrowImage.addChild(new Bitmap(arrowBitmapData));
        arrowImage.scaleX = arrowImage.scaleY = scaleFactor;
        if (pointLeft) 
        {
			arrowImage.pivotX = arrowImage.width / 2;
			arrowImage.pivotY = arrowImage.height / 2;
			arrowImage.rotation = 180;
			// Have to subtract instead of add because of the rotation
			arrowImage.x -= arrowImage.width / 2;
			arrowImage.y += arrowImage.height / 2;
        }
		arrowImage.transform.colorTransform = XColor.rgbToColorTransform(color);
        return arrowImage;
    }
    
	// TODO: uncomment when scrollbars are redesigned
    //public static function createScrollbar(assetManager : AssetManager) : IScrollBar
    //{
        //var scrollbar : ScrollBar = new ScrollBar();
        //scrollbar.thumbFactory = function() : Button
                //{
                    //var thumbButton : Button = new Button();
                    //thumbButton.defaultSkin = new Image(getTexture("scrollbar_button"));
                    //thumbButton.downSkin = new Image(getTexture("scrollbar_button_click"));
                    //thumbButton.hoverSkin = new Image(getTexture("scrollbar_button_mouseover"));
                    //return thumbButton;
                //};
        //
        //scrollbar.decrementButtonFactory = function() : Button
                //{
                    //var decrementButton : Button = new Button();
                    //decrementButton.defaultSkin = new Image(getTexture("scrollbar_up"));
                    //decrementButton.downSkin = new Image(getTexture("scrollbar_up_click"));
                    //return decrementButton;
                //};
        //
        //scrollbar.incrementButtonFactory = function() : Button
                //{
                    //var incrementButton : Button = new Button();
                    //incrementButton.defaultSkin = new Image(getTexture("scrollbar_down"));
                    //incrementButton.downSkin = new Image(getTexture("scrollbar_down_click"));
                    //return incrementButton;
                //};
        //
        //scrollbar.minimumTrackFactory = function() : Button
                //{
                    //var trackButton : Button = new Button();
                    //trackButton.defaultSkin = new Image(getTexture("scrollbar_track"));
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
}
