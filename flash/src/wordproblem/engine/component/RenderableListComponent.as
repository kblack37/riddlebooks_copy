package wordproblem.engine.component
{
    import starling.display.DisplayObject;
    
    /**
     * Used if an entity might have several views attached to it.
     * 
     * One example usage of this is the term areas, which contain several cards possibly bound to
     * a single data value. (In this case the entity id is the data)
     */
    public class RenderableListComponent extends Component
    {
        public static const TYPE_ID:String = "RenderableListComponent";
        
        /**
         * List of display objects for the enitity, can be null
         */
        public var views:Vector.<DisplayObject>;
        
        public function RenderableListComponent(entityId:String, views:Vector.<DisplayObject>)
        {
            super(entityId, TYPE_ID);
            
            this.views = views;
        }
    }
}