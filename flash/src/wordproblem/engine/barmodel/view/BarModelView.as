package wordproblem.engine.barmodel.view
{
    import flash.geom.Rectangle;
    
    import feathers.textures.Scale3Textures;
    import feathers.textures.Scale9Textures;
    
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.Sprite;
    import starling.textures.Texture;
    
    import wordproblem.display.DottedRectangle;
    import wordproblem.engine.barmodel.model.BarComparison;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.expression.SymbolData;
    import wordproblem.resource.AssetManager;
    
    /**
     * This is a basic canvas to allow for the displaying of a bar model.
     * 
     * IMPORTANT:
     * Layout, scaling, and hit bounds for the bar model view might be a bit confusing.
     * The bounding rectangle fields in each view are all relative to this bar model area container. When refreshed they
     * should automatically take in any scaling that is applied to this object.
     * 
     * However when the layout and positioning of the views in here is performed the scale is initially ignored
     * and then reapplied to the whole container at once. This allows us to easily scale everything in one call.
     * The reason scale is ignored on layout
     */
    public class BarModelView extends Sprite
    {
        /**
         * If set to true, this component will always try to fit the current bar model
         * contents within the bounding constraints. It renders any external setting of
         * the unit length to not have any effect.
         */
        public var alwaysAutoCalculateUnitLength:Boolean = false;
        
        /**
         * The height in pixels of each bar. This implicitly says all bars have the same height
         */
        public var unitHeight:Number;
        
        /**
         * Within the constraints of this view how much empty space should be on the top of
         * the first bar
         */
        public var topBarPadding:Number;
        
        /**
         * Within the constraints of this view how much empty space should be on the left of
         * the lined up bars (Stays constant)
         */
        public var leftBarPadding:Number;
        
        /*
        IMPORTANT
        Bottom and right padding is only useful when the bar model view is editable, it is specified
        only to provide space for hit areas to do things like and new vertical label on the right
        or a new bar on the bottom
        */
        public var bottomBarPadding:Number;
        public var rightBarPadding:Number;
        
        /**
         * Amount of space between each of the bars
         */
        public var barGap:Number;
        
        /**
         * The normalizing factor can be thought of as number should be treated as the 'unit length'.
         * For example, if this value is 3 and the player creates a bar from the term value 6, that new
         * bar with 6 has a unit value of 6/3=>2.
         */
        public var normalizingFactor:Number = 1;
        
        /**
         * The length in pixels of segment that is of unit one. This is used to properly draw each segment.
         */
        protected var m_unitLength:Number;
        
        /**
         * This component may need to automatically resize the bars by setting the unit length
         * to new values. These new values will override those set by the application.
         * 
         * However we want to rememeber the values set by application as they will serve
         * as an upper bound to how wide we allow the auto-resized bars to be
         */
        protected var m_savedUnitLength:Number;
        
        /**
         * All data properties related to the representation of the bars
         */
        protected var m_barModelData:BarModelData;
        
        /**
         * List of all visible bars along with their attached labels
         */
        protected var m_barWholeViews:Vector.<BarWholeView>;
        
        /**
         * List of all vertical bars views
         */
        protected var m_verticalLabelViews:Vector.<BarLabelView>;
        
        /**
         * This is this layer in which all the actual bar model views are added to.
         * The main reason for this is that we can remove these objects from view at once, which is useful
         * to show just a preview of the change while hiding the original. In addition we can
         * apply a uniform scale to all the objects
         */
        protected var m_objectLayer:Sprite;
        
        /**
         * Other classes can access this layer to put object that appear on top of everything, like animations
         */
        protected var m_foregroundLayer:Sprite;
        
        /**
         * Get the constraining bounds of the bar model area, relative to its own frame of reference
         */
        protected var m_constraints:Rectangle;
        
        /**
         * Use this to draw cards
         */
        protected var m_expressionSymbolMap:ExpressionSymbolMap;
        
        /**
         * Use this to access textures
         */
        protected var m_assetManager:AssetManager;
        
        public function BarModelView(unitLength:Number, 
                                     unitHeight:Number,
                                     topBarPadding:Number,
                                     bottomBarPadding:Number,
                                     leftBarPadding:Number,
                                     rightBarPadding:Number,
                                     barGap:Number,
                                     barModelData:BarModelData, 
                                     expressionSymbolMap:ExpressionSymbolMap,
                                     assetManager:AssetManager)
        {
            super();
            
            this.unitLength = unitLength;
            this.unitHeight = unitHeight;
            this.topBarPadding = topBarPadding;
            this.leftBarPadding = leftBarPadding;
            this.bottomBarPadding = bottomBarPadding;
            this.rightBarPadding = rightBarPadding;
            this.barGap = barGap;
            
            m_barWholeViews = new Vector.<BarWholeView>();
            m_verticalLabelViews = new Vector.<BarLabelView>();
            
            setBarModelData(barModelData);
            
            m_objectLayer = new Sprite();
            m_foregroundLayer = new Sprite();
            m_constraints = new Rectangle();
            m_expressionSymbolMap = expressionSymbolMap;
            m_assetManager = assetManager;
        }
        
        /**
         * HACK: Used only if some other class want to get symbols with the same style
         * as the ones drawn in this bar model.
         */
        public function getExpressionSymbolMap():ExpressionSymbolMap
        {
            return m_expressionSymbolMap;
        }
        
        /**
         * It is possible for the contents of the model to not fit within the given constraints. If this happens we may
         * need to scale down the view.
         * 
         * This applies a uniform scale to every element. Should generally avoid using this if possible
         * 
         * (NOTE: this scale only affects the views and not any properties of the data model)
         */
        public function set scaleFactor(value:Number):void
        {
            m_objectLayer.scaleX = m_objectLayer.scaleY = value;
        }
        
        public function get scaleFactor():Number
        {
            return m_objectLayer.scaleX;
        }
        
        /**
         * (Internally, do not use this function, set the private field directly)
         */
        public function set unitLength(value:Number):void
        {
            m_unitLength = value;
            
            // Everytime an external call is made to change the unit length we
            // save the value since auto resizing may overwrite
            m_savedUnitLength = value;
        }
        
        public function get unitLength():Number
        {
            return m_unitLength;
        }
        
        public function get maxAllowableWidth():Number
        {
            // Note the primary purpose of the padding is to provide additional space for hit areas
            return this.getConstraints().width - this.leftBarPadding - this.rightBarPadding;
        }
        
        /**
         * MUST BE CALLED AT LEAST ONCE
         */
        public function setDimensions(width:Number, height:Number):void
        {
            m_constraints.width = width;
            m_constraints.height = height;
        }
        
        /**
         * These are the fixed upper limits to the size of this view.
         * Differs from normal width and height in that the constraints are always fixed
         * regardless of the size of the display objects contained inside this view.
         */
        public function getConstraints():Rectangle
        {
            return m_constraints;
        }
        
        /**
         * Given a target bar model data we want to calculate a 'best' fitting unit value such
         * that when drawn in this ui it will fill up as much space as possible
         * 
         * @param excessPadding
         *      This is the space that non-segments take up (notably the vertical bars)
         *      This extra space is NOT usable by the segments
         * 
         */
        public function getUnitValueFromBarModelData(barModelData:BarModelData, excessPadding:Number=0):Number
        {
            var maxBarUnitValue:Number = barModelData.getMaxBarUnitValue();
            var desiredUnitLength:Number = (maxAllowableWidth - excessPadding) / (maxBarUnitValue * this.scaleFactor);
            return desiredUnitLength;
        }
        
        public function setBarModelData(barModelData:BarModelData):void
        {
            m_barModelData = barModelData;
            
            while (m_barWholeViews.length > 0)
            {
                var barWholeView:BarWholeView = m_barWholeViews.pop();
                barWholeView.removeFromParent();
                barWholeView.dispose();
            }
            
            while (m_verticalLabelViews.length > 0)
            {
                var barLabelView:BarLabelView = m_verticalLabelViews.pop();
                barLabelView.removeFromParent();
                barLabelView.dispose();
            }
        }
        
        public function createBarLabelView(barLabel:BarLabel):BarLabelView
        {
            var leftBracketTexture:Texture = m_assetManager.getTexture("brace_left_end");
            var rightBracketTexture:Texture = m_assetManager.getTexture("brace_right_end");
            var middleBracketTexture:Texture = m_assetManager.getTexture("brace_center");
            var fullBracketTexture:Texture = m_assetManager.getTexture("brace_full");
            
            var blankTexturePadding:Number = 12;
            var blankTexture:Texture = m_assetManager.getTexture("wildcard");
            var blankNineSliceGrid:Rectangle = new Rectangle(blankTexturePadding, blankTexturePadding, blankTexture.width - 2 * blankTexturePadding, blankTexture.height - 2 * blankTexturePadding);
            
            var dottedLineCornerTexture:Texture = m_assetManager.getTexture("dotted_line_corner");
            var dottedLineSegmentTexture:Texture = m_assetManager.getTexture("dotted_line_segment");
            
            // Look at the expression symbol map for styling properties
            // Color text inside segment differently than outside
            var fontColor:uint = (barLabel.bracketStyle == BarLabel.BRACKET_NONE) ?
                0x000000 : 0xFFFFFF;
            var symbolData:SymbolData = m_expressionSymbolMap.getSymbolDataFromValue(barLabel.value);
            
            var hiddenLabelImage:DottedRectangle = new DottedRectangle(blankTexture, blankNineSliceGrid, 1.0, dottedLineCornerTexture, dottedLineSegmentTexture);
            var labelImage:DisplayObject = null;
            if (barLabel.numImages > 1)
            {
                var labelImageContainer:Sprite = new Sprite();
                var i:int;
                for (i = 0; i < barLabel.numImages; i++)
                {
                    var cardSymbol:DisplayObject = m_expressionSymbolMap.getCardFromSymbolValue(barLabel.value);
                    labelImageContainer.addChild(cardSymbol);
                }
                labelImage = labelImageContainer;
            }
            else
            {
                labelImage = m_expressionSymbolMap.getCardFromSymbolValue(barLabel.value);
            }
            
            var barLabelView:BarLabelView = new BarLabelView(
                barLabel, 
                symbolData.fontName,
                fontColor,
                leftBracketTexture, 
                rightBracketTexture, 
                middleBracketTexture, 
                fullBracketTexture,
                symbolData.abbreviatedName,
                labelImage,
                symbolData.symbolTextureName != null,
                hiddenLabelImage
            );
            return barLabelView;
        }
        
        public function createBarComparisonView(barComparison:BarComparison):BarComparisonView
        {
            var comparisonLeftTexture:Texture = m_assetManager.getTexture("comparison_left");
            var comparisonRightTexture:Texture = m_assetManager.getTexture("comparison_right");
            var comparisonFullTexture:Texture = m_assetManager.getTexture("comparison_full");
            var threeSlicePadding:Number = 28;
            var threeSliceComparisonTexture:Scale3Textures = new Scale3Textures(comparisonFullTexture, threeSlicePadding, comparisonFullTexture.width - 2 * threeSlicePadding);
            
            var symbolData:SymbolData = m_expressionSymbolMap.getSymbolDataFromValue(barComparison.value);
            var fontName:String = symbolData.fontName;
            var textName:String = symbolData.name;
            var symbolImage:DisplayObject = m_expressionSymbolMap.getCardFromSymbolValue(barComparison.value);
            symbolImage.pivotX = 0;
            symbolImage.pivotY = 0;
            symbolImage.scaleX = symbolImage.scaleY = 0.6;
            var barComparisonView:BarComparisonView = new BarComparisonView(
                barComparison, 
                1,
                textName,
                fontName,
                0xFFFFFF,
                symbolImage,
                threeSliceComparisonTexture, 
                comparisonFullTexture
            );
            return barComparisonView;
        }
        
        public function getBarSegmentViewById(segmentId:String):BarSegmentView
        {
            var matchingSegmentView:BarSegmentView = null;
            var numBarWholeViews:int = m_barWholeViews.length;
            var i:int;
            var barWholeView:BarWholeView;
            for (i = 0; i < numBarWholeViews; i++)
            {
                barWholeView = m_barWholeViews[i];
                
                var j:int;
                var numSegmentViews:int = barWholeView.segmentViews.length;
                var barSegmentView:BarSegmentView;
                for (j = 0; j < numSegmentViews; j++)
                {
                    barSegmentView = barWholeView.segmentViews[j];
                    if (barSegmentView.data.id == segmentId)
                    {
                        matchingSegmentView = barSegmentView;
                        break;
                    }
                }
                
                if (matchingSegmentView != null)
                {
                    break;
                }
            }
            
            return matchingSegmentView;
        }
        
        public function getBarLabelViewById(labelId:String):BarLabelView
        {
            var matchingBarLabelView:BarLabelView = null;
            var numBarWholeViews:int = m_barWholeViews.length;
            var i:int;
            var barWholeView:BarWholeView;
            for (i = 0; i < numBarWholeViews; i++)
            {
                barWholeView = m_barWholeViews[i];
                
                var j:int;
                var numBarLabelViews:int = barWholeView.labelViews.length;
                var barLabelView:BarLabelView;
                for (j = 0; j < numBarLabelViews; j++)
                {
                    barLabelView = barWholeView.labelViews[j];
                    if (barLabelView.data.id == labelId)
                    {
                        matchingBarLabelView = barLabelView;
                        break;
                    }
                }
                
                if (matchingBarLabelView != null)
                {
                    break;
                }
            }
            
            return matchingBarLabelView;
        }
        
        public function getBarWholeViewById(barWholeId:String):BarWholeView
        {
            var matchingBarWholeView:BarWholeView;
            var i:int;
            var numBarWholeViews:int = m_barWholeViews.length;
            var barWholeView:BarWholeView;
            for (i = 0; i < numBarWholeViews; i++)
            {
                barWholeView = m_barWholeViews[i];
                if (barWholeView.data.id == barWholeId)
                {
                    matchingBarWholeView = barWholeView;
                    break;
                }
            }
            
            return matchingBarWholeView;
        }
        
        public function getVerticalBarLabelViewById(verticalBarLabelId:String):BarLabelView
        {
            var matchingBarLabelView:BarLabelView;
            var i:int;
            var numVerticalBarLabelViews:int = m_verticalLabelViews.length;
            var verticalBarLabelView:BarLabelView;
            for (i = 0; i < numVerticalBarLabelViews; i++)
            {
                verticalBarLabelView = m_verticalLabelViews[i];
                if (verticalBarLabelView.data.id == verticalBarLabelId)
                {
                    matchingBarLabelView = verticalBarLabelView;
                    break;
                }
            }
            
            return matchingBarLabelView;
        }
        
        public function getBarModelData():BarModelData
        {
            return m_barModelData;
        }
        
        public function getBarWholeViews():Vector.<BarWholeView>
        {
            return m_barWholeViews;
        }
        
        public function getVerticalBarLabelViews():Vector.<BarLabelView>
        {
            return m_verticalLabelViews;
        }
        
        /**
         * Get back a layer in which any extra display objects added should appear on top of
         * the bar model pieces
         */
        public function getForegroundLayer():DisplayObjectContainer
        {
            return m_foregroundLayer;
        }
        
        /**
         * This function checks whether the smallest segment in the given bar model is able to
         * fit within the constraints of this view.
         * 
         * It is a guard to see if this view would be able to draw all segments given their
         * current proportions.
         */
        public function checkAllBarSegmentsFitInView(barModelData:BarModelData):Boolean
        {
            // We first need to calculate the segment value of the longest total bar
            var i:int;
            var numBars:int = barModelData.barWholes.length;
            var maxBarValue:Number = 0;
            for (i = 0; i < numBars; i++)
            {
                var barWhole:BarWhole = barModelData.barWholes[i];
                var barValue:Number = barWhole.getValue();
                if (barValue > maxBarValue)
                {
                    maxBarValue = barValue;
                }
            }
            
            // Figure out the pixels per unit value if the longest total bar were to stretch
            // out to fit the entire horizontal space of the bar
            var maxViewSpace:Number = this.getConstraints().width;
            var maxPixelsPerUnit:Number = maxViewSpace / maxBarValue;
            
            // Find the smallest possible bar segment and see if the unit value
            // we calculated would result in a box that would appear visible
            for (i = 0; i < numBars; i++)
            {
                barWhole = barModelData.barWholes[i];
                var barSegments:Vector.<BarSegment> = barWhole.barSegments;
                var j:int = 0;
                var minSegmentValue:Number = int.MAX_VALUE;
                for (j = 0; j < barSegments.length; j++)
                {
                    var barSegment:BarSegment = barSegments[j];
                    var barSegmentValue:Number = barSegment.getValue();
                    if (minSegmentValue > barSegmentValue)
                    {
                        minSegmentValue = barSegmentValue;
                    }
                }
            }
            
            var minPixelValue:Number = minSegmentValue * maxPixelsPerUnit;
            var minPixelThreshold:Number = 16;
            return minPixelValue >= minPixelThreshold;
        }
        
        /**
         * Redraw will create a completely new set of views for all parts of the bar model. All previous
         * display objects that were visible will be discarded, this is very important to keep in mind if
         * another script is using a view (i.e. like highlighting it or attaching a callout) since the view
         * it is referencing must change on every redraw.
         * 
         * MUST BE CALLED AT LEAST ONCE to have something show up.
         * 
         * @param doDispatchEvent
         *      True if the view should send a signal that a redraw was completed. Only time we want
         *      this to false is if we want to immediately draw again based on the completion of a redraw
         *      and don't want that area of code to catch the event again.
         * @param centerContents
         *      If true, the contents of the view are centered within the constraints
         */
        public function redraw(doDispatchEvent:Boolean=true, centerContents:Boolean=false):void
        {
            // Make sure objects are reset to origin when redrawing and laying out for the first time
            m_objectLayer.x = m_objectLayer.y = 0;
            addChild(m_objectLayer);
            addChild(m_foregroundLayer);
            _redraw();
            
            // Redraw at smaller scale if we detect spillover
            checkAndCorrectBarSpillover();
            
            // Perform centering of the elements
            if (centerContents)
            {
                var objectBounds:Rectangle = m_objectLayer.getBounds(this);
                m_objectLayer.x = (m_constraints.width - objectBounds.width) * 0.5 - leftBarPadding;
                m_objectLayer.y = (m_constraints.height - objectBounds.height) * 0.5 - topBarPadding;
                
                // Center may change the bounds as well
                this.recalculateBounds();
            }
            
            // Dispatch event letting other objects know that the view has finished drawing and laying out the objects
            if (doDispatchEvent)
            {
                dispatchEventWith(GameEvent.BAR_MODEL_AREA_REDRAWN);
            }
        }
        
        /**
         * Just looking at the existing views, this function should lay everything out again.
         * (Useful if a property of an existing part of the model changes and we need to resize or reposition but
         * do not need to create new visual objects)
         */
        public function layout():void
        {
            var prevScale:Number = this.scaleFactor;
            this.scaleFactor = 1.0;
            var hiddenSegmentStack:Vector.<BarSegmentView> = new Vector.<BarSegmentView>();
            var shownSegmentStack:Vector.<BarSegmentView> = new Vector.<BarSegmentView>();
            
            // The redraw function needs to first draw unscaled versions of the bars and their segments.
            var i:int;
            var numBarWholesViews:int = this.getBarWholeViews().length;
            for (i = 0; i < numBarWholesViews; i++)
            {
                var barWholeView:BarWholeView = this.getBarWholeViews()[i];
                var xSegmentOffset:Number = 0;
                
                var j:int;
                var numSegmentViews:int = barWholeView.segmentViews.length;
                
                // If bar whole should be group together hidden segments as one, then first re-order
                // the segments such that hidden ones are bunched to the right.
                // This is a special case only used to draw the dotted outline on a bar for tutorials
                if (!barWholeView.data.displayHiddenSegments)
                {
                    for (j = 0; j < numSegmentViews; j++)
                    {
                        barSegmentView = barWholeView.segmentViews[j];
                        if (barSegmentView.data.hiddenValue != null)
                        {
                            hiddenSegmentStack.push(barSegmentView);
                        }
                        else
                        {
                            shownSegmentStack.push(barSegmentView);
                        }
                    }
                    
                    // Re-order both the view and the backing data lists of the segments
                    barWholeView.data.barSegments.length = 0;
                    barWholeView.segmentViews.length = 0;
                    while (shownSegmentStack.length > 0)
                    {
                        barSegmentView = shownSegmentStack.shift();
                        barWholeView.data.barSegments.push(barSegmentView.data);
                        barWholeView.segmentViews.push(barSegmentView);
                    }
                    
                    while (hiddenSegmentStack.length > 0)
                    {
                        barSegmentView = hiddenSegmentStack.shift();
                        barWholeView.data.barSegments.push(barSegmentView.data);
                        barWholeView.segmentViews.push(barSegmentView);
                    }
                }
                
                // resize and reposition the segments contained in this view
                for (j = 0; j < numSegmentViews; j++)
                {
                    var barSegmentView:BarSegmentView = barWholeView.segmentViews[j];
                    barSegmentView.resize(this.unitLength, this.unitHeight);
                    barSegmentView.x = xSegmentOffset;
                    xSegmentOffset += barSegmentView.width;
                }
                
                // Add the comparison view if it exists, it goes at the edge of the bar
                // Its length requires looking at the other bar to compare against
                if (barWholeView.comparisonView != null)
                {
                    barWholeView.comparisonView.x = xSegmentOffset;
                    barWholeView.comparisonView.y = -10;
                }
                
                // The horizontal labels can be drawn after the segments have been created.
                // However they cannot be fully positioned yet, as this may require knowledge about other bars first
                var barLabelView:BarLabelView;
                var numLabelViews:int = barWholeView.labelViews.length;
                for (j = 0; j < numLabelViews; j++)
                {
                    barLabelView = barWholeView.labelViews[j];
                    
                    // Need to get the segment widths in order to calculate the label length
                    // Combine the lengths of all segments between the start and end of the label
                    // Note that label length also depends on whether the bar is scaled.
                    var k:int;
                    var labelLength:Number = 0;
                    var startSegmentIndex:int = barLabelView.data.startSegmentIndex;
                    var endSegmentIndex:int = barLabelView.data.endSegmentIndex;
                    for (k = startSegmentIndex; k <= endSegmentIndex; k++)
                    {
                        labelLength += barWholeView.data.barSegments[k].getValue() * this.unitLength;
                    }
                    
                    barLabelView.rescaleAndRedraw(labelLength, -1, 1.0, 1.0);
                }
            }
            
            // Once we have done a first pass creating all the bars and horizontal labels we need to determine their positioning
            // and even their scaling within each whole bar.
            // First orient the labels on the bars
            for (i = 0; i < m_barWholeViews.length; i++)
            {
                barWholeView = m_barWholeViews[i];
                m_objectLayer.addChild(barWholeView);
                
                numLabelViews = barWholeView.labelViews.length;
                
                // First pass draw all the label on top of the bar, need to start backwards
                // as later ones are closer
                var yOffsetLabel:Number = 0;
                var numTopLabels:int = 0;
                for (j = numLabelViews - 1; j >= 0; j--)
                {
                    barLabelView = barWholeView.labelViews[j];
                    
                    if (barLabelView.data.isAboveSegment && barLabelView.data.bracketStyle != BarLabel.BRACKET_NONE)
                    {
                        barLabelView.y = yOffsetLabel;
                        barLabelView.x = barWholeView.segmentViews[barLabelView.data.startSegmentIndex].x;
                        
                        numTopLabels++;
                        yOffsetLabel += barLabelView.height;
                    }
                }
                
                // Shift down all the segments by the new y-offset that was caused by the top labels
                if (numTopLabels > 0)
                {
                    yOffsetLabel += 5;
                }
                
                numSegmentViews = barWholeView.segmentViews.length;
                for (j = 0; j < numSegmentViews; j++)
                {
                    barWholeView.segmentViews[j].y = yOffsetLabel;
                }
                
                // Position all of the labels that go underneath the bar segment
                yOffsetLabel += barWholeView.segmentViews[0].height;
                for (j = 0; j < numLabelViews; j++)
                {
                    barLabelView = barWholeView.labelViews[j];
                    
                    // Also take care of situations where the label should sit directly on top of the segment
                    if (barLabelView.data.bracketStyle == BarLabel.BRACKET_NONE)
                    {
                        var targetSegmentView:BarSegmentView = barWholeView.segmentViews[barLabelView.data.startSegmentIndex];
                        barLabelView.x = targetSegmentView.x;
                        barLabelView.y = targetSegmentView.y;
                        barLabelView.rescaleAndRedraw(targetSegmentView.width, targetSegmentView.height, 1.0, 1.0);
                    }
                    else if (!barLabelView.data.isAboveSegment && barLabelView.data.bracketStyle != BarLabel.BRACKET_NONE)
                    {
                        // Need to get the segment widths in order to calculate the label length
                        // Combine the lengths of all segments between the start and end of the label
                        // Note that label length also depends on whether the bar is scaled.
                        var startIndex:int = barLabelView.data.startSegmentIndex;
                        var endIndex:int = barLabelView.data.endSegmentIndex;
                        labelLength = 0;
                        for (k = startIndex; k <= endIndex; k++)
                        {
                            labelLength += barWholeView.segmentViews[k].data.getValue() * this.unitLength;
                        }
                        
                        barLabelView.rescaleAndRedraw(labelLength, -1, 1.0, 1.0);
                        barLabelView.y = yOffsetLabel;
                        barLabelView.x = barWholeView.segmentViews[barLabelView.data.startSegmentIndex].x;
                        
                        // TODO: Labels can fit on the same line as long as their indices don't overlap
                        yOffsetLabel += barLabelView.height;
                    }
                }
            }
            
            // Second pass orients the bars (with the labels attached to them) RELATIVE to each other
            var yOffsetBar:Number = topBarPadding;
            var boundingRectangleBuffer:Rectangle = new Rectangle();
            for (i = 0; i < m_barWholeViews.length; i++)
            {
                barWholeView = m_barWholeViews[i];
                barWholeView.getBounds(this, boundingRectangleBuffer);
                
                barWholeView.x = this.leftBarPadding;
                barWholeView.y = yOffsetBar;
                
                // HACK: Do not apply gap if this bar has a bottom label or next one has a top label
                var gap:Number = this.barGap;
                var barLabelViews:Vector.<BarLabelView> = barWholeView.labelViews;
                for each (barLabelView in barLabelViews)
                {
                    if (barLabelView.data.bracketStyle != BarLabel.BRACKET_NONE && !barLabelView.data.isAboveSegment)
                    {
                        gap = 2;
                        break;
                    }
                }
                
                yOffsetBar += boundingRectangleBuffer.height + gap;
            }
            
            // Set up the bounding hit areas of segments and labels for the bars
            // Since the common case is that these items don't change, calculate them on a refresh
            // so scripts have fast access to them.
            for (i = 0; i < m_barWholeViews.length; i++)
            {
                barWholeView = m_barWholeViews[i];
                
                var segmentView:BarSegmentView;
                var segmentViews:Vector.<BarSegmentView> = barWholeView.segmentViews;
                numSegmentViews = segmentViews.length;
                for (j = 0; j < numSegmentViews; j++)
                {
                    segmentView = segmentViews[j];
                    barWholeView.addChild(segmentView); // Make sure segment view is added as part of the stage
                    segmentView.getBounds(this, boundingRectangleBuffer);
                    segmentView.rigidBody.boundingRectangle.setTo(
                        boundingRectangleBuffer.x,
                        boundingRectangleBuffer.y,
                        boundingRectangleBuffer.width,
                        boundingRectangleBuffer.height
                    );
                }
                
                var labelView:BarLabelView;
                var labelViews:Vector.<BarLabelView> = barWholeView.labelViews;
                for (j = 0; j < labelViews.length; j++)
                {
                    labelView = labelViews[j];
                    barWholeView.addChild(labelView); // Make sure label view is added as part of the stage
                    labelView.lineGraphicDisplayContainer.getBounds(this, boundingRectangleBuffer);
                    labelView.rigidBody.boundingRectangle.setTo(
                        boundingRectangleBuffer.x,
                        boundingRectangleBuffer.y,
                        boundingRectangleBuffer.width,
                        boundingRectangleBuffer.height
                    );
                }
                
                // Refresh drawing of the bar to handle displaying the image of the hidden pieces being grouped together
                barWholeView.redraw();
            }
            
            // It is only after the segment bounds have been determined that we can properly determine the position and
            // length of the bar comparison view within each bar
            var numBarWholeViews:int = m_barWholeViews.length;
            for (i = 0; i < numBarWholeViews; i++)
            {
                barWholeView = m_barWholeViews[i];
                
                var leftCompareEdge:Number = barWholeView.segmentViews[barWholeView.segmentViews.length - 1].rigidBody.boundingRectangle.right;
                var barComparisonView:BarComparisonView = barWholeView.comparisonView;
                if (barComparisonView != null)
                {
                    var barWholeViewToCompare:BarWholeView;
                    for (j = 0; j < numBarWholeViews; j++)
                    {
                        barWholeViewToCompare = m_barWholeViews[j];
                        if (barWholeViewToCompare.data.id == barComparisonView.data.barWholeIdComparedTo)
                        {
                            var rightCompareEdge:Number = barWholeViewToCompare.segmentViews[barComparisonView.data.segmentIndexComparedTo].rigidBody.boundingRectangle.right;
                            barComparisonView.resizeToLength(rightCompareEdge - leftCompareEdge);
                            
                            var referenceSegmentView:BarSegmentView = barWholeView.segmentViews[0];
                            barComparisonView.y = referenceSegmentView.y + (referenceSegmentView.rigidBody.boundingRectangle.height - barComparisonView.height) * 0.5;
                            break;
                        }
                    }
                    
                    // Set bounds for the comparison after it is done being positioned
                    barWholeView.comparisonView.lineGraphicDisplayContainer.getBounds(this, boundingRectangleBuffer);
                    barWholeView.comparisonView.rigidBody.boundingRectangle.setTo(
                        boundingRectangleBuffer.x,
                        boundingRectangleBuffer.y,
                        boundingRectangleBuffer.width,
                        boundingRectangleBuffer.height
                    );
                }
            }
            
            // Create and add the vertical labels, their position changes depending on the vertical position of all
            // the items.
            // The vertical bars should stack from left to right
            // The starting x offset should be the length of the longest bar
            var startingXOffsetForVertical:Number = 0;
            for (i = 0; i < numBarWholesViews; i++)
            {
                barWholeView = m_barWholeViews[i];
                barWholeView.getBounds(this, boundingRectangleBuffer);
                
                startingXOffsetForVertical = Math.max(startingXOffsetForVertical, boundingRectangleBuffer.right);
            }
            
            var verticalBarXOffset:Number = 20;
            var numVerticalBars:int = m_barModelData.verticalBarLabels.length;
            for (i = 0; i < numVerticalBars; i++)
            {
                barLabelView = this.getVerticalBarLabelViews()[i];
                startSegmentIndex = barLabelView.data.startSegmentIndex;
                endSegmentIndex = barLabelView.data.endSegmentIndex;
                
                var startingBarView:BarWholeView = m_barWholeViews[startSegmentIndex];
                var topY:Number = (startingBarView.segmentViews.length > 0) ? 
                    startingBarView.segmentViews[0].rigidBody.boundingRectangle.top :
                    startingBarView.y;
                
                var endingBarView:BarWholeView = m_barWholeViews[endSegmentIndex];
                var bottomY:Number = (endingBarView.segmentViews.length > 0) ?
                    endingBarView.segmentViews[0].rigidBody.boundingRectangle.bottom :
                    endingBarView.y + endingBarView.height;
                
                barLabelView.rescaleAndRedraw(-1, bottomY - topY, 1.0, 1.0);
                barLabelView.x = startingXOffsetForVertical + verticalBarXOffset;
                barLabelView.y = topY;
                m_objectLayer.addChild(barLabelView);
                
                verticalBarXOffset += barLabelView.width;
            }
            
            // Set up the bounding hit areas for the vertical labels
            for (i = 0; i < m_verticalLabelViews.length; i++)
            {
                labelView = m_verticalLabelViews[i];
                labelView.lineGraphicDisplayContainer.getBounds(this, boundingRectangleBuffer);
                labelView.rigidBody.boundingRectangle.setTo(
                    boundingRectangleBuffer.x,
                    boundingRectangleBuffer.y,
                    boundingRectangleBuffer.width,
                    boundingRectangleBuffer.height
                );
            }
            
            this.scaleFactor = prevScale;
            recalculateBounds();
        }
        
        private function _redraw():void
        {
            // As a simple first take, whenever redraw is called we dispose of everything
            // and recreate each view.
            while (m_barWholeViews.length > 0)
            {
                m_barWholeViews.pop().removeFromParent(true);
            }
            
            while (m_verticalLabelViews.length > 0)
            {
                m_verticalLabelViews.pop().removeFromParent(true);
            }
            
            // The redraw function needs to first draw unscaled versions of the bars and their segments.
            var i:int;
            var numBarWholes:int = m_barModelData.barWholes.length;
            var segmentTexture:Texture = m_assetManager.getTexture("card_background_square");
            var nineSlicePadding:Number = 8;
            var nineSliceTexture:Scale9Textures = new Scale9Textures(segmentTexture, 
                new Rectangle(nineSlicePadding, 
                    nineSlicePadding, 
                    segmentTexture.width - 2 * nineSlicePadding, 
                    segmentTexture.height - 2 * nineSlicePadding
                )
            );
            
            var blankTexturePadding:Number = 12;
            var blankTexture:Texture = m_assetManager.getTexture("wildcard");
            var blankNineSliceGrid:Rectangle = new Rectangle(blankTexturePadding, blankTexturePadding, blankTexture.width - 2 * blankTexturePadding, blankTexture.height - 2 * blankTexturePadding);
            
            var dottedLineCornerTexture:Texture = m_assetManager.getTexture("dotted_line_corner");
            var dottedLineSegmentTexture:Texture = m_assetManager.getTexture("dotted_line_segment");
            
            for (i = 0; i < numBarWholes; i++)
            {
                var barWhole:BarWhole = m_barModelData.barWholes[i];
                
                // Draw and re-position the segments contained in this view
                var j:int;
                var barSegment:BarSegment;
                var numSegments:int = barWhole.barSegments.length;
                var barWholeHiddenImage:DottedRectangle = new DottedRectangle(blankTexture, blankNineSliceGrid, 1, dottedLineCornerTexture, dottedLineSegmentTexture);
                var barWholeView:BarWholeView = new BarWholeView(barWhole, barWholeHiddenImage);
                for (j = 0; j < numSegments; j++)
                {
                    barSegment = barWhole.barSegments[j];
                    
                    var hiddenSegment:DottedRectangle = new DottedRectangle(blankTexture, blankNineSliceGrid, 1, dottedLineCornerTexture, dottedLineSegmentTexture);
                    var barSegmentView:BarSegmentView = new BarSegmentView(
                        barSegment, 
                        nineSliceTexture, 
                        segmentTexture,
                        hiddenSegment
                    );
                    barWholeView.addSegmentView(barSegmentView);
                }
                
                // Add the comparison view if it exists, it goes at the edge of the bar
                // Its length requires looking at the other bar to compare against
                var barComparison:BarComparison = barWhole.barComparison;
                if (barComparison != null)
                {
                    var barComparisonView:BarComparisonView = this.createBarComparisonView(barComparison);
                    barWholeView.addComparisonView(barComparisonView);
                }
                
                m_barWholeViews.push(barWholeView);
                
                // The horizontal labels can be drawn after the segments have been created.
                // However they cannot be fully positioned yet, as this may require knowledge about other bars first
                var barLabel:BarLabel;
                var numLabels:int = barWhole.barLabels.length;
                for (j = 0; j < numLabels; j++)
                {
                    barLabel = barWhole.barLabels[j];
                    var barLabelView:BarLabelView = this.createBarLabelView(barLabel);
                    barWholeView.addLabelView(barLabelView);
                }
            }
            
            // Create and add the vertical labels, their position changes depending on the vertical position of all
            // the items.
            // The vertical bars should stack from left to right
            // The starting x offset should be the length of the longest bar
            var numVerticalBars:int = m_barModelData.verticalBarLabels.length;
            for (i = 0; i < numVerticalBars; i++)
            {
                barLabel = m_barModelData.verticalBarLabels[i];
                barLabelView = this.createBarLabelView(barLabel);
                m_objectLayer.addChild(barLabelView);
                
                m_verticalLabelViews.push(barLabelView);
            }
            
            // After all views are created then layout again
            this.layout();
        }
        
        /**
         * Helper function that goes the given bar model view and checks whether any of the
         * currently displayed bars overflow. Force redraw if it fails
         */
        protected function checkAndCorrectBarSpillover():void
        {
            // Look through all the bars and get their bounds relative to the view
            // Allow for extra padding at the edge of the constraints so pieces don't
            // sit exactly on the edge
            var maxAllowableHeight:Number = this.getConstraints().height - topBarPadding - bottomBarPadding;
            var boundsBuffer:Rectangle = new Rectangle();
            m_objectLayer.getBounds(this, boundsBuffer);
            
            // If current bounds of the bar object exceeds the max constraints, then we need to rescale
            // and redraw. Also handles the case where we want the object to go back to normal unscaled size
            // Find the amount to scale horizontally so the object fits
            // Find the amount to scale vertically so the object fits
            var verticalScaleFactor:Number = Math.min(1.0, maxAllowableHeight / (boundsBuffer.height / this.scaleFactor));
            var newScalefactor:Number = verticalScaleFactor;
            
            if (this.scaleFactor != newScalefactor)
            {
                this.scaleFactor = newScalefactor;
                
                // Re-calculate bounds
                m_objectLayer.getBounds(this, boundsBuffer);
            }
            
            // Force a redraw if the unit length was altered (This should take existing views and just reposition them
            // to avoid recreating new views)
            // Iterate through every bar, we want to find the one with the greatest value
            // We also need to take into account scaling, since scaling down will shrink the segments such that they won't quite fit
            // to the edge.
            var maxScaledWidthOfLongestBar:Number = this.m_barModelData.getMaxBarUnitValue() * this.unitLength * this.scaleFactor;
            var excessPadding:Number = boundsBuffer.width - maxScaledWidthOfLongestBar;
            var desiredUnitLength:Number = this.getUnitValueFromBarModelData(m_barModelData, excessPadding);
            var newUnitLength:Number = m_unitLength;
            if (desiredUnitLength != this.unitLength && desiredUnitLength != Infinity)
            {
                if (desiredUnitLength > m_savedUnitLength && !this.alwaysAutoCalculateUnitLength)
                {
                    newUnitLength = m_savedUnitLength;
                }
                else
                {
                    newUnitLength = desiredUnitLength;
                }
                
                m_unitLength = newUnitLength;
                this.layout();
            }

            this.recalculateBounds();
        }
        
        /**
         * Each element of the bar model has a fixed bounding box use to detect hits in various gestures.
         * Each time the view changes (it gets scaled or moved) we need to refresh those values.
         */
        private function recalculateBounds():void
        {
            var i:int;
            var boundingRectangleBuffer:Rectangle = new Rectangle();
            for (i = 0; i < m_barWholeViews.length; i++)
            {
                var barWholeView:BarWholeView = m_barWholeViews[i];
                
                var segmentView:BarSegmentView;
                var segmentViews:Vector.<BarSegmentView> = barWholeView.segmentViews;
                var numSegmentViews:int = segmentViews.length;
                var j:int;
                for (j = 0; j < numSegmentViews; j++)
                {
                    segmentView = segmentViews[j];
                    barWholeView.addChild(segmentView); // Make sure segment view is added as part of the stage
                    segmentView.getBounds(this, boundingRectangleBuffer);
                    segmentView.rigidBody.boundingRectangle.setTo(
                        boundingRectangleBuffer.x,
                        boundingRectangleBuffer.y,
                        boundingRectangleBuffer.width,
                        boundingRectangleBuffer.height
                    );
                }
                
                var labelView:BarLabelView;
                var labelViews:Vector.<BarLabelView> = barWholeView.labelViews;
                for (j = 0; j < labelViews.length; j++)
                {
                    labelView = labelViews[j];
                    barWholeView.addChild(labelView); // Make sure label view is added as part of the stage
                    labelView.lineGraphicDisplayContainer.getBounds(this, boundingRectangleBuffer);
                    labelView.rigidBody.boundingRectangle.setTo(
                        boundingRectangleBuffer.x,
                        boundingRectangleBuffer.y,
                        boundingRectangleBuffer.width,
                        boundingRectangleBuffer.height
                    );
                }
                
                if (barWholeView.comparisonView != null)
                {
                    // Set bounds for the comparison after it is done being positioned
                    barWholeView.comparisonView.lineGraphicDisplayContainer.getBounds(this, boundingRectangleBuffer);
                    barWholeView.comparisonView.rigidBody.boundingRectangle.setTo(
                        boundingRectangleBuffer.x,
                        boundingRectangleBuffer.y,
                        boundingRectangleBuffer.width,
                        boundingRectangleBuffer.height
                    );
                }
            }
            
            // Set up the bounding hit areas for the vertical labels
            for (i = 0; i < m_verticalLabelViews.length; i++)
            {
                labelView = m_verticalLabelViews[i];
                labelView.lineGraphicDisplayContainer.getBounds(this, boundingRectangleBuffer);
                labelView.rigidBody.boundingRectangle.setTo(
                    boundingRectangleBuffer.x,
                    boundingRectangleBuffer.y,
                    boundingRectangleBuffer.width,
                    boundingRectangleBuffer.height
                );
            }
        }
    }
}