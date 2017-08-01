package wordproblem.hints;


import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.ExpressionUtil;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import starling.display.DisplayObject;
import starling.display.Sprite;
import starling.text.TextField;
import starling.utils.VAlign;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.expression.SymbolData;
import wordproblem.engine.expression.tree.ExpressionTree;
import wordproblem.engine.expression.widget.ExpressionTreeWidget;
import wordproblem.engine.text.GameFonts;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.model.ModelSpecificEquation;

/**
 * Like the bar model show answer hint, this is really just a cheat that allows the player to
 * give up if they are having trouble with a problem.
 */
class ShowEquationAnswerHint extends HintScript
{
    private static inline var WARNING_TEXT : String = "Having trouble figuring out the equation. Click show to see the answer. Warning: You won't get credit for solving this problem if you use this hint.";
    
    /**
		 * Interface to every other part of the game
		 */
    private var m_gameEngine : IGameEngine;
    
    /**
     * Need to have operators be a specific color, this requires overriding
     * some of the values of the symbol map used to construct an expression view.
     */
    private var m_clonedExpressionSymbolMap : ExpressionSymbolMap;
    
    /**
     * There are instances where we need to switch to and from expressions in string and node
     * format, which the compiler handles.
     */
    private var m_expressionTreeCompiler : IExpressionTreeCompiler;
    
    /**
     * This is needed to create the expression views.
     */
    private var m_assetManager : AssetManager;
    
    /**
		 * Dependency on this script since it stores all the data about what equations need to be
		 * modeled and what equations have yet to be validated
		 */
    private var m_modelSpecificEquation : ModelSpecificEquation;
    
    /**
		 * Keep track of whether the player has pressed show (confirmation that they want to see the answer)
		 */
    private var m_activated : Bool;
    
    public function new(gameEngine : IGameEngine,
            expressionTreeCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            modelSpecificEquation : ModelSpecificEquation,
            unlocked : Bool,
            id : String = null,
            isActive : Bool = true)
    {
        super(unlocked, id, isActive);
        
        m_modelSpecificEquation = modelSpecificEquation;
        m_expressionTreeCompiler = expressionTreeCompiler;
        m_assetManager = assetManager;
        m_gameEngine = gameEngine;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        // Clean out the textures of the map used to create the descriptions
        if (m_clonedExpressionSymbolMap != null) 
        {
            m_clonedExpressionSymbolMap.clear();
        }
    }
    
    override public function show() : Void
    {
        if (!m_activated) 
        {
            m_activated = true;
            
            // Set the used cheat flag
            m_gameEngine.getCurrentLevel().statistics.usedEquationModelCheatHint = true;
        }  // Check just the first equation set (treating this as the cannonical answer)  
        
        
        
        var allEquationSets : Array<Array<String>> = m_modelSpecificEquation.getEquationIdSets();
        if (allEquationSets.length > 0) 
        {
            var referenceSet : Array<String> = allEquationSets[0];
            var allEquations : Array<ExpressionComponent> = m_modelSpecificEquation.getEquations();
            var numEquations : Int = allEquations.length;
            var i : Int = 0;
            var numEquationIds : Int = referenceSet.length;
            
            // We get the very first unmodeled equation from the first set as the answer.
            // In the common case where we just have a single goal equation, this is the only thing we need.
            var equationToShow : ExpressionComponent = null;
            for (i in 0...numEquationIds){
                var equation : ExpressionComponent = this.getEquationFromId(referenceSet[i]);
                if (!equation.hasBeenModeled) 
                {
                    equationToShow = equation;
                    
                    var leftRoot : ExpressionNode = equationToShow.root.left;
                    var leftExpressionString : String = ((leftRoot != null)) ? 
                    ExpressionUtil.print(leftRoot, m_expressionTreeCompiler.getVectorSpace()) : null;
                    var rightRoot : ExpressionNode = equationToShow.root.right;
                    var rightExpressionString : String = ((rightRoot != null)) ? 
                    ExpressionUtil.print(rightRoot, m_expressionTreeCompiler.getVectorSpace()) : null;
                    m_gameEngine.setTermAreaContent("leftTermArea", leftExpressionString);
                    m_gameEngine.setTermAreaContent("rightTermArea", rightExpressionString);
                    
                    break;
                }
            }
        }
    }
    
    override public function isUsefulForCurrentState() : Bool
    {
        // This hint assumes that it will mostly just be used for the
        // generic level (either model equation is the only thing to do or
        // the bar model must be constructed first)
        var isUseful : Bool = false;
        
        // Need to check if the bar modeling is complete
        // If it doesn't exist we assume we are immediately in the equation model secion.
        if (m_modelSpecificEquation.getIsActive()) 
        {
            isUseful = true;
        }
        return isUseful;
    }
    
    override public function getDescription(width : Float, height : Float) : DisplayObject
    {
        // We have two types of description, one is a warning telling them to try first and saying
        // the problem is incorrect if they use this hint
        var descriptionContainer : Sprite = new Sprite();
        if (!m_activated) 
        {
            textField = new TextField(width, height, WARNING_TEXT, GameFonts.DEFAULT_FONT_NAME, 22);
            textField.vAlign = VAlign.TOP;
            descriptionContainer.addChild(textField);
        }
        else 
        {
            var textField : TextField = new TextField(width, 50, "This is the answer.", GameFonts.DEFAULT_FONT_NAME, 22);
            descriptionContainer.addChild(textField);
            
            if (m_clonedExpressionSymbolMap == null) 
            {
                m_clonedExpressionSymbolMap = m_gameEngine.getExpressionSymbolResources().clone();
                
                // Paint operators black
                var operatorNames : Array<String> = ["+", "/", "=", "*", "-"];
                for (operatorName in operatorNames)
                {
                    var operatorData : SymbolData = m_clonedExpressionSymbolMap.getSymbolDataFromValue(operatorName);
                    if (operatorData != null) 
                    {
                        operatorData.symbolTextureColor = 0;
                    }
                }
            }  // the equations will look like as a term area view    // For every expression in the first set we need to create an image of what  
            
            
            
            
            
            var allEquationSets : Array<Array<String>> = m_modelSpecificEquation.getEquationIdSets();
            if (allEquationSets.length > 0) 
            {
                var referenceSet : Array<String> = allEquationSets[0];
                var numEquationIds : Int = referenceSet.length;
                var i : Int = 0;
                var yOffset : Float = textField.height;
                for (i in 0...numEquationIds){
                    var equation : ExpressionComponent = this.getEquationFromId(referenceSet[i]);
                    var equationRoot : ExpressionNode = m_expressionTreeCompiler.compile(equation.expressionString).head;
                    
                    // Create a new view
                    var equationView : ExpressionTreeWidget = new ExpressionTreeWidget(
                    new ExpressionTree(m_expressionTreeCompiler.getVectorSpace(), equationRoot), 
                    m_clonedExpressionSymbolMap, 
                    m_assetManager, 
                    300, 100, 
                    );
                    
                    // The hint background is white, by default the operator images are also white.
                    // We need to make sure the equation is colored differently so it is visible.
                    // Ideally we could clone all the symbol data and them inject custom image with a better color.
                    
                    equationView.refreshNodes();
                    equationView.buildTreeWidget();
                    equationView.x = (width - equationView.width) * 0.5;
                    equationView.y = yOffset;
                    descriptionContainer.addChild(equationView);
                    
                    // Position all the equation views in a vertical list
                    yOffset += equationView.height;
                }
            }
        }
        
        return descriptionContainer;
    }
    
    private function getEquationFromId(id : String) : ExpressionComponent
    {
        var matchingEquation : ExpressionComponent = null;
        var allEquations : Array<ExpressionComponent> = m_modelSpecificEquation.getEquations();
        var numEquations : Int = allEquations.length;
        var i : Int = 0;
        for (i in 0...numEquations){
            var equation : ExpressionComponent = allEquations[i];
            if (equation.entityId == id) 
            {
                matchingEquation = equation;
                break;
            }
        }
        return matchingEquation;
    }
}
