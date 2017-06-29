package gameconfig.commonresource;


import wordproblem.resource.bundles.ResourceBundle;

/**
 * All data resources customized for the positive vs negative items experiment
 */
class EmbeddedPositiveNegativeData extends ResourceBundle
{
    @:meta(Embed(source="/../assets/levels/positive_negative_experiment/booklet_A.json",mimeType="application/octet-stream"))

    public static var sequence_genres_A : Class<Dynamic>;
    @:meta(Embed(source="/../assets/levels/positive_negative_experiment/booklet_B.json",mimeType="application/octet-stream"))

    public static var sequence_genres_B : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/items/items_db.json",mimeType="application/octet-stream"))

    public static var items_db : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/game_items.json",mimeType="application/octet-stream"))

    public static var game_items : Class<Dynamic>;
    
    @:meta(Embed(source="/../src/gameconfig/commonresource/genres_and_chapters.json",mimeType="application/octet-stream"))

    public static var genres_and_chapters : Class<Dynamic>;
    @:meta(Embed(source="/../src/gameconfig/commonresource/achievements_default.json",mimeType="application/octet-stream"))

    public static var achievements : Class<Dynamic>;
    @:meta(Embed(source="/../assets/characters/characters.json",mimeType="application/octet-stream"))

    public static var characters : Class<Dynamic>;
    
    public function new()
    {
        super();
    }
}
