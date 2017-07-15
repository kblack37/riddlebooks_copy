package wordproblem.engine.text.view;


import flash.geom.Point;

import starling.display.DisplayObject;

import wordproblem.engine.text.model.ImageNode;

/**
 * View representating a single still image.
 */
class ImageView extends DocumentView
{
    public function new(node : ImageNode, image : DisplayObject)
    {
        super(node);
        
        this.addChild(image);
    }
    
    override public function hitTestPoint(globalPoint : Point, ignoreNonSelectable : Bool = true) : DocumentView
    {
        var hitView : Bool = this.hitTest(this.globalToLocal(globalPoint)) != null;
        var viewToReturn : DocumentView = null;
        if (hitView && (this.node.getSelectable() || !ignoreNonSelectable)) 
        {
            viewToReturn = this;
        }
        return viewToReturn;
    }
}
