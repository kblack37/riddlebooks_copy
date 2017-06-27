package wordproblem.engine.component
{
    /**
     * Used if an item should have an icon to be displayed when the player gets the item as a reward, assume that
     * the icon is always a single static image.
     * 
     * Note that this is a bit different from the TextureCollectionComponent since that bit of
     * data is used to draw the item within the game world. In addition some items still need the icon
     * but don't have a single static image because it uses a spritesheet or has multiple stages.
     */
    public class RewardIconComponent extends Component
    {
        public static const TYPE_ID:String = "RewardIconComponent";
        
        /**
         * Name of the texture to use for the icon.
         */
        public var textureName:String;
        
        public function RewardIconComponent(entityId:String)
        {
            super(entityId, TYPE_ID);
        }
        
        override public function deserialize(data:Object):void
        {
            this.textureName = data.textureName;
        }
    }
}