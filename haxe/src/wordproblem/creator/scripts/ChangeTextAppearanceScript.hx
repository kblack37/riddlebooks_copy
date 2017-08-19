package wordproblem.creator.scripts;


import flash.display.BitmapData;
import flash.text.TextFormat;

import starling.display.Image;
import starling.textures.Texture;

import wordproblem.creator.EditableTextArea;
import wordproblem.creator.ProblemCreateEvent;
import wordproblem.creator.ScrollOptionsPicker;
import wordproblem.creator.WordProblemCreateState;
import wordproblem.engine.barmodel.BarModelBackgroundToStyle;
import wordproblem.engine.barmodel.BarModelTypeDrawer;
import wordproblem.resource.AssetManager;

/**
 * Script controls drawing the ui part that changes the background image and the corresponding
 * text style.
 */
class ChangeTextAppearanceScript extends BaseProblemCreateScript
{
    private var m_currentBackground : Image;
    private var m_currentBackgroundName : String;
    private var m_barModelDrawer : BarModelTypeDrawer;
    
    public function new(createState : WordProblemCreateState,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(createState, assetManager, id, isActive);
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        
        m_barModelDrawer = new BarModelTypeDrawer();
        
        var backgroundPicker : ScrollOptionsPicker = try cast(m_createState.getWidgetFromId("backgroundPicker"), ScrollOptionsPicker) catch(e:Dynamic) null;
        
        var backgroundStyleData : BarModelBackgroundToStyle = new BarModelBackgroundToStyle();
        var backgroundIds : Array<String> = backgroundStyleData.getAllBackgroundIds();
        var backgroundOptions : Array<Dynamic> = new Array<Dynamic>();
        for (backgroundId in backgroundIds)
        {
            // TODO: The location of the background image may not always need to be relative
            var textStyle : Dynamic = backgroundStyleData.getTextStyleFromId(backgroundId);
            var highlightColors : Dynamic = backgroundStyleData.getHighlightColorsFromId(backgroundId);
            backgroundOptions.push({
                        text : backgroundId,
                        url : "../assets/level_images/" + backgroundStyleData.getBackgroundNameFromId(backgroundId) + ".jpg",
                        fontName : textStyle.fontName,
                        fontColor : parseInt(textStyle.color, 16),
                        highlightColors : highlightColors,

                    });
        }
        
        backgroundPicker.setOptions(backgroundOptions);
        backgroundPicker.setOptionChangedCallback(onBackgroundChange);
        backgroundPicker.showOptionAtIndex(0);
        
        // HACK: Trying to position the picker anywhere but here (including at the startup of the level)
        // has no affect. It always just starts up at (0, 0)
        backgroundPicker.x = (800 - backgroundPicker.width) * 0.5;
        backgroundPicker.y = 600 - backgroundPicker.height;
        m_createState.addChild(backgroundPicker);
    }
    
    private function onBackgroundChange(index : Int, item : Dynamic) : Void
    {
        if (m_currentBackground != null) 
        {
            m_currentBackground.removeFromParent(true);
            m_assetManager.removeTexture(m_currentBackgroundName, true);
        }  // The unique name of the background image is just the entire url  
        
        
        
        var url : String = item.url;
        
        // Asset manager either needs to load the new image or
        // fetch a copy of the texture
        var backgroundTexture : Texture = m_assetManager.getTexture(url);
        if (backgroundTexture == null) 
        {
            var bitmapDataForBackground : BitmapData = m_assetManager.getBitmapData(url);
            if (bitmapDataForBackground != null) 
            {
                m_assetManager.addTexture(url, Texture.fromBitmapData(bitmapDataForBackground));
                createBackgroundImage(url);
            }
            else 
            {
                m_assetManager.enqueueWithName(url, url);
                m_assetManager.loadQueue(function(ratio : Float) : Void
                        {
                            if (ratio == 1.0) 
                            {
                                createBackgroundImage(url);
                            }
                        });
            }
        }
        else 
        {
            createBackgroundImage(url);
        }  // Change the text style to match the new background  
        
        
        
        var editableTextArea : EditableTextArea = try cast(m_createState.getWidgetFromId("editableTextArea"), EditableTextArea) catch(e:Dynamic) null;
        var currentFormat : TextFormat = editableTextArea.getTextFormat();
        editableTextArea.setTextFormatProperties(item.fontColor, Std.parseInt(currentFormat.size), item.fontName);
        
        // The example text also needs to be updated
        var exampleTextArea : EditableTextArea = try cast(m_createState.getWidgetFromId("exampleTextArea"), EditableTextArea) catch(e:Dynamic) null;
        if (exampleTextArea != null) 
        {
            exampleTextArea.setTextFormatProperties(item.fontColor, Std.parseInt(currentFormat.size), item.fontName);
        }  // To get the text to change colors need to alter the highlight objects  
        
        
        
        var activeHighlightObjects : Dynamic = editableTextArea.getHighlightTextObjects();
        var newHighlightColors : Dynamic = item.highlightColors;
        for (highlightId in Reflect.fields(activeHighlightObjects))
        {
            if (newHighlightColors.exists(highlightId)) 
            {
                Reflect.setField(activeHighlightObjects, highlightId, Reflect.field(newHighlightColors, highlightId)).color;
            }
        }
        editableTextArea.redrawHighlightsAtCurrentIndices();
        
        // Changing the background might also force a change to both the colors in the bar model
        // and the highlights in the text
        m_createState.getCurrentLevel().currentlySelectedBackgroundData = item;
        m_createState.dispatchEvent(ProblemCreateEvent.BACKGROUND_AND_STYLES_CHANGED);
    }
    
    private function createBackgroundImage(name : String) : Void
    {
        m_currentBackground = new Image(m_assetManager.getTexture(name));
        m_createState.addChildAt(m_currentBackground, 0);
        m_currentBackgroundName = name;
    }
}
