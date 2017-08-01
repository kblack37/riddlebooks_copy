package wordproblem.scripts.layering;


import flash.geom.Point;

import dragonbox.common.ui.MouseState;

import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;

import wordproblem.display.Layer;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.ScriptStatus;

/**
 * The layering script simply provides a way to disable and enable display objects
 * that lie beneath another in the display tree.
 */
class Layering extends ScriptNode
{
    /**
     * Buffer to hold the layers
     */
    private var m_layers : Array<Layer>;
    
    /**
     * The root display from which to check layers on top of
     */
    private var m_baseLayer : DisplayObjectContainer;
    
    /**
     * Need to detect clicks on the main layer
     */
    private var m_mouseState : MouseState;
    
    /**
     * Buffer to hold mouse point click positions
     */
    private var m_mousePoint : Point;
    
    /**
     * Buffer to hold result of translating point to local coordinates of a layer
     */
    private var m_resultPoint : Point;
    
    public function new(baseLayer : DisplayObjectContainer, mouseState : MouseState)
    {
        super("Layering");
        
        m_layers = new Array<Layer>();
        m_mousePoint = new Point();
        m_resultPoint = new Point();
        m_baseLayer = baseLayer;
        m_mouseState = mouseState;
    }
    
    override public function visit() : Int
    {
		m_layers = new Array<Layer>();
        this.getOrderedLayerList(m_baseLayer, m_layers);
        
        m_mousePoint.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
        
        // Iterate through the set of selected layers and set whether the mouse has hit it
        // Note that the layer at the lower index is actually higher on the display list
        var numLayers : Int = m_layers.length;
        var layer : Layer = null;
        var i : Int = 0;
        var blockLayers : Bool = false;
        for (i in 0...numLayers){
            layer = m_layers[i];
            
            if (!blockLayers) 
            {
                layer.activeForFrame = true;
                layer.globalToLocal(m_mousePoint, m_resultPoint);
                if (layer.hitTest(m_resultPoint) != null) 
                {
                    blockLayers = true;
                }
            }
            else 
            {
                layer.activeForFrame = false;
            }
        }
        
        return ScriptStatus.SUCCESS;
    }
    
    /**
     * 
     * @param outLayers
     *      The layers closer to the top are earlier in the list.
     */
    private function getOrderedLayerList(object : DisplayObject,
            outLayers : Array<Layer>) : Void
    {
        // Examine potential children layers first, they are on top
        // anyways
        if (Std.is(object, DisplayObjectContainer)) 
        {
            var container : DisplayObjectContainer = try cast(object, DisplayObjectContainer) catch(e:Dynamic) null;
            var numChildren : Int = container.numChildren;
            var i : Int = 0;
            i = numChildren - 1;
            while (i >= 0){
                getOrderedLayerList(container.getChildAt(i), outLayers);
                i--;
            }
        }
        
        if (Std.is(object, Layer)) 
        {
            outLayers.push(try cast(object, Layer) catch(e:Dynamic) null);
        }
    }
}
