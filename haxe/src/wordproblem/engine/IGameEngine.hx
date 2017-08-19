package wordproblem.engine;


import dragonbox.common.display.ISprite;
import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

import openfl.display.DisplayObject;
import openfl.events.Event;
import openfl.geom.Point;

import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.level.WordProblemLevelData;
import wordproblem.engine.text.model.DocumentNode;

/**
	 * The main entry point from which various scripted events can manipulate the state of the
	 * game. This will probably grow into a large class since we require an interface that
 * allows for any data to be polled from it as well as any game related action to be executed in it.
 * (for example there should be a function to highlight a specific card in the deck during a minigame
 * or trigger a a piece of dialog to be played)
 * 
 * Ideally the only thing the engine is act as a black board where some external scripting file
 * inputs data to alter the gameworld or poll data or events to make decision on what to do next.
 * 
 * It is also the point where relevant logging information about player actions flow into and out
 * of the system.
 * 
	 */
interface IGameEngine extends ISprite
{

    /** Prototype needed to indicate the interface with event dispatcher */
    function addEventListener(type : String, listener : Dynamic->Void, useCapture : Bool = false, priority : Int = 0, useWeakReference : Bool = false) : Void;
    
    /** Prototype needed to indicate the interface with event dispatcher */
    function removeEventListener(type : String, listener : Dynamic->Void, useCapture : Bool = false) : Void;
    
    /** Prototype needed to indicate the interface with event dispatcher */
    function dispatchEvent(event : Event) : Bool;
    
    /** Frame ticker to update all the data in the game world */
    function update(time : Time, mouseState : MouseState) : Void;
    
    /** Expose the mouse state so scripts can link into changes in clicks and touches */
    function getMouseState() : MouseState;
    
    /**
     * Get the rendering data about cards
     */
    function getExpressionSymbolResources() : ExpressionSymbolMap;
    
    /**
     * Get temp items in a level
     */
    function getItemComponentManager() : ComponentManager;
    
    /**
     * Get list of ui parts in the screen
     */
    function getUiComponentManager() : ComponentManager;
    
    /**
     * Get character data for the helper entities
     */
    function getCharacterComponentManager() : ComponentManager;
    
    /**
     * Get the actual ui display object bound to a specific id
     * 
     * @param entityId
     *      The instance name of the widget to get, these are normally defined in the xml struct
     * @return
     *      Null if the ui entity does not exist or the game is not in the proper mode yet
     */
    function getUiEntity(entityId : String) : DisplayObject;
    
    /**
     * Get the ui component at a location
     * 
     * @param aPoint
     *      Typically a mousePoint, but conceivably anywhere.
     * @return
     *      Null if the ui entity does not exist or the game is not in the proper mode yet
     */
    function getUiEntityUnder(aPoint : Point) : RenderableComponent;
    
    /**
     * Get back a list of ui objects that match a given class definition
     * 
     * @param classDefinition
     *      The class name to fetch matching ui objects for
     * @param outObject
     *      list that will be populated with matching entities
     * @return
     *      The list of ui object, empty if nothing matched the given class
     */
    function getUiEntitiesByClass(classDefinition : Class<Dynamic>, outObjects : Array<DisplayObject> = null) : Array<DisplayObject>;
    
    /**
     * Given an existing display object, get what the assigned entity id for that
     * object should be.
     * 
     * Useful in scripts that get entities by the class type but later, for something like logging purposes
     * need to figure out what specific object of that class type was modified
     * 
     * @param diplayObject
     *      The ui entity to get id for
     * @return
     *      The entity id of the displayObject, null if nothing found
     */
    function getUiEntityIdFromObject(displayObject : DisplayObject) : String;
    
    /**
     * Toggle whether this should go into a pause state. The usage is when a player opens up an option menu
     * or the copilot pauses the game.
     * 
     * @param value
     *      True if the game should go into the pause state, false if it should continue
     */
    function setPaused(value : Bool) : Void;
    
    /**
     * There are some instances where a level will want to completely redraw a page or set of
     * pages. This can happen when we want to dynamically add new xml chunks to a level.
     * 
     * @param index
     *      The index of the page to redraw
     * @param
     *      The root model to use to recreate the page
     */
    function redrawPageViewAtIndex(index : Int, documentNodeRoot : DocumentNode) : Void;
    
    /**
     * Bind a portions of text to a particular term value
     * 
     * @param termValue
     *      Either an integer value or variable name that was declared in the level definition
     * @param documentId
     *      The tagged "id" attribute contained in the textual portion of the level definition
     */
    function addTermToDocument(termValue : String, documentId : String) : Bool;
    
    /**
     * Set the contents of the deck area, accepts a list of strings representing the expressions
     * to be inserted into the deck.
     * 
     * @param content
     *      The expression strings to be added to the deck
     * @param hidden
     *      A flag indicating whether the current content should be hidden from view initially
     *      Indices need to match up with the content.
     * @param attemptMergeSymbol
     *      If true we will compare the list of symbols with the existing deck and try to
     *      append the new symbols. If false we discard everything in the deck and create
     *      new instances of the cards.
     */
    function setDeckAreaContent(content : Array<String>, hidden : Array<Bool>, attemptMergeSymbols : Bool) : Bool;
    
    /**
     * Toggle the visibility of one or both of the term areas
     * 
     * @param id
     *      The name of the widget to toggle. The ids were specified
     *      in the level file or the default configuration.
     * @return
     *      True if the action successfully completed 
     */
    function setWidgetVisible(id : String, visible : Bool) : Bool;
    
    /**
     * Get the current expression represented by the contents of the term areas
     * 
     * @return
     *      Root expression node that combines the expression of all active term areas
     */
    function getExpressionFromTermAreas() : ExpressionNode;
    
    /**
     * Get the current contents of the term area compressed into a list of subtrees.
     * 
     * @param ids
     *      The id names of the term area from which to pull. If empty list then get the 
     *      contents of every term area, later it will populate the list with the term area ids.
     * @param outNodes
     *      List that will contain the set of expression nodes indexed the same of the ids. May contain
     *      null entries if a term area is empty
     * @return
     *      True if the action successfully completed.
     */
    function getTermAreaContent(ids : Array<String>, outNodes : Array<ExpressionNode>) : Bool;
    
    /**
     * Set the expression content for one or more term areas
     *
     * @param termAreaIds
     *      A space separated list of ids bound to a term area widget. The ids were specified
     *      in the level file or the default configuration.
     * @param content
     *      An expression in decompiled string format
     * @return
     *      True if the action successfully completed
     */
    function setTermAreaContent(termAreaIds : String, content : String) : Bool;
    
    /**
     * Used to fetch settings about the current word problem level being played. Note that modifying
     * the properties of the returned object may change the game instantaneously.
     * 
     * An example usage is for pre-written scripts to freely modify level rules while the game is playing
     * 
     * @return
     *      The current level data object.
     */
    function getCurrentLevel() : WordProblemLevelData;
}
