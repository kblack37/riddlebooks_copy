package wordproblem.engine.text.view
{
    import flash.geom.Point;
    
    import starling.display.DisplayObject;
    
    import wordproblem.engine.text.model.ImageNode;
    
    /**
     * View representating a single still image.
     */
    public class ImageView extends DocumentView
    {
        public function ImageView(node:ImageNode, image:DisplayObject)
        {
            super(node);
            
            this.addChild(image);
        }
        
        override public function hitTestPoint(globalPoint:Point, ignoreNonSelectable:Boolean=true):DocumentView
        {
            const hitView:Boolean = this.hitTest(this.globalToLocal(globalPoint)) != null;
            var viewToReturn:DocumentView = null;
            if (hitView && (super.node.getSelectable() || !ignoreNonSelectable))
            {
                viewToReturn = this;
            }
            return viewToReturn;
        }
    }
}