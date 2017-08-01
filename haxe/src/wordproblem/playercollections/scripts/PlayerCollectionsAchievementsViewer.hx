package wordproblem.playercollections.scripts;

import wordproblem.playercollections.scripts.PlayerCollectionViewer;

import dragonbox.common.ui.MouseState;

import starling.display.DisplayObjectContainer;

import wordproblem.achievements.PlayerAchievementButton;
import wordproblem.achievements.PlayerAchievementsModel;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.resource.AssetManager;

/**
 * This script handles rendering the screen showing all the achievements that the player
 * has earned.
 */
class PlayerCollectionsAchievementsViewer extends PlayerCollectionViewer
{
    private var m_playerAchievementsModel : PlayerAchievementsModel;
    
    /**
     * A list of pages where each individual page is a list of ids to draw
     */
    private var m_achievementsPerPage : Array<Array<String>>;
    
    /**
     * List of display objects for achievements showing in the current page
     */
    private var m_activeAchievementButtons : Array<PlayerAchievementButton>;
    
    public function new(playerAchievementsModel : PlayerAchievementsModel,
            canvasContainer : DisplayObjectContainer,
            assetManager : AssetManager,
            mouseState : MouseState,
            id : String = null,
            isActive : Bool = true)
    {
        super(canvasContainer, assetManager, mouseState, null, id, isActive);
        
        m_playerAchievementsModel = playerAchievementsModel;
        
        m_achievementsPerPage = new Array<Array<String>>();
        m_activeAchievementButtons = new Array<PlayerAchievementButton>();
        m_titleText.text = "Achievements";
    }
    
    override public function visit() : Int
    {
        var prevPage : Int = m_activeItemPageIndex;
        if (m_scrollLeftClickedLastFrame) 
        {
            m_scrollLeftClickedLastFrame = false;
            
            m_activeItemPageIndex--;
            if (m_activeItemPageIndex < 0) 
            {
                m_activeItemPageIndex = m_achievementsPerPage.length - 1;
            }
        }
        
        if (m_scrollRightClickedLastFrame) 
        {
            m_scrollRightClickedLastFrame = false;
            
            m_activeItemPageIndex++;
            if (m_activeItemPageIndex >= m_achievementsPerPage.length) 
            {
                m_activeItemPageIndex = 0;
            }
        }  // If switch to new page, clear the old buttons  
        
        
        
        if (prevPage != m_activeItemPageIndex) 
        {
            clearAchievementButtons();
            drawAchievementsForPage(m_activeItemPageIndex);
        }
        
        return ScriptStatus.SUCCESS;
    }
    
    override public function show() : Void
    {
        super.show();
        
        m_canvasContainer.addChild(m_titleText);
        
        // Much like items we need to break up achievements into pages
        var achievementIds : Array<String> = m_playerAchievementsModel.getAchievementIds();
		m_achievementsPerPage = new Array<Array<String>>();
        divideAchievementIdsIntoPages(m_playerAchievementsModel.getAchievementIds(), 3, m_achievementsPerPage);
        
        // Always start at the first page of achievements
        drawAchievementsForPage(0);
        showScrollButtons(m_achievementsPerPage.length > 1);
    }
    
    override public function hide() : Void
    {
        super.hide();
        
        clearAchievementButtons();
    }
    
    /**
     *
     * @param inList
     *      List of achievement ids to divide
     * @param itemsPerPage
     *      A positive value of the number of achievement display objects that should appear in on page
     * @param outPages
     *      Each element is the list of achievement ids that be shown on a given page
     */
    private function divideAchievementIdsIntoPages(inList : Array<String>, itemsPerPage : Int, outPages : Array<Array<String>>) : Void
    {
        var itemsInCurrentPage : Array<String> = new Array<String>();
        var totalAchievements : Int = inList.length;
        var i : Int = 0;
        for (i in 0...totalAchievements){
            if (itemsInCurrentPage.length >= itemsPerPage) 
            {
                outPages.push(itemsInCurrentPage);
                itemsInCurrentPage = new Array<String>();
            }
            
            itemsInCurrentPage.push(inList[i]);
        }
        
        outPages.push(itemsInCurrentPage);
    }
    
    private function drawAchievementsForPage(pageIndex : Int) : Void
    {
        var buttonWidth : Float = 400;
        var buttonHeight : Float = 100;
        
        var xOffset : Float = (800 - buttonWidth) * 0.5;
        var yOffset : Float = 100;
        
        // Create and layout the buttons for the achievements in the page
        var achievementIdsInPage : Array<String> = m_achievementsPerPage[pageIndex];
        var i : Int = 0;
        var numAchievementIdsInPage : Int = achievementIdsInPage.length;
        for (i in 0...numAchievementIdsInPage){
            var achievementData : Dynamic = m_playerAchievementsModel.getAchievementDetailsFromId(achievementIdsInPage[i]);
            var achievementButton : PlayerAchievementButton = new PlayerAchievementButton(achievementData, buttonWidth, buttonHeight, m_assetManager);
            m_activeAchievementButtons.push(achievementButton);
            
            achievementButton.x = xOffset;
            achievementButton.y = yOffset;
            m_canvasContainer.addChild(achievementButton);
            
            yOffset += buttonHeight + 20;
        }
        
        showPageIndicator(pageIndex + 1, m_achievementsPerPage.length);
    }
    
    private function clearAchievementButtons() : Void
    {
        var i : Int = 0;
        var numButtons : Int = m_activeAchievementButtons.length;
        for (i in 0...numButtons){
            var achievementButton : PlayerAchievementButton = m_activeAchievementButtons[i];
            achievementButton.removeFromParent(true);
        }
        
		m_activeAchievementButtons = new Array<PlayerAchievementButton>();
    }
}
