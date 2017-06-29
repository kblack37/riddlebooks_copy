package wordproblem.scripts.deck;


import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import starling.display.DisplayObject;
import wordproblem.resource.AssetManager;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.widget.DeckWidget;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.scripts.BaseGameScript;

/**
 * This script is used to control the number of times that a particular card in the
 * deck can be added to one of the term areas.
 * 
 * Used primarily for tutorial levels, one example is we want the player to sum together
 * a few cards but want to ensure they can only pick distinct ones.
 */
class RestrictCardAmount extends BaseGameScript
{
    /**
     * List of limits for each card.
     * 
     * Index needs to match with list of values
     */
    private var m_limits : Array<Int>;
    
    /**
     * List of values that have restricted limits.
     * 
     * Index needs to match with the list of limits
     */
    private var m_values : Array<String>;
    
    private var m_termAreas : Array<TermAreaWidget>;
    
    /**
     * Temp buffer to get all cards in the existing term widgets
     */
    private var m_outWidgetLeaves : Array<BaseTermWidget>;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_limits = new Array<Int>();
        m_values = new Array<String>();
        m_outWidgetLeaves = new Array<BaseTermWidget>();
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        m_gameEngine.removeEventListener(GameEvent.TERM_AREAS_CHANGED, onTermAreasChanged);
    }
    
    public function setLimitForValue(limit : Int, value : String) : Void
    {
        m_limits.push(limit);
        m_values.push(value);
    }
    
    /**
     * Remove all limits that had been set
     */
    public function resetAllLimits() : Void
    {
        as3hx.Compat.setArrayLength(m_limits, 0);
        as3hx.Compat.setArrayLength(m_values, 0);
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        // Get all term areas and listen for changes in their contents
        var termAreaDisplays : Array<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TermAreaWidget);
        m_termAreas = new Array<TermAreaWidget>();
        for (termAreaDisplay in termAreaDisplays)
        {
            m_termAreas.push(try cast(termAreaDisplay, TermAreaWidget) catch(e:Dynamic) null);
        }
        
        m_gameEngine.addEventListener(GameEvent.TERM_AREAS_CHANGED, onTermAreasChanged);
    }
    
    private function onTermAreasChanged() : Void
    {
        as3hx.Compat.setArrayLength(m_outWidgetLeaves, 0);
        
        var deckWidget : DeckWidget = try cast(m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null;
        
        // First get all cards
        var i : Int;
        var numTermAreas : Int = m_termAreas.length;
        var termAreaWidget : TermAreaWidget;
        for (i in 0...numTermAreas){
            termAreaWidget = m_termAreas[i];
            termAreaWidget.getWidgetLeaves(m_outWidgetLeaves);
        }  // number of cards with that same value do not exceed the limit.    // Then search for each value with a limit and make sure the actual  
        
        
        
        
        
        var numTotalCards : Int = m_outWidgetLeaves.length;
        var numCardsWithLimit : Int = m_values.length;
        var value : String;
        var limit : Int;
        for (i in 0...numCardsWithLimit){
            value = m_values[i];
            limit = m_limits[i];
            
            var j : Int;
            var baseTermWidget : BaseTermWidget;
            var numCardsWithSameValue : Int = 0;
            for (j in 0...numTotalCards){
                baseTermWidget = m_outWidgetLeaves[j];
                if (baseTermWidget.getNode().data == value || baseTermWidget.getNode().getOppositeValue() == value) 
                {
                    numCardsWithSameValue++;
                }
            }  // Make sure it is visible if it is below    // Make sure card is hidden if it exceeds or is at the limit  
            
            
            
            
            
            if (numCardsWithSameValue >= limit) 
            {
                deckWidget.toggleSymbolEnabled(false, value);
            }
            else 
            {
                deckWidget.toggleSymbolEnabled(true, value);
            }
        }
    }
}
