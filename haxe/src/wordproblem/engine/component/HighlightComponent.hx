package wordproblem.engine.component;


import motion.Actuate;
import motion.actuators.GenericActuator;
import openfl.display.DisplayObject;
import wordproblem.display.PivotSprite;

class HighlightComponent extends Component
{
    public static inline var TYPE_ID : String = "HighlightComponent";
    
    /**
     * The color to apply to the highlight
     */
    public var color : Int;
    
    /**
     * If we want the highlight to pulse over time, this is the number of seconds
     * that it should take to go for opacity to transition from max to min values.
     * 
     * If zero, do not animate.
     */
    public var animationPeriod : Float;
    
    /**
     * Right now we are assuming a highlight is just another texture that gets added somewhere
     * on the target object. If null the object doesn't have a currently displayed highlight.
     * 
     * (Set by the highlight system)
     */
    public var displayedHighlight : PivotSprite;
    
    /**
     * This component indicates that some part of the game should get some glow around it. 
     */
    public function new(entityId : String, color : Int, animationPeriod : Float)
    {
        super(entityId, HighlightComponent.TYPE_ID);
        
        this.color = color;
        this.animationPeriod = animationPeriod;
        this.displayedHighlight = null;
    }
    
    override public function dispose() : Void
    {
		Actuate.stop(displayedHighlight);
        
        if (displayedHighlight != null) 
        {
			if (displayedHighlight.parent != null) displayedHighlight.parent.removeChild(displayedHighlight);
        }
    }
}
