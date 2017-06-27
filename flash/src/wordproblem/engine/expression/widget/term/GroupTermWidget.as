package wordproblem.engine.expression.widget.term
{
    import flash.geom.Rectangle;
    
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.math.vectorspace.IVectorSpace;
    
    import feathers.display.Scale3Image;
    import feathers.textures.Scale3Textures;
    
    import starling.display.DisplayObject;
    import starling.textures.Texture;
    import wordproblem.resource.AssetManager
    
    import wordproblem.engine.expression.ExpressionSymbolMap;

    /**
     * A visual representation of a collection of widgets, this is usually either
     * an operator or the equals symbol 
     */
    public class GroupTermWidget extends BaseTermWidget
    {
        /**
         * The image of just the operator graphic, is independent of any display children
         */
        public var groupImage:DisplayObject;
        
        public function GroupTermWidget(node:ExpressionNode,
                                        vectorSpace:IVectorSpace,
                                        expressionSymbolMap:ExpressionSymbolMap,
                                        assetManager:AssetManager)
        {
            super(node, assetManager);
            
            var textureName:String;
            super.mainGraphicBounds = new Rectangle(0, 0, 0, 0);
            
            if (node.isSpecificOperator(vectorSpace.getDivisionOperator()))
            {
                // The division symbol needs to be able to scale horizontally if it is the bar
                var texture:Texture = assetManager.getTexture("divide_bar");
                const centerX:Number = 10;
                const centerWidth:Number = texture.width - 2 * centerX;
                this.groupImage = new Scale3Image(new Scale3Textures(texture, centerX, centerWidth));
            }
            else
            {
                this.groupImage = expressionSymbolMap.getCardFromSymbolValue(node.data);
            }

            this.groupImage.pivotX = this.groupImage.width * 0.5;
            this.groupImage.pivotY = this.groupImage.height * 0.5;
            this.addChild(groupImage);
            
            super.mainGraphicBounds = this.groupImage.getBounds(this);
        }
    }
}