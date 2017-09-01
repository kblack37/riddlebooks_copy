package wordproblem.engine;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.ExpressionUtil;
import dragonbox.common.expressiontree.WildCardNode;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.math.vectorspace.RealsVectorSpace;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;
import wordproblem.display.DisposableSprite;
import wordproblem.display.Scale9Image;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.TextFormat;

import wordproblem.display.LabelButton;
import wordproblem.display.Layer;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.component.WidgetAttributesComponent;
import wordproblem.engine.events.DataEvent;
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
class GameEngine extends Sprite implements IGameEngine
{
    private var m_width : Float;
    private var m_height : Float;
    
    /**
     * Keep track of dynamic data properties on the mainly static ui pieces
     * 
     * This is to allow us to easily to do things like add an arrow component
     * pointing to an undo button or to an empty term area
     */
    private var m_uiComponentManager : ComponentManager;
    
    /**
     * Keep track of all the items in possession by the player
     * during a playthrough of a level. (These are temporary and or only stored
     * for a single level)
     * 
     * Each item acts as an entity
     */
    private var m_itemComponentManager : ComponentManager;
    
    /**
     * Keep track of the entities representing the characters.
     * This is passed in at the start of every level from a state higher up.
     * The game engine is not responsible for resetting the data.
     * 
     * Kept in here so other scripts can more easily fetch this data.
     */
    private var m_characterComponentManager : ComponentManager;
    
    /**
     * Display for the text and illustrations of the word problem
     */
    private var m_textArea : TextAreaWidget;
    
    /**
     * During play we need to shuffle between string and expression node tree formats of an
     * expression.
     */
    private var m_compiler : IExpressionTreeCompiler;
    
    /**
     * A container for all the important information about assigned variables
     */
    private var m_expressionSymbolMap : ExpressionSymbolMap;
    
    private var m_mouseState : MouseState;
    
    private var m_assetManager : AssetManager;
    
    /**
     * The current level being played, must always be a non-null value
     */
    private var m_currentLevel : WordProblemLevelData;
    
    // TODO:
    // Should not need to reference
    // These systems below do not undergo the same update path as the ones above
    // and are always enabled.
    private var m_systems : ConcurrentSelector;
    
    /**
     * Animate sprite sheets that are using the starling movieclip class
     */
    //private var m_spriteSheetJuggler : Juggler;
    
    public function new(compiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            expressionSymbolMap : ExpressionSymbolMap,
            width : Float,
            height : Float,
            mouseState : MouseState)
    {
        super();
        m_compiler = compiler;
        m_expressionSymbolMap = expressionSymbolMap;
        m_width = width;
        m_height = height;
        m_assetManager = assetManager;
        m_mouseState = mouseState;
        //m_spriteSheetJuggler = new Juggler();
        
        // Initialize the component managers, they are re-used for every level
        m_itemComponentManager = new ComponentManager();
        
        // Each of the static ui components need to be able to accept even more
        // properties for hinting purposes
        m_uiComponentManager = new ComponentManager();
        
        // Construct the systems that are re-usable across all levels
		// TODO: revisit some of these animations once more basic display elements are working
        m_systems = new ConcurrentSelector(-1);
        m_systems.pushChild(new ArrowDrawingSystem(m_assetManager));
        m_systems.pushChild(new BounceSystem());
        m_systems.pushChild(new ScanSystem());
        m_systems.pushChild(new HighlightSystem(m_assetManager));
        //m_systems.pushChild(new HelperCharacterRenderSystem(m_assetManager, m_spriteSheetJuggler, this.getSprite()));
        m_systems.pushChild(new CalloutSystem(m_assetManager, this.getSprite(), mouseState));
        m_systems.pushChild(new FreeTransformSystem());
        //m_systems.pushChild(new BlinkSystem());
    }
    
    /**
     * Get back the root display containing the ui components representing a level.
     * Note that external scripts that want to add things to the main game display should
     * 
     */
    public function getSprite() : Sprite
    {
        return this;
    }
    
    public function getMouseState() : MouseState
    {
        return m_mouseState;
    }
    
    public function getExpressionSymbolResources() : ExpressionSymbolMap
    {
        return m_expressionSymbolMap;
    }
    
    public function getExpressionCompiler() : IExpressionTreeCompiler
    {
        return m_compiler;
    }
    
    public function getItemComponentManager() : ComponentManager
    {
        return m_itemComponentManager;
    }
    
    public function getUiComponentManager() : ComponentManager
    {
        return m_uiComponentManager;
    }
    
    public function getCharacterComponentManager() : ComponentManager
    {
        return m_characterComponentManager;
    }
    
    public function getCurrentLevel() : WordProblemLevelData
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
    public function getTermAreaContent(ids : Array<String>, outNodes : Array<ExpressionNode>) : Bool
    {
        var i : Int = 0;
        var id : String = null;
        
        if (ids.length > 0) 
        {
            for (i in 0...ids.length){
                id = ids[i];
                var component : RenderableComponent = try cast(m_uiComponentManager.getComponentFromEntityIdAndType(
                        id,
                        RenderableComponent.TYPE_ID
                        ), RenderableComponent) catch(e:Dynamic) null;
                if (component != null) 
                {
                    var termAreaWidget : TermAreaWidget = try cast(component.view, TermAreaWidget) catch(e:Dynamic) null;
                    var termAreaRootNode : ExpressionNode = null;
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
            var renderComponents : Array<Component> = m_uiComponentManager.getComponentListForType(
                    RenderableComponent.TYPE_ID
                    );
            
            for (i in 0...renderComponents.length){
                var component = try cast(renderComponents[i], RenderableComponent) catch(e:Dynamic) null;
                if (Std.is(component.view, TermAreaWidget)) 
                {
                    ids.push(component.entityId);
                    
                    var termAreaWidget = try cast(component.view, TermAreaWidget) catch(e:Dynamic) null;
                    outNodes.push(((termAreaWidget.getWidgetRoot() != null)) ? 
                            termAreaWidget.getWidgetRoot().getNode() : null);
                }
            }
        }
        
        return true;
    }
    
    public function getUiEntityUnder(aPoint : Point) : RenderableComponent
    {
        var returncomponent : RenderableComponent = null;
        var componentList : Array<Component> = m_uiComponentManager.getComponentListForType(RenderableComponent.TYPE_ID);
        var i : Int = componentList.length - 1;
        while (i >= 0){  //iterate over the list in reverse to get the lowest leaf covered in the spacial grid  
            if (Std.is(componentList[i], RenderableComponent)) {
                var aComponent : RenderableComponent = try cast(componentList[i], RenderableComponent) catch(e:Dynamic) null;
                if (aComponent.view.parent != null) {
                    if (aComponent.view.getBounds(this.stage).containsPoint(aPoint)) {
                        returncomponent = aComponent;
                        break;
                    }
                }
            }
            i--;
        }
        return returncomponent;
    }
    
    public function getUiEntity(entityId : String) : DisplayObject
    {
        var component : Component = m_uiComponentManager.getComponentFromEntityIdAndType(entityId, RenderableComponent.TYPE_ID);
        return component != null ? (try cast(component, RenderableComponent) catch(e:Dynamic) null).view : null;
    }
    
    public function getUiEntitiesByClass(classDefinition : Class<Dynamic>,
            outObjects : Array<DisplayObject> = null) : Array<DisplayObject>
    {
        if (outObjects == null) 
        {
            outObjects = new Array<DisplayObject>();
        }
        var renderComponents : Array<Component> = m_uiComponentManager.getComponentListForType(RenderableComponent.TYPE_ID);
        var numComponents : Int = renderComponents.length;
        var i : Int = 0;
        var renderComponent : RenderableComponent = null;
        for (i in 0...numComponents){
            renderComponent = try cast(renderComponents[i], RenderableComponent) catch(e:Dynamic) null;
            if (Std.is(renderComponent.view, classDefinition)) 
            {
                outObjects.push(renderComponent.view);
            }
        }
        
        return outObjects;
    }
    
    public function getUiEntityIdFromObject(displayObject : DisplayObject) : String
    {
        var renderComponents : Array<Component> = m_uiComponentManager.getComponentListForType(RenderableComponent.TYPE_ID);
        var numComponents : Int = renderComponents.length;
        var matchedEntityId : String = null;
        var i : Int = 0;
        var renderComponent : RenderableComponent = null;
        for (i in 0...numComponents){
            renderComponent = try cast(renderComponents[i], RenderableComponent) catch(e:Dynamic) null;
            if (renderComponent.view == displayObject) 
            {
                matchedEntityId = renderComponent.entityId;
                break;
            }
        }
        
        return matchedEntityId;
    }
    
    public function setPaused(value : Bool) : Void
    {
        // All entity groups that can take in a callout need to have them turned off.
        
    }
    
    public function setDeckAreaContent(expressions : Array<String>, hidden : Array<Bool>, attemptMergeSymbols : Bool) : Bool
    {
        var widget : BaseTermWidget = null;
        var expression : String = null;
        var expressionComponent : ExpressionComponent = null;
        var entitiesToRemove : Array<DisplayObject> = new Array<DisplayObject>();
        
        // Compare the new set of symbols requested with the ones already on the board
        // If a symbol already exists then there is no need to create it again.
        // Note that its ok if the symbols have the opposite signs as long
        // as card flipping is allowed.
        var deckComponentManager : ComponentManager = (try cast(this.getUiEntitiesByClass(DeckWidget)[0], DeckWidget) catch(e:Dynamic) null).componentManager;
        var idsToRemove : Array<String> = new Array<String>();
        if (attemptMergeSymbols) 
        {
            var expressionComponents : Array<Component> = deckComponentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
            var numExpressions : Int = expressionComponents.length;
            for (i in 0...numExpressions){
                var existingExpressionFoundInNewList : Bool = false;
                expressionComponent = try cast(expressionComponents[i], ExpressionComponent) catch(e:Dynamic) null;
                
                for (j in 0...expressions.length){
                    expression = expressions[j];
                    
                    var existingData : String = expressionComponent.root.data;
                    var existingIsNegative : Bool = expressionComponent.root.isNegative();
                    var symbolIsNegative : Bool = expression.charAt(0) == "-";
                    var existingAndNewMatch : Bool = false;
                    if (symbolIsNegative && existingIsNegative ||
                        !symbolIsNegative && !existingIsNegative) 
                    {
                        existingAndNewMatch = (existingData == expression);
                    }
                    // If a symbol is found splice it out from being added later
                    else if (existingIsNegative && existingData.substr(1) == expression ||
                        symbolIsNegative && expression.substr(1) == existingData) 
                    {
                        existingAndNewMatch = true;
                    }
                    
                    
                    
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
            var expressionComponents = deckComponentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
            var numExpressions = expressionComponents.length;
            for (i in 0...numExpressions){
                expressionComponent = try cast(expressionComponents[i], ExpressionComponent) catch(e:Dynamic) null;
                idsToRemove.push(expressionComponent.entityId);
            }
        } 
		
		// Clear components from the entities that will be discarded  
        for (entityIdToRemove in idsToRemove)
        {
            entitiesToRemove.push((try cast(deckComponentManager.getComponentFromEntityIdAndType(entityIdToRemove, RenderableComponent.TYPE_ID), RenderableComponent) catch(e:Dynamic) null).view);
            deckComponentManager.removeAllComponentsFromEntity(entityIdToRemove);
        }  
		
		// Create widgets for each of the new symbols that we have discovered  
        var node : ExpressionNode = null;
        var renderComponent : RenderableComponent = null;
        var entitiesToAdd : Array<DisplayObject> = new Array<DisplayObject>();
        var entityIdToAdd : String = null;
        var i : Int = 0;
        for (i in 0...expressions.length){
            expression = expressions[i];
            entityIdToAdd = expression;
            
            node = m_compiler.compile(expression);
            var isInitiallyVisible : Bool = ((hidden != null)) ? !hidden[i] : true;
            expressionComponent = new ExpressionComponent(entityIdToAdd, expression, node, isInitiallyVisible);
            deckComponentManager.addComponentToEntity(expressionComponent);
            
            // Currently assuming all content in the deck represents a single symbol
            // rather than an entire expression.
            widget = ((Std.is(node, WildCardNode))) ? 
                    new WildCardTermWidget(try cast(node, WildCardNode) catch(e:Dynamic) null, m_expressionSymbolMap, m_assetManager) : 
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
        
        var deckAreas : Array<DisplayObject> = this.getUiEntitiesByClass(DeckWidget);
        for (deckArea in deckAreas)
        {
            (try cast(deckArea, DeckWidget) catch (e : Dynamic) null).batchAddRemoveExpressions(entitiesToAdd, entitiesToRemove);
        }
        
        return true;
    }
    
    public function redrawPageViewAtIndex(index : Int, documentNodeRoot : DocumentNode) : Void
    {
        // Redraw the text
        var textArea : TextAreaWidget = try cast(this.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        var textViewFactory : TextViewFactory = new TextViewFactory(m_assetManager, this.getExpressionSymbolResources());
        var pageView : DocumentView = textViewFactory.createView(documentNodeRoot);
        
        var currentPageViews : Array<DocumentView> = textArea.getPageViews();
        if (index < currentPageViews.length) 
        {
            // Remove and dispose previous view at the given index and replace with the new one
			var currentPageView = currentPageViews[index];
			if (currentPageView.parent != null) currentPageView.parent.removeChild(currentPageView);
			currentPageView = null;
            currentPageViews[index] = pageView;
        }
        else 
        {
            textArea.getPageViews().push(pageView);
        }
    }
    
    public function addTermToDocument(termValue : String, documentId : String) : Bool
    {
        var textArea : TextAreaWidget = try cast(this.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        var expressionComponent : ExpressionComponent = new ExpressionComponent(documentId, termValue, null);
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
    public function setTermAreaContent(termAreaIds : String, content : String) : Bool
    {
        // Need to parse the term area ids
        var termAreaIdList : Array<String> = termAreaIds.split(" ");
        
        var contentRoot : ExpressionNode = ((content == null || content == "")) ? 
        null : m_compiler.compile(content);
        var vectorSpace : RealsVectorSpace = m_compiler.getVectorSpace();
        
        // Make sure every term area defined gets an expression root
        var roots : Array<ExpressionNode> = new Array<ExpressionNode>();
        var rootTracker : ExpressionNode = contentRoot;
        var numRootsToAdd : Int = termAreaIdList.length;
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
        
        var i : Int = 0;
        for (i in 0...termAreaIdList.length){
            var termAreaWidget : TermAreaWidget = try cast((try cast(m_uiComponentManager.getComponentFromEntityIdAndType(
                    termAreaIdList[i],
                    RenderableComponent.TYPE_ID
                    ), RenderableComponent) catch(e:Dynamic) null).view, TermAreaWidget) catch(e:Dynamic) null;
            if (termAreaWidget != null) 
            {
                var rootToUse : ExpressionNode = ((i < roots.length)) ? roots[i] : null;
                termAreaWidget.setTree(new ExpressionTree(vectorSpace, rootToUse));
                termAreaWidget.redrawAfterModification();
            }
        }
        
        return true;
    }
    
    public function getExpressionFromTermAreas() : ExpressionNode
    {
        var root : ExpressionNode = null;
        var termAreas : Array<DisplayObject> = this.getUiEntitiesByClass(TermAreaWidget);
        if (termAreas.length == 2) 
        {
            var vectorSpace : RealsVectorSpace = m_compiler.getVectorSpace();
            var leftTermArea : TermAreaWidget = try cast(termAreas[0], TermAreaWidget) catch(e:Dynamic) null;
            var modeledLeft : ExpressionNode = ((leftTermArea.getWidgetRoot() != null)) ? 
            leftTermArea.getWidgetRoot().getNode() : null;
            var rightTermArea : TermAreaWidget = try cast(termAreas[1], TermAreaWidget) catch(e:Dynamic) null;
            var modeledRight : ExpressionNode = ((rightTermArea.getWidgetRoot() != null)) ? 
            rightTermArea.getWidgetRoot().getNode() : null;
            root = ExpressionUtil.createOperatorTree(
                            modeledLeft,
                            modeledRight,
                            vectorSpace,
                            vectorSpace.getEqualityOperator());
        }
        
        return root;
    }
    
    public function setWidgetVisible(widgetId : String, visible : Bool) : Bool
    {
        // Find the view for the widget
        var attributesForId : WidgetAttributesComponent = try cast(m_uiComponentManager.getComponentFromEntityIdAndType(
                widgetId,
                WidgetAttributesComponent.TYPE_ID
                ), WidgetAttributesComponent) catch(e:Dynamic) null;
        var renderComponent : RenderableComponent = try cast(m_uiComponentManager.getComponentFromEntityIdAndType(
                widgetId,
                RenderableComponent.TYPE_ID
                ), RenderableComponent) catch(e:Dynamic) null;
        if (attributesForId != null) 
        {
            if (visible && renderComponent.view.parent == null) 
            {
                // Need to add object to the correct index of the parent widget
                var parentAttributes : WidgetAttributesComponent = attributesForId.parent;
                var parentRenderComponent : RenderableComponent = try cast(m_uiComponentManager.getComponentFromEntityIdAndType(
                        parentAttributes.entityId,
                        RenderableComponent.TYPE_ID
                        ), RenderableComponent) catch(e:Dynamic) null;
                
                var i : Int = 0;
                for (i in 0...parentAttributes.children.length){
                                    if (parentAttributes.children[i] == attributesForId) 
                                    {
                                        break;
                                    }
                                }(try cast(parentRenderComponent.view, DisplayObjectContainer) catch(e:Dynamic) null).addChildAt(renderComponent.view, i);
            }
            // TODO:
            // Need to reposition objects to take into account the fact that the object is not visible
            // an object that is no longer visible will have its width and height treated as zero.
            else if (!visible && renderComponent.view.parent != null) 
            {
				if (renderComponent.view.parent != null) renderComponent.view.parent.removeChild(renderComponent.view);
            }
        }
        
        return true;
    }
    
    /**
     * Get the widget attribute node for a specific id
     */
    private function getWidgetFromId(id : String, rootAttribute : WidgetAttributesComponent) : WidgetAttributesComponent
    {
        var matchingAttributes : WidgetAttributesComponent = null;
        if (rootAttribute != null) 
        {
            if (rootAttribute.entityId == id) 
            {
                matchingAttributes = rootAttribute;
            }
            else if (rootAttribute.children != null) 
            {
                var i : Int = 0;
                var numWidgetChildren : Int = rootAttribute.children.length;
                for (i in 0...numWidgetChildren){
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
    public function enter(params : Array<Dynamic> = null) : Void
    {
        var vectorSpace : RealsVectorSpace = m_compiler.getVectorSpace();
        var currentLevel : WordProblemLevelData = try cast(params[0], WordProblemLevelData) catch(e:Dynamic) null;
        m_currentLevel = currentLevel;
        
        // Set characters that are available for display in this level
        m_characterComponentManager = try cast(params[1], ComponentManager) catch(e:Dynamic) null;
        
        // Set up a default layering for the for parts in the game view
        var bottomLayerComponent : RenderableComponent = new RenderableComponent("bottomLayer");
        bottomLayerComponent.view = new Sprite();
        m_uiComponentManager.addComponentToEntity(bottomLayerComponent);
        this.addChild(bottomLayerComponent.view);
        
        var middleLayerComponent : RenderableComponent = new RenderableComponent("middleLayer");
        middleLayerComponent.view = new Sprite();
        m_uiComponentManager.addComponentToEntity(middleLayerComponent);
        this.addChild(middleLayerComponent.view);
        
        var topLayerComponent : RenderableComponent = new RenderableComponent("topLayer");
        topLayerComponent.view = new Sprite();
        m_uiComponentManager.addComponentToEntity(topLayerComponent);
        this.addChild(topLayerComponent.view);
        
        // Create the set of widgets
        var widgetAttributesRoot : WidgetAttributesComponent = currentLevel.getLayoutData();
        this.createWidgets(widgetAttributesRoot);
        
        // Perform layout on widgets
        this.layoutWidgets();
        
        var i : Int = 0;
        var documentNodes : Array<DocumentNode> = currentLevel.getRootDocumentNodes();
        for (i in 0...documentNodes.length){
            this.redrawPageViewAtIndex(i, documentNodes[i]);
        }
        m_textArea.renderText();
        m_textArea.showPageAtIndex(0);
        
        // Make sure callouts point to the appropriate parent canvas whenever a new level starts
        var calloutSystem : CalloutSystem = try cast(m_systems.getNodeById("CalloutSystem"), CalloutSystem) catch(e:Dynamic) null;
        calloutSystem.setCalloutLayer(try cast(middleLayerComponent.view, Sprite) catch(e:Dynamic) null);
        
        var scanSystem : BaseSystemScript = try cast(m_systems.getNodeById("ScanSystem"), BaseSystemScript) catch(e:Dynamic) null;
        var highlightSystem : BaseSystemScript = try cast(m_systems.getNodeById("HighlightSystem"), BaseSystemScript) catch(e:Dynamic) null;
        //var blinkSystem : BaseSystemScript = try cast(m_systems.getNodeById("BlinkSystem"), BaseSystemScript) catch(e:Dynamic) null;
        
        // TODO:
        // We don't know what component managers will actually be available
        var textComponentManager : ComponentManager = (try cast(this.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null).componentManager;
        //blinkSystem.addComponentManager(textComponentManager);
        
        var barModelAreas : Array<DisplayObject> = this.getUiEntitiesByClass(BarModelAreaWidget);
        for (barModelArea in barModelAreas)
        {
			var barModelAreaComponentManager = (try cast(barModelArea, BarModelAreaWidget) catch (e : Dynamic) null).componentManager;
            calloutSystem.addComponentManager(barModelAreaComponentManager);
            //blinkSystem.addComponentManager(barModelAreaComponentManager);
            highlightSystem.addComponentManager(barModelAreaComponentManager);
        }
        
        var termAreas : Array<DisplayObject> = this.getUiEntitiesByClass(TermAreaWidget);
        for (termArea in termAreas)
        {
			var termAreaComponentManager = (try cast(termArea, TermAreaWidget) catch (e : Dynamic) null).componentManager;
            calloutSystem.addComponentManager(termAreaComponentManager);
        }
        
        scanSystem.addComponentManager(textComponentManager);
        highlightSystem.addComponentManager(m_uiComponentManager);
        highlightSystem.addComponentManager(textComponentManager);
        
        var deckAreas : Array<DisplayObject> = this.getUiEntitiesByClass(DeckWidget);
        for (deckArea in deckAreas)
        {
			var deckAreaComponentManager = (try cast(deckArea, DeckWidget) catch (e : Dynamic) null).componentManager;
            calloutSystem.addComponentManager(deckAreaComponentManager);
            highlightSystem.addComponentManager(deckAreaComponentManager);
        }
        
        calloutSystem.addComponentManager(m_uiComponentManager);
        calloutSystem.addComponentManager(textComponentManager);
        
        if (m_characterComponentManager != null) 
        {
            //(try cast(m_systems.getNodeById("HelperCharacterRenderSystem"), BaseSystemScript) catch(e:Dynamic) null).addComponentManager(m_characterComponentManager);
            (try cast(m_systems.getNodeById("FreeTransformSystem"), BaseSystemScript) catch(e:Dynamic) null).addComponentManager(m_characterComponentManager);
            (try cast(m_systems.getNodeById("CalloutSystem"), BaseSystemScript) catch(e:Dynamic) null).addComponentManager(m_characterComponentManager);
        } 
		
		// Dispatch indication that this level is ready  
        this.dispatchEvent(new Event(GameEvent.LEVEL_READY));
    }
    
    /**
     * Perform clean up procedures to terminate the level
     */
    public function exit() : Void
    {
        var i : Int = 0;
        
        // Walk the list of widgets and dispose all of them
        // Do not dispose of this main state however
        var widgetAttributesList : Array<Component> = m_uiComponentManager.getComponentListForType(WidgetAttributesComponent.TYPE_ID);
        var widgetAttributes : WidgetAttributesComponent = null;
        var renderComponent : RenderableComponent = null;
        for (i in 0...widgetAttributesList.length){
            widgetAttributes = try cast(widgetAttributesList[i], WidgetAttributesComponent) catch(e:Dynamic) null;
            
            // For some reason disposing of the sprite containers causes
            // the screen to go blank so we make sure only leaf widgets are removed.
            if (widgetAttributes.children == null) 
            {
                renderComponent = try cast(m_uiComponentManager.getComponentFromEntityIdAndType(
                                widgetAttributes.entityId,
                                RenderableComponent.TYPE_ID
                                ), RenderableComponent) catch (e:Dynamic) null;
				if (renderComponent.view.parent != null) renderComponent.view.parent.removeChild(renderComponent.view);
				if (Std.is(renderComponent.view, DisposableSprite)) {
					(try cast(renderComponent.view, DisposableSprite) catch (e : Dynamic) null).dispose();
				}
            }
        }  
		
		// Clear the component list for each of the systems  
        for (i in 0...m_systems.getChildren().length){
            (try cast(m_systems.getChildren()[i], BaseSystemScript) catch(e:Dynamic) null).clear();
        }  
		
		// TODO: The corresponding widget each is a part of should clear these    // Clear out the data in the component managers  
        m_uiComponentManager.clear();
        m_itemComponentManager.clear(); 
		
		// Clear temp items on exit  
        while (this.numChildren > 0)
        {
            removeChildAt(0);
        }
    }
    
    public function update(time : Time,
            mouseState : MouseState) : Void
    {
        // TODO: Need to update the contents of the text view if they change
        
        // Advance juggler time so items added to it animate
        //m_spriteSheetJuggler.advanceTime(time.currentDeltaSeconds);
        
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
    private function layoutWidgets() : Void
    {
        // Look through the list of all the widget attributes and attempt to
        var widgetAttributeComponents : Array<Component> = m_uiComponentManager.getComponentListForType(
                WidgetAttributesComponent.TYPE_ID
                );
        var numWidgets : Int = widgetAttributeComponents.length;
        var valueMap : Map<String, Float> = new Map<String, Float>();
        var i : Int = 0;
        var widgetAttributeComponent : WidgetAttributesComponent = null;
        var renderComponent : RenderableComponent = null;
        for (i in 0...numWidgets){
            widgetAttributeComponent = try cast(widgetAttributeComponents[i], WidgetAttributesComponent) catch(e:Dynamic) null;
            
            var widgetId : String = widgetAttributeComponent.entityId;
            renderComponent = try cast(m_uiComponentManager.getComponentFromEntityIdAndType(
                            widgetId,
                            RenderableComponent.TYPE_ID
                            ), RenderableComponent) catch(e:Dynamic) null;
            
            // Fill the value map for the given widget
            // We basically want to create a mapping from id_attribute to a single value
            // Reassigning values simply involves plugging in values from the map
            // If a value is not known, search widgets for the matching id
            createLayoutMapping(widgetId, valueMap);
            
            // Setting the width and height of an object might have secondary effects
            // on the widget, so we cannot simply assign those properties using the
            // direct .width or .height
            // Instead we use a setDimension function specific to each widget
            var targetWidth : Float = valueMap[widgetId + "_width"];
            var targetHeight : Float = valueMap[widgetId + "_height"];
            var widgetType : String = widgetAttributeComponent.widgetType;
            if (widgetType == "textArea") 
            {
                (try cast(renderComponent.view, TextAreaWidget) catch(e:Dynamic) null).setDimensions(
                        targetWidth, targetHeight, widgetAttributeComponent.viewportWidth, widgetAttributeComponent.viewportHeight, 0, 0);
            }
            else if (widgetType == "deckArea") 
            {
                (try cast(renderComponent.view, DeckWidget) catch(e:Dynamic) null).setDimensions(targetWidth, targetHeight);
            }
            else if (widgetType == "equationToText") 
            {
                (try cast(renderComponent.view, EquationToTextWidget) catch(e:Dynamic) null).setDimensions(targetWidth, targetHeight);
            }
            else if (widgetType == "inventoryArea") 
            {
                (try cast(renderComponent.view, EquationInventoryWidget) catch(e:Dynamic) null).setDimensions(targetWidth, targetHeight);
            }
            else if (widgetType == "termArea") 
            {
                (try cast(renderComponent.view, TermAreaWidget) catch(e:Dynamic) null).setConstraints(targetWidth, targetHeight, true, false);
            }
            else if (widgetType == "expressionPicker") 
            {
                (try cast(renderComponent.view, ExpressionPickerWidget) catch(e:Dynamic) null).setDimensions(targetWidth, targetHeight);
            }
            else if (widgetType == "barModelArea") 
            {
                (try cast(renderComponent.view, BarModelAreaWidget) catch (e:Dynamic) null).setDimensions(targetWidth, targetHeight);
            }
            else if (widgetType == "group") 
            {
                // Only the background image should scale
                // Scaling the entire container will cause the children to be stretched as well
                var group : DisplayObjectContainer = try cast(renderComponent.view, DisplayObjectContainer) catch(e:Dynamic) null;
                
                if (group.numChildren > 0) 
                {
                    var firstChild : DisplayObject = group.getChildAt(0);
                    firstChild.width = targetWidth;
                    firstChild.height = targetHeight;
                }
            }
            // Seting the x,y can be done using the DisplayObject interface
            else if (widgetType == "button") 
            {
                // If a button does not have a width and height value set then do not set the values
                // Otherwise it sets the dimension to a zero value
                var button : LabelButton = try cast(renderComponent.view, LabelButton) catch(e:Dynamic) null;
                if (targetWidth > 0) 
                {
                    button.width = targetWidth;
                }
                
                if (targetHeight > 0) 
                {
                    button.height = targetHeight;
                }
            }
            
            renderComponent.view.x = valueMap[widgetId + "_x"];
            renderComponent.view.y = valueMap[widgetId + "_y"];
            
            this.setWidgetVisible(widgetAttributeComponent.entityId, widgetAttributeComponent.visible);
        }
    }
    
    /**
     * For each widget we create a mapping for each widget layout attribute to a single numeric value.
     */
    private function createLayoutMapping(widgetId : String,
            outValueMap : Map<String, Float>) : Void
    {
        var widgetAttributeComponents : Array<Component> = m_uiComponentManager.getComponentListForType(
                WidgetAttributesComponent.TYPE_ID
                );
        var numWidgets : Int = widgetAttributeComponents.length;
        var i : Int = 0;
        var widgetAttributeComponent : WidgetAttributesComponent = null;
        var renderComponent : RenderableComponent = null;
        for (i in 0...numWidgets){
            widgetAttributeComponent = try cast(widgetAttributeComponents[i], WidgetAttributesComponent) catch(e:Dynamic) null;
            renderComponent = try cast(m_uiComponentManager.getComponentFromEntityIdAndType(widgetId, RenderableComponent.TYPE_ID), RenderableComponent) catch(e:Dynamic) null;
            if (widgetId == widgetAttributeComponent.entityId) 
            {
                // Fetch the values for the x,y,width,height from the widget attributes
                // For each one we get back a list of dependent widgets
                // if the value have not been assigned a mapping we recursively search for it
                var valuesBuffer : Array<String> = new Array<String>();
                
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
    private function populateValueMapForAttribute(widgetId : String,
            expressionRoot : ExpressionNode,
            attributeName : String,
            valuesBuffer : Array<String>,
            outValueMap : Map<String, Float>) : Void
    {
		valuesBuffer = new Array<String>();
        getDynamicValues(expressionRoot, valuesBuffer);
        var j : Int = 0;
        var outputValue : String = null;
        for (j in 0...valuesBuffer.length){
            outputValue = valuesBuffer[j];
            if (!outValueMap.exists(outputValue)) 
            {
                var outputValuePieces : Array<Dynamic> = outputValue.split("_");
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
    private function getDynamicValues(root : ExpressionNode, outValues : Array<String>) : Void
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
    private function createWidgets(widgetAttributeRoot : WidgetAttributesComponent) : DisplayObject
    {
        var widget : DisplayObject  = null;
        if (widgetAttributeRoot != null) 
        {
            var widgetType : String = widgetAttributeRoot.widgetType;
            var resourceList : Array<Dynamic> = widgetAttributeRoot.getResourceSourceList();
            var numberResources : Int = resourceList.length;
            var bitmapData : BitmapData = numberResources > 0 ? 
				m_assetManager.getBitmapData(widgetAttributeRoot.getResourceSourceList()[0].name) : null;
            
            // HACK: The 'topmost' layer in the composition of the widgets forming the game screen is called
            // layout. It should appear at the bottom of this screen
            if (widgetType == "layout") 
            {
                widget = getUiEntity("bottomLayer");
            }
            else if (widgetType == "group") 
            {
                var groupWidget : Sprite = new Layer();
                
                // The background texture needs to be able to scale properly, this requires using
                // either a scale3 or scale9 image
                if (bitmapData != null) 
                {
                    var imagePadding : Float = 10;
                    var scaledImage : Scale9Image = new Scale9Image(bitmapData, new Rectangle(0, imagePadding, bitmapData.width, bitmapData.height - imagePadding * 2));
                    groupWidget.addChild(scaledImage);
                }
                
                widget = groupWidget;
            }
            else if (widgetType == "termArea") 
            {
                // Create term areas
                var vectorSpace : RealsVectorSpace = m_compiler.getVectorSpace();
                var termAreaWidget : TermAreaWidget = new TermAreaWidget(
					new ExpressionTree(vectorSpace, null), 
					m_expressionSymbolMap, 
					m_assetManager, 
					bitmapData, 
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
                var extraData : Dynamic = widgetAttributeRoot.extraData;
                m_textArea = new TextAreaWidget(
                        m_assetManager, 
                        bitmapData, 
                        extraData.backgroundAttachment, 
                        extraData.backgroundRepeat, 
                        extraData.autoCenterPages, 
                        extraData.allowScroll
                        );
                widget = m_textArea;
            }
            else if (widgetType == "button") 
            {
                var extraData = widgetAttributeRoot.extraData;
                
                var nineSliceString : String = extraData.nineSlice;
                var nineSlice : Rectangle = null;
                if (nineSliceString != null) 
                {
                    var nineSliceParts : Array<Dynamic> = nineSliceString.split(",");
                    nineSlice = new Rectangle(
                            Std.parseInt(nineSliceParts[0]), 
                            Std.parseInt(nineSliceParts[1]), 
                            Std.parseInt(nineSliceParts[2]), 
                            Std.parseInt(nineSliceParts[3])
                            );
                }
                
                var button : LabelButton = this.createPlainButton(
                        numberResources,
                        resourceList,
                        extraData.label,
                        extraData.label != null ? new TextFormat(extraData.fontName, extraData.fontSize, extraData.fontColor) : null,
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
            // Assign the widget view to the attributes node
            else if (widgetType == "barModelArea") 
            {
                var extraData = widgetAttributeRoot.extraData;
                
                // Need extra space to add additional bars at the bottom
                var bottomPadding : Float = 50;
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
            
            var uiRenderComponent : RenderableComponent = new RenderableComponent(widgetAttributeRoot.entityId);
            uiRenderComponent.view = widget;
            m_uiComponentManager.addComponentToEntity(uiRenderComponent);
            
            // Bind the widget attributes to the component manager
            m_uiComponentManager.addComponentToEntity(widgetAttributeRoot);
            
            if (widgetAttributeRoot.children != null) 
            {
                var i : Int = 0;
                var widgetChild : DisplayObject = null;
                var numWidgetChildren : Int = widgetAttributeRoot.children.length;
                for (i in 0...numWidgetChildren){
                    widgetChild = createWidgets(widgetAttributeRoot.children[i]);
                    (try cast(widget, Sprite) catch(e:Dynamic) null).addChild(widgetChild);
                }
            }
        }
        
        return widget;
    }
    
    private function createPlainButton(numberResources : Int,
            resourceList : Array<Dynamic>,
            label : String,
            textFormat : TextFormat,
            nineSlice : Rectangle) : LabelButton
    {
        var buttonImageNormal : String = ((numberResources > 0)) ? 
			resourceList[0].name : null;
		var buttonImageClick : String = ((numberResources > 1)) ? 
			resourceList[1].name : null;
        var buttonImageOver : String = ((numberResources > 2)) ? 
			resourceList[2].name : null;
        var buttonImageInactive : String = ((numberResources > 3)) ? 
			resourceList[3].name : null;
		
        var button : LabelButton = WidgetUtil.createButton(
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
    
    private function onTermAreaChanged(event : Dynamic) : Void
    {
		var data : Dynamic = null;
		if (Std.is(event, DataEvent)) {
			data = (try cast(event, DataEvent) catch (e : Dynamic) null).getData();
		}
        // We bubble up an event indicating the term area values have been modified
        // This fires an event only when both term areas are in a ready state
        var termAreas : Array<DisplayObject> = this.getUiEntitiesByClass(TermAreaWidget);
        var termAreasReady : Bool = true;
        var i : Int = 0;
        var numTermAreas : Int = termAreas.length;
        for (i in 0...numTermAreas){
            var termArea : TermAreaWidget = try cast(termAreas[i], TermAreaWidget) catch(e:Dynamic) null;
            if (!termArea.isReady) 
            {
                termAreasReady = false;
                break;
            }
        }
        
        if (termAreasReady) 
        {
            dispatchEvent(new Event(GameEvent.TERM_AREAS_CHANGED));
        }
    }
}
