package wordproblem.engine.component
{
    import starling.display.DisplayObject;

    /**
     * Indicates that an entity should be rendered on screen.
     * Component should not subclass any display type object so the reference to
     * the view is done through composition.
     * 
     * Serves as the parent class for render components that require more data about
     * how to render to be stored
     */
    public class RenderableComponent extends Component
    {
        public static const TYPE_ID:String = "RenderableComponent";
        
        /**
         * The number is used as a special indicator for how the item should be drawn.
         * For example in the item in the shelves we treat this value as an index into a
         * collection of textures representing different states of the item.
         * 
         * (Note that since this is a stateful property that varies for different instances of
         * an item it needs to be saved)
         */
        public var renderStatus:int;
        
        /**
         * The container for graphics
         */
        public var view:DisplayObject;
        
        public var isVisible:Boolean = true;
        
        public function RenderableComponent(entityId:String, typeId:String=TYPE_ID)
        {
            super(entityId, typeId);
            
            this.renderStatus = 0;
        }
        
        override public function deserialize(data:Object):void
        {
            if (data.hasOwnProperty("isVisible"))
            {
                this.isVisible = data.isVisible;
            }
        }
    }
}