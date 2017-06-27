package gameconfig.versions.challengedemo
{
    import wordproblem.resource.bundles.ResourceBundle;
    
    public class EmbeddedData extends ResourceBundle
    {
        [Embed(source="/../src/gameconfig/versions/challengedemo/levelsequences/sequence_fall_2016_demo_2_under.json", mimeType="application/octet-stream")]
        public static const sequence_grade_2_under:Class;
        [Embed(source="/../src/gameconfig/versions/challengedemo/levelsequences/sequence_fall_2016_demo_3_4.json", mimeType="application/octet-stream")]
        public static const sequence_grade_3_4:Class;
        [Embed(source="/../src/gameconfig/versions/challengedemo/levelsequences/sequence_fall_2016_demo_5_6.json", mimeType="application/octet-stream")]
        public static const sequence_grade_5_6:Class;
        [Embed(source="/../src/gameconfig/versions/challengedemo/levelsequences/sequence_fall_2016_demo_7_up.json", mimeType="application/octet-stream")]
        public static const sequence_grade_7_up:Class;
        [Embed(source="/../src/gameconfig/versions/challengedemo/levelsequences/sequence_fall_2016_demo_all.json", mimeType="application/octet-stream")]
        public static const sequence_grade_all:Class;
        
        [Embed(source="/../src/gameconfig/versions/brainpopturk/items_db_small_eggs.json", mimeType="application/octet-stream")]
        public static const items_db:Class;
        [Embed(source="/../src/gameconfig/versions/challengedemo/data/achievements.json", mimeType="application/octet-stream")]
        public static const achievements:Class;
        [Embed(source="/../src/gameconfig/versions/brainpopturk/game_items.json", mimeType="application/octet-stream")]
        public static const game_items:Class;
        
        [Embed(source="/../src/gameconfig/versions/challengedemo/data/level_select_config.json", mimeType="application/octet-stream")]
        public static const level_select_config:Class;
        [Embed(source="/../assets/characters/characters.json", mimeType="application/octet-stream")]
        public static const characters:Class;
        
        public function EmbeddedData()
        {
            super();
        }
    }
}