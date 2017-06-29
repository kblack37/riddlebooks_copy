package wordproblem.resource.bundles;

import wordproblem.resource.bundles.ResourceBundle;

class AudioBundle extends ResourceBundle
{
    @:meta(Embed(source="/../assets/audio/audio.xml",mimeType="application/octet-stream"))

    public static var audio : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/audio/chime.mp3"))

    public static var chime : Class<Dynamic>;
    @:meta(Embed(source="/../assets/audio/bg_music1.mp3"))

    public static var bg_music1 : Class<Dynamic>;
    @:meta(Embed(source="/../assets/audio/bg_music2.mp3"))

    public static var bg_music2 : Class<Dynamic>;
    
    public function new()
    {
        super(ResourceBundle.STARLING_ASSET_COMPATIBLE);
    }
}
