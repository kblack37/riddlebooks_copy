package dragonbox.common.system
{
    import flash.geom.Rectangle;

    public class RectanglePool
    {
        private var m_pool:Vector.<Rectangle>;
        
        public function RectanglePool()
        {
            m_pool = new Vector.<Rectangle>();
        }
        
        public function returnRectangles(rectangles:Vector.<Rectangle>):void
        {
            while (rectangles.length > 0)
            {
                m_pool.push(rectangles.pop());
            }
        }
        
        public function returnRectangle(rectangle:Rectangle):void
        {
            m_pool.push(rectangle);
        }
        
        public function getRectangle():Rectangle
        {
            if (m_pool.length == 0)
            {
                m_pool.push(new Rectangle());
            }
            
            var rectangle:Rectangle = m_pool.pop(); 
            rectangle.setTo(0, 0, 0, 0);
            return rectangle;
        }
    }
}