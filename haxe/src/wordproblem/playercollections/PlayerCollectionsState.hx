package wordproblem.playercollections;


import flash.geom.Rectangle;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

import cgs.audio.Audio;

import dragonbox.common.state.BaseState;
import dragonbox.common.state.IStateMachine;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;
import dragonbox.common.util.XColor;

import feathers.controls.Button;
import feathers.controls.ToggleButton;
import feathers.display.Scale9Image;
import feathers.textures.Scale9Textures;

import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;
import starling.textures.Texture;

import wordproblem.achievements.PlayerAchievementsModel;
import wordproblem.currency.PlayerCurrencyModel;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.selector.ConcurrentSelector;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.widget.WidgetUtil;
import wordproblem.items.ItemDataSource;
import wordproblem.items.ItemInventory;
import wordproblem.level.controller.WordProblemCgsLevelManager;
import wordproblem.player.ButtonColorData;
import wordproblem.player.ChangeButtonColorScript;
import wordproblem.player.ChangeCursorScript;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.playercollections.scripts.PlayerCollectionCustomizeViewer;
import wordproblem.playercollections.scripts.PlayerCollectionItemViewer;
import wordproblem.playercollections.scripts.PlayerCollectionStatsViewer;
import wordproblem.playercollections.scripts.PlayerCollectionViewer;
import wordproblem.playercollections.scripts.PlayerCollectionsAchievementsViewer;
import wordproblem.resource.AssetManager;
import wordproblem.xp.PlayerXpModel;

class PlayerCollectionsState extends BaseState
{
    private var m_background : Image;
    
    /**
     * This is the screen from which all other subscreens will add content to.
     */
    private var m_canvasContainer : Sprite;
    
    /**
     * List of categories lining the top of the screen, player selects one to go to a particular
     * view.
     */
    private var m_categoryButtons : Array<ToggleButton>;
    
    /**
     * This button is used to back out of the collections screen and back
     * into the main level selection
     */
    private var m_backButton : Button;
    
    /**
     * Required to draw all the various items
     */
    private var m_assetManager : AssetManager;
    
    /**
     * This source is needed to draw all the items related to a collection.
     */
    private var m_itemDataSource : ItemDataSource;
    
    /**
     * This source is needed to figure out what items in the collection the player has actually
     * unlocked.
     */
    private var m_playerInventory : ItemInventory;
    
    private var m_exitCallback : Function;
    
    /**
     * Main root for some of the logic in the ui (i.e. controllers for the screens fit in here)
     */
    private var m_scriptRoot : ScriptNode;
    
    /**
     * The script controller the current view the player is looking at
     */
    private var m_activeViewerScript : PlayerCollectionViewer;
    
    /**
     * Keep track of elapsed time, used by other scripts
     */
    private var m_timer : Time;
    
    private var m_buttonColorData : ButtonColorData;
    private var m_lastEquippedColorValue : Int;
    
    public function new(stateMachine : IStateMachine,
            assetManager : AssetManager,
            mouseState : MouseState,
            levelManager : WordProblemCgsLevelManager,
            playerXpModel : PlayerXpModel,
            playerCurrencyModel : PlayerCurrencyModel,
            playerAchievementsModel : PlayerAchievementsModel,
            itemDataSource : ItemDataSource,
            playerInventory : ItemInventory,
            collectionInformation : Array<Dynamic>,
            customizablesInformation : Array<Dynamic>,
            playerStatsAndSaveData : PlayerStatsAndSaveData,
            changeCursorScript : ChangeCursorScript,
            changeButtonColorScript : ChangeButtonColorScript,
            exitCallback : Function,
            buttonColorData : ButtonColorData)
    {
        super(stateMachine);
        
        m_assetManager = assetManager;
        m_itemDataSource = itemDataSource;
        m_playerInventory = playerInventory;
        m_exitCallback = exitCallback;
        m_timer = new Time();
        m_buttonColorData = buttonColorData;
        m_lastEquippedColorValue = buttonColorData.getUpButtonColor();
        
        var screenWidth : Float = 800;
        var screenHeight : Float = 600;
        m_background = new Image(assetManager.getTexture("summary_background"));
        m_background.width = screenWidth;
        m_background.height = screenHeight;
        
        m_canvasContainer = new Sprite();
        
        m_scriptRoot = new ConcurrentSelector(-1);
        m_scriptRoot.pushChild(new PlayerCollectionStatsViewer(levelManager, playerXpModel, playerCurrencyModel, m_canvasContainer, m_assetManager, mouseState, m_timer, "PlayerCollectionStatsViewer", false));
        m_scriptRoot.pushChild(new PlayerCollectionItemViewer(collectionInformation, playerInventory, itemDataSource, m_canvasContainer, m_assetManager, mouseState, buttonColorData, "PlayerCollectionItemViewer", false));
        m_scriptRoot.pushChild(new PlayerCollectionsAchievementsViewer(playerAchievementsModel, m_canvasContainer, m_assetManager, mouseState, "PlayerCollectionAchievementsViewer", false));
        m_scriptRoot.pushChild(new PlayerCollectionCustomizeViewer(customizablesInformation, playerInventory, itemDataSource, playerCurrencyModel, 
                playerStatsAndSaveData, changeCursorScript, changeButtonColorScript, 
                m_canvasContainer, m_assetManager, mouseState, buttonColorData, "PlayerCollectionCustomizeViewer"));
    }
    
    override public function enter(fromState : Dynamic, params : Array<Dynamic> = null) : Void
    {
        addChildAt(m_background, 0);
        
        // Render the buttons for each category collection
        var buttonLabels : Array<String> = ["Stats", "Collectables", "Achievements", "Customize"];
        var buttonIconTextureNames : Array<String> = ["addition_icon", "cards_icon", "achievements_icon", "exclaimation_icon"];
        m_categoryButtons = new Array<ToggleButton>();
        
        var selectedTexture : Texture = m_assetManager.getTexture("button_white");
        var selectedScale9Texture : Scale9Textures = new Scale9Textures(selectedTexture, new Rectangle(8, 8, 16, 16));
        var i : Int;
        var fontSize : Int = 20;
        for (i in 0...buttonLabels.length){
            var categoryButtonWidth : Float = 170;
            var categoryButtonHeight : Float = 40;
            var categoryToggleButton : ToggleButton = try cast(WidgetUtil.createGenericColoredButton(
                    m_assetManager,
                    m_buttonColorData.getUpButtonColor(),
                    buttonLabels[i],
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, fontSize, 0xFFFFFF),
                    new TextFormat(GameFonts.DEFAULT_FONT_NAME, fontSize, 0xFFFFFF),
                    true
                    ), ToggleButton) catch(e:Dynamic) null;
            categoryToggleButton.isToggle = true;
            m_categoryButtons.push(categoryToggleButton);
            
            var categoryIconTexture : Texture = m_assetManager.getTexture(buttonIconTextureNames[i]);
            var iconScale : Float = (categoryButtonHeight * 0.9) / categoryIconTexture.height;
            var categoryIcon : Image = new Image(categoryIconTexture);
            categoryIcon.scaleX = categoryIcon.scaleY = iconScale;
            categoryToggleButton.defaultIcon = categoryIcon;
            categoryToggleButton.iconOffsetX = categoryIconTexture.width * iconScale * 0.6;
            
            // Set a selection skin
            var defaultSelectedImage : Scale9Image = new Scale9Image(selectedScale9Texture);
            defaultSelectedImage.color = XColor.shadeColor(m_buttonColorData.getUpButtonColor(), 1.0);
            categoryToggleButton.defaultSelectedSkin = defaultSelectedImage;
            categoryToggleButton.defaultSelectedLabelProperties = {
                        textFormat : new TextFormat(GameFonts.DEFAULT_FONT_NAME, fontSize, 0x000000, null, null, null, null, null, TextFormatAlign.CENTER)

                    };
            categoryToggleButton.width = categoryButtonWidth;
            categoryToggleButton.height = categoryButtonHeight;
            categoryToggleButton.addEventListener(Event.TRIGGERED, onCategorySelected);
        }
        
        var backButtonWidth : Float = 60;
        var backButtonHeight : Float = 60;
        var homeIcon : Image = new Image(m_assetManager.getTexture("home_icon"));
        var iconScaleTarget : Float = (backButtonHeight * 0.8) / homeIcon.height;
        homeIcon.scaleX = homeIcon.scaleY = iconScaleTarget;
        var backButton : Button = WidgetUtil.createGenericColoredButton(m_assetManager, m_buttonColorData.getUpButtonColor(), null, null);
        backButton.defaultIcon = homeIcon;
        backButton.width = backButtonWidth;
        backButton.height = backButtonHeight;
        backButton.x = m_background.width - backButtonWidth;
        backButton.y = m_background.height - backButtonHeight;
        m_backButton = backButton;
        
        m_canvasContainer.y = 60;
        addChild(m_canvasContainer);
        addChild(m_backButton);
        m_backButton.addEventListener(Event.TRIGGERED, onBackButtonClicked);
        
        var numCategories : Int = m_categoryButtons.length;
        var totalButtonWidth : Float = 0;
        var buttonGap : Float = 20;
        for (i in 0...numCategories){
            totalButtonWidth += m_categoryButtons[i].width;
            if (i > 0) 
            {
                totalButtonWidth += buttonGap;
            }
        }
        
        var xOffset : Float = (800 - totalButtonWidth) * 0.5;
        for (i in 0...numCategories){
            var categoryButton : Button = m_categoryButtons[i];
            categoryButton.x = xOffset;
            xOffset += buttonGap + categoryButton.width;
            addChild(categoryButton);
        }
        
        changeToViewerFromSelectedButton(m_categoryButtons[1]);
        m_categoryButtons[1].isSelected = true;
    }
    
    override public function exit(toState : Dynamic) : Void
    {
        m_background.removeFromParent();
        m_canvasContainer.removeFromParent();
        m_backButton.removeFromParent();
        m_backButton.removeEventListener(Event.TRIGGERED, onBackButtonClicked);
        
        // Delete the category buttons (they will be recreated later if necessary)
        for (categoryButton in m_categoryButtons)
        {
            categoryButton.removeEventListeners();
            categoryButton.removeFromParent(true);
        }
        as3hx.Compat.setArrayLength(m_categoryButtons, 0);
        
        // Clean up the active screen
        if (m_activeViewerScript != null) 
        {
            m_activeViewerScript.hide();
            m_activeViewerScript = null;
        }
    }
    
    override public function update(time : Time, mouseState : MouseState) : Void
    {
        m_timer.update();
        
        // Scripts will control most of the logic behind the screen.
        // They need to be updated as part of this loop
        m_scriptRoot.visit();
        
        // Check if the equipped color changed
        if (m_lastEquippedColorValue != m_buttonColorData.getUpButtonColor()) 
        {
            m_lastEquippedColorValue = m_buttonColorData.getUpButtonColor();
            
            // HACK:
            // We know we just need to refresh the colors of the top category buttons
            // and the home button
            for (categoryButton in m_categoryButtons)
            {
                WidgetUtil.changeColorForGenericButton(categoryButton, m_lastEquippedColorValue);
                
                if (Std.is(categoryButton, ToggleButton)) 
                {
                    (try cast((try cast(categoryButton, ToggleButton) catch(e:Dynamic) null).defaultSelectedSkin, Scale9Image) catch(e:Dynamic) null).color = XColor.shadeColor(m_buttonColorData.getUpButtonColor(), 1.0);
                }
            }
            WidgetUtil.changeColorForGenericButton(m_backButton, m_lastEquippedColorValue);
        }
    }
    
    private function onBackButtonClicked() : Void
    {
        Audio.instance.playSfx("button_click");
        m_exitCallback();
    }
    
    private function onCategorySelected(event : Event) : Void
    {
        Audio.instance.playSfx("button_click");
        var targetButton : Button = try cast(event.currentTarget, ToggleButton) catch(e:Dynamic) null;
        changeToViewerFromSelectedButton(targetButton);
    }
    
    private function changeToViewerFromSelectedButton(targetButton : Button) : Void
    {
        // BUG: For some reason setting isSelected to true removes the select state
        // Go through the buttons and set them to the correct selected/unselected value
        for (categoryButton in m_categoryButtons)
        {
            if (targetButton != categoryButton) 
            {
                categoryButton.isEnabled = true;
                categoryButton.isSelected = false;
            }
            else if (!categoryButton.isSelected) 
            {
                categoryButton.isEnabled = false;
            }
        }  // The index of the button will match the index of the script to execute  
        
        
        
        var targetIndex : Int = Lambda.indexOf(m_categoryButtons, try cast(targetButton, ToggleButton) catch(e:Dynamic) null);
        var viewerScript : PlayerCollectionViewer = try cast(m_scriptRoot.getChildren()[targetIndex], PlayerCollectionViewer) catch(e:Dynamic) null;
        
        // From the selected category, activate the appropriate screen if it is not already active
        if (m_activeViewerScript != viewerScript) 
        {
            if (m_activeViewerScript != null) 
            {
                m_activeViewerScript.hide();
            }
            
            viewerScript.show();
            m_activeViewerScript = viewerScript;
        }
    }
}
