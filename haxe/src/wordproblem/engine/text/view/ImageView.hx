package wordproblem.engine.text.view;


import openfl.geom.Point;

import openfl.display.DisplayObject;

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
    
    override public function customHitTestPoint(globalPoint : Point, ignoreNonSelectable : Bool = true) : DocumentView
    {
        var hitView : Bool = this.hitTestPoint(globalPoint.x, globalPoint.y) != null;
        var viewToReturn : DocumentView = null;
        if (hitView && (this.node.getSelectable() || !ignoreNonSelectable)) 
        {
            viewToReturn = this;
        }
        return viewToReturn;
    }
}
