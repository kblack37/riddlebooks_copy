package wordproblem.engine.widget;


import dragonbox.common.math.vectorspace.RealsVectorSpace;
import flash.geom.Rectangle;
import starling.display.Image;

import dragonbox.common.dispose.IDisposable;
import dragonbox.common.math.vectorspace.IVectorSpace;

//import feathers.display.Scale9Image;
//import feathers.textures.Scale9Textures;

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
    
    override public function dispose() : Void
    {
        while (numChildren > 0)
        {
            removeChildAt(0);
        }
        
        super.dispose();
    }
    
    private function createBackgroundImage(textureName : String, assetManager : AssetManager) : DisplayObject
    {
        var backgroundImage : DisplayObject = null;
        if (textureName != null) 
        {
            var texture : Texture = assetManager.getTexture(textureName);
            var bgPadding : Float = 15;
			// TODO: these were textures from the feathers library and may need to be fixed
            var scale9Texture : Texture = Texture.fromTexture(texture, new Rectangle(bgPadding, bgPadding, texture.width - 2 * bgPadding, texture.height - 2 * bgPadding));
            backgroundImage = new Image(scale9Texture);
        }
        else 
        {
            backgroundImage = new Quad(50, 50, 0xFFFFFF);
        }
        
        return backgroundImage;
    }
}
