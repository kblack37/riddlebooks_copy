package gameconfig.commonresource;


import wordproblem.resource.bundles.ResourceBundle;

class AudioBundle extends ResourceBundle
{
    @:meta(Embed(source="/../assets/audio/audio.xml",mimeType="application/octet-stream"))

    public static var audio : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/audio/SndEff_pageflip_v1.mp3"))

    public static var SndEff_pageflip_v1 : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/audio/SndEff_bookopen_v1.mp3"))

    public static var SndEff_bookopen_v1 : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/audio/SndEff_cardflip_v1.mp3"))

    public static var SndEff_cardflip_v1 : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/audio/SndEff_text2card_v1.mp3"))

    public static var SndEff_text2card_v1 : Class<Dynamic>;
    @:meta(Embed(source="/../assets/audio/SndEff_text2card_v2.mp3"))

    public static var SndEff_text2card_v2 : Class<Dynamic>;
    @:meta(Embed(source="/../assets/audio/SndEff_text2card_v3.mp3"))

    public static var SndEff_text2card_v3 : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/audio/SndEff_card2deck_v1.mp3"))

    public static var SndEff_card2deck_v1 : Class<Dynamic>;
    @:meta(Embed(source="/../assets/audio/SndEff_card2deck_v2.mp3"))

    public static var SndEff_card2deck_v2 : Class<Dynamic>;
    @:meta(Embed(source="/../assets/audio/SndEff_card2deck_v3.mp3"))

    public static var SndEff_card2deck_v3 : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/audio/SndEff_carddrop_v2.mp3"))

    public static var SndEff_carddrop_v2 : Class<Dynamic>;
    @:meta(Embed(source="/../assets/audio/SndEff_carddrop_v3.mp3"))

    public static var SndEff_carddrop_v3 : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/audio/SndEff_Win.mp3"))

    public static var SndEff_Win : Class<Dynamic>;
    @:meta(Embed(source="/../assets/audio/SndEff_Win2.mp3"))

    public static var SndEff_Win2 : Class<Dynamic>;
    @:meta(Embed(source="/../assets/audio/SndEff_Win3.mp3"))

    public static var SndEff_Win3 : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/audio/SndEff_Wrong.mp3"))

    public static var SndEff_Wrong : Class<Dynamic>;
    @:meta(Embed(source="/../assets/audio/SndEff_Wrong2.mp3"))

    public static var SndEff_Wrong2 : Class<Dynamic>;
    @:meta(Embed(source="/../assets/audio/SndEff_Wrong3.mp3"))

    public static var SndEff_Wrong3 : Class<Dynamic>;
    
    
    public function new()
    {
        super();
    }
}
