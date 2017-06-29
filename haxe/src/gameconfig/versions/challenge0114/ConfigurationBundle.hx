package gameconfig.versions.challenge0114;


import wordproblem.resource.bundles.ResourceBundle;

class ConfigurationBundle extends ResourceBundle
{
    @:meta(Embed(source="config.xml",mimeType="application/octet-stream"))

    public static var config : Class<Dynamic>;
    
    public function new()
    {
        super();
        
        m_nameToResourceMap["config"] = config;
    }
}
