package wordproblem.engine.component
{
    import starling.display.DisplayObject;
    
    import wordproblem.engine.animation.LinkToAnimation;

    /**
     * Component is used to link an entity to it a secondary dragged object.
     * 
     * The secondard object will link to the main renderer for the entity
     */
    public class LinkToDraggedObjectComponent extends Component
    {
        public static const TYPE_ID:String = "LinkToDraggedObjectComponent";
        
        /**
         * Some distinguishing property on the dragged object to indicate it is in fact
         * the one that should be linked to a given entity.
         * 
         * For example it can be the expression string or another entity id
         */
        public var draggedObjectId:String;
        
        /**
         * Reference to the display object
         */
        public var draggedObjectDisplay:DisplayObject;
        
        /**
         * Get whether the animation for this link is playing already
         */
        public var animationPlaying:Boolean;
        
        /**
         * Reference to the display object representing this entity. The dragged object
         * should link to this object.
         */
        public var targetObjectDisplay:DisplayObject;
        
        /**
         * The amount to shift the x anchor point on the target display object
         */
        public var xOffset:Number;
        
        /**
         * The amount to shift the y anchor point on the target display object
         */
        public var yOffset:Number;
        
        /**
         * Need to keep a reference to the animation that is playing. This disposal of this component needs to immediately
         * trigger the disposal of the connected animation
         */
        public var animation:LinkToAnimation;
        
        public function LinkToDraggedObjectComponent(entityId:String, 
                                                     draggedObjectId:String, 
                                                     xOffset:Number, 
                                                     yOffset:Number)
        {
            super(entityId, TYPE_ID);
            
            this.refresh(draggedObjectId, xOffset, yOffset)
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            if (this.animation != null)
            {
                this.animation.stop();
            }
        }
        
        override public function deserialize(data:Object):void
        {
            var draggedObjectId:String = data.draggedObjectId;
            var xOffset:Number = data.xOffset;
            var yOffset:Number = data.yOffset;
            this.refresh(draggedObjectId, xOffset, yOffset);
        }
        
        private function refresh(draggedObjectId:String, xOffset:Number, yOffset:Number):void
        {
            this.draggedObjectId = draggedObjectId;
            this.animationPlaying = false;
            this.targetObjectDisplay = null;
            this.xOffset = xOffset;
            this.yOffset = yOffset;
            this.animation = null;
        }
    }
}