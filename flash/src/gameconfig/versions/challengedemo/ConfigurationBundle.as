package gameconfig.versions.challengedemo
{
    import wordproblem.resource.bundles.ResourceBundle;
    
    public class ConfigurationBundle extends ResourceBundle
    {
        [Embed(source="data/config.xml", mimeType="application/octet-stream")] 
        public static const config:Class;
        
        public function ConfigurationBundle()
        {
            super();
            
            m_nameToResourceMap["config"] = config;
        }
    }
}