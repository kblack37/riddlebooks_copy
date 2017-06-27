package dragonbox.common.particlesystem
{
    public class Particle
    {
        /**
         * x position measured in pixels
         */
        public var xPosition:Number;
        
        /**
         * y position measured in pixels
         */
        public var yPosition:Number;
        
        /**
         * velocity of the x component measured in pixels per second
         */
        public var xVelocity:Number;
        
        /**
         * velocity of the y component measured in pixels per second
         */
        public var yVelocity:Number;
        
        /**
         * Uniform color of the particle
         */
        public var color:uint;
        
        /**
         * Transparency of the particle
         */
        public var alpha:Number;
        
        /**
         * Rotation of this particle in radians. For circular particles
         * this doesn't really do anything.
         */
        public var rotation:Number;
        
        /**
         * Angular velocity of particle in radians per second
         * Its the amount the particle itself rotates along its center
         */
        public var angularVelocity:Number;
        
        /**
         * Scale of the particle relative to its texture size
         */
        public var scale:Number;
        
        /**
         * How long this particle has to live in seconds. This value stays the same after
         * the particle has been created.
         */
        public var lifeTime:Number;
        
        /**
         * How long this particle has been alive since it was first emitted measured in
         * seconds.
         */
        public var age:Number;
        
        /**
         * A value between 0 and 1 that acts like an intensity measurement. At 1 the particle
         * is at maximum energy while 0 means it is dead. Energy can be used to vary properties
         * like color or alpha and is typically changes as the particle ages.
         */
        public var energy:Number;
        
        /**
         * Indicate whether the particle is dead and should no longer
         * be updated or rendered.
         */
        public var isDead:Boolean;
        
        /** Topmost texture coordinate value to be sampled from source */
        public var textureTopV:Number;
        
        /** Leftmost texture coordinate value to be sampled from source */
        public var textureLeftU:Number;
        
        /** Width of the amount of texture to sample normalized between 0 and 1 */
        public var textureWidthUV:Number;
        
        /** Height of the amount of texture to sample normalized between 0 and 1 */
        public var textureHeightUV:Number;
        
        /** Pixel width of amount of texture to sample */
        public var textureWidthPixels:Number;
        
        /** Pixel height of amount texture to sample */
        public var textureHeightPixels:Number;
        
        /** Color the particle starts at, should be fixed */
        public var startColor:uint;
        
        /** Color the particle ends at, should be fixed */
        public var endColor:uint;
        
        /** Start scale of the particle, should be fixed */
        public var startScale:Number;
        
        /** End scale of the particle, should be fixed */
        public var endScale:Number;
        
        public function Particle()
        {
            reset();
        }
        
        public function reset():void
        {
            this.rotation = 0;
            this.xPosition = 0;
            this.yPosition = 0;
            this.xVelocity = 0;
            this.yVelocity = 0;
            this.scale = 1.0;
            this.alpha = 1;
            this.color = 0xFFFFFF;
            this.age = 0;
            this.isDead = false;
        }
    }
}