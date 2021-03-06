package wordproblem.hints.scripts
{
    import flash.geom.Rectangle;
    import flash.text.TextFormat;
    
    import cgs.Audio.Audio;
    
    import dragonbox.common.time.Time;
    import dragonbox.common.ui.MouseState;
    import dragonbox.common.util.ListUtil;
    
    import feathers.controls.Button;
    
    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    import starling.events.Event;
    import starling.text.TextField;
    import starling.textures.Texture;
    
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.expression.SymbolData;
    import wordproblem.engine.level.CardAttributes;
    import wordproblem.engine.scripting.graph.ScriptNode;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.text.GameFonts;
    import wordproblem.engine.widget.WidgetUtil;
    import wordproblem.hints.tips.AddNewBarComparisonTip;
    import wordproblem.hints.tips.AddNewBarTip;
    import wordproblem.hints.tips.AddNewHorizontalLabelTip;
    import wordproblem.hints.tips.AddNewLabelOnSegmentTip;
    import wordproblem.hints.tips.AddNewUnitBarTip;
    import wordproblem.hints.tips.AddNewVerticalLabelTip;
    import wordproblem.hints.tips.AddParenthesisTip;
    import wordproblem.hints.tips.ChangeAndRemoveParenthesisTip;
    import wordproblem.hints.tips.CycleOperatorTip;
    import wordproblem.hints.tips.DivideExpressionTip;
    import wordproblem.hints.tips.HoldToCopyTip;
    import wordproblem.hints.tips.RemoveBarSegmentTip;
    import wordproblem.hints.tips.ResizeHorizontalBarLabelTip;
    import wordproblem.hints.tips.SplitBarSegmentTip;
    import wordproblem.player.ButtonColorData;
    import wordproblem.resource.AssetManager;
    
    public class TipsViewer extends ScriptNode implements IShowableScript
    {
        public static const SUBTRACT_WITH_BOXES:String = "Subtract Boxes";
        public static const MULTIPLY_WITH_BOXES:String = "Multiply Boxes";
        public static const DIVIDE_A_BOX:String = "Divide a Box";
        public static const NAME_A_BOX:String = "Name a Box";
        public static const NAME_MANY_BOXES:String = "Name Many Boxes I";
        public static const NAME_MANY_BOXES_LINES:String = "Name Many Boxes II";
        public static const RESIZE_LABEL:String = "Resize Name";
        public static const ADD_BOX_NEW_LINE:String = "Add New Box";
        public static const REMOVE_BAR_SEGMENT:String = "Remove Box";
        public static const HOLD_TO_COPY:String = "Copy Box/Name";
        public static const CYCLE_OPERATOR:String = "Change Operator";
        public static const DIVIDE_EXPRESSION:String = "Division Operator";
        public static const ADD_PARENTHESIS:String = "Add Parenthesis";
        public static const CHANGE_REMOVE_PARENTHESIS:String = "Change/Remove Parenthesis";
        
        private var m_screenWidth:Number;
        private var m_screenHeight:Number;
        
        private var m_canvasContainer:DisplayObjectContainer;
        private var m_assetManager:AssetManager;
        private var m_buttonColorData:ButtonColorData;
        private var m_backButton:Button;
        
        private var m_tipsTitle:TextField;
        
        /**
         * Button to go to the previous page of content
         */
        protected var m_scrollLeftButton:Button;
        
        /**
         * Button to go to the next page of content
         */
        protected var m_scrollRightButton:Button;
        
        /**
         * Some text at the bottom of the screen showing the user the page number the player is on
         */
        private var m_pageIndicatorText:TextField;
        
        /**
         * The name of the tip as it appears on the button
         */
        private var m_names:Vector.<String>;
        
        private var m_namesPerPage:Vector.<Vector.<String>>;
        
        /**
         * All the tip buttons that are currently shown
         */
        private var m_activeNamesButtonsForPage:Vector.<Button>;
        
        /**
         * Current index of pages of tip names, each page has a list of tips the user can
         * select to view more details about that tip.
         */
        private var m_currentPageIndex:int;
        
        /**
         * The logic to render a tip, index should match up with the names list
         */
        private var m_tipScripts:Vector.<IShowableScript>;
        
        /**
         * The tip animation that is currently playing.
         */
        private var m_activeTipScript:IShowableScript;
        
        /**
         * Each tip animation may need of a dummy mouse controller to simulate dragging and
         * clicking.
         */
        private var m_simulatedMouseState:MouseState;
        
        private var m_simulatedTimer:Time;
        
        public function TipsViewer(canvasContainer:DisplayObjectContainer,
                                   assetManager:AssetManager,
                                   buttonColorData:ButtonColorData,
                                   names:Vector.<String>,
                                   screenWidth:Number,
                                   screenHeight:Number,
                                   id:String=null, 
                                   isActive:Boolean=true)
        {
            super(id, isActive);
            
            m_canvasContainer = canvasContainer;
            m_assetManager = assetManager;
            m_buttonColorData = buttonColorData;
            m_names = names;
            m_screenWidth = screenWidth;
            m_screenHeight = screenHeight;
            m_namesPerPage = new Vector.<Vector.<String>>();
            m_activeNamesButtonsForPage = new Vector.<Button>();
            
            // Much like the item collection screen, we can paginate all the names of the tips
            // Can do that here since they don't change after construction
            ListUtil.subdivideList(names, 4, m_namesPerPage);
            
            m_tipsTitle = new TextField(screenWidth, 60, "How to...", GameFonts.DEFAULT_FONT_NAME, 24, 0xFFFFFF);
            
            // Create the back button to return from the script view to the tip names view
            var arrowRotateTexture:Texture = m_assetManager.getTexture("arrow_rotate");
            var scaleFactor:Number = 0.65;
            var backUpImage:Image = new Image(arrowRotateTexture);
            backUpImage.color = 0xFBB03B;
            backUpImage.scaleX = backUpImage.scaleY = scaleFactor;
            var backOverImage:Image = new Image(arrowRotateTexture);
            backOverImage.color = 0xFDDDAC;
            backOverImage.scaleX = backOverImage.scaleY = scaleFactor;
            m_backButton = WidgetUtil.createButtonFromImages(
                backUpImage,
                backOverImage,
                null,
                backOverImage,
                null,
                null
            );
            m_backButton.scaleWhenDown = 0.9;
            m_backButton.scaleWhenHovering = 1.1;
            
            // The custom mouse controls do not bind to any events, code in the script
            // will manipulate the properties directly.
            m_simulatedMouseState = new MouseState(null, null);
            
            m_simulatedTimer = new Time();
            
            var expressionSymbolMap:ExpressionSymbolMap = new ExpressionSymbolMap(assetManager);
            expressionSymbolMap.setConfiguration(CardAttributes.DEFAULT_CARD_ATTRIBUTES);
            expressionSymbolMap.bindSymbolsToAtlas(Vector.<SymbolData>([]));
            
            // The scripts for the tips should just be created here since the tips view has all
            // of the important objects
            m_tipScripts = new Vector.<IShowableScript>();
            var screenBounds:Rectangle = new Rectangle(0, 0, screenWidth, screenHeight);
            for each (var tipName:String in names)
            {
                var tipScript:IShowableScript = TipsViewer.getTipScriptFromName(tipName, expressionSymbolMap, canvasContainer, 
                    m_simulatedMouseState, m_simulatedTimer, assetManager, screenBounds);
                m_tipScripts.push(tipScript);
            }
            
            var arrowTexture:Texture = assetManager.getTexture("arrow_short");
            scaleFactor = 1.5;
            var leftUpImage:Image = WidgetUtil.createPointingArrow(arrowTexture, true, scaleFactor);
            var leftOverImage:Image = WidgetUtil.createPointingArrow(arrowTexture, true, scaleFactor, 0xCCCCCC);
            
            m_scrollLeftButton = WidgetUtil.createButtonFromImages(
                leftUpImage,
                leftOverImage,
                null,
                leftOverImage,
                null,
                null,
                null
            );
            m_scrollLeftButton.x = 0;
            m_scrollLeftButton.y = 200;
            m_scrollLeftButton.scaleWhenDown = 0.9;
            
            var rightUpImage:Image = WidgetUtil.createPointingArrow(arrowTexture, false, scaleFactor, 0xFFFFFF);
            var rightOverImage:Image = WidgetUtil.createPointingArrow(arrowTexture, false, scaleFactor, 0xCCCCCC);
            m_scrollRightButton = WidgetUtil.createButtonFromImages(
                rightUpImage,
                rightOverImage,
                null,
                rightOverImage,
                null,
                null,
                null
            );
            m_scrollRightButton.x = screenWidth - rightUpImage.width;
            m_scrollRightButton.y = m_scrollLeftButton.y;
            m_scrollRightButton.scaleWhenDown = m_scrollLeftButton.scaleWhenDown;
            
            m_pageIndicatorText = new TextField(screenWidth, 80, "ffff", GameFonts.DEFAULT_FONT_NAME, 24, 0xFFFFFF);
            m_pageIndicatorText.x = 0;
            m_pageIndicatorText.y = screenHeight - m_pageIndicatorText.height * 2;
        }
        
        public static function getTipScriptFromName(tipName:String, 
                                                    expressionSymbolMap:ExpressionSymbolMap, 
                                                    canvasContainer:DisplayObjectContainer, 
                                                    simulatedMouseState:MouseState, 
                                                    simulatedTimer:Time, 
                                                    assetManager:AssetManager, 
                                                    screenBounds:Rectangle):IShowableScript
        {
            var tipScript:IShowableScript;
            if (tipName == TipsViewer.SUBTRACT_WITH_BOXES)
            {
                tipScript = new AddNewBarComparisonTip(expressionSymbolMap, canvasContainer, simulatedMouseState, simulatedTimer, assetManager, screenBounds, tipName);
            }
            else if (tipName == TipsViewer.DIVIDE_A_BOX)
            {
                tipScript = new SplitBarSegmentTip(expressionSymbolMap, canvasContainer, simulatedMouseState, simulatedTimer, assetManager, screenBounds, tipName);
            }
            else if (tipName == TipsViewer.MULTIPLY_WITH_BOXES)
            {
                tipScript = new AddNewUnitBarTip(expressionSymbolMap, canvasContainer, simulatedMouseState, simulatedTimer, assetManager, screenBounds, tipName);
            }
            else if (tipName == TipsViewer.ADD_BOX_NEW_LINE)
            {
                tipScript = new AddNewBarTip(expressionSymbolMap, canvasContainer, simulatedMouseState, simulatedTimer, assetManager, screenBounds, tipName);
            }
            else if (tipName == TipsViewer.NAME_A_BOX)
            {
                tipScript = new AddNewLabelOnSegmentTip(expressionSymbolMap, canvasContainer, simulatedMouseState, simulatedTimer, assetManager, screenBounds, tipName);
            }
            else if (tipName == TipsViewer.NAME_MANY_BOXES)
            {
                tipScript = new AddNewHorizontalLabelTip(expressionSymbolMap, canvasContainer, simulatedMouseState, simulatedTimer, assetManager, screenBounds, tipName);
            }
            else if (tipName == TipsViewer.NAME_MANY_BOXES_LINES)
            {
                tipScript = new AddNewVerticalLabelTip(expressionSymbolMap, canvasContainer, simulatedMouseState, simulatedTimer, assetManager, screenBounds, tipName);
            }
            else if (tipName == TipsViewer.REMOVE_BAR_SEGMENT)
            {
                tipScript = new RemoveBarSegmentTip(expressionSymbolMap, canvasContainer, simulatedMouseState, simulatedTimer, assetManager, screenBounds, tipName);
            }
            else if (tipName == TipsViewer.RESIZE_LABEL)
            {
                tipScript = new ResizeHorizontalBarLabelTip(expressionSymbolMap, canvasContainer, simulatedMouseState, simulatedTimer, assetManager, screenBounds, tipName);
            }
            else if (tipName == TipsViewer.CYCLE_OPERATOR)
            {
                tipScript = new CycleOperatorTip(expressionSymbolMap, canvasContainer, simulatedMouseState, simulatedTimer, assetManager, screenBounds, tipName);
            }
            else if (tipName == TipsViewer.DIVIDE_EXPRESSION)
            {
                tipScript = new DivideExpressionTip(expressionSymbolMap, canvasContainer, simulatedMouseState, simulatedTimer, assetManager, screenBounds, tipName);
            }
            else if (tipName == TipsViewer.ADD_PARENTHESIS)
            {
                tipScript = new AddParenthesisTip(expressionSymbolMap, canvasContainer, simulatedMouseState, simulatedTimer, assetManager, screenBounds, tipName);
            }
            else if (tipName == TipsViewer.CHANGE_REMOVE_PARENTHESIS)
            {
                tipScript = new ChangeAndRemoveParenthesisTip(expressionSymbolMap, canvasContainer, simulatedMouseState, simulatedTimer, assetManager, screenBounds, tipName);
            }
            else if (tipName == TipsViewer.HOLD_TO_COPY)
            {
                tipScript = new HoldToCopyTip(expressionSymbolMap, canvasContainer, simulatedMouseState, simulatedTimer, assetManager, screenBounds, tipName);
            }
            
            return tipScript;
        }
        
        override public function visit():int
        {
            m_simulatedTimer.update();
            if (m_activeTipScript != null)
            {
                (m_activeTipScript as ScriptNode).visit();
            }
            
            return ScriptStatus.SUCCESS;
        }
        
        public function show():void
        {
            // Always start of with the list of tips
            changeToNamesView();
            
            m_backButton.addEventListener(Event.TRIGGERED, onBackClicked);
            
            m_scrollLeftButton.addEventListener(Event.TRIGGERED, onScrollLeftButtonClicked);
            m_scrollRightButton.addEventListener(Event.TRIGGERED, onScrollRightButtonClicked);
        }
        
        public function hide():void
        {
            // Remove whatever view or script is visible
            hideNamesView();
            hideScriptsView();
            
            m_backButton.removeEventListener(Event.TRIGGERED, onBackClicked);
            
            m_scrollLeftButton.removeEventListener(Event.TRIGGERED, onScrollLeftButtonClicked);
            m_scrollRightButton.removeEventListener(Event.TRIGGERED, onScrollRightButtonClicked);
        }
        
        override public function dispose():void
        {
            super.dispose();
            hide();
            
            for each (var tipScript:IShowableScript in m_tipScripts)
            {
                (tipScript as ScriptNode).dispose();
            }
        }
        
        /**
         * Show the list of names of possible tips the player can see.
         */
        private function changeToNamesView():void
        {
            // On show, redraw all the tips on the current page
            drawTipButtonsForPage(m_currentPageIndex);
            
            m_canvasContainer.addChild(m_tipsTitle);
            showPageIndicator(m_currentPageIndex + 1, m_namesPerPage.length);
            
            showScrollButtons(m_namesPerPage.length > 1);
                
        }
        
        private function hideNamesView():void
        {
            // Clean up all of the buttons for the names.
            for each (var tipButton:Button in m_activeNamesButtonsForPage)
            {
                tipButton.removeEventListeners();
                tipButton.removeFromParent(true);
            }
            
            m_pageIndicatorText.removeFromParent();
            m_tipsTitle.removeFromParent();
            
            showScrollButtons(false);
        }
        
        private function drawTipButtonsForPage(pageIndex:int):void
        {
            var buttonWidth:Number = 350;
            var buttonHeight:Number = 50;
            
            // NOTE: columns * row must be less than or equal to number of items
            // per page.
            var columns:int = 1;
            var rows:int = 4;
            
            var namesInCurrentPage:Vector.<String> = m_namesPerPage[m_currentPageIndex];
            var i:int;
            var namesInPage:int = namesInCurrentPage.length;
            var yOffset:Number = 50;
            var calculatedHorizontalGap:Number = (m_screenWidth - columns * buttonWidth) / (columns + 1);
            var calculatedVerticalGap:Number = ((m_screenHeight - 170) - rows * buttonHeight) / (rows + 1);
            for (i = 0; i < namesInPage; i++)
            {
                var name:String = namesInCurrentPage[i];
                
                // Button appearance will differ if the item was already purchased or if it is currently equipped.
                // The logic to change this is all baked inside the button class
                var tipButton:Button = WidgetUtil.createGenericColoredButton(
                    m_assetManager, 
                    m_buttonColorData.getUpButtonColor(),
                    name, new TextFormat(GameFonts.DEFAULT_FONT_NAME, 24, 0xFFFFFF)
                );
                tipButton.width = buttonWidth;
                tipButton.height = buttonHeight;
                tipButton.addEventListener(Event.TRIGGERED, onTipButtonClicked);
                
                var rowIndex:int = i / columns;
                var columnIndex:int = i % columns;
                tipButton.x = columnIndex * buttonWidth + calculatedHorizontalGap * (columnIndex + 1);
                tipButton.y = rowIndex * buttonHeight + calculatedVerticalGap * (rowIndex + 1) + yOffset;
                
                m_canvasContainer.addChild(tipButton);
                m_activeNamesButtonsForPage.push(tipButton);
            }
        }
        
        private function onTipButtonClicked(event:Event):void
        {
            // The index of the tip name that was selected will map us to the correct
            // tip script that needs to be executed
            var targetButton:Button = event.currentTarget as Button;
            changeToScriptsView(targetButton.label);
        }
        
        private function changeToScriptsView(tipName:String):void
        {
            hideNamesView();
            
            // Find the tip script that matches the name and then execute it
            var tipNameIndex:int = m_names.indexOf(tipName);
            var tipScript:IShowableScript = m_tipScripts[tipNameIndex];
            tipScript.show();
            m_activeTipScript = tipScript;
            
            // Add the back button (the canvas is offset slightly down from the border, we want the
            // back button to just touch the wooden border)
            var woodenBorderThickness:Number = 33;
            m_backButton.x = woodenBorderThickness;
            m_backButton.y = -29;
            m_canvasContainer.addChild(m_backButton);
        }
        
        private function hideScriptsView():void
        {
            // Remove the back button
            m_backButton.removeFromParent();
            
            if (m_activeTipScript != null)
            {
                m_activeTipScript.hide();
                m_activeTipScript = null;
            }
        }
        
        private function onBackClicked():void
        {
            Audio.instance.playSfx("button_click");
            hideScriptsView();
            changeToNamesView();
        }
        
        private function onScrollLeftButtonClicked():void
        {
            Audio.instance.playSfx("button_click");
            m_currentPageIndex--;
            if (m_currentPageIndex < 0)
            {
                m_currentPageIndex = m_namesPerPage.length - 1;
            }
            hideNamesView();
            changeToNamesView();
        }
        
        private function onScrollRightButtonClicked():void
        {
            Audio.instance.playSfx("button_click");
            m_currentPageIndex++;
            if (m_currentPageIndex > m_namesPerPage.length - 1)
            {
                m_currentPageIndex = 0;
            }
            hideNamesView();
            changeToNamesView();
        }
        
        private function showScrollButtons(doShow:Boolean):void
        {
            if (doShow)
            {
                m_canvasContainer.addChild(m_scrollLeftButton);
                m_canvasContainer.addChild(m_scrollRightButton);
            }
            else
            {
                m_scrollLeftButton.removeFromParent();
                m_scrollRightButton.removeFromParent();
            }
        }
        
        private function showPageIndicator(currentPage:int, totalPages:int):void
        {
            m_pageIndicatorText.text = currentPage + " / " + totalPages;
            m_canvasContainer.addChild(m_pageIndicatorText);
        }
    }
}