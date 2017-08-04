package wordproblem.engine.widget;

import starling.display.Image;
import wordproblem.engine.widget.IBaseWidget;

import flash.geom.Rectangle;

import starling.display.DisplayObject;
import starling.textures.Texture;

import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.view.BarLabelView;
import wordproblem.engine.barmodel.view.BarModelView;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.barmodel.view.BarWholeView;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.resource.AssetManager;

/**
 * This is the main display container for the bar modeling portion of the game.
 */
class BarModelAreaWidget extends BarModelView implements IBaseWidget
{
    public var componentManager(get, never) : ComponentManager;

    private var m_background : DisplayObject;
    
    /**
     * An arbitrary restriction of the number of vertical labels we want to allow
     * Change this for things like tutorial restriction.
     */
    private var m_numMaxVerticalBars : Int = 1;
    
    /**
     * The preview view is used to show changes that would occur to the bar model if a particular
     * action was applied.
     * 
     * IMPORTANT: Some issues to keep in mind when manipulating the preview through various scripts.
     * Higher priority scripts can activate previews which overwrite/deactivate previews of lower
     * priority scripts.
     */
    private var m_previewBarModelView : BarModelView;
    
    /**
     * This link is necessary to make sure the attached preview view takes on the right values
     * when it is visible.
     */
    private var m_componentManager : ComponentManager;
    
    public function new(expressionSymbolMap : ExpressionSymbolMap,
            assetManager : AssetManager,
            unitLength : Float,
            unitHeight : Float,
            topBarPadding : Float,
            bottomBarPadding : Float,
            leftBarPadding : Float,
            rightBarPadding : Float,
            barGap : Float)
    {
        // Widget always starts out initially empty
        super(unitLength, unitHeight, topBarPadding, bottomBarPadding, leftBarPadding, rightBarPadding, barGap, new BarModelData(), expressionSymbolMap, assetManager);
        
        m_previewBarModelView = new BarModelView(unitLength, unitHeight, topBarPadding, bottomBarPadding, leftBarPadding, rightBarPadding, barGap, null, expressionSymbolMap, assetManager);
        
        // Prepare bar model area to add dynamic properties
        m_componentManager = new ComponentManager();
        
        var horizontalPadding : Float = 20;
        var verticalPadding : Float = 30;
        var backgroundImageTexture : Texture = assetManager.getTexture("term_area_left");
        var bgImage : Image = new Image(Texture.fromTexture(backgroundImageTexture, new Rectangle(
        horizontalPadding, verticalPadding, backgroundImageTexture.width - 2 * horizontalPadding, backgroundImageTexture.height - 2 * verticalPadding))
        );
        m_background = bgImage;
    }
    
    override public function setDimensions(width : Float, height : Float) : Void
    {
        super.setDimensions(width, height);
        
        if (m_background != null) 
        {
            m_background.removeFromParent(true);
        }
        m_background.width = width;
        m_background.height = height;
        addChild(m_background);
        
        m_previewBarModelView.setDimensions(width, height);
    }
    
    override public function redraw(doDispatchEvent : Bool = true, centerContents : Bool = false) : Void
    {
        super.redraw(doDispatchEvent, centerContents);
        
        // The render components that were previously set on parts on this model are discarded on a redraw.
        // Need to refresh them so that other scripts that are using that part are referencing the copy
        // that is actually visible
        var renderComponents : Array<Component> = m_componentManager.getComponentListForType(RenderableComponent.TYPE_ID);
        for (renderComponent in renderComponents)
        {
            this.addOrRefreshViewFromId(renderComponent.entityId);
        }
    }
    
    private function get_componentManager() : ComponentManager
    {
        return m_componentManager;
    }
    
    /**
     * Get the background so we can color it when a correct or incorrect validation is attempted
     */
    public function getBackgroundImage() : DisplayObject
    {
        return m_background;
    }
    
    /**
     * Get whether the preview image is showing
     */
    public function getPreviewShowing() : Bool
    {
        return m_previewBarModelView.parent != null;
    }
    
    /**
     * Get back the preview (which is more a way to get the model data of that
     * preview so that various scripts can modify it)
     * 
     * @param doCloneData
     *      If true the preview returned should take a snapshot
     * @return
     *      The preview view
     */
    public function getPreviewView(doCloneData : Bool) : BarModelView
    {
        m_previewBarModelView.normalizingFactor = this.normalizingFactor;
        m_previewBarModelView.alwaysAutoCalculateUnitLength = this.alwaysAutoCalculateUnitLength;
        
        if (doCloneData) 
        {
            var barModelDataClone : BarModelData = this.m_barModelData.clone();
            m_previewBarModelView.unitHeight = this.unitHeight;
            m_previewBarModelView.unitLength = this.unitLength;
            m_previewBarModelView.setBarModelData(barModelDataClone);
        }
        
        return m_previewBarModelView;
    }
    
    /**
     * Show the preview
     * 
     * @param value
     *      True if the preview should be displayed, false if the preview should be hidden and the
     *      regular bar model images should show up.
     */
    public function showPreview(value : Bool) : Void
    {
        if (value) 
        {
            // Copy properties of this widget to the preview so they line up correctly
            m_previewBarModelView.topBarPadding = this.topBarPadding;
            m_previewBarModelView.leftBarPadding = this.leftBarPadding;
            m_previewBarModelView.barGap = this.barGap;
            if (m_previewBarModelView.parent == null) 
            {
                addChild(m_previewBarModelView);
                m_objectLayer.visible = false;
            }
            
            m_previewBarModelView.redraw();
        }
        else 
        {
            if (m_previewBarModelView.parent != null) 
            {
                removeChild(m_previewBarModelView);
                m_objectLayer.visible = true;
            }
        }
    }
    
    /**
     * Most of the dynamic properties we want to add to a bar model view will require
     * referencing the RenderComponent. In most cases we don't bother creating these component
     * for each of the bar model view elements.
     * 
     * However, in the case of hints or tutorials we may want to add components to specific pieces.
     * This function handles the book-keeping to create the base components for a particular piece.
     * 
     * @param usePreviewView
     *      If true, the view to use belongs to the preview. Only useful if we want to apply
     *      some affect to the model while the real bar model is hidden
     */
    public function addOrRefreshViewFromId(id : String, usePreviewView : Bool = false) : Void
    {
        var barModelArea : BarModelView = ((usePreviewView)) ? m_previewBarModelView : this;
        var targetView : DisplayObject = null;
        
        // We just do a brute force search through all elements
        var barWholeViews : Array<BarWholeView> = barModelArea.getBarWholeViews();
        var i : Int = 0;
        var numBarWholeViews : Int = barWholeViews.length;
        for (i in 0...numBarWholeViews){
            var barWholeView : BarWholeView = barWholeViews[i];
            
            var j : Int = 0;
            for (j in 0...barWholeView.segmentViews.length){
                var segmentView : BarSegmentView = barWholeView.segmentViews[j];
                if (segmentView.data.id == id) 
                {
                    targetView = segmentView;
                    break;
                }
            }
            
            for (j in 0...barWholeView.labelViews.length){
                var barLabelView : BarLabelView = barWholeView.labelViews[j];
                if (barLabelView.data.id == id) 
                {
                    targetView = barLabelView;
                    break;
                }
            }
            
            if (barWholeView.comparisonView != null && barWholeView.comparisonView.data.id == id) 
            {
                targetView = barWholeView.comparisonView;
            }
            
            if (targetView != null) 
            {
                break;
            }
        }  // If not contained in one of the bar model elements, check if it is in the vertical labels  
        
        
        
        if (targetView == null) 
        {
            targetView = barModelArea.getVerticalBarLabelViewById(id);
        }  // Either create a new component for a view or refresh it.  
        
        
        
        var renderComponent : RenderableComponent = try cast(m_componentManager.getComponentFromEntityIdAndType(id, RenderableComponent.TYPE_ID), RenderableComponent) catch(e:Dynamic) null;
        if (renderComponent == null) 
        {
            renderComponent = new RenderableComponent(id);
            renderComponent.view = targetView;
            m_componentManager.addComponentToEntity(renderComponent);
        }
        else 
        {
            if (targetView == null) 
            {
                m_componentManager.removeComponentFromEntity(id, RenderableComponent.TYPE_ID);
            }
            else if (renderComponent.view != targetView) 
            {
                renderComponent.view = targetView;
            }
        }
    }
}
