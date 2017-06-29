package dragonbox.common.particlesystem;


class Particle
{
    /**
     * x position measured in pixels
     */
    public var xPosition : Float;
    
    /**
     * y position measured in pixels
     */
    public var yPosition : Float;
    
    /**
     * velocity of the x component measured in pixels per second
     */
    public var xVelocity : Float;
    
    /**
     * velocity of the y component measured in pixels per second
     */
    public var yVelocity : Float;
    
    /**
     * Uniform color of the particle
     */
    public var color : Int;
    
    /**
     * Transparency of the particle
     */
    public var alpha : Float;
    
    /**
     * Rotation of this particle in radians. For circular particles
     * this doesn't really do anything.
     */
    public var rotation : Float;
    
    /**
     * Angular velocity of particle in radians per second
     * Its the amount the particle itself rotates along its center
     */
    public var angularVelocity : Float;
    
    /**
     * Scale of the particle relative to its texture size
     */
    public var scale : Float;
    
    /**
     * How long this particle has to live in seconds. This value stays the same after
     * the particle has been created.
     */
    public var lifeTime : Float;
    
    /**
     * How long this particle has been alive since it was first emitted measured in
     * seconds.
     */
    public var age : Float;
    
    /**
     * A value between 0 and 1 that acts like an intensity measurement. At 1 the particle
     * is at maximum energy while 0 means it is dead. Energy can be used to vary properties
     * like color or alpha and is typically changes as the particle ages.
     */
    public var energy : Float;
    
    /**
     * Indicate whether the particle is dead and should no longer
     * be updated or rendered.
     */
    public var isDead : Bool;
    
    /** Topmost texture coordinate value to be sampled from source */
    public var textureTopV : Float;
    
    /** Leftmost texture coordinate value to be sampled from source */
    public var textureLeftU : Float;
    
    /** Width of the amount of texture to sample normalized between 0 and 1 */
    public var textureWidthUV : Float;
    
    /** Height of the amount of texture to sample normalized between 0 and 1 */
    public var textureHeightUV : Float;
    
    /** Pixel width of amount of texture to sample */
    public var textureWidthPixels : Float;
    
    /** Pixel height of amount texture to sample */
    public var textureHeightPixels : Float;
    
    /** Color the particle starts at, should be fixed */
    public var startColor : Int;
    
    /** Color the particle ends at, should be fixed */
    public var endColor : Int;
    
    /** Start scale of the particle, should be fixed */
    public var startScale : Float;
    
    /** End scale of the particle, should be fixed */
    public var endScale : Float;
    
    public function new()
    {
        reset();
    }
    
    public function reset() : Void
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
