package wordproblem.xp
{
    import starling.animation.Transitions;
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    
    /**
     * This class encapsulates all the animations of the bar being filled up and the level getting updated
     * 
     * TODO: Should be able to click to skip directly to the end state
     */
    public class PlayerXpBarAnimation
    {
        /**
         * The number of seconds it should take for a bar to go from a
         * fill ratio of 0.0 to 1.0
         */
        private var m_fillVelocity:Number = 1.5;
        
        /**
         * This is the ui component that the animation will mostly be trying to modify
         */
        private var m_playerXpBar:PlayerXPBar;
        
        private var m_playerXpModel:PlayerXpModel;
        
        private var m_fillRatioProperty:Object;
        
        /**
         * We handle sequencing all the various animation by referencing them via a list
         */
        private var m_animationList:Vector.<Function>;
        
        private var m_animationListParams:Vector.<Object>;
        
        /**
         * For a playing animation we keep track of all the tween object that were used so we can properly
         * stop and clean them up if we are interuppted in the middle.
         */
        private var m_activeTweens:Vector.<Tween>;
        
        /**
         * Other parts of game may need to know when the level up animation is finished.
         * For example the summary shows a reward screen for each level gained by the player.
         */
        private var m_levelUpCallback:Function;
        
        /**
         * Callback to outside world to indicate everything here is finished
         * (Accepts no params)
         */
        private var m_finishCallback:Function;
        
        public function PlayerXpBarAnimation(playerXpBar:PlayerXPBar, 
                                             playerXpModel:PlayerXpModel)
        {
            m_playerXpBar = playerXpBar;
            m_playerXpModel = playerXpModel;
            
            m_fillRatioProperty = {ratio:0.0};
            m_animationList = new Vector.<Function>();
            m_animationListParams = new Vector.<Object>();
            m_activeTweens = new Vector.<Tween>();
        }
        
        /**
         * @param levelUpCallback
         *      Function triggered whenever a new level is gained in this animation
         *      callback(newLevel:int):void
         * @param finishCallback
         *      Function triggered whenever the animation is finished
         */
        public function start(startTotalXp:uint, 
                              endTotalXp:uint, 
                              levelUpCallback:Function, 
                              finishCallback:Function):void
        {
            m_levelUpCallback = levelUpCallback;
            m_finishCallback = finishCallback;
            
            var outData:Vector.<uint> = new Vector.<uint>();
            m_playerXpModel.getLevelAndRemainingXpFromTotalXp(startTotalXp, outData);
            var startRemainingXp:uint = outData[1];
            var startPlayerLevel:uint = outData[0];
            
            // Determine the end xp state and level
            outData.length = 0;
            m_playerXpModel.getLevelAndRemainingXpFromTotalXp(endTotalXp, outData);
            var endRemainingXp:uint = outData[1];
            var endPlayerLevel:uint = outData[0];
            
            // Calculate the fill ratio and level needed for the starting level
            // Set the xp bar to this initial state
            var totalXpForNextLevelAfterStart:uint = m_playerXpModel.getTotalXpForLevel(startPlayerLevel + 1);
            var totalXpForStart:uint = m_playerXpModel.getTotalXpForLevel(startPlayerLevel);
            var startFillRatio:Number = startRemainingXp / (totalXpForNextLevelAfterStart - totalXpForStart);
            m_playerXpBar.setFillRatio(startFillRatio);
            m_playerXpBar.getPlayerLevelTextField().setText("" + startPlayerLevel);
            
            // Work our way backwards to figure out how many fill tweens and level up tweens we need
            // (need at least one per level up)
            var currentLevelCounter:uint = endPlayerLevel;
            while (currentLevelCounter > startPlayerLevel)
            {
                // The fill for the last level up is from 0.0 to whatever remainder is left out
                if (currentLevelCounter == endPlayerLevel)
                {
                    var endFillRatio:Number = endRemainingXp / (m_playerXpModel.getTotalXpForLevel(endPlayerLevel + 1) - m_playerXpModel.getTotalXpForLevel(endPlayerLevel));
                    m_animationList.push(playFillAnimation);
                    m_animationListParams.push({startRatio:0.0, endRatio:endFillRatio});
                }
                // The fill should go from 0.0 to 1.0 (this is the rare case where enough xp was earned to jump several levels)
                else
                {
                    m_animationList.push(playFillAnimation);
                    m_animationListParams.push({startRatio:0.0, endRatio:1.0});
                }
                
                // Add a special tween for level up after the fill is completed
                m_animationList.push(playerLevelUpAnimation);
                m_animationListParams.push({level:currentLevelCounter});
                
                currentLevelCounter--;
            }
            
            // Regardless of level ups we always have a tween for the first fill
            // One case is player stays at same level so we just need to calculate the end 
            if (startPlayerLevel == endPlayerLevel)
            {
                endFillRatio = endRemainingXp / (totalXpForNextLevelAfterStart - totalXpForStart);
                m_animationList.push(playFillAnimation);
                m_animationListParams.push({startRatio:startFillRatio, endRatio:endFillRatio});
                
            }
            // The fill should stop at one, this is when the first tween goes to a level up
            else
            {
                m_animationList.push(playFillAnimation);
                m_animationListParams.push({startRatio:startFillRatio, endRatio:1.0});
            }
            
            // Start the animation
            playNextAnimation();
        }
        
        public function stop():void
        {
            var i:int;
            var numTweens:int = m_activeTweens.length;
            for (i = 0; i < numTweens; i++)
            {
                var tween:Tween = m_activeTweens[i];
                Starling.juggler.remove(tween);
            }
            
            m_activeTweens.length = 0;
            m_animationList.length = 0;
        }
        
        /**
         * If another class supplies a level up callback when the animation starts,
         * after every level up this animation pauses and waits for the supplying
         * cause to manually resume the animation
         */
        public function resumeAfterLevelUpPause():void
        {
            playNextAnimation();
        }
        
        private function playNextAnimation():void
        {
            if (m_animationList.length > 0)
            {
                var animationCallback:Function = m_animationList.pop();
                var animationParams:Object = m_animationListParams.pop();
                animationCallback(animationParams);
            }
            else if (m_finishCallback != null)
            {
                m_finishCallback();
            }
        }
        
        private function playFillAnimation(params:Object):void
        {
            var startRatio:Number = params.startRatio;
            m_fillRatioProperty.ratio = startRatio;
            m_playerXpBar.setFillRatio(startRatio);
            
            var endRatio:Number = params.endRatio;
            
            // Create a background that is flashing constantly
            var backgroundBarFill:DisplayObject = m_playerXpBar.setBackgroundFillRatio(endRatio);
            backgroundBarFill.alpha = 0.5;
            var flashTargetTween:Tween = new Tween(backgroundBarFill, 0.4);
            flashTargetTween.fadeTo(1.0);
            flashTargetTween.repeatCount = 0;
            flashTargetTween.reverse = true;
            addAndPlayTween(flashTargetTween);
            
            // Simple tween of the bar filling
            var duration:Number = (endRatio - startRatio) * m_fillVelocity;
            var fillBarTween:Tween = new Tween(m_fillRatioProperty, duration);
            fillBarTween.animate("ratio", endRatio);
            fillBarTween.onUpdate = function():void
            {
                m_playerXpBar.setFillRatio(m_fillRatioProperty.ratio);
            };
            fillBarTween.onComplete = function():void
            {
                Starling.juggler.remove(flashTargetTween);
                m_playerXpBar.removeBackgroundFill();
                playNextAnimation();
            }
            addAndPlayTween(fillBarTween);
        }
        
        private function playerLevelUpAnimation(params:Object):void
        {
            // On level up, other parts of the game may want to show an extra notification message.
            // In this case the animation needs to be able to pause and then get an external resume signal
            var duration:Number = 0.3;
            var level:int = params.level;
            var fadeOldLevelTween:Tween = new Tween(m_playerXpBar.getPlayerLevelTextField(), duration, Transitions.EASE_IN);
            fadeOldLevelTween.animate("alpha", 0.0);
            fadeOldLevelTween.animate("scaleX", 4);
            fadeOldLevelTween.animate("scaleY", 4);
            fadeOldLevelTween.onComplete = function():void
            {
                m_playerXpBar.getPlayerLevelTextField().setText(level + "");
                var showNewLevelTween:Tween = new Tween(m_playerXpBar.getPlayerLevelTextField(), duration, Transitions.EASE_OUT);
                showNewLevelTween.animate("alpha", 1);
                showNewLevelTween.animate("scaleX", 1);
                showNewLevelTween.animate("scaleY", 1);
                
                // On finish, we hand control to the summary script so it can
                // explain the level up rewards and the summary screen
                showNewLevelTween.onComplete = (m_levelUpCallback != null) ? m_levelUpCallback : playNextAnimation;
                showNewLevelTween.onCompleteArgs = (m_levelUpCallback != null) ? [level] : null;
                addAndPlayTween(showNewLevelTween);
            };
            addAndPlayTween(fadeOldLevelTween);
        }
        
        private function addAndPlayTween(tween:Tween):void
        {
            m_activeTweens.push(tween);
            Starling.juggler.add(tween);
        }
        
        /*
        The fill animation should just involve calling fill ratio multiple times
        
        While this is happening the background brain layers should be flashing.
        This should just be a scale and fade, we cycle through the different background layers
        
        We need to create a sequence of tweens
        
        Need a constant velocity for xp to pixel mapping
        
        fill tween, bar increases to end capacity.
        
        level up, take a filled bar and have it flash and expand away
        particle explosion of small brains, the value of the level in the text changes
        Set fill to empty again
        
        have a callback whenever level up animation is finished
        have a callback when everything is completely finished
        */
    }
}