package wordproblem.engine.barmodel.animation
{
    import starling.animation.IAnimatable;
    import starling.animation.Tween;
    import starling.core.Starling;
    
    import wordproblem.engine.barmodel.view.ResizeableBarPieceView;
    
    public class RemoveResizeableBarPieceAnimation implements IAnimatable
    {
        private var m_shrinkVelocityPixelPerSecond:Number;
        private var m_endPixelLength:Number = 40;
        private var m_barPieceViewToRemove:ResizeableBarPieceView;
        
        private var m_onComplete:Function;
        
        private var m_fallTween:Tween;
        
        public function RemoveResizeableBarPieceAnimation(onComplete:Function)
        {
            m_onComplete = onComplete;
        }
        
        public function advanceTime(time:Number):void
        {
            // Gradually shrink the label
            if (m_barPieceViewToRemove.pixelLength > m_endPixelLength)
            {
                var pixelDelta:Number = time * m_shrinkVelocityPixelPerSecond;
                var newLength:Number = Math.max(m_barPieceViewToRemove.pixelLength - pixelDelta, m_endPixelLength);
                m_barPieceViewToRemove.resizeToLength(newLength);
            }
            else 
            {
                m_fallTween.advanceTime(time);
            }
        }
        
        public function play(resizeableBarView:ResizeableBarPieceView):void
        {
            // Figure out how many pixels it will take to go from the current length to a new minimum
            m_shrinkVelocityPixelPerSecond = Math.max(1200, (resizeableBarView.pixelLength - m_endPixelLength) / 0.5);
            m_barPieceViewToRemove = resizeableBarView;
            Starling.juggler.add(this);
            
            var thisAnimation:IAnimatable = this;
            m_fallTween = new Tween(m_barPieceViewToRemove, 0.7);
            m_fallTween.animate("rotation", Math.PI);
            m_fallTween.animate("alpha", 0.0);
            m_fallTween.animate("y", m_barPieceViewToRemove.y + 300);
            m_fallTween.onComplete = function():void
            {
                Starling.juggler.remove(thisAnimation);
                if (m_onComplete != null)
                {
                    m_onComplete();
                }
            }
        }
    }
}