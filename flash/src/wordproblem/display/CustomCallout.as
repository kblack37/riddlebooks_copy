package wordproblem.display
{
    import flash.geom.Point;
    
    import feathers.controls.Callout;
    
    /**
     * Extend the functionality of the feathers callout class mainly to add the ability to add an offset
     */
    public class CustomCallout extends Callout
    {
        public var xOffset:Number;
        public var yOffset:Number;
        
        public var closeOnTouchBeganInside:Boolean;
        
        private var m_positionWithoutOffset:Point;
        
        public function CustomCallout()
        {
            super();
            
            xOffset = 0;
            yOffset = 0;
            this.closeOnTouchBeganInside = false;
            
            m_positionWithoutOffset = new Point();
        }
        
        override protected function positionToOrigin():void
        {
            // Before positioning, reset this callout to its unmodified coordinates
            // This is to prevent the offset being re-added multiple times
            this.x = m_positionWithoutOffset.x;
            this.y = m_positionWithoutOffset.y;
            
            super.positionToOrigin();
            
            m_positionWithoutOffset.setTo(this.x, this.y);
            this.x = m_positionWithoutOffset.x + xOffset;
            this.y = m_positionWithoutOffset.y + yOffset;
        }
    }
}