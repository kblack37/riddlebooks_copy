package wordproblem.engine.expression.widget.term;


import dragonbox.common.math.vectorspace.RealsVectorSpace;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import wordproblem.display.PivotSprite;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.math.vectorspace.IVectorSpace;

import openfl.display.DisplayObject;
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
    public var groupImage : PivotSprite;
    
    public function new(node : ExpressionNode,
            vectorSpace : RealsVectorSpace,
            expressionSymbolMap : ExpressionSymbolMap,
            assetManager : AssetManager)
    {
        super(node, assetManager);
        
        this.mainGraphicBounds = new Rectangle(0, 0, 0, 0);
        
        if (node.isSpecificOperator(vectorSpace.getDivisionOperator())) 
        {
            // The division symbol needs to be able to scale horizontally if it is the bar
            var bitmapData : BitmapData = assetManager.getBitmapData("divide_bar");
            var centerX : Float = 10;
            var centerWidth : Float = bitmapData.width - 2 * centerX;
            this.groupImage = new PivotSprite();
			this.groupImage.addChild(new Bitmap(bitmapData));
			this.groupImage.scale9Grid = new Rectangle(centerX, 0, centerWidth, bitmapData.height);
        }
        else 
        {
            this.groupImage = try cast(expressionSymbolMap.getCardFromSymbolValue(node.data), PivotSprite) catch (e : Dynamic) null;
        }
        
        this.groupImage.pivotX = this.groupImage.width * 0.5;
        this.groupImage.pivotY = this.groupImage.height * 0.5;
        this.addChild(groupImage);
        
        this.mainGraphicBounds = this.groupImage.getBounds(this);
    }
}
