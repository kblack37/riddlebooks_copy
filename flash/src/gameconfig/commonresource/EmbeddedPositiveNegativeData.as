package gameconfig.commonresource
{
    import wordproblem.resource.bundles.ResourceBundle;

    /**
     * All data resources customized for the positive vs negative items experiment
     */
    public class EmbeddedPositiveNegativeData extends ResourceBundle
    {
        [Embed(source="/../assets/levels/positive_negative_experiment/booklet_A.json", mimeType="application/octet-stream")]
        public static const sequence_genres_A:Class;
        [Embed(source="/../assets/levels/positive_negative_experiment/booklet_B.json", mimeType="application/octet-stream")]
        public static const sequence_genres_B:Class;
        
        [Embed(source="/../assets/items/items_db.json", mimeType="application/octet-stream")]
        public static const items_db:Class;
        [Embed(source="/../assets/items/game_items.json", mimeType="application/octet-stream")]
        public static const game_items:Class;
        
        [Embed(source="/../src/gameconfig/commonresource/genres_and_chapters.json", mimeType="application/octet-stream")]
        public static const genres_and_chapters:Class;
        [Embed(source="/../src/gameconfig/commonresource/achievements_default.json", mimeType="application/octet-stream")]
        public static const achievements:Class;
        [Embed(source="/../assets/characters/characters.json", mimeType="application/octet-stream")]
        public static const characters:Class;
        
        public function EmbeddedPositiveNegativeData()
        {
            super();
        }
    }
}