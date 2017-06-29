package wordproblem.engine.widget;


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
class ExpressionPickerWidget extends Sprite implements IDisposable
{
    private var m_totalWidth : Float;
    private var m_totalHeight : Float;
    
    /**
     * The limiting number of items that can be contained within a single column.
     * A value of zero or less indicates an unlimited number of items within
     * a columns, thus only a single one is used.
     */
    private var m_numItemsPerColumnLimit : Int = -1;
    
    /**
     * The height of each individual option. We assume the options span the total width
     * of this component by default but the vertical length should be adjustable.
     */
    private var m_entryHeight : Float = 50;
    
    /**
     * This value is automatically calculated.
     */
    private var m_entryWidth : Float;
    
    private var m_expressionCompiler : IExpressionTreeCompiler;
    private var m_expressionSymbolResource : ExpressionSymbolMap;
    private var m_assetManager : AssetManager;
    
    /**
     * List of all possible expression containers
     */
    private var m_expressionContainers : Array<ExpressionContainer>;
    
    /**
     * List of expression containers that were selected
     */
    private var m_selectedExpressionContainersBuffer : Array<ExpressionContainer>;
    private var m_hitBoundsBuffer : Rectangle = new Rectangle();
    
    /**
     * The maximum number of items allowed to be selectable at any one time
     */
    public var maxAllowedSelected : Int = 1;
    
    /**
     * Should mouse interactions be allowed on this widget, set to false if we are in the
     * middle of animating something in the picker.
     * 
     * For example when animating whether a picked option is correct, the player should not be
     * able to select a new option.
     */
    public var isActive : Bool;
    
    public function new(expressionCompiler : IExpressionTreeCompiler,
            expressionSymbolResource : ExpressionSymbolMap,
            assetManager : AssetManager)
    {
        super();
        
        m_expressionCompiler = expressionCompiler;
        m_expressionSymbolResource = expressionSymbolResource;
        m_assetManager = assetManager;
        m_expressionContainers = new Array<ExpressionContainer>();
        m_selectedExpressionContainersBuffer = new Array<ExpressionContainer>();
        
        isActive = true;
    }
    
    override public function dispose() : Void
    {
        this.removeAllExpressions();
        
        super.dispose();
    }
    
    public function setDimensions(width : Float, height : Float) : Void
    {
        m_totalWidth = width;
        m_totalHeight = height;
    }
    
    public function setEntryHeight(height : Float) : Void
    {
        m_entryHeight = height;
    }
    
    public function setNumItemsPerColumnLimit(limit : Float = -1) : Void
    {
        m_numItemsPerColumnLimit = limit;
    }
    
    public function addExpressions(expressions : Array<String>) : Void
    {
        // Create a button entry for the new expression
        var i : Int;
        var numTotalExpressions : Int = expressions.length;
        var columnsRequired : Float = ((m_numItemsPerColumnLimit > 0)) ? 
        Math.ceil(numTotalExpressions / m_numItemsPerColumnLimit) : 
        1;
        var entryWidth : Float = m_totalWidth / columnsRequired;
        m_entryWidth = entryWidth;
        for (i in 0...numTotalExpressions){
            var expression : String = expressions[i];
            var root : ExpressionNode = m_expressionCompiler.compile(expression).head;
            
            // The width of each entry is determined by the number of columns we would need
            var expressionComponent : ExpressionComponent = new ExpressionComponent(null, expression, root);
            var expressionContainer : ExpressionContainer = new ExpressionContainer(
            m_expressionCompiler.getVectorSpace(), 
            m_assetManager, 
            m_expressionSymbolResource, 
            expressionComponent, 
            entryWidth, 
            m_entryHeight, 
            "button_white", 
            "button_white", 
            "button_white", 
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
    public function pickExpressionContainerUnderPoint(globalX : Float, globalY : Float) : ExpressionContainer
    {
        var expressionContainerUnderPoint : ExpressionContainer = null;
        var i : Int;
        var expressionContainer : ExpressionContainer;
        var numExpressionContainers : Int = m_expressionContainers.length;
        for (i in 0...numExpressionContainers){
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
    
    public function removeAllExpressions() : Void
    {
        while (m_expressionContainers.length > 0)
        {
            var expressionContainer : ExpressionContainer = m_expressionContainers.pop();
            expressionContainer.dispose();
            expressionContainer.removeFromParent();
        }
        
        as3hx.Compat.setArrayLength(m_selectedExpressionContainersBuffer, 0);
    }
    
    public function getSelectedExpressionContainers(outContainers : Array<ExpressionContainer>) : Void
    {
        for (expressionContainer in m_expressionContainers)
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
    public function setGrayScaleToUnselected() : Void
    {
        for (expressionContainer in m_expressionContainers)
        {
            if (!expressionContainer.getIsSelected()) 
            {
                var colorMatrixFilter : ColorMatrixFilter = new ColorMatrixFilter();
                colorMatrixFilter.adjustSaturation(-1);
                expressionContainer.filter = colorMatrixFilter;
            }
        }
    }
    
    /**
     * Helper function that restores the color of every container to its original state.
     * Used to remove the gray out effect.
     */
    public function resetColors() : Void
    {
        for (expressionContainer in m_expressionContainers)
        {
            expressionContainer.filter = null;
        }
    }
    
    public function setExpressionContainerSelected(expressionContainer : ExpressionContainer, selected : Bool) : Void
    {
        // Check to make the container is inside this widget
        var indexOfContainer : Int = Lambda.indexOf(m_expressionContainers, expressionContainer);
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
                    var containerToRemove : ExpressionContainer = m_selectedExpressionContainersBuffer.shift();
                    containerToRemove.setSelected(false);
                }
            }
            else 
            {
                var indexInSelected : Int = Lambda.indexOf(m_selectedExpressionContainersBuffer, expressionContainer);
                m_selectedExpressionContainersBuffer.splice(indexInSelected, 1);
            }
        }
    }
    
    public function setExpressionContainerOver(expressionContainer : ExpressionContainer, over : Bool) : Void
    {
        if (Lambda.indexOf(m_expressionContainers, expressionContainer) >= 0) 
        {
            expressionContainer.setOver(over);
        }
    }
    
    private function layout() : Void
    {
        // Center contents within the total width and height
        var i : Int;
        var expressionContainer : ExpressionContainer;
        var numExpressionContainers : Int = m_expressionContainers.length;
        var itemInColumnCounter : Int = 0;
        var yOffset : Float = 0;
        var xOffset : Float = 0;
        
        var verticalSpacing : Int = 5;
        var containerHeight : Float = 0;
        for (i in 0...numExpressionContainers){
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
        
        var numColumns : Int = 1;
        var totalContainerHeight : Int = numExpressionContainers * m_entryHeight + verticalSpacing * (numExpressionContainers - 1);
        if (m_numItemsPerColumnLimit > 0) 
        {
            numColumns = Math.ceil(numExpressionContainers / m_numItemsPerColumnLimit);
            totalContainerHeight = m_numItemsPerColumnLimit * m_entryHeight + verticalSpacing * (m_numItemsPerColumnLimit - 1);
        }
        
        yOffset = (m_totalHeight - totalContainerHeight) * 0.5;
        
        // Second pass assigns the y offset that vertically centers the containers
        for (i in 0...numExpressionContainers){
            expressionContainer = m_expressionContainers[i];
            expressionContainer.y += yOffset;
            
            addChild(expressionContainer);
        }
    }
}
