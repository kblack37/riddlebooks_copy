package wordproblem.achievements;


/**
 * This class serves as the backing model for all the achievements that a player can earn
 * in a version of the game.
 * 
 * NOTE: We should never need to save data just to keep track of achievement progress.
 * We don't access a cache since that progress information is stored in other sources, for example
 * level completion info is already saved elsewhere and this achievement info simply needs to read
 * that data. Even something like make 100 clicks is more part of the player stats save blob, so achievements
 * just need to be able to read those other sources to update it's completion value
 */
class PlayerAchievementsModel
{
    /**
     * Map from achievement's id to another object with details about that achievemnt.
     * For example its description or color to use when drawing it.
     * 
     * For simplicity we'll also stuff state, like completion value afterwards
     * 
     * {
     * name:Title of the achievement
     * description:More detailed description of what the achievement represents
     * isComplete:Boolean of whether the achivement was completed
     * }
     */
    private var m_idToDataMap : Dynamic;
    
    /**
     * Ordered list of all achievement ids available for the player to earn
     */
    private var m_achievementIds : Array<String>;
    
    /**
     *
     * @param dataSource
     *      A json formatted string of all available achievements
     *      (Specifics of its formatting should be in a readme)
     */
    public function new(dataSource : Dynamic)
    {
        m_idToDataMap = { };
        m_achievementIds = new Array<String>();
        
        // The data source provides an explicit ordering of all achievements
        // This order is used to render
        var achievementList : Array<Dynamic> = dataSource.achievements;
        var i : Int = 0;
        for (i in 0...achievementList.length){
            var achievementData : Dynamic = achievementList[i];
            var achievementId : String = achievementData.id;
            
            // Set all achievements to incomplete initially, a separate pass should set the proper value
            // For debug purpose the data source might want to override the value
            if (!achievementData.exists("isComplete")) 
            {
                achievementData.isComplete = false;
            }  // Based on color we set the trophy name icon appearing of the gem  
            
            
            
            var achievementColor : String = achievementData.color;
            var trophyName : String = "Art_TrophyBronze";
            if (achievementColor == "Blue") 
            {
                trophyName = "Art_TrophySilverShort";
            }
            else if (achievementColor == "Orange") 
            {
                trophyName = "Art_TrophyGold";
            }
            achievementData.trophyName = trophyName;
            
            Reflect.setField(m_idToDataMap, achievementId, achievementData);
            m_achievementIds.push(achievementId);
        }
    }
    
    public function getAchievementDetailsFromId(id : String) : Dynamic
    {
        return ((m_idToDataMap.exists(id))) ? Reflect.field(m_idToDataMap, id) : null;
    }
    
    public function getAchievementIds() : Array<String>
    {
        return m_achievementIds;
    }
}
