package wordproblem.xp;

import wordproblem.xp.PlayerXpModel;

import starling.animation.Transitions;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;

/**
 * This class encapsulates all the animations of the bar being filled up and the level getting updated
 * 
 * TODO: Should be able to click to skip directly to the end state
 */
class PlayerXpBarAnimation
{
    /**
     * The number of seconds it should take for a bar to go from a
     * fill ratio of 0.0 to 1.0
     */
    private var m_fillVelocity : Float = 1.5;
    
    /**
     * This is the ui component that the animation will mostly be trying to modify
     */
    private var m_playerXpBar : PlayerXPBar;
    
    private var m_playerXpModel : PlayerXpModel;
    
    private var m_fillRatioProperty : Dynamic;
    
    /**
     * We handle sequencing all the various animation by referencing them via a list
     */
    private var m_animationList : Array<Function>;
    
    private var m_animationListParams : Array<Dynamic>;
    
    /**
     * For a playing animation we keep track of all the tween object that were used so we can properly
     * stop and clean them up if we are interuppted in the middle.
     */
    private var m_activeTweens : Array<Tween>;
    
    /**
     * Other parts of game may need to know when the level up animation is finished.
     * For example the summary shows a reward screen for each level gained by the player.
     */
    private var m_levelUpCallback : Function;
    
    /**
     * Callback to outside world to indicate everything here is finished
     * (Accepts no params)
     */
    private var m_finishCallback : Function;
    
    public function new(playerXpBar : PlayerXPBar,
            playerXpModel : PlayerXpModel)
    {
        m_playerXpBar = playerXpBar;
        m_playerXpModel = playerXpModel;
        
        m_fillRatioProperty = {
                    ratio : 0.0

                };
        m_animationList = new Array<Function>();
        m_animationListParams = new Array<Dynamic>();
        m_activeTweens = new Array<Tween>();
    }
    
    /**
     * @param levelUpCallback
     *      Function triggered whenever a new level is gained in this animation
     *      callback(newLevel:int):void
     * @param finishCallback
     *      Function triggered whenever the animation is finished
     */
    public function start(startTotalXp : Int,
            endTotalXp : Int,
            levelUpCallback : Function,
            finishCallback : Function) : Void
    {
        m_levelUpCallback = levelUpCallback;
        m_finishCallback = finishCallback;
        
        var outData : Array<Int> = new Array<Int>();
        m_playerXpModel.getLevelAndRemainingXpFromTotalXp(startTotalXp, outData);
        var startRemainingXp : Int = outData[1];
        var startPlayerLevel : Int = outData[0];
        
        // Determine the end xp state and level
        as3hx.Compat.setArrayLength(outData, 0);
        m_playerXpModel.getLevelAndRemainingXpFromTotalXp(endTotalXp, outData);
        var endRemainingXp : Int = outData[1];
        var endPlayerLevel : Int = outData[0];
        
        // Calculate the fill ratio and level needed for the starting level
        // Set the xp bar to this initial state
        var totalXpForNextLevelAfterStart : Int = m_playerXpModel.getTotalXpForLevel(startPlayerLevel + 1);
        var totalXpForStart : Int = m_playerXpModel.getTotalXpForLevel(startPlayerLevel);
        var startFillRatio : Float = startRemainingXp / (totalXpForNextLevelAfterStart - totalXpForStart);
        m_playerXpBar.setFillRatio(startFillRatio);
        m_playerXpBar.getPlayerLevelTextField().setText("" + startPlayerLevel);
        
        // Work our way backwards to figure out how many fill tweens and level up tweens we need
        // (need at least one per level up)
        var currentLevelCounter : Int = endPlayerLevel;
        while (currentLevelCounter > startPlayerLevel)
        {
            // The fill for the last level up is from 0.0 to whatever remainder is left out
            if (currentLevelCounter == endPlayerLevel) 
            {
                var endFillRatio : Float = endRemainingXp / (m_playerXpModel.getTotalXpForLevel(endPlayerLevel + 1) - m_playerXpModel.getTotalXpForLevel(endPlayerLevel));
                m_animationList.push(playFillAnimation);
                m_animationListParams.push({
                            startRatio : 0.0,
                            endRatio : endFillRatio,

                        });
            }
            // The fill should go from 0.0 to 1.0 (this is the rare case where enough xp was earned to jump several levels)
            else 
            {
                m_animationList.push(playFillAnimation);
                m_animationListParams.push({
                            startRatio : 0.0,
                            endRatio : 1.0,

                        });
            }  // Add a special tween for level up after the fill is completed  
            
            
            
            m_animationList.push(playerLevelUpAnimation);
            m_animationListParams.push({
                        level : currentLevelCounter

                    });
            
            currentLevelCounter--;
        }  // One case is player stays at same level so we just need to calculate the end    // Regardless of level ups we always have a tween for the first fill  
        
        
        
        
        
        if (startPlayerLevel == endPlayerLevel) 
        {
            endFillRatio = endRemainingXp / (totalXpForNextLevelAfterStart - totalXpForStart);
            m_animationList.push(playFillAnimation);
            m_animationListParams.push({
                        startRatio : startFillRatio,
                        endRatio : endFillRatio,

                    });
        }
        // The fill should stop at one, this is when the first tween goes to a level up
        else 
        {
            m_animationList.push(playFillAnimation);
            m_animationListParams.push({
                        startRatio : startFillRatio,
                        endRatio : 1.0,

                    });
        }  // Start the animation  
        
        
        
        playNextAnimation();
    }
    
    public function stop() : Void
    {
        var i : Int;
        var numTweens : Int = m_activeTweens.length;
        for (i in 0...numTweens){
            var tween : Tween = m_activeTweens[i];
            Starling.juggler.remove(tween);
        }
        
        as3hx.Compat.setArrayLength(m_activeTweens, 0);
        as3hx.Compat.setArrayLength(m_animationList, 0);
    }
    
    /**
     * If another class supplies a level up callback when the animation starts,
     * after every level up this animation pauses and waits for the supplying
     * cause to manually resume the animation
     */
    public function resumeAfterLevelUpPause() : Void
    {
        playNextAnimation();
    }
    
    private function playNextAnimation() : Void
    {
        if (m_animationList.length > 0) 
        {
            var animationCallback : Function = m_animationList.pop();
            var animationParams : Dynamic = m_animationListParams.pop();
            animationCallback(animationParams);
        }
        else if (m_finishCallback != null) 
        {
            m_finishCallback();
        }
    }
    
    private function playFillAnimation(params : Dynamic) : Void
    {
        var startRatio : Float = params.startRatio;
        m_fillRatioProperty.ratio = startRatio;
        m_playerXpBar.setFillRatio(startRatio);
        
        var endRatio : Float = params.endRatio;
        
        // Create a background that is flashing constantly
        var backgroundBarFill : DisplayObject = m_playerXpBar.setBackgroundFillRatio(endRatio);
        backgroundBarFill.alpha = 0.5;
        var flashTargetTween : Tween = new Tween(backgroundBarFill, 0.4);
        flashTargetTween.fadeTo(1.0);
        flashTargetTween.repeatCount = 0;
        flashTargetTween.reverse = true;
        addAndPlayTween(flashTargetTween);
        
        // Simple tween of the bar filling
        var duration : Float = (endRatio - startRatio) * m_fillVelocity;
        var fillBarTween : Tween = new Tween(m_fillRatioProperty, duration);
        fillBarTween.animate("ratio", endRatio);
        fillBarTween.onUpdate = function() : Void
                {
                    m_playerXpBar.setFillRatio(m_fillRatioProperty.ratio);
                };
        fillBarTween.onComplete = function() : Void
                {
                    Starling.juggler.remove(flashTargetTween);
                    m_playerXpBar.removeBackgroundFill();
                    playNextAnimation();
                };
        addAndPlayTween(fillBarTween);
    }
    
    private function playerLevelUpAnimation(params : Dynamic) : Void
    {
        // On level up, other parts of the game may want to show an extra notification message.
        // In this case the animation needs to be able to pause and then get an external resume signal
        var duration : Float = 0.3;
        var level : Int = params.level;
        var fadeOldLevelTween : Tween = new Tween(m_playerXpBar.getPlayerLevelTextField(), duration, Transitions.EASE_IN);
        fadeOldLevelTween.animate("alpha", 0.0);
        fadeOldLevelTween.animate("scaleX", 4);
        fadeOldLevelTween.animate("scaleY", 4);
        fadeOldLevelTween.onComplete = function() : Void
                {
                    m_playerXpBar.getPlayerLevelTextField().setText(level + "");
                    var showNewLevelTween : Tween = new Tween(m_playerXpBar.getPlayerLevelTextField(), duration, Transitions.EASE_OUT);
                    showNewLevelTween.animate("alpha", 1);
                    showNewLevelTween.animate("scaleX", 1);
                    showNewLevelTween.animate("scaleY", 1);
                    
                    // On finish, we hand control to the summary script so it can
                    // explain the level up rewards and the summary screen
                    showNewLevelTween.onComplete = ((m_levelUpCallback != null)) ? m_levelUpCallback : playNextAnimation;
                    showNewLevelTween.onCompleteArgs = ((m_levelUpCallback != null)) ? [level] : null;
                    addAndPlayTween(showNewLevelTween);
                };
        addAndPlayTween(fadeOldLevelTween);
    }
    
    private function addAndPlayTween(tween : Tween) : Void
    {
        m_activeTweens.push(tween);
        Starling.juggler.add(tween);
    }
}
