package wordproblem.engine.widget;


import dragonbox.common.math.vectorspace.RealsVectorSpace;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import wordproblem.display.Scale9Image;

import dragonbox.common.dispose.IDisposable;
import dragonbox.common.math.vectorspace.IVectorSpace;

import openfl.display.DisplayObject;
import openfl.display.Sprite;

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
class ExpressionContainer extends Sprite implements IDisposable
{
    private var m_isSelected : Bool;
    
    private var m_maxWidth : Float;
    private var m_maxHeight : Float;
    
    private var m_unselectedUpImage : DisplayObject;
    private var m_unselectedOverImage : DisplayObject;
    private var m_selectedUpImage : DisplayObject;
    
    /**
     * Backing data representing the equation
     */
    private var m_expressionComponent : ExpressionComponent;
    
    /**
     * The view for the equation
     */
    private var m_expressionTreeWidget : ExpressionTreeWidget;
    
    private var m_vectorSpace : RealsVectorSpace;
    private var m_expressionResources : ExpressionSymbolMap;
    
    private var m_bgLayer : Sprite;
    
    public function new(vectorSpace : RealsVectorSpace,
            assetManager : AssetManager,
            expressionSymbolResources : ExpressionSymbolMap,
            equation : ExpressionComponent,
            maxWidth : Float,
            maxHeight : Float,
            backgroundImageUnselectedUp : String,
            backgroundImageSelectedUp : String,
            backgroundImageUnselectedOver : String)
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
        var expressionTreeWidget : ExpressionTreeWidget = new ExpressionTreeWidget(
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
    
    public function getExpressionWidget() : ExpressionTreeWidget
    {
        return m_expressionTreeWidget;
    }
    
    public function getExpressionComponent() : ExpressionComponent
    {
        return m_expressionComponent;
    }
    
    public function getIsSelected() : Bool
    {
        return m_isSelected;
    }
    
    public function setSelected(isSelected : Bool) : Void
    {
        m_bgLayer.removeChildren();
        m_isSelected = isSelected;
        
        var selectedImage : DisplayObject = ((isSelected)) ? m_selectedUpImage : m_unselectedUpImage;
        
        selectedImage.width = m_maxWidth;
        selectedImage.height = m_maxHeight;
        m_bgLayer.addChild(selectedImage);
    }
    
    public function setOver(isOver : Bool) : Void
    {
        if (!m_isSelected) 
        {
            m_bgLayer.removeChildren();
            
            var overImage : DisplayObject = ((isOver)) ? m_unselectedOverImage : m_unselectedUpImage;
            overImage.width = m_maxWidth;
            overImage.height = m_maxHeight;
            m_bgLayer.addChild(overImage);
        }
    }
    
    public function update() : Void
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
    
    public function dispose() : Void
    {
        while (numChildren > 0)
        {
            removeChildAt(0);
        }
		
		if (Std.is(m_unselectedUpImage, Scale9Image)) {
			cast(m_unselectedUpImage, Scale9Image).dispose();
		} else {
			cast(m_unselectedUpImage, Bitmap).bitmapData.dispose();
		}
		
		if (Std.is(m_unselectedOverImage, Scale9Image)) {
			cast(m_unselectedOverImage, Scale9Image).dispose();
		} else {
			cast(m_unselectedOverImage, Bitmap).bitmapData.dispose();
		}
		
		if (Std.is(m_selectedUpImage, Scale9Image)) {
			cast(m_selectedUpImage, Scale9Image).dispose();
		} else {
			cast(m_selectedUpImage, Bitmap).bitmapData.dispose();
		}
    }
    
    private function createBackgroundImage(bitmapDataName : String, assetManager : AssetManager) : DisplayObject
    {
        var backgroundImage : DisplayObject = null;
        if (bitmapDataName != null) 
        {
            var bitmapData : BitmapData = assetManager.getBitmapData(bitmapDataName);
            var bgPadding : Float = 15;
            backgroundImage = new Scale9Image(bitmapData, new Rectangle(bgPadding, bgPadding, bitmapData.width - 2 * bgPadding, bitmapData.height - 2 * bgPadding));
        }
        else 
        {
			backgroundImage = new Bitmap(new BitmapData(50, 50, false, 0xFFFFFFFF));
        }
        
        return backgroundImage;
    }
}
