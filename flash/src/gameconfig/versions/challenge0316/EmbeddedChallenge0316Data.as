package gameconfig.versions.challenge0316
{
    import wordproblem.resource.bundles.ResourceBundle;
    
    public class EmbeddedChallenge0316Data extends ResourceBundle
    {
        [Embed(source="/../src/gameconfig/versions/challenge0316/levelsequences/sequence_2_under.json", mimeType="application/octet-stream")]
        public static const sequence_2_under:Class;
        [Embed(source="/../src/gameconfig/versions/challenge0316/levelsequences/sequence_3_4.json", mimeType="application/octet-stream")]
        public static const sequence_3_4:Class;
        [Embed(source="/../src/gameconfig/versions/challenge0316/levelsequences/sequence_5_6.json", mimeType="application/octet-stream")]
        public static const sequence_5_6:Class;
        [Embed(source="/../src/gameconfig/versions/challenge0316/levelsequences/sequence_7_over.json", mimeType="application/octet-stream")]
        public static const sequence_7_over:Class;
        
        [Embed(source="/../src/gameconfig/versions/challenge0316/items_db_small_eggs.json", mimeType="application/octet-stream")]
        public static const items_db:Class;
        [Embed(source="/../src/gameconfig/versions/challenge0114/achievements.json", mimeType="application/octet-stream")]
        public static const achievements:Class;
        [Embed(source="/../assets/items/game_items.json", mimeType="application/octet-stream")]
        public static const game_items:Class;
        
        [Embed(source="/../src/gameconfig/versions/challenge0316/level_select_config.json", mimeType="application/octet-stream")]
        public static const level_select_config:Class;
        [Embed(source="/../assets/characters/characters.json", mimeType="application/octet-stream")]
        public static const characters:Class;
        
        public function EmbeddedChallenge0316Data()
        {
            super();
        }
    }
}