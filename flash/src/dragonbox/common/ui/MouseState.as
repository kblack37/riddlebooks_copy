package dragonbox.common.ui
{
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	
	import dragonbox.common.dispose.IDisposable;
	
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	public class MouseState implements IDisposable
	{		
		/**
		 * Did the player press the mouse down at the very start of this frame
		 */
		public var leftMousePressedThisFrame:Boolean;
		public var leftMouseDown:Boolean;
		public var leftMouseReleasedThisFrame:Boolean;
		public var leftMouseMovedThisFrame:Boolean;
        
        /**
         * A drag occurs ONLY if the mouse has moved since the last frame
         */
		public var leftMouseDraggedThisFrame:Boolean;
		
        /**
         * The object that dispatched the touch event.
         * This is useful for the situations where we want to see the lowest level object
         * that was attached to the mouse at a given frame, i.e. during a press we want to
         * check whether the press was over something that was a button.
         */
        public var target:starling.events.EventDispatcher;
        
		public var mousePositionLastFrame:Vector3D = new Vector3D();
		public var mousePositionThisFrame:Vector3D = new Vector3D();
		public var mouseDeltaThisFrame:Vector3D = new Vector3D();
        public var mouseWheelDeltaThisFrame:int;
		
        /**
         * Binding to starling events
         */
		private var binding:starling.events.EventDispatcher;
        
        /**
         * Binding to flash events that are not handled by starling.
         */
        private var nativeFlashBinding:flash.events.EventDispatcher;
		
		public function MouseState(binding:starling.events.EventDispatcher, 
                                   nativeFlashDispatcher:flash.events.EventDispatcher)
		{
            this.nativeFlashBinding = nativeFlashDispatcher;
			bind(binding);
		}
		
		public function bind(binding:starling.events.EventDispatcher):void
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
		
		public function dispose():void
		{
			if (this.binding != null)
			{
                this.binding.removeEventListener(TouchEvent.TOUCH, onTouch);
                this.nativeFlashBinding.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			}
		}
        
        public function onEnterFrame(e:Event=null):void
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
		
        private function onMouseWheel(e:MouseEvent):void
        {
            this.mouseWheelDeltaThisFrame = e.delta;
        }
        
        private function onTouch(event:TouchEvent):void
        {
            const touches:Vector.<Touch> = event.touches;
            const touchCount:int = touches.length;
            
            // Touches exceeds one only if multiple pressure points have been detected
            // On a touch-screen device this would be multiple fingers
            if (touchCount == 1)
            {
                this.target = event.target;
                
                const touch:Touch = touches[0];
                const touchPhase:String = touch.phase;
                const x:Number = touch.globalX;
                const y:Number = touch.globalY;
                this.mousePositionThisFrame.x = x;
                this.mousePositionThisFrame.y = y;
                
                const prevX:Number = touch.previousGlobalX;
                const prevY:Number = touch.previousGlobalY;
                this.mousePositionLastFrame.x = prevX;
                this.mousePositionLastFrame.y = prevY;
                
                this.mouseDeltaThisFrame.x = x - prevX;
                this.mouseDeltaThisFrame.y = y - prevY;
                
                // User moves without pressing down
                if (touchPhase == TouchPhase.HOVER)
                {
                    this.leftMouseMovedThisFrame = true
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
                {
                }
            }
        }
	}
}