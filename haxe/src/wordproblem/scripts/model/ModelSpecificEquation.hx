package wordproblem.scripts.model;


import cgs.audio.Audio;
import dragonbox.common.math.vectorspace.RealsVectorSpace;
import dragonbox.common.util.XColor;
import motion.Actuate;
import motion.easing.Linear;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.filters.BitmapFilter;
import wordproblem.display.PivotSprite;
import wordproblem.engine.events.DataEvent;

import dragonbox.common.expressiontree.EquationSolver;
import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.ExpressionUtil;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.math.vectorspace.IVectorSpace;

import wordproblem.display.LabelButton;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.filters.ColorMatrixFilter;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.level.WordProblemLevelData;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;

/**
 * The script checks if the player has properly modeled one of the target equations laid out by the level.
 */
class ModelSpecificEquation extends BaseGameScript
{
    private var m_termAreas : Array<TermAreaWidget>;
    private var m_checkEquationButton : DisplayObject;
    private var m_audioDriver : Audio;
    
    /**
     * The solver is only necessary is if for some reason the goal equation to check against
     * isn't in definition form.
     */
    private var m_equationSolver : EquationSolver;
    
    /** 
     * TODO: This should be moved else where, has nothing to do with modeling
     * 
     * For logging purposes, keep track of the previous equation in the term areas, so that the incremental changes of 
     *  onTermAreaChanged can log before and after states.
     */
    private var m_previousEquation : String;
    
    /**
     * List of target equation the player is trying to model.
     */
    private var m_equations : Array<ExpressionComponent>;
    
    /**
     * When trying to model an equation it is possible for the player to try to
     * solve a problem with a small set of equations or a single one.
     * 
     * This structure represents all possible solutions to solving the problem
     * Each list is an id that references objects contained in the equation to model list.
     */
    private var m_equationSets : Array<Array<String>>;
    
    /**
     * Key: name of an alias term value
     * Value: the original term value
     * 
     * Multiple aliases might map to one original value
     */
    private var m_aliasValueToTermMap : Dynamic;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation", isActive);
        
        m_audioDriver = Audio.instance;
        m_previousEquation = "";
        m_equationSolver = new EquationSolver();
        m_equations = new Array<ExpressionComponent>();
        m_equationSets = new Array<Array<String>>();
        m_aliasValueToTermMap = { };
    }
    
    /**
     * For tutorial levels (mainly brainpop) it is possible for a player to pick one of many options in their model
     * and all options should be treated as correct
     * 
     * For example, the player have 5 choices to make an 'equation' with. The name is just cosmetic, all five options are ok.
     * Rather than making 5 separate reference equation, we can say those 5 choices are aliases for a single reference
     * value.
     * 
     * @param value
     *      The original term value the alias names are replaceable with
     * @param aliases
     *      List of term values that serve as an alias for the original
     */
    public function setTermValueAliases(value : String, aliases : Array<String>) : Void
    {
        var i : Int = 0;
        for (i in 0...aliases.length){
            Reflect.setField(m_aliasValueToTermMap, Std.string(aliases[i]), value);
        }
    }
    
    /**
     * Remove an alias mapping
     * 
     * @param value
     *      If null, clear all aliases
     */
    public function deleteTermValueAlias(value : String = null) : Void
    {

    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_ready) 
        {
            m_checkEquationButton.removeEventListener(MouseEvent.CLICK, onCheckEquationClicked);
            for (termArea in m_termAreas)
            {
                termArea.removeEventListener(GameEvent.TERM_AREA_CHANGED, onTermAreaChange);
            }
            
            if (value) 
            {
				m_checkEquationButton.filters = new Array<BitmapFilter>();
                m_checkEquationButton.addEventListener(MouseEvent.CLICK, onCheckEquationClicked);
                for (termArea in m_termAreas)
                {
                    termArea.addEventListener(GameEvent.TERM_AREA_CHANGED, onTermAreaChange);
                }
            }
            else if (m_checkEquationButton.filters.length == 0) 
            {
                // Set color to grey scale
				var filters = new Array<BitmapFilter>();
				filters.push(XColor.getGrayscaleFilter());
				m_checkEquationButton.filters = filters;
            }
            
            if (Std.is(m_checkEquationButton, LabelButton)) 
            {
                (try cast(m_checkEquationButton, LabelButton) catch(e:Dynamic) null).enabled = value;
            }
        }
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        
        var termAreaDisplayObjects : Array<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TermAreaWidget);
        m_termAreas = new Array<TermAreaWidget>();
        for (termArea in termAreaDisplayObjects)
        {
            m_termAreas.push(try cast(termArea, TermAreaWidget) catch(e:Dynamic) null);
        }
        
        m_checkEquationButton = m_gameEngine.getUiEntity("modelEquationButton");
        
        // Automatically activate on ready to rebind event listeners
        this.setIsActive(m_isActive);
    }
    
    /**
     * Add an equation to check for during the current equation modeling phase.
     * NOTE: Remember to bin equations into sets if you want to validate a system.
     * 
     * @param id 
     *      unique name of the equation so it can easily be accessed later
     * @param equation
     *      The equation to be modeled as a string (must have only one equals sign)
     * @param strictMatch
     *      If true, the a modeled equation must match the exact structure of the one given
     *      for it to pass. If false, the equation just needs to be semantically equal to the given one.
     *      VERY IMPORTANT: if set to the false the given equation must be in definition format, like
     *      x=a+b+c and not x-a=b+c, this is just how the check works that situation.
     * @param addToSetOfOne
     *      Many times we just want the modeling a one exact equation, if true we automatically add
     *      the equation to its own set
     */
    public function addEquation(id : String, decompiledEquation : String, strictMatch : Bool, addToSetOfOne : Bool = false) : Void
    {
        var expressionRoot : ExpressionNode = m_expressionCompiler.compile(decompiledEquation);
        var equationComponent : ExpressionComponent = new ExpressionComponent(
			id, 
			decompiledEquation, 
			expressionRoot
        );
        equationComponent.strictMatch = strictMatch;
        
        m_equations.push(equationComponent);
        if (addToSetOfOne) 
        {
            addEquationSet([id]);
        }
        
        m_gameEngine.dispatchEvent(new DataEvent(GameEvent.ADD_NEW_EQUATION, {
                    expression : expressionRoot
                }));
    }
    
    /**
     * Bind a set of equations that were previously already added via the addEquation function.
     * The purpose of this is for levels that allow a player to solve a part of the problem using 
     * a system of equations as well as have multiple solution sets. Perhaps they can use either a simple
     * set of multiple equation OR a single complex one.
     * 
     * @param equationIdsInSet
     *      list of the ids that were used in the addEquation function to indicate those equations should
     *      be part of a set.
     */
    public function addEquationSet(equationIdsInSet : Array<String>) : Void
    {
        m_equationSets.push(equationIdsInSet);
    }
    
    /**
     * Reset the target equation to model. Used only for levels that have multiple parts like the tutorials
     * 
     * (It removes all defined sets and goal equations added before)
     */
    public function resetEquations() : Void
    {
		m_equations = new Array<ExpressionComponent>();
		m_equationSets = new Array<Array<String>>();
    }
    
    /**
     * This is the terminating condition for most levels, check that at least one of the
     * assigned equation set is completed.
     */
    public function getAtLeastOneSetComplete() : Bool
    {
        var i : Int = 0;
        var idToEquationHasBeenModeled : Dynamic = { };
        for (i in 0...m_equations.length){
            var equation : ExpressionComponent = m_equations[i];
			Reflect.setField(idToEquationHasBeenModeled, equation.entityId, equation.hasBeenModeled);
        }
        
        var oneSetComplete : Bool = false;
        var numEquationSets : Int = m_equationSets.length;
        for (i in 0...numEquationSets){
            var allEquationsInSetModeled : Bool = true;
            var equationSetIds : Array<String> = m_equationSets[i];
            var j : Int = 0;
            for (j in 0...equationSetIds.length){
                var equationId : String = equationSetIds[j];
                if (!Reflect.field(idToEquationHasBeenModeled, equationId)) 
                {
                    allEquationsInSetModeled = false;
                    break;
                }
            }
            
            if (allEquationsInSetModeled) 
            {
                oneSetComplete = true;
                break;
            }
        }
        
        return oneSetComplete;
    }
    
    public function getNumberEquationsLeftToModel() : Int
    {
        var i : Int = 0;
        var numEquationsLeftToModel : Int = 0;
        var numEquationsToModel : Int = m_equations.length;
        for (i in 0...numEquationsToModel){
            if (!m_equations[i].hasBeenModeled) 
            {
                numEquationsLeftToModel++;
            }
        }
        return numEquationsLeftToModel;
    }
    
    /**
		 * Get back the list of equation ids in ALL the sets that the player is trying to model
		 */
    public function getEquationIdSets() : Array<Array<String>>
    {
        return m_equationSets;
    }
    
    /**
		 * Get back all equations that the player can model. This list includes the equations
     * the player has and has not correctly modeled. No information about how they are
     * separated into sets is included here.
		 */
    public function getEquations() : Array<ExpressionComponent>
    {
        return m_equations;
    }
    
    private function onTermAreaChange(event : Dynamic) : Void
    {
        /*
         * Returns the current equation (String) and whether or not it is correct (Boolean)
         * as a dynamic object. This requires a hole (ie. hack) to be punched into the 
         * script node system to get the data we need. This is used for logging, especially
         * the quest end.
         */
        
        // Log equation changed
        var loggingDetails : Dynamic = { };
        var givenEquation : ExpressionNode = m_gameEngine.getExpressionFromTermAreas();
        
        // Build result
        var matchingCorrectEquation : ExpressionComponent = this.checkEquationIsCorrect(
                givenEquation,
                m_expressionCompiler.getVectorSpace(),
                false
                );
        loggingDetails = {
                    equation : m_expressionCompiler.decompileAtNode(givenEquation),
                    isCorrect : matchingCorrectEquation != null,
                    goalEquation : ((matchingCorrectEquation != null)) ? matchingCorrectEquation.expressionString : "",
                };
        
        Reflect.setField(loggingDetails, "previousEquation", m_previousEquation);
        m_gameEngine.dispatchEvent(new DataEvent(AlgebraAdventureLoggingConstants.EQUATION_CHANGED_EVENT, loggingDetails));
        
        // cache the current given equation for the Before state upon the next change
        m_previousEquation = Reflect.field(loggingDetails, "equation");
    }
    
    private function onCheckEquationClicked(event : Dynamic) : Void
    {
        //log the button click first before checking the equation modeling.
        m_gameEngine.dispatchEvent(new DataEvent(AlgebraAdventureLoggingConstants.EQUALS_CLICKED_EVENT, {
                    buttonName : "EqualsButton"
                }));
        
        var currentLevel : WordProblemLevelData = m_gameEngine.getCurrentLevel();
        var allEquationsModeled : Bool = (this.getNumberEquationsLeftToModel() == 0);
        var vectorSpace : RealsVectorSpace = m_expressionCompiler.getVectorSpace();
        
        if (!allEquationsModeled) 
        {
            var givenEquation : ExpressionNode = m_gameEngine.getExpressionFromTermAreas();
            var modeledEquation : ExpressionComponent = this.checkEquationIsCorrect(
                    givenEquation,
                    vectorSpace,
                    true
                    );
            var solvedEquation : Bool = modeledEquation != null;
            var decompiledEquation : String = "";
            var goalEquationAttempted : String = "";
            if (solvedEquation) 
            {
                // Mark the equation as being modeled
                modeledEquation.hasBeenModeled = true;
                goalEquationAttempted = modeledEquation.expressionString;
                decompiledEquation = m_expressionCompiler.decompileAtNode(givenEquation);
                
                // Signal that an equation was finished
                m_gameEngine.dispatchEvent(new DataEvent(GameEvent.EQUATION_MODEL_SUCCESS, {
                            id : modeledEquation.entityId,
                            equation : decompiledEquation,
                        }));
            }
            else 
            {
                // If something is not a valid equation, then return the side that was not empty
                // If both were empty send an empty string
                if (givenEquation.left == null && givenEquation.right != null) 
                {
                    decompiledEquation = m_expressionCompiler.decompileAtNode(givenEquation.right);
                }
                else if (givenEquation.right == null && givenEquation.left != null) 
                {
                    decompiledEquation = m_expressionCompiler.decompileAtNode(givenEquation.left);
                }
                else 
                {
                    decompiledEquation = m_expressionCompiler.decompileAtNode(givenEquation);
                }
                
                m_gameEngine.dispatchEvent(new DataEvent(GameEvent.EQUATION_MODEL_FAIL, {
                            equation : decompiledEquation
                        }));
                
                // Get the first unmodeled equation
                for (i in 0...m_equations.length){
                    if (!m_equations[i].hasBeenModeled) 
                    {
                        goalEquationAttempted = m_equations[i].expressionString;
                        break;
                    }
                }
            }
            
            if (decompiledEquation == "=") 
            {
                decompiledEquation = "";
            } 
			
			// Log that an attempt was made to model a target equation regardless of whether it succeeded.  
            var loggingDetails : Dynamic = {
                equation : decompiledEquation,
                isCorrect : solvedEquation,
                goalEquation : goalEquationAttempted,
                setComplete : getAtLeastOneSetComplete(),
            };
            m_gameEngine.dispatchEvent(new DataEvent(AlgebraAdventureLoggingConstants.VALIDATE_EQUATION_MODEL, loggingDetails));
            
            // Provide visual feedback of whether the equation was correct or not
            var i : Int = 0;
            var color : Int = solvedEquation ? 0x8800FF00 : 0x88FF0000;
            for (i in 0...m_termAreas.length){
                m_termAreas[i].fadeOutBackground(color);
            } 
			
			// Show an incorrect or correct icon on top of the model button  
            // Tween in the icon 
            var modelEquationButton : DisplayObject = m_gameEngine.getUiEntity("modelEquationButton");
            var targetTextureName : String = ((solvedEquation)) ? "correct" : "wrong";
            var targetBitmapData : BitmapData = m_assetManager.getBitmapData(targetTextureName);
            var targetIcon : PivotSprite = new PivotSprite();
			targetIcon.addChild(new Bitmap(targetBitmapData));
            targetIcon.pivotX = targetBitmapData.width * 0.5;
            targetIcon.pivotY = targetBitmapData.height * 0.5;
            targetIcon.x = modelEquationButton.width * 0.5 + modelEquationButton.x;
            targetIcon.y = modelEquationButton.height * 0.5 + modelEquationButton.y;
            targetIcon.mouseEnabled = false;
            
            var endingScaleFactor : Float = modelEquationButton.width / targetBitmapData.width;
            var startingScaleFactor : Float = endingScaleFactor * 3;
            targetIcon.scaleX = targetIcon.scaleY = startingScaleFactor;
            targetIcon.alpha = 0.0;
            if (modelEquationButton.parent != null) 
            {
                modelEquationButton.parent.addChild(targetIcon);
            }
			
			Actuate.tween(targetIcon, 0.7, { scaleX: endingScaleFactor, scaleY: endingScaleFactor, alpha: 1 }).ease(Linear.easeNone).onComplete(function() : Void
                    {
						Actuate.tween(targetIcon, 0.3, { alpha: 0 }).delay(0.4).onComplete(function() : Void
                                {
									if (targetIcon.parent != null) targetIcon.parent.removeChild(targetIcon);
									targetIcon.dispose();
                                });
                    });
            
            //Provide audio feedback too.
            if (solvedEquation) 
            {
                m_audioDriver.playSfx("find_correct_equation");
            }
            else 
            {
                m_audioDriver.playSfx("wrong");
            }
        }
    }
    
    /**
     * Check if a given expression structure matches an equation that the player needs to model
     * 
     * @param ignoreAlreadyModeled
     *      If true, ignore matches on equations already marked as modeled
     * @return
     *      The equation that was modeled, null if none
     */
    public function checkEquationIsCorrect(rootToCheckAgainst : ExpressionNode,
            vectorSpace : RealsVectorSpace,
            ignoreAlreadyModeled : Bool) : ExpressionComponent
    {
        // It is possible to model and submit something like x=
        // In this degenerate case it is not possible to try to solve for the key
        var modeledEquation : ExpressionComponent = null;
        var rootToCheck : ExpressionNode = null;
        if (rootToCheckAgainst != null &&
            rootToCheckAgainst.left != null &&
            rootToCheckAgainst.right != null) 
        {
            // Replace alias values
            replaceAliasValues(rootToCheckAgainst);
            
            // This thing also seems to crash if we do something like 3=2+1, it cannot
            // handle equations without a variable. To check this, just go through every terminal
            // node and make sure at least one of them is not a numeric symbol
            var leafNodes : Array<ExpressionNode> = new Array<ExpressionNode>();
            ExpressionUtil.getLeafNodes(rootToCheckAgainst, leafNodes);
            var numLeaves : Int = leafNodes.length;
            var foundAtLeastOneVariable : Bool = false;
            for (i in 0...numLeaves){
                if (!ExpressionUtil.isNodeNumeric(leafNodes[i])) 
                {
                    foundAtLeastOneVariable = true;
                    break;
                }
            }
            
            if (foundAtLeastOneVariable) 
            {
                // Convert the equation so the target variable is on one side
                rootToCheck = rootToCheckAgainst;
            }
        }
        
        if (rootToCheck != null && !ExpressionUtil.wildCardNodeExists(rootToCheck)) 
        {
            var currentLevel : WordProblemLevelData = m_gameEngine.getCurrentLevel();
            for (i in 0...m_equations.length){
                // Do not check if the equation already has been modeled
                var equationToModel : ExpressionComponent = m_equations[i];
                if (!equationToModel.hasBeenModeled || !ignoreAlreadyModeled) 
                {
                    var goalRoot : ExpressionNode = equationToModel.root;
					var equationsEqual : Bool = false;
                    if (equationToModel.strictMatch) 
                    {
                        // We force that the simplifying assumption that the left side of the goal equation
                        // is always just a definition variable
                        equationsEqual = ExpressionUtil.getExpressionsStructurallyEquivalent(
                                goalRoot,
                                rootToCheck,
                                true,
                                vectorSpace
                                );
                    }
                    else 
                    {
                        equationsEqual = ExpressionUtil.getEquationsSemanticallyEquivalent(
                                        goalRoot,
                                        rootToCheck,
                                        vectorSpace
                                        );
                    }
                    
                    if (equationsEqual) 
                    {
                        modeledEquation = equationToModel;
                    }
                }
            }
        }
        
        return modeledEquation;
    }
    
    private function replaceAliasValues(node : ExpressionNode) : Void
    {
        if (node != null) 
        {
            if (Reflect.hasField(m_aliasValueToTermMap, node.data)) 
            {
                node.data = Reflect.field(m_aliasValueToTermMap, node.data);
            }
            replaceAliasValues(node.left);
            replaceAliasValues(node.right);
        }
    }
}
