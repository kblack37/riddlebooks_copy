package wordproblem.hints.selector
{
    import wordproblem.characters.HelperCharacterController;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.text.TextParser;
    import wordproblem.engine.text.TextViewFactory;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.hints.HintCommonUtil;
    import wordproblem.hints.HintScript;
    import wordproblem.hints.HintSelectorNode;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.barmodel.ValidateBarModelArea;
    import wordproblem.scripts.model.ModelSpecificEquation;
    
    /**
     * Mostly used by tutorials, gives help for problems related to basic addition type problems.
     * These problem require a model showing two values added together with a total.
     * These types of problem can be solved using two rows with a vertical bracket or one
     * row with a horizontal bracket.
     */
    public class SimpleAdditionHint extends HintSelectorNode
    {
        private var m_gameEngine:IGameEngine;
        private var m_assetManager:AssetManager;
        private var m_textParser:TextParser;
        private var m_textViewFactory:TextViewFactory;
        private var m_helperCharacterController:HelperCharacterController;
        
        private var m_textAreaWidget:TextAreaWidget;
        private var m_barModelWidget:BarModelAreaWidget;
        private var m_barModelValidation:ValidateBarModelArea;
        private var m_equationValidation:ModelSpecificEquation;
        
        public function SimpleAdditionHint(gameEngine:IGameEngine, 
                                           assetManager:AssetManager, 
                                           textParser:TextParser, 
                                           textViewFactory:TextViewFactory, 
                                           helperCharacterController:HelperCharacterController, 
                                           barModelValidation:ValidateBarModelArea, 
                                           equationValidation:ModelSpecificEquation)
        {
            super();
            
            m_gameEngine = gameEngine;
            m_assetManager = assetManager;
            m_textParser = textParser;
            m_textViewFactory = textViewFactory;
            m_helperCharacterController = helperCharacterController;
            
            m_textAreaWidget = m_gameEngine.getUiEntitiesByClass(TextAreaWidget)[0] as TextAreaWidget;
            m_barModelWidget = m_gameEngine.getUiEntitiesByClass(BarModelAreaWidget)[0] as BarModelAreaWidget;
            m_barModelValidation = barModelValidation;
            m_equationValidation = equationValidation;
        }
        
        override public function getHint():HintScript
        {
            var hintScript:HintScript = null;
            
            // Need to figure the state of the level at the moment this is clicked
            // Should we give a hint for the 
            if (HintCommonUtil.getLevelStillNeedsBarModelToSolve(m_gameEngine))
            {
                // If bar model, get the reference model to see where everything should be positioned
                // TODO: Assumes reference model has everything on one row
                var referenceModel:BarModelData = m_barModelValidation.getReferenceModels()[0];
                var boxesToAdd:Vector.<String> = new Vector.<String>();
                var total:String = null;
                var barWhole:BarWhole = referenceModel.barWholes[0];
                for each (var barLabel:BarLabel in barWhole.barLabels)
                {
                    if (barLabel.bracketStyle == BarLabel.BRACKET_NONE)
                    {
                        boxesToAdd.push(barLabel.value);
                    }
                    else
                    {
                        total = barLabel.value;
                    }
                }
                
                // Get current state of the bar model area
                var userBoxesAdded:Vector.<String> = new Vector.<String>();
                var userTotal:String = null;
                var userBarWholes:Vector.<BarWhole> = m_barModelWidget.getBarModelData().barWholes;
                if (userBarWholes.length > 0)
                {
                    for each (barWhole in userBarWholes)
                    {
                        for each (barLabel in barWhole.barLabels)
                        {
                            if (barLabel.bracketStyle == BarLabel.BRACKET_NONE)
                            {
                                userBoxesAdded.push(barLabel.value);
                            }
                            else
                            {
                                userTotal = barLabel.value;
                            }
                        }
                    }
                    
                    for each (var verticalLabel:BarLabel in m_barModelWidget.getBarModelData().verticalBarLabels)
                    {
                        userTotal = barLabel.value;
                    }
                }
                
                // If empty tell them to add boxes
                var hintMessage:String = null;
                if (userBoxesAdded.length == 0)
                {
                    hintMessage = "Add " + boxesToAdd.length + " boxes together.";
                }
                else
                {
                    // Now check that the box values are the same
                    // See if something is missing in the user model
                    for each (var expected:String in boxesToAdd)
                    {
                        var expectedFound:Boolean = false;
                        for each (var given:String in userBoxesAdded)
                        {
                            if (expected == given)
                            {
                                expectedFound = true
                                break;
                            }
                        }
                        
                        // Missing an expected value as a box, tell them they need to add it
                        if (!expectedFound)
                        {
                            var missingValue:String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(expected).abbreviatedName;
                            hintMessage = "'" + missingValue + "' needs to be added as a box.";
                        }
                    }
                    
                    // See if an extra value is present
                    for each (given in userBoxesAdded)
                    {
                        var givenFound:Boolean = false;
                        for each (expected in boxesToAdd)
                        {
                            if (given == expected)
                            {
                                givenFound = true;
                                break;
                            }
                        }
                        
                        if (!givenFound)
                        {
                            var extraValue:String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(given).abbreviatedName;
                            hintMessage = "'" + extraValue + "' should not be a box.";
                        }
                    }
                    
                    // If boxes are the same, make sure the total is the same
                    if (hintMessage == null)
                    {
                        if (userTotal == null)
                        {
                            // First, prompt to add the total
                            hintMessage = "Where should you add the total?";
                            
                            // Second, show the video of how to add the label
                            
                            // Third, highlight the text
                        }
                        else if (userTotal != total)
                        {
                            var actualTotalName:String = m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(total).abbreviatedName;
                            hintMessage = "'" + actualTotalName + "' should be the total name.";
                        }
                    }
                }
                
                if (hintMessage == null)
                {
                    hintMessage = "Press the green check!";
                }
            }
            else if (m_equationValidation != null)
            {
                // Get what the user has created and determine whether that represents a valid addition
                hintMessage = "Make sure the numbers in the boxes are added together.";
            }
            
            if (hintMessage != null)
            {
                var hintData:Object = {descriptionContent: hintMessage};
                hintScript = HintCommonUtil.createHintFromMismatchData(
                    hintData, 
                    m_helperCharacterController, 
                    m_assetManager, 
                    m_gameEngine.getMouseState(),
                    m_textParser, m_textViewFactory, m_textAreaWidget, m_gameEngine,
                    200, 300
                );
            }
            return hintScript;
        }
    }
}