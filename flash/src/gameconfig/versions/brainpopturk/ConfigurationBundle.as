package gameconfig.versions.brainpopturk
{
    import wordproblem.resource.bundles.ResourceBundle;
    
    public class ConfigurationBundle extends ResourceBundle
    {
        [Embed(source="config_abcya.xml", mimeType="application/octet-stream")] 
        public static const config:Class;
        
        public function ConfigurationBundle()
        {
            super();
            
            m_nameToResourceMap["config"] = config;
        }
    }
}