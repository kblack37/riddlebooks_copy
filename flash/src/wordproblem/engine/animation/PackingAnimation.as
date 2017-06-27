package wordproblem.engine.animation
{
    import com.gskinner.motion.GTween;
    
    import flash.geom.Point;
    import flash.utils.Dictionary;
    
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.ExpressionUtil;
    import dragonbox.common.math.vectorspace.IVectorSpace;
    
    import starling.display.DisplayObject;
    
    import wordproblem.engine.expression.widget.ExpressionTreeWidget;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.expression.widget.term.GroupTermWidget;

    /**
     * The animation of the right side of an equation packing into the left side.
     * 
     * (Unfortunately this can only handle equation that are exactly in definition format)
     */
    public class PackingAnimation
    {
        private var m_rootEquationWidget:BaseTermWidget;
        private var m_vectorSpace:IVectorSpace;
        
        public static var MAX_SCALE_UP_VALUE:Number = 0.25;
        private var m_amountToScaleUpBy:Number;
        private var m_numObjectsToAbsorb:int;
		
		private var m_finishCallback:Function;
        
        public function PackingAnimation()
        {
        }
        
        public function play(rootEquationWidget:BaseTermWidget, 
                             vectorSpace:IVectorSpace,
                             finishCallback:Function):void
        {
            m_rootEquationWidget = rootEquationWidget;
            m_vectorSpace = vectorSpace;
            m_finishCallback = finishCallback;
            
            // Look at the root widget
            var rootNode:ExpressionNode = m_rootEquationWidget.getNode();
            
            // Get every group of terms that move in unison
            var outNodes:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            var objectsToTween:Vector.<DisplayObject> = new Vector.<DisplayObject>();
            var additionNodeIdsProcessed:Dictionary = new Dictionary();
            ExpressionUtil.getCommutativeGroupRoots(
                rootNode.right, 
                m_vectorSpace.getAdditionOperator(), 
                outNodes);
            for (var i:int = 0; i < outNodes.length; i++)
            {
                var additionGroupNode:ExpressionNode = outNodes[i];
                var additionGroupWidget:BaseTermWidget = ExpressionTreeWidget.getWidgetFromId(additionGroupNode.id, m_rootEquationWidget);
                objectsToTween.push(additionGroupWidget);
                
                // Grab reference to the addition graphics
                var parentNode:ExpressionNode = additionGroupWidget.parentWidget.getNode();
                if (parentNode.isSpecificOperator(m_vectorSpace.getAdditionOperator()) &&
                    !additionNodeIdsProcessed.hasOwnProperty(parentNode.id))
                {
                    var additionWidget:GroupTermWidget = additionGroupWidget.parentWidget as GroupTermWidget;
                    objectsToTween.push(additionWidget.groupImage);
                    additionNodeIdsProcessed[parentNode.id] = true;
                }
            }
            
            // Grab reference to the equals graphic
            var equalsWidget:GroupTermWidget = m_rootEquationWidget as GroupTermWidget;
            var definitionWidget:BaseTermWidget = equalsWidget.leftChildWidget;
            var globalCoordinatesOfDefinition:Point = definitionWidget.localToGlobal(new Point(0, 0));
            var globalCoordinatesOfEqual:Point = equalsWidget.localToGlobal(new Point(0, 0));
            objectsToTween.push(equalsWidget.groupImage);
            
            // Shift the widget over so that the center of the definition variable goes where
            // the center of the equals operator was
            const xToShiftDefinition:Number = globalCoordinatesOfEqual.x - globalCoordinatesOfDefinition.x;
            globalCoordinatesOfDefinition.x += xToShiftDefinition
            definitionWidget.x += xToShiftDefinition;
            
            m_numObjectsToAbsorb = objectsToTween.length;
            m_amountToScaleUpBy = MAX_SCALE_UP_VALUE / m_numObjectsToAbsorb;
            
            // For each object to be sucked in
            for (i = 0; i < objectsToTween.length; i++)
            {
                var objectToTween:DisplayObject = objectsToTween[i];
                
                // assign a random y offset to reposition the items
                // so as to create more variance in the absorbtion motion
                
                // Assign a random rotation direction to each group
                var rotationDegrees:Number = (Math.random() * 360);
                
                // Identify the global target x,y and for each group identify the global position
                // This will give us the proper offsets per object
                var globalCoordinatesOfObject:Point = objectToTween.parent.localToGlobal(new Point(objectToTween.x, objectToTween.y));
                
                var xToShift:Number = globalCoordinatesOfDefinition.x - globalCoordinatesOfObject.x;
                var yToShift:Number = globalCoordinatesOfDefinition.y - globalCoordinatesOfObject.y;
                const duration:Number = Math.log(Math.abs(xToShift)) / 10;
                var objectTween:GTween = new GTween(
                    objectToTween,
                    duration,
                    {
                        rotation:rotationDegrees,
                        x:objectToTween.x + xToShift,
                        y:objectToTween.y + yToShift,
                        scaleX:0.3,
                        scaleY:0.3
                    },
                    {
                        onComplete:onObjectTweenComplete
                    }
                );
            }
        }
        
        private function onObjectTweenComplete(tween:GTween):void
        {
            var targetObject:DisplayObject = tween.target as DisplayObject;
            targetObject.visible = false;
            m_numObjectsToAbsorb--;
            
            // After each object is absorbed, we increase the size of the object
            // up to some fix maximum size
            var definitionWidget:BaseTermWidget = m_rootEquationWidget.leftChildWidget;
            definitionWidget.scaleX += m_amountToScaleUpBy;
            definitionWidget.scaleY += m_amountToScaleUpBy;
            
            // After all objects have been absorbed we shift the widget over so as to properly
            // center it on the mouse
            if (m_numObjectsToAbsorb == 0)
            {
                if (m_finishCallback != null)
                {
                    m_finishCallback(this);
                }
                
            }
        }
    }
}