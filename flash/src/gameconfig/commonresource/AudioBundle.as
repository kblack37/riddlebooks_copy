package gameconfig.commonresource
{
    import wordproblem.resource.bundles.ResourceBundle;

    public class AudioBundle extends ResourceBundle
    {
        [Embed(source="/../assets/audio/audio.xml", mimeType="application/octet-stream")]
        public static var audio:Class;
        
        [Embed(source="/../assets/audio/SndEff_pageflip_v1.mp3")]
        public static const SndEff_pageflip_v1:Class;
        
        [Embed(source="/../assets/audio/SndEff_bookopen_v1.mp3")]
        public static const SndEff_bookopen_v1:Class;
        
        [Embed(source="/../assets/audio/SndEff_cardflip_v1.mp3")]
        public static const SndEff_cardflip_v1:Class;
        
        [Embed(source="/../assets/audio/SndEff_text2card_v1.mp3")]
        public static const SndEff_text2card_v1:Class;
        [Embed(source="/../assets/audio/SndEff_text2card_v2.mp3")]
        public static const SndEff_text2card_v2:Class;
        [Embed(source="/../assets/audio/SndEff_text2card_v3.mp3")]
        public static const SndEff_text2card_v3:Class;

        [Embed(source="/../assets/audio/SndEff_card2deck_v1.mp3")]
        public static const SndEff_card2deck_v1:Class;
        [Embed(source="/../assets/audio/SndEff_card2deck_v2.mp3")]
        public static const SndEff_card2deck_v2:Class;
        [Embed(source="/../assets/audio/SndEff_card2deck_v3.mp3")]
        public static const SndEff_card2deck_v3:Class;

        [Embed(source="/../assets/audio/SndEff_carddrop_v2.mp3")]
        public static const SndEff_carddrop_v2:Class;
        [Embed(source="/../assets/audio/SndEff_carddrop_v3.mp3")]
        public static const SndEff_carddrop_v3:Class;
        
        [Embed(source="/../assets/audio/SndEff_Win.mp3")]
        public static const SndEff_Win:Class;
        [Embed(source="/../assets/audio/SndEff_Win2.mp3")]
        public static const SndEff_Win2:Class;
        [Embed(source="/../assets/audio/SndEff_Win3.mp3")]
        public static const SndEff_Win3:Class;
        
        [Embed(source="/../assets/audio/SndEff_Wrong.mp3")]
        public static const SndEff_Wrong:Class;
        [Embed(source="/../assets/audio/SndEff_Wrong2.mp3")]
        public static const SndEff_Wrong2:Class;
        [Embed(source="/../assets/audio/SndEff_Wrong3.mp3")]
        public static const SndEff_Wrong3:Class;
       
                
        public function AudioBundle()
        {
            super();
        }
    }
}