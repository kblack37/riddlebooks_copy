package gameconfig.commonresource
{
    import wordproblem.resource.bundles.ResourceBundle;

    /**
     * This bundle contains all the text data for the bar model testing version
     */
    public class EmbeddedBarModelData extends ResourceBundle
    {
        [Embed(source="/../assets/levels/bar_model/booklet_A.json", mimeType="application/octet-stream")]
        public static const sequence_genres_A:Class;
        
        [Embed(source="/../src/gameconfig/commonresource/items_db_small_eggs.json", mimeType="application/octet-stream")]
        public static const items_db:Class;
        [Embed(source="/../src/gameconfig/commonresource/achievements_default.json", mimeType="application/octet-stream")]
        public static const achievements:Class;
        [Embed(source="/../assets/items/game_items.json", mimeType="application/octet-stream")]
        public static const game_items:Class;
        
        [Embed(source="/../src/gameconfig/commonresource/level_select_config.json", mimeType="application/octet-stream")]
        public static const level_select_config:Class;
        [Embed(source="/../assets/characters/characters.json", mimeType="application/octet-stream")]
        public static const characters:Class;
        
        public function EmbeddedBarModelData()
        {
            super();
        }
    }
}