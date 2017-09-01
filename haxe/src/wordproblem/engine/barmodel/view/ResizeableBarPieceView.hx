package wordproblem.engine.barmodel.view;

import wordproblem.display.DisposableSprite;

class ResizeableBarPieceView extends DisposableSprite
{
    /**
     * Total length in pixels of this display.
     */
    public var pixelLength : Float;
    
    public function new()
    {
        super();
        this.pixelLength = 0;
    }
    
    public function resizeToLength(newLength : Float) : Void
    {
    }
	
	override public function dispose() {
	}
}
