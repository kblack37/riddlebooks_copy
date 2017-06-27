package wordproblem.playercollections.scripts
{
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
    public class PlayerCollectionsAchievementsViewer extends PlayerCollectionViewer
    {
        private var m_playerAchievementsModel:PlayerAchievementsModel;
        
        /**
         * A list of pages where each individual page is a list of ids to draw
         */
        private var m_achievementsPerPage:Vector.<Vector.<String>>;
        
        /**
         * List of display objects for achievements showing in the current page
         */
        private var m_activeAchievementButtons:Vector.<PlayerAchievementButton>;
        
        public function PlayerCollectionsAchievementsViewer(playerAchievementsModel:PlayerAchievementsModel,
                                                            canvasContainer:DisplayObjectContainer, 
                                                            assetManager:AssetManager,
                                                            mouseState:MouseState,
                                                            id:String=null, 
                                                            isActive:Boolean=true)
        {
            super(canvasContainer, assetManager, mouseState, null, id, isActive);
            
            m_playerAchievementsModel = playerAchievementsModel;
            
            m_achievementsPerPage = new Vector.<Vector.<String>>();
            m_activeAchievementButtons = new Vector.<PlayerAchievementButton>();
            m_titleText.text = "Achievements";
        }
        
        override public function visit():int
        {
            var prevPage:int = m_activeItemPageIndex;
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
            }
            
            // If switch to new page, clear the old buttons
            if (prevPage != m_activeItemPageIndex)
            {
                clearAchievementButtons();
                drawAchievementsForPage(m_activeItemPageIndex);
            }
            
            return ScriptStatus.SUCCESS;
        }
        
        override public function show():void
        {
            super.show();
            
            m_canvasContainer.addChild(m_titleText);
            
            // Much like items we need to break up achievements into pages
            var achievementIds:Vector.<String> = m_playerAchievementsModel.getAchievementIds();
            m_achievementsPerPage.length = 0;
            divideAchievementIdsIntoPages(m_playerAchievementsModel.getAchievementIds(), 3, m_achievementsPerPage);
            
            // Always start at the first page of achievements
            drawAchievementsForPage(0);
            showScrollButtons(m_achievementsPerPage.length > 1);
        }
        
        override public function hide():void
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
        private function divideAchievementIdsIntoPages(inList:Vector.<String>, itemsPerPage:int, outPages:Vector.<Vector.<String>>):void
        {
            var itemsInCurrentPage:Vector.<String> = new Vector.<String>();
            var totalAchievements:int = inList.length;
            var i:int;
            for (i = 0; i < totalAchievements; i++)
            {
                if (itemsInCurrentPage.length >= itemsPerPage)
                {
                    outPages.push(itemsInCurrentPage);
                    itemsInCurrentPage = new Vector.<String>();
                }
                
                itemsInCurrentPage.push(inList[i]);
            }
            
            outPages.push(itemsInCurrentPage);
        }
        
        private function drawAchievementsForPage(pageIndex:int):void
        {
            var buttonWidth:Number = 400;
            var buttonHeight:Number = 100;
            
            var xOffset:Number = (800 - buttonWidth) * 0.5;
            var yOffset:Number = 100;
            
            // Create and layout the buttons for the achievements in the page
            var achievementIdsInPage:Vector.<String> = m_achievementsPerPage[pageIndex];
            var i:int;
            var numAchievementIdsInPage:int = achievementIdsInPage.length;
            for (i = 0; i < numAchievementIdsInPage; i++)
            {
                var achievementData:Object = m_playerAchievementsModel.getAchievementDetailsFromId(achievementIdsInPage[i]);
                var achievementButton:PlayerAchievementButton = new PlayerAchievementButton(achievementData, buttonWidth, buttonHeight, m_assetManager);
                m_activeAchievementButtons.push(achievementButton);
                
                achievementButton.x = xOffset;
                achievementButton.y = yOffset;
                m_canvasContainer.addChild(achievementButton);
                
                yOffset += buttonHeight + 20;
            }
            
            showPageIndicator(pageIndex + 1, m_achievementsPerPage.length);
        }
        
        private function clearAchievementButtons():void
        {
            var i:int;
            var numButtons:int = m_activeAchievementButtons.length;
            for (i = 0; i < numButtons; i++)
            {
                var achievementButton:PlayerAchievementButton = m_activeAchievementButtons[i];
                achievementButton.removeFromParent(true);
            }
            
            m_activeAchievementButtons.length = 0;
        }
    }
}