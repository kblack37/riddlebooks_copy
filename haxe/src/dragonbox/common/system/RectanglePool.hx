package dragonbox.common.system;


import flash.geom.Rectangle;

class RectanglePool
{
    private var m_pool : Array<Rectangle>;
    
    public function new()
    {
        m_pool = new Array<Rectangle>();
    }
    
    public function returnRectangles(rectangles : Array<Rectangle>) : Void
    {
        while (rectangles.length > 0)
        {
            m_pool.push(rectangles.pop());
        }
    }
    
    public function returnRectangle(rectangle : Rectangle) : Void
    {
        m_pool.push(rectangle);
    }
    
    public function getRectangle() : Rectangle
    {
        if (m_pool.length == 0) 
        {
            m_pool.push(new Rectangle());
        }
        
        var rectangle : Rectangle = m_pool.pop();
        rectangle.setTo(0, 0, 0, 0);
        return rectangle;
    }
}
