package wordproblem.scripts.layering
{
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
    public class Layering extends ScriptNode
    {
        /**
         * Buffer to hold the layers
         */
        private var m_layers:Vector.<Layer>;
        
        /**
         * The root display from which to check layers on top of
         */
        private var m_baseLayer:DisplayObjectContainer;
        
        /**
         * Need to detect clicks on the main layer
         */
        private var m_mouseState:MouseState;
        
        /**
         * Buffer to hold mouse point click positions
         */
        private var m_mousePoint:Point;
        
        /**
         * Buffer to hold result of translating point to local coordinates of a layer
         */
        private var m_resultPoint:Point;
        
        public function Layering(baseLayer:DisplayObjectContainer, mouseState:MouseState)
        {
            super("Layering");
            
            m_layers = new Vector.<Layer>();
            m_mousePoint = new Point();
            m_resultPoint = new Point();
            m_baseLayer = baseLayer;
            m_mouseState = mouseState;
        }
        
        override public function visit():int
        {
            m_layers.length = 0;
            this.getOrderedLayerList(m_baseLayer, m_layers);
            
            m_mousePoint.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
            
            // Iterate through the set of selected layers and set whether the mouse has hit it
            // Note that the layer at the lower index is actually higher on the display list
            var numLayers:int = m_layers.length;
            var layer:Layer;
            var i:int;
            var blockLayers:Boolean = false;
            for (i = 0; i < numLayers; i++)
            {
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
        private function getOrderedLayerList(object:DisplayObject, 
                                             outLayers:Vector.<Layer>):void
        {
            // Examine potential children layers first, they are on top
            // anyways
            if (object is DisplayObjectContainer)
            {
                var container:DisplayObjectContainer = object as DisplayObjectContainer;
                var numChildren:int = container.numChildren;
                var i:int;
                for (i = numChildren - 1; i >= 0; i--)
                {
                    getOrderedLayerList(container.getChildAt(i), outLayers);
                }
            }
            
            if (object is Layer)
            {
                outLayers.push(object as Layer);
            }
        }
    }
}