package wordproblem.engine.component
{
    /**
     * Indicate that an entity is bound to one particular word problem genre.
     * 
     * It's usage is to make it clear where a reward item should be placed in the level selection screen
     */
    public class GenreIdComponent extends Component
    {
        public static const TYPE_ID:String = "GenreIdComponent";
        
        /**
         * The genre id is the same string that is used to tag GenreLevelPacks within the level
         * management system.
         */
        public var genreId:String;
        
        public function GenreIdComponent(entityId:String)
        {
            super(entityId, TYPE_ID);
        }
        
        override public function deserialize(data:Object):void
        {
            this.genreId = data.genreId;
        }
    }
}