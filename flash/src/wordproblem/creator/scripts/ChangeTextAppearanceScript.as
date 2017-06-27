package wordproblem.creator.scripts
{
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
    public class ChangeTextAppearanceScript extends BaseProblemCreateScript
    {
        private var m_currentBackground:Image;
        private var m_currentBackgroundName:String;
        private var m_barModelDrawer:BarModelTypeDrawer;
        
        public function ChangeTextAppearanceScript(createState:WordProblemCreateState,
                                                   assetManager:AssetManager,
                                                   id:String=null, 
                                                   isActive:Boolean=true)
        {
            super(createState, assetManager, id, isActive);
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            m_barModelDrawer = new BarModelTypeDrawer();
            
            var backgroundPicker:ScrollOptionsPicker = m_createState.getWidgetFromId("backgroundPicker") as ScrollOptionsPicker;
            
            var backgroundStyleData:BarModelBackgroundToStyle = new BarModelBackgroundToStyle();
            var backgroundIds:Vector.<String> = backgroundStyleData.getAllBackgroundIds();
            var backgroundOptions:Vector.<Object> = new Vector.<Object>();
            for each (var backgroundId:String in backgroundIds)
            {
                // TODO: The location of the background image may not always need to be relative
                var textStyle:Object = backgroundStyleData.getTextStyleFromId(backgroundId);
                var highlightColors:Object = backgroundStyleData.getHighlightColorsFromId(backgroundId);
                backgroundOptions.push({
                    text: backgroundId,
                    url: "../assets/level_images/" + backgroundStyleData.getBackgroundNameFromId(backgroundId) + ".jpg",
                    fontName: textStyle.fontName,
                    fontColor: parseInt(textStyle.color, 16),
                    highlightColors: highlightColors
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
        
        private function onBackgroundChange(index:int, item:Object):void
        {
            if (m_currentBackground != null)
            {
                m_currentBackground.removeFromParent(true);
                m_assetManager.removeTexture(m_currentBackgroundName, true);
            }
            
            // The unique name of the background image is just the entire url
            var url:String = item.url;
            
            // Asset manager either needs to load the new image or
            // fetch a copy of the texture
            var backgroundTexture:Texture = m_assetManager.getTexture(url);
            if (backgroundTexture == null)
            {
                var bitmapDataForBackground:BitmapData = m_assetManager.getBitmapData(url);
                if (bitmapDataForBackground != null)
                {
                    m_assetManager.addTexture(url, Texture.fromBitmapData(bitmapDataForBackground));
                    createBackgroundImage(url);
                }
                else
                {
                    m_assetManager.enqueueWithName(url, url);
                    m_assetManager.loadQueue(function(ratio:Number):void
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
            }
            
            // Change the text style to match the new background
            var editableTextArea:EditableTextArea = m_createState.getWidgetFromId("editableTextArea") as EditableTextArea;
            var currentFormat:TextFormat = editableTextArea.getTextFormat();
            editableTextArea.setTextFormatProperties(item.fontColor, currentFormat.size as int, item.fontName);
            
            // The example text also needs to be updated
            var exampleTextArea:EditableTextArea = m_createState.getWidgetFromId("exampleTextArea") as EditableTextArea;
            if (exampleTextArea != null)
            {
                exampleTextArea.setTextFormatProperties(item.fontColor, currentFormat.size as int, item.fontName);
            }
            
            // To get the text to change colors need to alter the highlight objects
            var activeHighlightObjects:Object = editableTextArea.getHighlightTextObjects();
            var newHighlightColors:Object = item.highlightColors;
            for (var highlightId:String in activeHighlightObjects)
            {
                if (newHighlightColors.hasOwnProperty(highlightId))
                {
                    activeHighlightObjects[highlightId].color = newHighlightColors[highlightId];
                }
            }
            editableTextArea.redrawHighlightsAtCurrentIndices();
            
            // Changing the background might also force a change to both the colors in the bar model
            // and the highlights in the text
            m_createState.getCurrentLevel().currentlySelectedBackgroundData = item;
            m_createState.dispatchEventWith(ProblemCreateEvent.BACKGROUND_AND_STYLES_CHANGED);
            
        }
        
        private function createBackgroundImage(name:String):void
        {
            m_currentBackground = new Image(m_assetManager.getTexture(name));
            m_createState.addChildAt(m_currentBackground, 0);
            m_currentBackgroundName = name;
        }
            
    }
}