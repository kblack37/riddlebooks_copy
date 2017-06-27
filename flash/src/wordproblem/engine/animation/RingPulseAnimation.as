package wordproblem.engine.animation
{
    import dragonbox.common.dispose.IDisposable;
    
    import starling.animation.IAnimatable;
    import starling.animation.Tween;
    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    import starling.textures.Texture;
    
    /**
     * This animation plays
     */
    public class RingPulseAnimation implements IAnimatable, IDisposable
    {
        /**
         * Maximum radius that a ring can be
         */
        private var m_maxRingRadius:Number = 32;
        
        /**
         * The number of seconds it should take for a single ring to go
         * through it's animation cycle
         */
        private var m_singleRingDuration:Number = 0.75;
        
        /**
         * The number of seconds that pass before a new ring is generated
         */
        private var m_frequency:Number = 1;
        
        /**
         * The container where the rings should be added
         */
        private var m_displayContainer:DisplayObjectContainer;
        
        private var m_activeTweens:Vector.<Tween>;
        
        private var m_ringTexture:Texture;
        
        /**
         * Trigger when the animation has completed
         */
        private var m_onComplete:Function;
        
        private var m_totalTweensToPlay:int;
        
        /**
         * Keep track of tweens finished during a play through, should reset to zero when
         * a new one is started.
         */
        private var m_numCompletedTweens:int;
        
        public function RingPulseAnimation(ringTexture:Texture, onComplete:Function)
        {
            m_ringTexture = ringTexture;
            m_activeTweens = new Vector.<Tween>();
            m_onComplete = onComplete;
            m_numCompletedTweens = 0;
        }
        
        public function dispose():void
        {
            // Clear all textures that are active
            for each (var activeTween:Tween in m_activeTweens)
            {
                (activeTween.target as Image).removeFromParent(true);
            }
        }
        
        public function advanceTime(time:Number):void
        {
            var i:int;
            var numTweens:int = m_activeTweens.length;
            for (i = 0; i < numTweens; i++)
            {
                m_activeTweens[i].advanceTime(time);
            }
        }
        
        public function reset(xPosition:Number, yPosition:Number, displayContainer:DisplayObjectContainer, color:uint):void
        {
            // Interrupt currently playing tweens
            var i:int;
            var numTweens:int = m_activeTweens.length;
            for (i = 0; i < numTweens; i++)
            {
                (m_activeTweens[i].target as Image).removeFromParent(true);
            }
            m_activeTweens.length = 0;
            
            // Each individual ring should start out minimized and then expand outwards while fading
            m_displayContainer = displayContainer;
            m_numCompletedTweens = 0;
            var endScaleFactor:Number = m_maxRingRadius / (m_ringTexture.width * 0.5);
            
            // The number of tweens to create is determined by the number that can be active at any given
            // time.
            var numSimultaneousActiveRings:int = Math.ceil(m_singleRingDuration / m_frequency);
            for (i = 0; i < numSimultaneousActiveRings; i++)
            {
                var ringImage:Image = new Image(m_ringTexture);
                ringImage.pivotX = m_ringTexture.width * 0.5;
                ringImage.pivotY = m_ringTexture.height * 0.5;
                ringImage.scaleX = ringImage.scaleY = 0.0;
                ringImage.x = xPosition;
                ringImage.y = yPosition;
                ringImage.color = color;
                
                var ringExpandTween:Tween = new Tween(ringImage, m_singleRingDuration);
                ringExpandTween.delay = i * m_frequency;
                ringExpandTween.animate("scaleX", endScaleFactor);
                ringExpandTween.animate("scaleY", endScaleFactor);
                ringExpandTween.animate("alpha", 0.1);
                ringExpandTween.repeatCount = 1;
                ringExpandTween.onComplete = onTweenComplete;
                ringExpandTween.onCompleteArgs = [ringExpandTween];
                m_activeTweens.push(ringExpandTween);
                
                displayContainer.addChild(ringImage);
            }
            
            m_totalTweensToPlay = m_activeTweens.length;
        }
        
        private function onTweenComplete(tween:Tween):void
        {
            m_displayContainer.removeChild(tween.target as Image);
            m_activeTweens.splice(m_activeTweens.indexOf(tween), 1);
            
            m_numCompletedTweens++;
            if (m_numCompletedTweens >= m_totalTweensToPlay)
            {
                m_activeTweens.length = 0;
                m_onComplete();
            }
        }
    }
}