package wordproblem.state;


import flash.display.Stage;
import flash.geom.Rectangle;
import flash.text.TextFormat;

import cgs.audio.Audio;
import cgs.internationalization.StringTable;
import cgs.levelProgression.nodes.ICgsLevelNode;

import dragonbox.common.state.BaseState;
import dragonbox.common.state.IStateMachine;
import dragonbox.common.time.Time;
import dragonbox.common.ui.LogoutWidget;
import dragonbox.common.ui.MouseState;
import dragonbox.common.util.XColor;

import starling.animation.Juggler;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Quad;
import starling.display.Sprite;
import starling.text.TextField;

import wordproblem.AlgebraAdventureConfig;
import wordproblem.credits.CreditsWidget;
import wordproblem.display.Layer;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.selector.ConcurrentSelector;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.widget.ConfirmationWidget;
import wordproblem.event.CommandEvent;
import wordproblem.event.LevelSelectEvent;
import wordproblem.items.ItemDataSource;
import wordproblem.items.ItemInventory;
import wordproblem.level.controller.WordProblemCgsLevelManager;
import wordproblem.level.nodes.GenreLevelPack;
import wordproblem.levelselect.GenreWidget;
import wordproblem.levelselect.scripts.LevelSelectCharacterSequence;
import wordproblem.log.AlgebraAdventureLogger;
import wordproblem.player.ButtonColorData;
import wordproblem.resource.AssetManager;
import wordproblem.settings.OptionsWidget;

/**
 * This class acts like the level select screen (This will need to be revised to incorporate several of 
 * the animations)
 */
class WordProblemSelectState extends BaseState
{
    private var m_config : AlgebraAdventureConfig;
    
    /** 
     * The selection state need to access the actual graph structure of the levels
     * to properly render the ui. For example the level graph has a parent node for each
     * genre. Will need to manually walk this walk to know what levels belong to a certain genre.
     */
    private var m_levelManager : WordProblemCgsLevelManager;
    
    /**
     * Used to fetch resources to render the level select.
     */
    private var m_assetManager : AssetManager;
    
    /**
     * IMPORTANT: This class directly modifies the level select config and uses that as a cache
     * 
     * keys per element:
     * hitArea: Keep track of the hit areas for each genre. When this hit area is clicked on, then
     * we should open up a level select screen.
     * 
     * hoverName: When a player hovers over a genre, if applicable show the name of the genre they are over.
     * 
     * hoverBackgroundImage: When the player hovers over a particular area in the level select we swap of the background
     * with an image that has the hovered section colored. This is a stopgap solution as it requires an entire 
     * background for each hoverable area.
     * 
     * genreNode: Need some way to link the button that was selected to the node containing information
     * about the genre.
     * 
     * linkToId: Special id to indicate behavior when a section is selection, copied from the level select config
     */
    private var m_cachedDataObjectsForLevelSelect : Array<Dynamic>;
    
    /**
     * This is a reference to the sub-screen that gets opened when the player selects a specific genre.
     */
    private var m_currentGenreWidget : GenreWidget;
    
    /**
     * The level select will display the items the player has earned throughout play as rewards.
     * 
     * Also has fixed item entities that will appear for every player. For example, the box prop in the
     * dragonbox shelf.
     */
    private var m_playerItemInventory : ItemInventory;
    
    /**
     * An in-memory db of all the items that can be acquired. Used to help render player items in
     * this screen.
     */
    private var m_itemDataSource : ItemDataSource;
    
    /**
     * The root sequence of scripts that should execute while in the level selection state.
     */
    private var m_prebakedScripts : ScriptNode;
    
    /**
     * The place where we want to swap in and out various pieces in the background layer.
     */
    private var m_backgroundLayer : Layer;
    
    /**
     * Keep reference to un-modified background so we can revert back to it at anytime.
     */
    private var m_originalBackgroundImage : Image;
    
    /**
     * This is the place where player rewards are pasted. Appears between the background and foreground
     */
    private var m_rewardLayer : Layer;
    
    /**
     * The place where all dialogs are added. Appears on top of everything except the options screen
     */
    private var m_calloutLayer : Sprite;
    
    /**
     * This is the layer to add the options submenu
     * 
     * (These things should block out the genres from being selected or hover over)
     */
    private var m_foregroundLayer : Layer;
    
    /**
     * Screen to show credits
     */
    private var m_credits : CreditsWidget;
    
    /**
     * Screen to ask the user if they are ok with resetting the game
     */
    private var m_resetConfirmationWidget : ConfirmationWidget;
    
    /**
     * Overlay for options.
     */
    private var m_optionsWidget : OptionsWidget;
    
    /**
     * Overlay to show user's name and the option to sign out
     */
    private var m_logoutWidget : LogoutWidget;
    
    /**
     * Screen to ask the user if they are ok with restting the game
     */
    private var m_logoutConfirmationWidget : ConfirmationWidget;
    
    /**
     * Need the user to pass out the credentials to dragonbox
     */
    private var m_logger : AlgebraAdventureLogger;
    
    /**
     * By toggling the active flag, the update loop of this state is disabled.
     * Useful if we don't want this screen to detect mouse interaction like when the register screen
     * is put on top.
     */
    public var isActive : Bool = true;
    
    /**
     * Have a custom juggler that animates all spritesheets in this screen
     * (Right now just the hamster characters)
     */
    private var m_spritesheetJuggler : Juggler;
    
    private var m_flashStage : flash.display.Stage;
    
    /**
     * This data is needed to adjust the color of several buttons to a user selected color
     */
    private var m_buttonColorData : ButtonColorData;
    
    public function new(stateMachine : IStateMachine,
            config : AlgebraAdventureConfig,
            levelManager : WordProblemCgsLevelManager,
            resourceManager : AssetManager,
            playerItemInventory : ItemInventory,
            itemDataSource : ItemDataSource,
            logger : AlgebraAdventureLogger,
            flashStage : flash.display.Stage,
            buttonColorData : ButtonColorData)
    {
        super(stateMachine);
        
        m_config = config;
        m_levelManager = levelManager;
        m_assetManager = resourceManager;
        m_playerItemInventory = playerItemInventory;
        m_itemDataSource = itemDataSource;
        m_logger = logger;
        m_flashStage = flashStage;
        m_buttonColorData = buttonColorData;
        
        m_spritesheetJuggler = new Juggler();
        
        // Create layers once
        m_rewardLayer = new Layer();
        m_calloutLayer = new Sprite();
        m_foregroundLayer = new Layer();
        
        // Initialize scripted logic
        // Re-use the same scripts for the entire session, just don't update them when not in this screen
        var prebakedRootScript : ScriptNode = new ConcurrentSelector(-1);
        prebakedRootScript.pushChild(new LevelSelectCharacterSequence(m_assetManager, this, levelManager, m_spritesheetJuggler));
        m_prebakedScripts = prebakedRootScript;
    }
    
    /**
     * 
     * @param params
     *      If it exists, the first param is a data blob to indicate where.
     *      levelIndex, chapterIndex, genre
     */
    override public function enter(fromState : Dynamic, params : Array<Dynamic> = null) : Void
    {
        m_currentGenreWidget = new GenreWidget(
            m_assetManager, 
            m_levelManager, 
            m_playerItemInventory, 
            m_itemDataSource, 
            onCloseGenreWidgetCallback, 
            onStartLevelGenreWidgetCallback, 
            m_buttonColorData.getUpButtonColor()
        );
        
        // Draw a temp background
        m_backgroundLayer = new Layer();
        addChild(m_backgroundLayer);
        
        // Add library shelf background image
        m_originalBackgroundImage = new Image(m_assetManager.getTexture("library_bg.png"));
        m_backgroundLayer.addChild(m_originalBackgroundImage);
        
        // Create middle layer where scripts can paste new objects into the level select
        m_rewardLayer.removeChildren();
        addChild(m_rewardLayer);
        
        // Create the layer
        m_calloutLayer.removeChildren();
        addChild(m_calloutLayer);
        
        // Create foreground
        m_foregroundLayer.removeChildren();
        addChild(m_foregroundLayer);
        
        m_cachedDataObjectsForLevelSelect = new Array<Dynamic>();
        
        // Grab all the genre nodes, this will help us define all the clickable areas
        var outGenreNodes : Array<GenreLevelPack> = new Array<GenreLevelPack>();
        m_levelManager.getGenreNodes(outGenreNodes);
        
        // Look at the level select to configure the hit areas and label rendering of this screen
        var levelSelectConfig : Dynamic = m_assetManager.getObject("level_select_config");
        var sectionsInLevelSelect : Array<Dynamic> = levelSelectConfig.sections;
        var numSections : Int = sectionsInLevelSelect.length;
        for (sectionInLevelSelect in sectionsInLevelSelect)
        {
            var cachedObjectForSection : Dynamic = { };
            
            // If genre is locked it should not be clickable
            var hitAreaData : Dynamic = sectionInLevelSelect.hitArea;
            var hitArea : Rectangle = new Rectangle(hitAreaData.x, hitAreaData.y, hitAreaData.width, hitAreaData.height);
            cachedObjectForSection.hitArea = hitArea;
            
            // For each hit area, assign the background image containing the proper colored hover area
            cachedObjectForSection.hoverBackgroundImage = new Image(m_assetManager.getTexture(sectionInLevelSelect.hoverBackgroundTexture));
			
			// Check if the genre has a name display object that should be shown on hover over
            var hoverTextDisplay : DisplayObject = null;
            if (sectionInLevelSelect.exists("hoverTextArea")) 
            {
                var textAreaRectangle : Dynamic = sectionInLevelSelect.hoverTextArea;
                var hoverTextField : TextField = new TextField(
					textAreaRectangle.width, 
					textAreaRectangle.height, 
					sectionInLevelSelect.title, 
					GameFonts.DEFAULT_FONT_NAME, 
					((textAreaRectangle.exists("fontSize"))) ? textAreaRectangle.fontSize : 32, 
					0xFFFFFF
                );
                hoverTextField.x = textAreaRectangle.x + sectionInLevelSelect.hitArea.x;
                hoverTextField.y = textAreaRectangle.y + sectionInLevelSelect.hitArea.y;
                hoverTextDisplay = hoverTextField;
            }
            
            cachedObjectForSection.hoverTextDisplay = hoverTextDisplay;
            m_calloutLayer.addChild(hoverTextDisplay);
            
            for (playableGenreLevels in outGenreNodes)
            {
                if (playableGenreLevels.getThemeId() == sectionInLevelSelect.linkToId) 
                {
                    cachedObjectForSection.genreNode = playableGenreLevels;
                    
                    // If genre locked, add a disabling sprite on top of the hit area for a genre
                    if (playableGenreLevels.isLocked) 
                    {
                        var disableQuad : Quad = new Quad(hitAreaData.width, hitAreaData.height, 0x000000);
                        disableQuad.alpha = 0.8;
                        disableQuad.x = hitAreaData.x;
                        disableQuad.y = hitAreaData.y;
                        
                        var lockImage : Image = new Image(m_assetManager.getTexture("level_button_lock.png"));
                        lockImage.pivotX = lockImage.width * 0.5;
                        lockImage.pivotY = lockImage.height * 0.5;
                        lockImage.x = disableQuad.x + hitAreaData.width * 0.5;
                        lockImage.y = disableQuad.y + hitAreaData.height * 0.5;
                        
                        m_calloutLayer.addChild(disableQuad);
                        m_calloutLayer.addChild(lockImage);
                    }
                    break;
                }
            }
            
            cachedObjectForSection.linkToId = sectionInLevelSelect.linkToId;
            m_cachedDataObjectsForLevelSelect.push(cachedObjectForSection);
        }
        
        var optionNames : Array<String> = [OptionsWidget.OPTION_MUSIC, OptionsWidget.OPTION_SFX, OptionsWidget.OPTION_CREDITS];
        if (m_config.getAllowResetData()) 
        {
            optionNames.push(OptionsWidget.OPTION_RESET);
        }  // Create the options button on top most layer  
        
        
        
        var optionsWidget : OptionsWidget = new OptionsWidget(
			m_assetManager, 
			optionNames, 
			onCreditsClicked, 
			onResetClicked, 
			m_buttonColorData.getUpButtonColor()
        );
        optionsWidget.x = 0;
        optionsWidget.y = m_originalBackgroundImage.height - optionsWidget.height;
        m_foregroundLayer.addChild(optionsWidget);
        m_optionsWidget = optionsWidget;
        
        // Screen to show credits
        m_credits = new CreditsWidget(
            m_config.getWidth(), 
            m_config.getHeight(), 
            m_assetManager, 
            null, 
            m_buttonColorData.getUpButtonColor()
        );
        
        m_resetConfirmationWidget = new ConfirmationWidget(
                m_config.getWidth(), 
                m_config.getHeight(), 
                function() : DisplayObject
                {
                    var contentTextField : TextField = new TextField(
						400, 
						200, 
						// TODO: uncomment when cgs library is finished
						"",//StringTable.lookup("reset_data_warning"), 
						GameFonts.DEFAULT_FONT_NAME, 
						30, 
						0xFFFFFF
						);
                    return contentTextField;
				}, 
				function() : Void
				{
					// Perform reset
					m_foregroundLayer.removeChild(m_resetConfirmationWidget);
					
					// Just forward logic to upper level class
					dispatchEventWith(CommandEvent.RESET_DATA);
				}, 
				function() : Void
				{
					m_foregroundLayer.removeChild(m_resetConfirmationWidget);
				}, 
				m_assetManager, 
				m_buttonColorData.getUpButtonColor(), 
				// TODO: uncomment when cgs library is finished
				"", ""//StringTable.lookup("yes"), StringTable.lookup("no")
        );
        
        // Ui for the player to logout
        m_logoutWidget = new LogoutWidget(
            m_logger.getCgsUser(), 
            m_config.showUserNameInSelectScreen, 
            new TextFormat(GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF, true, null, true), 
            new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, 0x5CBFF8, true), 
            new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, 0xFFFFFF, true, null, true), 
            function() : Void
            {
                m_foregroundLayer.addChild(m_logoutConfirmationWidget);
            }, 
            function() : Void
            {
                // Go to the create account screen
                dispatchEventWith(CommandEvent.SHOW_ACCOUNT_CREATE);
            }
        );
        m_logoutWidget.x = ((m_config.showUserNameInSelectScreen)) ? 510 : 600;
        m_logoutWidget.y = 0;
        var flashToStarlingScale : Float = Starling.current.viewPort.width / m_flashStage.width;
        m_logoutWidget.x *= flashToStarlingScale;
        //m_flashStage.addChild(m_logoutWidget);
        
        m_logoutConfirmationWidget = new ConfirmationWidget(
            m_config.getWidth(), 
            m_config.getHeight(), 
            function() : DisplayObject
            {
                var contentTextField : TextField = new TextField(
					400, 
					200, 
					// TODO: uncomment when cgs library is finished
					"",//StringTable.lookup("signout_warning"), 
					GameFonts.DEFAULT_FONT_NAME, 
					30, 
					0xFFFFFF
                );
                return contentTextField;
            }, 
            function() : Void
            {
                // Sign out from the current account, clear on data on the client side only
                dispatchEventWith(CommandEvent.SIGN_OUT);
                m_foregroundLayer.removeChild(m_logoutConfirmationWidget);
            }, 
            function() : Void
            {
                m_foregroundLayer.removeChild(m_logoutConfirmationWidget);
            }, 
			// TODO: uncomment when cgs library is finished
            m_assetManager, XColor.ROYAL_BLUE, "", ""//StringTable.lookup("yes"), StringTable.lookup("no")
        );
        
        // Play background music
        // If background music is already playing do not restart it
        //An update of CgsCommon eliminated the getCurrentMusicTypeName call. 7/1/2014 RAD
        if (Audio.instance.getCurrentMusicTypeName() != "bg_home_music") 
        {
            Audio.instance.playMusic("bg_home_music");
        }  // Restart scripts  
        
        
        
        m_prebakedScripts.setIsActive(true);
        
        // In some situations we have a saved genre and page that the player was at.
        // For example if they open and play a fantasy level and exit, they should
        // return with the fantasy book opened at the page they were at.
        if (params != null && params.length > 0) 
        {
            var openGenreWidgetData : Dynamic = params[0];
            openGenreWidgetData.levelIndex;
            var chapterIndex : Int = openGenreWidgetData.chapterIndex;
            var genreNode : ICgsLevelNode = m_levelManager.getNodeByName(openGenreWidgetData.genre);
            if (openGenreWidgetData.exists("levelIndex") && m_currentGenreWidget != null) 
            {
                m_currentGenreWidget.setGenre(try cast(genreNode, GenreLevelPack) catch(e:Dynamic) null, chapterIndex);
                m_foregroundLayer.addChild(m_currentGenreWidget);
            }
        }
    }
    
    override public function exit(toState : Dynamic) : Void
    {
        // Clean up the background images
        var i : Int = 0;
        for (i in 0...m_cachedDataObjectsForLevelSelect.length){
            var bgImage : Image = try cast(m_cachedDataObjectsForLevelSelect[i].hoverBackgroundImage, Image) catch(e:Dynamic) null;
            bgImage.dispose();
        }
        
        while (this.numChildren > 0)
        {
            removeChildAt(0);
        }
		
		// Remove objects added to flash stage  
        if (m_logoutWidget.parent != null) 
        {
            m_logoutWidget.parent.removeChild(m_logoutWidget);
        }
        m_logoutWidget.dispose();
        
        // Stop background music
        Audio.instance.reset();
        
        // Clear out reward layer
        m_rewardLayer.removeChildren();
        
        // Set all scripts to not active
        m_prebakedScripts.setIsActive(false);
        
        // TODO:
        // Dispose of the visual elements (their textures need to be freed from memory)
        // They need to get recreated the next time we enter this screen
        m_currentGenreWidget.removeFromParent(true);
    }
    
    override public function update(time : Time, mouseState : MouseState) : Void
    {
        if (!isActive) 
        {
            return;
        }  // Advance time for all the spritesheets  
        
        
        
        m_spritesheetJuggler.advanceTime(time.currentDeltaSeconds);
        
        // Execute logic in the scripts contained only in the level select
        // (For example a script might have the code to draw the reward creatures)
        m_prebakedScripts.visit();
        
        // Mouse detection for important sections of the screen
        // First check that a genre is not already being displayed
        if (m_currentGenreWidget.parent == null) 
        {
            // Check if the player has their mouse over one of the hit areas
            // AND the mouse is not blocked by any upper layer
            var i : Int = 0;
            var hitArea : Rectangle = null;
            var hitAnArea : Bool = false;
            for (i in 0...m_cachedDataObjectsForLevelSelect.length){
                var cachedDataForSection : Dynamic = m_cachedDataObjectsForLevelSelect[i];
                hitArea = cachedDataForSection.hitArea;
                
                var selectedGenre : GenreLevelPack = ((cachedDataForSection.exists("genreNode"))) ? 
                cachedDataForSection.genreNode : null;
                
                // If genre is locked clicks and hovers should have no effect
                if (selectedGenre != null && selectedGenre.isLocked) 
                {
                    continue;
                }
                
                if (m_rewardLayer.activeForFrame && hitArea.contains(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y)) 
                {
                    hitAnArea = true;
                    
                    if (mouseState.leftMousePressedThisFrame) 
                    {
                        // On click open the level select for that world
                        if (selectedGenre != null) 
                        {
                            m_currentGenreWidget.setGenre(selectedGenre, -1);
                            m_foregroundLayer.addChild(m_currentGenreWidget);
                            
                            this.dispatchEventWith(LevelSelectEvent.OPEN_GENRE, false, selectedGenre);
                            
                            Audio.instance.playSfx("book_open");
                        }
                        // The selection section should have a link to id. Use this id to determine behavior
                        // when selected
                        else 
                        {
                            if (cachedDataForSection.linkToId == "player_collections") 
                            {
                                this.dispatchEventWith(CommandEvent.GO_TO_PLAYER_COLLECTIONS);
                            }
                        }
                    }
                    else 
                    {
                        // On hover check if the background needs to change,
                        // Right now assume that background layer contains exactly one child
                        var backgroundImageToChangeTo : Image = cachedDataForSection.hoverBackgroundImage;
                        if (m_backgroundLayer.getChildAt(0) != backgroundImageToChangeTo) 
                        {
                            m_backgroundLayer.removeChildren();
                            m_backgroundLayer.addChild(backgroundImageToChangeTo);
                        }
                    }
                    break;
                }
            }  // If we did not hit anything, revert back to the regular background  
            
            
            
            if (!hitAnArea) 
            {
                if (m_backgroundLayer.getChildAt(0) != m_originalBackgroundImage) 
                {
                    m_backgroundLayer.removeChildren();
                    m_backgroundLayer.addChild(m_originalBackgroundImage);
                }
            }
        }
        else 
        {
            m_currentGenreWidget.update(mouseState);
        }  // If click outside the bounds of the options, the options menu should close  
        
        
        
        if (mouseState.leftMousePressedThisFrame && m_optionsWidget.isOpen()) 
        {
            var optionBounds : Rectangle = m_optionsWidget.getBounds(m_optionsWidget.stage);
            if (!optionBounds.contains(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y)) 
            {
                m_optionsWidget.toggleOptionsOpen(false);
            }
        }
    }
    
    /**
     * Expose the middle layer as various scripts need to get at this to paste the rewards a
     * player has earned
     * 
     * @return
     *      The layer in which to add things into the background. Anything added here should appear
     *      on top of the book shelf images but behind foreground elements like the credits screen
     */
    public function getRewardLayer() : Layer
    {
        return m_rewardLayer;
    }
    
    /**
     * Get the layer to add all dialogs 
     */
    public function getCalloutLayer() : Sprite
    {
        return m_calloutLayer;
    }
    
    private function onCloseGenreWidgetCallback() : Void
    {
        m_currentGenreWidget.removeFromParent();
        this.dispatchEventWith(LevelSelectEvent.CLOSE_GENRE, false, null);
    }
    
    private function onStartLevelGenreWidgetCallback(levelName : String) : Void
    {
        // TODO: Add the genre and page number the player was at when they selected the level
        
        this.dispatchEventWith(CommandEvent.GO_TO_LEVEL, false, levelName);
    }
    
    private function onCreditsClicked() : Void
    {
        // Paste the credits screen on top
        m_foregroundLayer.addChild(m_credits);
    }
    
    private function onResetClicked() : Void
    {
        // Show the confirmation of reset
        m_foregroundLayer.addChild(m_resetConfirmationWidget);
    }
}
