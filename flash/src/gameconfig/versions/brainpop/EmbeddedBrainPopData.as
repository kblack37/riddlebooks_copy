package gameconfig.versions.brainpop
{
    import wordproblem.resource.bundles.ResourceBundle;

    public class EmbeddedBrainPopData extends ResourceBundle
    {
        // Brainpop should use the concept explicitness data designed by the education researchers
        [Embed(source="/../src/gameconfig/versions/brainpop/levels/sequence_A.json", mimeType="application/octet-stream")]
        public static const sequence_A:Class;
        [Embed(source="/../src/gameconfig/versions/brainpop/levels/sequence_B.json", mimeType="application/octet-stream")]
        public static const sequence_B:Class;
        [Embed(source="/../src/gameconfig/versions/brainpop/levels/sequence_C.json", mimeType="application/octet-stream")]
        public static const sequence_C:Class;
        [Embed(source="/../src/gameconfig/versions/brainpop/levels/sequence_D.json", mimeType="application/octet-stream")]
        public static const sequence_D:Class;
        
        [Embed(source="/../src/gameconfig/versions/brainpop/items_db_small_eggs.json", mimeType="application/octet-stream")]
        public static const items_db:Class;
        [Embed(source="/../src/gameconfig/commonresource/achievements_default.json", mimeType="application/octet-stream")]
        public static const achievements:Class;
        [Embed(source="/../assets/items/game_items.json", mimeType="application/octet-stream")]
        public static const game_items:Class;
        
        [Embed(source="/../src/gameconfig/versions/brainpop/level_select_config.json", mimeType="application/octet-stream")]
        public static const level_select_config:Class;
        [Embed(source="/../assets/characters/characters.json", mimeType="application/octet-stream")]
        public static const characters:Class;
        
        public function EmbeddedBrainPopData()
        {
        }
    }
}