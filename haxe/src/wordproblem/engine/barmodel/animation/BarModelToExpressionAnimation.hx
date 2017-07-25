package wordproblem.engine.barmodel.animation;


import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import haxe.Constraints.Function;

import starling.animation.IAnimatable;
import starling.animation.Juggler;
import starling.animation.Tween;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.textures.RenderTexture;

import wordproblem.engine.barmodel.view.BarModelView;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.expression.tree.ExpressionTree;
import wordproblem.engine.expression.widget.ExpressionTreeWidget;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.expression.widget.term.GroupTermWidget;
import wordproblem.resource.AssetManager;

/**
 * This is a test animation to convert various parts of a bar model view into a target expression
 */
class BarModelToExpressionAnimation implements IAnimatable
{
    /**
     * TODO: Temp made static so all other scripts needing to manipulate copies of the bar model view
     */
    public static function convertBarModelViewsToSingleImage(barModelViews : Array<DisplayObject>,
            boundsFrameOfReference : DisplayObjectContainer,
            scaleFactor : Float,
            outTotalBoundsBuffer : Rectangle = null) : Image
    {
        var i : Int;
        var numViews : Int = barModelViews.length;
        var barModelViewBounds : Array<Rectangle> = new Array<Rectangle>();
        var totalBoundsBuffer : Rectangle = new Rectangle();
        for (i in 0...numViews){
            var barModelView : DisplayObject = barModelViews[i];
            var barModelViewBound : Rectangle = barModelView.getBounds(boundsFrameOfReference);
            barModelViewBounds.push(barModelViewBound);
            totalBoundsBuffer = barModelViewBound.union(totalBoundsBuffer);
        }  // The total bounds gives us the size of the canvas as well as the drawing offset  
        
        
        
        var barModelRenderTexture : RenderTexture = new RenderTexture(Std.int(totalBoundsBuffer.width), Std.int(totalBoundsBuffer.height), false);
        barModelRenderTexture.drawBundled(function(DisplayObject, Matrix, Float) : Void
                {
                    // We want each individual view to be oriented relative to the total bounds
                    for (i in 0...numViews){
                        var barModelViewBound = barModelViewBounds[i];
                        var barModelView = barModelViews[i];
                        
                        var xOffset : Float = barModelViewBound.x - totalBoundsBuffer.x;
                        var yOffset : Float = barModelViewBound.y - totalBoundsBuffer.y;
                        barModelRenderTexture.draw(barModelView, new Matrix(scaleFactor, 0, 0, scaleFactor, xOffset, yOffset));
                    }
                });
        
        if (outTotalBoundsBuffer != null) 
        {
            outTotalBoundsBuffer.setTo(totalBoundsBuffer.x, totalBoundsBuffer.y, totalBoundsBuffer.width, totalBoundsBuffer.height);
        }
        return new Image(barModelRenderTexture);
    }
    
    /**
     * This is the starting bar model
     */
    private var m_barModelView : BarModelView;
    
    /**
     * A list of objects that are used to map from parts of the current
     * bar model view to eventual parts of the expression view.
     * 
     * Each object has
     * barModelViews:Array of Display objects representing labels, segments, or comparisons
     * subexpression: Subexpression string of the expression view the bar model views to transform into
     * expressionView: The root view that the preceding subexpression row should move to in order to complete the animation
     * expressionTree:
     */
    private var m_barModelToExpressionMappings : Array<Dynamic>;
    
    /**
     * Need to keep track of the current tween being played
     */
    private var m_currentTweenIndexPlaying : Int;
    
    /**
     * List of tweens ordered in the sequence they should be played.
     */
    private var m_tweens : Array<Tween>;
    
    /**
     * Keep track of all the bar model copy images created.
     * We must properly dispose of the textures when they are no longer needed
     */
    private var m_barModelCopyImages : Array<Image>;
    
    /**
     * Keep track of all the subexpression views created.
     * We must properly dispose of them when they are no longer needed
     */
    private var m_subexpressionViews : Array<ExpressionTreeWidget>;
    
    /**
     * This is the primary parent container to hold all the transient visual objects related to this animation
     */
    private var m_displayContainer : DisplayObjectContainer;
    
    /**
     * This function should pass in the bar model view
     */
    private var m_mapFunction : Function;
    
    private var m_expressionCompiler : IExpressionTreeCompiler;
    private var m_expressionSymbolResource : ExpressionSymbolMap;
    private var m_assetManager : AssetManager;
    
    /**
     * The origin is used for translation
     */
    private var originPoint : Point = new Point();
    
    /**
     * This is the animator
     */
    private var m_juggler : Juggler;
    
    /**
     * Callback when the animation is over
     * 
     * Accepts a single callback which is this object. Used so it can be disposed at the right time.
     */
    private var m_endCallback : Function;
    
    /**
     *
     * @param mapFunction
     *      Signature callback(barModelView:BarModelView, addMappingCallback:Function)
     * @param endCallback
     *      Signature callback(animation:BarModelToExpressionAnimation)
     */
    public function new(barModelView : BarModelView,
            mapFunction : Function,
            endCallback : Function,
            displayContainer : DisplayObjectContainer,
            expressionCompiler : IExpressionTreeCompiler,
            expressionSymbolResource : ExpressionSymbolMap,
            assetManager : AssetManager,
            juggler : Juggler)
    {
        m_barModelToExpressionMappings = new Array<Dynamic>();
        m_barModelCopyImages = new Array<Image>();
        m_subexpressionViews = new Array<ExpressionTreeWidget>();
        m_tweens = new Array<Tween>();
        m_barModelView = barModelView;
        m_mapFunction = mapFunction;
        m_endCallback = endCallback;
        m_displayContainer = displayContainer;
        m_expressionCompiler = expressionCompiler;
        m_expressionSymbolResource = expressionSymbolResource;
        m_assetManager = assetManager;
        m_juggler = juggler;
    }
    
    public function start() : Void
    {
		m_barModelToExpressionMappings = new Array<Dynamic>();
        
        m_mapFunction(m_barModelView, addMapping);
        
        // Once map is populated we can now start playing all the tweens in the
        // appropriate order.
        m_currentTweenIndexPlaying = 0;
        if (m_tweens.length > m_currentTweenIndexPlaying) 
        {
            m_juggler.add(m_tweens[m_currentTweenIndexPlaying]);
        }
        else if (m_endCallback != null) 
        {
            m_endCallback(this);
        }
    }
    
    public function dispose() : Void
    {
        var i : Int;
        var numImages : Int = m_barModelCopyImages.length;
        for (i in 0...numImages){
            var barModelCopyImage : Image = m_barModelCopyImages[i];
            barModelCopyImage.removeFromParent(true);
            barModelCopyImage.texture.dispose();
            
            var subexpressionView : ExpressionTreeWidget = m_subexpressionViews[i];
            subexpressionView.removeFromParent(true);
        }  // Make original views transparent  
        
        
        
        var numMappings : Int = m_barModelToExpressionMappings.length;
        for (i in 0...numMappings){
            var mappingObject : Dynamic = m_barModelToExpressionMappings[i];
            var j : Int;
            var barModelViews : Array<DisplayObject> = mappingObject.barModelViews;
            for (j in 0...barModelViews.length){
                barModelViews[j].alpha = 1.0;
            }
        }
        
		m_barModelCopyImages = new Array<Image>();
		m_subexpressionViews = new Array<ExpressionTreeWidget>();
    }
    
    /**
     * The map function needs to call this in order record the order at which things should be animated
     */
    private function addMapping(barModelViews : Array<DisplayObject>,
            subexpression : String,
            expressionView : BaseTermWidget) : Void
    {
        var mappingObject : Dynamic = {
            barModelViews : barModelViews,
            subexpression : subexpression,
            expressionView : expressionView,

        };
        m_barModelToExpressionMappings.push(mappingObject);
        
        // Immediately setup all the intermediate images and tweens for that mapping
        createTweensForBarToExpressionData(mappingObject);
    }
    
    private function createTweensForBarToExpressionData(data : Dynamic) : Void
    {
        // Create bounding boxes around all views that are part of the animation.
        // The union of all the rectangles is the overall size of the canvas
        var barModelViews : Array<DisplayObject> = data.barModelViews;
        var totalBoundsBuffer : Rectangle = new Rectangle();
        var image : Image = BarModelToExpressionAnimation.convertBarModelViewsToSingleImage(barModelViews, m_displayContainer, m_barModelView.scaleFactor, totalBoundsBuffer);
        
        // Make original views transparent
        var i : Int;
        var numViews : Int = barModelViews.length;
        for (i in 0...numViews){
            var barModelView : DisplayObject = barModelViews[i];
            barModelView.alpha = 0.2;
        }  // Need to make sure this texture gets cleaned up later which is why we add it to a list  
        
        
        
        m_displayContainer.addChild(image);
        m_barModelCopyImages.push(image);
        
        // Have the pivot of the copy be right in the center
        image.pivotX = totalBoundsBuffer.width * 0.5;
        image.pivotY = totalBoundsBuffer.height * 0.5;
        image.x = totalBoundsBuffer.x + image.pivotX;
        image.y = totalBoundsBuffer.y + image.pivotY;
        
        // Need a tween that collapses the bar model part into the subexpression
        var subExpressionTree : ExpressionTree = new ExpressionTree(
			m_expressionCompiler.getVectorSpace(), 
			m_expressionCompiler.compile(data.subexpression)
        );
        var subexpressionView : ExpressionTreeWidget = new ExpressionTreeWidget(subExpressionTree, m_expressionSymbolResource, m_assetManager, 200, 150, true, false);
        subexpressionView.refreshNodes();
        subexpressionView.buildTreeWidget();
        
        // The subexpression the bar model should transform to should appear at the same location as the bar model
        var subexpressionLocalBounds : Rectangle = subexpressionView.getWidgetRoot().rigidBodyComponent.boundingRectangle;
        subexpressionView.pivotX = subexpressionView.getConstraintsWidth() * 0.5;
        subexpressionView.pivotY = subexpressionView.getConstraintsWidth() * 0.5;
        subexpressionView.x = image.x - subexpressionView.getConstraintsWidth() * 0.5 + subexpressionView.pivotX;
        subexpressionView.y = image.y - subexpressionView.getConstraintsHeight() * 0.5 + subexpressionView.pivotY;
        var originalSubexpressionScale : Float = subexpressionView.getScaleFactor();
        m_displayContainer.addChild(subexpressionView);
        
        var targetTermWidget : BaseTermWidget = data.expressionView;
        var targetLocalBounds : Rectangle = targetTermWidget.rigidBodyComponent.boundingRectangle;
        var globalTargetAnchor : Point = targetTermWidget.localToGlobal(originPoint);
        
        // Need to move the subexpression to the final target
        // We can find out the amount to shift by looking at the bounding boxes defined for the subexpression root
        // and the target term view
        // For the point translation to work correctly, the object must have been added to the display hierarchy
        var globalSubexpressionAnchor : Point = subexpressionView.getWidgetRoot().localToGlobal(originPoint);
        var subexpressionBoundsForComparison : Rectangle;
        var targetExpressionBoundsForComparison : Rectangle;
        if (Std.is(subexpressionView.getWidgetRoot(), GroupTermWidget)) 
        {
            var graphicsBounds : Rectangle = (try cast(subexpressionView.getWidgetRoot(), GroupTermWidget) catch(e:Dynamic) null).mainGraphicBounds;
            subexpressionBoundsForComparison = graphicsBounds.clone();
            targetLocalBounds = (try cast(targetTermWidget, GroupTermWidget) catch(e:Dynamic) null).mainGraphicBounds;
        }
        else 
        {
            subexpressionBoundsForComparison = subexpressionView.getWidgetRoot().rigidBodyComponent.boundingRectangle;
        }
        var scaleAmount : Float = (targetLocalBounds.width * originalSubexpressionScale) / subexpressionBoundsForComparison.width;
        subexpressionView.removeFromParent();
        m_subexpressionViews.push(subexpressionView);
        
        // The tween sequence is the bar model pieces collapse into the subexpression
        // The subexpression scale to set to on move can be found by looking at the same 'leaf'
        // views in both places
        var deltaX : Float = globalTargetAnchor.x - globalSubexpressionAnchor.x;
        var deltaY : Float = globalTargetAnchor.y - globalSubexpressionAnchor.y;
        var moveExpressionTween : Tween = new Tween(subexpressionView, 0.4);
        moveExpressionTween.delay = 1.0;
        moveExpressionTween.animate("x", subexpressionView.x + deltaX);
        moveExpressionTween.animate("y", subexpressionView.y + deltaY);
        moveExpressionTween.animate("scaleX", scaleAmount);
        moveExpressionTween.animate("scaleY", scaleAmount);
        moveExpressionTween.onCompleteArgs = [subexpressionView];
        moveExpressionTween.onComplete = onMoveExpressionComplete;
        
        var scaleSubexpressionTween : Tween = new Tween(subexpressionView, 0.3);
        scaleSubexpressionTween.animate("scaleX", originalSubexpressionScale);
        scaleSubexpressionTween.animate("scaleY", originalSubexpressionScale);
        scaleSubexpressionTween.onCompleteArgs = [subexpressionView, moveExpressionTween];
        scaleSubexpressionTween.onComplete = onScaleSubexpressionComplete;
        
        // Have the bar model copy shrink into the bottom point
        var scaleBarModelTween : Tween = new Tween(image, 0.3);
        scaleBarModelTween.animate("scaleX", 0);
        scaleBarModelTween.animate("scaleY", 0);
        scaleBarModelTween.delay = 0.5;
        scaleBarModelTween.onCompleteArgs = [subexpressionView, scaleSubexpressionTween];
        scaleBarModelTween.onComplete = onScaleBarModelComplete;
        
        m_tweens.push(scaleBarModelTween);
    }
    
    private function onMoveExpressionComplete(subexpressionView : ExpressionTreeWidget) : Void
    {
        // Move onto the next tween
        m_currentTweenIndexPlaying++;
        if (m_tweens.length > m_currentTweenIndexPlaying) 
        {
            m_juggler.add(m_tweens[m_currentTweenIndexPlaying]);
        }
        else if (m_endCallback != null) 
        {
            m_endCallback(this);
        }
    }
    
    private function onScaleSubexpressionComplete(subexpressionView : ExpressionTreeWidget, nextTween : Tween) : Void
    {
        m_juggler.add(nextTween);
    }
    
    private function onScaleBarModelComplete(subexpressionView : ExpressionTreeWidget, nextTween : Tween) : Void
    {
        // Set up the subexpression to not be visible
        subexpressionView.scaleX = subexpressionView.scaleY = 0.0;
        m_displayContainer.addChild(subexpressionView);
        
        m_juggler.add(nextTween);
    }
    
    // Need to make sure the animation can be paused at anytime and disposed of properly
    // One option would be to create all possible tween and images at the start
    // Thus we would only need to figure out how to transition between all tweens
    
    public function advanceTime(time : Float) : Void
    {
    }
}
