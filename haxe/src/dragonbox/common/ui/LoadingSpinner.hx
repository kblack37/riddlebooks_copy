package dragonbox.common.ui;


import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.TimerEvent;
import flash.utils.Timer;

/**
 * The spinning object for the loader. Just to give an animation
 * for the user to view when something is loading.
 */
class LoadingSpinner extends Sprite
{
    private var m_spinnerColor : Int;
    private var m_outlineColor : Int;
    private var m_tickSlices : Int;
    private var m_radius : Int;
    private var m_spinTimer : Timer;
    
    public function new(slices : Int = 12,
            radius : Int = 6,
            fillColor : Int = 0xff0000,
            outLineColor : Int = 0xff0000)
    {
        super();
        m_spinnerColor = fillColor;
        m_outlineColor = outLineColor;
        
        m_tickSlices = slices;
        m_radius = radius;
        draw();
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
    }
    
    public function setXY(x : Int, y : Int) : Void
    {
        this.x = x;
        this.y = y;
    }
    
    public function dispose() : Void
    {
        if (m_spinTimer != null) 
        {
            onRemovedFromStage(null);
        }
        removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
    }
    
    private function onAddedToStage(event : Event) : Void
    {
        m_spinTimer = new Timer(65);
        m_spinTimer.addEventListener(TimerEvent.TIMER, onTimer, false, 0, true);
        m_spinTimer.start();
    }
    
    private function onRemovedFromStage(event : Event) : Void
    {
        m_spinTimer.reset();
        m_spinTimer.removeEventListener(TimerEvent.TIMER, onTimer);
        m_spinTimer = null;
    }
    
    private function onTimer(event : TimerEvent) : Void
    {
        rotation = (rotation + (360 / m_tickSlices)) % 360;
    }
    
    private function draw() : Void
    {
        var i : Int = m_tickSlices;
        var degrees : Int = 360 / m_tickSlices;
        while (i--)
        {
            var slice : Shape = getSlice();
            slice.alpha = Math.max(0.2, 1 - (0.1 * i));
            var radianAngle : Float = (degrees * i) * Math.PI / 180;
            slice.rotation = -degrees * i;
            slice.x = Math.sin(radianAngle) * m_radius;
            slice.y = Math.cos(radianAngle) * m_radius;
            addChild(slice);
        }
    }
    
    private function getSlice() : Shape
    {
        var slice : Shape = new Shape();
        slice.graphics.lineStyle(2, m_outlineColor);
        slice.graphics.beginFill(m_spinnerColor);
        slice.graphics.drawRoundRect(-1, 0, 5, m_radius, 12, 12);
        slice.graphics.endFill();
        return slice;
    }
}
