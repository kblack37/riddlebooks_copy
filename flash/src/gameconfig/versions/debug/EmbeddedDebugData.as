package gameconfig.versions.debug
{
    import wordproblem.resource.bundles.ResourceBundle;
    
    public class EmbeddedDebugData extends ResourceBundle
    {
        [Embed(source="/../src/gameconfig/versions/debug/booklet_A.json", mimeType="application/octet-stream")]
        //[Embed(source="/../src/gameconfig/versions/debug/playtest_012116.json", mimeType="application/octet-stream")]
        public static const sequence_genres_A:Class;
        
        [Embed(source="/../src/gameconfig/versions/debug/items_db_small_eggs.json", mimeType="application/octet-stream")]
        public static const items_db:Class;
        [Embed(source="/../src/gameconfig/versions/challenge0114/achievements.json", mimeType="application/octet-stream")]
        public static const achievements:Class;
        [Embed(source="/../assets/items/game_items.json", mimeType="application/octet-stream")]
        public static const game_items:Class;
        
        [Embed(source="/../src/gameconfig/versions/debug/level_select_config.json", mimeType="application/octet-stream")]
        public static const level_select_config:Class;
        [Embed(source="/../assets/characters/characters.json", mimeType="application/octet-stream")]
        public static const characters:Class;
        
        public function EmbeddedDebugData()
        {
            super();
        }
    }
}