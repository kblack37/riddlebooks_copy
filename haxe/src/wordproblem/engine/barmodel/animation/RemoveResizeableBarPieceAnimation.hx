package wordproblem.engine.barmodel.animation;

import haxe.Constraints.Function;

import motion.Actuate;

import wordproblem.engine.barmodel.view.ResizeableBarPieceView;

class RemoveResizeableBarPieceAnimation
{
    private var m_endPixelLength : Float = 40;
    
    private var m_onComplete : Function;
    
    public function new(onComplete : Function)
    {
        m_onComplete = onComplete;
    }
    
    public function play(resizeableBarView : ResizeableBarPieceView) : Void
    {
        // Figure out how many pixels it will take to go from the current length to a new minimum
        var shrinkVelocityPixelPerSecond = Math.max(1200, (resizeableBarView.pixelLength - m_endPixelLength) / 0.5);
		
		var duration : Float = (resizeableBarView.pixelLength - m_endPixelLength) / shrinkVelocityPixelPerSecond;
		Actuate.update(resizeableBarView.resizeToLength, duration, [resizeableBarView.pixelLength], [m_endPixelLength]).onComplete(function() {
			Actuate.tween(resizeableBarView, 0.7, { rotation: 180, alpha: 0, y: resizeableBarView.y + 300 }).smartRotation().onComplete(m_onComplete);
		});
    }
}
