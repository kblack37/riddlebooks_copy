package wordproblem.engine.expression.widget.term;


import dragonbox.common.expressiontree.WildCardNode;
import openfl.display.Bitmap;
import wordproblem.display.PivotSprite;

import wordproblem.resource.AssetManager;

import wordproblem.engine.expression.ExpressionSymbolMap;

/**
 * Visual representation of wild card data types. They symbolize blank spaces that take on
 * concrete values later on.
 * 
 * Some example usages include being used as the placeholder spaces when players are discovering
 * terms or the spaces when the player has caused in imbalance during the solving portions of
 * the game.
 */
class WildCardTermWidget extends BaseTermWidget
{
    public function new(node : WildCardNode,
            expressionResources : ExpressionSymbolMap,
            assetManager : AssetManager,
            visible : Bool = true)
    {
        super(node, assetManager);
        
        // TODO: Early on we want wild cards to represent blank placeholders
        // We don't want to lock them into any particular data value.
        // For now printing out a question mark card
        var wildCardImage : PivotSprite = new PivotSprite();
		wildCardImage.addChild(new Bitmap(assetManager.getBitmapData("wildcard")));
        wildCardImage.pivotX += wildCardImage.width * 0.5;
        wildCardImage.pivotY += wildCardImage.height * 0.5;
        addChild(wildCardImage);
        
        if (!visible) 
        {
            wildCardImage.alpha = 0.0001;
        }
    }
}
