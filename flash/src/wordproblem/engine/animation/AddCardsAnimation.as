package wordproblem.engine.animation
{
    import flash.geom.Point;
    
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
    public class AddCardsAnimation
    {
        private var m_termArea:TermAreaWidget;
        
        public function AddCardsAnimation()
        {
        }
        
        public function play(termArea:TermAreaWidget,
                             addedNodeId:int,
                             dropX:Number,
                             dropY:Number,
                             nodeResourceMap:ExpressionSymbolMap, 
                             assetManager:AssetManager,
                             onComplete:Function):void
        {
            var cardShiftAnimationComplete:Boolean = false;
            var addedCardShiftComplete:Boolean = false;
            
            // Preview immediately lays out where everything should go after the sub takes place
            // this guarantees we will have space
            var previewTree:ExpressionTreeWidget = termArea.getPreviewView(false);
            termArea.showPreview(true);
            
            // While the other items are shifting into place, concurrently shift the object
            // that was dropped to its given slot in the preview
            const scaleFactor:Number = previewTree.getScaleFactor();
            const addedLeafWidget:BaseTermWidget = previewTree.getWidgetFromNodeId(addedNodeId);
            if (addedLeafWidget == null)
            {
                if (onComplete != null)
                {
                    onComplete();
                }
                return;
            }
            
            var finalPoint:Point = termArea.globalToLocal(
                addedLeafWidget.localToGlobal(new Point(0, 0)));
            termArea.showPreview(false);

            // WARNING we have a timing issue before calling the complete callback we must
            // wait for both the preview shift and the added card shift to complete.
            // Even if their durations are set to be the same one can complete on a frame before
            // another one.
            const cardShiftDuration:Number = 0.25;
            const cardShiftAnimation:CardShiftAnimation = new CardShiftAnimation();
            cardShiftAnimation.play(
                termArea, 
                previewTree, 
                function():void
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
            
            // Create a copy of the widget
            const addedLeafWidgetCopy:BaseTermWidget = new SymbolTermWidget(
                addedLeafWidget.getNode(),
                nodeResourceMap,
                assetManager
            );
            addedLeafWidgetCopy.x = dropX;
            addedLeafWidgetCopy.y = dropY;
            termArea.addChild(addedLeafWidgetCopy);
            
            // Shift duration depends on the distance to move
            const deltaX:Number = dropX - finalPoint.x;
            const deltaY:Number = dropY - finalPoint.y;
            const addedCardShiftDuration:Number = Math.sqrt(deltaX * deltaX + deltaY * deltaY) / 800;
            var tween:Tween = new Tween(addedLeafWidgetCopy, addedCardShiftDuration);
            tween.moveTo(finalPoint.x, finalPoint.y);
            tween.scaleTo(scaleFactor);
            tween.onComplete = onCompleteMove;
            Starling.juggler.add(tween);

            function onCompleteMove():void
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
            }
            
        }
    }
}