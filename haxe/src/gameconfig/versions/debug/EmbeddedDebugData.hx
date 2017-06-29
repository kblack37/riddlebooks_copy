package gameconfig.versions.debug;


import wordproblem.resource.bundles.ResourceBundle;

class EmbeddedDebugData extends ResourceBundle
{
    @:meta(Embed(source="/../src/gameconfig/versions/debug/booklet_A.json",mimeType="application/octet-stream"))

    //[Embed(source="/../src/gameconfig/versions/debug/playtest_012116.json", mimeType="application/octet-stream")]
    public static var sequence_genres_A : Class<Dynamic>;
    
    @:meta(Embed(source="/../src/gameconfig/versions/debug/items_db_small_eggs.json",mimeType="application/octet-stream"))

    public static var items_db : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/versions/challenge0114/achievements.json",mimeType="application/octet-stream"))

    public static var achievements : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/game_items.json",mimeType="application/octet-stream"))

    public static var game_items : Class<Dynamic>;
    
    @:meta(Embed(source="/../src/gameconfig/versions/debug/level_select_config.json",mimeType="application/octet-stream"))

    public static var level_select_config : Class<Dynamic>;
    @:meta(Embed(source="/../assets/characters/characters.json",mimeType="application/octet-stream"))

    public static var characters : Class<Dynamic>;
    
    public function new()
    {
        super();
    }
}
