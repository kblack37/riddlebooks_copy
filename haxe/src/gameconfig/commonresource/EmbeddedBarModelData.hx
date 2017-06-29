package gameconfig.commonresource;


import wordproblem.resource.bundles.ResourceBundle;

/**
 * This bundle contains all the text data for the bar model testing version
 */
class EmbeddedBarModelData extends ResourceBundle
{
    @:meta(Embed(source="/../assets/levels/bar_model/booklet_A.json",mimeType="application/octet-stream"))

    public static var sequence_genres_A : Class<Dynamic>;
    
    @:meta(Embed(source="/../src/gameconfig/commonresource/items_db_small_eggs.json",mimeType="application/octet-stream"))

    public static var items_db : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/commonresource/achievements_default.json",mimeType="application/octet-stream"))

    public static var achievements : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/game_items.json",mimeType="application/octet-stream"))

    public static var game_items : Class<Dynamic>;
    
    @:meta(Embed(source="/../src/gameconfig/commonresource/level_select_config.json",mimeType="application/octet-stream"))

    public static var level_select_config : Class<Dynamic>;
    @:meta(Embed(source="/../assets/characters/characters.json",mimeType="application/octet-stream"))

    public static var characters : Class<Dynamic>;
    
    public function new()
    {
        super();
    }
}
