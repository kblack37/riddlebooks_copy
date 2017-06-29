package wordproblem.engine.component;


import wordproblem.engine.animation.ScanAnimation;

class ScanComponent extends Component
{
    public static inline var TYPE_ID : String = "ScanComponent";
    
    public var color : Int;
    public var velocity : Float;
    public var width : Float;
    public var delay : Float;
    
    /**
     * The animation that modifies the view.
     */
    public var animation : ScanAnimation;
    
    public function new(entityId : String,
            color : Int,
            velocity : Float,
            width : Float,
            delay : Float)
    {
        super(entityId, TYPE_ID);
        
        this.refresh(color, velocity, width, delay);
    }
    
    override public function dispose() : Void
    {
        if (this.animation != null) 
        {
            this.animation.stop();
        }
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        var color : Int = parseInt(data.color, 16);
        var velocity : Float = data.velocity;
        var width : Float = data.width;
        var delay : Float = data.delay;
        this.refresh(color, velocity, width, delay);
    }
    
    private function refresh(color : Int, velocity : Float, width : Float, delay : Float) : Void
    {
        this.color = color;
        this.velocity = velocity;
        this.width = width;
        this.delay = delay;
        this.animation = null;
    }
}
