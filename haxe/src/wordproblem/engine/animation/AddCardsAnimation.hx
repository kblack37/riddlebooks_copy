package wordproblem.engine.animation;

import wordproblem.engine.animation.CardShiftAnimation;

import flash.geom.Point;

import haxe.Constraints.Function;

import starling.animation.Tween;
import starling.core.Starling;

import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.expression.widget.ExpressionTreeWidget;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.expression.widget.term.SymbolTermWidget;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.resource.AssetManager;

/**
 * Used to play an animation of cards being added to the term area.
 */
class AddCardsAnimation
{
    private var m_termArea : TermAreaWidget;
    
    public function new()
    {
    }
    
    public function play(termArea : TermAreaWidget,
            addedNodeId : Int,
            dropX : Float,
            dropY : Float,
            nodeResourceMap : ExpressionSymbolMap,
            assetManager : AssetManager,
            onComplete : Function) : Void
    {
        var cardShiftAnimationComplete : Bool = false;
        var addedCardShiftComplete : Bool = false;
        
        // Preview immediately lays out where everything should go after the sub takes place
        // this guarantees we will have space
        var previewTree : ExpressionTreeWidget = termArea.getPreviewView(false);
        termArea.showPreview(true);
        
        // While the other items are shifting into place, concurrently shift the object
        // that was dropped to its given slot in the preview
        var scaleFactor : Float = previewTree.getScaleFactor();
        var addedLeafWidget : BaseTermWidget = previewTree.getWidgetFromNodeId(addedNodeId);
        if (addedLeafWidget == null) 
        {
            if (onComplete != null) 
            {
                onComplete();
            }
            return;
        }
        
        var finalPoint : Point = termArea.globalToLocal(
                addedLeafWidget.localToGlobal(new Point(0, 0)));
        termArea.showPreview(false);
        
        // WARNING we have a timing issue before calling the complete callback we must
        // wait for both the preview shift and the added card shift to complete.
        // Even if their durations are set to be the same one can complete on a frame before
        // another one.
        var cardShiftDuration : Float = 0.25;
        var cardShiftAnimation : CardShiftAnimation = new CardShiftAnimation();
		
		// Create a copy of the widget
        var addedLeafWidgetCopy : BaseTermWidget = new SymbolTermWidget(
			addedLeafWidget.getNode(), 
			nodeResourceMap, 
			assetManager
        );
        addedLeafWidgetCopy.x = dropX;
        addedLeafWidgetCopy.y = dropY;
        termArea.addChild(addedLeafWidgetCopy);
		
        cardShiftAnimation.play(
            termArea,
            previewTree,
            function() : Void
            {
                cardShiftAnimationComplete = true;
                if (cardShiftAnimationComplete && addedCardShiftComplete) 
                {
                    termArea.removeChild(addedLeafWidgetCopy);
                    
                    if (onComplete != null) 
                    {
                        onComplete();
                    }
				}
            },
            cardShiftDuration
        );
        
        // Shift duration depends on the distance to move
        var deltaX : Float = dropX - finalPoint.x;
        var deltaY : Float = dropY - finalPoint.y;
        var addedCardShiftDuration : Float = Math.sqrt(deltaX * deltaX + deltaY * deltaY) / 800;
        var tween : Tween = new Tween(addedLeafWidgetCopy, addedCardShiftDuration);
        tween.moveTo(finalPoint.x, finalPoint.y);
        tween.scaleTo(scaleFactor);
		function onCompleteMove() : Void
        {
            addedCardShiftComplete = true;
            if (cardShiftAnimationComplete && addedCardShiftComplete) 
            {
                termArea.removeChild(addedLeafWidgetCopy);
                
                if (onComplete != null) 
                {
                    onComplete();
                }
            }
        };
        tween.onComplete = onCompleteMove;
        Starling.current.juggler.add(tween);
    }
}
