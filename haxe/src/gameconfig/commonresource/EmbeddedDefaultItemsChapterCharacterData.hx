package gameconfig.commonresource;


import wordproblem.resource.bundles.ResourceBundle;

class EmbeddedDefaultItemsChapterCharacterData extends ResourceBundle
{
    @:meta(Embed(source="/../assets/items/items_db.json",mimeType="application/octet-stream"))

    public static var items_db : Class<Dynamic>;
    @:meta(Embed(source="/../assets/items/game_items.json",mimeType="application/octet-stream"))

    public static var game_items : Class<Dynamic>;
    
    @:meta(Embed(source="/gameconfig/commonresource/genres_and_chapters.json",mimeType="application/octet-stream"))

    public static var chapters : Class<Dynamic>;
    @:meta(Embed(source="/../assets/characters/characters.json",mimeType="application/octet-stream"))

    public static var characters : Class<Dynamic>;
    
    public function new()
    {
        super();
    }
}
