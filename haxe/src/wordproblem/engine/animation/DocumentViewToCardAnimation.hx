package wordproblem.engine.animation;


import flash.geom.Point;
import flash.geom.Rectangle;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.math.vectorspace.IVectorSpace;

import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Sprite;
import starling.extensions.textureutil.TextureUtil;

import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.expression.widget.term.SymbolTermWidget;
import wordproblem.resource.AssetManager;

/**
 * Representation of a dragged component holding data that was extracted from the paragraph.
 * 
 * Given a reference to a view that was embedded in the paragraph it created a copy of that object.
 * Is also used as a generic view component that can create a visual copy of an
 * existing starling display object
 * 
 */
class DocumentViewToCardAnimation extends Sprite
{
    /**
     * Reference to the expression value attached to this text, null if
     * no valid expression is found
     */
    public var term : String;
    
    /**
     * A copy of the view
     */
    public var viewCopy : DisplayObject;
    
    /**
     * Resource to create the the final views related to a term
     */
    private var m_expressionSymbolMap : ExpressionSymbolMap;
    
    /**
     * Needed to create new card objects
     */
    private var m_assetManager : AssetManager;
    
    private var m_vectorSpace : IVectorSpace;
    
    private var m_textShrinkTween : Tween;
    private var m_termExpandTween : Tween;
    
    public function new(expressionSymbolMap : ExpressionSymbolMap,
            assetManager : AssetManager,
            vectorSpace : IVectorSpace)
    {
        super();
        
        m_expressionSymbolMap = expressionSymbolMap;
        m_assetManager = assetManager;
        m_vectorSpace = vectorSpace;
    }
    
    /**
     * Cleans up the resources associated with the drag.
     * 
     * Its possible we want to do some animation with the dragged copy in which case
     * we will reference data still in this object. The animation must be completed 
     * before this is called as the texture for the copy will get destroyed in this
     * function.
     */
    public function reset() : Void
    {
        if (this.viewCopy != null) 
        {
            this.viewCopy.removeFromParent(true);
            this.removeChildren();
            
            this.parent.removeChild(this);
            
            // Delete the custom rendered texture
            if (Std.is(this.viewCopy, Image)) 
            {
                (try cast(this.viewCopy, Image) catch(e:Dynamic) null).texture.dispose();
            }
        }
        
        this.term = null;
        this.viewCopy = null;
        
        // Kill any playing tweens
        if (m_textShrinkTween != null) 
        {
            Starling.juggler.remove(m_textShrinkTween);
            m_textShrinkTween = null;
        }
        
        if (m_termExpandTween != null) 
        {
            Starling.juggler.remove(m_termExpandTween);
            m_termExpandTween = null;
        }
    }
    
    // The original view can be composed of several visual elements, we want to perform the
    public function setView(originalView : DisplayObject,
            attachedExpression : String,
            parentContainer : DisplayObjectContainer,
            mousePoint : Point,
            onAnimationComplete : Function) : Void
    {
        this.term = attachedExpression;
        
        // As long as the view isn't null we want the player to see the content being
        // dragged from the page even if it not associated with a term
        // We create a copy of the view
        
        // Original view is actually the container holding the specific document pieces
        // To shift properly need to get as tight a bound as possible
        var tightBounds : Rectangle = originalView.getBounds(originalView);
        
        // Pivot should be at the location of the mouse press, need to convert it from global space
        // to that of the parent container.
        // NOTE that the drawn copy gets rebounded to a tight box
        var localPoint : Point = originalView.globalToLocal(mousePoint);
        var drawnCopy : DisplayObject = TextureUtil.getImageFromDisplayObject(originalView);
        drawnCopy.pivotX = localPoint.x - tightBounds.left;
        drawnCopy.pivotY = localPoint.y - tightBounds.top;
        addChild(drawnCopy);
        this.viewCopy = drawnCopy;
        
        if (attachedExpression != null) 
        {
            var termImage : DisplayObject = new SymbolTermWidget(
            new ExpressionNode(m_vectorSpace, attachedExpression), 
            m_expressionSymbolMap, m_assetManager, 
            );
            
            var tweenDuration : Float = 0.2;
            var textShrinkTween : Tween = new Tween(drawnCopy, tweenDuration);
            textShrinkTween.scaleTo(0);
            textShrinkTween.onComplete = function() : Void
                    {
                        termImage.scaleX = termImage.scaleY = 0;
                        addChild(termImage);
                        drawnCopy.removeFromParent(true);
                        (try cast(drawnCopy, Image) catch(e:Dynamic) null).texture.dispose();
                        
                        // Using gtween because for some reason linking multiple starling tweens together causes
                        // stuttering with particle system rendering when we try to reuse emitters
                        var termExpandTween : Tween = new Tween(termImage, tweenDuration);
                        termExpandTween.scaleTo(1.0);
                        termExpandTween.onComplete = onExpandComplete;
                        Starling.juggler.add(termExpandTween);
                        
                        function onExpandComplete() : Void
                        {
                            termImage.visible = false;
                            onAnimationComplete();
                        };
                        m_termExpandTween = termExpandTween;
                        viewCopy = termImage;
                    };
            Starling.juggler.add(textShrinkTween);
            m_textShrinkTween = textShrinkTween;
        }
        
        parentContainer.addChild(this);
    }
}
