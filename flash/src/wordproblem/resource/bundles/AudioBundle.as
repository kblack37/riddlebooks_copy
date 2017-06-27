package wordproblem.resource.bundles
{
    public class AudioBundle extends ResourceBundle
    {
        [Embed(source="/../assets/audio/audio.xml", mimeType="application/octet-stream")]
        public static var audio:Class;
        
        [Embed(source="/../assets/audio/chime.mp3")]
        public static const chime:Class;
        [Embed(source="/../assets/audio/bg_music1.mp3")]
        public static const bg_music1:Class;
        [Embed(source="/../assets/audio/bg_music2.mp3")]
        public static const bg_music2:Class;
        
        public function AudioBundle()
        {
            super(ResourceBundle.STARLING_ASSET_COMPATIBLE);
        }
    }
}