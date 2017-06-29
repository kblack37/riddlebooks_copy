package dragonbox.common.ui;


import flash.events.EventDispatcher;
import flash.events.MouseEvent;
import flash.geom.Vector3D;

import dragonbox.common.dispose.IDisposable;

import starling.events.Event;
import starling.events.EventDispatcher;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;

class MouseState implements IDisposable
{
    /**
		 * Did the player press the mouse down at the very start of this frame
		 */
    public var leftMousePressedThisFrame : Bool;
    public var leftMouseDown : Bool;
    public var leftMouseReleasedThisFrame : Bool;
    public var leftMouseMovedThisFrame : Bool;
    
    /**
     * A drag occurs ONLY if the mouse has moved since the last frame
     */
    public var leftMouseDraggedThisFrame : Bool;
    
    /**
     * The object that dispatched the touch event.
     * This is useful for the situations where we want to see the lowest level object
     * that was attached to the mouse at a given frame, i.e. during a press we want to
     * check whether the press was over something that was a button.
     */
    public var target : starling.events.EventDispatcher;
    
    public var mousePositionLastFrame : Vector3D = new Vector3D();
    public var mousePositionThisFrame : Vector3D = new Vector3D();
    public var mouseDeltaThisFrame : Vector3D = new Vector3D();
    public var mouseWheelDeltaThisFrame : Int;
    
    /**
     * Binding to starling events
     */
    private var binding : starling.events.EventDispatcher;
    
    /**
     * Binding to flash events that are not handled by starling.
     */
    private var nativeFlashBinding : flash.events.EventDispatcher;
    
    public function new(binding : starling.events.EventDispatcher,
            nativeFlashDispatcher : flash.events.EventDispatcher)
    {
        this.nativeFlashBinding = nativeFlashDispatcher;
        bind(binding);
    }
    
    public function bind(binding : starling.events.EventDispatcher) : Void
    {
        if (this.binding != null) 
        {
            this.binding.removeEventListener(TouchEvent.TOUCH, onTouch);
            this.nativeFlashBinding.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
        }
        
        this.binding = binding;
        if (this.binding != null) 
        {
            this.binding.addEventListener(TouchEvent.TOUCH, onTouch);
            this.nativeFlashBinding.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
        }
    }
    
    public function dispose() : Void
    {
        if (this.binding != null) 
        {
            this.binding.removeEventListener(TouchEvent.TOUCH, onTouch);
            this.nativeFlashBinding.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
        }
    }
    
    public function onEnterFrame(e : Event = null) : Void
    {
        // For some reason the mouse state values are being reset before
        // any other part of the application can read them in, thus the we need
        // to now have the game loop reset the values
        this.leftMouseMovedThisFrame = false;
        this.leftMousePressedThisFrame = false;
        this.leftMouseReleasedThisFrame = false;
        this.leftMouseDraggedThisFrame = false;
        this.mouseDeltaThisFrame.x = 0;
        this.mouseDeltaThisFrame.y = 0;
        this.mouseWheelDeltaThisFrame = 0;
    }
    
    private function onMouseWheel(e : MouseEvent) : Void
    {
        this.mouseWheelDeltaThisFrame = e.delta;
    }
    
    private function onTouch(event : TouchEvent) : Void
    {
        var touches : Array<Touch> = event.touches;
        var touchCount : Int = touches.length;
        
        // Touches exceeds one only if multiple pressure points have been detected
        // On a touch-screen device this would be multiple fingers
        if (touchCount == 1) 
        {
            this.target = event.target;
            
            var touch : Touch = touches[0];
            var touchPhase : String = touch.phase;
            var x : Float = touch.globalX;
            var y : Float = touch.globalY;
            this.mousePositionThisFrame.x = x;
            this.mousePositionThisFrame.y = y;
            
            var prevX : Float = touch.previousGlobalX;
            var prevY : Float = touch.previousGlobalY;
            this.mousePositionLastFrame.x = prevX;
            this.mousePositionLastFrame.y = prevY;
            
            this.mouseDeltaThisFrame.x = x - prevX;
            this.mouseDeltaThisFrame.y = y - prevY;
            
            // User moves without pressing down
            if (touchPhase == TouchPhase.HOVER) 
            {
                this.leftMouseMovedThisFrame = true;
            }
            // User moves while still pressing down
            else if (touchPhase == TouchPhase.MOVED) 
            {
                this.leftMouseDown = true;
                this.leftMouseMovedThisFrame = true;
                this.leftMouseDraggedThisFrame = true;
            }
            // User pressed down
            else if (touchPhase == TouchPhase.BEGAN) 
            {
                this.leftMousePressedThisFrame = true;
                this.leftMouseDown = true;
            }
            // User released a press
            else if (touchPhase == TouchPhase.ENDED) 
            {
                this.leftMouseReleasedThisFrame = true;
                this.leftMouseDraggedThisFrame = false;
                this.leftMouseDown = false;
            }
            else if (touchPhase == TouchPhase.STATIONARY) 
                { }
        }
    }
}
