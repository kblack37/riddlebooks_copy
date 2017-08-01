package wordproblem.engine.expression.widget.term;


import dragonbox.common.math.vectorspace.RealsVectorSpace;
import flash.geom.Rectangle;
import starling.display.Image;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.math.vectorspace.IVectorSpace;

//import feathers.display.Scale3Image;
//import feathers.textures.Scale3Textures;

import starling.display.DisplayObject;
import starling.textures.Texture;
import wordproblem.resource.AssetManager;

import wordproblem.engine.expression.ExpressionSymbolMap;

/**
 * A visual representation of a collection of widgets, this is usually either
 * an operator or the equals symbol 
 */
class GroupTermWidget extends BaseTermWidget
{
    /**
     * The image of just the operator graphic, is independent of any display children
     */
    public var groupImage : DisplayObject;
    
    public function new(node : ExpressionNode,
            vectorSpace : RealsVectorSpace,
            expressionSymbolMap : ExpressionSymbolMap,
            assetManager : AssetManager)
    {
        super(node, assetManager);
        
        var textureName : String = null;
        this.mainGraphicBounds = new Rectangle(0, 0, 0, 0);
        
        if (node.isSpecificOperator(vectorSpace.getDivisionOperator())) 
        {
            // The division symbol needs to be able to scale horizontally if it is the bar
            var texture : Texture = assetManager.getTexture("divide_bar");
            var centerX : Float = 10;
            var centerWidth : Float = texture.width - 2 * centerX;
			// TODO: this was converted from a Scale3Texture from the feathers library
			// and will probably need to be fixed
            this.groupImage = new Image(Texture.fromTexture(texture, new Rectangle(centerX, 0, centerWidth, texture.height)));
        }
        else 
        {
            this.groupImage = expressionSymbolMap.getCardFromSymbolValue(node.data);
        }
        
        this.groupImage.pivotX = this.groupImage.width * 0.5;
        this.groupImage.pivotY = this.groupImage.height * 0.5;
        this.addChild(groupImage);
        
        this.mainGraphicBounds = this.groupImage.getBounds(this);
    }
}
