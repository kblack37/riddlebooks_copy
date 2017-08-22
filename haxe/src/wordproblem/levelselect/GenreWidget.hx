package wordproblem.levelselect;

import dragonbox.common.util.XColor;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.EventDispatcher;
import openfl.text.TextFormatAlign;
import wordproblem.display.PivotSprite;
import wordproblem.display.Scale9Image;
import wordproblem.levelselect.LevelSetSelector;

import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.TextFormat;

import cgs.audio.Audio;
import cgs.internationalization.StringTable;
import cgs.levelProgression.nodes.ICgsLevelNode;
import cgs.levelProgression.nodes.ICgsLevelPack;

import dragonbox.common.ui.MouseState;

import haxe.Constraints.Function;

import wordproblem.display.LabelButton;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;

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
//import wordproblem.levelselect.scripts.DrawItemsOnShelves;
import wordproblem.resource.AssetManager;

/**
 * This is the primary container that appears when the user has selected a word problem
 * genre.
 * 
 * It should display information about the genre and allow the user to start playing levels related this
 * genre.
 */
// TODO: revisit animation when more basic elements are displayed properly
class GenreWidget extends Sprite
{
    /**
     * Use this to fetch textures
     */
    private var m_assetManager : AssetManager;
    
    /**
     * Contains all information of the current genre that should be displayed 
     */
    private var m_genreLevelPack : GenreLevelPack;
    
    /**
     * In the level select screen we need to be able to map the button or hit area that
     * was clicked to some identifier for the level to go to.
     */
    private var m_buttonToLevelNode : Map<EventDispatcher, ICgsLevelNode>;
    
    /**
     * The layout algorithm to use for buttons.
     */
    // TODO: this layout will likely need to be fixed
	//private var m_buttonLayout : HorizontalGridLayout;
    
    /**
     * In each chapter we have a button to go to the last unplayed level
     */
    private var m_buttonToChapterNode : Map<EventDispatcher, ICgsLevelPack>;
    
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
    private var m_book : BookWidget;
    
    /**
     * For each genre we have single active creature to display related for the genre.
     * When the player opens the book a fullsized image of the creature tied to that genre
     * should be visible
     */
    private var m_currentImageForGenre : DisplayObject;
    
    /**
     * The button/hit area that detects when the player wants to close this button and pick
     * another genre.
     */
    private var m_closeButton : LabelButton;
    
    /**
     * Button when clicked will go to the next page of the book 
     */
    private var m_nextPageHitArea : LabelButton;
    
    /**
     * Button when clicked will go to the previous page of the book
     */
    private var m_previousPageHitArea : LabelButton;
    
    /**
     * Function to trigger when the widget should be closed
     */
    private var m_onCloseCallback : Function;
    
    /**
     * Function to trigger when the widget has detected the user wants to go to a specific level
     * 
     * Accepts one parameter (the name of the level to go to)
     */
    private var m_onStartLevelCallback : Function;
    
    /**
     * Need this to check if particular levels have a reward so we can draw a small version of the
     * icon on the level button
     */
    private var m_playerItemInventory : ItemInventory;
    
    /**
     * Need this to fetch the data to draw the reward icons on the level buttons
     */
    private var m_itemDataSource : ItemDataSource;
    
    /**
     * Mapping from node name to the level component with the matching node
     * Used just so we don't need to look through every component for every level during the redraw.
     * 
     * key: String node name
     * value: Level Component
     */
    private var m_levelNodeNameToLevelComponent : Map<String, LevelComponent>;
    
    /**
     * A map coming from the world+chapter data source that links the world name to
     * details about that world. 
     */
    private var m_levelManager : WordProblemCgsLevelManager;
    //private var m_worldsInfo:Object;
    //private var m_chaptersInfo:Object;
    
    private inline static var levelButtonsPerPage : Int = 9;
    private inline static var m_screenWidth : Int = 800;
    private inline static var m_screenHeight : Int = 600;
    
    /**
     * Allow user to view and plays that are nested in a level set. Mostly
     * to allow replay of problems.
     */
    private var m_levelSetSelector : LevelSetSelector;
    
    /**
     *
     * @param onCloseCallback
     *      
     * @param onStartLevelCallback
     *      Accepts single param that is the string level name to play
     */
    public function new(assetManager : AssetManager,
            levelManager : WordProblemCgsLevelManager,
            playerItemInventory : ItemInventory,
            itemDataSource : ItemDataSource,
            onCloseCallback : Function,
            onStartLevelCallback : Function,
            homeButtonColor : Int)
    {
        super();
        
        m_assetManager = assetManager;
        m_levelManager = levelManager;
        m_playerItemInventory = playerItemInventory;
        m_itemDataSource = itemDataSource;
        
        var closeButtonHeight : Float = 60;
        var closeButtonWidth : Float = 60;
        var homeIcon : Bitmap = new Bitmap(m_assetManager.getBitmapData("home_icon"));
        var iconScaleTarget : Float = (closeButtonHeight * 0.8) / homeIcon.height;
        homeIcon.scaleX = homeIcon.scaleY = iconScaleTarget;
        m_closeButton = WidgetUtil.createGenericColoredButton(assetManager, homeButtonColor, null, null);
        m_closeButton.upState = homeIcon;
        m_closeButton.width = closeButtonWidth;
        m_closeButton.height = closeButtonHeight;
        m_closeButton.addEventListener(MouseEvent.CLICK, onCloseTriggered);
        m_onCloseCallback = onCloseCallback;
        m_onStartLevelCallback = onStartLevelCallback;
        
        var arrowBitmapData : BitmapData = assetManager.getBitmapData("arrow_short");
        var pageChangeButtonScaleFactor : Float = 1.25;
        var leftUpImage : DisplayObject = WidgetUtil.createPointingArrow(arrowBitmapData, true, pageChangeButtonScaleFactor);
        var leftOverImage : DisplayObject = WidgetUtil.createPointingArrow(arrowBitmapData, true, pageChangeButtonScaleFactor, 0xCCCCCC);
        
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
        m_previousPageHitArea.addEventListener(MouseEvent.CLICK, onPrevTriggered);
        
        var rightUpImage : DisplayObject = WidgetUtil.createPointingArrow(arrowBitmapData, false, pageChangeButtonScaleFactor, 0xFFFFFF);
        var rightOverImage : DisplayObject = WidgetUtil.createPointingArrow(arrowBitmapData, false, pageChangeButtonScaleFactor, 0xCCCCCC);
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
        m_nextPageHitArea.addEventListener(MouseEvent.CLICK, onNextTriggered);
        
		// TODO: uncomment when layout replacement is designed
        //m_buttonLayout = new HorizontalGridLayout();
        //m_buttonLayout.useSquareTiles = true;
        //m_buttonLayout.padding = 10;
        //m_buttonLayout.verticalGap = 25;
        //m_buttonLayout.horizontalGap = 25;
        //m_buttonLayout.paging = TiledRowsLayout.PAGING_NONE;
        //m_buttonLayout.tileHorizontalAlign = TiledRowsLayout.TILE_HORIZONTAL_ALIGN_LEFT;
        //m_buttonLayout.tileVerticalAlign = TiledRowsLayout.TILE_VERTICAL_ALIGN_TOP;
        //m_buttonLayout.horizontalAlign = TiledRowsLayout.HORIZONTAL_ALIGN_LEFT;
        //m_buttonLayout.verticalAlign = TiledRowsLayout.VERTICAL_ALIGN_TOP;
        //m_buttonLayout.useVirtualLayout = false;
        
        m_levelSetSelector = new LevelSetSelector(m_screenWidth, m_screenHeight, m_assetManager, 
                onLevelSelectedFromSelector, onDismissLevelSetSelector);
    }
    
    public function update(mouseState : MouseState) : Void
    {
        if (m_levelSetSelector != null && m_levelSetSelector.parent != null) 
        {
            m_levelSetSelector.update(mouseState);
        }
    }
    
    public function dispose() : Void
    {
		m_closeButton.removeEventListener(MouseEvent.CLICK, onCloseTriggered);
		m_previousPageHitArea.removeEventListener(MouseEvent.CLICK, onPrevTriggered);
		m_nextPageHitArea.removeEventListener(MouseEvent.CLICK, onNextTriggered);
		
		m_book.dispose();
    }
    
    /**
     * Get back the last opened genre
     * 
     * @return
     *      null if no genre screen was last opened
     */
    public function getGenre() : GenreLevelPack
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
    public function setGenre(genreLevelPack : GenreLevelPack, chapterIndex : Int, levelIndex : Int = -1) : Void
    {
		function cleanButtonDictionary(dictionary : Map<EventDispatcher, Dynamic>) : Void
        {
            var dictionaryKey : Dynamic = null;
            for (dictionaryKey in Reflect.fields(dictionary))
            {
                var button : LabelButton = try cast(dictionaryKey, LabelButton) catch (e:Dynamic) null;
				button.removeEventListener(MouseEvent.CLICK, onLevelButtonTriggered);
                button.dispose();
            }
        };  
		
        // Clean out level buttons
        if (m_buttonToLevelNode != null) 
        {
            cleanButtonDictionary(m_buttonToLevelNode);
        }
        else 
        {
            m_buttonToLevelNode = new Map();
        }
		
		// Clean out the chapter buttons  
        if (m_buttonToChapterNode != null) 
        {
            cleanButtonDictionary(m_buttonToChapterNode);
        }
        else 
        {
            m_buttonToChapterNode = new Map();
        }
        
		// Remove previous egg image
        if (m_currentImageForGenre != null) 
        {
			if (m_currentImageForGenre.parent != null) m_currentImageForGenre.parent.removeChild(m_currentImageForGenre);
            m_currentImageForGenre = null;
        }		
		
		// Go through every level component and create a quick mapping from the level node name to the component  
		// This is so we don't need to loop through every component every time we draw the level buttons
        // to see if a reward should be attached
        m_levelNodeNameToLevelComponent = new Map();
        var levelComponents : Array<Component> = m_playerItemInventory.componentManager.getComponentListForType(LevelComponent.TYPE_ID);
        var numComponents : Int = levelComponents.length;
        for (i in 0...numComponents){
            var levelComponent : LevelComponent = try cast(levelComponents[i], LevelComponent) catch(e:Dynamic) null;
            m_levelNodeNameToLevelComponent[levelComponent.levelName] = levelComponent;
        }
        
        this.closeGenre();
        m_genreLevelPack = genreLevelPack;
        
        // Pick the proper background to use from the genre data blob
        var data : Dynamic = getLevelSelectSectionMatchingGenre(genreLevelPack.getThemeId());
        var bgImage : Bitmap = new Bitmap(m_assetManager.getBitmapData(data.levelSelectBackgroundTexture));
        addChild(bgImage);
        
        m_nextPageHitArea.x = 740;
        m_nextPageHitArea.y = 280;
        this.addChild(m_nextPageHitArea);
        m_previousPageHitArea.x = 10;
        m_previousPageHitArea.y = m_nextPageHitArea.y;
        this.addChild(m_previousPageHitArea);
        
        var book : BookWidget = new BookWidget(true);
        m_book = book;
        
        // The total number of pages required are the
        // front info page,
        // variable number of pages for levels, and
        
        // Draw each page and add it to the book, beginning with the genre description
        var pageWidth : Float = m_screenWidth * 0.5;
        var titlePage : Sprite = drawTitlePage(genreLevelPack, pageWidth);
        titlePage.x -= (pageWidth - 35);
        book.addChild(titlePage);
        
        // Need to separate out the regular level nodes and those belonging to a chapter
        // The reason is we draw the levels belonging to a chapter first and the levels
        // without a chapter are all grouped together at the end.
        // This only applies for the level select.
        var chapterNodes : Array<ChapterLevelPack> = new Array<ChapterLevelPack>();
        var levelNodesWithoutChapter : Array<WordProblemLevelLeaf> = new Array<WordProblemLevelLeaf>();
        WordProblemCgsLevelManager.separateChapterAndLevelNodes(chapterNodes, levelNodesWithoutChapter, genreLevelPack);
        
        // HACK: Doing a hack where the page on the left is always blank, this is because we want
        // the genre description to always appear at that left area
        
        // Draw the pages for each chapter
        var page : Sprite = null;
        var outPagesBuffer : Array<Sprite> = new Array<Sprite>();
        var numChapters : Int = chapterNodes.length;
        var chapter : ICgsLevelPack = null;
        var i : Int = 0;
        var startingPageIndicesAtChapter : Array<Int> = new Array<Int>();
        var pagesInLastChapter : Int = 0;
        for (i in 0...numChapters){
            chapter = chapterNodes[i];
            
            var outLevelNodesToDisplay : Array<ICgsLevelNode> = new Array<ICgsLevelNode>();
            for (childNode in chapter.nodes)
            {
                _getDisplayableNodes(outLevelNodesToDisplay, childNode);
            }
            drawPagesForChapter(chapter, genreLevelPack, i + 1, outLevelNodesToDisplay, pageWidth, outPagesBuffer);
            for (page in outPagesBuffer)
            {
                book.addPage(new Sprite(), 0);
                book.addPage(page, pageWidth);
            }
			
			// Remember which page belongs to which chapter  
            startingPageIndicesAtChapter.push(pagesInLastChapter);
            pagesInLastChapter += outPagesBuffer.length;
            
			outPagesBuffer = new Array<Sprite>();
        }
		
		// Draw the pages for the levels with no attached chapter  
        var levelNodesBuffer : Array<ICgsLevelNode> = new Array<ICgsLevelNode>();
        for (node in levelNodesWithoutChapter)
        {
            _getDisplayableNodes(levelNodesBuffer, node);
        }
        drawPagesForChapter(null, genreLevelPack, 0, levelNodesBuffer, pageWidth, outPagesBuffer);
        for (page in outPagesBuffer)
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
    
    private function _getDisplayableNodes(outNodes : Array<ICgsLevelNode>, parent : ICgsLevelNode) : Void
    {
        if (Std.is(parent, WordProblemLevelNode) && (try cast(parent, WordProblemLevelNode) catch(e:Dynamic) null).canShowInLevelSelect()) 
        {
            outNodes.push(parent);
        }
        else if (Std.is(parent, WordProblemLevelPack)) 
        {
            var children : Array<ICgsLevelNode> = (try cast(parent, WordProblemLevelPack) catch(e:Dynamic) null).nodes;
            for (child in children)
            {
                _getDisplayableNodes(outNodes, child);
            }
        }
    }
    
    public function closeGenre() : Void
    {
        while (this.numChildren > 0)
        {
            this.removeChildAt(0);
        }
    }
    
    private function onCloseTriggered(event : Event) : Void
    {
        Audio.instance.playSfx("button_click");
        if (m_onCloseCallback != null) 
        {
            m_onCloseCallback();
        }
    }
    
    private function onNextTriggered(event : Event) : Void
    {
        m_book.goToNextPage();
        Audio.instance.playSfx("page_flip");
        togglePrevNextPageButtonsEnabled();
    }
    
    private function onPrevTriggered(event : Event) : Void
    {
        m_book.goToPreviousPage();
        Audio.instance.playSfx("page_flip");
        togglePrevNextPageButtonsEnabled();
    }
    
    private function onLevelButtonTriggered(event : Dynamic) : Void
    {
        var levelNode : ICgsLevelNode = m_buttonToLevelNode[event.target];
        var audioName : String = ((levelNode.isLocked)) ? "locked" : "button_click";
        Audio.instance.playSfx(audioName);
        
        if (!levelNode.isLocked) 
        {
            // If it is another set, open up another sub menu to select individual problems from that set
            // Only open up the selector if set had been previously completed already, this is to avoid
            // a user constantly playing the same level to achieve objectives for a set (should probably
            // be checking this case elsewhere anyways
            if (Std.is(levelNode, WordProblemLevelPack) && levelNode.isComplete) 
            {
                var levelLeafNodes : Array<WordProblemLevelLeaf> = new Array<WordProblemLevelLeaf>();
                WordProblemCgsLevelManager.getLevelNodes(levelLeafNodes, levelNode);
                
                // Get the information for the World, Chapter, and Set index to display in the widget
                var setDescription : String = "";
                if (levelLeafNodes.length > 0) 
                {
                    // Assume set number is just baked into the label
                    var setNumber : Int = Std.parseInt((try cast(event.target, LabelButton) catch(e:Dynamic) null).label);
                    var chapterNumber : Int = levelLeafNodes[0].parentChapterLevelPack.index + 1;
                    var data : Dynamic = getLevelSelectSectionMatchingGenre(levelLeafNodes[0].parentGenreLevelPack.getThemeId());
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
    
    private function onLevelSelectedFromSelector(levelNode : WordProblemLevelLeaf) : Void
    {
        onDismissLevelSetSelector();
        m_onStartLevelCallback(levelNode.nodeName);
    }
    
    private function onDismissLevelSetSelector() : Void
    {
        m_levelSetSelector.close();
        if (m_levelSetSelector.parent != null) m_levelSetSelector.parent.removeChild(m_levelSetSelector);
    }
    
    private function drawTitlePage(genreLevelPack : GenreLevelPack, pageWidth : Float) : Sprite
    {
        // Draw the information screen of the cover
        var data : Dynamic = getLevelSelectSectionMatchingGenre(genreLevelPack.getThemeId());
        var fontColor : Int = Std.parseInt(data.textStyle.color);
        var fontName : String = data.textStyle.font;
        var page : Sprite = new Sprite();
        
        // Used to help determine dimensions of the various text elements
        var measuringText : MeasuringTextField = new MeasuringTextField();
        
        // Create the title
        var titleText : String = data.title;
        var titleTextFormat : TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 32, fontColor);
        measuringText.defaultTextFormat = titleTextFormat;
        measuringText.width = pageWidth;
        measuringText.text = titleText;
        var titleTextField : TextField = new TextField();
		titleTextField.width = measuringText.width;
		titleTextField.height = measuringText.textHeight + 20;
		titleTextField.text = titleText;
		titleTextField.setTextFormat(new TextFormat(titleTextFormat.font, titleTextFormat.size, titleTextFormat.color, null, null, null, null, null, TextFormatAlign.CENTER));
        titleTextField.x = 0;
        page.addChild(titleTextField);
        
        // Create area for the flavor text describing this genre
        var flavorText : String = data.flavorText;
        var flavorTextPadding : Float = 20;
        var flavorTextFormat : TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 24, fontColor);
        measuringText.defaultTextFormat = flavorTextFormat;
        measuringText.width = pageWidth - flavorTextPadding * 2;
        measuringText.wordWrap = true;
        measuringText.text = flavorText;
        
        var flavorTextField : TextField = new TextField();
		flavorTextField.width = measuringText.width + 10;
		flavorTextField.height = measuringText.textHeight + 20; 
		flavorTextField.text = flavorText;
		flavorTextField.setTextFormat(new TextFormat(flavorTextFormat.font, flavorTextFormat.size, flavorTextFormat.color));
        flavorTextField.x = (pageWidth - flavorTextField.width) * 0.5;
        flavorTextField.y = 50;
        page.addChild(flavorTextField);
        
        var prizeBitmapDataInGenre : Array<BitmapData> = new Array<BitmapData>();
        
        // Need to find all prizes that can be awarded in this genre in the title page
        var levelComponents : Array<Component> = m_playerItemInventory.componentManager.getComponentListForType(LevelComponent.TYPE_ID);
        var numComponents : Int = levelComponents.length;
        var i : Int = 0;
        for (i in 0...numComponents){
            var levelComponent : LevelComponent = try cast(levelComponents[i], LevelComponent) catch(e:Dynamic) null;
            if (levelComponent.genre == genreLevelPack.getThemeId()) 
            {
                var itemIdComponent : ItemIdComponent = try cast(m_playerItemInventory.componentManager.getComponentFromEntityIdAndType(
                        levelComponent.entityId,
                        ItemIdComponent.TYPE_ID
                        ), ItemIdComponent) catch(e:Dynamic) null;
                var hiddenItemComponent : HiddenItemComponent = try cast(m_playerItemInventory.componentManager.getComponentFromEntityIdAndType(
                        levelComponent.entityId,
                        HiddenItemComponent.TYPE_ID
                        ), HiddenItemComponent) catch(e:Dynamic) null;
                var levelSelectIconComponent : LevelSelectIconComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(
                        itemIdComponent.itemId,
                        LevelSelectIconComponent.TYPE_ID
                        ), LevelSelectIconComponent) catch(e:Dynamic) null;
                var textureName : String = ((hiddenItemComponent.isHidden)) ? 
                levelSelectIconComponent.hiddenTextureName : levelSelectIconComponent.shownTextureName;
                prizeBitmapDataInGenre.push(m_assetManager.getBitmapData(textureName));
            }
        }
        
        if (prizeBitmapDataInGenre.length > 0) 
        {
            var prizesCollectedText : TextField = new TextField();
			prizesCollectedText.width = 150;
			prizesCollectedText.height = 35;
			prizesCollectedText.text = "Prizes Collected:";
			prizesCollectedText.setTextFormat(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 16, fontColor));
            prizesCollectedText.x = (pageWidth - prizesCollectedText.width) * 0.5;
            prizesCollectedText.y = flavorTextField.y + flavorTextField.textHeight + 25;
            page.addChild(prizesCollectedText);
            
            var prizeImageContainer : Sprite = new Sprite();
            prizeImageContainer.x = 0;
            prizeImageContainer.y = prizesCollectedText.y + prizesCollectedText.textHeight + 10;
            page.addChild(prizeImageContainer);
            
            // Center and position the objects in a row
            var numTextures : Int = prizeBitmapDataInGenre.length;
            var textureGap : Float = 18;
            var totalWidth : Float = 0;
            var bitmapData : BitmapData = null;
            for (i in 0...numTextures){
                bitmapData = prizeBitmapDataInGenre[i];
                totalWidth += bitmapData.width;
                
                // Padding in between
                if (i != 0) 
                {
                    totalWidth += textureGap;
                }
            }
            
            var offset : Float = (pageWidth - totalWidth) * 0.5;
            for (i in 0...numTextures){
                bitmapData = prizeBitmapDataInGenre[i];
                var prizeImage : Bitmap = new Bitmap(bitmapData);
                prizeImage.x = offset;
                
                offset += textureGap + bitmapData.width;
                prizeImageContainer.addChild(prizeImage);
            }
        }  
		
		// Draw the single egg  
		// Check which items match the appropriate genre   
		// To do this just loop through all items and find ones that match the genre that was opened.  
        // Assuming just one 'active' item per genre   
        var componentManager : ComponentManager = m_playerItemInventory.componentManager;
        var itemIdComponents : Array<Component> = componentManager.getComponentListForType(ItemIdComponent.TYPE_ID);
        
        var numItemIds : Int = itemIdComponents.length;
        for (i in 0...numItemIds){
            var itemIdComponent = try cast(itemIdComponents[i], ItemIdComponent) catch(e:Dynamic) null;
            
            // Check to see if this item matches the appropriate genre, on the first match break out
            var itemId : String = itemIdComponent.itemId;
            var genreIdComponent : GenreIdComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(
                    itemId,
                    GenreIdComponent.TYPE_ID
                    ), GenreIdComponent) catch(e:Dynamic) null;
            if (genreIdComponent != null && genreIdComponent.genreId == genreLevelPack.getThemeId()) 
            {
                // Draw the item for the genre and paste it on top
                // HACK:
                // This assumes that there is only one item per genre that has the grow in stages data
                var currentGrowInStageComponent : CurrentGrowInStageComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                        itemIdComponent.entityId,
                        CurrentGrowInStageComponent.TYPE_ID
                        ), CurrentGrowInStageComponent) catch(e:Dynamic) null;
                
                if (currentGrowInStageComponent != null) 
                {
                    // From the current stage need to figure out which texture to use for the creature
                    // We only need to redraw if the value of the current stage changes
                    var textureCollectionComponent : TextureCollectionComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(
                            itemIdComponent.itemId,
                            TextureCollectionComponent.TYPE_ID
                            ), TextureCollectionComponent) catch(e:Dynamic) null;
                    var textureDataObjects : Array<Dynamic> = textureCollectionComponent.textureCollection;
                    var currentStage : Int = currentGrowInStageComponent.currentStage;
                    if (currentStage >= 0 && currentStage < textureDataObjects.length) 
                    {
                        // Based on the texture type draw a static version of the creature
                        var textureDataObject : Dynamic = textureDataObjects[currentStage];
                        var creatureForGenreImage : DisplayObject = null;
                        if (textureDataObject.type == "ImageStatic") 
                        {
                            //creatureForGenreImage = DrawItemsOnShelves.createImageStaticView(textureDataObject, m_assetManager);
                        }
                        // The image to display on the book is scaled up to a fixed size
                        else if (textureDataObject.type == "SpriteSheetStatic") 
                        {
                            //creatureForGenreImage = DrawItemsOnShelves.createSpriteSheetStaticView(textureDataObject, m_assetManager);
                        }
                        
                        
                        
                        var targetHeight : Float = 240;
                        var scaleFactor : Float = targetHeight / creatureForGenreImage.height;
                        creatureForGenreImage.scaleX = creatureForGenreImage.scaleY = scaleFactor;
                        creatureForGenreImage.x = (400 - creatureForGenreImage.width) * 0.5;
                        creatureForGenreImage.y = 500 - creatureForGenreImage.height;
                        page.addChild(creatureForGenreImage);
                        
                        m_currentImageForGenre = creatureForGenreImage;
                        
                        // Add some text about the number of levels to finish before the egg reaches its final stage
                        var levelsCompletedPerStageComponent : LevelsCompletedPerStageComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(
                                itemId,
                                LevelsCompletedPerStageComponent.TYPE_ID
                                ), LevelsCompletedPerStageComponent) catch(e:Dynamic) null;
                        var stageToLevelsList : Array<Int> = levelsCompletedPerStageComponent.stageToLevelsCompleted;
                        if (currentStage < stageToLevelsList.length) 
                        {
                            // Get the difference between the number of levels completed in genre and
                            // the number of levels needed for the last stage
                            var numLevelsToReachFinalStage : Int = stageToLevelsList[stageToLevelsList.length - 1];
                            var totalCompletedInGenre : Int = genreLevelPack.numLevelLeafsCompleted;
                            var remainingLevels : Int = numLevelsToReachFinalStage - totalCompletedInGenre;
                            
							// TODO: uncomment once cgs library is finished
							var remainingLevelsText : String = StringTools.replace("" /*StringTable.lookup("get_x_more_hatch")*/, "$1", Std.string(remainingLevels));
                            var remainingLevelsUntilHatchingTextField : TextField = new TextField();
							remainingLevelsUntilHatchingTextField.width = 290;
							remainingLevelsUntilHatchingTextField.height = 50; 
							remainingLevelsUntilHatchingTextField.text = remainingLevelsText; 
							remainingLevelsUntilHatchingTextField.setTextFormat(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF));
                            remainingLevelsUntilHatchingTextField.x = 21;
                            remainingLevelsUntilHatchingTextField.y = 0;
                            
                            // Draw the text over a black background
                            var nineSlicePadding : Float = 8;
                            var backgroundBitmapData : BitmapData = m_assetManager.getBitmapData("button_white");
                            var backgroundImage : Scale9Image = new Scale9Image(backgroundBitmapData, new Rectangle(
								nineSlicePadding,
								nineSlicePadding,
								backgroundBitmapData.width - 2 * nineSlicePadding,
								backgroundBitmapData.height - 2 * nineSlicePadding
							));
							backgroundImage.transform.colorTransform.concat(XColor.rgbToColorTransform(0x000000));
                            backgroundImage.alpha = 0.5;
                            backgroundImage.width = remainingLevelsUntilHatchingTextField.width;
                            backgroundImage.height = remainingLevelsUntilHatchingTextField.height;
                            backgroundImage.x = 0;
                            backgroundImage.y = 0;
                            
                            var starBitmapData : BitmapData = m_assetManager.getBitmapData("level_button_star");
                            var starImage : Bitmap = new Bitmap(starBitmapData);
                            starImage.x = 0;
                            starImage.y = 0;
                            
                            var remainingLevelsContainer : Sprite = new Sprite();
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
    private function drawPagesForChapter(chapterLevelPack : ICgsLevelPack,
            genreLevelPack : GenreLevelPack,
            chapterIndex : Int,
            levelNodes : Array<ICgsLevelNode>,
            pageWidth : Float,
            outPages : Array<Sprite>) : Void
    {
        // Get the texutures names used to render the buttons for each level
        var data : Dynamic = getLevelSelectSectionMatchingGenre(genreLevelPack.getThemeId());
        var textStyleData : Dynamic = data.textStyle;
        var fontColor : Int = Std.parseInt(textStyleData.color);
        var levelUnlockedTexturePrefix : String = data.levelUnlockedTexture;
        var levelLockedTexturePrefix : String = data.levelLockedTexture;
        
        // Set the view port for the buttons
        var viewPortHeight : Float = 600;
        var viewPortWidth : Float = 350;
        var viewBounds : Rectangle = new Rectangle();
        viewBounds.height = viewPortHeight;
        viewBounds.width = viewPortWidth;
        
        // Create a pages containing an x number of buttons each
        var pagesRequired : Int = Math.ceil(levelNodes.length * 1.0 / levelButtonsPerPage);
        var buttons : Array<DisplayObject> = new Array<DisplayObject>();
        
        var i : Int = 0;
        for (i in 0...pagesRequired){
            var page : Sprite = new Sprite();
            
            /* Chapter information drawing */
            
            // Specific data about a chapter is encoded in a separate file
            var chapterTitleText : TextField = new TextField();
			chapterTitleText.width = pageWidth;
			chapterTitleText.height = 30;
			chapterTitleText.text = "";
			chapterTitleText.setTextFormat(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 32, fontColor, null, null, true, null, null, TextFormatAlign.CENTER));
            chapterTitleText.text = Std.string(chapterIndex);
            page.addChild(chapterTitleText);
            
            // Need to calculate the total number of levels that can possibly completed + the total number they can complete
            // This will tell us the number of stars that could possibly be earned.
            var starsTotalWidth : Float = 0;
            var starBitmapData : BitmapData = m_assetManager.getBitmapData("level_button_star");
            starsTotalWidth += starBitmapData.width * 2;
            
            // Organize the section devoted to showing the number of stars earned.
            var starTextWidth : Float = 170;
            
			// TODO: uncomment once cgs library is finished
            var starText : String = "";// StringTable.lookup("m_out_n_earned");
			starText = StringTools.replace(starText, "$1", Std.string(chapterLevelPack.numLevelLeafsCompleted));
			starText = StringTools.replace(starText, "$2", Std.string(chapterLevelPack.numTotalLevelLeafs));
            var starInformationText : TextField = new TextField();
			starInformationText.width = 270;
			starInformationText.height = 30;
			starInformationText.text = starText;
			starInformationText.setTextFormat(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, fontColor));
            starsTotalWidth += starInformationText.width;
            
            var starOffsetX : Float = (pageWidth - starsTotalWidth) * 0.5;
            var starOffsetY : Float = chapterTitleText.height + 10;
            
            var starImageLeft : Bitmap = new Bitmap(starBitmapData);
            starImageLeft.x = starOffsetX;
            starImageLeft.y = starOffsetY;
            
            starInformationText.x = starImageLeft.width + starImageLeft.x;
            starInformationText.y = starOffsetY + 7;
            
            var starImageRight : Bitmap = new Bitmap(starBitmapData);
            starImageRight.x = starInformationText.x + starInformationText.width;
            starImageRight.y = starOffsetY;
            
            page.addChild(starImageLeft);
            page.addChild(starImageRight);
            page.addChild(starInformationText);
            
            // The chapter data block contains a desription to put on this page
            var levelPack : WordProblemLevelPack = try cast(chapterLevelPack, WordProblemLevelPack) catch(e:Dynamic) null;
            if (levelPack != null && levelPack.descriptionData != null) 
            {
                var sidePadding : Int = 50;
                var chapterDescriptionText : TextField = new TextField();
				chapterDescriptionText.width = pageWidth - sidePadding * 2;
				chapterDescriptionText.height = 100; 
				chapterDescriptionText.text = levelPack.descriptionData.description;
				chapterDescriptionText.setTextFormat(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, fontColor));
				chapterDescriptionText.x = sidePadding;
				chapterDescriptionText.y = 23 + starInformationText.y;
                page.addChild(chapterDescriptionText);
            }
			
			/* Level button drawing */  
			// Draw level buttons for the page, the values range from index offset
			// to the offset+maxButtonsPerPage
            var j : Int = 0;
            var startingPageOffset : Int = i * levelButtonsPerPage;
            var limit : Int = startingPageOffset + Std.int(Math.min(levelButtonsPerPage, levelNodes.length - startingPageOffset));
            var levelNode : ICgsLevelNode = null;
            for (j in startingPageOffset...limit){
                levelNode = levelNodes[j];
                
                // Render buttons depending on the play status of the levels
                // In particular, locked nodes should NOT be playable, they never trigger a call to
                // start a level.
                var buttonUpSkinContainer : Sprite = new Sprite();
                
                // The button skin is a composite image made of several textures, the first is the background texture
                // which might be different depending on the lock/unlock state
                var buttonBackgroundImage : DisplayObject = null;
                if (levelNode.isLocked) 
                {
                    buttonBackgroundImage = new Bitmap(m_assetManager.getBitmapData(levelLockedTexturePrefix + "_up"));
                }
                else 
                {
                    buttonBackgroundImage = new Bitmap(m_assetManager.getBitmapData(levelUnlockedTexturePrefix + "_up"));
                }  
				
				// The button is a composite  
                // Render the button differently if it is a problem create 
                var isProblemCreation : Bool = Std.is(levelNode, WordProblemLevelLeaf) && (try cast(levelNode, WordProblemLevelLeaf) catch(e:Dynamic) null).getIsProblemCreate();
                if (isProblemCreation) 
                {
                    var problemCreateBitmapData : BitmapData = m_assetManager.getBitmapData("button_white");
                    var padding : Float = 8;
                    var problemCreateButtonImage : Scale9Image = new Scale9Image(problemCreateBitmapData), new Rectangle(padding,
						padding,
						problemCreateBitmapData.width - 2 * padding,
						problemCreateBitmapData.height - 2 * padding
					));
					problemCreateButtonImage.transform.colorTransform.concat(XColor.rgbToColorTransform(0xFF0000));
                    buttonBackgroundImage = problemCreateButtonImage;
                }
                
                buttonBackgroundImage.width = 70;
                buttonBackgroundImage.height = 70;
                buttonUpSkinContainer.addChildAt(buttonBackgroundImage, 0);
                
                // Extra spaces needed because for some reason if the swf gets scaled down from native
                // resolution, this text gets cutoff.
				var levelButton : LabelButton = new LabelButton(buttonBackgroundImage);
				levelButton.label = " " + (j + 1) + " ";
				levelButton.textFormatDefault = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0x000000);
                levelButton.scaleWhenOver = 1.05;
                levelButton.scaleWhenDown = 0.95;
                
                // Draw the star or lock icon
                if (levelNode.isComplete) 
                {
                    // For level packs, the star is shown only if everything in the set is finished too
                    var doAddStar : Bool = true;
                    if (Std.is(levelNode, WordProblemLevelPack)) 
                    {
                        var levelSet : WordProblemLevelPack = (try cast(levelNode, WordProblemLevelPack) catch(e:Dynamic) null);
                        doAddStar = levelSet.numTotalLevelLeafs == levelSet.numLevelLeafsCompleted;
                    } 
					
					// If the level is completed, draw a star at the top left corner  
                    if (doAddStar) 
                    {
                        var starImage : PivotSprite = new PivotSprite();
						starImage.addChild(new Bitmap(m_assetManager.getBitmapData("level_button_star")));
                        starImage.pivotX = starImage.width * 0.5;
                        starImage.pivotY = starImage.height * 0.5;
                        starImage.x = 6;
                        starImage.y = 6;
                        levelButton.addChild(starImage);
                    }
                }
                else if (levelNode.isLocked) 
                {
                    var lockImage : Bitmap = new Bitmap(m_assetManager.getBitmapData("level_button_lock"));
                    lockImage.x = (buttonBackgroundImage.width - lockImage.width) * 0.5;
                    lockImage.y = (buttonBackgroundImage.height - lockImage.height) * 0.5;
                    levelButton.addChild(lockImage);
                    
                    levelButton.enabled = false;
                }
                
                // Some of the selectable levels might be tagged as 'practice'
                // Add a banner for these special levels
                var isPractice : Bool = (try cast(levelNode, WordProblemLevelNode) catch(e:Dynamic) null).getTagWithNameExists("practice");
                var isLevelSet : Bool = (Std.is(levelNode, WordProblemLevelPack));
                if (isPractice || isProblemCreation || isLevelSet) 
                {
                    var arch : PivotSprite = new PivotSprite();
					arch.addChild(new Bitmap(m_assetManager.getBitmapData("Art_YellowArch")));
                    arch.scaleX = arch.scaleY = 0.80;
                    arch.x = buttonUpSkinContainer.width * 0.5 * arch.scaleX;
                    arch.y = buttonUpSkinContainer.height - (10 * arch.scaleY);
                    arch.pivotX = arch.width * 0.5;
                    arch.pivotY = arch.height * 0.5;
                    levelButton.addChild(arch);
                    
                    var displayedText : String = "";
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
                    var bannerText : CurvedText = new CurvedText(displayedText, new TextFormat(GameFonts.DEFAULT_FONT_NAME, 12, 0x000000), 
                    new Point(0, 20), new Point(25, 0), new Point(65, 0), new Point(90, 20));
                    bannerText.y = arch.y - arch.pivotY + 10;
                    bannerText.x = arch.x - arch.pivotX + 12;
                    levelButton.addChild(bannerText);
                } 
				
				// Add lightbulb icon if a level is marked as a tutorial  
                var isTutorial : Bool = (try cast(levelNode, WordProblemLevelNode) catch(e:Dynamic) null).getTagWithNameExists("tutorial");
                if (isTutorial) 
                {
                    var lightBulbIcon : Bitmap = new Bitmap(m_assetManager.getBitmapData("light"));
                    lightBulbIcon.scaleX = lightBulbIcon.scaleY = 0.8;
                    lightBulbIcon.x = (buttonBackgroundImage.width - lightBulbIcon.width) * 0.5;
                    lightBulbIcon.y = (buttonBackgroundImage.height - lightBulbIcon.height) * 0.5;
                    levelButton.addChild(lightBulbIcon);
                    
                    lightBulbIcon.alpha = ((levelNode.isLocked)) ? 0.3 : 1.0;
                } 
				
				// Check if a reward item is attached to a level at a particular position  
                if (m_levelNodeNameToLevelComponent.exists(levelNode.nodeName)) 
                {
                    // Get the level select icon based on whether the item has been discovered or not
                    var levelComponentWithMatch : LevelComponent = try cast(m_levelNodeNameToLevelComponent[levelNode.nodeName], LevelComponent) catch(e:Dynamic) null;
                    var rewardItemEntityId : String = levelComponentWithMatch.entityId;
                    
                    // Use the item id to find the appropriate icon data component
                    var itemIdComponent : ItemIdComponent = try cast(m_playerItemInventory.componentManager.getComponentFromEntityIdAndType(
                            rewardItemEntityId,
                            ItemIdComponent.TYPE_ID
                            ), ItemIdComponent) catch(e:Dynamic) null;
                    var itemId : String = itemIdComponent.itemId;
                    
                    var levelSelectIconComponent : LevelSelectIconComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(
                            itemId,
                            LevelSelectIconComponent.TYPE_ID
                            ), LevelSelectIconComponent) catch(e:Dynamic) null;
                    
                    // Assuming that all items to display here have the hidden item component
                    // This tells us whether to use the hidden or visible icon
                    var hiddenItemComponent : HiddenItemComponent = try cast(m_playerItemInventory.componentManager.getComponentFromEntityIdAndType(
                            rewardItemEntityId,
                            HiddenItemComponent.TYPE_ID
                            ), HiddenItemComponent) catch(e:Dynamic) null;
                    
                    // The icon should appear around the top right corner of the button
                    var iconTextureName : String = ((hiddenItemComponent.isHidden)) ? 
                    levelSelectIconComponent.hiddenTextureName : levelSelectIconComponent.shownTextureName;
                    var iconBitmapData : BitmapData = m_assetManager.getBitmapData(iconTextureName);
                    var rewardItemIcon : PivotSprite = new PivotSprite();
					rewardItemIcon.addChild(new Bitmap(iconBitmapData));
                    rewardItemIcon.pivotX = iconBitmapData.width * 0.5;
                    rewardItemIcon.pivotY = iconBitmapData.height * 0.5;
                    rewardItemIcon.x = buttonBackgroundImage.width - 5;
                    rewardItemIcon.y = 0;
                    
                    levelButton.addChild(rewardItemIcon);
                }
                
                levelButton.addEventListener(MouseEvent.CLICK, onLevelButtonTriggered);
                buttons.push(levelButton);
                
                page.addChild(levelButton);
                
				m_buttonToLevelNode.set(levelButton, levelNode);
            }  
			
			// Layout all the buttons in the page  
			// The left padding depends on whether the levels buttons are on the left or right page.    
            // Those on left require more padding  
            viewBounds.x = 35;
            viewBounds.y = 170;
			// TODO: this layout will likely need to be fixed
            //m_buttonLayout.layout(buttons, viewBounds);
			buttons = new Array<DisplayObject>();
            
            outPages.push(page);
        }
    }
    
    private function getLevelSelectSectionMatchingGenre(genreId : String) : Dynamic
    {
        var matchingSection : Dynamic = null;
        var levelSelectSections : Array<Dynamic> = m_assetManager.getObject("level_select_config").sections;
        for (levelSelectSection in levelSelectSections)
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
    private function togglePrevNextPageButtonsEnabled() : Void
    {
        var enableNext : Bool = m_book.canGoToNextPage();
        m_nextPageHitArea.visible = enableNext;
        
        var enablePrev : Bool = m_book.canGoToPreviousPage();
        m_previousPageHitArea.visible = enablePrev;
    }
}
