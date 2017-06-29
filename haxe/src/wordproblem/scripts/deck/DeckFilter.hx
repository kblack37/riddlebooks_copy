package wordproblem.scripts.deck;


import flash.utils.Dictionary;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.ExpressionUtil;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.math.vectorspace.IVectorSpace;

import starling.utils.AssetManager;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.widget.DeckWidget;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.scripts.BaseGameScript;

/**
 * This class handles filtering the contents of the deck based on the equations
 * that are left to model as well as the current contents of the term area.
 * 
 * At any moment in time it guesses what equation the player is trying to model
 * and only enables the remaining cards needed to finish modeling it.
 */
class DeckFilter extends BaseGameScript
{
    private var m_deckWidget : DeckWidget;
    private var m_vectorSpace : IVectorSpace;
    private var m_termAreas : Array<TermAreaWidget>;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager)
    {
        super(gameEngine, expressionCompiler, assetManager);
    }
    
    override public function visit() : Int
    {
        return ScriptStatus.FAIL;
    }
    
    override public function dispose() : Void
    {
        super.m_gameEngine.removeEventListener(GameEvent.TERM_AREA_RESET, filterDeckSymbol);
        super.m_gameEngine.removeEventListener(GameEvent.TERM_AREA_CHANGED, filterDeckSymbol);
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        m_deckWidget = try cast(super.m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null;
        
        super.m_gameEngine.addEventListener(GameEvent.TERM_AREA_RESET, filterDeckSymbol);
        super.m_gameEngine.addEventListener(GameEvent.TERM_AREA_CHANGED, filterDeckSymbol);
    }
    
    private function filterDeckSymbol() : Void
    {
        // Perform a filter on the deck that in which the symbolic contents of the model areas
        // is compared against the contents of all remaining equations to model
        // TODO: Symbols in the equations to model only need to be calculated once
        var subtreeRoots : Array<ExpressionNode> = new Array<ExpressionNode>();
        var vectorSpace : IVectorSpace = m_vectorSpace;
        for (i in 0...m_termAreas.length){
            var termArea : TermAreaWidget = m_termAreas[i];
            var widgetRoot : BaseTermWidget = termArea.getWidgetRoot();
            if (widgetRoot != null) 
            {
                subtreeRoots.push(widgetRoot.getNode());
            }
        }  // Check that this set is a subset of the symbols within an equation to model  
        
        
        
        var allSymbolsInModelArea : Array<String> = ExpressionUtil.getUniqueSymbols(subtreeRoots, vectorSpace, !m_levelRules.allowCardFlip);
        
        var equationsLeftToModel : Array<ExpressionComponent> = new Array<ExpressionComponent>();
        var totalEquations : Array<ExpressionComponent> = m_equationSystem.getEquationsToModel();
        for (i in 0...totalEquations.length){
            var equation : ExpressionComponent = totalEquations[i];
            if (!equation.hasBeenModeled) 
            {
                equationsLeftToModel.push(equation);
            }
        }  // For every equation to model figure out what symbols compose it  
        
        
        
        var possibleEquationRoots : Array<ExpressionNode> = new Array<ExpressionNode>();
        for (i in 0...equationsLeftToModel.length){
            var equationToModel : ExpressionComponent = equationsLeftToModel[i];
            var symbolsInEquation : Dictionary = ExpressionUtil.getUniqueSymbols(equationToModel.root, vectorSpace, !m_levelRules.allowCardFlip);
            
            var isSubset : Bool = true;
            // Go through each symbols found in the model areas
            for (j in 0...allSymbolsInModelArea.length){
                // If a symbol in the model area is not in the modeled equation then we fail
                // for this equation
                var symbol : String = allSymbolsInModelArea[j];
                if (!symbolsInEquation.exists(symbol)) 
                {
                    isSubset = false;
                    break;
                }
            }
            
            if (isSubset) 
            {
                possibleEquationRoots.push(equationToModel.root);
            }
        }  // The union of all these set is what should be active in the deck    // then all those symbols are possibly valid.    // If all the symbols in the term area are present within a symbol set for an equation  
        
        
        
        
        
        
        
        this.refreshDeckContents(possibleEquationRoots, m_deck);
    }
    
    /**
     * Refresh the deck with all the unique symbols contained within a set of subtrees.
     * Most cases the subtrees are just the two sides of the equation.
     * 
     * If either subtree is null then we just empty the entire deck
     * 
     */
    private function refreshDeckContents(subtreeRoots : Array<ExpressionNode>,
            deck : DeckWidget) : Void
    {
        var vectorSpace : IVectorSpace = m_vectorSpace;
        
        // The active deck consists of all the distinct symbols contained in the whole equation
        
        // In the case of modeling, we need to compare which symbols have actually been
        // revealed within the set of discoverable terms. If the deck requires a term that has
        // not yet been revealed it will be replaced by a question mark or some locked symbol
        // that cannot be dragged.
        
        // Get the unique symbols in each subtree and derive the union of the symbols,
        // note that the negative signs are ignored in this case. The union list will
        // remove the signs completely
        var isolationSymbols : Array<String> = ExpressionUtil.getUniqueSymbols(subtreeRoots, vectorSpace, !m_levelRules.allowCardFlip)  /*
        const deckWidgets:Vector.<BaseTermWidget> = deck.getDeckWidgets();
        for (var j:int = 0; j < deckWidgets.length; j++)
        {
        // Keep hidden objects enabled
        const deckWidget:BaseTermWidget = deckWidgets[j];
        deckWidget.setEnabled(deckWidget.getIsHidden());
        for (var i:int = 0; i < isolationSymbols.length; i++)
        {
        const symbol:String = isolationSymbols[i];
        const symbolInDeck:String = deckWidget.getNode().data;
        if (symbolInDeck == symbol || symbolInDeck.charAt(0) == '-' && '-' + symbol == symbolInDeck)
        {
        deckWidget.setEnabled(true);
        break;
        }
        }
        }
        */    // disabled otherwise we toggle the enabled property if the symbol was within the set.    // For every symbol we look through each term in the deck. If it is hidden we leave it    // Figured out the set of symbols needed to satisfy a particular set of equations    // TODO:  ;
    }
}
