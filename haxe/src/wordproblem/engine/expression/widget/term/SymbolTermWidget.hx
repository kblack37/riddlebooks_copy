package wordproblem.engine.expression.widget.term;

import cgs.audio.Audio;

import dragonbox.common.expressiontree.ExpressionNode;

import haxe.Constraints.Function;

import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.textures.Texture;

import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.resource.AssetManager;
import wordproblem.resource.Resources;

/**
 * A visual representation of a leaf symbol, which is a variable or literal value.
 */
class SymbolTermWidget extends BaseTermWidget
{
    private var m_regularImage : DisplayObject;
    private var m_negativeImage : DisplayObject;
    
    /**
     * Special graphic to be shown instead of the normal one if a widget is supposed to be hidden
     */
    private var m_hiddenGraphic : DisplayObject;
    
    public function new(node : ExpressionNode,
            nodeResourceMap : ExpressionSymbolMap,
            assetManager : AssetManager)
    {
        super(node, assetManager);
        
        var symbol : String = node.data;
        var symbolIsNegative : Bool = (symbol != null && symbol.charAt(0) == node.vectorSpace.getSubtractionOperator());
        if (symbolIsNegative) 
        {
            m_negativeImage = nodeResourceMap.getCardFromSymbolValue(symbol);
            m_regularImage = nodeResourceMap.getCardFromSymbolValue(symbol.substr(1));
        }
        else 
        {
            m_negativeImage = nodeResourceMap.getCardFromSymbolValue(node.vectorSpace.getSubtractionOperator() + symbol);
            m_regularImage = nodeResourceMap.getCardFromSymbolValue(symbol);
        }
        
        var intialImageToUse : DisplayObject = ((symbolIsNegative)) ? 
        m_negativeImage : m_regularImage;
        addChild(intialImageToUse);
    }
    
    override public function setIsHidden(hidden : Bool) : Void
    {
        super.setIsHidden(hidden);
        
        // Show the blank version of the card if we need to keep the symbol hidden
        if (hidden) 
        {
            if (m_hiddenGraphic == null) 
            {
                var hiddenGraphicTexture : Texture = m_assetManager.getTexture(Resources.CARD_BLANK);
                m_hiddenGraphic = new Image(hiddenGraphicTexture);
                m_hiddenGraphic.x -= m_hiddenGraphic.width / 2;
                m_hiddenGraphic.y -= m_hiddenGraphic.height / 2;
            }
            
            addChild(m_hiddenGraphic);
            
            if (m_regularImage.parent != null) 
            {
                m_regularImage.parent.removeChild(m_regularImage);
            }
            
            if (m_negativeImage.parent != null) 
            {
                m_negativeImage.parent.removeChild(m_negativeImage);
            }
        }
        // Remove the hidden graphic if it has been placed
        else if (m_hiddenGraphic != null && m_hiddenGraphic.parent != null) 
        {
            m_hiddenGraphic.parent.removeChild(m_hiddenGraphic);
            if (this.m_node.isNegative()) 
            {
                addChild(m_negativeImage);
            }
            else 
            {
                addChild(m_regularImage);
            }
        }
    }
    
    private var m_reverseOnComplete : Function;
    
    /**
     * Reverse the sign of the term. This modifies the contents of the backing expression node.
     */
    public function reverseValue(onComplete : Function) : Void
    {
        Audio.instance.playSfx("card_flip");
        m_reverseOnComplete = onComplete;
        
        var collapseTween : Tween = new Tween(this, 0.3);
        collapseTween.animate("scaleX", 0);
        collapseTween.onComplete = onCollapseComplete;
        Starling.current.juggler.add(collapseTween);
    }
    
    private function onCollapseComplete() : Void
    {
        if (m_node.data.charAt(0) == m_node.vectorSpace.getSubtractionOperator()) 
        {
            // Flip to positive
            m_node.data = m_node.data.substr(1);
            removeChild(m_negativeImage);
            addChildAt(m_regularImage, 0);
        }
        else 
        {
            // Flip to negavtive
            m_node.data = m_node.vectorSpace.getSubtractionOperator() + m_node.data;
            removeChild(m_regularImage);
            addChildAt(m_negativeImage, 0);
        }
        var expandTween : Tween = new Tween(this, 0.3);
        expandTween.animate("scaleX", 1);
        expandTween.onComplete = function onExpandComplete() : Void
                {
                    if (m_reverseOnComplete != null) 
                    {
                        m_reverseOnComplete();
                    }
                };
        Starling.current.juggler.add(expandTween);
    }
}
