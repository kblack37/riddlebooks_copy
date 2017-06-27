package wordproblem.engine.widget
{
    import flash.geom.Rectangle;
    
    import dragonbox.common.dispose.IDisposable;
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import starling.display.Sprite;
    import starling.filters.ColorMatrixFilter;
    
    import wordproblem.engine.component.ExpressionComponent;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.resource.AssetManager;
    
    /**
     * This is the ui component that is used for the levels where the goal is simply
     * picking the corect expression or equation from some predefined list.
     * 
     * This widget is mainly just a container for equations or expressions
     */
    public class ExpressionPickerWidget extends Sprite implements IDisposable
    {
        private var m_totalWidth:Number;
        private var m_totalHeight:Number;

        /**
         * The limiting number of items that can be contained within a single column.
         * A value of zero or less indicates an unlimited number of items within
         * a columns, thus only a single one is used.
         */
        private var m_numItemsPerColumnLimit:int = -1;
        
        /**
         * The height of each individual option. We assume the options span the total width
         * of this component by default but the vertical length should be adjustable.
         */
        private var m_entryHeight:Number = 50;
        
        /**
         * This value is automatically calculated.
         */
        private var m_entryWidth:Number;
        
        private var m_expressionCompiler:IExpressionTreeCompiler;
        private var m_expressionSymbolResource:ExpressionSymbolMap;
        private var m_assetManager:AssetManager;
        
        /**
         * List of all possible expression containers
         */
        private var m_expressionContainers:Vector.<ExpressionContainer>;
        
        /**
         * List of expression containers that were selected
         */
        private var m_selectedExpressionContainersBuffer:Vector.<ExpressionContainer>;
        private var m_hitBoundsBuffer:Rectangle = new Rectangle();
        
        /**
         * The maximum number of items allowed to be selectable at any one time
         */
        public var maxAllowedSelected:int = 1;
        
        /**
         * Should mouse interactions be allowed on this widget, set to false if we are in the
         * middle of animating something in the picker.
         * 
         * For example when animating whether a picked option is correct, the player should not be
         * able to select a new option.
         */
        public var isActive:Boolean;
        
        public function ExpressionPickerWidget(expressionCompiler:IExpressionTreeCompiler, 
                                               expressionSymbolResource:ExpressionSymbolMap, 
                                               assetManager:AssetManager)
        {
            super();
            
            m_expressionCompiler = expressionCompiler;
            m_expressionSymbolResource = expressionSymbolResource;
            m_assetManager = assetManager;
            m_expressionContainers = new Vector.<ExpressionContainer>();
            m_selectedExpressionContainersBuffer = new Vector.<ExpressionContainer>();
            
            isActive = true;
        }
        
        override public function dispose():void
        {
            this.removeAllExpressions();
            
            super.dispose();
        }
        
        public function setDimensions(width:Number, height:Number):void
        {
            m_totalWidth = width;
            m_totalHeight = height;
        }
        
        public function setEntryHeight(height:Number):void
        {
            m_entryHeight = height;
        }
        
        public function setNumItemsPerColumnLimit(limit:Number=-1):void
        {
            m_numItemsPerColumnLimit = limit;
        }
        
        public function addExpressions(expressions:Vector.<String>):void
        {
            // Create a button entry for the new expression
            var i:int;
            var numTotalExpressions:int = expressions.length;
            var columnsRequired:Number = (m_numItemsPerColumnLimit > 0) ?
                Math.ceil(numTotalExpressions / m_numItemsPerColumnLimit) :
                1;
            var entryWidth:Number = m_totalWidth / columnsRequired;
            m_entryWidth = entryWidth;
            for (i = 0; i < numTotalExpressions; i++)
            {
                var expression:String = expressions[i];
                var root:ExpressionNode = m_expressionCompiler.compile(expression).head;
                
                // The width of each entry is determined by the number of columns we would need
                var expressionComponent:ExpressionComponent = new ExpressionComponent(null, expression, root);
                var expressionContainer:ExpressionContainer = new ExpressionContainer(
                    m_expressionCompiler.getVectorSpace(),
                    m_assetManager,
                    m_expressionSymbolResource,
                    expressionComponent,
                    entryWidth, 
                    m_entryHeight, 
                    "button_white",
                    "button_white",
                    "button_white"
                );
                m_expressionContainers.push(expressionContainer);
            }
            
            this.layout();
        }
        
        /**
         * Given a point in global coordinates, check if any one of the expression containers
         * contains that point
         * 
         * @return
         *      The expression container that hits the given point, null if nothing hit
         */
        public function pickExpressionContainerUnderPoint(globalX:Number, globalY:Number):ExpressionContainer
        {
            var expressionContainerUnderPoint:ExpressionContainer = null;
            var i:int;
            var expressionContainer:ExpressionContainer;
            var numExpressionContainers:int = m_expressionContainers.length;
            for (i = 0; i < numExpressionContainers; i++)
            {
                expressionContainer = m_expressionContainers[i];
                
                if (expressionContainer.stage != null)
                {
                    expressionContainer.getBounds(expressionContainer.stage, m_hitBoundsBuffer);
                    if (m_hitBoundsBuffer.contains(globalX, globalY))
                    {
                        expressionContainerUnderPoint = expressionContainer;
                        break;
                    }
                }
            }
            
            return expressionContainerUnderPoint;
        }
        
        public function removeAllExpressions():void
        {
            while (m_expressionContainers.length > 0)
            {
                var expressionContainer:ExpressionContainer = m_expressionContainers.pop();
                expressionContainer.dispose();
                expressionContainer.removeFromParent();
            }
            
            m_selectedExpressionContainersBuffer.length = 0;
        }
        
        public function getSelectedExpressionContainers(outContainers:Vector.<ExpressionContainer>):void
        {
            for each (var expressionContainer:ExpressionContainer in m_expressionContainers)
            {
                if (expressionContainer.getIsSelected())
                {
                    outContainers.push(expressionContainer);
                }
            }
        }
        
        /**
         * Helper function that looks through all unselected entries and applies a 
         * gray scale filter to them.
         * 
         * Used as part of an animation
         */
        public function setGrayScaleToUnselected():void
        {
            for each (var expressionContainer:ExpressionContainer in m_expressionContainers)
            {
                if (!expressionContainer.getIsSelected())
                {
                    var colorMatrixFilter:ColorMatrixFilter = new ColorMatrixFilter();
                    colorMatrixFilter.adjustSaturation(-1);
                    expressionContainer.filter = colorMatrixFilter;
                }
            }
        }
        
        /**
         * Helper function that restores the color of every container to its original state.
         * Used to remove the gray out effect.
         */
        public function resetColors():void
        {
            for each (var expressionContainer:ExpressionContainer in m_expressionContainers)
            {
                expressionContainer.filter = null;
            }
        }
        
        public function setExpressionContainerSelected(expressionContainer:ExpressionContainer, selected:Boolean):void
        {
            // Check to make the container is inside this widget
            var indexOfContainer:int = m_expressionContainers.indexOf(expressionContainer);
            if (indexOfContainer >= 0)
            {
                expressionContainer.setSelected(selected);
                
                if (selected)
                {
                    m_selectedExpressionContainersBuffer.push(expressionContainer);
                    
                    // If we exceeded the max selectable containers we need to deselect the last picked one
                    // This is automatically handled within the widget
                    if (m_selectedExpressionContainersBuffer.length > maxAllowedSelected)
                    {
                        var containerToRemove:ExpressionContainer = m_selectedExpressionContainersBuffer.shift();
                        containerToRemove.setSelected(false);
                    }
                }
                else
                {
                    var indexInSelected:int = m_selectedExpressionContainersBuffer.indexOf(expressionContainer);
                    m_selectedExpressionContainersBuffer.splice(indexInSelected, 1);
                }
            }
        }
        
        public function setExpressionContainerOver(expressionContainer:ExpressionContainer, over:Boolean):void
        {
            if (m_expressionContainers.indexOf(expressionContainer) >= 0)
            {
                expressionContainer.setOver(over);
            }
        }
        
        private function layout():void
        {
            // Center contents within the total width and height
            var i:int;
            var expressionContainer:ExpressionContainer;
            var numExpressionContainers:int = m_expressionContainers.length;
            var itemInColumnCounter:int = 0;
            var yOffset:Number = 0;
            var xOffset:Number = 0;
            
            var verticalSpacing:int = 5;
            var containerHeight:Number = 0;
            for (i = 0; i < numExpressionContainers; i++)
            {
                expressionContainer = m_expressionContainers[i];
                containerHeight = expressionContainer.height;
                
                expressionContainer.x = xOffset;
                expressionContainer.y = yOffset;
                
                itemInColumnCounter++;
                
                // Move to next column
                if (m_numItemsPerColumnLimit > 0 && itemInColumnCounter >= m_numItemsPerColumnLimit)
                {
                    xOffset += m_entryWidth;
                    yOffset = 0;
                    itemInColumnCounter = 0;
                }
                else
                {
                    yOffset += (verticalSpacing + containerHeight);
                }
            }
            
            var numColumns:int = 1;
            var totalContainerHeight:int = numExpressionContainers * m_entryHeight + verticalSpacing * (numExpressionContainers - 1);
            if (m_numItemsPerColumnLimit > 0)
            {
                numColumns = Math.ceil(numExpressionContainers / m_numItemsPerColumnLimit);
                totalContainerHeight = m_numItemsPerColumnLimit * m_entryHeight + verticalSpacing * (m_numItemsPerColumnLimit - 1);
            }
            
            yOffset = (m_totalHeight - totalContainerHeight) * 0.5;
            
            // Second pass assigns the y offset that vertically centers the containers
            for (i = 0; i < numExpressionContainers; i++)
            {
                expressionContainer = m_expressionContainers[i];
                expressionContainer.y += yOffset;
                
                addChild(expressionContainer)
            }
        }
    }
}