package wordproblem.engine.expression.widget.manager
{
	import flash.geom.Point;
	
	import dragonbox.common.ui.MouseState;
	
	import starling.display.Image;
	import starling.textures.RenderTexture;
	import starling.textures.Texture;
	import wordproblem.resource.AssetManager
	
	import wordproblem.engine.expression.widget.ExpressionTreeWidget;
	import wordproblem.engine.expression.widget.term.BaseTermWidget;

	/**
	 * Note that the manager currently has no knowledge of whether the widgets marked
	 * for cancellation can actually be cancelled.
	 * 
	 * Whatever object contains the manager will poll
	 */
	public class CancelManager
	{
		/**
		 * Flag to indicate whether the user completed a stroke of the cancel
		 * pen.
         * 
         * Accepts param of this object
		 */
		private var m_strokeFinishedCallback:Function;
		
        /**
         * The texture to use for a single stroke
         */
        private var m_strokeTexture:Texture;
        
		/**
		 * Flag to indicate whether the player had started a stroked with the cancel pen
		 */
		private var m_startedStroke:Boolean;
		
		/**
		 * The canvas and widgets the cancellations will operate on.
		 */
		private var m_treeWidget:ExpressionTreeWidget;
		
		/**
		 * A layer pasted just above the widgets where we will paint the cancellation strokes
         * 
         * Use render texture and rotate a series of quads in order to draw contiguous lines
		 */
		private var m_cancellationCanvas:Image;
		private var m_renderTexture:RenderTexture;
        
		/**
		 * A purely internal buffer that keeps track of all the widgets that
         * have been moused over
		 */
		private var m_markedForCancelBuffer:Vector.<BaseTermWidget>;
        
        private var m_previousMouseDragPoint:Point;
        private var m_previousMouseDragLocalPoint:Point;
		
		public function CancelManager(treeWidget:ExpressionTreeWidget,
                                      assetManager:AssetManager,
                                      strokeFinishedCallback:Function)
		{
			m_treeWidget = treeWidget;
            m_strokeTexture = assetManager.getTexture("brush_circle");
            
            m_renderTexture = new RenderTexture(treeWidget.getConstraintsWidth(), treeWidget.getConstraintsHeight());
			m_cancellationCanvas = new Image(m_renderTexture);
            
			m_markedForCancelBuffer = new Vector.<BaseTermWidget>();
			m_strokeFinishedCallback = strokeFinishedCallback;
		}
		
		public function getWidgetsMarkedForCancel():Vector.<BaseTermWidget>
		{
			return m_markedForCancelBuffer;
		}
		
		/**
		 * Clean all the data related to a cancellation
		 */
		public function clear():void
		{
			for each (var markedWidget:BaseTermWidget in m_markedForCancelBuffer)
			{
				markedWidget.alpha = 1.0;
			}
			
			m_startedStroke = false;
			m_markedForCancelBuffer.length = 0;
            
            m_renderTexture.clear();
		}
		
		public function update(mouseState:MouseState):void
		{
			if (m_cancellationCanvas.parent == null && m_treeWidget.parent != null)
			{
				m_cancellationCanvas.x = m_treeWidget.x;
				m_cancellationCanvas.y = m_treeWidget.y;
				m_treeWidget.parent.addChild(m_cancellationCanvas);
			}
			
			// Check that the mouse in within the bounds of the widget
			var mousePoint:Point = new Point(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
			if (m_treeWidget.hitTest(m_treeWidget.globalToLocal(new Point(mousePoint.x, mousePoint.y))))
			{
                var localPoint:Point = m_cancellationCanvas.globalToLocal(mousePoint);
				// If mouse in within the bounds then cancellation activities may be valid
				if (mouseState.leftMousePressedThisFrame)
				{
                    // See if there is a widget underneath this point
                    m_previousMouseDragPoint = mousePoint;
                    m_previousMouseDragLocalPoint = localPoint;
                    
					m_startedStroke = true;
				}
				else if (mouseState.leftMouseDraggedThisFrame && m_startedStroke)
				{
                    // Calculate the length of the line to draw and the angle from the horizontal
                    const deltaX:Number = localPoint.x - m_previousMouseDragLocalPoint.x;
                    const deltaY:Number = localPoint.y - m_previousMouseDragLocalPoint.y;
                    const length:Number = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
                    const angle:Number = Math.atan2(deltaY, deltaX);
                    const thickness:Number = 5;
                    const tempImage:Image = new Image(m_strokeTexture);
                    tempImage.width = Math.max(m_strokeTexture.width, length);
                    tempImage.pivotY = m_strokeTexture.height * 0.5;
                    tempImage.rotation = angle;
                    tempImage.x = m_previousMouseDragLocalPoint.x;
                    tempImage.y = m_previousMouseDragLocalPoint.y;
                    m_renderTexture.draw(tempImage);
                    
                    m_previousMouseDragLocalPoint = localPoint;
					
					// Grab widgets intersecting with the line segment and them to the buffer if they haven't already
					// been added there
                    var widgetsPicked:Vector.<BaseTermWidget> = new Vector.<BaseTermWidget>();
                    m_treeWidget.pickLeafWidgetsFromSegment(m_previousMouseDragPoint, mousePoint, widgetsPicked);
                    for each (var pickedWidget:BaseTermWidget in widgetsPicked)
                    {
                        if (m_markedForCancelBuffer.indexOf(pickedWidget) == -1)
                        {
                            pickedWidget.alpha = 0.5;
                            m_markedForCancelBuffer.push(pickedWidget);
                        }
                    }
                    
                    m_previousMouseDragPoint = mousePoint;
					
				}
				else if (mouseState.leftMouseReleasedThisFrame && m_startedStroke)
				{
                    
                    m_strokeFinishedCallback(this);
				}
			}
			else
			{
				// If the mouse is outside the bound we automatically clear out the graphics
				this.clear();
			}
		}
	}
}