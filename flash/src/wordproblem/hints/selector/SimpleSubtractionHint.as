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
    
    public class SimpleSubtractionHint extends HintSelectorNode
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
        
        public function SimpleSubtractionHint(gameEngine:IGameEngine, 
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
            var hintMessage:String = null;
            if (HintCommonUtil.getLevelStillNeedsBarModelToSolve(m_gameEngine))
            {
                // If bar model, get the reference model to see where everything should be positioned
                var referenceModel:BarModelData = m_barModelValidation.getReferenceModels()[0];
                var smallerValue:String = null;
                var largerValue:String = null;
                var difference:String = null;
                for each (var barWhole:BarWhole in referenceModel.barWholes)
                {
                    if (barWhole.barComparison == null)
                    {
                        largerValue = barWhole.barLabels[0].value;
                    }
                    else
                    {
                        smallerValue = barWhole.barLabels[0].value;
                        difference = barWhole.barComparison.value;
                    }
                }
                
                var userBarWholes:Vector.<BarWhole> = m_barModelWidget.getBarModelData().barWholes;
                if (userBarWholes.length == 0)
                {
                    hintMessage = "Put the numbers on different lines, then show the difference!";
                }
                else if (userBarWholes.length == 1)
                {
                    // Figure out which value was used
                    var userBarWhole:BarWhole = userBarWholes[0];
                    var valueAdded:String = userBarWhole.barLabels[0].value;
                    if (valueAdded == difference)
                    {
                        hintMessage = "The value for the difference shouldn't be used that way!";
                    }
                    else
                    {
                        var otherValueNeeded:String = smallerValue;
                        if (valueAdded == smallerValue)
                        {
                            otherValueNeeded = largerValue;
                        }
                        
                        hintMessage = "You need to add '" + otherValueNeeded + "' on another line.";
                    }
                }
                else
                {
                    var addedComparison:Boolean = false;
                    var addedCorrectComparison:Boolean = false;
                    var valuesAddedAsBoxes:Vector.<String> = new Vector.<String>();
                    for each (userBarWhole in userBarWholes)
                    {
                        if (userBarWhole.barComparison != null)
                        {
                            addedComparison = true;
                            addedCorrectComparison = (userBarWhole.barComparison.value == difference);
                        }
                        
                        for each (var userLabel:BarLabel in userBarWhole.barLabels)
                        {
                            valuesAddedAsBoxes.push(userLabel.value);
                        }
                    }
                    
                    if (addedComparison && addedCorrectComparison)
                    {
                        hintMessage = "Press the green check button!";
                    }
                    else if (addedComparison && !addedCorrectComparison)
                    {
                        hintMessage = "Wrong part used as difference, try a different one!";
                    }
                    else
                    {
                        if (valuesAddedAsBoxes.indexOf(difference) >= 0)
                        {
                            hintMessage = "The difference shouldn't be a box!";
                        }
                        else
                        {
                            hintMessage = "Almost there, just add the difference now!";
                        }
                    }
                }
            }
            else
            {
                hintMessage = "Make sure you have the smaller number subtracted from the larger one!";
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