package wordproblem.engine.animation
{
    import flash.geom.Point;
    import flash.geom.Vector3D;
    
    import dragonbox.common.expressiontree.ExpressionNode;
    
    import starling.animation.Tween;
    import starling.core.Starling;
    
    import wordproblem.engine.expression.widget.ExpressionTreeWidget;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;

    /**
     * Animation attempts to shift cards from one widget to match the position and
     * scale of cards in another widget.
     */
    public class CardShiftAnimation
    {
        private var m_numberWidgetsToShift:int;
        private var m_smoothShiftCompleteCallback:Function;
        
        public function CardShiftAnimation()
        {
        }
        
        /**
         * Given a preview tree, this function will attempt to gradually reposition the contents of
         * this tree to match the positions found in the given preview. Note that the preview tree must
         * share the same backing expression tree data structure of this to function correctly
         * 
         * Note that the layering will be completely screwed up after this so a fresh rebuild will be necessary
         * 
         * @param previewTreeWidget
         *      Contents a final desired layout for the widgets
         * @param onComplete
         *      Callback when the smooth shift is complete
         * @param duration
         *      Number of seconds to finish the shift
         */
        public function play(startingTreeWidget:ExpressionTreeWidget,
                             previewTreeWidget:ExpressionTreeWidget, 
                             onComplete:Function, 
                             duration:Number = 0.25):void
        {
            m_numberWidgetsToShift = 0;
            m_smoothShiftCompleteCallback = onComplete;
            _smoothShift(startingTreeWidget.getWidgetRoot(), startingTreeWidget, previewTreeWidget, previewTreeWidget.getScaleFactor(), duration);
            
            if (m_numberWidgetsToShift == 0)
            {
                onSmoothShiftComplete();
            }
        }
        
        private function _smoothShift(widget:BaseTermWidget, 
                                      startingTreeWidget:ExpressionTreeWidget,
                                      previewTreeWidget:ExpressionTreeWidget, 
                                      scaleFactor:Number, 
                                      duration:Number):void
        {   
            if (widget != null)
            {
                // Look at the children first in order to prevent layering issues and visual
                // inheritance issue associated with the parent properties being adjusted
                _smoothShift(widget.leftChildWidget, startingTreeWidget, previewTreeWidget, scaleFactor, duration);
                _smoothShift(widget.rightChildWidget, startingTreeWidget, previewTreeWidget, scaleFactor, duration);
                
                // Check if the current widget in this tree exists in the given preview.
                const widgetGlobalCoordinates:Point = widget.localToGlobal(new Point(0, 0));
                const widgetPosition:Point = startingTreeWidget.globalToLocal(widgetGlobalCoordinates);
                widget.x = widgetPosition.x;
                widget.y = widgetPosition.y;
                
                // Set the scale factor for each term to that of the entire tree
                // WARNING the widgets must have their scale factors reset to one
                // Scaling of a parent affects its children, but the scaleX and scaleY of
                // the children remain one
                widget.scaleX = widget.scaleY = startingTreeWidget.getScaleFactor();
                
                // Yank the widgets from their normal layers since its easier just to coordinate movement
                // of each individual card or operator than a collection of them
                // Warning doing this temporarily screws up tree layering which is only corrected after
                // explicitly rebuilding the widget groups.
                // This also screws up scaling of the widget
                startingTreeWidget.addChild(widget);
                var expressionNode:ExpressionNode = widget.getNode();
                
                var previewWidget:BaseTermWidget = previewTreeWidget.getWidgetFromNodeId(expressionNode.id);
                if (previewWidget != null)
                {
                    // If it does then we use look at the backing node's position
                    // Calculate the difference relative to this container of the two widgets.
                    const nodePosition:Vector3D = expressionNode.position;
                    
                    const xDelta:Number = nodePosition.x - widgetPosition.x;
                    const yDelta:Number = nodePosition.y - widgetPosition.y;
                    const error:Number = 0.01;
                    
                    // Only perform shift if the amount to move exceeds some error threshold
                    if (Math.abs(xDelta) > error || Math.abs(yDelta) > error)
                    {
                        m_numberWidgetsToShift++;
                        
                        // The final value is amount to actually tween the widget by
                        var tween:Tween = new Tween(widget, duration);
                        tween.moveTo(widget.x + xDelta, widget.y + yDelta);
                        tween.scaleTo(scaleFactor);
                        tween.onComplete = onSmoothShiftComplete;
                        Starling.juggler.add(tween);
                    }
                }
                else
                {
                    // The widget does not exist in the next snapshot (it got deleted)
                    // Since other animations may want to mess around with it still we
                    // will leave it alone
                }
            }
        }
        
        private function onSmoothShiftComplete():void
        {
            m_numberWidgetsToShift--;
            
            if (m_numberWidgetsToShift <= 0 && m_smoothShiftCompleteCallback != null)
            {
                m_smoothShiftCompleteCallback();
            }
        }
    }
}