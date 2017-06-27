package gameconfig.versions.brainpopturk
{
    import wordproblem.resource.bundles.ResourceBundle;
    
    public class EmbeddedData extends ResourceBundle
    {
        [Embed(source="/../src/gameconfig/versions/brainpopturk/levelsequences/sequence_brainpop_turk.json", mimeType="application/octet-stream")]
        public static const sequence_brainpop_turk:Class;
        
        [Embed(source="/../src/gameconfig/versions/brainpopturk/items_db_small_eggs.json", mimeType="application/octet-stream")]
        public static const items_db:Class;
        [Embed(source="/../src/gameconfig/versions/brainpopturk/achievements.json", mimeType="application/octet-stream")]
        public static const achievements:Class;
        [Embed(source="/../src/gameconfig/versions/brainpopturk/game_items.json", mimeType="application/octet-stream")]
        public static const game_items:Class;
        
        [Embed(source="/../src/gameconfig/versions/brainpopturk/level_select_config.json", mimeType="application/octet-stream")]
        public static const level_select_config:Class;
        [Embed(source="/../assets/characters/characters.json", mimeType="application/octet-stream")]
        public static const characters:Class;
        
        [Embed(source="/../assets/strings/default_barmodel_hints.xml", mimeType="application/octet-stream")]
        public static const default_barmodel_hints:Class;
        
        public function EmbeddedData()
        {
            super();
        }
    }
}