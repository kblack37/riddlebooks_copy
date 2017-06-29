package gameconfig.versions.challenge0114;


import wordproblem.resource.bundles.ResourceBundle;

class EmbeddedChallenge0114Data extends ResourceBundle
{
    @:meta(Embed(source="/../assets/levels/challenge0114/booklet_A.json",mimeType="application/octet-stream"))

    public static var sequence_genres_A : Class<Dynamic>;
    @:meta(Embed(source="/../assets/levels/challenge0114/booklet_B.json",mimeType="application/octet-stream"))

    public static var sequence_genres_B : Class<Dynamic>;
    
    @:meta(Embed(source="/../src/gameconfig/versions/challenge0114/items_db_small_eggs.json",mimeType="application/octet-stream"))

    public static var items_db : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/versions/challenge0114/achievements.json",mimeType="application/octet-stream"))

    public static var achievements : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/game_items.json",mimeType="application/octet-stream"))

    public static var game_items : Class<Dynamic>;
    
    @:meta(Embed(source="/../src/gameconfig/versions/challenge0114/level_select_config.json",mimeType="application/octet-stream"))

    public static var level_select_config : Class<Dynamic>;
    @:meta(Embed(source="/../assets/characters/characters.json",mimeType="application/octet-stream"))

    public static var characters : Class<Dynamic>;
    
    public function new()
    {
        super();
    }
}
