package gameconfig.versions.challenge0316;


import wordproblem.resource.bundles.ResourceBundle;

class EmbeddedChallenge0316Data extends ResourceBundle
{
    @:meta(Embed(source="/../src/gameconfig/versions/challenge0316/levelsequences/sequence_2_under.json",mimeType="application/octet-stream"))

    public static var sequence_2_under : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/versions/challenge0316/levelsequences/sequence_3_4.json",mimeType="application/octet-stream"))

    public static var sequence_3_4 : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/versions/challenge0316/levelsequences/sequence_5_6.json",mimeType="application/octet-stream"))

    public static var sequence_5_6 : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/versions/challenge0316/levelsequences/sequence_7_over.json",mimeType="application/octet-stream"))

    public static var sequence_7_over : Class<Dynamic>;
    
    @:meta(Embed(source="/../src/gameconfig/versions/challenge0316/items_db_small_eggs.json",mimeType="application/octet-stream"))

    public static var items_db : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/versions/challenge0114/achievements.json",mimeType="application/octet-stream"))

    public static var achievements : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/game_items.json",mimeType="application/octet-stream"))

    public static var game_items : Class<Dynamic>;
    
    @:meta(Embed(source="/../src/gameconfig/versions/challenge0316/level_select_config.json",mimeType="application/octet-stream"))

    public static var level_select_config : Class<Dynamic>;
    @:meta(Embed(source="/../assets/characters/characters.json",mimeType="application/octet-stream"))

    public static var characters : Class<Dynamic>;
    
    public function new()
    {
        super();
    }
}
