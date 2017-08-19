package wordproblem.engine.barmodel.view;


import dragonbox.common.dispose.IDisposable;

import openfl.display.Sprite;

class ResizeableBarPieceView extends Sprite implements IDisposable
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
	
	public function dispose() {
	}
}
