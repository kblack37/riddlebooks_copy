package wordproblem.summary
{
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.textures.Texture;
    
    import wordproblem.resource.AssetManager;
    
    /**
     * Base display representing a single reward shown on the summary screen
     */
    public class BaseRewardButton extends Sprite
    {
        public var data:Object;
        
        protected var m_assetManager:AssetManager
        
        protected var m_backgroundGlowImage:Image;
        
        protected var m_glowTween:Tween;
        
        public function BaseRewardButton(maxEdgeLength:Number, rewardData:Object, assetManager:AssetManager)
        {
            super();
            
            this.data = rewardData;
            m_assetManager = assetManager;
            
            // Create a general glow background for every button
            var backgroundGlowTexture:Texture = assetManager.getTexture("Art_YellowGlow");
            var backgroundGlowImage:Image = new Image(backgroundGlowTexture);
            backgroundGlowImage.pivotX = backgroundGlowTexture.width * 0.5;
            backgroundGlowImage.pivotY = backgroundGlowTexture.height * 0.5;
            backgroundGlowImage.width = backgroundGlowImage.height = maxEdgeLength;
            backgroundGlowImage.x = maxEdgeLength * 0.5;
            backgroundGlowImage.y = maxEdgeLength * 0.5;
            addChild(backgroundGlowImage);
            m_backgroundGlowImage = backgroundGlowImage;
            
            m_glowTween = new Tween(backgroundGlowImage, 2);
            m_glowTween.repeatCount = 0;
            m_glowTween.reverse = true;
            
            var originalScale:Number = m_backgroundGlowImage.scaleX;
            var newScale:Number = originalScale * 1.1;
            m_glowTween.animate("scaleX", newScale);
            m_glowTween.animate("scaleY", newScale);
            m_glowTween.animate("alpha", 0.8);
            Starling.juggler.add(m_glowTween);
        }
        
        /**
         * Subclasses should override this.
         * 
         * Each reward button type has a unique way of drawing the details screen related
         * to that particular reward.
         */
        public function getRewardDetailsScreen():Sprite
        {
            return null;
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            Starling.juggler.remove(m_glowTween);
        }
    }
}