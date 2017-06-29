package gameconfig.versions.brainpop;


import wordproblem.resource.bundles.ResourceBundle;

class EmbeddedBrainPopData extends ResourceBundle
{
    // Brainpop should use the concept explicitness data designed by the education researchers
    @:meta(Embed(source="/../src/gameconfig/versions/brainpop/levels/sequence_A.json",mimeType="application/octet-stream"))

    public static var sequence_A : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/versions/brainpop/levels/sequence_B.json",mimeType="application/octet-stream"))

    public static var sequence_B : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/versions/brainpop/levels/sequence_C.json",mimeType="application/octet-stream"))

    public static var sequence_C : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/versions/brainpop/levels/sequence_D.json",mimeType="application/octet-stream"))

    public static var sequence_D : Class<Dynamic>;
    
    @:meta(Embed(source="/../src/gameconfig/versions/brainpop/items_db_small_eggs.json",mimeType="application/octet-stream"))

    public static var items_db : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/commonresource/achievements_default.json",mimeType="application/octet-stream"))

    public static var achievements : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/game_items.json",mimeType="application/octet-stream"))

    public static var game_items : Class<Dynamic>;
    
    @:meta(Embed(source="/../src/gameconfig/versions/brainpop/level_select_config.json",mimeType="application/octet-stream"))

    public static var level_select_config : Class<Dynamic>;
    @:meta(Embed(source="/../assets/characters/characters.json",mimeType="application/octet-stream"))

    public static var characters : Class<Dynamic>;
    
    public function new()
    {
        super();
    }
}
