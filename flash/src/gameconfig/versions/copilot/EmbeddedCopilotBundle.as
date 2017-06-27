package gameconfig.versions.copilot
{
    import wordproblem.resource.bundles.ResourceBundle;

    public class EmbeddedCopilotBundle extends ResourceBundle
    {
        [Embed(source="/../assets/levelPacks/copilot/copilotFantasy1A.json", mimeType="application/octet-stream")]
        public static const copilotFantasy1A:Class;
        [Embed(source="/../assets/levelPacks/copilot/copilotFantasy1B.json", mimeType="application/octet-stream")]
        public static const copilotFantasy1B:Class;
        [Embed(source="/../assets/levelPacks/copilot/copilotFantasy2A.json", mimeType="application/octet-stream")]
        public static const copilotFantasy2A:Class;
        [Embed(source="/../assets/levelPacks/copilot/copilotFantasy2B.json", mimeType="application/octet-stream")]
        public static const copilotFantasy2B:Class;
        
        [Embed(source="/../assets/levelPacks/copilot/copilotMystery1A.json", mimeType="application/octet-stream")]
        public static const copilotMystery1A:Class;
        [Embed(source="/../assets/levelPacks/copilot/copilotMystery1B.json", mimeType="application/octet-stream")]
        public static const copilotMystery1B:Class;
        [Embed(source="/../assets/levelPacks/copilot/copilotMystery2A.json", mimeType="application/octet-stream")]
        public static const copilotMystery2A:Class;
        [Embed(source="/../assets/levelPacks/copilot/copilotMystery2B.json", mimeType="application/octet-stream")]
        public static const copilotMystery2B:Class;
        
        [Embed(source="/../assets/levelPacks/copilot/copilotScifi1A.json", mimeType="application/octet-stream")]
        public static const copilotScifi1A:Class;
        [Embed(source="/../assets/levelPacks/copilot/copilotScifi1B.json", mimeType="application/octet-stream")]
        public static const copilotScifi1B:Class;
        [Embed(source="/../assets/levelPacks/copilot/copilotScifi2A.json", mimeType="application/octet-stream")]
        public static const copilotScifi2A:Class;
        [Embed(source="/../assets/levelPacks/copilot/copilotScifi2B.json", mimeType="application/octet-stream")]
        public static const copilotScifi2B:Class;
        
        [Embed(source="/../assets/levelPacks/copilot/copilotTutorials.json", mimeType="application/octet-stream")]
        public static const copilotTutorials:Class;
        
        public function EmbeddedCopilotBundle()
        {
            super(ResourceBundle.STARLING_ASSET_COMPATIBLE);
        }
    }
}