package wordproblem.engine.animation;


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
class PackingAnimation
{
    private var m_rootEquationWidget : BaseTermWidget;
    private var m_vectorSpace : IVectorSpace;
    
    public static var MAX_SCALE_UP_VALUE : Float = 0.25;
    private var m_amountToScaleUpBy : Float;
    private var m_numObjectsToAbsorb : Int;
    
    private var m_finishCallback : Function;
    
    public function new()
    {
    }
    
    public function play(rootEquationWidget : BaseTermWidget,
            vectorSpace : IVectorSpace,
            finishCallback : Function) : Void
    {
        m_rootEquationWidget = rootEquationWidget;
        m_vectorSpace = vectorSpace;
        m_finishCallback = finishCallback;
        
        // Look at the root widget
        var rootNode : ExpressionNode = m_rootEquationWidget.getNode();
        
        // Get every group of terms that move in unison
        var outNodes : Array<ExpressionNode> = new Array<ExpressionNode>();
        var objectsToTween : Array<DisplayObject> = new Array<DisplayObject>();
        var additionNodeIdsProcessed : Dictionary = new Dictionary();
        ExpressionUtil.getCommutativeGroupRoots(
                rootNode.right,
                m_vectorSpace.getAdditionOperator(),
                outNodes);
        for (i in 0...outNodes.length){
            var additionGroupNode : ExpressionNode = outNodes[i];
            var additionGroupWidget : BaseTermWidget = ExpressionTreeWidget.getWidgetFromId(additionGroupNode.id, m_rootEquationWidget);
            objectsToTween.push(additionGroupWidget);
            
            // Grab reference to the addition graphics
            var parentNode : ExpressionNode = additionGroupWidget.parentWidget.getNode();
            if (parentNode.isSpecificOperator(m_vectorSpace.getAdditionOperator()) &&
                !additionNodeIdsProcessed.exists(parentNode.id)) 
            {
                var additionWidget : GroupTermWidget = try cast(additionGroupWidget.parentWidget, GroupTermWidget) catch(e:Dynamic) null;
                objectsToTween.push(additionWidget.groupImage);
                additionNodeIdsProcessed[parentNode.id] = true;
            }
        }  // Grab reference to the equals graphic  
        
        
        
        var equalsWidget : GroupTermWidget = try cast(m_rootEquationWidget, GroupTermWidget) catch(e:Dynamic) null;
        var definitionWidget : BaseTermWidget = equalsWidget.leftChildWidget;
        var globalCoordinatesOfDefinition : Point = definitionWidget.localToGlobal(new Point(0, 0));
        var globalCoordinatesOfEqual : Point = equalsWidget.localToGlobal(new Point(0, 0));
        objectsToTween.push(equalsWidget.groupImage);
        
        // Shift the widget over so that the center of the definition variable goes where
        // the center of the equals operator was
        var xToShiftDefinition : Float = globalCoordinatesOfEqual.x - globalCoordinatesOfDefinition.x;
        globalCoordinatesOfDefinition.x += xToShiftDefinition;
        definitionWidget.x += xToShiftDefinition;
        
        m_numObjectsToAbsorb = objectsToTween.length;
        m_amountToScaleUpBy = MAX_SCALE_UP_VALUE / m_numObjectsToAbsorb;
        
        // For each object to be sucked in
        for (i in 0...objectsToTween.length){
            var objectToTween : DisplayObject = objectsToTween[i];
            
            // assign a random y offset to reposition the items
            // so as to create more variance in the absorbtion motion
            
            // Assign a random rotation direction to each group
            var rotationDegrees : Float = (Math.random() * 360);
            
            // Identify the global target x,y and for each group identify the global position
            // This will give us the proper offsets per object
            var globalCoordinatesOfObject : Point = objectToTween.parent.localToGlobal(new Point(objectToTween.x, objectToTween.y));
            
            var xToShift : Float = globalCoordinatesOfDefinition.x - globalCoordinatesOfObject.x;
            var yToShift : Float = globalCoordinatesOfDefinition.y - globalCoordinatesOfObject.y;
            var duration : Float = Math.log(Math.abs(xToShift)) / 10;
            var objectTween : GTween = new GTween(
            objectToTween, 
            duration, 
            {
                rotation : rotationDegrees,
                x : objectToTween.x + xToShift,
                y : objectToTween.y + yToShift,
                scaleX : 0.3,
                scaleY : 0.3,

            }, 
            {
                onComplete : onObjectTweenComplete

            }, 
            );
        }
    }
    
    private function onObjectTweenComplete(tween : GTween) : Void
    {
        var targetObject : DisplayObject = try cast(tween.target, DisplayObject) catch(e:Dynamic) null;
        targetObject.visible = false;
        m_numObjectsToAbsorb--;
        
        // After each object is absorbed, we increase the size of the object
        // up to some fix maximum size
        var definitionWidget : BaseTermWidget = m_rootEquationWidget.leftChildWidget;
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
