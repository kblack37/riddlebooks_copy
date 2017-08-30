package wordproblem.engine.animation;


import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.math.vectorspace.RealsVectorSpace;
import motion.Actuate;
import wordproblem.display.PivotSprite;
import wordproblem.display.util.BitmapUtil;

import haxe.Constraints.Function;

import openfl.display.Bitmap;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.geom.Rectangle;

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
	 * References to the running tween object
	 */
	public var m_shrinkTweenObject : DisplayObject;
    
    /**
     * Resource to create the the final views related to a term
     */
    private var m_expressionSymbolMap : ExpressionSymbolMap;
    
    /**
     * Needed to create new card objects
     */
    private var m_assetManager : AssetManager;
    
    private var m_vectorSpace : RealsVectorSpace;
    
    public function new(expressionSymbolMap : ExpressionSymbolMap,
            assetManager : AssetManager,
            vectorSpace : RealsVectorSpace)
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
			if (this.viewCopy.parent != null) viewCopy.parent.removeChild(this.viewCopy);
            this.removeChildren();
            
            if (this.parent != null) this.parent.removeChild(this);
            
            // Delete the custom rendered texture
            if (Std.is(this.viewCopy, Bitmap)) 
            {
                (try cast(this.viewCopy, Bitmap) catch(e:Dynamic) null).bitmapData.dispose();
            }
        }
        
        this.term = null;
        
        // Kill any playing tweens
        if (m_shrinkTweenObject != null) 
        {
			Actuate.stop(m_shrinkTweenObject);
            m_shrinkTweenObject = null;
        }
        
        if (viewCopy != null) 
        {
			Actuate.stop(viewCopy);
        }
		
		this.viewCopy = null;
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
        var drawnCopy : PivotSprite = new PivotSprite();
		drawnCopy.addChild(BitmapUtil.getImageFromDisplayObject(originalView));
        drawnCopy.pivotX = localPoint.x - tightBounds.left;
        drawnCopy.pivotY = localPoint.y - tightBounds.top;
        addChild(drawnCopy);
        this.viewCopy = drawnCopy;
        
        if (attachedExpression != null) 
        {
            var termImage : DisplayObject = new SymbolTermWidget(
				new ExpressionNode(m_vectorSpace, attachedExpression), 
				m_expressionSymbolMap,
				m_assetManager
            );
            
            var tweenDuration : Float = 0.2;
			Actuate.tween(drawnCopy, tweenDuration, { scaleX: 0, scaleY: 0 }).onComplete(function() : Void
                    {
                        termImage.scaleX = termImage.scaleY = 0;
                        addChild(termImage);
						
						if (drawnCopy.parent != null) drawnCopy.parent.removeChild(drawnCopy);
                        (try cast(drawnCopy.getChildAt(0), Bitmap) catch (e:Dynamic) null).bitmapData.dispose();
						drawnCopy.dispose();
						m_shrinkTweenObject = null;
                        
                        // Using gtween because for some reason linking multiple starling tweens together causes
                        // stuttering with particle system rendering when we try to reuse emitters
						Actuate.tween(termImage, tweenDuration, { scaleX: 1, scaleY: 1 }).onComplete(function() : Void
							{
								termImage.visible = false;
								onAnimationComplete();
							});
                        viewCopy = termImage;
                    });
			m_shrinkTweenObject = drawnCopy;
        }
        
        parentContainer.addChild(this);
    }
}
