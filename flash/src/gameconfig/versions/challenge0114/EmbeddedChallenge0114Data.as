package gameconfig.versions.challenge0114
{
    import wordproblem.resource.bundles.ResourceBundle;
    
    public class EmbeddedChallenge0114Data extends ResourceBundle
    {
        [Embed(source="/../assets/levels/challenge0114/booklet_A.json", mimeType="application/octet-stream")]
        public static const sequence_genres_A:Class;
        [Embed(source="/../assets/levels/challenge0114/booklet_B.json", mimeType="application/octet-stream")]
        public static const sequence_genres_B:Class;
        
        [Embed(source="/../src/gameconfig/versions/challenge0114/items_db_small_eggs.json", mimeType="application/octet-stream")]
        public static const items_db:Class;
        [Embed(source="/../src/gameconfig/versions/challenge0114/achievements.json", mimeType="application/octet-stream")]
        public static const achievements:Class;
        [Embed(source="/../assets/items/game_items.json", mimeType="application/octet-stream")]
        public static const game_items:Class;
        
        [Embed(source="/../src/gameconfig/versions/challenge0114/level_select_config.json", mimeType="application/octet-stream")]
        public static const level_select_config:Class;
        [Embed(source="/../assets/characters/characters.json", mimeType="application/octet-stream")]
        public static const characters:Class;
        
        public function EmbeddedChallenge0114Data()
        {
            super();
        }
    }
}