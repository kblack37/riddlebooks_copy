package wordproblem.hints;

import wordproblem.hints.HintScript;

import starling.display.DisplayObject;
import starling.display.Sprite;
import starling.text.TextField;
import starling.utils.VAlign;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.barmodel.view.BarModelView;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.widget.BarModelAreaWidget;
import wordproblem.resource.AssetManager;

/**
 * This hint will display the answer that is expected for the bar model portion.
 * 
 * This is a final hint if the player is really struggling, problems should not
 * be marked as correct if they use this.
 */
class DrawBarModelAnswerHint extends HintScript
{
    private static inline var WARNING_TEXT : String = "Can't figure out the right picture? Press show to see the answer. Warning: You won't get credit for solving this problem if you use this hint.";
    
    private var m_gameEngine : IGameEngine;
    
    private var m_descriptionBarModel : BarModelView;
    
    /**
     * This is the bar model structure that we want to have built.
     */
    private var m_referenceBarModel : BarModelData;
    
    /**
     * Want to warn the player before giving this hint. If they still want to see it
     * we need to make sure some message is sent saying this problem should be marked as wrong
     */
    private var m_activated : Bool;
    
    public function new(gameEngine : IGameEngine,
            assetManager : AssetManager,
            referenceBarModel : BarModelData,
            id : String = null,
            isActive : Bool = true)
    {
        super(false, id, isActive);
        
        m_gameEngine = gameEngine;
        m_referenceBarModel = referenceBarModel.clone();
        
        // This is the reference bar model used when drawing in the description.
        // Need to manually adjust some of the properties (namely color so the reference model appears correct in different contexts)
        var descriptionReferenceModel : BarModelData = referenceBarModel.clone();
        modifyPropertiesOfBarModel(descriptionReferenceModel);
        
        var padding : Float = 0;
        m_descriptionBarModel = new BarModelView(100, 50, 
                padding, padding, padding, padding, 
                10, descriptionReferenceModel, gameEngine.getExpressionSymbolResources(), assetManager);
        
        //m_unlocked = true;
        m_activated = false;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_descriptionBarModel.removeFromParent(true);
    }
    
    override public function show() : Void
    {
        // Get the answer reference model
        var barModelArea : BarModelAreaWidget = try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        barModelArea.setBarModelData(m_referenceBarModel.clone());
        barModelArea.redraw();
        
        // They first time they hit show we should send a signal the 'give up' hint was used
        if (!m_activated) 
        {
            m_activated = true;
            
            // Set the used cheat flag
            m_gameEngine.getCurrentLevel().statistics.usedBarModelCheatHint = true;
        }
    }
    
    override public function hide() : Void
    {
    }
    
    override public function isUsefulForCurrentState() : Bool
    {
        return HintCommonUtil.getLevelStillNeedsBarModelToSolve(m_gameEngine);
    }
    
    override public function getDescription(width : Float, height : Float) : DisplayObject
    {
        // We have two types of description, one is a warning telling them to try first and saying
        // the problem is incorrect if they use this hint
        var descriptionContainer : Sprite = new Sprite();
        if (!m_activated) 
        {
            var textField : TextField = new TextField(width, height, WARNING_TEXT, GameFonts.DEFAULT_FONT_NAME, 22);
            textField.vAlign = VAlign.TOP;
            descriptionContainer.addChild(textField);
        }
        else 
        {
            textField = new TextField(width, 50, "This is the answer.", GameFonts.DEFAULT_FONT_NAME, 22);
            descriptionContainer.addChild(textField);
            
            // In some cases the answer bar model shown in the description is far too scrunched together
            // we want it to span as much of the description area as possible
            // We calculate the proportional value of the 'longest' bar whole.
            // We want that proportion to span the width of this description
            var largestProportionalValue : Float = 0;
            for (barWhole/* AS3HX WARNING could not determine type for var: barWhole exp: EField(EIdent(m_referenceBarModel),barWholes) type: null */ in m_referenceBarModel.barWholes)
            {
                var barWholeValue : Float = barWhole.getValue();
                if (barWholeValue > largestProportionalValue) 
                {
                    largestProportionalValue = barWholeValue;
                }
            }
            m_descriptionBarModel.unitLength = width / largestProportionalValue;
            
            m_descriptionBarModel.y = textField.height;
            m_descriptionBarModel.setDimensions(width, height - 50);
            m_descriptionBarModel.redraw(false);
            descriptionContainer.addChild(m_descriptionBarModel);
        }
        
        return descriptionContainer;
    }
    
    override public function disposeDescription(description : DisplayObject) : Void
    {
        m_descriptionBarModel.removeFromParent();
    }
    
    private function modifyPropertiesOfBarModel(barModelData : BarModelData) : Void
    {
        var barWholes : Array<BarWhole> = barModelData.barWholes;
        var i : Int = 0;
        for (i in 0...barWholes.length){
            var barWhole : BarWhole = barWholes[i];
            var barLabels : Array<BarLabel> = barWhole.barLabels;
            var j : Int = 0;
            for (j in 0...barLabels.length){
                var barLabel : BarLabel = barLabels[j];
                barLabel.color = 0x000000;
            }
            
            if (barWhole.barComparison != null) 
            {
                barWhole.barComparison.color = 0x000000;
            }
        }
        
        var verticalLabels : Array<BarLabel> = barModelData.verticalBarLabels;
        for (i in 0...verticalLabels.length){
            barLabel = verticalLabels[i];
            barLabel.color = 0x000000;
        }
    }
}
