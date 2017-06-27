package dragonbox.common.ui
{
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    
    /**
     * The spinning object for the loader. Just to give an animation
     * for the user to view when something is loading.
     */
    public class LoadingSpinner extends Sprite
    {
        private var m_spinnerColor:uint;
        private var m_outlineColor:uint;
        private var m_tickSlices:int;
        private var m_radius:int;
        private var m_spinTimer:Timer;
        
        public function LoadingSpinner(slices:int = 12, 
                                       radius:int = 6, 
                                       fillColor:uint = 0xff0000, 
                                       outLineColor:uint = 0xff0000)
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
        
        public function setXY(x:int, y:int):void
        {
            this.x = x;
            this.y = y;
        }
        
        public function dispose():void
        {
            if (m_spinTimer != null)
            {
                onRemovedFromStage(null);
            }
            removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
        }
        
        private function onAddedToStage(event:Event):void
        {
            m_spinTimer = new Timer(65);
            m_spinTimer.addEventListener(TimerEvent.TIMER, onTimer, false, 0, true);
            m_spinTimer.start();
        }
        
        private function onRemovedFromStage(event:Event):void
        {
            m_spinTimer.reset();
            m_spinTimer.removeEventListener(TimerEvent.TIMER, onTimer);
            m_spinTimer = null;
        }
        
        private function onTimer(event:TimerEvent):void
        {
            rotation = (rotation + (360 / m_tickSlices)) % 360;
        }
        
        private function draw():void
        {
            var i:int = m_tickSlices;
            var degrees:int = 360 / m_tickSlices;
            while (i--)
            {
                var slice:Shape = getSlice();
                slice.alpha = Math.max(0.2, 1 - (0.1 * i));
                var radianAngle:Number = (degrees * i) * Math.PI / 180;
                slice.rotation = -degrees * i;
                slice.x = Math.sin(radianAngle) * m_radius;
                slice.y = Math.cos(radianAngle) * m_radius;
                addChild(slice);
            }
        }
        
        private function getSlice():Shape
        {
            var slice:Shape = new Shape();
            slice.graphics.lineStyle(2, m_outlineColor);
            slice.graphics.beginFill(m_spinnerColor);
            slice.graphics.drawRoundRect(-1, 0, 5, m_radius, 12, 12);
            slice.graphics.endFill();
            return slice;
        }
    }
}