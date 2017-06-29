package wordproblem.engine.animation;


import com.gskinner.motion.GTween;
import com.gskinner.motion.easing.Back;

import flash.geom.Rectangle;
import flash.geom.Vector3D;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.ExpressionUtil;
import dragonbox.common.math.vectorspace.IVectorSpace;

import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import wordproblem.resource.AssetManager;

import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.expression.tree.ExpressionTree;
import wordproblem.engine.expression.widget.ExpressionTreeWidget;
import wordproblem.engine.expression.widget.term.BaseTermWidget;

class SubstitutionAnimation
{
    private var m_widgetToReplace : BaseTermWidget;
    private var m_subtreeToReplace : ExpressionNode;
    private var m_targetCoordinateSpace : DisplayObjectContainer;
    private var m_vectorSpace : IVectorSpace;
    private var m_expressionSymbolResources : ExpressionSymbolMap;
    private var m_assetManager : AssetManager;
    
    /**
     * The tree currently being manipulated.
     */
    private var m_currentTree : ExpressionTreeWidget;
    
    /**
     * A snapshot of the layout after the substitution is done, used so during
     * the animation piece move out of the way to make room for the substitution
     */
    private var m_previewTree : ExpressionTreeWidget;
    
    private var m_onCompleteCallback : Function;
    
    public function new(widgetToReplace : BaseTermWidget,
            replacementSubtree : ExpressionNode,
            targetCoordinateSpace : DisplayObjectContainer,
            vectorSpace : IVectorSpace,
            assetManager : AssetManager,
            expressionSymbolResource : ExpressionSymbolMap,
            currentTree : ExpressionTreeWidget,
            previewTree : ExpressionTreeWidget)
    {
        super();
        
        m_widgetToReplace = widgetToReplace;
        m_subtreeToReplace = replacementSubtree;
        m_targetCoordinateSpace = targetCoordinateSpace;
        m_vectorSpace = vectorSpace;
        m_assetManager = assetManager;
        m_expressionSymbolResources = expressionSymbolResource;
        m_currentTree = currentTree;
        m_previewTree = previewTree;
    }
    
    public function play(finishCallback : Function) : Void
    {
        m_onCompleteCallback = finishCallback;
        
        // Preview immediately lays out where everything should go after the sub takes place
        // this guarantees we will have space
        m_previewTree.visible = true;
        m_previewTree.refreshNodes();
        m_previewTree.buildTreeWidget();
        m_previewTree.visible = false;
        
        var cardShiftAnimation : CardShiftAnimation = new CardShiftAnimation();
        cardShiftAnimation.play(m_currentTree, m_previewTree, function() : Void
                {
                    animateSubstitution();
                });
    }
    
    private function animateSubstitution() : Void
    {
        // The widget to replace needs to take in the bloated look as specified by the packing
        // animation. The bloated image will then need to expand a bit more before shattering and
        // releasing some set of particles.
        var widgetToReplaceBounds : Rectangle = m_widgetToReplace.getBounds(m_targetCoordinateSpace);
        
        m_widgetToReplace.scaleX += PackingAnimation.MAX_SCALE_UP_VALUE;
        m_widgetToReplace.scaleY += PackingAnimation.MAX_SCALE_UP_VALUE;
        var expandToBurstDuration : Float = 0.3;
        var expandToBurstTween : GTween = new GTween(
        m_widgetToReplace, 
        expandToBurstDuration, 
        {
            scaleX : m_widgetToReplace.scaleX + 0.1,
            scaleY : m_widgetToReplace.scaleY + 0.1,

        }, 
        {
            onComplete : onExpandToBurst

        }, 
        );
        
        var replacementWidget : ExpressionTreeWidget = new ExpressionTreeWidget(
        new ExpressionTree(m_vectorSpace, ExpressionUtil.copy(m_subtreeToReplace, m_vectorSpace)), 
        m_expressionSymbolResources, 
        m_assetManager, 
        m_previewTree.getConstraintsWidth(), 
        m_previewTree.getConstraintsHeight(), 
        false, 
        );
        var replacementWidgetRoot : DisplayObject = replacementWidget.getWidgetRoot();
        var targetScale : Float = m_previewTree.getWidgetRoot().scaleX;
        
        function onExpandToBurst(tween : GTween) : Void
        {
            m_widgetToReplace.visible = false;
            
            var replacementInPreview : BaseTermWidget = m_previewTree.getWidgetFromNodeId(m_subtreeToReplace.id);
            var positionOfReplacementPreview : Vector3D = replacementInPreview.getNode().position;
            replacementWidgetRoot.x = positionOfReplacementPreview.x;
            replacementWidgetRoot.y = positionOfReplacementPreview.y;
            
            m_targetCoordinateSpace.addChild(replacementWidgetRoot);
            replacementWidgetRoot.scaleX = replacementWidgetRoot.scaleY = 0;
            
            var expandDuration : Float = 1;
            var expandReplacementTween : GTween = new GTween(
            replacementWidgetRoot, 
            expandDuration, 
            {
                scaleX : targetScale,
                scaleY : targetScale,

            }, 
            {
                ease : Back.easeOut,
                onComplete : onExpandComplete,

            }, 
            );
        };
        
        function onExpandComplete(tween : GTween) : Void
        {
            
            if (replacementWidgetRoot.parent != null) 
                replacementWidgetRoot.parent.removeChild(replacementWidgetRoot)  // Call the oncomplete callback  ;
            
            
            
            m_onCompleteCallback();
        };
    }
}
