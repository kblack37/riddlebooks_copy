package wordproblem.engine
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.TextFormat;
    import flash.utils.Dictionary;
    
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.ExpressionUtil;
    import dragonbox.common.expressiontree.WildCardNode;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.math.vectorspace.IVectorSpace;
    import dragonbox.common.time.Time;
    import dragonbox.common.ui.MouseState;
    
    import feathers.controls.Button;
    import feathers.display.Scale3Image;
    import feathers.display.Scale9Image;
    import feathers.textures.Scale3Textures;
    
    import starling.animation.Juggler;
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.textures.Texture;
    
    import wordproblem.display.Layer;
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.ComponentManager;
    import wordproblem.engine.component.ExpressionComponent;
    import wordproblem.engine.component.RenderableComponent;
    import wordproblem.engine.component.WidgetAttributesComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.expression.tree.ExpressionTree;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.expression.widget.term.SymbolTermWidget;
    import wordproblem.engine.expression.widget.term.WildCardTermWidget;
    import wordproblem.engine.level.WordProblemLevelData;
    import wordproblem.engine.scripting.graph.selector.ConcurrentSelector;
    import wordproblem.engine.systems.ArrowDrawingSystem;
    import wordproblem.engine.systems.BaseSystemScript;
    import wordproblem.engine.systems.BlinkSystem;
    import wordproblem.engine.systems.BounceSystem;
    import wordproblem.engine.systems.CalloutSystem;
    import wordproblem.engine.systems.FreeTransformSystem;
    import wordproblem.engine.systems.HelperCharacterRenderSystem;
    import wordproblem.engine.systems.HighlightSystem;
    import wordproblem.engine.systems.ScanSystem;
    import wordproblem.engine.text.TextViewFactory;
    import wordproblem.engine.text.model.DocumentNode;
    import wordproblem.engine.text.view.DocumentView;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.engine.widget.DeckWidget;
    import wordproblem.engine.widget.EquationInventoryWidget;
    import wordproblem.engine.widget.EquationToTextWidget;
    import wordproblem.engine.widget.ExpressionPickerWidget;
    import wordproblem.engine.widget.TermAreaWidget;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.engine.widget.WidgetUtil;
    import wordproblem.resource.AssetManager;
    
    /**
     * The state to model a single word problem.
     * 
     * Implementation wise this state accepts an entire level configuration xml. Inside the enter state it
     * will parse the config into its relevant pieces.
     */
    public class GameEngine extends Sprite implements IGameEngine
    {   
        private var m_width:Number;
        private var m_height:Number;
        
        /**
         * Keep track of dynamic data properties on the mainly static ui pieces
         * 
         * This is to allow us to easily to do things like add an arrow component
         * pointing to an undo button or to an empty term area
         */
        private var m_uiComponentManager:ComponentManager;
        
        /**
         * Keep track of all the items in possession by the player
         * during a playthrough of a level. (These are temporary and or only stored
         * for a single level)
         * 
         * Each item acts as an entity
         */
        private var m_itemComponentManager:ComponentManager;
        
        /**
         * Keep track of the entities representing the characters.
         * This is passed in at the start of every level from a state higher up.
         * The game engine is not responsible for resetting the data.
         * 
         * Kept in here so other scripts can more easily fetch this data.
         */
        private var m_characterComponentManager:ComponentManager;
        
        /**
         * Display for the text and illustrations of the word problem
         */
        private var m_textArea:TextAreaWidget;
        
        /**
         * During play we need to shuffle between string and expression node tree formats of an
         * expression.
         */
        private var m_compiler:IExpressionTreeCompiler;
        
        /**
         * A container for all the important information about assigned variables
         */
        private var m_expressionSymbolMap:ExpressionSymbolMap;
        
        private var m_mouseState:MouseState;

        private var m_assetManager:AssetManager;
        
        /**
         * The current level being played, must always be a non-null value
         */
        private var m_currentLevel:WordProblemLevelData;
        
        // TODO:
        // Should not need to reference 
        // These systems below do not undergo the same update path as the ones above
        // and are always enabled.
        private var m_systems:ConcurrentSelector;
        
        /**
         * Animate sprite sheets that are using the starling movieclip class
         */
        private var m_spriteSheetJuggler:Juggler;
        
        public function GameEngine(compiler:IExpressionTreeCompiler,
                                   assetManager:AssetManager,
                                   expressionSymbolMap:ExpressionSymbolMap,
                                   width:Number, 
                                   height:Number,
                                   mouseState:MouseState)
        {
            m_compiler = compiler;
            m_expressionSymbolMap = expressionSymbolMap;
            m_width = width;
            m_height = height;
            m_assetManager = assetManager;
            m_mouseState = mouseState;
            m_spriteSheetJuggler = new Juggler();
            
            // Initialize the component managers, they are re-used for every level
            m_itemComponentManager = new ComponentManager();
            
            // Each of the static ui components need to be able to accept even more 
            // properties for hinting purposes
            m_uiComponentManager = new ComponentManager();
            
            // Construct the systems that are re-usable across all levels
            m_systems = new ConcurrentSelector(-1);
            m_systems.pushChild(new ArrowDrawingSystem(m_assetManager));
            m_systems.pushChild(new BounceSystem());
            m_systems.pushChild(new ScanSystem());
            m_systems.pushChild(new HighlightSystem(m_assetManager))
            m_systems.pushChild(new HelperCharacterRenderSystem(m_assetManager, m_spriteSheetJuggler, this.getSprite()));
            m_systems.pushChild(new CalloutSystem(m_assetManager, this.getSprite(), mouseState));
            m_systems.pushChild(new FreeTransformSystem());
            m_systems.pushChild(new BlinkSystem());
        }
        
        /**
         * Get back the root display containing the ui components representing a level.
         * Note that external scripts that want to add things to the main game display should
         * 
         */
        public function getSprite():Sprite
        {
            return this;
        }
        
        public function getMouseState():MouseState
        {
            return m_mouseState;
        }
        
        public function getExpressionSymbolResources():ExpressionSymbolMap
        {
            return m_expressionSymbolMap;
        }
        
        public function getExpressionCompiler():IExpressionTreeCompiler
        {
            return m_compiler;
        }

        public function getItemComponentManager():ComponentManager
        {
            return m_itemComponentManager;
        }
        
        public function getUiComponentManager():ComponentManager
        {
            return m_uiComponentManager;
        }
        
        public function getCharacterComponentManager():ComponentManager
        {
            return m_characterComponentManager;
        }
        
        public function getCurrentLevel():WordProblemLevelData
        {
            return m_currentLevel;
        }
        
        /**
         * Get the expression representing the current contents of the term areas.
         * 
         * Note that this creates a brand new subtree everytime so it may not be efficient
         * to be calling this every single time.
         * 
         * @param ids
         *      The names of the term areas to pull from. If the list is empty it returns the
         *      contents of every term area.
         * @param outNodes
         *      Root expression nodes for each of the term areas. Can be null if the term area is empty
         */
        public function getTermAreaContent(ids:Vector.<String>, outNodes:Vector.<ExpressionNode>):Boolean
        {
            var i:int;
            var id:String;
            
            if (ids.length > 0)
            {
                for (i = 0; i < ids.length; i++)
                {
                    id = ids[i];
                    var component:RenderableComponent = m_uiComponentManager.getComponentFromEntityIdAndType(
                        id, 
                        RenderableComponent.TYPE_ID
                    ) as RenderableComponent;
                    if (component != null)
                    {
                        var termAreaWidget:TermAreaWidget = component.view as TermAreaWidget;
                        var termAreaRootNode:ExpressionNode = null;
                        if (termAreaWidget.getWidgetRoot() != null)
                        {
                            termAreaRootNode = termAreaWidget.getWidgetRoot().getNode();
                        }
                        
                        outNodes.push(termAreaRootNode);
                    }
                }
            }
            else
            {
                const renderComponents:Vector.<Component> = m_uiComponentManager.getComponentListForType(
                    RenderableComponent.TYPE_ID
                );
                
                for (i = 0; i < renderComponents.length; i++)
                {
                    component = renderComponents[i] as RenderableComponent;
                    if (component.view is TermAreaWidget)
                    {
                        ids.push(component.entityId);
                        
                        termAreaWidget = component.view as TermAreaWidget;
                        outNodes.push((termAreaWidget.getWidgetRoot() != null) ?
                            termAreaWidget.getWidgetRoot().getNode() : null);
                    }
                }
            }
            
            return true;
        }

        public function getUiEntityUnder(aPoint:Point):RenderableComponent 
        {
            var returncomponent:RenderableComponent = null;
            var componentList:Vector.<Component> = m_uiComponentManager.getComponentListForType(RenderableComponent.TYPE_ID);
            for (var i:int = componentList.length - 1; i >= 0; i--) 
            { //iterate over the list in reverse to get the lowest leaf covered in the spacial grid
                if (componentList[i] is RenderableComponent) {
                    var aComponent:RenderableComponent = componentList[i] as RenderableComponent;
                    if (aComponent.view.parent != null) { 
                        if (aComponent.view.getBounds(this.stage).containsPoint(aPoint)) {
                            returncomponent = aComponent;
                            break;
                        }
                    }
                }
            }
            return returncomponent;
        }
        
        public function getUiEntity(entityId:String):DisplayObject
        {
            var component:Component = m_uiComponentManager.getComponentFromEntityIdAndType(entityId, RenderableComponent.TYPE_ID);
            return (component != null) ? (component as RenderableComponent).view : null;
        }
        
        public function getUiEntitiesByClass(classDefinition:Class, 
                                             outObjects:Vector.<DisplayObject>=null):Vector.<DisplayObject>
        {
            if (outObjects == null)
            {
                outObjects = new Vector.<DisplayObject>();
            }
            const renderComponents:Vector.<Component> = m_uiComponentManager.getComponentListForType(RenderableComponent.TYPE_ID);
            const numComponents:int = renderComponents.length;
            var i:int;
            var renderComponent:RenderableComponent;
            for (i = 0; i < numComponents; i++)
            {
                renderComponent = renderComponents[i] as RenderableComponent;
                if (renderComponent.view is classDefinition)
                {
                    outObjects.push(renderComponent.view);
                }
            }
            
            return outObjects;
        }
        
        public function getUiEntityIdFromObject(displayObject:DisplayObject):String
        {
            var renderComponents:Vector.<Component> = m_uiComponentManager.getComponentListForType(RenderableComponent.TYPE_ID);
            var numComponents:int = renderComponents.length;
            var matchedEntityId:String = null;
            var i:int;
            var renderComponent:RenderableComponent;
            for (i = 0; i < numComponents; i++)
            {
                renderComponent = renderComponents[i] as RenderableComponent;
                if (renderComponent.view == displayObject)
                {
                    matchedEntityId = renderComponent.entityId;
                    break;
                }
            }
            
            return matchedEntityId;
        }
        
        public function setPaused(value:Boolean):void
        {
            // All entity groups that can take in a callout need to have them turned off.
        }
        
        public function setDeckAreaContent(expressions:Vector.<String>, hidden:Vector.<Boolean>, attemptMergeSymbols:Boolean):Boolean
        {
            var widget:BaseTermWidget;
            var expression:String;
            var expressionComponent:ExpressionComponent;
            var entitiesToRemove:Vector.<DisplayObject> = new Vector.<DisplayObject>();
            
            // Compare the new set of symbols requested with the ones already on the board
            // If a symbol already exists then there is no need to create it again.
            // Note that its ok if the symbols have the opposite signs as long
            // as card flipping is allowed.
            var deckComponentManager:ComponentManager = (this.getUiEntitiesByClass(DeckWidget)[0] as DeckWidget).componentManager;
            var idsToRemove:Vector.<String> = new Vector.<String>();
            if (attemptMergeSymbols)
            {
                var expressionComponents:Vector.<Component> = deckComponentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
                var numExpressions:int = expressionComponents.length;
                for (i = 0; i < numExpressions; i++)
                {
                    var existingExpressionFoundInNewList:Boolean = false;
                    expressionComponent = expressionComponents[i] as ExpressionComponent;
                    
                    for (var j:int = 0; j < expressions.length; j++)
                    {
                        expression = expressions[j];
                        
                        const existingData:String = expressionComponent.root.data;
                        const existingIsNegative:Boolean = expressionComponent.root.isNegative();
                        const symbolIsNegative:Boolean = expression.charAt(0) == "-";
                        var existingAndNewMatch:Boolean = false;
                        if (symbolIsNegative && existingIsNegative ||
                            !symbolIsNegative && !existingIsNegative)
                        {
                            existingAndNewMatch = (existingData == expression);
                        }
                        else if (existingIsNegative && existingData.substr(1) == expression ||
                            symbolIsNegative && expression.substr(1) == existingData)
                        {
                            existingAndNewMatch = true;
                        }
                        
                        // If a symbol is found splice it out from being added later
                        if (existingAndNewMatch)
                        {
                            existingExpressionFoundInNewList = true;
                            expressions.splice(j, 1);
                            break;
                        }
                    }
                    
                    if (!existingExpressionFoundInNewList)
                    {
                        idsToRemove.push(expressionComponent.entityId);
                    }
                }
            }
            else
            {
                // Remove all existing expressions
                expressionComponents = deckComponentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
                numExpressions = expressionComponents.length;
                for (i = 0; i < numExpressions; i++)
                {
                    expressionComponent = expressionComponents[i] as ExpressionComponent;
                    idsToRemove.push(expressionComponent.entityId);
                }
            }
            
            // Clear components from the entities that will be discarded
            for each (var entityIdToRemove:String in idsToRemove)
            {
                entitiesToRemove.push((deckComponentManager.getComponentFromEntityIdAndType(entityIdToRemove, RenderableComponent.TYPE_ID) as RenderableComponent).view);
                deckComponentManager.removeAllComponentsFromEntity(entityIdToRemove);
            }
            
            // Create widgets for each of the new symbols that we have discovered
            var node:ExpressionNode;
            var renderComponent:RenderableComponent;
            var entitiesToAdd:Vector.<DisplayObject> = new Vector.<DisplayObject>();
            var entityIdToAdd:String;
            var i:int;
            for (i = 0; i < expressions.length; i++)
            {
                expression = expressions[i];
                entityIdToAdd = expression;
                
                node =  m_compiler.compile(expression).head;
                const isInitiallyVisible:Boolean = (hidden != null) ? !hidden[i] : true;
                expressionComponent = new ExpressionComponent(entityIdToAdd, expression, node, isInitiallyVisible);
                deckComponentManager.addComponentToEntity(expressionComponent);
                
                // Currently assuming all content in the deck represents a single symbol
                // rather than an entire expression.
                widget = (node is WildCardNode) ?
                    new WildCardTermWidget(node as WildCardNode, m_expressionSymbolMap, m_assetManager) :
                    new SymbolTermWidget(node, m_expressionSymbolMap, m_assetManager);
                
                if (!isInitiallyVisible)
                {
                    widget.setIsHidden(true);
                }
                else
                {
                    widget.setEnabled(true);
                }
                renderComponent = new RenderableComponent(entityIdToAdd);
                renderComponent.view = widget;
                deckComponentManager.addComponentToEntity(renderComponent);
                entitiesToAdd.push(renderComponent.view);
                
                // Add rigid bounds
                widget.rigidBodyComponent.entityId = entityIdToAdd;
                deckComponentManager.addComponentToEntity(widget.rigidBodyComponent);
            }
            
            var deckAreas:Vector.<DisplayObject> = this.getUiEntitiesByClass(DeckWidget);
            for each (var deckArea:DeckWidget in deckAreas)
            {
                deckArea.batchAddRemoveExpressions(entitiesToAdd, entitiesToRemove);
            }
            
            return true;
        }
        
        public function redrawPageViewAtIndex(index:int, documentNodeRoot:DocumentNode):void
        {
            // Redraw the text
            var textArea:TextAreaWidget = this.getUiEntity("textArea") as TextAreaWidget;
            var textViewFactory:TextViewFactory = new TextViewFactory(m_assetManager, this.getExpressionSymbolResources());
            var pageView:DocumentView = textViewFactory.createView(documentNodeRoot);
            
            var currentPageViews:Vector.<DocumentView> = textArea.getPageViews();
            if (index < currentPageViews.length)
            {
                // Remove and dispose previous view at the given index and replace with the new one
                currentPageViews[index].removeFromParent(true);
                currentPageViews[index] = pageView;
            }
            else
            {
                textArea.getPageViews().push(pageView);
            }
        }
        
        public function addTermToDocument(termValue:String, documentId:String):Boolean
        {
            var textArea:TextAreaWidget = this.getUiEntity("textArea") as TextAreaWidget;
            var expressionComponent:ExpressionComponent = new ExpressionComponent(documentId, termValue, null);
            textArea.componentManager.addComponentToEntity(expressionComponent);
            return true;
        }

        /**
         * Set one or both term areas to new content. This will also cause a new undo history
         * stack starting with the new contents to be created at the bottom.
         * 
         * @param ids
         *      List of term area widget ids for which to set the content to. However many widgets are
         *      given will specifiy how many times the expression gets divided. Division should occur
         *      on the right subtree
         * @param content
         *      Decompiled expression. If it is null or an empty string it sets the specified term
         *      areas to be empty.
         */
        public function setTermAreaContent(termAreaIds:String, content:String):Boolean
        {
            // Need to parse the term area ids
            const termAreaIdList:Vector.<String> = Vector.<String>(termAreaIds.split(" "));
            
            const contentRoot:ExpressionNode = (content == null || content == "") ?
                null : m_compiler.compile(content).head;
            const vectorSpace:IVectorSpace = m_compiler.getVectorSpace();
            
            // Make sure every term area defined gets an expression root
            const roots:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            var rootTracker:ExpressionNode = contentRoot;
            var numRootsToAdd:int = termAreaIdList.length;
            while (numRootsToAdd > 1)
            {
                if (rootTracker != null)
                {
                    roots.push(rootTracker.left);
                    rootTracker = rootTracker.right;
                }
                
                numRootsToAdd--;
            }
            
            roots.push(rootTracker);
            
            var i:int;
            for (i = 0; i < termAreaIdList.length; i++)
            {
                var termAreaWidget:TermAreaWidget = (m_uiComponentManager.getComponentFromEntityIdAndType(
                    termAreaIdList[i],
                    RenderableComponent.TYPE_ID
                ) as RenderableComponent).view as TermAreaWidget;
                if (termAreaWidget != null)
                {
                    var rootToUse:ExpressionNode = (i < roots.length) ? roots[i] : null;
                    termAreaWidget.setTree(new ExpressionTree(vectorSpace, rootToUse));
                    termAreaWidget.redrawAfterModification();
                }
            }
            
            return true;
        }
        
        public function getExpressionFromTermAreas():ExpressionNode
        {
            var root:ExpressionNode = null;
            var termAreas:Vector.<DisplayObject> = this.getUiEntitiesByClass(TermAreaWidget);
            if (termAreas.length == 2)
            {
                var vectorSpace:IVectorSpace = m_compiler.getVectorSpace();
                var leftTermArea:TermAreaWidget = termAreas[0] as TermAreaWidget;
                var modeledLeft:ExpressionNode = (leftTermArea.getWidgetRoot() != null) ?
                    leftTermArea.getWidgetRoot().getNode() : null;
                var rightTermArea:TermAreaWidget = termAreas[1] as TermAreaWidget;
                var modeledRight:ExpressionNode = (rightTermArea.getWidgetRoot() != null) ?
                    rightTermArea.getWidgetRoot().getNode() : null;
                root = ExpressionUtil.createOperatorTree(
                    modeledLeft, 
                    modeledRight, 
                    vectorSpace, 
                    vectorSpace.getEqualityOperator());
            }
            
            return root;
        }
        
        public function setWidgetVisible(widgetId:String, visible:Boolean):Boolean
        {
            // Find the view for the widget
            var attributesForId:WidgetAttributesComponent = m_uiComponentManager.getComponentFromEntityIdAndType(
                widgetId,
                WidgetAttributesComponent.TYPE_ID
            ) as WidgetAttributesComponent;
            var renderComponent:RenderableComponent = m_uiComponentManager.getComponentFromEntityIdAndType(
                widgetId,
                RenderableComponent.TYPE_ID
            ) as RenderableComponent;
            if (attributesForId != null)
            {
                if (visible && renderComponent.view.parent == null)
                {
                    // Need to add object to the correct index of the parent widget
                    var parentAttributes:WidgetAttributesComponent = attributesForId.parent;
                    var parentRenderComponent:RenderableComponent = m_uiComponentManager.getComponentFromEntityIdAndType(
                        parentAttributes.entityId,
                        RenderableComponent.TYPE_ID
                    ) as RenderableComponent;
                    
                    var i:int;
                    for (i = 0; i < parentAttributes.children.length; i++)
                    {
                        if (parentAttributes.children[i] == attributesForId)
                        {
                            break;
                        }
                    }
                    
                    (parentRenderComponent.view as DisplayObjectContainer).addChildAt(renderComponent.view, i);
                }
                else if (!visible && renderComponent.view.parent != null)
                {
                    renderComponent.view.removeFromParent();
                }
                
                // TODO:
                // Need to reposition objects to take into account the fact that the object is not visible
                // an object that is no longer visible will have its width and height treated as zero.
            }
            
            return true;
        }
        
        /**
         * Get the widget attribute node for a specific id
         */
        private function getWidgetFromId(id:String, rootAttribute:WidgetAttributesComponent):WidgetAttributesComponent
        {
            var matchingAttributes:WidgetAttributesComponent;
            if (rootAttribute != null)
            {
                if (rootAttribute.entityId == id)
                {
                    matchingAttributes = rootAttribute;
                }
                else if (rootAttribute.children != null)
                {
                    var i:int;
                    const numWidgetChildren:int = rootAttribute.children.length;
                    for (i = 0; i < numWidgetChildren; i++)
                    {
                        matchingAttributes = getWidgetFromId(id, rootAttribute.children[i]);
                        if (matchingAttributes != null)
                        {
                            break;
                        }
                    }
                }
            }
            
            return matchingAttributes;
        }

        /**
         * Perform start up procedures to begin a level
         * 
         * @param params
         *      The first parameter is the level data to played
         */
        public function enter(params:Vector.<Object>=null):void
        {
            const vectorSpace:IVectorSpace = m_compiler.getVectorSpace();
            const currentLevel:WordProblemLevelData = params[0] as WordProblemLevelData;
            m_currentLevel = currentLevel;
            
            // Set characters that are available for display in this level
            m_characterComponentManager = params[1] as ComponentManager;
            
            // Set up a default layering for the for parts in the game view
            var bottomLayerComponent:RenderableComponent = new RenderableComponent("bottomLayer");
            bottomLayerComponent.view = new Sprite();
            m_uiComponentManager.addComponentToEntity(bottomLayerComponent);
            this.addChild(bottomLayerComponent.view);
            
            var middleLayerComponent:RenderableComponent = new RenderableComponent("middleLayer");
            middleLayerComponent.view = new Sprite();
            m_uiComponentManager.addComponentToEntity(middleLayerComponent);
            this.addChild(middleLayerComponent.view);
            
            var topLayerComponent:RenderableComponent = new RenderableComponent("topLayer");
            topLayerComponent.view = new Sprite();
            m_uiComponentManager.addComponentToEntity(topLayerComponent);
            this.addChild(topLayerComponent.view);
            
            // Create the set of widgets
            var widgetAttributesRoot:WidgetAttributesComponent = currentLevel.getLayoutData();
            this.createWidgets(widgetAttributesRoot);
            
            // Perform layout on widgets
            this.layoutWidgets();
            
            var i:int;
            var documentNodes:Vector.<DocumentNode> = currentLevel.getRootDocumentNodes();
            for (i = 0; i < documentNodes.length; i++)
            {
                this.redrawPageViewAtIndex(i, documentNodes[i]);
            }
            m_textArea.renderText();
            m_textArea.showPageAtIndex(0);
            
            // Make sure callouts point to the appropriate parent canvas whenever a new level starts
            var calloutSystem:CalloutSystem = m_systems.getNodeById("CalloutSystem") as CalloutSystem;
            calloutSystem.setCalloutLayer(middleLayerComponent.view as Sprite);
            
            var scanSystem:BaseSystemScript = m_systems.getNodeById("ScanSystem") as BaseSystemScript;
            var highlightSystem:BaseSystemScript = m_systems.getNodeById("HighlightSystem") as BaseSystemScript;
            var blinkSystem:BaseSystemScript = m_systems.getNodeById("BlinkSystem") as BaseSystemScript;
            
            // TODO:
            // We don't know what component managers will actually be available
            var textComponentManager:ComponentManager = (this.getUiEntity("textArea") as TextAreaWidget).componentManager;
            blinkSystem.addComponentManager(textComponentManager);
            
            var barModelAreas:Vector.<DisplayObject> = this.getUiEntitiesByClass(BarModelAreaWidget);
            for each (var barModelArea:BarModelAreaWidget in barModelAreas)
            {
                calloutSystem.addComponentManager(barModelArea.componentManager);
                blinkSystem.addComponentManager(barModelArea.componentManager);
                highlightSystem.addComponentManager(barModelArea.componentManager);
            }
            
            var termAreas:Vector.<DisplayObject> = this.getUiEntitiesByClass(TermAreaWidget);
            for each (var termArea:TermAreaWidget in termAreas)
            {
                calloutSystem.addComponentManager(termArea.componentManager);
            }
            
            scanSystem.addComponentManager(textComponentManager);
            highlightSystem.addComponentManager(m_uiComponentManager);
            highlightSystem.addComponentManager(textComponentManager);
            
            var deckAreas:Vector.<DisplayObject> = this.getUiEntitiesByClass(DeckWidget);
            for each (var deckArea:DeckWidget in deckAreas)
            {
                calloutSystem.addComponentManager(deckArea.componentManager);
                highlightSystem.addComponentManager(deckArea.componentManager);
            }
            
            calloutSystem.addComponentManager(m_uiComponentManager);
            calloutSystem.addComponentManager(textComponentManager);
            
            if (m_characterComponentManager != null)
            {
                (m_systems.getNodeById("HelperCharacterRenderSystem") as BaseSystemScript).addComponentManager(m_characterComponentManager);
                (m_systems.getNodeById("FreeTransformSystem") as BaseSystemScript).addComponentManager(m_characterComponentManager);
                (m_systems.getNodeById("CalloutSystem") as BaseSystemScript).addComponentManager(m_characterComponentManager);
            }
            
            // Dispatch indication that this level is ready
            this.dispatchEventWith(GameEvent.LEVEL_READY);
        }
        
        /**
         * Perform clean up procedures to terminate the level
         */
        public function exit():void
        {
            var i:int;
            
            // Walk the list of widgets and dispose all of them
            // Do not dispose of this main state however
            const widgetAttributesList:Vector.<Component> = m_uiComponentManager.getComponentListForType(WidgetAttributesComponent.TYPE_ID);
            var widgetAttributes:WidgetAttributesComponent;
            var renderComponent:RenderableComponent;
            for (i = 0; i < widgetAttributesList.length; i++)
            {
                widgetAttributes = widgetAttributesList[i] as WidgetAttributesComponent;
                
                // For some reason disposing of the sprite containers causes
                // the screen to go blank so we make sure only leaf widgets are removed.
                if (widgetAttributes.children == null)
                {
                    renderComponent = m_uiComponentManager.getComponentFromEntityIdAndType(
                        widgetAttributes.entityId, 
                        RenderableComponent.TYPE_ID
                    ) as RenderableComponent;
                    renderComponent.view.removeEventListeners();
                    renderComponent.view.dispose();
                    renderComponent.view.removeFromParent();
                }
            }
            
            // Clear the component list for each of the systems
            for (i = 0; i < m_systems.getChildren().length; i++)
            {
                (m_systems.getChildren()[i] as BaseSystemScript).clear();
            }
            
            // Clear out the data in the component managers
            // TODO: The corresponding widget each is a part of should clear these
            m_uiComponentManager.clear();
            m_itemComponentManager.clear(); // Clear temp items on exit
            
            while (this.numChildren > 0)
            {
                removeChildAt(0);
            }
        }
        
        public function update(time:Time, 
                               mouseState:MouseState):void
        {
            // TODO: Need to update the contents of the text view if they change
            
            // Advance juggler time so items added to it animate
            m_spriteSheetJuggler.advanceTime(time.currentDeltaSeconds);
            
            // Only some of the added widgets are updateable
            // Note that we have a problem where some of these widgets may not be present
            // TODO: Widgets should not be updateable, logic should be pushed to scripts
            m_textArea.update(time, mouseState);
            
            // Systems that do not inherit from the base system need to be updated separately
            m_systems.visit();
        }
        
        /**
         * Function that will resize and place the widget objects.
         * 
         * May need to be called several times during the course of a level.
         */
        private function layoutWidgets():void
        {
            // Look through the list of all the widget attributes and attempt to
            const widgetAttributeComponents:Vector.<Component> = m_uiComponentManager.getComponentListForType(
                WidgetAttributesComponent.TYPE_ID
            );
            const numWidgets:int = widgetAttributeComponents.length;
            var valueMap:Dictionary = new Dictionary();
            var i:int;
            var widgetAttributeComponent:WidgetAttributesComponent;
            var renderComponent:RenderableComponent;
            for (i = 0; i < numWidgets; i++)
            {
                widgetAttributeComponent = widgetAttributeComponents[i] as WidgetAttributesComponent;
                
                const widgetId:String = widgetAttributeComponent.entityId;
                renderComponent =  m_uiComponentManager.getComponentFromEntityIdAndType(
                    widgetId, 
                    RenderableComponent.TYPE_ID
                ) as RenderableComponent;
                
                // Fill the value map for the given widget
                // We basically want to create a mapping from id_attribute to a single value
                // Reassigning values simply involves plugging in values from the map
                // If a value is not known, search widgets for the matching id
                createLayoutMapping(widgetId, valueMap);
                
                // Setting the width and height of an object might have secondary effects
                // on the widget, so we cannot simply assign those properties using the
                // direct .width or .height
                // Instead we use a setDimension function specific to each widget
                var targetWidth:Number = valueMap[widgetId + "_width"];
                var targetHeight:Number = valueMap[widgetId + "_height"];
                const widgetType:String = widgetAttributeComponent.widgetType;
                if (widgetType == "textArea")
                {
                    (renderComponent.view as TextAreaWidget).setDimensions(
                        targetWidth, targetHeight, widgetAttributeComponent.viewportWidth, widgetAttributeComponent.viewportHeight, 0 , 0);
                }
                else if (widgetType == "deckArea")
                {
                    (renderComponent.view as DeckWidget).setDimensions(targetWidth, targetHeight);
                }
                else if (widgetType == "equationToText")
                {
                    (renderComponent.view as EquationToTextWidget).setDimensions(targetWidth, targetHeight);
                }
                else if (widgetType == "inventoryArea")
                {
                    (renderComponent.view as EquationInventoryWidget).setDimensions(targetWidth, targetHeight);   
                }
                else if (widgetType == "termArea")
                {
                    (renderComponent.view as TermAreaWidget).setConstraints(targetWidth, targetHeight, true, false);
                }
                else if (widgetType == "expressionPicker")
                {
                    (renderComponent.view as ExpressionPickerWidget).setDimensions(targetWidth, targetHeight);
                }
                else if (widgetType == "barModelArea")
                {
                    (renderComponent.view as BarModelAreaWidget).setDimensions(targetWidth, targetHeight);
                }
                else if (widgetType == "group")
                {
                    // Only the background image should scale
                    // Scaling the entire container will cause the children to be stretched as well
                    var group:DisplayObjectContainer = renderComponent.view as DisplayObjectContainer;
                    
                    if (group.numChildren > 0)
                    {
                        var firstChild:DisplayObject = group.getChildAt(0);
                        if (firstChild is Scale3Image || firstChild is Scale9Image)
                        {
                            firstChild.width = targetWidth;
                            firstChild.height = targetHeight;
                        }
                    }
                }
                else if (widgetType == "button")
                {
                    // If a button does not have a width and height value set then do not set the values
                    // Otherwise it sets the dimension to a zero value
                    var button:Button = renderComponent.view as Button;
                    if (targetWidth > 0)
                    {
                        button.width = targetWidth;
                    }
                    
                    if (targetHeight > 0)
                    {
                        button.height = targetHeight;
                    }
                }
                
                // Seting the x,y can be done using the DisplayObject interface
                renderComponent.view.x = valueMap[widgetId + "_x"];
                renderComponent.view.y = valueMap[widgetId + "_y"];
                
                this.setWidgetVisible(widgetAttributeComponent.entityId, widgetAttributeComponent.visible);
            }
        }
        
        /**
         * For each widget we create a mapping for each widget layout attribute to a single numeric value.
         */
        private function createLayoutMapping(widgetId:String,
                                             outValueMap:Dictionary):void
        {
            const widgetAttributeComponents:Vector.<Component> = m_uiComponentManager.getComponentListForType(
                WidgetAttributesComponent.TYPE_ID
            );
            const numWidgets:int = widgetAttributeComponents.length;
            var i:int;
            var widgetAttributeComponent:WidgetAttributesComponent;
            var renderComponent:RenderableComponent;
            for (i = 0; i < numWidgets; i++)
            {
                widgetAttributeComponent = widgetAttributeComponents[i] as WidgetAttributesComponent;
                renderComponent = m_uiComponentManager.getComponentFromEntityIdAndType(widgetId, RenderableComponent.TYPE_ID) as RenderableComponent;
                if (widgetId == widgetAttributeComponent.entityId)
                {
                    // Fetch the values for the x,y,width,height from the widget attributes
                    // For each one we get back a list of dependent widgets
                    // if the value have not been assigned a mapping we recursively search for it
                    const valuesBuffer:Vector.<String> = new Vector.<String>();
                    
                    if (widgetAttributeComponent.widthRoot != null)
                    {
                        populateValueMapForAttribute(widgetId, widgetAttributeComponent.widthRoot, "width", valuesBuffer, outValueMap);
                    }
                    else
                    {
                        outValueMap[widgetId + "_width"] = renderComponent.view.width;
                    }
                    
                    if (widgetAttributeComponent.heightRoot != null)
                    {
                        populateValueMapForAttribute(widgetId, widgetAttributeComponent.heightRoot, "height", valuesBuffer, outValueMap);
                    }
                    else
                    {
                        outValueMap[widgetId + "_height"] = renderComponent.view.height;
                    }
                    
                    populateValueMapForAttribute(widgetId, widgetAttributeComponent.xRoot, "x", valuesBuffer, outValueMap);
                    populateValueMapForAttribute(widgetId, widgetAttributeComponent.yRoot, "y", valuesBuffer, outValueMap);
                    break;
                }
            }
        }
        
        /**
         * For a given attribute, calculate the value
         */
        private function populateValueMapForAttribute(widgetId:String,
                                                      expressionRoot:ExpressionNode, 
                                                      attributeName:String,
                                                      valuesBuffer:Vector.<String>,
                                                      outValueMap:Dictionary):void
        {
            valuesBuffer.length = 0;
            getDynamicValues(expressionRoot, valuesBuffer);
            var j:int;
            var outputValue:String;
            for (j = 0; j < valuesBuffer.length; j++)
            {
                outputValue = valuesBuffer[j];
                if (!outValueMap.hasOwnProperty(outputValue))
                {
                    const outputValuePieces:Array = outputValue.split("_", 2);
                    createLayoutMapping(outputValuePieces[0], outValueMap);
                }
            }
            
            outValueMap[widgetId + "_" + attributeName] = ExpressionUtil.evaluateWithVariableReplacement(
                expressionRoot, outValueMap, m_compiler.getVectorSpace());
        }
        
        /**
         * For a particular expression get all dynamically assigned variables
         * 
         * Assume that all dynamic values are of the form widgetId_attributeName
         */
        private function getDynamicValues(root:ExpressionNode, outValues:Vector.<String>):void
        {
            if (root.isLeaf())
            {
                if (!ExpressionUtil.isNodeNumeric(root))
                {
                    outValues.push(root.data);
                }
            }
            else
            {
                getDynamicValues(root.left, outValues);
                getDynamicValues(root.right, outValues);
            }
        }
        
        /**
         * Function to create the widget objects
         * 
         * Note that the top most root widget is exactly this screen
         */
        private function createWidgets(widgetAttributeRoot:WidgetAttributesComponent):DisplayObject
        {
            var widget:DisplayObject;
            if (widgetAttributeRoot != null)
            {
                const widgetType:String = widgetAttributeRoot.widgetType;
                var resourceList:Vector.<Object> = widgetAttributeRoot.getResourceSourceList();
                const numberResources:int = resourceList.length;
                const texture:Texture = (numberResources > 0) ?
                    m_assetManager.getTexture(widgetAttributeRoot.getResourceSourceList()[0].name) : null;
                
                // HACK: The 'topmost' layer in the composition of the widgets forming the game screen is called
                // layout. It should appear at the bottom of this screen
                if (widgetType == "layout")
                {
                    widget = getUiEntity("bottomLayer");
                }
                else if (widgetType == "group")
                {
                    var groupWidget:Sprite = new Layer();
                    
                    // The background texture needs to be able to scale properly, this requires using
                    // either a scale3 or scale9 image
                    if (texture != null)
                    {
                        const imagePadding:Number = 10;
                        const scaledTexture:Scale3Textures = new Scale3Textures(texture, imagePadding, texture.height - imagePadding * 2, Scale3Textures.DIRECTION_VERTICAL);
                        const scaledImage:Scale3Image = new Scale3Image(scaledTexture);
                        groupWidget.addChild(scaledImage);
                    }
                    
                    widget = groupWidget;
                }
                else if (widgetType == "termArea")
                {
                    // Create term areas
                    const vectorSpace:IVectorSpace = m_compiler.getVectorSpace();
                    const termAreaWidget:TermAreaWidget = new TermAreaWidget(
                        new ExpressionTree(vectorSpace, null), 
                        m_expressionSymbolMap, 
                        m_assetManager,
                        texture,
                        0,
                        0
                    );

                    termAreaWidget.addEventListener(GameEvent.TERM_AREA_CHANGED, onTermAreaChanged);
                    termAreaWidget.addEventListener(GameEvent.TERM_AREA_RESET, onTermAreaChanged);
                    
                    widget = termAreaWidget;
                }
                else if (widgetType == "deckArea")
                {
                    // Add symbols both hidden and revealed to the intial deck of cards
                    widget = new DeckWidget(m_assetManager, null, -1);
                }
                else if (widgetType == "textArea")
                {
                    var extraData:Object = widgetAttributeRoot.extraData;
                    m_textArea = new TextAreaWidget(
                        m_assetManager,
                        texture,
                        extraData.backgroundAttachment,
                        extraData.backgroundRepeat,
                        extraData.autoCenterPages,
                        extraData.allowScroll
                    );
                    widget = m_textArea;
                }
                else if (widgetType == "button")
                {
                    extraData = widgetAttributeRoot.extraData;
                    
                    var nineSliceString:String = extraData.nineSlice;
                    var nineSlice:Rectangle  = null;
                    if (nineSliceString != null)
                    {
                        var nineSliceParts:Array = nineSliceString.split(",");
                        nineSlice = new Rectangle(
                            parseInt(nineSliceParts[0]),
                            parseInt(nineSliceParts[1]),
                            parseInt(nineSliceParts[2]),
                            parseInt(nineSliceParts[3])
                        );
                    }
                    
                    var button:Button = this.createPlainButton(
                        numberResources, 
                        resourceList, 
                        extraData.label,
                        (extraData.label != null) ? new TextFormat(extraData.fontName, extraData.fontSize, extraData.fontColor) : null,
                        nineSlice
                    );
                    
                    widget = button;
                }
                else if (widgetType == "equationToText")
                {
                    // Equation to text
                    widget = new EquationToTextWidget();
                }
                else if (widgetType == "inventoryArea")
                {
                    widget = new EquationInventoryWidget(m_assetManager);
                }
                else if (widgetType == "expressionPicker")
                {
                    widget = new ExpressionPickerWidget(m_compiler, m_expressionSymbolMap, m_assetManager);
                }
                else if (widgetType == "barModelArea")
                {
                    extraData = widgetAttributeRoot.extraData;
                    
                    // Need extra space to add additional bars at the bottom
                    var bottomPadding:Number = 50;
                    widget = new BarModelAreaWidget(
                        m_expressionSymbolMap, 
                        m_assetManager,
                        extraData.unitLength,
                        extraData.unitHeight,
                        extraData.topBarPadding,
                        bottomPadding,
                        extraData.leftBarPadding,
                        extraData.leftBarPadding,
                        extraData.barGap
                    );
                }
                
                // Assign the widget view to the attributes node
                const uiRenderComponent:RenderableComponent = new RenderableComponent(widgetAttributeRoot.entityId);;
                uiRenderComponent.view = widget;
                m_uiComponentManager.addComponentToEntity(uiRenderComponent);
                
                // Bind the widget attributes to the component manager
                m_uiComponentManager.addComponentToEntity(widgetAttributeRoot);
                
                if (widgetAttributeRoot.children != null)
                {
                    var i:int;
                    var widgetChild:DisplayObject;
                    const numWidgetChildren:int = widgetAttributeRoot.children.length;
                    for (i = 0; i < numWidgetChildren; i++)
                    {
                        widgetChild = createWidgets(widgetAttributeRoot.children[i]);
                        (widget as Sprite).addChild(widgetChild);
                    }
                }
            }
            
            return widget;
        }
        
        private function createPlainButton(numberResources:int, 
                                           resourceList:Vector.<Object>, 
                                           label:String, 
                                           textFormat:TextFormat, 
                                           nineSlice:Rectangle):Button
        {
            const buttonImageNormal:String = (numberResources > 0) ? 
                resourceList[0].name : null;
            const buttonImageClick:String = (numberResources > 1) ? 
                resourceList[1].name : null;
            const buttonImageOver:String = (numberResources > 2) ? 
                resourceList[2].name : null;
            const buttonImageInactive:String = (numberResources > 3) ?
                resourceList[3].name : null;
            
            const button:Button = WidgetUtil.createButton(
                m_assetManager,
                buttonImageNormal,
                buttonImageClick,
                buttonImageInactive,
                buttonImageOver,
                label,
                textFormat,
                null,
                nineSlice
            );
            return button;
        }
        
        private function onTermAreaChanged(event:Event):void
        {
            // We bubble up an event indicating the term area values have been modified
            // This fires an event only when both term areas are in a ready state
            var termAreas:Vector.<DisplayObject> = this.getUiEntitiesByClass(TermAreaWidget);
            var termAreasReady:Boolean = true;
            var i:int;
            var numTermAreas:int = termAreas.length;
            for (i = 0; i < numTermAreas; i++) {
                var termArea:TermAreaWidget = termAreas[i] as TermAreaWidget;
                if (!termArea.isReady) 
                {
                    termAreasReady = false;
                    break;
                }
            }
            
            if (termAreasReady) 
            {
                dispatchEventWith(GameEvent.TERM_AREAS_CHANGED);
            }
        }
    }
}