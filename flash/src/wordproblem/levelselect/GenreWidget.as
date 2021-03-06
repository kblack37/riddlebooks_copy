package wordproblem.levelselect
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.TextFormat;
    import flash.utils.Dictionary;
    
    import cgs.Audio.Audio;
    import cgs.internationalization.StringTable;
    import cgs.levelProgression.nodes.ICgsLevelNode;
    import cgs.levelProgression.nodes.ICgsLevelPack;
    
    import dragonbox.common.ui.MouseState;
    
    import feathers.controls.Button;
    import feathers.controls.text.TextFieldTextRenderer;
    import feathers.core.ITextRenderer;
    import feathers.display.Scale9Image;
    import feathers.layout.TiledRowsLayout;
    import feathers.layout.ViewPortBounds;
    import feathers.textures.Scale9Textures;
    
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.utils.HAlign;
    
    import wordproblem.display.CurvedText;
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.ComponentManager;
    import wordproblem.engine.component.CurrentGrowInStageComponent;
    import wordproblem.engine.component.GenreIdComponent;
    import wordproblem.engine.component.HiddenItemComponent;
    import wordproblem.engine.component.ItemIdComponent;
    import wordproblem.engine.component.LevelComponent;
    import wordproblem.engine.component.LevelSelectIconComponent;
    import wordproblem.engine.component.LevelsCompletedPerStageComponent;
    import wordproblem.engine.component.TextureCollectionComponent;
    import wordproblem.engine.text.GameFonts;
    import wordproblem.engine.text.MeasuringTextField;
    import wordproblem.engine.widget.BookWidget;
    import wordproblem.engine.widget.WidgetUtil;
    import wordproblem.items.ItemDataSource;
    import wordproblem.items.ItemInventory;
    import wordproblem.level.controller.WordProblemCgsLevelManager;
    import wordproblem.level.nodes.ChapterLevelPack;
    import wordproblem.level.nodes.GenreLevelPack;
    import wordproblem.level.nodes.WordProblemLevelLeaf;
    import wordproblem.level.nodes.WordProblemLevelNode;
    import wordproblem.level.nodes.WordProblemLevelPack;
    import wordproblem.levelselect.scripts.DrawItemsOnShelves;
    import wordproblem.resource.AssetManager;
    
    /**
     * This is the primary container that appears when the user has selected a word problem
     * genre.
     * 
     * It should display information about the genre and allow the user to start playing levels related this
     * genre.
     */
    public class GenreWidget extends Sprite
    {
        /**
         * Use this to fetch textures
         */
        private var m_assetManager:AssetManager;
        
        /**
         * Contains all information of the current genre that should be displayed 
         */
        private var m_genreLevelPack:GenreLevelPack;
        
        /**
         * In the level select screen we need to be able to map the button or hit area that
         * was clicked to some identifier for the level to go to.
         */
        private var m_buttonToLevelNode:Dictionary;
        
        /**
         * The layout algorithm to use for buttons.
         */
        private var m_buttonLayout:TiledRowsLayout;
        
        /**
         * In each chapter we have a button to go to the last unplayed level
         */
        private var m_buttonToChapterNode:Dictionary;
        
        /**
         * This is a ui component that encapsulates the level selection and information relating to the genre
         * in the visual form of a book.
         * 
         * (Remember the book widget might be separate from the fixed book background, in which case we need to be careful
         * that the widget contents align with that background)
         * 
         * The 'book' will consist of content only appearing on the right side, which has all the buttons for playing a level.
         * On the left side we have a fixed description of the genre, the eggs, and the prizes present
         */
        private var m_book:BookWidget;
        
        /**
         * For each genre we have single active creature to display related for the genre.
         * When the player opens the book a fullsized image of the creature tied to that genre
         * should be visible
         */
        private var m_currentImageForGenre:DisplayObject;
        
        /**
         * The button/hit area that detects when the player wants to close this button and pick
         * another genre.
         */
        private var m_closeButton:Button;
        
        /**
         * Button when clicked will go to the next page of the book 
         */
        private var m_nextPageHitArea:Button;
        
        /**
         * Button when clicked will go to the previous page of the book
         */
        private var m_previousPageHitArea:Button;
        
        /**
         * Function to trigger when the widget should be closed
         */
        private var m_onCloseCallback:Function;
        
        /**
         * Function to trigger when the widget has detected the user wants to go to a specific level
         * 
         * Accepts one parameter (the name of the level to go to)
         */
        private var m_onStartLevelCallback:Function;
        
        /**
         * Need this to check if particular levels have a reward so we can draw a small version of the
         * icon on the level button
         */
        private var m_playerItemInventory:ItemInventory;
        
        /**
         * Need this to fetch the data to draw the reward icons on the level buttons
         */
        private var m_itemDataSource:ItemDataSource;
        
        /**
         * Mapping from node name to the level component with the matching node
         * Used just so we don't need to look through every component for every level during the redraw.
         * 
         * key: String node name
         * value: Level Component
         */
        private var m_levelNodeNameToLevelComponent:Dictionary;
        
        /**
         * A map coming from the world+chapter data source that links the world name to
         * details about that world. 
         */
        private var m_levelManager:WordProblemCgsLevelManager;
        //private var m_worldsInfo:Object;
        //private var m_chaptersInfo:Object;
        
        private const levelButtonsPerPage:int = 9;
        private const m_screenWidth:Number = 800;
        private const m_screenHeight:Number = 600;
        
        /**
         * Allow user to view and plays that are nested in a level set. Mostly
         * to allow replay of problems.
         */
        private var m_levelSetSelector:LevelSetSelector;
        
        /**
         *
         * @param onCloseCallback
         *      
         * @param onStartLevelCallback
         *      Accepts single param that is the string level name to play
         */
        public function GenreWidget(assetManager:AssetManager,
                                    levelManager:WordProblemCgsLevelManager,
                                    playerItemInventory:ItemInventory, 
                                    itemDataSource:ItemDataSource,
                                    onCloseCallback:Function, 
                                    onStartLevelCallback:Function, 
                                    homeButtonColor:uint)
        {
            super();
            
            m_assetManager = assetManager;
            m_levelManager = levelManager;
            m_playerItemInventory = playerItemInventory;
            m_itemDataSource = itemDataSource;
            
            var closeButtonHeight:Number = 60;
            var closeButtonWidth:Number = 60;
            var homeIcon:Image = new Image(m_assetManager.getTexture("home_icon"));
            var iconScaleTarget:Number = (closeButtonHeight * 0.8) / homeIcon.height;
            homeIcon.scaleX = homeIcon.scaleY = iconScaleTarget;
            m_closeButton = WidgetUtil.createGenericColoredButton(assetManager, homeButtonColor, null, null);
            m_closeButton.defaultIcon = homeIcon;
            m_closeButton.width = closeButtonWidth;
            m_closeButton.height = closeButtonHeight;
            m_closeButton.addEventListener(Event.TRIGGERED, onCloseTriggered);
            m_onCloseCallback = onCloseCallback;
            m_onStartLevelCallback = onStartLevelCallback;
            
            var arrowTexture:Texture = assetManager.getTexture("arrow_short");
            var pageChangeButtonScaleFactor:Number = 1.25;
            var leftUpImage:Image = WidgetUtil.createPointingArrow(arrowTexture, true, pageChangeButtonScaleFactor);
            var leftOverImage:Image = WidgetUtil.createPointingArrow(arrowTexture, true, pageChangeButtonScaleFactor, 0xCCCCCC);
            
            m_previousPageHitArea = WidgetUtil.createButtonFromImages(
                leftUpImage,
                leftOverImage,
                null,
                leftOverImage,
                null,
                null,
                null
            );
            m_previousPageHitArea.scaleWhenDown = 0.9;
            m_previousPageHitArea.addEventListener(Event.TRIGGERED, onPrevTriggered);
            
            var rightUpImage:Image = WidgetUtil.createPointingArrow(arrowTexture, false, pageChangeButtonScaleFactor, 0xFFFFFF);
            var rightOverImage:Image = WidgetUtil.createPointingArrow(arrowTexture, false, pageChangeButtonScaleFactor, 0xCCCCCC);
            m_nextPageHitArea = WidgetUtil.createButtonFromImages(
                rightUpImage,
                rightOverImage,
                null,
                rightOverImage,
                null,
                null,
                null
            );
            m_nextPageHitArea.scaleWhenDown = m_previousPageHitArea.scaleWhenDown;
            m_nextPageHitArea.addEventListener(Event.TRIGGERED, onNextTriggered);
            
            m_buttonLayout = new TiledRowsLayout();
            m_buttonLayout.useSquareTiles = true;
            m_buttonLayout.padding = 10;
            m_buttonLayout.verticalGap = 25;
            m_buttonLayout.horizontalGap = 25;
            m_buttonLayout.paging = TiledRowsLayout.PAGING_NONE;
            m_buttonLayout.tileHorizontalAlign = TiledRowsLayout.TILE_HORIZONTAL_ALIGN_LEFT;
            m_buttonLayout.tileVerticalAlign = TiledRowsLayout.TILE_VERTICAL_ALIGN_TOP;
            m_buttonLayout.horizontalAlign = TiledRowsLayout.HORIZONTAL_ALIGN_LEFT;
            m_buttonLayout.verticalAlign = TiledRowsLayout.VERTICAL_ALIGN_TOP;
            m_buttonLayout.useVirtualLayout = false;
            
            m_levelSetSelector = new LevelSetSelector(m_screenWidth, m_screenHeight, m_assetManager, 
                onLevelSelectedFromSelector, onDismissLevelSetSelector);
        }
        
        public function update(mouseState:MouseState):void
        {
            if (m_levelSetSelector != null && m_levelSetSelector.parent != null)
            {
                m_levelSetSelector.update(mouseState);
            }
        }
        
        override public function dispose():void
        {
            super.dispose();
            m_closeButton.removeEventListeners();
            m_previousPageHitArea.removeEventListeners();
            m_nextPageHitArea.removeEventListeners();
        }
        
        /**
         * Get back the last opened genre
         * 
         * @return
         *      null if no genre screen was last opened
         */
        public function getGenre():GenreLevelPack
        {
            return m_genreLevelPack;
        }
        
        /**
         * Set the contents of this widget to fit a particular genre.
         * 
         * @param genreLevelPack
         *      The node containing the information about the genre to play
         * @param chapterIndex
         *      The chapter index of the genre to start off in. If -1 or not valid, start at the
         *      beginning of the chapter
         * @param levelIndex
         */
        public function setGenre(genreLevelPack:GenreLevelPack, chapterIndex:int, levelIndex:int=-1):void
        {
            // Clean out level buttons
            if (m_buttonToLevelNode != null)
            {
                cleanButtonDictionary(m_buttonToLevelNode);
            }
            else
            {
                m_buttonToLevelNode = new Dictionary();
            }
            
            // Clean out the chapter buttons
            if (m_buttonToChapterNode != null)
            {
                cleanButtonDictionary(m_buttonToChapterNode);
            }
            else
            {
                m_buttonToChapterNode = new Dictionary();
            }
            
            function cleanButtonDictionary(dictionary:Dictionary):void
            {
                var dictionaryKey:Object;
                for (dictionaryKey in dictionary)
                {
                    var button:Button = dictionaryKey as Button;
                    button.removeEventListeners();
                    button.dispose();
                    delete m_buttonToLevelNode[button];
                }
            }
            
            // Remove previous egg image
            if (m_currentImageForGenre != null)
            {
                m_currentImageForGenre.removeFromParent(true);
                m_currentImageForGenre = null;
            }
            
            // Go through every level component and create a quick mapping from the level node name to the component
            // This is so we don't need to loop through every component every time we draw the level buttons
            // to see if a reward should be attached
            m_levelNodeNameToLevelComponent = new Dictionary();
            var levelComponents:Vector.<Component> = m_playerItemInventory.componentManager.getComponentListForType(LevelComponent.TYPE_ID);
            var numComponents:int = levelComponents.length;
            for (i = 0; i < numComponents; i++)
            {
                var levelComponent:LevelComponent = levelComponents[i] as LevelComponent;
                m_levelNodeNameToLevelComponent[levelComponent.levelName] = levelComponent;
            }
            
            this.closeGenre();
            m_genreLevelPack = genreLevelPack;
            
            // Pick the proper background to use from the genre data blob
            var data:Object = getLevelSelectSectionMatchingGenre(genreLevelPack.getThemeId());
            var bgImage:Image = new Image(m_assetManager.getTexture(data.levelSelectBackgroundTexture));
            addChild(bgImage);
            
            m_nextPageHitArea.x = 740;
            m_nextPageHitArea.y = 280;
            this.addChild(m_nextPageHitArea);
            m_previousPageHitArea.x = 10;
            m_previousPageHitArea.y = m_nextPageHitArea.y;
            this.addChild(m_previousPageHitArea);
            
            const book:BookWidget = new BookWidget(true)
            m_book = book;
            
            // The total number of pages required are the
            // front info page,
            // variable number of pages for levels, and
            
            // Draw each page and add it to the book, beginning with the genre description
            const pageWidth:Number = m_screenWidth * 0.5;
            var titlePage:Sprite = drawTitlePage(genreLevelPack, pageWidth);
            titlePage.x -= (pageWidth - 35);
            book.addChild(titlePage);
            
            // Need to separate out the regular level nodes and those belonging to a chapter
            // The reason is we draw the levels belonging to a chapter first and the levels
            // without a chapter are all grouped together at the end.
            // This only applies for the level select.
            var chapterNodes:Vector.<ChapterLevelPack> = new Vector.<ChapterLevelPack>();
            var levelNodesWithoutChapter:Vector.<WordProblemLevelLeaf> = new Vector.<WordProblemLevelLeaf>();
            WordProblemCgsLevelManager.separateChapterAndLevelNodes(chapterNodes, levelNodesWithoutChapter, genreLevelPack);
            
            // HACK: Doing a hack where the page on the left is always blank, this is because we want
            // the genre description to always appear at that left area
            
            // Draw the pages for each chapter
            var page:Sprite;
            var outPagesBuffer:Vector.<Sprite> = new Vector.<Sprite>();
            var numChapters:int = chapterNodes.length;
            var chapter:ICgsLevelPack;
            var i:int;
            var startingPageIndicesAtChapter:Vector.<int> = new Vector.<int>();
            var pagesInLastChapter:int = 0;
            for (i = 0; i < numChapters; i++)
            {
                chapter = chapterNodes[i];
                
                var outLevelNodesToDisplay:Vector.<ICgsLevelNode> = new Vector.<ICgsLevelNode>();
                for each (var childNode:ICgsLevelNode in chapter.nodes)
                {
                    _getDisplayableNodes(outLevelNodesToDisplay, childNode);
                }
                drawPagesForChapter(chapter, genreLevelPack, i + 1, outLevelNodesToDisplay, pageWidth, outPagesBuffer);
                for each (page in outPagesBuffer)
                {
                    book.addPage(new Sprite(), 0);
                    book.addPage(page, pageWidth);
                }
                
                // Remember which page belongs to which chapter
                startingPageIndicesAtChapter.push(pagesInLastChapter);
                pagesInLastChapter += outPagesBuffer.length;
                
                outPagesBuffer.length = 0;
            }
            
            // Draw the pages for the levels with no attached chapter
            var levelNodesBuffer:Vector.<ICgsLevelNode> = new Vector.<ICgsLevelNode>();
            for each (var node:WordProblemLevelLeaf in levelNodesWithoutChapter)
            {
                _getDisplayableNodes(levelNodesBuffer, node);
            }
            drawPagesForChapter(null, genreLevelPack, 0, levelNodesBuffer, pageWidth, outPagesBuffer);
            for each (page in outPagesBuffer)
            {
                book.addPage(new Sprite(), 0);
                book.addPage(page, pageWidth);
            }
            
            // Horizontally center the book on the screen
            book.x = m_screenWidth * 0.5;
            
            // The book needs to line up with the book image baked into the background
            // so need to shift it down slightly
            book.y = 60;
            
            // Redraw contents for first time
            addChild(book);
            
            // TODO:
            // Need to figure out the correct real page index
            // Do not start at cover which is at zero, immediately open the book
            if (chapterIndex > -1 && chapterIndex < startingPageIndicesAtChapter.length)
            {
                book.goToPageIndex(startingPageIndicesAtChapter[chapterIndex] + 1);
            }
            else
            {
                book.goToPageIndex(1);
            }
            togglePrevNextPageButtonsEnabled();
            
            m_closeButton.x = m_screenWidth - m_closeButton.width;
            m_closeButton.y = m_screenHeight - m_closeButton.height;
            this.addChild(m_closeButton);
            
            
        }
        
        private function _getDisplayableNodes(outNodes:Vector.<ICgsLevelNode>, parent:ICgsLevelNode):void
        {
            if (parent is WordProblemLevelNode && (parent as WordProblemLevelNode).canShowInLevelSelect())
            {
                outNodes.push(parent);
            }
            else if (parent is WordProblemLevelPack)
            {
                var children:Vector.<ICgsLevelNode> = (parent as WordProblemLevelPack).nodes;
                for each (var child:ICgsLevelNode in children)
                {
                    _getDisplayableNodes(outNodes, child);
                }
            }
        }
        
        public function closeGenre():void
        {
            while (this.numChildren > 0)
            {
                this.removeChildAt(0);
            }
        }
        
        private function onCloseTriggered(event:Event):void
        {
            Audio.instance.playSfx("button_click");
            if (m_onCloseCallback != null)
            {
                m_onCloseCallback();
            }
        }
        
        private function onNextTriggered(event:Event):void
        {
            m_book.goToNextPage();
            Audio.instance.playSfx("page_flip");
            togglePrevNextPageButtonsEnabled();
        }
        
        private function onPrevTriggered(event:Event):void
        {
            m_book.goToPreviousPage();
            Audio.instance.playSfx("page_flip");
            togglePrevNextPageButtonsEnabled();
        }
        
        private function onLevelButtonTriggered(event:Event):void
        {
            var levelNode:ICgsLevelNode = m_buttonToLevelNode[event.target] as ICgsLevelNode;
            var audioName:String = (levelNode.isLocked) ? "locked" : "button_click";
            Audio.instance.playSfx(audioName);
            
            if (!levelNode.isLocked)
            {
                // If it is another set, open up another sub menu to select individual problems from that set
                // Only open up the selector if set had been previously completed already, this is to avoid
                // a user constantly playing the same level to achieve objectives for a set (should probably
                // be checking this case elsewhere anyways
                if (levelNode is WordProblemLevelPack && levelNode.isComplete)
                {
                    var levelLeafNodes:Vector.<WordProblemLevelLeaf> = new Vector.<WordProblemLevelLeaf>();
                    WordProblemCgsLevelManager.getLevelNodes(levelLeafNodes, levelNode);
                    
                    // Get the information for the World, Chapter, and Set index to display in the widget
                    var setDescription:String = "";
                    if (levelLeafNodes.length > 0)
                    {
                        // Assume set number is just baked into the label
                        var setNumber:int = parseInt((event.target as Button).label);
                        var chapterNumber:int = levelLeafNodes[0].parentChapterLevelPack.index + 1;
                        var data:Object = getLevelSelectSectionMatchingGenre(levelLeafNodes[0].parentGenreLevelPack.getThemeId());
                        setDescription = data.title + ": " + chapterNumber + "-" + setNumber;
                    }
                    
                    m_levelSetSelector.open(setDescription, levelLeafNodes);
                    addChild(m_levelSetSelector);
                }
                else
                {
                    m_onStartLevelCallback(levelNode.nodeName);
                }
            }
        }
        
        private function onLevelSelectedFromSelector(levelNode:WordProblemLevelLeaf):void
        {
            onDismissLevelSetSelector();
            m_onStartLevelCallback(levelNode.nodeName);
        }
        
        private function onDismissLevelSetSelector():void
        {
            m_levelSetSelector.close();
            m_levelSetSelector.removeFromParent();
        }
        
        private function drawTitlePage(genreLevelPack:GenreLevelPack, pageWidth:Number):Sprite
        {
            // Draw the information screen of the cover
            var data:Object = getLevelSelectSectionMatchingGenre(genreLevelPack.getThemeId());
            var fontColor:uint = parseInt(data.textStyle.color, 16);
            var fontName:String = data.textStyle.font;
            var page:Sprite = new Sprite();

            // Used to help determine dimensions of the various text elements
            const measuringText:MeasuringTextField = new MeasuringTextField();
            
            // Create the title
            const titleText:String = data.title;
            const titleTextFormat:TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 32, fontColor);
            measuringText.defaultTextFormat = titleTextFormat;
            measuringText.width = pageWidth;
            measuringText.text = titleText;
            const titleTextField:TextField = new TextField(
                measuringText.width,
                measuringText.textHeight + 20,
                titleText,
                titleTextFormat.font,
                titleTextFormat.size as int,
                titleTextFormat.color as uint
            );
            titleTextField.hAlign = HAlign.CENTER;
            titleTextField.x = 0;
            page.addChild(titleTextField);
            
            // Create area for the flavor text describing this genre
            const flavorText:String = data.flavorText;
            const flavorTextPadding:Number = 20;
            const flavorTextFormat:TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 24, fontColor);
            measuringText.defaultTextFormat = flavorTextFormat;
            measuringText.width = pageWidth - flavorTextPadding * 2;
            measuringText.wordWrap = true;
            measuringText.text = flavorText;
            
            const flavorTextField:TextField = new TextField(
                measuringText.width + 10, 
                measuringText.textHeight + 20, 
                flavorText, 
                flavorTextFormat.font, 
                flavorTextFormat.size as int,
                flavorTextFormat.color as uint
            );
            flavorTextField.x = (pageWidth - flavorTextField.width) * 0.5;
            flavorTextField.y = 50;
            page.addChild(flavorTextField);
            
            var prizeTexturesInGenre:Vector.<Texture> = new Vector.<Texture>();
            
            // Need to find all prizes that can be awarded in this genre in the title page
            var levelComponents:Vector.<Component> = m_playerItemInventory.componentManager.getComponentListForType(LevelComponent.TYPE_ID);
            var numComponents:int = levelComponents.length;
            var i:int;
            for (i = 0; i < numComponents; i++)
            {
                var levelComponent:LevelComponent = levelComponents[i] as LevelComponent;
                if (levelComponent.genre == genreLevelPack.getThemeId())
                {
                    var itemIdComponent:ItemIdComponent = m_playerItemInventory.componentManager.getComponentFromEntityIdAndType(
                        levelComponent.entityId,
                        ItemIdComponent.TYPE_ID
                    ) as ItemIdComponent;
                    var hiddenItemComponent:HiddenItemComponent = m_playerItemInventory.componentManager.getComponentFromEntityIdAndType(
                        levelComponent.entityId,
                        HiddenItemComponent.TYPE_ID
                    ) as HiddenItemComponent;
                    var levelSelectIconComponent:LevelSelectIconComponent = m_itemDataSource.getComponentFromEntityIdAndType(
                        itemIdComponent.itemId, 
                        LevelSelectIconComponent.TYPE_ID
                    ) as LevelSelectIconComponent;
                    var textureName:String = (hiddenItemComponent.isHidden) ?
                        levelSelectIconComponent.hiddenTextureName : levelSelectIconComponent.shownTextureName;
                    prizeTexturesInGenre.push(m_assetManager.getTexture(textureName));
                }
            }
            
            if (prizeTexturesInGenre.length > 0)
            {
                var prizesCollectedText:TextField = new TextField(150, 35, "Prizes Collected:", GameFonts.DEFAULT_FONT_NAME, 16, fontColor);
                prizesCollectedText.x = (pageWidth - prizesCollectedText.width) * 0.5;
                prizesCollectedText.y = flavorTextField.y + flavorTextField.textBounds.height + 25;
                page.addChild(prizesCollectedText);
                
                var prizeImageContainer:Sprite = new Sprite();
                prizeImageContainer.x = 0;
                prizeImageContainer.y = prizesCollectedText.y + prizesCollectedText.textBounds.height + 10;
                page.addChild(prizeImageContainer);
                
                // Center and position the objects in a row
                var numTextures:int = prizeTexturesInGenre.length;
                var textureGap:Number = 18;
                var totalWidth:Number = 0;
                var texture:Texture
                for (i = 0; i < numTextures; i++)
                {
                    texture = prizeTexturesInGenre[i];
                    totalWidth += texture.width;
                    
                    // Padding in between
                    if (i != 0)
                    {
                        totalWidth += textureGap;
                    }
                }
                
                var offset:Number = (pageWidth - totalWidth) * 0.5;
                for (i = 0; i < numTextures; i++)
                {
                    texture = prizeTexturesInGenre[i];
                    var prizeImage:Image = new Image(texture);
                    prizeImage.x = offset;
                    
                    offset += textureGap + texture.width;
                    prizeImageContainer.addChild(prizeImage);
                }
            }
            
            // Draw the single egg
            // Check which items match the appropriate genre
            // To do this just loop through all items and find ones that match the genre that was opened.
            // Assuming just one 'active' item per genre
            var componentManager:ComponentManager = m_playerItemInventory.componentManager;
            var itemIdComponents:Vector.<Component> = componentManager.getComponentListForType(ItemIdComponent.TYPE_ID);
            
            var numItemIds:int = itemIdComponents.length;
            for (i = 0; i < numItemIds; i++)
            {
                itemIdComponent = itemIdComponents[i] as ItemIdComponent;
                
                // Check to see if this item matches the appropriate genre, on the first match break out
                var itemId:String = itemIdComponent.itemId;
                const genreIdComponent:GenreIdComponent = m_itemDataSource.getComponentFromEntityIdAndType(
                    itemId, 
                    GenreIdComponent.TYPE_ID
                ) as GenreIdComponent;
                if (genreIdComponent != null && genreIdComponent.genreId == genreLevelPack.getThemeId())
                {
                    // Draw the item for the genre and paste it on top
                    // HACK:
                    // This assumes that there is only one item per genre that has the grow in stages data
                    var currentGrowInStageComponent:CurrentGrowInStageComponent = componentManager.getComponentFromEntityIdAndType(
                        itemIdComponent.entityId,
                        CurrentGrowInStageComponent.TYPE_ID
                    ) as CurrentGrowInStageComponent;
                    
                    if (currentGrowInStageComponent != null)
                    {
                        // From the current stage need to figure out which texture to use for the creature
                        // We only need to redraw if the value of the current stage changes
                        var textureCollectionComponent:TextureCollectionComponent = m_itemDataSource.getComponentFromEntityIdAndType(
                            itemIdComponent.itemId, 
                            TextureCollectionComponent.TYPE_ID
                        ) as TextureCollectionComponent;
                        var textureDataObjects:Vector.<Object> = textureCollectionComponent.textureCollection;
                        var currentStage:int = currentGrowInStageComponent.currentStage;
                        if (currentStage >= 0 && currentStage < textureDataObjects.length)
                        {
                            // Based on the texture type draw a static version of the creature
                            var textureDataObject:Object = textureDataObjects[currentStage];
                            var creatureForGenreImage:DisplayObject = null;
                            if (textureDataObject.type == "ImageStatic")
                            {
                                creatureForGenreImage = DrawItemsOnShelves.createImageStaticView(textureDataObject, m_assetManager);
                            }
                            else if (textureDataObject.type == "SpriteSheetStatic")
                            {
                                creatureForGenreImage = DrawItemsOnShelves.createSpriteSheetStaticView(textureDataObject, m_assetManager);
                            }
                            
                            // The image to display on the book is scaled up to a fixed size
                            var targetHeight:Number = 240;
                            var scaleFactor:Number = targetHeight / creatureForGenreImage.height;
                            creatureForGenreImage.scaleX = creatureForGenreImage.scaleY = scaleFactor;
                            creatureForGenreImage.x = (400 - creatureForGenreImage.width) * 0.5;
                            creatureForGenreImage.y = 500 - creatureForGenreImage.height;
                            page.addChild(creatureForGenreImage);
                            
                            m_currentImageForGenre = creatureForGenreImage;
                            
                            // Add some text about the number of levels to finish before the egg reaches its final stage
                            var levelsCompletedPerStageComponent:LevelsCompletedPerStageComponent = m_itemDataSource.getComponentFromEntityIdAndType(
                                itemId,
                                LevelsCompletedPerStageComponent.TYPE_ID
                            ) as LevelsCompletedPerStageComponent;
                            var stageToLevelsList:Vector.<int> = levelsCompletedPerStageComponent.stageToLevelsCompleted;
                            if (currentStage < stageToLevelsList.length)
                            {
                                // Get the difference between the number of levels completed in genre and
                                // the number of levels needed for the last stage
                                var numLevelsToReachFinalStage:int = stageToLevelsList[stageToLevelsList.length - 1];
                                var totalCompletedInGenre:int = genreLevelPack.numLevelLeafsCompleted;
                                var remainingLevels:int = numLevelsToReachFinalStage - totalCompletedInGenre;
                                
                                var remainingLevelsText:String = StringTable.lookup("get_x_more_hatch").replace("$1", remainingLevels.toString());
                                var remainingLevelsUntilHatchingTextField:TextField = new TextField(
                                    290, 50,
                                    remainingLevelsText, 
                                    GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF);
                                remainingLevelsUntilHatchingTextField.x = 21;
                                remainingLevelsUntilHatchingTextField.y = 0;
                                
                                // Draw the text over a black background
                                var nineSlicePadding:Number = 8;
                                var backgroundTexture:Texture = m_assetManager.getTexture("button_white");
                                var backgroundImage:Scale9Image = new Scale9Image(new Scale9Textures(
                                    backgroundTexture, new Rectangle(nineSlicePadding, nineSlicePadding, backgroundTexture.width - 2 * nineSlicePadding, backgroundTexture.height - 2 * nineSlicePadding)));
                                backgroundImage.color = 0x000000;
                                backgroundImage.alpha = 0.5;
                                backgroundImage.width = remainingLevelsUntilHatchingTextField.width;
                                backgroundImage.height = remainingLevelsUntilHatchingTextField.height;
                                backgroundImage.x = 0;
                                backgroundImage.y = 0;
                                
                                var starTexture:Texture = m_assetManager.getTexture("level_button_star");
                                var starImage:Image = new Image(starTexture);
                                starImage.x = 0;
                                starImage.y = 0;
                                
                                var remainingLevelsContainer:Sprite = new Sprite();
                                remainingLevelsContainer.addChild(backgroundImage);
                                remainingLevelsContainer.addChild(starImage);
                                remainingLevelsContainer.addChild(remainingLevelsUntilHatchingTextField);
                                remainingLevelsContainer.x = creatureForGenreImage.x - 40;
                                remainingLevelsContainer.y = 440;
                                page.addChild(remainingLevelsContainer);
                            }
                        }
                        
                        break;
                    }
                }
            }
            
            return page;
        }
        
        /**
         * For all the levels in a chapter we need to draw as many pages as possible such
         * that buttons for all those levels will remain visible
         */
        private function drawPagesForChapter(chapterLevelPack:ICgsLevelPack,
                                             genreLevelPack:GenreLevelPack,
                                             chapterIndex:int,
                                             levelNodes:Vector.<ICgsLevelNode>,
                                             pageWidth:Number,
                                             outPages:Vector.<Sprite>):void
        {
            // Get the texutures names used to render the buttons for each level
            var data:Object = getLevelSelectSectionMatchingGenre(genreLevelPack.getThemeId());
            var textStyleData:Object = data.textStyle;
            var fontColor:uint = parseInt(textStyleData.color, 16);
            var levelUnlockedTexturePrefix:String = data.levelUnlockedTexture;
            var levelLockedTexturePrefix:String = data.levelLockedTexture;
            
            // Set the view port for the buttons
            const viewPortHeight:Number = 600;
            const viewPortWidth:Number = 350;
            const viewBounds:ViewPortBounds = new ViewPortBounds();
            viewBounds.maxHeight = viewPortHeight;
            viewBounds.maxWidth = viewPortWidth;
            
            // Create a pages containing an x number of buttons each
            var pagesRequired:int = Math.ceil(levelNodes.length * 1.0 / levelButtonsPerPage);
            var buttons:Vector.<DisplayObject> = new Vector.<DisplayObject>();
            
            var i:int;
            for (i = 0; i < pagesRequired; i++)
            {
                var page:Sprite = new Sprite();
                
                /* Chapter information drawing */
                
                // Specific data about a chapter is encoded in a separate file
                var chapterTitleText:TextField = new TextField(pageWidth, 30, "", GameFonts.DEFAULT_FONT_NAME, 32, fontColor);
                chapterTitleText.hAlign = HAlign.CENTER;
                chapterTitleText.text = chapterIndex.toString();
                page.addChild(chapterTitleText);
                
                var underlineText:TextField = new TextField(pageWidth, 30, "___________________________", GameFonts.DEFAULT_FONT_NAME, 24, fontColor);
                underlineText.y += 13;
                page.addChild(underlineText);
                
                // Need to calculate the total number of levels that can possibly completed + the total number they can complete
                // This will tell us the number of stars that could possibly be earned.
                var starsTotalWidth:Number = 0;
                var starTexture:Texture = m_assetManager.getTexture("level_button_star");
                starsTotalWidth += starTexture.width * 2;
                
                // Organize the section devoted to showing the number of stars earned.
                var starTextWidth:Number = 170;
                
                var starText:String = StringTable.lookup("m_out_n_earned");
                starText = starText.replace("$1", chapterLevelPack.numLevelLeafsCompleted.toString());
                starText = starText.replace("$2", chapterLevelPack.numTotalLevelLeafs.toString());
                var starInformationText:TextField = new TextField(270, 30, starText, GameFonts.DEFAULT_FONT_NAME, 20, fontColor);
                starsTotalWidth += starInformationText.width;
                
                var starOffsetX:Number = (pageWidth - starsTotalWidth) * 0.5;
                var starOffsetY:Number = chapterTitleText.height + 10;
                
                var starImageLeft:Image = new Image(starTexture);
                starImageLeft.x = starOffsetX;
                starImageLeft.y = starOffsetY;
                
                starInformationText.x = starImageLeft.width + starImageLeft.x;
                starInformationText.y = starOffsetY + 7;
                
                var starImageRight:Image = new Image(starTexture);
                starImageRight.x = starInformationText.x + starInformationText.width;
                starImageRight.y = starOffsetY;
                
                page.addChild(starImageLeft);
                page.addChild(starImageRight);
                page.addChild(starInformationText);
                
                // The chapter data block contains a desription to put on this page
                var levelPack:WordProblemLevelPack = chapterLevelPack as WordProblemLevelPack;
                if (levelPack != null && levelPack.descriptionData != null)
                {
                    var sidePadding:int = 50;
                    var chapterDescriptionText:TextField = new TextField(pageWidth - sidePadding * 2, 100, 
                        levelPack.descriptionData.description, GameFonts.DEFAULT_FONT_NAME, 20, fontColor);
                    chapterDescriptionText.x = sidePadding;
                    chapterDescriptionText.y = 23 + starInformationText.y;
                    page.addChild(chapterDescriptionText);
                }
                
                /* Level button drawing */
                
                // Draw level buttons for the page, the values range from index offset
                // to the offset+maxButtonsPerPage
                var j:int;
                var startingPageOffset:int = i * levelButtonsPerPage;
                var limit:int = startingPageOffset + Math.min(levelButtonsPerPage, levelNodes.length - startingPageOffset);
                var levelNode:ICgsLevelNode;
                for (j = startingPageOffset; j < limit; j++)
                {
                    levelNode = levelNodes[j];
                    
                    // Render buttons depending on the play status of the levels
                    // In particular, locked nodes should NOT be playable, they never trigger a call to
                    // start a level.
                    var buttonUpSkinContainer:Sprite = new Sprite();
                    
                    // The button skin is a composite image made of several textures, the first is the background texture
                    // which might be different depending on the lock/unlock state
                    var buttonBackgroundImage:DisplayObject = null;
                    if (levelNode.isLocked)
                    {
                        buttonBackgroundImage = new Image(m_assetManager.getTexture(levelLockedTexturePrefix + "_up"));
                    }
                    else
                    {
                        buttonBackgroundImage = new Image(m_assetManager.getTexture(levelUnlockedTexturePrefix + "_up"));   
                    }
                    
                    // The button is a composite
                    
                    // Render the button differently if it is a problem create
                    var isProblemCreation:Boolean = levelNode is WordProblemLevelLeaf && (levelNode as WordProblemLevelLeaf).getIsProblemCreate();
                    if (isProblemCreation)
                    {
                        var problemCreateTexture:Texture = m_assetManager.getTexture("button_white");
                        var padding:Number = 8;
                        var problemCreateButtonImage:Scale9Image = new Scale9Image(new Scale9Textures(
                            problemCreateTexture,
                            new Rectangle(padding, padding, problemCreateTexture.width - 2 * padding, problemCreateTexture.height - 2 * padding)));
                        problemCreateButtonImage.color = 0xFF0000;
                        buttonBackgroundImage = problemCreateButtonImage;
                    }
                    
                    buttonBackgroundImage.width = 70;
                    buttonBackgroundImage.height = 70;
                    buttonUpSkinContainer.addChildAt(buttonBackgroundImage, 0);
                    
                    // Select icons to paste on top of the button background
                    var labelFactory:Function = function():ITextRenderer
                    {
                        var textRenderer:TextFieldTextRenderer = new TextFieldTextRenderer();
                        var fontName:String = GameFonts.DEFAULT_FONT_NAME;
                        textRenderer.embedFonts = GameFonts.getFontIsEmbedded(fontName);
                        textRenderer.textFormat = new TextFormat(fontName, 18, 0x000000);
                        return textRenderer;
                    };
                    
                    var levelButton:Button = new Button();
                    levelButton.defaultSkin = buttonUpSkinContainer;
                    // Extra spaces needed because for some reason if the swf gets scaled down from native
                    // resolution, this text gets cutoff.
                    levelButton.label = " " + (j + 1) + " ";
                    levelButton.labelFactory = labelFactory;
                    levelButton.scaleWhenHovering = 1.05;
                    levelButton.scaleWhenDown = 0.95;
                    
                    // Draw the star or lock icon
                    if (levelNode.isComplete)
                    {
                        // For level packs, the star is shown only if everything in the set is finished too
                        var doAddStar:Boolean = true;
                        if (levelNode is WordProblemLevelPack)
                        {
                            var levelSet:WordProblemLevelPack = (levelNode as WordProblemLevelPack);
                            doAddStar = levelSet.numTotalLevelLeafs == levelSet.numLevelLeafsCompleted;
                        }
                        
                        // If the level is completed, draw a star at the top left corner
                        if (doAddStar)
                        {
                            var starImage:Image = new Image(m_assetManager.getTexture("level_button_star"));
                            starImage.pivotX = starImage.width * 0.5;
                            starImage.pivotY = starImage.height * 0.5;
                            starImage.x = 6;
                            starImage.y = 6;
                            levelButton.addChild(starImage);
                        }
                    }
                    else if (levelNode.isLocked)
                    {
                        const lockImage:Image = new Image(m_assetManager.getTexture("level_button_lock"));
                        lockImage.x = (buttonBackgroundImage.width - lockImage.width) * 0.5;
                        lockImage.y = (buttonBackgroundImage.height - lockImage.height) * 0.5;
                        levelButton.addChild(lockImage);
                        
                        levelButton.isEnabled = false;
                        // TODO: Perhaps text in the locked version of the button should be a lighter color
                        // The gray color makes the black a bit difficult to see
                    }
                    
                    // Some of the selectable levels might be tagged as 'practice'
                    // Add a banner for these special levels
                    var isPractice:Boolean = (levelNode as WordProblemLevelNode).getTagWithNameExists("practice");
                    var isLevelSet:Boolean = (levelNode is WordProblemLevelPack);
                    if (isPractice || isProblemCreation || isLevelSet)
                    {
                        var arch:DisplayObject = new Image(m_assetManager.getTexture("Art_YellowArch"));
                        arch.scaleX = arch.scaleY = 0.80;
                        arch.x = buttonUpSkinContainer.width * 0.5 * arch.scaleX;
                        arch.y = buttonUpSkinContainer.height - (10 * arch.scaleY);
                        arch.pivotX = arch.width * 0.5;
                        arch.pivotY = arch.height * 0.5;
                        levelButton.addChild(arch);
                        
                        var displayedText:String = "";
                        if (isPractice)
                        {
                            displayedText = "Practice";
                        }
                        else if (isProblemCreation)
                        {
                            displayedText = "Create";
                        }
                        else
                        {
                            displayedText = "Set";
                        }
                        var bannerText:CurvedText = new CurvedText(displayedText, new TextFormat(GameFonts.DEFAULT_FONT_NAME, 12, 0x000000), 
                            new Point(0, 20), new Point(25, 0), new Point(65, 0), new Point(90, 20));
                        bannerText.y = arch.y - arch.pivotY + 10;
                        bannerText.x = arch.x - arch.pivotX + 12;
                        levelButton.addChild(bannerText);
                    }
                    
                    // Add lightbulb icon if a level is marked as a tutorial
                    var isTutorial:Boolean = (levelNode as WordProblemLevelNode).getTagWithNameExists("tutorial");
                    if (isTutorial)
                    {
                        var lightBulbIcon:Image = new Image(m_assetManager.getTexture("light"));
                        lightBulbIcon.scaleX = lightBulbIcon.scaleY = 0.8;
                        lightBulbIcon.x = (buttonBackgroundImage.width - lightBulbIcon.width) * 0.5;
                        lightBulbIcon.y = (buttonBackgroundImage.height - lightBulbIcon.height) * 0.5;
                        levelButton.addChild(lightBulbIcon);
                        
                        lightBulbIcon.alpha = (levelNode.isLocked) ? 0.3 : 1.0;
                    }
                    
                    // Check if a reward item is attached to a level at a particular position
                    if (m_levelNodeNameToLevelComponent.hasOwnProperty(levelNode.nodeName))
                    {
                        // Get the level select icon based on whether the item has been discovered or not
                        var levelComponentWithMatch:LevelComponent = m_levelNodeNameToLevelComponent[levelNode.nodeName] as LevelComponent;
                        var rewardItemEntityId:String = levelComponentWithMatch.entityId;
                        
                        // Use the item id to find the appropriate icon data component
                        var itemIdComponent:ItemIdComponent = m_playerItemInventory.componentManager.getComponentFromEntityIdAndType(
                            rewardItemEntityId,
                            ItemIdComponent.TYPE_ID
                        ) as ItemIdComponent;
                        var itemId:String = itemIdComponent.itemId;
                        
                        var levelSelectIconComponent:LevelSelectIconComponent = m_itemDataSource.getComponentFromEntityIdAndType(
                            itemId, 
                            LevelSelectIconComponent.TYPE_ID
                        ) as LevelSelectIconComponent;
                        
                        // Assuming that all items to display here have the hidden item component
                        // This tells us whether to use the hidden or visible icon
                        var hiddenItemComponent:HiddenItemComponent = m_playerItemInventory.componentManager.getComponentFromEntityIdAndType(
                            rewardItemEntityId,
                            HiddenItemComponent.TYPE_ID
                        ) as HiddenItemComponent;
                        
                        // The icon should appear around the top right corner of the button
                        var iconTextureName:String = (hiddenItemComponent.isHidden) ? 
                            levelSelectIconComponent.hiddenTextureName : levelSelectIconComponent.shownTextureName;
                        var iconTexture:Texture = m_assetManager.getTexture(iconTextureName);
                        var rewardItemIcon:DisplayObject = new Image(iconTexture);
                        rewardItemIcon.pivotX = iconTexture.width * 0.5;
                        rewardItemIcon.pivotY = iconTexture.height * 0.5;
                        rewardItemIcon.x = buttonBackgroundImage.width - 5;
                        rewardItemIcon.y = 0;
                        
                        levelButton.addChild(rewardItemIcon);
                    }
                    
                    levelButton.addEventListener(Event.TRIGGERED, onLevelButtonTriggered);
                    buttons.push(levelButton);
                    
                    page.addChild(levelButton);
                    
                    m_buttonToLevelNode[levelButton] = levelNode;
                }
                
                // Layout all the buttons in the page
                // The left padding depends on whether the levels buttons are on the left or right page.
                // Those on left require more padding
                viewBounds.x = 35;
                viewBounds.y = 170;
                m_buttonLayout.layout(buttons, viewBounds);
                buttons.length = 0;
                
                outPages.push(page);
            }
        }
        
        private function getLevelSelectSectionMatchingGenre(genreId:String):Object
        {
            var matchingSection:Object = null;
            var levelSelectSections:Array = m_assetManager.getObject("level_select_config").sections;
            for each (var levelSelectSection:Object in levelSelectSections)
            {
                if (levelSelectSection.linkToId == genreId)
                {
                    matchingSection = levelSelectSection;
                    break;
                }
            }
            
            return matchingSection;
        }
        
        /**
         * Check whether the current setup of the book requires the enable of the
         * next/prev buttons
         */
        private function togglePrevNextPageButtonsEnabled():void
        {
            var enableNext:Boolean = m_book.canGoToNextPage();
            m_nextPageHitArea.visible = enableNext;
            
            var enablePrev:Boolean = m_book.canGoToPreviousPage();
            m_previousPageHitArea.visible = enablePrev;
        }
    }
}