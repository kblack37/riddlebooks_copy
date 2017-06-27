package wordproblem.engine.component
{
    import dragonbox.common.util.XString;

    /**
     * This component signifies that an item has a hidden and an unhidden status.
     * 
     * In the common case a hidden status means that only a transparent silouhette of the
     * item should appear.
     * 
     * TODO: If we wanted more general control over how something is rendered, then a component should not
     * need to specify the render status to switch if one of it's values changed.
     * Instead: would have some code somewhere that knows for each item how all the various properties contained within
     * it should modify its render status.
     * 
     */
    public class HiddenItemComponent extends Component
    {
        public static const TYPE_ID:String = "HiddenItemComponent";
        
        public var isHidden:Boolean;
        
        public function HiddenItemComponent(entityId:String)
        {
            super(entityId, TYPE_ID);
        }
        
        override public function deserialize(data:Object):void
        {
            if (data.hasOwnProperty("isHidden"))
            {
                this.isHidden = XString.stringToBool(data.isHidden);
            }
            else
            {
                // By default an item is initially hidden
                this.isHidden = true;
            }
        }
    }
}