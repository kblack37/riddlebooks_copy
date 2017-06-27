package wordproblem.hints.scripts
{
    import flash.geom.Rectangle;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    
    import dragonbox.common.util.XColor;
    
    import feathers.controls.Button;
    import feathers.controls.ToggleButton;
    import feathers.core.ToggleGroup;
    import feathers.display.Scale9Image;
    import feathers.textures.Scale9Textures;
    
    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.textures.Texture;
    
    import wordproblem.display.Layer;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.level.LevelRules;
    import wordproblem.engine.scripting.graph.ScriptNode;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.text.GameFonts;
    import wordproblem.engine.widget.WidgetUtil;
    import wordproblem.hints.BasicTextInViewerHint;
    import wordproblem.hints.HintScript;
    import wordproblem.player.ButtonColorData;
    import wordproblem.resource.AssetManager;
    
    /**
     * The main ui component shows to the player all the help options available to them
     * during the current level.
     */
    public class HelpScreenViewer extends ScriptNode
    {
        /**
         * Dismiss the screen without doing anything
         */
        private var m_closeButton:Button;
        
        /**
         * The primary container in which to paste the screen on top of
         */
        private var m_parentCanvas:DisplayObjectContainer;
        
        /**
         * The main screen display container.
         */
        private var m_mainLayer:Layer;
        
        /**
         * This is the main body drawing area for the content of this screen.
         * (draw the hints list and the control description list in here)
         */
        private var m_contentCanvas:DisplayObjectContainer;
        
        /**
         * This has the logic to draw each specific hint and controls the clicks in the
         * ui at a lower level.
         */
        private var m_hintViewer:HintsViewer;
        
        /**
         * Callback when we want to close this screen
         * 
         * No params in signature
         */
        private var m_onCloseCallback:Function;
        
        /**
         * The categories of help options available for viewing.
         */
        private var m_categoryButtons:Vector.<Button>;
        private var m_categoryToggleGroup:ToggleGroup;
        private var m_helpCategoryScripts:Vector.<IShowableScript>;
        private var m_currentlyShownScript:IShowableScript;
        
        public function HelpScreenViewer(gameEngine:IGameEngine,
                                         assetManager:AssetManager,
                                         availableHints:Vector.<HintScript>,
                                         parentCanvas:DisplayObjectContainer,
                                         onCloseCallback:Function, 
                                         buttonColorData:ButtonColorData,
                                         id:String=null)
        {
            super(id);
            m_parentCanvas = parentCanvas;
            m_mainLayer = new Layer();
            
            var totalWidth:Number = 800;
            var totalHeight:Number = 600;
            var disablingQuad:Quad = new Quad(totalWidth, totalHeight, 0);
            disablingQuad.alpha = 0.6;
            m_mainLayer.addChild(disablingQuad);
            
            var screenLayer:Sprite = new Sprite();
            var screenWidth:Number = totalWidth - 100;
            var screenHeight:Number = totalHeight - 70;
            var backgroundImage:Image = new Image(assetManager.getTexture("summary_background"));
            backgroundImage.width = screenWidth;
            backgroundImage.height = screenHeight;
            screenLayer.addChild(backgroundImage);
            
            // Have a distinctation in the help between hints vs tips, they are separate tabs.
            // Hints are supposed to be directly related to helping the player solve the specific level
            // they are on.
            // Tips are general help topics applicable to any situation (for example showing the gesture to
            // perform subtraction is a tip, while telling them what should be subtracted is a hint)
            var buttonLabels:Vector.<String> = Vector.<String>(["Tips", "Controls"]);
            var numButtons:int = buttonLabels.length;
            m_categoryButtons = new Vector.<Button>();
            var whiteButtonTexture:Texture = assetManager.getTexture("button_white");
            var whiteScale9Texture:Scale9Textures = new Scale9Textures(whiteButtonTexture, new Rectangle(8, 8, 16, 16));
            var i:int;
            var fontSize:int = 20;
            var categoryButtonWidth:Number = 170;
            var categoryButtonHeight:Number = 40;
            var padding:Number = 50;
            m_categoryToggleGroup = new ToggleGroup();
            m_categoryToggleGroup.isSelectionRequired = true;
            var totalButtonWidth:Number = (numButtons - 1) * padding + numButtons * categoryButtonWidth;
            var xOffset:Number = (screenWidth - totalButtonWidth) * 0.5;
            for (i = 0; i < numButtons; i++)
            {
                var categoryToggleButton:ToggleButton = WidgetUtil.createGenericColoredButton(
                    assetManager, 
                    buttonColorData.getUpButtonColor(),
                    buttonLabels[i], 
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, fontSize, 0xFFFFFF),
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, fontSize, 0xFFFFFF),
                    true
                ) as ToggleButton;
                categoryToggleButton.isToggle = true;
                m_categoryButtons.push(categoryToggleButton);
                
                // Set a selection skin
                var defaultSelectedImage:Scale9Image = new Scale9Image(whiteScale9Texture);
                defaultSelectedImage.color = XColor.shadeColor(buttonColorData.getUpButtonColor(), 1.0);
                categoryToggleButton.defaultSelectedSkin = defaultSelectedImage;
                categoryToggleButton.defaultSelectedLabelProperties = {textFormat:new TextFormat(GameFonts.DEFAULT_FONT_NAME, fontSize, 0x000000, null, null, null, null, null, TextFormatAlign.CENTER)};
                categoryToggleButton.width = categoryButtonWidth;
                categoryToggleButton.height = categoryButtonHeight;
                screenLayer.addChild(categoryToggleButton);
                categoryToggleButton.x = xOffset;
                xOffset += categoryButtonWidth + padding;
                
                m_categoryToggleGroup.addItem(categoryToggleButton);
                
                // HACK: Bind the listener AFTER the item is added
                // We do not want to trigger the toggle change event at this moment
                categoryToggleButton.addEventListener(Event.CHANGE, onCategorySelected);
            }
            
            var closeWidth:Number = 80;
            var closeIconTexture:Texture = assetManager.getTexture("wrong");
            var closeIcon:Image = new Image(closeIconTexture);
            m_closeButton = new Button();
            m_closeButton.defaultSkin = closeIcon;
            m_closeButton.defaultIcon = closeIcon;
            m_closeButton.scaleWhenHovering = 1.2;
            m_closeButton.scaleWhenDown = 0.8;
            m_closeButton.width = m_closeButton.height = closeWidth;
            m_closeButton.addEventListener(Event.TRIGGERED, onCloseClicked);
            // The button needs to be positioned such that the edges just slightly touch the wooden border of the
            // screen (need to hardcode the width of the borders)
            var woodBorderThickness:Number = 27;
            m_closeButton.x = screenWidth - closeWidth - woodBorderThickness;
            m_closeButton.y = woodBorderThickness;
            screenLayer.addChild(m_closeButton);
            
            screenLayer.x = (totalWidth - screenWidth) * 0.5;
            screenLayer.y = (totalHeight - screenHeight) * 0.5;
            m_mainLayer.addChild(screenLayer);
            
            m_onCloseCallback = onCloseCallback;
            
            m_contentCanvas = new Sprite();
            m_contentCanvas.y = 70;
            screenLayer.addChild(m_contentCanvas);
            
            // Adding help info that would be useful for everything
            var levelGoals:HintScript = new BasicTextInViewerHint("Goals", "Some problems have extra goals that you can accomplish" +
                " by making as few mistakes as possible and by not using too many hints. Achieving enough of them will unlock more challenging problems." +
                " Don't worry if you can't get them on the first try, there are lots of problems to practice!", true);
            availableHints.push(levelGoals);
            
            var brainPointsHint:HintScript = new BasicTextInViewerHint("Brain Points", "Finish problems to get Brain Points. " +
                "Get enough of them to level up and earn new rewards! Harder problems will give you more. You will also get " +
                "some while you are building your answers!", true);
            availableHints.push(brainPointsHint);
            
            var coinsHint:HintScript = new BasicTextInViewerHint("Coins", "Finish problems and leveling up with Brain Points will give you coins. " +
                "To spend them, go to \"My Collection\" in the main menu and pick the \"Customize\" option.", true);
            availableHints.push(coinsHint);
            
            // The ordering of these scripts MUST match the ordering of the button names
            m_helpCategoryScripts = new Vector.<IShowableScript>();
            m_helpCategoryScripts.push(new HintsViewer(gameEngine, assetManager, availableHints, screenWidth, screenHeight, m_contentCanvas, buttonColorData));
            
            // HACK: We assume that a level has already been fully set up at this point,
            // so the rules and level data are all okay to read
            // Available tips depends on what rules are available for the given level
            var availableTipNames:Vector.<String> = Vector.<String>([
                TipsViewer.NAME_A_BOX,
                TipsViewer.NAME_MANY_BOXES, 
                TipsViewer.ADD_BOX_NEW_LINE,
                TipsViewer.REMOVE_BAR_SEGMENT
            ]);
            
            var levelRules:LevelRules = gameEngine.getCurrentLevel().getLevelRules();
            if (levelRules.allowAddBarComparison)
            {
                availableTipNames.push(TipsViewer.SUBTRACT_WITH_BOXES);
            }
            
            if (levelRules.allowAddVerticalLabels)
            {
                availableTipNames.push(TipsViewer.NAME_MANY_BOXES_LINES);
            }
            
            if (levelRules.allowAddUnitBar)
            {
                availableTipNames.push(TipsViewer.MULTIPLY_WITH_BOXES);
            }
            
            if (levelRules.allowSplitBar)
            {
                availableTipNames.push(TipsViewer.DIVIDE_A_BOX);
            }
            
            if (levelRules.allowCopyBar)
            {
                availableTipNames.push(TipsViewer.HOLD_TO_COPY);
            }
            
            if (levelRules.allowResizeBrackets)
            {
                availableTipNames.push(TipsViewer.RESIZE_LABEL);
            }
            
            if (levelRules.allowSubtract || levelRules.allowMultiply)
            {
                availableTipNames.push(TipsViewer.CYCLE_OPERATOR);
            }
            
            if (levelRules.allowDivide)
            {
                availableTipNames.push(TipsViewer.DIVIDE_EXPRESSION);
            }
            
            if (levelRules.allowParenthesis)
            {
                availableTipNames.push(TipsViewer.ADD_PARENTHESIS, TipsViewer.CHANGE_REMOVE_PARENTHESIS);
            }
            
            m_helpCategoryScripts.push(new TipsViewer(m_contentCanvas, assetManager, buttonColorData, availableTipNames, screenWidth, screenHeight));
        }
        
        public function show():void
        {
            m_parentCanvas.addChild(m_mainLayer);
            
            // First time hint opens, show the hints automatically
            if (m_categoryToggleGroup.selectedIndex < 0)
            {
                m_categoryToggleGroup.selectedIndex = 0;
            }
            else
            {
                var scriptToShow:IShowableScript = m_helpCategoryScripts[m_categoryToggleGroup.selectedIndex];
                scriptToShow.show();
                m_currentlyShownScript = scriptToShow;
                
                // Make sure close button is not obscured by the layers
                m_closeButton.parent.addChild(m_closeButton);
            }
        }
        
        public function hide():void
        {
            m_mainLayer.removeFromParent();
            
            if (m_categoryToggleGroup.selectedIndex >= 0)
            {
                var scriptToHide:IShowableScript = m_helpCategoryScripts[m_categoryToggleGroup.selectedIndex];
                scriptToHide.hide();
            }
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_closeButton.removeEventListener(Event.TRIGGERED, onCloseClicked);
            
            for each (var categoryButton:Button in m_categoryButtons)
            {
                categoryButton.removeEventListeners();
                categoryButton.removeFromParent(true);
            }
            
            for each (var helpCategoryScript:IShowableScript in m_helpCategoryScripts)
            {
                if (helpCategoryScript is ScriptNode)
                {
                    (helpCategoryScript as ScriptNode).dispose();
                }
            }
        }
        
        override public function visit():int
        {
            // Run visit on the currently active screen
            var currentlySelectedScreenIndex:int = m_categoryToggleGroup.selectedIndex;
            if (currentlySelectedScreenIndex >= 0)
            {
                (m_helpCategoryScripts[currentlySelectedScreenIndex] as ScriptNode).visit();
            }
            
            return ScriptStatus.SUCCESS;
        }
        
        private function onCloseClicked():void
        {
            if (m_onCloseCallback != null)
            {
                m_onCloseCallback();
            }
        }
        
        private function onCategorySelected(event:Event):void
        {
            // Do not show script again if it is already currently showing
            
            var targetButton:ToggleButton = event.currentTarget as ToggleButton;
            var buttonIndex:int = m_categoryToggleGroup.getItemIndex(targetButton);
            var scriptAtIndex:IShowableScript = m_helpCategoryScripts[buttonIndex];
            if (targetButton.isSelected)
            {
                if (m_currentlyShownScript != scriptAtIndex)
                {
                    scriptAtIndex.show();
                    m_currentlyShownScript = scriptAtIndex;
                }
            }
            else
            {
                scriptAtIndex.hide();
            }
        }
    }
}