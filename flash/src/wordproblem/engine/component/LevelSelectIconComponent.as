package wordproblem.engine.component
{
    /**
     * Used if an item should have an icon that is displayed in the level select screen within a genre.
     * We assume the icons are just static images.
     * 
     * There are two icons, one for if the item has been recieved already and the other if it is
     * still hidden.
     */
    public class LevelSelectIconComponent extends Component
    {
        public static const TYPE_ID:String = "LevelSelectIconComponent";
        
        /**
         * The texture for the icon if the reward is hidden.
         */
        public var hiddenTextureName:String;
        
        /**
         * The texture for the icon if the reward is visible.
         */
        public var shownTextureName:String;
        
        public function LevelSelectIconComponent(entityId:String)
        {
            super(entityId, TYPE_ID);
        }
        
        override public function deserialize(data:Object):void
        {
            this.hiddenTextureName = data.hiddenTextureName;
            this.shownTextureName = data.shownTextureName;
        }
    }
}