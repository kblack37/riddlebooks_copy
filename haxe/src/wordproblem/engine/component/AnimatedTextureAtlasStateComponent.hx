package wordproblem.engine.component;

import wordproblem.engine.component.Component;

import starling.display.Image;

/**
 * This component is closely attached to the AnimatedTextureAtlasComponent.
 * 
 * It keeps track of state per instance of the item. Systems and scripts should
 * modify the data fields to adjust how the entity's spritesheet is drawn.
 */
class AnimatedTextureAtlasStateComponent extends Component
{
    public static inline var TYPE_ID : String = "AnimatedTextureAtlasStateComponent";
    
    /**
     * Current frame that should be displayed. Less than zero means no frame should be playing.
     */
    public var currentFrameCounter : Int;
    
    /**
     * Current part of the delay before the next animation should be played.
     */
    public var currentDelayCounter : Int;
    
    /**
     * Number of animation cycles completed for the currently playing texture atlas.
     * Zero means the atlas is going through it's first pass since it was switched in.
     */
    public var currentCyclesComplete : Int;
    
    public function new(entityId : String)
    {
        super(entityId, TYPE_ID);
    }
    
    override public function deserialize(data : Dynamic) : Void
    {
        this.currentFrameCounter = 0;
        this.currentDelayCounter = 0;
        this.currentCyclesComplete = 0;
    }
}
