package wordproblem.hints.selector
{
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.ExpressionUtil;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import wordproblem.characters.HelperCharacterController;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.BarModelTypes;
    import wordproblem.engine.component.Component;
    import wordproblem.engine.component.ExpressionComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.text.TextParser;
    import wordproblem.engine.text.TextViewFactory;
    import wordproblem.engine.widget.DeckWidget;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.hints.HintCommonUtil;
    import wordproblem.hints.HintScript;
    import wordproblem.hints.HintSelectorNode;
    import wordproblem.hints.scripts.TipsViewer;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.model.ModelSpecificEquation;

    /**
     * These hints are intended to show up when the player presses the hint button
     * during the equation modeling portion of a problem and displays help information
     * related to mistakes in the user's equation model.
     */
    public class ExpressionModelHintSelector extends HintSelectorNode
    {
        private var m_gameEngine:IGameEngine;
        private var m_assetManager:AssetManager;
        private var m_expressionCompiler:IExpressionTreeCompiler;
        private var m_characterController:HelperCharacterController;
        private var m_textParser:TextParser;
        private var m_textViewFactory:TextViewFactory;
        
        /**
         * Mapping from document id to an expression/term value
         * Relies on fact that document ids in a level can be directly mapped to elements in a
         * template of a bar model type. For example the doc id 'b1' refers to the number of
         * groups in any type 3a model.
         */
        private var m_documentIdToExpressionMap:Object;
        
        /**
         * Need this to check whether the equation the player currently has entered in a correct equation
         * already. We don't want to give misleading information once a valid answer has been constructed.
         */
        private var m_modelSpecificEquation:ModelSpecificEquation;
        private var m_characterStopX:Number;
        private var m_characterStopY:Number;
        
        /**
         * Counter when the user triggers a hint for a two step problem and the term areas are empty and one
         * equation has already been created.
         */
        private var m_twoStepOneEquationCounter:int;
        
        /**
         * Counter when the user triggers a hint for a two step problem and the term areas are empty and no
         * previous equation is created.
         */
        private var m_twoStepNoEquationCounter:int;
        
        /**
         * If the user has not placed anything and requested a hint, we want to show something generic to try and encourage
         * them to do something so we can get a better idea of what they are confused about.
         * 
         * Once this counter reaches a certain threshold we may want to stop showing these types of hints
         */
        private var m_genericHintShownCounter:int;
        
        /*
        Some hints we want to show the replay of the gesture. For a problem, we determine if a gesture is necessary to
        make the equation and see if the user has ever made an equation with an element from that gesture.
        If the counter is at zero, we assume the user has never performed the gesture and a good hint might be to
        show the replay.
        */
        private var m_numEquationsWithMultiply:int;
        private var m_numEquationsWithDivide:int;
        private var m_numEquationsWithSubtract:int;
        private var m_unknownMissingCounter:int;
        private var m_importantNumberMissingCounter:int;
        
        // Count of the stage we are at for a fraction model when we do not have anymore general hints
        private var m_fractionBarCounter:int;
        private var m_createNewNumberCounter:int;
        
        public function ExpressionModelHintSelector(gameEngine:IGameEngine,
                                                    assetManager:AssetManager,
                                                    characterController:HelperCharacterController,
                                                    expressionCompiler:IExpressionTreeCompiler,
                                                    modelSpecificEquation:ModelSpecificEquation, 
                                                    characterStopX:Number, characterStopY:Number)
        {
            super();
        
            m_gameEngine = gameEngine;
            m_assetManager = assetManager;
            m_characterController = characterController;
            m_expressionCompiler = expressionCompiler;
            m_modelSpecificEquation = modelSpecificEquation;
            
            m_characterStopX = characterStopX;
            m_characterStopY = characterStopY;
            
            m_textParser = new TextParser();
            m_textViewFactory = new TextViewFactory(assetManager, m_gameEngine.getExpressionSymbolResources());
            
            m_twoStepOneEquationCounter = 0;
            m_twoStepNoEquationCounter = 0;
            
            m_genericHintShownCounter = 0;
            
            m_numEquationsWithMultiply = 0;
            m_numEquationsWithDivide = 0;
            m_numEquationsWithSubtract = 0;
            m_unknownMissingCounter = 0;
            m_importantNumberMissingCounter = 0;
            m_createNewNumberCounter = 0;
            m_gameEngine.addEventListener(GameEvent.EQUATION_CHANGED, onEquationChanged);
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_gameEngine.removeEventListener(GameEvent.EQUATION_CHANGED, onEquationChanged);
        }
        
        override public function getHint():HintScript
        {
            if (m_documentIdToExpressionMap == null)
            {
                m_documentIdToExpressionMap = (m_gameEngine.getUiEntitiesByClass(TextAreaWidget)[0] as TextAreaWidget).getDocumentIdToExpressionMap();
            }
            
            var hintData:Object = null;
            var userExpressionRoot:ExpressionNode = m_gameEngine.getExpressionFromTermAreas();
            var matchingExpression:ExpressionComponent = m_modelSpecificEquation.checkEquationIsCorrect(userExpressionRoot, m_expressionCompiler.getVectorSpace(), true);
            if (matchingExpression == null)
            {
                /*
                Expression modeling that occurs after the bar modeling will have a different flow
                */
                
                // If the level is tagged with a bar model type then we have at least a basic understanding of what
                // the expression representing the bar model looks like.
                // Can provide hints indicating differences between what the user has constructed and the template
                // based on the bar model type.
                var barModelType:String = m_gameEngine.getCurrentLevel().getBarModelType();
                if (barModelType != null)
                {
                    // If the term areas are empty and the user requests a hint for the first time then we
                    // want to show a generic hint
                    if (userExpressionRoot == null || userExpressionRoot.isLeaf())
                    {
                        if (m_genericHintShownCounter < 3)
                        {
                            m_genericHintShownCounter++;
                            
                            var genericHintDescriptors:Vector.<String> = Vector.<String>([
                                "Think about how the boxes and names make up parts of the equation.",
                                "Show what the unknown part equals to as an equation.",
                                "The boxes and names tell you the answer! Just make the equation from it.",
                                "What operations and parts do you need? The boxes and names above show it."
                            ]);
                            
                            hintData = {
                                descriptionContent: genericHintDescriptors[Math.floor(Math.random() * genericHintDescriptors.length)]
                            };
                        }
                    }
                        // The unknown value MUST be present
                    else
                    {
                        hintData = checkExpressionValueMissing(m_documentIdToExpressionMap['unk'], userExpressionRoot);
                    }
                    
                    if (hintData == null)
                    {
                        if (barModelType == BarModelTypes.TYPE_1A || barModelType == BarModelTypes.TYPE_2B)
                        {
                            hintData = generateTotalEqualsSumHint(m_documentIdToExpressionMap['unk'], userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_2E)
                        {
                            hintData = generateTotalEqualsSumHint(m_documentIdToExpressionMap['b1'], userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_1B || barModelType == BarModelTypes.TYPE_2A)
                        {
                            hintData = generateTotalEqualsDifferenceHint("b", "a", m_documentIdToExpressionMap['unk'], userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_2C)
                        {
                            hintData = generateTotalEqualsDifferenceHint("b", "unk", m_documentIdToExpressionMap['a1'], userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_2D)
                        {
                            hintData = generateTotalEqualsDifferenceHint("unk", "a", m_documentIdToExpressionMap['b1'], userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_3A)
                        {
                            hintData = generateMultiplyDivideHint(
                                parseInt(m_documentIdToExpressionMap['b1']), m_documentIdToExpressionMap['unk'], m_documentIdToExpressionMap['a1'],
                                null, null, userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_3B)
                        {
                            hintData = generateMultiplyDivideHint(
                                parseInt(m_documentIdToExpressionMap['a1']), m_documentIdToExpressionMap['b1'], m_documentIdToExpressionMap['unk'],
                                null, null, userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_4A)
                        {
                            hintData = generateMultiplyDivideHint(
                                parseInt(m_documentIdToExpressionMap['b1']), 
                                m_documentIdToExpressionMap['unk'], 
                                m_documentIdToExpressionMap['a1'],
                                null, null, userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_4B)
                        {
                            hintData = generateMultiplyDivideHint(
                                parseInt(m_documentIdToExpressionMap['b1']), 
                                m_documentIdToExpressionMap['a1'], 
                                m_documentIdToExpressionMap['unk'],
                                null, null, userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_4C)
                        {
                            hintData = generateMultiplyDivideHint(
                                parseInt(m_documentIdToExpressionMap['b1']), 
                                null, 
                                m_documentIdToExpressionMap['a1'],
                                null, m_documentIdToExpressionMap['unk'], userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_4D)
                        {
                            hintData = generateMultiplyDivideHint(
                                parseInt(m_documentIdToExpressionMap['b1']), 
                                null, 
                                m_documentIdToExpressionMap['a1'],
                                m_documentIdToExpressionMap['unk'], null, userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_4E)
                        {
                            hintData = generateMultiplyDivideHint(
                                parseInt(m_documentIdToExpressionMap['b1']), 
                                null, 
                                m_documentIdToExpressionMap['unk'],
                                null, m_documentIdToExpressionMap['a1'], userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_4F)
                        {
                            hintData = generateMultiplyDivideHint(
                                parseInt(m_documentIdToExpressionMap['b1']), 
                                null, 
                                m_documentIdToExpressionMap['unk'],
                                m_documentIdToExpressionMap['a1'], null, userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_5A)
                        {
                            hintData = generateTwoStepNoGroupsHint(
                                m_documentIdToExpressionMap['a1'],
                                m_documentIdToExpressionMap['c'],
                                m_documentIdToExpressionMap['b1'],
                                m_documentIdToExpressionMap['unk'],
                                userExpressionRoot
                            );
                        }
                        else if (barModelType == BarModelTypes.TYPE_5B)
                        {
                            hintData = generateTwoStepNoGroupsHint(
                                m_documentIdToExpressionMap['c'],
                                m_documentIdToExpressionMap['a1'],
                                m_documentIdToExpressionMap['b1'],
                                m_documentIdToExpressionMap['unk'],
                                userExpressionRoot
                            );
                        }
                        else if (barModelType == BarModelTypes.TYPE_5C)
                        {
                            hintData = generateTwoStepNoGroupsHint(
                                m_documentIdToExpressionMap['a1'],
                                m_documentIdToExpressionMap['c'],
                                m_documentIdToExpressionMap['unk'],
                                m_documentIdToExpressionMap['b1'],
                                userExpressionRoot
                            );
                        }
                        else if (barModelType == BarModelTypes.TYPE_5D)
                        {
                            hintData = generateTwoStepNoGroupsHint(
                                m_documentIdToExpressionMap['c'],
                                m_documentIdToExpressionMap['unk'],
                                m_documentIdToExpressionMap['a1'],
                                m_documentIdToExpressionMap['b1'],
                                userExpressionRoot
                            );
                        }
                        else if (barModelType == BarModelTypes.TYPE_5E)
                        {
                            hintData = generateTwoStepNoGroupsHint(
                                m_documentIdToExpressionMap['unk'],
                                m_documentIdToExpressionMap['c'],
                                m_documentIdToExpressionMap['a1'],
                                m_documentIdToExpressionMap['b1'],
                                userExpressionRoot
                            );
                        }
                        else if (barModelType == BarModelTypes.TYPE_5F)
                        {
                            hintData = generateTwoStepGroupsHint(
                                parseInt(m_documentIdToExpressionMap['b1']),
                                m_documentIdToExpressionMap['c'],
                                m_documentIdToExpressionMap['a1'],
                                null,
                                m_documentIdToExpressionMap['unk'],
                                userExpressionRoot
                            );
                        }
                        else if (barModelType == BarModelTypes.TYPE_5G)
                        {
                            hintData = generateTwoStepGroupsHint(
                                parseInt(m_documentIdToExpressionMap['b1']),
                                m_documentIdToExpressionMap['c'],
                                m_documentIdToExpressionMap['a1'],
                                m_documentIdToExpressionMap['unk'],
                                null,
                                userExpressionRoot
                            );
                        }
                        else if (barModelType == BarModelTypes.TYPE_5H)
                        {
                            hintData = generateTwoStepGroupsHint(
                                parseInt(m_documentIdToExpressionMap['b1']),
                                m_documentIdToExpressionMap['c'],
                                m_documentIdToExpressionMap['unk'],
                                null,
                                m_documentIdToExpressionMap['a1'],
                                userExpressionRoot
                            );
                        }
                        else if (barModelType == BarModelTypes.TYPE_5I)
                        {
                            hintData = generateTwoStepGroupsHint(
                                parseInt(m_documentIdToExpressionMap['b1']),
                                m_documentIdToExpressionMap['c'],
                                null,
                                m_documentIdToExpressionMap['unk'],
                                m_documentIdToExpressionMap['a1'],
                                userExpressionRoot
                            );
                        }
                        else if (barModelType == BarModelTypes.TYPE_5J)
                        {
                            hintData = generateTwoStepGroupsHint(
                                parseInt(m_documentIdToExpressionMap['b1']),
                                m_documentIdToExpressionMap['c'],
                                m_documentIdToExpressionMap['unk'],
                                m_documentIdToExpressionMap['a1'],
                                null,
                                userExpressionRoot
                            );
                        }
                        else if (barModelType == BarModelTypes.TYPE_5K)
                        {
                            hintData = generateTwoStepGroupsHint(
                                parseInt(m_documentIdToExpressionMap['b1']),
                                m_documentIdToExpressionMap['c'],
                                null,
                                m_documentIdToExpressionMap['a1'],
                                m_documentIdToExpressionMap['unk'],
                                userExpressionRoot
                            );
                        }
                        else if (barModelType == BarModelTypes.TYPE_6A)
                        {
                            hintData = generateFractionHint(
                                m_documentIdToExpressionMap['unk'],
                                parseInt(m_documentIdToExpressionMap['a1']),
                                m_documentIdToExpressionMap['b1'],
                                parseInt(m_documentIdToExpressionMap['a2']),
                                Vector.<int>([parseInt(m_documentIdToExpressionMap['a2']) - parseInt(m_documentIdToExpressionMap['a1'])]),
                                userExpressionRoot);
                            
                        }
                        else if (barModelType == BarModelTypes.TYPE_6B)
                        {
                            hintData = generateFractionHint(
                                m_documentIdToExpressionMap['unk'],
                                parseInt(m_documentIdToExpressionMap['a2']) - parseInt(m_documentIdToExpressionMap['a1']),
                                m_documentIdToExpressionMap['b1'],
                                parseInt(m_documentIdToExpressionMap['a2']),
                                Vector.<int>([parseInt(m_documentIdToExpressionMap['a2']) - parseInt(m_documentIdToExpressionMap['a1'])]),
                                userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_6C)
                        {
                            hintData = generateFractionHint(
                                m_documentIdToExpressionMap['unk'],
                                parseInt(m_documentIdToExpressionMap['a2']),
                                m_documentIdToExpressionMap['b1'],
                                parseInt(m_documentIdToExpressionMap['a1']), 
                                null,
                                userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_6D)
                        {
                            hintData = generateFractionHint(
                                m_documentIdToExpressionMap['unk'],
                                parseInt(m_documentIdToExpressionMap['a2']) - parseInt(m_documentIdToExpressionMap['a1']),
                                m_documentIdToExpressionMap['b1'],
                                parseInt(m_documentIdToExpressionMap['a1']), 
                                Vector.<int>([parseInt(m_documentIdToExpressionMap['a2']) - parseInt(m_documentIdToExpressionMap['a1'])]),
                                userExpressionRoot);
                        }
                            // For type 7, the 'a2' tag in the document is the denominator of the fraction
                        else if (barModelType == BarModelTypes.TYPE_7A)
                        {
                            hintData = generateFractionHint(
                                m_documentIdToExpressionMap['unk'],
                                parseInt(m_documentIdToExpressionMap['a2']),
                                m_documentIdToExpressionMap['b1'],
                                parseInt(m_documentIdToExpressionMap['a1']), 
                                null,
                                userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_7B)
                        {
                            hintData = generateFractionHint(
                                m_documentIdToExpressionMap['unk'],
                                parseInt(m_documentIdToExpressionMap['a2']) + parseInt(m_documentIdToExpressionMap['a1']),
                                m_documentIdToExpressionMap['b1'],
                                parseInt(m_documentIdToExpressionMap['a1']), 
                                Vector.<int>([parseInt(m_documentIdToExpressionMap['a2']) + parseInt(m_documentIdToExpressionMap['a1'])]),
                                userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_7C)
                        {
                            hintData = generateFractionHint(
                                m_documentIdToExpressionMap['unk'],
                                parseInt(m_documentIdToExpressionMap['a2']) - parseInt(m_documentIdToExpressionMap['a1']),
                                m_documentIdToExpressionMap['b1'],
                                parseInt(m_documentIdToExpressionMap['a1']), 
                                Vector.<int>([parseInt(m_documentIdToExpressionMap['a2']) - parseInt(m_documentIdToExpressionMap['a1'])]),
                                userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_7D_1)
                        {
                            hintData = generateFractionHint(
                                m_documentIdToExpressionMap['unk'],
                                parseInt(m_documentIdToExpressionMap['a2']),
                                m_documentIdToExpressionMap['b1'],
                                parseInt(m_documentIdToExpressionMap['a1']) + parseInt(m_documentIdToExpressionMap['a1']), 
                                Vector.<int>([parseInt(m_documentIdToExpressionMap['a1']) + parseInt(m_documentIdToExpressionMap['a2'])]),
                                userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_7D_2)
                        {
                            hintData = generateFractionHint(
                                m_documentIdToExpressionMap['unk'],
                                parseInt(m_documentIdToExpressionMap['a1']),
                                m_documentIdToExpressionMap['b1'],
                                parseInt(m_documentIdToExpressionMap['a1']) + parseInt(m_documentIdToExpressionMap['a2']), 
                                Vector.<int>([parseInt(m_documentIdToExpressionMap['a1']) + parseInt(m_documentIdToExpressionMap['a2'])]),
                                userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_7E)
                        {
                            hintData = generateFractionHint(
                                m_documentIdToExpressionMap['unk'],
                                parseInt(m_documentIdToExpressionMap['a2']) - parseInt(m_documentIdToExpressionMap['a1']),
                                m_documentIdToExpressionMap['b1'],
                                parseInt(m_documentIdToExpressionMap['a1']) + parseInt(m_documentIdToExpressionMap['a2']), 
                                Vector.<int>([parseInt(m_documentIdToExpressionMap['a2']) - parseInt(m_documentIdToExpressionMap['a1']),
                                    parseInt(m_documentIdToExpressionMap['a2']) + parseInt(m_documentIdToExpressionMap['a1'])]),
                                userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_7F_1)
                        {
                            hintData = generateFractionHint(
                                m_documentIdToExpressionMap['unk'],
                                parseInt(m_documentIdToExpressionMap['a2']),
                                m_documentIdToExpressionMap['b1'],
                                parseInt(m_documentIdToExpressionMap['a2']) - parseInt(m_documentIdToExpressionMap['a1']), 
                                Vector.<int>([parseInt(m_documentIdToExpressionMap['a2']) - parseInt(m_documentIdToExpressionMap['a1']),
                                    parseInt(m_documentIdToExpressionMap['a2']) + parseInt(m_documentIdToExpressionMap['a1'])]),
                                userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_7F_2)
                        {
                            hintData = generateFractionHint(
                                m_documentIdToExpressionMap['unk'],
                                parseInt(m_documentIdToExpressionMap['a1']),
                                m_documentIdToExpressionMap['b1'],
                                parseInt(m_documentIdToExpressionMap['a2']) - parseInt(m_documentIdToExpressionMap['a1']), 
                                Vector.<int>([parseInt(m_documentIdToExpressionMap['a2']) - parseInt(m_documentIdToExpressionMap['a1']),
                                    parseInt(m_documentIdToExpressionMap['a2']) + parseInt(m_documentIdToExpressionMap['a1'])]),
                                userExpressionRoot);
                        }
                        else if (barModelType == BarModelTypes.TYPE_7G)
                        {
                            hintData = generateFractionHint(
                                m_documentIdToExpressionMap['unk'],
                                parseInt(m_documentIdToExpressionMap['a2']) + parseInt(m_documentIdToExpressionMap['a1']),
                                m_documentIdToExpressionMap['b1'],
                                parseInt(m_documentIdToExpressionMap['a2']) - parseInt(m_documentIdToExpressionMap['a1']), 
                                Vector.<int>([parseInt(m_documentIdToExpressionMap['a2']) - parseInt(m_documentIdToExpressionMap['a1']),
                                    parseInt(m_documentIdToExpressionMap['a2']) + parseInt(m_documentIdToExpressionMap['a1'])]),
                                userExpressionRoot);
                        }
                    }
                }
                // Expression modeling without the bar model
                else
                {
                    // We need to enforce the requirement that the reference equation must provide useful structural information.
                    // This category is useful if the user has not ever tried using one of those operators
                    // (These are high level generic hints)

                    // First bundle of hints point out if the user is missing at least one key term in their model.
                    // For most levels these are just the numbers or the unknown (which is the only non-number in the text)
                    var textArea:TextAreaWidget = m_gameEngine.getUiEntitiesByClass(TextAreaWidget)[0] as TextAreaWidget;
                    var expressionsInText:Vector.<Component> = textArea.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
                    var unknownName:String = null;
                    for each (var expressionComponent:ExpressionComponent in expressionsInText)
                    {
                        hintData = checkExpressionValueMissing(expressionComponent.expressionString, userExpressionRoot);
                        
                        // A missing unknown takes precedent over missing number
                        if (isNaN(parseInt(expressionComponent.expressionString)) && hintData != null)
                        {
                            break;
                        }
                    }
                    
                    // Next hints attempt to check if an operator is missing
                    if (hintData == null)
                    {
                        var operatorTypes:Vector.<String> = Vector.<String>(["+", "-", "*", "/"]);
                        var operatorHintContent:Vector.<String> = new Vector.<String>();
                        operatorHintContent.push("You may need to add some parts together.");
                        operatorHintContent.push("You may need to subtract some parts.");
                        operatorHintContent.push("You may need to multiply some parts.");
                        operatorHintContent.push("You may need to divide a part by some number.");
                        
                        // The target equation can be navigated to see what sort of operators need to be used.
                        // Each operator can have a hint associated with it.
                        // Compare what the operators are between the user model and the reference model
                        var referenceEquationRoot:ExpressionNode = m_expressionCompiler.compile(m_modelSpecificEquation.getEquations()[0].expressionString).head;
                        for (var i:int = 0; i < operatorTypes.length; i++)
                        {
                            var targetOperator:String = operatorTypes[i];
                            if (expressionContainsValue(referenceEquationRoot, targetOperator) && 
                                !expressionContainsValue(userExpressionRoot, targetOperator))
                            {
                                hintData = {
                                    descriptionContent: operatorHintContent[i]  
                                };
                                break;
                            }
                        }
                    }
                    
                    // Next hints attempt to check if a term is used with the correct operator
                    // We use the simplifying assumption that the parent operator is what we want to match
                    if (hintData == null)
                    {
                        // For each term in the reference, find the operator
                        var referenceEquationLeaves:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
                        ExpressionUtil.getLeafNodes(referenceEquationRoot, referenceEquationLeaves);
                        
                        var userEquationLeaves:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
                        ExpressionUtil.getLeafNodes(userExpressionRoot, userEquationLeaves);
                        for each (var referenceLeaf:ExpressionNode in referenceEquationLeaves)
                        {
                            if (referenceLeaf.parent != null)
                            {
                                var parentOperatorName:String = referenceLeaf.parent.data;
                                var matchedReferenceLeafWithUser:Boolean = false;
                                for each (var userLeaf:ExpressionNode in userEquationLeaves)
                                {
                                    if (referenceLeaf.data == userLeaf.data && userLeaf.parent != null && userLeaf.parent.data == parentOperatorName)
                                    {
                                        matchedReferenceLeafWithUser = true;
                                        break;
                                    }
                                }
                                
                                // If a pair of a term and operator is found in the reference model but not in the user constructed one
                                // then we show a prompt that a particular value should be used a certain way 
                                if (!matchedReferenceLeafWithUser)
                                {
                                    if (parentOperatorName == "+")
                                    {
                                        hintData = {
                                            descriptionContent: "Try adding with " + referenceLeaf.data
                                        };
                                    }
                                    else if (parentOperatorName == "-")
                                    {
                                        hintData = {
                                            descriptionContent: "Try using " + referenceLeaf.data + " in a subtraction."  
                                        };
                                    }
                                    else if (parentOperatorName == "*")
                                    {
                                        hintData = {
                                            descriptionContent: "Trying multiplying with " + referenceLeaf.data  
                                        };
                                    }
                                    else if (parentOperatorName == "/")
                                    {
                                        hintData = {
                                            descriptionContent: "Try using " + referenceLeaf.data + " in division."  
                                        };
                                    }
                                    
                                    if (hintData != null)
                                    {
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // If user has constructed a valid expression, then ask them if they want to submit an answer.
            else
            {
                hintData = {
                    descriptionContent: "Press the 'equals' if you think you have the right answer!"
                };
            }
            
            // Make sure the hint is never null, pick out very general hints if we get here.
            if (hintData == null)
            {
                hintData = {
                    descriptionContent: "Are you sure you have everything in the right order?"
                };
            }
            
            return HintCommonUtil.createHintFromMismatchData(hintData, 
                m_characterController, m_assetManager,
                m_gameEngine.getMouseState(), 
                m_textParser, m_textViewFactory, m_gameEngine.getUiEntity("textArea") as TextAreaWidget, m_gameEngine,
                m_characterStopX, m_characterStopY
            );
        }
        
        /**
         * Generate generic hint if an important value is missing entirely from the user created expression.
         * If the value we are searching for is a variable, generate a different kind of hint
         * 
         * @expressionValue
         *      If this is not a number then we assume the value being looked for is the unknown
         */
        private function checkExpressionValueMissing(expressionValue:String, userExpressionRoot:ExpressionNode):Object
        {
            var hintData:Object = null;
            
            if (!expressionContainsValue(userExpressionRoot, expressionValue))
            {
                var isUnknown:Boolean = isNaN(parseFloat(expressionValue));
                var valueMissingHints:Vector.<String> = new Vector.<String>();
                if (isUnknown)
                {
                    // Tell user the unknown is missing, this is the one term we know is absolutely necessary
                    m_unknownMissingCounter++;
                    if (m_unknownMissingCounter > 2)
                    {
                        valueMissingHints.push(
                            "'" + expressionValue + "' needs to be in the answer.",
                            "You need to add '" + expressionValue + "' somewhere."
                        );
                    }
                    else
                    {
                        valueMissingHints.push(
                            "You need to put the unknown value in your answer!",
                            "An important value is missing."
                        );
                    }
                }
                else
                {
                    m_importantNumberMissingCounter++;
                    if (m_importantNumberMissingCounter > 3)
                    {
                        valueMissingHints.push(
                            "'" + expressionValue + "' may need to be put somewhere."  
                        );
                    }
                    else
                    {
                        valueMissingHints.push(
                            "An important part is missing in your answer!",
                            "Do you have all the numbers you need?",
                            "What numbers are you missing"
                        );
                    }
                }
                
                hintData = {
                    descriptionContent: valueMissingHints[Math.floor(Math.random() * valueMissingHints.length)]
                };
            }
            
            return hintData;
        }
        
        private function onEquationChanged():void
        {
            var currentEquation:ExpressionNode = m_gameEngine.getExpressionFromTermAreas();
            if (expressionContainsValue(currentEquation, m_expressionCompiler.getVectorSpace().getSubtractionOperator()))
            {
                m_numEquationsWithSubtract++;
            }
            
            if (expressionContainsValue(currentEquation, m_expressionCompiler.getVectorSpace().getMultiplicationOperator()))
            {
                m_numEquationsWithMultiply++;
            }
            
            if (expressionContainsValue(currentEquation, m_expressionCompiler.getVectorSpace().getDivisionOperator()))
            {
                m_numEquationsWithDivide++;
            }
        }
        
        private function expressionContainsValue(node:ExpressionNode, value:String):Boolean
        {
            var containsValue:Boolean = false;
            if (node != null)
            {
                containsValue = node.data == value;
                if (!containsValue)
                {
                    containsValue = expressionContainsValue(node.left, value) || expressionContainsValue(node.right, value);
                }
            }
            
            return containsValue;
        }
        
        /**
         * Create hints related to an expression where multiple parts add together to create a total
         */
        private function generateTotalEqualsSumHint(totalValue:String, userExpression:ExpressionNode):Object
        {
            var hintData:Object = null;
            
            // Check if the current expression has the sum parts
            // 'You are missing one of the parts being added.'
            
            var partsInSumValues:Vector.<String> = new Vector.<String>();
            for (var documentId:String in m_documentIdToExpressionMap)
            {
                var expressionValue:String = m_documentIdToExpressionMap[documentId];
                if (expressionValue != totalValue)
                {
                    partsInSumValues.push(expressionValue);
                }
            }
            
            for each (var partInSum:String in partsInSumValues)
            {
                if (!expressionContainsValue(userExpression, partInSum))
                {
                    hintData = {
                        descriptionContent: "The answer has several parts added together, what are they?" 
                    };
                    break;
                }
            }
            
            // Check if the current expression has the total
            // 'You are missing the total'
            if (hintData != null && !expressionContainsValue(userExpression, totalValue))
            {
                hintData = {
                    descriptionContent: "You are missing the total"  
                };
            }
            
            return hintData;
        }
        
        /**
         * Create hints related to an expression where two parts are subtracted from one another.
         * The parts being subtracted may be composed of several parts
         */
        private function generateTotalEqualsDifferenceHint(largerPartPrefix:String, 
                                                           smallerPartPrefix:String, 
                                                           difference:String, 
                                                           userExpression:ExpressionNode):Object
        {
            var hintData:Object = null;
            
            // Search for subtraction in the user expression
            var aSubtractionNode:ExpressionNode = getFirstNodeInstanceMatchingOperator(userExpression, m_expressionCompiler.getVectorSpace().getSubtractionOperator());
            if (aSubtractionNode != null)
            {
                // If subtraction is present, do a quick check of whether all the parts that need to subtracted
                // are present. (Are the bigger and smaller parts all present as children of the subtract?)
                var expectedExpressionsInDifference:Vector.<String> = new Vector.<String>();
                for (var docId:String in m_documentIdToExpressionMap)
                {
                    if (docId.indexOf(largerPartPrefix) == 0 || docId.indexOf(smallerPartPrefix) == 0)
                    {
                        expectedExpressionsInDifference.push(m_documentIdToExpressionMap[docId]);
                    }
                }
                
                var childrenOfSubtraction:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
                var expectedExpressionMissing:Boolean = false;
                ExpressionUtil.getLeafNodes(aSubtractionNode, childrenOfSubtraction);
                for each (var expectedExpression:String in expectedExpressionsInDifference)
                {
                    for each (var child:ExpressionNode in childrenOfSubtraction)
                    {
                        if (child.data == expectedExpression)
                        {
                            expectedExpressionMissing = true;
                            break;
                        }
                    }
                    
                    if (expectedExpressionMissing)
                    {
                        hintData = {
                            descriptionContent: "Do you have the right parts being subtracted from each other?"  
                        };
                        break;
                    }
                }
            }
            else
            {
                hintData = {
                    descriptionContent: "Can you find what parts need to be subtracted?"  
                };
            }
            
            if (m_numEquationsWithSubtract == 0)
            {
                hintData = {
                    descriptionContent: "You may want to use subtraction.", 
                    linkToTip: TipsViewer.CYCLE_OPERATOR
                };
            }
            
            return hintData;
        }
        
        private function getFirstNodeInstanceMatchingOperator(node:ExpressionNode, operator:String):ExpressionNode
        {
            var matchingNode:ExpressionNode = null;
            if (node != null && node.isOperator())
            {
                if (node.isSpecificOperator(operator))
                {
                    matchingNode = node;
                }
                else
                {
                    matchingNode = getFirstNodeInstanceMatchingOperator(node.left, operator);
                    if (matchingNode != null)
                    {
                        matchingNode = getFirstNodeInstanceMatchingOperator(node.right, operator);
                    }
                }
            }
            
            return matchingNode;
        }
        
        /**
         *
         * @param sumOfGroups
         * @param totalOfEverything
         */
        private function generateMultiplyDivideHint(numGroups:int, 
                                                    sumOfGroups:String, 
                                                    multipliedValue:String, 
                                                    totalOfEverything:String, 
                                                    difference:String, 
                                                    userExpression:ExpressionNode):Object
        {
            var hintData:Object = null;
            
            /*
            May want to somehow differentiate between multiply and divide.
            */
            
            // Check if the user is using a multiplier for the number of groups appropriately.
            // The num groups multiplier
            if (m_numEquationsWithMultiply == 0)
            {
                hintData = {
                    descriptionContent: "You may want to use multiplication in your answer."  
                };
            }
            
            var multiplicationNode:ExpressionNode = getFirstNodeInstanceMatchingOperator(userExpression, m_expressionCompiler.getVectorSpace().getMultiplicationOperator());
            if (multiplicationNode != null)
            {
                if (!expressionContainsValue(multiplicationNode, multipliedValue) || expressionContainsValue(multiplicationNode, numGroups + ""))
                {
                    hintData = {
                        descriptionContent: "One of the parts being multiplied is missing."  
                    };
                }
            }
            else
            {
                hintData = {
                    descriptionContent: "How much is one group and many groups does the unknown show?"  
                };
            }
            
            // If the bar model includes a total for everything, we must now look for a sum.
            if (hintData == null && totalOfEverything != null && !expressionContainsValue(userExpression, m_expressionCompiler.getVectorSpace().getSubtractionOperator()))
            {
                hintData = {
                    descriptionContent: "This problem has parts being added."  
                };
            }
            
            if (hintData == null && difference != null && !expressionContainsValue(userExpression, m_expressionCompiler.getVectorSpace().getAdditionOperator()))
            {
                hintData = {
                    descriptionContent: "The problem has parts being subtracted."
                };
            }
            
            return hintData;
        }
        
        /**
         * Two step problems are solvable with a system of equations.
         */
        private function generateTwoStepNoGroupsHint(largerPart:String, 
                                                     smallerPart:String, 
                                                     difference:String, 
                                                     total:String, 
                                                     userExpression:ExpressionNode):Object
        {
            var hintData:Object = null;
            
            hintData = getGeneralTwoStepHint(userExpression);
            
            // Create an equation just representing the difference (ignore the total)
            
            // Create an equation representing the total (ignore the difference)
            
            return hintData;
        }
        
        /**
         *
         * @param sumOfGroups
         *      null if this total is not present
         * @param totalOfEverything
         *      null if this total is not present
         * @param difference
         *      null if this total is not present
         */
        private function generateTwoStepGroupsHint(numGroups:int,
                                                   intermediateValue:String,
                                                   sumOfGroups:String, 
                                                   totalOfEverything:String,
                                                   difference:String,
                                                   userExpression:ExpressionNode):Object
        {
            var hintData:Object = null;
            
            hintData = getGeneralTwoStepHint(userExpression);
            
            // Create an equation talking about finding the sum of one of the objects (ignore the total)
            
            // Create an equation talking about finding the sum of everything
            
            return hintData;
        }
        
        /**
         * Get hints that are general for any two step problem
         */
        private function getGeneralTwoStepHint(userExpression:ExpressionNode):Object
        {
            var hintData:Object = null;
            
            // Check if the user has already solved on part of a system
            // Assuming this system is at most a pair so if just one other equation is marked
            // as modeled, then there is only other one left
            var equationHasBeenModeled:Boolean = false;
            var equationsToModel:Vector.<ExpressionComponent> = m_modelSpecificEquation.getEquations();
            for each (var equationToModel:ExpressionComponent in equationsToModel)
            {
                if (equationToModel.hasBeenModeled)
                {
                    equationHasBeenModeled = true;
                    break;
                }
            }
            
            // An important hint for these types of problems involves pointing out you can solve the problem
            // with a system of equations. 
            // The best way to to show this is when the user hasn't done very many actions or the
            // expression area is empty
            if (userExpression == null || userExpression.isLeaf())
            {
                var hintContent:String = null;
                if (equationHasBeenModeled)
                {
                    // If there is one equation that was already modeled, then we want to encourage the user
                    // to model the other equation.
                    m_twoStepOneEquationCounter++;
                    if (m_twoStepOneEquationCounter == 1)
                    {
                        hintContent = "You have one part right, what is the other equation that will complete the answer?";
                    }
                    else
                    {
                        hintContent = "Is there a value in the problem that is missing in the first equation? You may need use it.";
                    }
                    
                    hintData = {
                        descriptionContent: hintContent
                    };
                }
                else
                {
                    m_twoStepNoEquationCounter++;
                    if (m_twoStepNoEquationCounter == 1)
                    {
                        hintContent = "It may be easier to make two smaller equations than one big one.";
                    }
                    else
                    {
                        hintContent = (Math.random() > 0.5) ? "Each equation only needs to show a part of the answer." :
                            "Together, two simpler equation are the same as the answer you need.";
                    }
                    
                    hintData = {
                        descriptionContent: hintContent
                    };
                }
            }
            
            return hintData;
        }
        
        /**
         * The equation template for fraction types is to figure out how much a group is through division and
         * then multiply by the number of groups indicated by the unknown.
         * 
         */
        private function generateFractionHint(unknownName:String, 
                                              unknownGroups:int, 
                                              knownName:String, 
                                              knownGroups:int,
                                              missingNumbers:Vector.<int>,
                                              userExpression:ExpressionNode):Object
        {
            var hintData:Object = null;
            
            // An important hint for these types of problems is the fact you may have to create a brand new
            // number to solve the problem.
            
            // If either the number of unknown or known groupings does not exist, the user may need to
            // create a new term for that missing number (this is always the total minus the shaded part
            // of the fraction)
            if (missingNumbers != null && m_createNewNumberCounter < 1)
            {
                m_createNewNumberCounter++;
                
                // Show the missing number hint only a limited number of times (perhaps even once is enough)
                var createdMissingNumbers:Boolean = false;
                var deckArea:DeckWidget = m_gameEngine.getUiEntitiesByClass(DeckWidget)[0] as DeckWidget;
                var expressionsInDeck:Vector.<Component> = deckArea.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
                for each (var missingNumber:int in missingNumbers)
                {
                    var numberFound:Boolean = false;
                    for each (var expressionComponent:ExpressionComponent in expressionsInDeck)
                    {
                        if (parseInt(expressionComponent.expressionString) == missingNumber)
                        {
                            numberFound = true;
                            break;
                        }
                    }
                    
                    if (!numberFound)
                    {
                        createdMissingNumbers = false;
                        break;
                    }
                }
                
                // The missing number that is useful is either the total number of groups
                // or the difference between the
                if (!createdMissingNumbers)
                {
                    hintData = {
                        descriptionContent: "You can make a new number if you need it."  
                    };
                }
            }
            
            // How many times bigger is the unknown than one of the groups?
            // Create a sequence of hints
            // (Seems like this is a good approach, heavily rely on using the bar model template as a guide
            // to creating the equation)
            if (hintData == null)
            {
                m_fractionBarCounter++;
                
                var hintText:String = null;
                if (m_fractionBarCounter == 1)
                {
                    hintText = "How many boxes does each important name take up?";
                }
                else if (m_fractionBarCounter == 2)
                {
                    hintText = "How much is one of the boxes?";
                }
                else
                {
                    hintText = "If you know how much is one box and how many boxes the unknown takes, you have the answer?";
                }

                hintData = {
                    descriptionContent: hintText
                };
            }
            
            return hintData;
        }
    }
}