package gameconfig.versions.copilot
{
    import wordproblem.resource.bundles.ResourceBundle;

    public class EmbeddedCopilotBarModelBundle extends ResourceBundle
    {
        [Embed(source="/../assets/levelPacks/copilot/barmodel/copilotFantasy1A.json", mimeType="application/octet-stream")]
        public static const copilotFantasy1A:Class;
        [Embed(source="/../assets/levelPacks/copilot/barmodel/copilotFantasy1B.json", mimeType="application/octet-stream")]
        public static const copilotFantasy1B:Class;
        [Embed(source="/../assets/levelPacks/copilot/barmodel/copilotFantasy2A.json", mimeType="application/octet-stream")]
        public static const copilotFantasy2A:Class;
        [Embed(source="/../assets/levelPacks/copilot/barmodel/copilotFantasy2B.json", mimeType="application/octet-stream")]
        public static const copilotFantasy2B:Class;
        
        [Embed(source="/../assets/levelPacks/copilot/barmodel/copilotMystery1A.json", mimeType="application/octet-stream")]
        public static const copilotMystery1A:Class;
        [Embed(source="/../assets/levelPacks/copilot/barmodel/copilotMystery1B.json", mimeType="application/octet-stream")]
        public static const copilotMystery1B:Class;
        [Embed(source="/../assets/levelPacks/copilot/barmodel/copilotMystery2A.json", mimeType="application/octet-stream")]
        public static const copilotMystery2A:Class;
        [Embed(source="/../assets/levelPacks/copilot/barmodel/copilotMystery2B.json", mimeType="application/octet-stream")]
        public static const copilotMystery2B:Class;
        
        [Embed(source="/../assets/levelPacks/copilot/barmodel/copilotScifi1A.json", mimeType="application/octet-stream")]
        public static const copilotScifi1A:Class;
        [Embed(source="/../assets/levelPacks/copilot/barmodel/copilotScifi1B.json", mimeType="application/octet-stream")]
        public static const copilotScifi1B:Class;
        [Embed(source="/../assets/levelPacks/copilot/barmodel/copilotScifi2A.json", mimeType="application/octet-stream")]
        public static const copilotScifi2A:Class;
        [Embed(source="/../assets/levelPacks/copilot/barmodel/copilotScifi2B.json", mimeType="application/octet-stream")]
        public static const copilotScifi2B:Class;
        
        [Embed(source="/../assets/levelPacks/copilot/barmodel/copilotTutorials.json", mimeType="application/octet-stream")]
        public static const copilotTutorials:Class;
        
        public function EmbeddedCopilotBarModelBundle()
        {
            super();
        }
    }
}