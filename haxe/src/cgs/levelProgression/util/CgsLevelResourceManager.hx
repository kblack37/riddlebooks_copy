package cgs.levelProgression.util;


/**
	 * Basic implementation of an ICgsLevelSelectResource.
	 * @author Rich
	 */
class CgsLevelResourceManager implements ICgsLevelResourceManager
{
    // State
    private var m_resources : Dynamic;  // Dictionary of resources (levels and level packs)  
    
    public function new()
    {
        m_resources = {};
    }
    
    /**
		 * @inheritDoc
		 */
    public function addResource(resourceName : String, resource : String) : Void
    {
        Reflect.setField(m_resources, resourceName, resource);
    }
    
    /**
		 * @inheritDoc
		 */
    public function getResource(resourceName : String) : String
    {
        return Reflect.field(m_resources, resourceName);
    }
    
    /**
		 * @inheritDoc
		 */
    public function resourceExists(resourceName : String) : Bool
    {
        return m_resources.exists(resourceName) && Reflect.field(m_resources, resourceName) != null;
    }
}

