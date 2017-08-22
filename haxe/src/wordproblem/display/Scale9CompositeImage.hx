package wordproblem.display;

import dragonbox.common.dispose.IDisposable;
import openfl.display.Bitmap;
import openfl.display.DisplayObject;
import openfl.display.Sprite;

class Scale9CompositeImage extends Sprite implements IDisposable
{
    public function new(args : Array<DisplayObject>)
    {
        super();
        
        for (i in 0...args.length){
            var childToAdd : DisplayObject = try cast(args[i], DisplayObject) catch(e:Dynamic) null;
            if (childToAdd != null) 
            {
                addChild(childToAdd);
            }
        }
    }
    
    override private function set_width(value : Float) : Float
    {
        var i : Int = 0;
        var numChildren : Int = this.numChildren;
        for (i in 0...numChildren){
            this.getChildAt(i).width = value;
        }
        return value;
    }
    
    override private function set_height(value : Float) : Float
    {
        var i : Int = 0;
        var numChildren : Int = this.numChildren;
        for (i in 0...numChildren){
            this.getChildAt(i).height = value;
        }
        return value;
    }
	
	public function dispose() {
		while (numChildren > 0) {
			var child = removeChildAt(0);
			if (Std.is(child, IDisposable)) {
				cast(child, IDisposable).dispose();
			}
		}
	}
}
