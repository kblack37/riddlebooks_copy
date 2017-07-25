package wordproblem.hints.tips.util;


import flash.geom.Point;

import dragonbox.common.dispose.IDisposable;
import dragonbox.common.ui.MouseState;
import dragonbox.common.util.XColor;

import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.textures.Texture;

import wordproblem.engine.animation.RingPulseAnimation;
import wordproblem.resource.AssetManager;

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
    private var m_pulseAnimation : RingPulseAnimation;
    
    public function new(mouseState : MouseState,
            canvas : DisplayObjectContainer,
            assetManager : AssetManager)
    {
        m_mouseState = mouseState;
        m_canvas = canvas;
        
        var cursorTexture : Texture = assetManager.getTexture("custom_cursor");
        m_cursor = new Image(cursorTexture);
        
        m_globalBuffer = new Point();
        m_localBuffer = new Point();
        
        m_pulseAnimation = new RingPulseAnimation(assetManager.getTexture("ring"), onPulseComplete);
    }
    
    public function dispose() : Void
    {
        m_cursor.removeFromParent(true);
        Starling.current.juggler.remove(m_pulseAnimation);
        m_pulseAnimation.dispose();
    }
    
    public function hide() : Void
    {
        m_cursor.removeFromParent();
        Starling.current.juggler.remove(m_pulseAnimation);
        m_pulseAnimation.dispose();
    }
    
    public function update() : Void
    {
        // Mouse state is in global coordinates (relative to the main stage)
        // The cursor is part of the canvas, which may have a different frame of
        // reference. Convert the global coordinates to the canvas space
        m_globalBuffer.x = m_mouseState.mousePositionThisFrame.x;
        m_globalBuffer.y = m_mouseState.mousePositionThisFrame.y;
        m_canvas.globalToLocal(m_globalBuffer, m_localBuffer);
        
        m_cursor.x = m_localBuffer.x;
        m_cursor.y = m_localBuffer.y;
        
        // Add pulses to indicate press and release
        if (m_mouseState.leftMousePressedThisFrame) 
        {
            m_pulseAnimation.reset(m_localBuffer.x, m_localBuffer.y, m_canvas, XColor.BRIGHT_ORANGE);
            Starling.current.juggler.add(m_pulseAnimation);
        }  // Must make sure the cursor graphic stays on top  
        
        
        
        m_canvas.addChild(m_cursor);
    }
    
    private function onPulseComplete() : Void
    {
        Starling.current.juggler.remove(m_pulseAnimation);
    }
}
