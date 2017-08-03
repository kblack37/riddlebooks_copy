package wordproblem.summary;


import flash.geom.Rectangle;
import flash.text.TextFormat;

import cgs.internationalization.StringTable;

import dragonbox.common.ui.MouseState;
import dragonbox.common.util.ListUtil;
import dragonbox.common.util.XColor;

import haxe.Constraints.Function;

import starling.display.Button;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.Event;
import starling.filters.BlurFilter;
import starling.text.TextField;
import starling.textures.Texture;

import wordproblem.display.Layer;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.widget.WidgetUtil;
import wordproblem.items.ItemDataSource;
import wordproblem.items.ItemInventory;
import wordproblem.resource.AssetManager;

/**
 * This screen shows the player all the new rewards that were earned after the completion
 * of the last level.
 */
class SummaryRewardsScreen extends Layer
{
    // HACK: We keep the width of all buttons as a fixed value
    private static inline var BUTTON_WIDTH : Float = 175;
    private static inline var ROWS : Int = 2;
    private static inline var COLUMNS : Int = 3;
    
    /**
     * Canvas in which to add new
     */
    private var m_displayParent : DisplayObjectContainer;
    
    private var m_playerItemInventory : ItemInventory;
    private var m_itemDataSource : ItemDataSource;
    
    private var m_assetManager : AssetManager;
    
    /**
     * This is the subscreen showing details about a particular reward, if not null then
     * the player is viewing the details.
     */
    private var m_activeRewardsDetailScreen : Sprite;
    
    /**
     * Button to dismiss the rewards.
     * 
     * Reused to dismiss the entire screen and also dismisses the 'subscreen' showing
     * details about a particular reward.
     */
    private var m_rewardsDismissButton : Button;
    
    /**
     * Upon clicking an object in reward scroller we will popup an extra screen to show
     * details about that reward.
     * 
     * This maps links the clicked object id to extra data about what the reward represents
     * Key: String id of the object
     * Value: Object with extra data of how to render the additional popup
     */
    private var m_renderComponentIdToData : Map<String, Dynamic>;
    
    /**
     * Between a new draw call and before a reset call we need to keep track of the textures of rewards
     * that were used. Only care about reward images since those are the ones that take up the most space
     * while also being the least frequently used.
     * 
     * key: name of texture
     * value: true if texture was a TextureAtlas, false otherwise
     */
    private var m_itemTextureNamesUsedBuffer : Map<String, Bool>;
    
    /**
     * This is the list of all display objects that are the visual representation of the rewards
     * earned. Clicking on these will trigger another screen to view details about that reward
     */
    private var m_rewardButtonsInCurrentPage : Array<BaseRewardButton>;
    private var m_currentPageIndex : Int;
    private var m_rewardButtonHitBuffer : Rectangle;
    private var m_rewardIdsPerPage : Array<Array<String>>;
    
    /**
     * This is the list of data objects representing all the rewards that are to be given
     */
    private var m_rewardDataModels : Array<Dynamic>;
    
    /**
     * Title describing rewards given after the completion of a level.
     */
    private var m_rewardsTitle : TextField;
    
    /**
     * Button to go to the previous page of content
     */
    private var m_scrollLeftButton : Button;
    
    /**
     * Button to go to the next page of content
     */
    private var m_scrollRightButton : Button;
    
    private var m_closeCallback : Function;
    
    /**
     * To get the mouse over animations/graphics we keep track of which button the
     * mouse is currently over
     */
    private var m_currentRewardButtonMousedOver : BaseRewardButton;
    private var m_currentRewardButtonPressed : BaseRewardButton;
    
    public function new(totalScreenWidth : Float,
            totalScreenHeight : Float,
            displayParent : DisplayObjectContainer,
            playerItemInventory : ItemInventory,
            itemDataSource : ItemDataSource,
            assetManager : AssetManager,
            closeCallback : Function)
    {
        super();
        
        m_displayParent = displayParent;
        m_playerItemInventory = playerItemInventory;
        m_itemDataSource = itemDataSource;
        m_assetManager = assetManager;
        m_renderComponentIdToData = new Map();
        m_itemTextureNamesUsedBuffer = new Map();
        m_rewardButtonsInCurrentPage = new Array<BaseRewardButton>();
        m_rewardButtonHitBuffer = new Rectangle();
        m_rewardDataModels = new Array<Dynamic>();
		// TODO: uncomment when cgs library is finished
        m_rewardsTitle = new TextField(800, 60, "", /*StringTable.lookup("rewards")*/ GameFonts.DEFAULT_FONT_NAME, 32, 0xFFFFFF);
        m_closeCallback = closeCallback;
        
        // Add transparent background to block events below
        var disablingQuad : Quad = new Quad(totalScreenWidth, totalScreenHeight, 0x000000);
        disablingQuad.alpha = 0.8;
        addChild(disablingQuad);
        
        m_rewardsDismissButton = WidgetUtil.createGenericColoredButton(
                        assetManager,
                        XColor.ROYAL_BLUE,
						// TODO: uncomment when cgs library is finished
                        "",//StringTable.lookup("ok"),
                        new TextFormat(GameFonts.DEFAULT_FONT_NAME, 32, 0xFFFFFF),
                        null
                        );
        m_rewardsDismissButton.width = 200;
        m_rewardsDismissButton.height = 70;
        m_rewardsDismissButton.x = (totalScreenWidth - m_rewardsDismissButton.width) * 0.5;
        m_rewardsDismissButton.y = totalScreenHeight - m_rewardsDismissButton.height * 1.5;
        m_rewardsDismissButton.addEventListener(Event.TRIGGERED, onRewardDismissClick);
        
        var arrowTexture : Texture = assetManager.getTexture("assets/ui/arrow_short.png");
        var scaleFactor : Float = 1.5;
        var leftUpImage : Image = WidgetUtil.createPointingArrow(arrowTexture, true, scaleFactor);
        var leftOverImage : Image = WidgetUtil.createPointingArrow(arrowTexture, true, scaleFactor, 0xCCCCCC);
        
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
        m_scrollLeftButton.addEventListener(Event.TRIGGERED, onScrollLeftButtonClicked);
        
        var rightUpImage : Image = WidgetUtil.createPointingArrow(arrowTexture, false, scaleFactor, 0xFFFFFF);
        var rightOverImage : Image = WidgetUtil.createPointingArrow(arrowTexture, false, scaleFactor, 0xCCCCCC);
        m_scrollRightButton = WidgetUtil.createButtonFromImages(
                        rightUpImage,
                        rightOverImage,
                        null,
                        rightOverImage,
                        null,
                        null,
                        null
                        );
        m_scrollRightButton.x = totalScreenWidth - rightUpImage.width;
        m_scrollRightButton.y = m_scrollLeftButton.y;
        m_scrollRightButton.scaleWhenDown = m_scrollLeftButton.scaleWhenDown;
        m_scrollRightButton.addEventListener(Event.TRIGGERED, onScrollRightButtonClicked);
    }
    
    /**
     * Update so this screen can process real time mouse events.
     * Used to see if the user has clicked on the reward buttons
     */
    public function update(mouseState : MouseState) : Void
    {
        if (m_activeRewardsDetailScreen == null && this.stage != null) 
        {
            // Only check the buttons visible on the currently active page
            var buttonMouseIsOverThisFrame : BaseRewardButton = null;
            var i : Int = 0;
            var numRewards : Int = m_rewardButtonsInCurrentPage.length;
            for (i in 0...numRewards){
                // Go through and set the hit areas after layout is finished
                var rewardButton : BaseRewardButton = m_rewardButtonsInCurrentPage[i];
                rewardButton.getBounds(this.stage, m_rewardButtonHitBuffer);
                
                if (m_rewardButtonHitBuffer.contains(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y)) 
                {
                    buttonMouseIsOverThisFrame = rewardButton;
                    if (m_currentRewardButtonMousedOver != buttonMouseIsOverThisFrame) 
                    {
                        clearMouseOverRewardButtonState();
                        
                        m_currentRewardButtonMousedOver = buttonMouseIsOverThisFrame;
                        m_currentRewardButtonMousedOver.filter = BlurFilter.createGlow(0x00FF00, 1);
                    }  // with that item or just more info    // On press of a reward button, show a details screen that shows an animation  
                    
                    
                    
                    
                    
                    if (mouseState.leftMousePressedThisFrame) 
                    {
                        m_currentRewardButtonPressed = buttonMouseIsOverThisFrame;
                    }
                    else if (mouseState.leftMouseReleasedThisFrame && m_currentRewardButtonPressed == buttonMouseIsOverThisFrame) 
                    {
                        // Immediately display the new details screen
                        m_activeRewardsDetailScreen = rewardButton.getRewardDetailsScreen();
                        addChild(m_activeRewardsDetailScreen);
                        
                        // Make sure dismiss button is on top
                        addChild(m_rewardsDismissButton);
                        
                        // Make sure the reward buttons are temporarily removed
                        for (rewardButton in m_rewardButtonsInCurrentPage)
                        {
                            rewardButton.removeFromParent();
                        }  // Also remove the scroll buttons if present  
                        
                        
                        
                        m_scrollLeftButton.removeFromParent();
                        m_scrollRightButton.removeFromParent();
                    }
                    
                    break;
                }
            }
            
            if (mouseState.leftMouseReleasedThisFrame) 
            {
                m_currentRewardButtonPressed = null;
            }
            
            if (buttonMouseIsOverThisFrame == null) 
            {
                clearMouseOverRewardButtonState();
            }
        }
    }
    
    /**
     * As soon as the summary pops up, we need to call this immediately to set up starting data
     * about all the types of rewards we should be showing to the player.
     * 
     * Only need to do this once per instance the summary pops up.
     */
    public function setRewardsDataModels(earnedNewStar : Bool,
            newRewardItemIds : Array<String>,
            changedRewardEntityIds : Array<String>,
            previousStages : Array<Int>,
            currentStages : Array<Int>) : Void
    {
        // Clear out old models
		m_rewardDataModels = new Array<Dynamic>();
        
        // Create reward model data for each one of the types of rewards
        // There is an extra dirty property that when set to true should prompt
        // a redraw of the display
        
        // Stars may not be something we want to show anymore
        /*
        if (earnedNewStar)
        {
        var starModel:Object = {id:"star", type:"star", dirty:true};
        m_rewardDataModels.push(starModel);
        }
        */
        
        var i : Int = 0;
        for (i in 0...newRewardItemIds.length){
            // New items are intially hidden as presents
            // This hidden property is so we know whether the player has seen what the item
            // has been revealed as. In this case the button no longer needs to be drawn as a present
            var newItemModel : Dynamic = {
                type : "newItem",
                id : newRewardItemIds[i],
                hidden : true,
                dirty : true,

            };
            m_rewardDataModels.push(newItemModel);
        }
        
        for (i in 0...changedRewardEntityIds.length){
            // The hidden property for changed item means the player did not see the animation
            // of the item changing already
            var changedItemModel : Dynamic = {
                type : "changedItem",
                id : changedRewardEntityIds[i],
                prevStage : previousStages[i],
                currentStage : currentStages[i],
                hidden : true,
                dirty : true,

            };
            m_rewardDataModels.push(changedItemModel);
        }  // Paginate the rewards based on the given models  
        
        
        
        m_rewardIdsPerPage = new Array<Array<String>>();
        var rewardDataIds : Array<String> = new Array<String>();
        for (rewardModelData in m_rewardDataModels)
        {
            rewardDataIds.push(rewardModelData.id);
        }  // In this case we need to break things up into pages    // It is possible the number of rewards overflows what can fit on a single screen.    // Layout the reward buttons.  
        
        
        
        
        
        
        
        ListUtil.subdivideList(rewardDataIds, ROWS * COLUMNS, m_rewardIdsPerPage);
    }
    
    /**
     * Go through all data models, check which ones have been altered and then redraw the buttons
     * for them. Should be called anytime we suspect a change has occured
     */
    public function refreshAndLayoutButtons() : Void
    {
        // On redraw make sure to clear out the button hover state
        m_currentRewardButtonPressed = null;
        
        disposeButtons();
        drawButtonsAtCurrentPage(m_currentPageIndex);
        
        // Make sure dismiss button is on top
        addChild(m_rewardsDismissButton);
        
        // Add scroll button if there are multiple pages
        if (m_rewardIdsPerPage.length > 1) 
        {
            addChild(m_scrollLeftButton);
            addChild(m_scrollRightButton);
        }
    }
    
    private function clearMouseOverRewardButtonState() : Void
    {
        if (m_currentRewardButtonMousedOver != null) 
        {
            m_currentRewardButtonMousedOver.filter = null;
            m_currentRewardButtonMousedOver = null;
        }
    }
    
    private function disposeButtons() : Void
    {
        clearMouseOverRewardButtonState();
        
        // Clean out previous buttons and textures
        for (existingRewardButton in m_rewardButtonsInCurrentPage)
        {
            existingRewardButton.removeFromParent(true);
        }
		m_rewardButtonsInCurrentPage = new Array<BaseRewardButton>();
    }
    
    private function drawButtonsAtCurrentPage(pageIndex : Int) : Void
    {
        // Get the model data related to the id and then create the button from it
        var rewardsIdsInPage : Array<String> = m_rewardIdsPerPage[pageIndex];
        for (rewardId in rewardsIdsInPage)
        {
            for (rewardDataModel in m_rewardDataModels)
            {
                if (rewardId == rewardDataModel.id) 
                {
                    var rewardButton = createButton(rewardDataModel);
                    m_rewardButtonsInCurrentPage.push(rewardButton);
                }
            }
        }  // Layout the buttons  
        
        
        
        var expectedButtonWidth : Float = BUTTON_WIDTH;
        var expectedButtonHeight : Float = BUTTON_WIDTH;
        var buttonGap : Float = 40;
        var totalRowWidth : Float = COLUMNS * expectedButtonWidth + (COLUMNS - 1) * buttonGap;
        var totalColumnHeight : Float = ROWS * expectedButtonHeight + (ROWS - 1) * buttonGap;
        
        var xOffsetForNewRow : Float = (800 - totalRowWidth) * 0.5;
        var xOffset : Float = xOffsetForNewRow;
        var yOffset : Float = (500 - totalColumnHeight) * 0.5;
        for (i in 0...m_rewardButtonsInCurrentPage.length){
            var rewardButton : BaseRewardButton = m_rewardButtonsInCurrentPage[i];
            if (i % COLUMNS == 0 && i != 0) 
            {
                xOffset = xOffsetForNewRow;
                yOffset += expectedButtonHeight + 10;
            }
            rewardButton.x = xOffset;
            rewardButton.y = yOffset;
            addChild(rewardButton);
            
            xOffset += rewardButton.width + buttonGap;
        }
    }
    
    /**
     * Create a unique display button for a reward type
     */
    private function createButton(data : Dynamic) : BaseRewardButton
    {
        // Each reward type will have a different button
        var buttonEdgeLength : Float = BUTTON_WIDTH;
        var rewardButton : BaseRewardButton = null;
        var rewardType : String = data.type;
        if (rewardType == "star") 
        {
            rewardButton = new NewStarButton(buttonEdgeLength, data, m_assetManager);
        }
        else if (rewardType == "newItem") 
        {
            rewardButton = new NewItemButton(buttonEdgeLength, data, m_itemDataSource, m_assetManager);
        }
        else if (rewardType == "changedItem") 
        {
            rewardButton = new ChangedItemButton(buttonEdgeLength, data, m_itemDataSource, m_assetManager);
        }
        
        return rewardButton;
    }
    
    /**
     * This is called to show the reward screen
     */
    public function open() : Void
    {
        // Always start at the first page
        m_currentPageIndex = 0;
        
        m_displayParent.addChild(this);
        
        this.addChild(m_rewardsTitle);
        
        refreshAndLayoutButtons();
    }
    
    public function close() : Void
    {
        // Dispose of all reward model buttons and data models
		m_rewardDataModels = new Array<Dynamic>();
        disposeButtons();
        m_rewardsTitle.removeFromParent();
        m_displayParent.removeChild(this);
        
        m_scrollLeftButton.removeFromParent();
        m_scrollRightButton.removeFromParent();
    }
    
    private function onRewardDismissClick(event : Event) : Void
    {
        // Re-use dismiss for both the main reward screen and the details screen
        if (m_activeRewardsDetailScreen == null) 
        {
            if (m_closeCallback != null) 
            {
                m_closeCallback();
            }
        }
        else 
        {
            // Clean out the details screen and restore the buttons that were visible before
            m_activeRewardsDetailScreen.removeFromParent(true);
            m_activeRewardsDetailScreen = null;
            
            // Do not need to dispose textures because the buttons that will
            // show up will be on the same page the user was at.
            refreshAndLayoutButtons();
        }
    }
    
    private function onScrollLeftButtonClicked() : Void
    {
        m_currentPageIndex--;
        if (m_currentPageIndex < 0) 
        {
            m_currentPageIndex = m_rewardIdsPerPage.length - 1;
        }
        
        refreshAndLayoutButtons();
    }
    
    private function onScrollRightButtonClicked() : Void
    {
        m_currentPageIndex++;
        if (m_currentPageIndex > m_rewardIdsPerPage.length - 1) 
        {
            m_currentPageIndex = 0;
        }
        
        refreshAndLayoutButtons();
    }
}
