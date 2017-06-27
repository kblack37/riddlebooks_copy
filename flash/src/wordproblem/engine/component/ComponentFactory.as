package wordproblem.engine.component
{
    import flash.utils.Dictionary;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.system.Map;

    /**
     * Provides a singular method to create individual components from a well structured
     * data format.
     */
    public class ComponentFactory
    {
        private var m_expressionCompiler:IExpressionTreeCompiler;
        
        public function ComponentFactory(expressionCompiler:IExpressionTreeCompiler)
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
        public function createAndAddComponentsForItemList(componentManager:ComponentManager, data:Object):void
        {
            const entities:Array = data as Array;
            
            var i:int;
            var item:Object;
            const numItems:int = entities.length;
            for (i = 0; i < numItems; i++)
            {
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
        public function createAndAddComponentsForSingleItem(componentManager:ComponentManager, data:Object):void
        {
            // Iterate through the components in an item and add the data directly to
            // this manager.
            var entityId:String = data.entityId;
            var components:Array = data.components;
            var i:int
            const numComponents:int = components.length;
            for (i = 0; i < numComponents; i++)
            {
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
        public function createComponent(entityId:String, data:Object):Component
        {
            var component:Component = null;
            const componentTypeId:String = data.typeId;
            switch (componentTypeId)
            {
                case AnimatedTextureAtlasStateComponent.TYPE_ID:
                    component = new AnimatedTextureAtlasStateComponent(entityId);
                    break;
                case ArrowComponent.TYPE_ID:
                    component = new ArrowComponent(entityId, 0, 0, 0, 0);
                    break;
                case ItemBlueprintComponent.TYPE_ID:
                    component = new ItemBlueprintComponent(entityId);
                    break;
                case BounceComponent.TYPE_ID:
                    component = new BounceComponent(entityId);
                    break;
                case CurrentGrowInStageComponent.TYPE_ID:
                    component = new CurrentGrowInStageComponent(entityId);
                    break;
                case DescriptionComponent.TYPE_ID:
                    component = new DescriptionComponent(entityId);
                    break;
                case EquippableComponent.TYPE_ID:
                    component = new EquippableComponent(entityId);
                    break;
                case ExpressionComponent.TYPE_ID:
                    const equationString:String = data.data.equationString;
                    component = new ExpressionComponent(entityId, equationString, m_expressionCompiler.compile(equationString).head);
                    break;
                case GenreIdComponent.TYPE_ID:
                    component = new GenreIdComponent(entityId);
                    break;
                case HiddenItemComponent.TYPE_ID:
                    component = new HiddenItemComponent(entityId);
                    break;
                case HighlightComponent.TYPE_ID:
                    break;
                case ItemIdComponent.TYPE_ID:
                    component = new ItemIdComponent(entityId);
                    break;
                case LevelComponent.TYPE_ID:
                    component = new LevelComponent(entityId);
                    break;
                case LevelsCompletedPerStageComponent.TYPE_ID:
                    component = new LevelsCompletedPerStageComponent(entityId);
                    break;
                case LevelSelectIconComponent.TYPE_ID:
                    component = new LevelSelectIconComponent(entityId);
                    break;
                case LinkToDraggedObjectComponent.TYPE_ID:
                    component = new LinkToDraggedObjectComponent(entityId, null, 0, 0);
                    break;
                case MouseInteractableComponent.TYPE_ID:
                    break;
                case MoveableComponent.TYPE_ID:
                    component = new MoveableComponent(entityId);
                    break;
                case NameComponent.TYPE_ID:
                    component = new NameComponent(entityId, null);
                    break;
                case PriceComponent.TYPE_ID:
                    component = new PriceComponent(entityId);
                    break;
                case RenderableComponent.TYPE_ID:
                    component = new RenderableComponent(entityId);
                    break;
                case RenderCardComponent.TYPE_ID:
                    component = new RenderCardComponent(entityId, null);
                    break;
                case RewardIconComponent.TYPE_ID:
                    component = new RewardIconComponent(entityId);
                    break;
                case RigidBodyComponent.TYPE_ID:
                    component = new RigidBodyComponent(entityId);
                    break;
                case RotatableComponent.TYPE_ID:
                    component = new RotatableComponent(entityId);
                    break;
                case ScanComponent.TYPE_ID:
                    component = new ScanComponent(entityId, 0, 0, 0, 0);
                    break;
                case StageChangeAnimationComponent.TYPE_ID:
                    component = new StageChangeAnimationComponent(entityId);
                    break;
                case TextureCollectionComponent.TYPE_ID:
                    component = new TextureCollectionComponent(entityId);
                    break;
                case TransformComponent.TYPE_ID:
                    component = new TransformComponent(entityId);
                    break;
            }
            
            // Have the component parse the data
            if (component != null)
            {
                component.deserialize(data.data);
            }
            
            return component;
        }
        
        public function serializeComponentManager(componentManager:ComponentManager):Object
        {
            var entityIdToComponentList:Dictionary = new Dictionary();
            
            var enityToComponentMaps:Array = componentManager.getComponentTypeToEntityComponentMap().getValues()
            var numMaps:int = enityToComponentMaps.length;
            var i:int;
            for (i = 0; i < numMaps; i++)
            {
                var entityToComponentMap:Map = enityToComponentMaps[i];
                var components:Array = entityToComponentMap.getValues();
                var numComponents:int = components.length;
                var j:int;
                for (j = 0; j < numComponents; j++)
                {
                    var component:Component = components[j];
                    var entityId:String = component.entityId;
                    if (entityIdToComponentList.hasOwnProperty(entityId))
                    {
                        (entityIdToComponentList[entityId] as Vector.<Component>).push(component);
                    }
                    else
                    {
                        entityIdToComponentList[entityId] = Vector.<Component>([component]);
                    }
                }
            }
            
            // Go through the dictionary and convert it to the object form
            var serializedItems:Array = [];
            var componentList:Vector.<Component>;
            for (entityId in entityIdToComponentList)
            {
                var entityObject:Object = {
                    entityId:entityId,
                    components:[]
                };
                componentList = entityIdToComponentList[entityId];
                numComponents = componentList.length;
                for (i = 0; i < numComponents; i++)
                {
                    (entityObject.components as Array).push(componentList[i].serialize());
                }
                
                serializedItems.push(entityObject);
            }
            
            return serializedItems;
        }
    }
}