package wordproblem.engine.barmodel.view
{
    import flash.geom.Rectangle;
    
    import dragonbox.common.dispose.IDisposable;
    
    import starling.display.Sprite;
    
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.display.DottedRectangle;
    
    public class BarWholeView extends Sprite implements IDisposable
    {
        public var data:BarWhole;
        public var segmentViews:Vector.<BarSegmentView>;
        public var labelViews:Vector.<BarLabelView>;
        public var comparisonView:BarComparisonView;
        
        /**
         * This is only ever used in the case where we want all hidden segments to be grouped
         * together.
         */
        public var hiddenImage:DottedRectangle;
        
		public function BarWholeView(barWhole:BarWhole, hiddenImage:DottedRectangle)
        {
            super();

            this.data = barWhole;
            this.segmentViews = new Vector.<BarSegmentView>();
            this.labelViews = new Vector.<BarLabelView>();
            this.comparisonView = null;
            this.hiddenImage = hiddenImage;
        }
        
        public function redraw():void
        {
            // Re-add the segment views
            var i:int;
            var numSegmentViews:int = segmentViews.length;
            var segmentView:BarSegmentView;
            for (i = 0; i < numSegmentViews; i++)
            {
                segmentView = segmentViews[i];
                addChild(segmentView);
            }
            
            // After the segment view bounds have been finalized we do a pass for any bars
            // that want to group together all the hidden segments as one
            if (!this.data.displayHiddenSegments)
            {
                var startingIndexOfHiddenIndex:int = -1;
                for (i = 0; i < numSegmentViews; i++)
                {
                    segmentView = segmentViews[i];
                    if (segmentView.data.hiddenValue != null)
                    {
                        if (startingIndexOfHiddenIndex == -1)
                        {
                            startingIndexOfHiddenIndex = i;
                        }
                        
                        // Remove the hidden segment view
                        removeChild(segmentView);
                    }
                }
                
                // Figure out the bounds of the section of the hidden segments
                if (startingIndexOfHiddenIndex >= 0)
                {
                    var firstHiddenSegmentBounds:Rectangle = segmentViews[startingIndexOfHiddenIndex].rigidBody.boundingRectangle;
                    var lastHiddenSegmentBounds:Rectangle = segmentViews[numSegmentViews - 1].rigidBody.boundingRectangle;
                    var lengthOfHiddenSection:Number = lastHiddenSegmentBounds.right - firstHiddenSegmentBounds.left;
                    this.hiddenImage.resize(lengthOfHiddenSection, firstHiddenSegmentBounds.height, 12, 2);
                    this.hiddenImage.y = segmentViews[startingIndexOfHiddenIndex].y;
                    this.hiddenImage.x = segmentViews[startingIndexOfHiddenIndex].x;
                    addChild(hiddenImage);
                }
            }
            
            // Need to re-add the bar label views so they appear on top of the segments
            var numLabelViews:int = this.labelViews.length;
            var labelView:BarLabelView;
            var barLabel:BarLabel;
            for (i = 0; i < numLabelViews; i++)
            {
                // However, DO NOT re-add labels that have no brackets and are instead attached on top of 
                // the segment.
                labelView = this.labelViews[i];
                barLabel = labelView.data;
                var doShowLabel:Boolean = true;
                if (barLabel.bracketStyle == BarLabel.BRACKET_NONE && barLabel.startSegmentIndex == barLabel.endSegmentIndex)
                {
                    // Check if the attached segment is hidden in which case don't show it
                    doShowLabel = segmentViews[barLabel.startSegmentIndex].data.hiddenValue == null;
                }
                
                if (doShowLabel)
                {
                    addChild(labelView);
                }
                else
                {
                    labelView.removeFromParent();
                }
            }
        }
        
        public function addSegmentView(segmentView:BarSegmentView):void
        {
            segmentViews.push(segmentView);
            addChild(segmentView);
        }
        
		public function removeSegmentView(segmentView:BarSegmentView):void
		{
			const indx:int = segmentViews.indexOf(segmentView);
			if (indx > -1) segmentViews.splice(indx, 1);
			if (segmentView.parent == this) segmentView.removeFromParent();
		}
		
        public function addLabelView(labelView:BarLabelView):void
        {
            labelViews.push(labelView);
            addChild(labelView);
        }
        
        public function addComparisonView(comparisonView:BarComparisonView):void
        {
            this.comparisonView = comparisonView;
            addChild(comparisonView);
        }
        
		public function removeLabelView(labelView:BarLabelView):void
		{
			const indx:int = labelViews.indexOf(labelView);
			if (indx > -1) labelViews.splice(indx, 1);
			if (labelView.parent == this) labelView.removeFromParent();
		}
		
        override public function dispose():void
        {
            while (segmentViews.length > 0)
            {
                segmentViews.pop().removeFromParent(true);
            }

            while (labelViews.length > 0)
            {
                labelViews.pop().removeFromParent(true);
            }
            
            this.removeChildren();
            
            super.dispose();
        }
    }
}