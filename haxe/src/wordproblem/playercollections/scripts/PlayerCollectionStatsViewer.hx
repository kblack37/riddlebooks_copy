package wordproblem.playercollections.scripts;

import wordproblem.playercollections.scripts.PlayerCollectionViewer;

import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

import openfl.display.DisplayObjectContainer;
import openfl.text.TextField;

import wordproblem.currency.CurrencyCounter;
import wordproblem.currency.PlayerCurrencyModel;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.text.GameFonts;
import wordproblem.level.controller.WordProblemCgsLevelManager;
import wordproblem.resource.AssetManager;
import wordproblem.xp.PlayerXPBar;
import wordproblem.xp.PlayerXpModel;

/**
 * This script handles rendering the screen showing any miscellaneous player stats.
 */
class PlayerCollectionStatsViewer extends PlayerCollectionViewer
{
    /**
     * Used to keep track of stats related to playing of levels
     */
    private var m_levelManager : WordProblemCgsLevelManager;
    
    /**
     * Show the current experience progress of the player
     */
    private var m_playerXpBar : PlayerXPBar;
    
    /**
     * The data needed to draw the xp bar correctly
     */
    private var m_playerXpModel : PlayerXpModel;
    
    private var m_totalXpText : TextField;
    private var m_xpUntilNextLevelText : TextField;
    
    private var m_totalLevelsText : TextField;
    
    /**
     * The data needed to draw the currency possessed by the player
     */
    private var m_playerCurrencyModel : PlayerCurrencyModel;
    
    /**
     * Display showing the number of coins earned.
     */
    private var m_currencyCounter : CurrencyCounter;
    
    private var m_timer : Time;
    private var m_secondsSinceLastFlip : Float;
    
    public function new(levelManager : WordProblemCgsLevelManager,
            playerXpModel : PlayerXpModel,
            playerCurrencyModel : PlayerCurrencyModel,
            canvasContainer : DisplayObjectContainer,
            assetManager : AssetManager,
            mouseState : MouseState,
            timer : Time,
            id : String = null,
            isActive : Bool = true)
    {
        super(canvasContainer, assetManager, mouseState, null, id, isActive);
        
        m_timer = timer;
        m_secondsSinceLastFlip = 0;
        
        m_levelManager = levelManager;
        m_playerXpModel = playerXpModel;
        m_playerXpBar = new PlayerXPBar(assetManager, 400);
        
        m_playerCurrencyModel = playerCurrencyModel;
        m_currencyCounter = new CurrencyCounter(assetManager, 180, 50, 50);
        
        m_titleText.text = "Stats";
        
        m_totalXpText = new TextField(800, 60, "", GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF);
        m_xpUntilNextLevelText = new TextField(800, 60, "", GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF);
        m_totalLevelsText = new TextField(800, 60, "", 
                GameFonts.DEFAULT_FONT_NAME, 22, 0xFFFFFF);
    }
    
    override public function visit() : Int
    {
        m_secondsSinceLastFlip += m_timer.currentDeltaSeconds;
        if (m_secondsSinceLastFlip > 4) 
        {
            m_secondsSinceLastFlip = 0;
            m_currencyCounter.startAnimateCoinFlip(1, Math.PI);
        }
        return ScriptStatus.SUCCESS;
    }
    
    override public function show() : Void
    {
        super.show();
        
        m_titleText.y = 0;
        m_canvasContainer.addChild(m_titleText);
        
        // Set the fill and level for the player
        var outXpData : Array<Int> = new Array<Int>();
        m_playerXpModel.getLevelAndRemainingXpFromTotalXp(m_playerXpModel.totalXP, outXpData);
        
        var xpForCurrentLevel : Int = m_playerXpModel.getTotalXpForLevel(outXpData[0]);
        var xpForNextLevel : Int = m_playerXpModel.getTotalXpForLevel(outXpData[0] + 1);
        
        m_playerXpBar.setFillRatio(outXpData[1] / (xpForNextLevel - xpForCurrentLevel));
        m_playerXpBar.getPlayerLevelTextField().setText(outXpData[0] + "");
        
        m_playerXpBar.y = m_titleText.y + m_titleText.height + 10;
        m_playerXpBar.x = (800 - m_playerXpBar.width) * 0.5;
        m_canvasContainer.addChild(m_playerXpBar);
        
        m_currencyCounter.setValue(m_playerCurrencyModel.totalCoins);
        m_currencyCounter.x = 50;
        m_currencyCounter.y = 600 - m_currencyCounter.height * 2;
        m_canvasContainer.addChild(m_currencyCounter);
        
        var spacing : Float = 10;
        
        // Show info about total xp earned and xp until player reaches next brain level
        m_totalXpText.text = "Total Brain XP earned: " + m_playerXpModel.totalXP;
        m_totalXpText.y = m_playerXpBar.y + m_playerXpBar.height;  // Bar already has large amount of padding  
        m_canvasContainer.addChild(m_totalXpText);
        
        m_xpUntilNextLevelText.text = "XP until next Brain Level Up: " + (xpForNextLevel - m_playerXpModel.totalXP);
        m_xpUntilNextLevelText.y = m_totalXpText.y + m_totalXpText.height + spacing;
        m_canvasContainer.addChild(m_xpUntilNextLevelText);
        
        // Show info related to total levels played
        m_totalLevelsText.x = 0;
        m_totalLevelsText.y = m_xpUntilNextLevelText.y + m_xpUntilNextLevelText.height + spacing;
        var totalLevelsCompleted : Int = m_levelManager.currentLevelProgression.numLevelLeafsCompleted;
        m_totalLevelsText.text = "Total Levels Finished: " + totalLevelsCompleted;
        m_canvasContainer.addChild(m_totalLevelsText);
    }
    
    override public function hide() : Void
    {
        super.hide();
        if (m_playerXpBar.parent != null) m_playerXpBar.parent.removeChild(m_playerXpBar);
        if (m_totalXpText.parent != null) m_totalXpText.parent.removeChild(m_totalXpText);
        if (m_xpUntilNextLevelText.parent != null) m_xpUntilNextLevelText.parent.removeChild(m_xpUntilNextLevelText);
        if (m_totalLevelsText.parent != null) m_totalLevelsText.parent.removeChild(m_totalLevelsText);
        
        if (m_currencyCounter.parent != null) m_currencyCounter.parent.removeChild(m_currencyCounter);
    }
}
