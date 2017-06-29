package gameconfig.versions.copilot;


import wordproblem.resource.bundles.ResourceBundle;

class EmbeddedCopilotBundle extends ResourceBundle
{
    @:meta(Embed(source="/../assets/levelPacks/copilot/copilotFantasy1A.json",mimeType="application/octet-stream"))

    public static var copilotFantasy1A : Class<Dynamic>;
    @:meta(Embed(source="/../assets/levelPacks/copilot/copilotFantasy1B.json",mimeType="application/octet-stream"))

    public static var copilotFantasy1B : Class<Dynamic>;
    @:meta(Embed(source="/../assets/levelPacks/copilot/copilotFantasy2A.json",mimeType="application/octet-stream"))

    public static var copilotFantasy2A : Class<Dynamic>;
    @:meta(Embed(source="/../assets/levelPacks/copilot/copilotFantasy2B.json",mimeType="application/octet-stream"))

    public static var copilotFantasy2B : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/levelPacks/copilot/copilotMystery1A.json",mimeType="application/octet-stream"))

    public static var copilotMystery1A : Class<Dynamic>;
    @:meta(Embed(source="/../assets/levelPacks/copilot/copilotMystery1B.json",mimeType="application/octet-stream"))

    public static var copilotMystery1B : Class<Dynamic>;
    @:meta(Embed(source="/../assets/levelPacks/copilot/copilotMystery2A.json",mimeType="application/octet-stream"))

    public static var copilotMystery2A : Class<Dynamic>;
    @:meta(Embed(source="/../assets/levelPacks/copilot/copilotMystery2B.json",mimeType="application/octet-stream"))

    public static var copilotMystery2B : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/levelPacks/copilot/copilotScifi1A.json",mimeType="application/octet-stream"))

    public static var copilotScifi1A : Class<Dynamic>;
    @:meta(Embed(source="/../assets/levelPacks/copilot/copilotScifi1B.json",mimeType="application/octet-stream"))

    public static var copilotScifi1B : Class<Dynamic>;
    @:meta(Embed(source="/../assets/levelPacks/copilot/copilotScifi2A.json",mimeType="application/octet-stream"))

    public static var copilotScifi2A : Class<Dynamic>;
    @:meta(Embed(source="/../assets/levelPacks/copilot/copilotScifi2B.json",mimeType="application/octet-stream"))

    public static var copilotScifi2B : Class<Dynamic>;
    
    @:meta(Embed(source="/../assets/levelPacks/copilot/copilotTutorials.json",mimeType="application/octet-stream"))

    public static var copilotTutorials : Class<Dynamic>;
    
    public function new()
    {
        super(ResourceBundle.STARLING_ASSET_COMPATIBLE);
    }
}
