package wordproblem.engine.component;

import flash.errors.Error;

import dragonbox.common.system.Map;

/**
	 * The layout of components can be thought of as being in a columns with entities acting as rows.
 * Its purpose is to manage the aggregation of properties to be applied to any game object, which
 * each property being as loosely coupled with other properties as possible.
 * 
 * The is responsible for mapping some set of entities in the game with all their relevant data
 * which are encapsulated into individual components.
	 */
class ComponentManager
{
    /**
		 * A mapping from a component type to a list of components belonging
		 * to that type.
		 * 
		 * Key: String component type
		 * Value: Vector of the components matching that type
		 */
    private var m_componentTypeToComponentsList : Map;
    
    /**
		 * A mapping from component type to a mapping of entity ids to components
		 * 
		 * Key: String component type
		 * Value: Map with key=entityId and value=component object of matching type
		 */
    private var m_componentTypeToEntityComponentMap : Map;
    
    /**
     * Remember which component types have had backing structures already created for it.
     */
    private var m_activeComponentTypes : Dynamic;
    
    /**
     * @param componentTypes
     *      Must set all initial type of components that can be added for the lifetime of
     *      this object
     */
    public function new()
    {
        m_componentTypeToComponentsList = new Map();
        m_componentTypeToEntityComponentMap = new Map();
        m_activeComponentTypes = { };
    }
    
    /**
     * Remove all components from usage, retain the types though
     */
    public function clear() : Void
    {
        for (componentType/* AS3HX WARNING could not determine type for var: componentType exp: ECall(EField(EIdent(m_componentTypeToComponentsList),getKeys),[]) type: null */ in m_componentTypeToComponentsList.getKeys())
        {
            var componentsForType : Array<Component> = m_componentTypeToComponentsList.get(componentType);
            while (componentsForType.length > 0)
            {
                var componentToRemove : Component = componentsForType.pop();
                componentToRemove.dispose();
            }
            
            var entityComponentMap : Map = m_componentTypeToEntityComponentMap.get(componentType);
            entityComponentMap.clear();
        }
    }
    
    /**
     * Get whether the given component type was registered with this manager
     * 
     * @return
     *      True if the component type maps to a valid list
     */
    public function hasComponentType(componentType : String) : Bool
    {
        return m_componentTypeToComponentsList.contains(componentType);
    }
    
    /**
     * Get a set of components from a given type
     * 
     * @return
     *      Null if the component type was never registered
     */
    public function getComponentListForType(componentType : String) : Array<Component>
    {
        if (!m_activeComponentTypes.exists(componentType)) 
        {
            initStructuresForComponentType(componentType);
        }
        return m_componentTypeToComponentsList.get(componentType);
    }
    
    public function getComponentTypeToEntityComponentMap() : Map
    {
        return m_componentTypeToEntityComponentMap;
    }
    
    /**
     * Get the component object for a particular entity and component type
     */
    public function getComponentFromEntityIdAndType(entityId : String,
            componentType : String) : Component
    {
        if (!m_activeComponentTypes.exists(componentType)) 
        {
            initStructuresForComponentType(componentType);
        }
        
        var entityToComponentMap : Map = m_componentTypeToEntityComponentMap.get(componentType);
        return entityToComponentMap.get(entityId);
    }
    
    /**
     * Registers a new component with an entity.
     * 
     * If an entity already has that component, the old component is disposed and replaced
     * by the new one.
     */
    public function addComponentToEntity(component : Component) : Void
    {
        var entityId : String = component.entityId;
        var componentType : String = component.typeId;
        
        if (!m_activeComponentTypes.exists(componentType)) 
        {
            initStructuresForComponentType(componentType);
        }
        
        var entityToComponentMap : Map = m_componentTypeToEntityComponentMap.get(componentType);
        if (entityToComponentMap == null) 
        {
            throw new Error("wordproblem.engine.component.ComponentManager::Missing component type " + componentType);
        }  // Discard old component if it exists  
        
        
        
        if (entityToComponentMap.contains(entityId)) 
        {
            removeComponentFromEntity(entityId, componentType);
        }
        
        entityToComponentMap.put(entityId, component);
        var componentList : Array<Component> = m_componentTypeToComponentsList.get(componentType);
        componentList.push(component);
    }
    
    /**
     * Remove a single component from a particular entity
     */
    public function removeComponentFromEntity(entityId : String, componentType : String) : Void
    {
        var success : Bool = false;
        var entityToComponentMap : Map = m_componentTypeToEntityComponentMap.get(componentType);
        if (entityToComponentMap != null) 
        {
            var componentToRemove : Component = entityToComponentMap.get(entityId);
            entityToComponentMap.remove(entityId);
            
            if (componentToRemove != null) 
            {
                var componentList : Array<Component> = m_componentTypeToComponentsList.get(componentType);
                componentList.splice(Lambda.indexOf(componentList, componentToRemove), 1);
                
                componentToRemove.dispose();
                success = true;
            }
        }
        
        if (!success) 
        {
            trace("wordproblem.engine.component.ComponentManager::Cannot remove " + componentType + " from " + entityId);
        }
    }
    
    /**
     * Remove all the components belonging to an entity
     */
    public function removeAllComponentsFromEntity(entityIdToRemove : String) : Void
    {
        var componentType : String;
        var componentList : Array<Component>;
        var entityComponentMap : Map;
        for (componentType/* AS3HX WARNING could not determine type for var: componentType exp: ECall(EField(EIdent(m_componentTypeToComponentsList),getKeys),[]) type: null */ in m_componentTypeToComponentsList.getKeys())
        {
            componentList = m_componentTypeToComponentsList.get(componentType);
            entityComponentMap = m_componentTypeToEntityComponentMap.get(componentType);
            
            var entityId : String;
            var componentToRemove : Component;
            for (entityId/* AS3HX WARNING could not determine type for var: entityId exp: ECall(EField(EIdent(entityComponentMap),getKeys),[]) type: null */ in entityComponentMap.getKeys())
            {
                // Need to delete from both maps, assume each entity has at most one
                // of each component type
                if (entityId == entityIdToRemove) 
                {
                    componentToRemove = entityComponentMap.get(entityId);
                    componentToRemove.dispose();
                    componentList.splice(Lambda.indexOf(componentList, componentToRemove), 1);
                    
                    entityComponentMap.remove(entityId);
                    break;
                }
            }
        }
    }
    
    /**
     * Get back an list of all entity ids associated with components stored in this manager
     */
    public function getEntityIds(outEntityIds : Array<String>) : Void
    {
        var componentTypes : Array<Dynamic> = m_componentTypeToComponentsList.getKeys();
        var numTypes : Int = componentTypes.length;
        var i : Int;
        for (i in 0...numTypes){
            var entityMap : Map = m_componentTypeToEntityComponentMap.get(componentTypes[i]);
            var entities : Array<Dynamic> = entityMap.getKeys();
            var numEntities : Int = entities.length;
            var j : Int;
            for (j in 0...numEntities){
                var entityId : String = entities[j];
                if (Lambda.indexOf(outEntityIds, entityId) == -1) 
                {
                    outEntityIds.push(entityId);
                }
            }
        }
    }
    
    private function initStructuresForComponentType(type : String) : Void
    {
        Reflect.setField(m_activeComponentTypes, type, true);
        m_componentTypeToComponentsList.put(type, new Array<Component>());
        m_componentTypeToEntityComponentMap.put(type, new Map());
    }
}
