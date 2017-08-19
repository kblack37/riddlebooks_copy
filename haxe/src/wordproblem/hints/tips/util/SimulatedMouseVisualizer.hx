package wordproblem.hints.tips.util;


import openfl.display.Bitmap;
import openfl.geom.Point;

import dragonbox.common.dispose.IDisposable;
import dragonbox.common.ui.MouseState;
import dragonbox.common.util.XColor;

import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;

//import wordproblem.engine.animation.RingPulseAnimation;
import wordproblem.resource.AssetManager;

// TODO: work out the animation code replacement when more
// basic elements are working
class SimulatedMouseVisualizer implements IDisposable
{
    private var m_mouseState : MouseState;
    private var m_canvas : DisplayObjectContainer;
    
    private var m_cursor : DisplayObject;
    private var m_globalBuffer : Point;
    private var m_localBuffer : Point;
    
    /**
     * Used to indicate presses and releases of the mouse
     */
    //private var m_pulseAnimation : RingPulseAnimation;
    
    public function new(mouseState : MouseState,
            canvas : DisplayObjectContainer,
            assetManager : AssetManager)
    {
        m_mouseState = mouseState;
        m_canvas = canvas;
        
        var cursorBitmapData : BitmapData = assetManager.getBitmapData("custom_cursor");
        m_cursor = new Bitmap(cursorBitmapData);
        
        m_globalBuffer = new Point();
        m_localBuffer = new Point();
        
        //m_pulseAnimation = new RingPulseAnimation(assetManager.getBitmapData("ring"), onPulseComplete);
    }
    
    public function dispose() : Void
    {
		if (m_cursor.parent != null) m_cursor.parent.removeChild(m_cursor);
		m_cursor = null;
        //Starling.current.juggler.remove(m_pulseAnimation);
        //m_pulseAnimation.dispose();
    }
    
    public function hide() : Void
    {
        if (m_cursor.parent != null) m_cursor.parent.removeChild(m_cursor);
        //Starling.current.juggler.remove(m_pulseAnimation);
        //m_pulseAnimation.dispose();
    }
    
    public function update() : Void
    {
        // Mouse state is in global coordinates (relative to the main stage)
        // The cursor is part of the canvas, which may have a different frame of
        // reference. Convert the global coordinates to the canvas space
        m_globalBuffer.x = m_mouseState.mousePositionThisFrame.x;
        m_globalBuffer.y = m_mouseState.mousePositionThisFrame.y;
        m_localBuffer = m_canvas.globalToLocal(m_globalBuffer);
        
        m_cursor.x = m_localBuffer.x;
        m_cursor.y = m_localBuffer.y;
        
        // Add pulses to indicate press and release
        if (m_mouseState.leftMousePressedThisFrame) 
        {
            //m_pulseAnimation.reset(m_localBuffer.x, m_localBuffer.y, m_canvas, XColor.BRIGHT_ORANGE);
            //Starling.current.juggler.add(m_pulseAnimation);
        }  
		
		// Must make sure the cursor graphic stays on top  
        m_canvas.addChild(m_cursor);
    }
    
    private function onPulseComplete() : Void
    {
        //Starling.current.juggler.remove(m_pulseAnimation);
    }
}
