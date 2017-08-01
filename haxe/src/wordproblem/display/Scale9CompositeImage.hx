package wordproblem.display;


import starling.display.DisplayObject;
import starling.display.Sprite;

class Scale9CompositeImage extends Sprite
{
    public function new(args : Array<Dynamic>)
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
}
