package gameconfig.versions.brainpopturk;


import wordproblem.resource.bundles.ResourceBundle;

class EmbeddedData extends ResourceBundle
{
    @:meta(Embed(source="/../src/gameconfig/versions/brainpopturk/levelsequences/sequence_brainpop_turk.json",mimeType="application/octet-stream"))

    public static var sequence_brainpop_turk : Class<Dynamic>;
    
    @:meta(Embed(source="/../src/gameconfig/versions/brainpopturk/items_db_small_eggs.json",mimeType="application/octet-stream"))

    public static var items_db : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/versions/brainpopturk/achievements.json",mimeType="application/octet-stream"))

    public static var achievements : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/versions/brainpopturk/game_items.json",mimeType="application/octet-stream"))

    public static var game_items : Class<Dynamic>;
    
    @:meta(Embed(source="/../src/gameconfig/versions/brainpopturk/level_select_config.json",mimeType="application/octet-stream"))

    public static var level_select_config : Class<Dynamic>;
    @:meta(Embed(source="/../assets/characters/characters.json",mimeType="application/octet-stream"))

    public static var characters : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/strings/default_barmodel_hints.xml",mimeType="application/octet-stream"))

    public static var default_barmodel_hints : Class<Dynamic>;
    
    public function new()
    {
        super();
    }
}
