package wordproblem.scripts.model
{
    import cgs.Audio.Audio;
    
    import dragonbox.common.expressiontree.EquationSolver;
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.ExpressionUtil;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.math.vectorspace.IVectorSpace;
    
    import feathers.controls.Button;
    
    import starling.animation.Transitions;
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    import starling.events.Event;
    import starling.filters.ColorMatrixFilter;
    import starling.textures.Texture;
    
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
    public class ModelSpecificEquation extends BaseGameScript
    {
        private var m_termAreas:Vector.<TermAreaWidget>;
        private var m_checkEquationButton:DisplayObject;
        private var m_audioDriver:Audio;
        
        /**
         * The solver is only necessary is if for some reason the goal equation to check against
         * isn't in definition form.
         */
        private var m_equationSolver:EquationSolver;
        
        /** 
         * TODO: This should be moved else where, has nothing to do with modeling
         * 
         * For logging purposes, keep track of the previous equation in the term areas, so that the incremental changes of 
         *  onTermAreaChanged can log before and after states.
         */ 
        private var m_previousEquation:String;
        
        /**
         * List of target equation the player is trying to model.
         */
        private var m_equations:Vector.<ExpressionComponent>;
        
        /**
         * When trying to model an equation it is possible for the player to try to
         * solve a problem with a small set of equations or a single one.
         * 
         * This structure represents all possible solutions to solving the problem
         * Each list is an id that references objects contained in the equation to model list.
         */
        private var m_equationSets:Vector.<Vector.<String>>;
        
        /**
         * Key: name of an alias term value
         * Value: the original term value
         * 
         * Multiple aliases might map to one original value
         */
        private var m_aliasValueToTermMap:Object;
        
        public function ModelSpecificEquation(gameEngine:IGameEngine, 
                                              expressionCompiler:IExpressionTreeCompiler, 
                                              assetManager:AssetManager, 
                                              id:String=null, 
                                              isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation", isActive);
            
            m_audioDriver = Audio.instance;
            m_previousEquation = "";
            m_equationSolver = new EquationSolver();
            m_equations = new Vector.<ExpressionComponent>();
            m_equationSets = new Vector.<Vector.<String>>();
            m_aliasValueToTermMap = new Object();
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
        public function setTermValueAliases(value:String, aliases:Vector.<String>):void
        {
            var i:int;
            for (i = 0; i < aliases.length; i++)
            {
                m_aliasValueToTermMap[aliases[i]] = value;
            }
        }
        
        /**
         * Remove an alias mapping
         * 
         * @param value
         *      If null, clear all aliases
         */
        public function deleteTermValueAlias(value:String=null):void
        {
            if (value == null)
            {
                for (var key:String in m_aliasValueToTermMap)
                {
                    delete m_aliasValueToTermMap[key];
                }
            }
            else if (m_aliasValueToTermMap.hasOwnProperty(value))
            {
                delete m_aliasValueToTermMap[value];   
            }
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            if (m_ready)
            {
                m_checkEquationButton.removeEventListener(Event.TRIGGERED, onCheckEquationClicked);
                for each (var termArea:TermAreaWidget in m_termAreas)
                {
                    termArea.removeEventListener(GameEvent.TERM_AREA_CHANGED, onTermAreaChange);
                }
                
                if (value)
                {
                    m_checkEquationButton.filter = null;
                    m_checkEquationButton.addEventListener(Event.TRIGGERED, onCheckEquationClicked);
                    for each (termArea in m_termAreas)
                    {
                        termArea.addEventListener(GameEvent.TERM_AREA_CHANGED, onTermAreaChange);
                    }
                }
                else if (m_checkEquationButton.filter == null)
                {
                    // Set color to grey scale
                    var colorMatrixFilter:ColorMatrixFilter = new ColorMatrixFilter();
                    colorMatrixFilter.adjustSaturation(-1);
                    m_checkEquationButton.filter = colorMatrixFilter;
                }
                
                if (m_checkEquationButton is Button)
                {
                    (m_checkEquationButton as Button).isEnabled = value;
                }
            }
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            var termAreaDisplayObjects:Vector.<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TermAreaWidget);
            m_termAreas = new Vector.<TermAreaWidget>();
            for each (var termArea:DisplayObject in termAreaDisplayObjects)
            {
                m_termAreas.push(termArea as TermAreaWidget);
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
        public function addEquation(id:String, decompiledEquation:String, strictMatch:Boolean, addToSetOfOne:Boolean=false):void
        {
            var expressionRoot:ExpressionNode = m_expressionCompiler.compile(decompiledEquation).head;
            var equationComponent:ExpressionComponent = new ExpressionComponent(
                id,
                decompiledEquation,
                expressionRoot
            );
            equationComponent.strictMatch = strictMatch;
            
            m_equations.push(equationComponent);
            if (addToSetOfOne)
            {
                addEquationSet(Vector.<String>([id]));
            }
            
            m_gameEngine.dispatchEventWith(GameEvent.ADD_NEW_EQUATION, false, {expression:expressionRoot});
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
        public function addEquationSet(equationIdsInSet:Vector.<String>):void
        {
            m_equationSets.push(equationIdsInSet);
        }
        
        /**
         * Reset the target equation to model. Used only for levels that have multiple parts like the tutorials
         * 
         * (It removes all defined sets and goal equations added before)
         */
        public function resetEquations():void
        {
            m_equations.length = 0;
            m_equationSets.length = 0;
        }
        
        /**
         * This is the terminating condition for most levels, check that at least one of the
         * assigned equation set is completed.
         */
        public function getAtLeastOneSetComplete():Boolean
        {
            var i:int;
            var idToEquationHasBeenModeled:Object = {};
            for (i = 0; i < m_equations.length; i++)
            {
                var equation:ExpressionComponent = m_equations[i];
                idToEquationHasBeenModeled[equation.entityId] = equation.hasBeenModeled;
            }
            
            var oneSetComplete:Boolean = false;
            var numEquationSets:int = m_equationSets.length;
            for (i = 0; i < numEquationSets; i++)
            {
                var allEquationsInSetModeled:Boolean = true;
                var equationSetIds:Vector.<String> = m_equationSets[i];
                var j:int;
                for (j = 0; j < equationSetIds.length; j++)
                {
                    var equationId:String = equationSetIds[j];
                    if (!idToEquationHasBeenModeled[equationId])
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
        
        public function getNumberEquationsLeftToModel():int
        {
            var i:int;
            var numEquationsLeftToModel:int = 0;
            var numEquationsToModel:int = m_equations.length;
            for (i = 0; i < numEquationsToModel; i++)
            {
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
		public function getEquationIdSets():Vector.<Vector.<String>>
		{
			return m_equationSets;
		}
		
		/**
		 * Get back all equations that the player can model. This list includes the equations
         * the player has and has not correctly modeled. No information about how they are
         * separated into sets is included here.
		 */
		public function getEquations():Vector.<ExpressionComponent>
		{
			return m_equations;
		}
        
        private function onTermAreaChange():void
        {
            /*
             * Returns the current equation (String) and whether or not it is correct (Boolean)
             * as a dynamic object. This requires a hole (ie. hack) to be punched into the 
             * script node system to get the data we need. This is used for logging, especially
             * the quest end.
             */
            
            // Log equation changed
            var loggingDetails:Object = new Object();
            var givenEquation:ExpressionNode = m_gameEngine.getExpressionFromTermAreas();
            
            // Build result
            var matchingCorrectEquation:ExpressionComponent = this.checkEquationIsCorrect(
                givenEquation, 
                m_expressionCompiler.getVectorSpace(), 
                false
            );
            loggingDetails = {
                equation:m_expressionCompiler.decompileAtNode(givenEquation), 
                isCorrect:matchingCorrectEquation != null,
                goalEquation:(matchingCorrectEquation != null) ? matchingCorrectEquation.expressionString : ""
            };
            
            loggingDetails["previousEquation"] = m_previousEquation;
            m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.EQUATION_CHANGED_EVENT, false, loggingDetails);

            // cache the current given equation for the Before state upon the next change
            m_previousEquation = loggingDetails["equation"];
        }
        
        private function onCheckEquationClicked():void
        {   
            //log the button click first before checking the equation modeling.
            m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.EQUALS_CLICKED_EVENT, false, {buttonName:"EqualsButton"} );
            
            var currentLevel:WordProblemLevelData = m_gameEngine.getCurrentLevel();
            var allEquationsModeled:Boolean = (this.getNumberEquationsLeftToModel() == 0);
            var vectorSpace:IVectorSpace = m_expressionCompiler.getVectorSpace();
            
            if (!allEquationsModeled)
            {
                var givenEquation:ExpressionNode = m_gameEngine.getExpressionFromTermAreas();
                var modeledEquation:ExpressionComponent = this.checkEquationIsCorrect(
                    givenEquation, 
                    vectorSpace,
                    true
                );
                var solvedEquation:Boolean = modeledEquation != null;
                var decompiledEquation:String = "";
                var goalEquationAttempted:String = "";
                if (solvedEquation)
                {
                    // Mark the equation as being modeled
                    modeledEquation.hasBeenModeled = true;
                    goalEquationAttempted = modeledEquation.expressionString;
                    decompiledEquation = m_expressionCompiler.decompileAtNode(givenEquation);
                    
                    // Signal that an equation was finished
                    m_gameEngine.dispatchEventWith(GameEvent.EQUATION_MODEL_SUCCESS, false, {id:modeledEquation.entityId, equation:decompiledEquation});
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
                    
                    m_gameEngine.dispatchEventWith(GameEvent.EQUATION_MODEL_FAIL, false, {equation:decompiledEquation});
                    
                    // Get the first unmodeled equation
                    for (i = 0; i < m_equations.length; i++)
                    {
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
                var loggingDetails:Object = {
                    equation:decompiledEquation, 
                    isCorrect:solvedEquation,
                    goalEquation:goalEquationAttempted,
                    setComplete:getAtLeastOneSetComplete()
                };
                m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.VALIDATE_EQUATION_MODEL, false, loggingDetails);
                
                // Provide visual feedback of whether the equation was correct or not
                var i:int;
                var color:uint = (solvedEquation) ? 0x00FF00 : 0xFF0000;
                for (i = 0; i < m_termAreas.length; i++)
                {
                    m_termAreas[i].fadeOutBackground(color);
                }
                
                // Show an incorrect or correct icon on top of the model button
                // Tween in the icon
                var modelEquationButton:DisplayObject = m_gameEngine.getUiEntity("modelEquationButton");
                var targetTextureName:String = (solvedEquation) ? "correct" : "wrong";
                var targetTexture:Texture = m_assetManager.getTexture(targetTextureName);
                var targetIcon:Image = new Image(targetTexture);
                targetIcon.pivotX = targetTexture.width * 0.5;
                targetIcon.pivotY = targetTexture.height * 0.5;
                targetIcon.x = modelEquationButton.width * 0.5 + modelEquationButton.x;
                targetIcon.y = modelEquationButton.height * 0.5 + modelEquationButton.y;
                targetIcon.touchable = false;
                
                var endingScaleFactor:Number = modelEquationButton.width / targetTexture.width;
                var startingScaleFactor:Number = endingScaleFactor * 3;
                targetIcon.scaleX = targetIcon.scaleY = startingScaleFactor;
                targetIcon.alpha = 0.0;
                if (modelEquationButton.parent)
                {
                    modelEquationButton.parent.addChild(targetIcon);
                }
                
                var fadeInTween:Tween = new Tween(targetIcon, 0.7, Transitions.LINEAR);
                fadeInTween.animate("scaleX", endingScaleFactor);
                fadeInTween.animate("scaleY", endingScaleFactor);
                fadeInTween.animate("alpha", 1.0);
                fadeInTween.onComplete = function():void
                {
                    var fadeOutTween:Tween = new Tween(targetIcon, 0.3);
                    fadeOutTween.animate("alpha", 0.0);
                    fadeOutTween.delay = 0.4;
                    fadeOutTween.onComplete = function():void
                    {
                        targetIcon.removeFromParent(true);
                    };
                    Starling.juggler.add(fadeOutTween);
                };
                Starling.juggler.add(fadeInTween); 
                
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
        public function checkEquationIsCorrect(rootToCheckAgainst:ExpressionNode, 
                                               vectorSpace:IVectorSpace, 
                                               ignoreAlreadyModeled:Boolean):ExpressionComponent
        {
            // It is possible to model and submit something like x=
            // In this degenerate case it is not possible to try to solve for the key
            var modeledEquation:ExpressionComponent = null;
            var rootToCheck:ExpressionNode = null;
            if (rootToCheckAgainst != null && 
                rootToCheckAgainst.left != null && 
                rootToCheckAgainst.right != null)
            {
                // Replace alias values
                replaceAliasValues(rootToCheckAgainst);
                
                // This thing also seems to crash if we do something like 3=2+1, it cannot
                // handle equations without a variable. To check this, just go through every terminal
                // node and make sure at least one of them is not a numeric symbol
                var leafNodes:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
                ExpressionUtil.getLeafNodes(rootToCheckAgainst, leafNodes);
                var numLeaves:int = leafNodes.length;
                var foundAtLeastOneVariable:Boolean = false;
                for (i = 0; i < numLeaves; i++)
                {
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
                var currentLevel:WordProblemLevelData = m_gameEngine.getCurrentLevel();
                for (var i:int = 0; i < m_equations.length; i++)
                {
                    // Do not check if the equation already has been modeled
                    var equationToModel:ExpressionComponent = m_equations[i];
                    if (!equationToModel.hasBeenModeled || !ignoreAlreadyModeled)
                    {
                        var goalRoot:ExpressionNode = equationToModel.root;
                        if (equationToModel.strictMatch)
                        {
                            // We force that the simplifying assumption that the left side of the goal equation
                            // is always just a definition variable
                            var equationsEqual:Boolean = ExpressionUtil.getExpressionsStructurallyEquivalent(
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
        
        private function replaceAliasValues(node:ExpressionNode):void
        {
            if (node != null)
            {
                if (m_aliasValueToTermMap.hasOwnProperty(node.data))
                {
                    node.data = m_aliasValueToTermMap[node.data];
                }
                replaceAliasValues(node.left);
                replaceAliasValues(node.right);
            }
        }
    }
}