package gameconfig.commonresource
{
    import wordproblem.resource.bundles.ResourceBundle;

    public class EmbeddedDefaultItemsChapterCharacterData extends ResourceBundle
    {
        [Embed(source="/../assets/items/items_db.json", mimeType="application/octet-stream")]
        public static const items_db:Class;
        [Embed(source="/../assets/items/game_items.json", mimeType="application/octet-stream")]
        public static const game_items:Class;
        
        [Embed(source="/gameconfig/commonresource/genres_and_chapters.json", mimeType="application/octet-stream")]
        public static const chapters:Class;
        [Embed(source="/../assets/characters/characters.json", mimeType="application/octet-stream")]
        public static const characters:Class;
        
        public function EmbeddedDefaultItemsChapterCharacterData()
        {
            super();
        }
    }
}