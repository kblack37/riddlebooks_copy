package gameconfig.versions.debug
{
    import wordproblem.resource.bundles.ResourceBundle;
    
    public class ConfigurationBundle extends ResourceBundle
    {
        [Embed(source="config.xml", mimeType="application/octet-stream")] 
        public static const config:Class;
        
        public function ConfigurationBundle()
        {
            super();
            
            m_nameToResourceMap["config"] = config;//"C:/Users/szetor/Repos/Repos/algebra_adventure/src/gameconfig/versions/debug/config.xml";
        }
    }
}