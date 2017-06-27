package wordproblem.engine.widget
{
    import flash.geom.Rectangle;
    
    import dragonbox.common.dispose.IDisposable;
    import dragonbox.common.math.vectorspace.IVectorSpace;
    
    import feathers.display.Scale9Image;
    import feathers.textures.Scale9Textures;
    
    import starling.display.DisplayObject;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.textures.Texture;
    
    import wordproblem.engine.component.ExpressionComponent;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.expression.tree.ExpressionTree;
    import wordproblem.engine.expression.widget.ExpressionTreeWidget;
    import wordproblem.resource.AssetManager;
    
    /**
     * This class is simply a container sprite for an equation that is visible in the generic
     * substitution deck widget.
     * 
     * It shows the equation itself as well as some indication that it is selected.
     */
    public class ExpressionContainer extends Sprite implements IDisposable
    {
        private var m_isSelected:Boolean;
        
        private var m_maxWidth:Number;
        private var m_maxHeight:Number;
        
        private var m_unselectedUpImage:DisplayObject;
        private var m_unselectedOverImage:DisplayObject;
        private var m_selectedUpImage:DisplayObject;
        
        /**
         * Backing data representing the equation
         */
        private var m_expressionComponent:ExpressionComponent;
        
        /**
         * The view for the equation
         */
        private var m_expressionTreeWidget:ExpressionTreeWidget;
        
        private var m_vectorSpace:IVectorSpace;
        private var m_expressionResources:ExpressionSymbolMap;
        
        private var m_bgLayer:Sprite;
        
        public function ExpressionContainer(vectorSpace:IVectorSpace,
                                          assetManager:AssetManager,
                                          expressionSymbolResources:ExpressionSymbolMap,
                                          equation:ExpressionComponent, 
                                          maxWidth:Number, 
                                          maxHeight:Number, 
                                          backgroundImageUnselectedUp:String,
                                          backgroundImageSelectedUp:String,
                                          backgroundImageUnselectedOver:String)
        {
            super();
            
            m_vectorSpace = vectorSpace;
            m_expressionResources = expressionSymbolResources;
            
            // May need to scale background images
            m_maxWidth = maxWidth;
            m_maxHeight = maxHeight;
            
            // The settings of the background depend on whether there is an actual equation as
            // well as whether the background was selected
            m_unselectedUpImage = createBackgroundImage(backgroundImageUnselectedUp, assetManager);
            m_unselectedOverImage = createBackgroundImage(backgroundImageUnselectedOver, assetManager);
            m_selectedUpImage = createBackgroundImage(backgroundImageSelectedUp, assetManager);
            m_bgLayer = new Sprite();
            addChild(m_bgLayer);
            
            // Create a brand new copy of the view, note that it is possible to create
            // an empty tree, in which case the graphic should be replaced by some blank depression
            var expressionTreeWidget:ExpressionTreeWidget = new ExpressionTreeWidget(
                new ExpressionTree(vectorSpace, equation.root),
                expressionSymbolResources,
                assetManager,
                maxWidth, 
                maxHeight * 0.9
            );
            expressionTreeWidget.refreshNodes(true, true);
            expressionTreeWidget.buildTreeWidget();
            addChild(expressionTreeWidget);
            
            m_expressionTreeWidget = expressionTreeWidget;
            m_expressionComponent = equation;
            
            setSelected(false);
        }
        
        public function getExpressionWidget():ExpressionTreeWidget
        {
            return m_expressionTreeWidget;
        }
        
        public function getExpressionComponent():ExpressionComponent
        {
            return m_expressionComponent;
        }
        
        public function getIsSelected():Boolean
        {
            return m_isSelected;
        }
        
        public function setSelected(isSelected:Boolean):void
        {
            m_bgLayer.removeChildren();
            m_isSelected = isSelected;
            
            var selectedImage:DisplayObject = (isSelected) ? m_selectedUpImage : m_unselectedUpImage;
            
            selectedImage.width = m_maxWidth;
            selectedImage.height = m_maxHeight
            m_bgLayer.addChild(selectedImage);
        }
        
        public function setOver(isOver:Boolean):void
        {
            if (!m_isSelected)
            {
                m_bgLayer.removeChildren();
                
                var overImage:DisplayObject = (isOver) ? m_unselectedOverImage : m_unselectedUpImage;
                overImage.width = m_maxWidth;
                overImage.height = m_maxHeight;
                m_bgLayer.addChild(overImage);
            }
        }
        
        public function update():void
        {
            if (m_expressionComponent.dirty)
            {
                m_expressionTreeWidget.setTree(new ExpressionTree(m_vectorSpace, m_expressionComponent.root));
                m_expressionTreeWidget.refreshNodes(true, false);
                m_expressionTreeWidget.buildTreeWidget();
                m_expressionComponent.dirty = false;
                addChild(m_expressionTreeWidget);
            }
        }
        
        override public function dispose():void
        {
            while (numChildren > 0)
            {
                removeChildAt(0);
            }
            
            super.dispose();
        }
        
        private function createBackgroundImage(textureName:String, assetManager:AssetManager):DisplayObject
        {
            var backgroundImage:DisplayObject;
            if (textureName != null)
            {
                var texture:Texture = assetManager.getTexture(textureName);
                var bgPadding:Number = 15;
                var scale9Texture:Scale9Textures = new Scale9Textures(texture, new Rectangle(bgPadding, bgPadding, texture.width - 2 * bgPadding, texture.height - 2 * bgPadding));
                backgroundImage = new Scale9Image(scale9Texture);
            }
            else
            {
                backgroundImage = new Quad(50, 50, 0xFFFFFF);
            }
            
            return backgroundImage;
        }
    }
}