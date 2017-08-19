package wordproblem.hints;


import starling.display.DisplayObject;
import starling.display.Quad;
import starling.display.Sprite;
import starling.textures.Texture;

import wordproblem.characters.HelperCharacterController;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.BarModelTypeDrawer;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.view.BarModelView;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.expression.SymbolData;
import wordproblem.engine.level.CardAttributes;
import wordproblem.engine.text.TextParser;
import wordproblem.engine.text.TextViewFactory;
import wordproblem.resource.AssetManager;

/**
 * This type of hint shows the bar model picture template that the player is attempting to draw.
 * The templates that are shown are not the exact answers, showing the exact expected answer
 * is yet another hint and requires looking at a specific reference model.
 * 
 * The drawn parts here are more of a categorization
 * 
 * (Show the helper character with a mini version of the drawn bar model in a thought bubble)
 */
class DrawBarModelTypeHint extends BasicTextAndCharacterHint
{
    /**
     * The bar model type to draw a template for
     * 
     * (Found in list of constants BarModelTypes
     */
    private var m_barModelType : String;
    
    /**
     * The sample bar model view to show in the description box
     */
    private var m_descriptionBarModelView : BarModelView;
    
    /**
     * The bar model to attach to the callout the helper character tries to show
     */
    private var m_calloutBarModelView : BarModelView;
    
    /**
     * Rendering map for special drawing
     */
    private var m_expressionSymbolMap : ExpressionSymbolMap;
    
    private var m_barModelTypeDrawer : BarModelTypeDrawer;
    
    public function new(gameEngine : IGameEngine,
            assetManager : AssetManager,
            characterController : HelperCharacterController,
            textParser : TextParser,
            textViewFactory : TextViewFactory,
            barModelType : String,
            id : String = null,
            isActive : Bool = true)
    {
        var descriptionText : FastXML = FastXML.parse("<p>You will need to draw the boxes so they look similar to this...</p>");
        var characterText : FastXML = FastXML.parse("<p>It looks like this!</p>");
        super(gameEngine, assetManager, characterController, textParser, textViewFactory, descriptionText, characterText, null, null, false, id, isActive);
        
        m_barModelType = barModelType;
        m_barModelTypeDrawer = new BarModelTypeDrawer();
        
        // Create a separate expression map (TODO: Set default card attributes)
        m_expressionSymbolMap = new ExpressionSymbolMap(assetManager);
        m_expressionSymbolMap.setConfiguration(CardAttributes.DEFAULT_CARD_ATTRIBUTES);
        var unknownData : SymbolData = m_expressionSymbolMap.getSymbolDataFromValue("?");
        unknownData.backgroundColor = 0xFFFFFF;
        
        var padding : Float = 0;
        m_descriptionBarModelView = new BarModelView(100, 50, 
                padding, padding, padding, padding, 
                10, new BarModelData(), m_expressionSymbolMap, assetManager);
        
        // Based on the type create a drawn copy of the bar model
        m_barModelTypeDrawer.drawBarModelIntoViewFromType(m_barModelType, m_descriptionBarModelView);
    }
    
    override public function show() : Void
    {
        // Have the helper character fly around to a spot
        characterId = "Taco";
        super.show();
    }
    
    override public function getDescription(width : Float, height : Float) : DisplayObject
    {
        // Redraw the type of bar
        m_descriptionBarModelView.setDimensions(width, height - 60);
        m_descriptionBarModelView.redraw(false);
        
        var descriptionContainer : Sprite = new Sprite();
        
        // The super draws the original content
        descriptionContainer.addChild(super.getDescription(width, height));
        
        m_descriptionBarModelView.y = height * 0.35;
        descriptionContainer.addChild(m_descriptionBarModelView);
        return descriptionContainer;
    }
    
    override public function disposeDescription(description : DisplayObject) : Void
    {
        if (m_descriptionBarModelView.parent != null) m_descriptionBarModelView.parent.removeChild(m_descriptionBarModelView);
        description.removeFromParent(true);
    }
    
    override public function isUsefulForCurrentState() : Bool
    {
        return HintCommonUtil.getLevelStillNeedsBarModelToSolve(m_gameEngine);
    }
    
    override private function showHints() : DisplayObject
    {
        // Add callout to the character (the thought bubble used as the default background
        // only has a small rectangular segment where we can properly fit the model
        var calloutBackground : Texture = m_assetManager.getTexture("thought_bubble");
        var calloutWidth : Float = calloutBackground.width;
        var calloutHeight : Float = calloutBackground.height;
        var calloutVerticalPadding : Float = 20;
        var calloutHorizontalPadding : Float = 20;
        
        var padding : Float = 0;
        var barModelView : BarModelView = new BarModelView(100, 25, 
        padding, padding, padding, padding, 
        10, new BarModelData(), m_expressionSymbolMap, m_assetManager);
        barModelView.setDimensions(calloutWidth - 2 * calloutHorizontalPadding,
                calloutHeight - 2 * calloutVerticalPadding);
        m_barModelTypeDrawer.drawBarModelIntoViewFromType(m_barModelType, barModelView);
        barModelView.redraw(false);
        
        // The callout automatically ties to set the content to the specified width and height
        // This causes ugly scaling which we don't want.
        // To prevent this we create an empty quad fill the gap
        var dummyContainer : Sprite = new Sprite();
        var gapToFixSize : Quad = new Quad(calloutWidth, calloutHeight, 0);
        gapToFixSize.alpha = 0.0001;
        dummyContainer.addChild(gapToFixSize);
        
        barModelView.x = (calloutWidth - barModelView.width) * 0.5;
        barModelView.y = (calloutHeight - barModelView.height) * 0.5;
        dummyContainer.addChild(barModelView);
        return dummyContainer;
    }
}
