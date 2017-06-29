package gameconfig.versions.challengedemo;


import wordproblem.resource.bundles.ResourceBundle;

class EmbeddedData extends ResourceBundle
{
    @:meta(Embed(source="/../src/gameconfig/versions/challengedemo/levelsequences/sequence_fall_2016_demo_2_under.json",mimeType="application/octet-stream"))

    public static var sequence_grade_2_under : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/versions/challengedemo/levelsequences/sequence_fall_2016_demo_3_4.json",mimeType="application/octet-stream"))

    public static var sequence_grade_3_4 : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/versions/challengedemo/levelsequences/sequence_fall_2016_demo_5_6.json",mimeType="application/octet-stream"))

    public static var sequence_grade_5_6 : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/versions/challengedemo/levelsequences/sequence_fall_2016_demo_7_up.json",mimeType="application/octet-stream"))

    public static var sequence_grade_7_up : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/versions/challengedemo/levelsequences/sequence_fall_2016_demo_all.json",mimeType="application/octet-stream"))

    public static var sequence_grade_all : Class<Dynamic>;
    
    @:meta(Embed(source="/../src/gameconfig/versions/brainpopturk/items_db_small_eggs.json",mimeType="application/octet-stream"))

    public static var items_db : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/versions/challengedemo/data/achievements.json",mimeType="application/octet-stream"))

    public static var achievements : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/versions/brainpopturk/game_items.json",mimeType="application/octet-stream"))

    public static var game_items : Class<Dynamic>;
    
    @:meta(Embed(source="/../src/gameconfig/versions/challengedemo/data/level_select_config.json",mimeType="application/octet-stream"))

    public static var level_select_config : Class<Dynamic>;
    @:meta(Embed(source="/../assets/characters/characters.json",mimeType="application/octet-stream"))

    public static var characters : Class<Dynamic>;
    
    public function new()
    {
        super();
    }
}
