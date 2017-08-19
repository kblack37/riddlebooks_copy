package dragonbox.common.ui;


import openfl.events.EventDispatcher;
import openfl.events.MouseEvent;
import openfl.geom.Vector3D;

import dragonbox.common.dispose.IDisposable;

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
     * Binding to flash events that are not handled by starling.
     */
    private var binding : EventDispatcher;
    
    public function new(binding : EventDispatcher)
    {
		bind(binding);
    }
    
    public function bind(binding : EventDispatcher) : Void
    {
        if (this.binding != null) 
        {
			this.binding.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			this.binding.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			this.binding.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            this.binding.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
        }
        
        this.binding = binding;
        if (this.binding != null) 
        {
			this.binding.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			this.binding.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			this.binding.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            this.binding.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
        }
    }
    
    public function dispose() : Void
    {
        if (this.binding != null) 
        {
			this.binding.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			this.binding.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			this.binding.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            this.binding.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
        }
    }
    
    public function onEnterFrame(e : Dynamic) : Void
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
    
    private function onMouseWheel(event : Dynamic) : Void
    {
        this.mouseWheelDeltaThisFrame = cast(event, MouseEvent).delta;
    }
	
	private function onMouseDown(event : Dynamic) {
		trace(mousePositionThisFrame.x + ", " + mousePositionThisFrame.y);
		this.leftMousePressedThisFrame = true;
		this.leftMouseDown = true;
	}
	
	private function onMouseUp(event : Dynamic) {
		this.leftMouseReleasedThisFrame = true;
		this.leftMouseDraggedThisFrame = false;
		this.leftMouseDown = false;
	}
	
	private function onMouseMove(event : Dynamic) {
		var mouseEvent : MouseEvent = try cast(event, MouseEvent) catch (e : Dynamic) null;
		
		var prevX = mousePositionLastFrame.x = mousePositionThisFrame.x;
		var prevY = mousePositionLastFrame.y = mousePositionThisFrame.y;
		
		var x : Float = mouseEvent.stageX;
		var y : Float = mouseEvent.stageY;
		this.mousePositionThisFrame.x = x;
		this.mousePositionThisFrame.y = y;
		
		this.mouseDeltaThisFrame.x = x - prevX;
		this.mouseDeltaThisFrame.y = y - prevY;
		
		this.leftMouseMovedThisFrame = true;
		
		if (mouseEvent.buttonDown) {
			this.leftMouseDown = true;
			this.leftMouseDraggedThisFrame = true;
		}
	}
}
