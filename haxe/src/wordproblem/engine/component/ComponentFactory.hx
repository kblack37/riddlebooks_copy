package wordproblem.engine.component;

import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.CurrentGrowInStageComponent;
import wordproblem.engine.component.DescriptionComponent;
import wordproblem.engine.component.EquippableComponent;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.component.GenreIdComponent;
import wordproblem.engine.component.HiddenItemComponent;
import wordproblem.engine.component.ItemBlueprintComponent;
import wordproblem.engine.component.ItemIdComponent;
import wordproblem.engine.component.LevelComponent;
import wordproblem.engine.component.LevelSelectIconComponent;
import wordproblem.engine.component.LevelsCompletedPerStageComponent;
import wordproblem.engine.component.LinkToDraggedObjectComponent;
import wordproblem.engine.component.MoveableComponent;
import wordproblem.engine.component.NameComponent;
import wordproblem.engine.component.PriceComponent;
import wordproblem.engine.component.RenderCardComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.component.RewardIconComponent;
import wordproblem.engine.component.RigidBodyComponent;
import wordproblem.engine.component.RotatableComponent;
import wordproblem.engine.component.ScanComponent;
import wordproblem.engine.component.StageChangeAnimationComponent;
import wordproblem.engine.component.TextureCollectionComponent;
import wordproblem.engine.component.TransformComponent;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

/**
 * Provides a singular method to create individual components from a well structured
 * data format.
 */
class ComponentFactory
{
    private var m_expressionCompiler : IExpressionTreeCompiler;
    
    public function new(expressionCompiler : IExpressionTreeCompiler)
    {
        m_expressionCompiler = expressionCompiler;
    }
    
    /**
     * Given an existing component manager and a raw data format, create and add components
     * to that manager.
     * 
     * @param data
     *      The data must be formatted in a very specific manner. It is an array of 'items'
     *      Form is [{"entityId":entity_name, "components":[{"typeId":type_id, "data":{data_attributes}}],...]
     */
    public function createAndAddComponentsForItemList(componentManager : ComponentManager, data : Dynamic) : Void
    {
        var entities : Array<Dynamic> = try cast(data, Array<Dynamic>) catch(e:Dynamic) null;
        
        var i : Int = 0;
        var item : Dynamic = null;
        var numItems : Int = entities.length;
        for (i in 0...numItems){
            item = entities[i];
            createAndAddComponentsForSingleItem(componentManager, item);
        }
    }
    
    /**
     *
     * @param data
     *      The data must be formatted in a very specific manner. The items contains an array of 'items'
     *      Form is {"entityId":entity_name, "components":[{"typeId":type_id, "data":{data_attributes}}]}
     */
    public function createAndAddComponentsForSingleItem(componentManager : ComponentManager, data : Dynamic) : Void
    {
        // Iterate through the components in an item and add the data directly to
        // this manager.
        var entityId : String = data.entityId;
        var components : Array<Dynamic> = data.components;
        var i : Int = 0;
        var numComponents : Int = components.length;
        for (i in 0...numComponents){
            componentManager.addComponentToEntity(this.createComponent(entityId, components[i]));
        }
    }
    
    /**
     * Create the component from some structured data.
     * The data to be serialized must match the component type for this
     * function to behave correctly.
     * 
     * @param entityId
     *      Id that the created component should bind to
     * @param data
     *      JSON format object the component needs to know how to
     *      serialize. Need to look like {typeId:component_name, data:{data attributes}}
     * @return
     *      The created component, null if the component type was not valid
     */
    public function createComponent(entityId : String, data : Dynamic) : Component
    {
        var component : Component = null;
        var componentTypeId : String = data.typeId;
        switch (componentTypeId)
        {
            case AnimatedTextureAtlasStateComponent.TYPE_ID:
                component = new AnimatedTextureAtlasStateComponent(entityId);
            case ArrowComponent.TYPE_ID:
                component = new ArrowComponent(entityId, 0, 0, 0, 0);
            case ItemBlueprintComponent.TYPE_ID:
                component = new ItemBlueprintComponent(entityId);
            case BounceComponent.TYPE_ID:
                component = new BounceComponent(entityId);
            case CurrentGrowInStageComponent.TYPE_ID:
                component = new CurrentGrowInStageComponent(entityId);
            case DescriptionComponent.TYPE_ID:
                component = new DescriptionComponent(entityId);
            case EquippableComponent.TYPE_ID:
                component = new EquippableComponent(entityId);
            case ExpressionComponent.TYPE_ID:
                var equationString : String = data.data.equationString;
                component = new ExpressionComponent(entityId, equationString, m_expressionCompiler.compile(equationString));
            case GenreIdComponent.TYPE_ID:
                component = new GenreIdComponent(entityId);
            case HiddenItemComponent.TYPE_ID:
                component = new HiddenItemComponent(entityId);
            case HighlightComponent.TYPE_ID:
            case ItemIdComponent.TYPE_ID:
                component = new ItemIdComponent(entityId);
            case LevelComponent.TYPE_ID:
                component = new LevelComponent(entityId);
            case LevelsCompletedPerStageComponent.TYPE_ID:
                component = new LevelsCompletedPerStageComponent(entityId);
            case LevelSelectIconComponent.TYPE_ID:
                component = new LevelSelectIconComponent(entityId);
            case LinkToDraggedObjectComponent.TYPE_ID:
                component = new LinkToDraggedObjectComponent(entityId, null, 0, 0);
            case MouseInteractableComponent.TYPE_ID:
            case MoveableComponent.TYPE_ID:
                component = new MoveableComponent(entityId);
            case NameComponent.TYPE_ID:
                component = new NameComponent(entityId, null);
            case PriceComponent.TYPE_ID:
                component = new PriceComponent(entityId);
            case RenderableComponent.TYPE_ID:
                component = new RenderableComponent(entityId);
            case RenderCardComponent.TYPE_ID:
                component = new RenderCardComponent(entityId, null);
            case RewardIconComponent.TYPE_ID:
                component = new RewardIconComponent(entityId);
            case RigidBodyComponent.TYPE_ID:
                component = new RigidBodyComponent(entityId);
            case RotatableComponent.TYPE_ID:
                component = new RotatableComponent(entityId);
            case ScanComponent.TYPE_ID:
                component = new ScanComponent(entityId, 0, 0, 0, 0);
            case StageChangeAnimationComponent.TYPE_ID:
                component = new StageChangeAnimationComponent(entityId);
            case TextureCollectionComponent.TYPE_ID:
                component = new TextureCollectionComponent(entityId);
            case TransformComponent.TYPE_ID:
                component = new TransformComponent(entityId);
        }  // Have the component parse the data  
        
        
        
        if (component != null) 
        {
            component.deserialize(data.data);
        }
        
        return component;
    }
    
    public function serializeComponentManager(componentManager : ComponentManager) : Dynamic
    {
        var entityIdToComponentList : Map<String, Array<Component>> = new Map<String, Array<Component>>();
        
        var entityToComponentMaps = componentManager.getComponentTypeToEntityComponentMap().iterator();
        for (entityToComponentMap in entityToComponentMaps) {
            var components = entityToComponentMap.iterator();
            for (component in components){
                var entityId : String = component.entityId;
                if (entityIdToComponentList.exists(entityId)) 
                {
                    (try cast(Reflect.field(entityIdToComponentList, entityId), Array<Dynamic>) catch(e:Dynamic) null).push(component);
                }
                else 
                {
                    Reflect.setField(entityIdToComponentList, entityId, [component]);
                }
            }
        }
		
		// Go through the dictionary and convert it to the object form  
        var serializedItems : Array<Dynamic> = [];
        var componentList : Array<Component> = null;
        for (entityId in Reflect.fields(entityIdToComponentList))
        {
            var entityObject : Dynamic = {
                entityId : entityId,
                components : [],
            };
            componentList = Reflect.field(entityIdToComponentList, entityId);
            var numComponents = componentList.length;
            for (i in 0...numComponents){
                (try cast(entityObject.components, Array<Dynamic>) catch(e:Dynamic) null).push(componentList[i].serialize());
            }
            
            serializedItems.push(entityObject);
        }
        
        return serializedItems;
    }
}
