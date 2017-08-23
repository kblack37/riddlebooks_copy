package wordproblem.engine.barmodel.view;

import openfl.display.BitmapData;
import openfl.events.Event;
import wordproblem.display.PivotSprite;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.barmodel.view.BarWholeView;

import openfl.geom.Rectangle;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;

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
class BarModelView extends Sprite
{
    public var scaleFactor(get, set) : Float;
    public var unitLength(get, set) : Float;
    public var maxAllowableWidth(get, never) : Float;

    /**
     * If set to true, this component will always try to fit the current bar model
     * contents within the bounding constraints. It renders any external setting of
     * the unit length to not have any effect.
     */
    public var alwaysAutoCalculateUnitLength : Bool = false;
    
    /**
     * The height in pixels of each bar. This implicitly says all bars have the same height
     */
    public var unitHeight : Float;
    
    /**
     * Within the constraints of this view how much empty space should be on the top of
     * the first bar
     */
    public var topBarPadding : Float;
    
    /**
     * Within the constraints of this view how much empty space should be on the left of
     * the lined up bars (Stays constant)
     */
    public var leftBarPadding : Float;
    
    /*
    IMPORTANT
    Bottom and right padding is only useful when the bar model view is editable, it is specified
    only to provide space for hit areas to do things like and new vertical label on the right
    or a new bar on the bottom
    */
    public var bottomBarPadding : Float;
    public var rightBarPadding : Float;
    
    /**
     * Amount of space between each of the bars
     */
    public var barGap : Float;
    
    /**
     * The normalizing factor can be thought of as number should be treated as the 'unit length'.
     * For example, if this value is 3 and the player creates a bar from the term value 6, that new
     * bar with 6 has a unit value of 6/3=>2.
     */
    public var normalizingFactor : Float = 1;
    
    /**
     * The length in pixels of segment that is of unit one. This is used to properly draw each segment.
     */
    private var m_unitLength : Float;
    
    /**
     * This component may need to automatically resize the bars by setting the unit length
     * to new values. These new values will override those set by the application.
     * 
     * However we want to rememeber the values set by application as they will serve
     * as an upper bound to how wide we allow the auto-resized bars to be
     */
    private var m_savedUnitLength : Float;
    
    /**
     * All data properties related to the representation of the bars
     */
    private var m_barModelData : BarModelData;
    
    /**
     * List of all visible bars along with their attached labels
     */
    private var m_barWholeViews : Array<BarWholeView>;
    
    /**
     * List of all vertical bars views
     */
    private var m_verticalLabelViews : Array<BarLabelView>;
    
    /**
     * This is this layer in which all the actual bar model views are added to.
     * The main reason for this is that we can remove these objects from view at once, which is useful
     * to show just a preview of the change while hiding the original. In addition we can
     * apply a uniform scale to all the objects
     */
    private var m_objectLayer : Sprite;
    
    /**
     * Other classes can access this layer to put object that appear on top of everything, like animations
     */
    private var m_foregroundLayer : Sprite;
    
    /**
     * Get the constraining bounds of the bar model area, relative to its own frame of reference
     */
    private var m_constraints : Rectangle;
    
    /**
     * Use this to draw cards
     */
    private var m_expressionSymbolMap : ExpressionSymbolMap;
    
    /**
     * Use this to access textures
     */
    private var m_assetManager : AssetManager;
    
    public function new(unitLength : Float,
            unitHeight : Float,
            topBarPadding : Float,
            bottomBarPadding : Float,
            leftBarPadding : Float,
            rightBarPadding : Float,
            barGap : Float,
            barModelData : BarModelData,
            expressionSymbolMap : ExpressionSymbolMap,
            assetManager : AssetManager)
    {
        super();
        
        this.unitLength = unitLength;
        this.unitHeight = unitHeight;
        this.topBarPadding = topBarPadding;
        this.leftBarPadding = leftBarPadding;
        this.bottomBarPadding = bottomBarPadding;
        this.rightBarPadding = rightBarPadding;
        this.barGap = barGap;
        
        m_barWholeViews = new Array<BarWholeView>();
        m_verticalLabelViews = new Array<BarLabelView>();
        
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
    public function getExpressionSymbolMap() : ExpressionSymbolMap
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
    private function set_scaleFactor(value : Float) : Float
    {
        m_objectLayer.scaleX = m_objectLayer.scaleY = value;
        return value;
    }
    
    private function get_scaleFactor() : Float
    {
        return m_objectLayer.scaleX;
    }
    
    /**
     * (Internally, do not use this function, set the private field directly)
     */
    private function set_unitLength(value : Float) : Float
    {
        m_unitLength = value;
        
        // Everytime an external call is made to change the unit length we
        // save the value since auto resizing may overwrite
        m_savedUnitLength = value;
        return value;
    }
    
    private function get_unitLength() : Float
    {
        return m_unitLength;
    }
    
    private function get_maxAllowableWidth() : Float
    {
        // Note the primary purpose of the padding is to provide additional space for hit areas
        return this.getConstraints().width - this.leftBarPadding - this.rightBarPadding;
    }
    
    /**
     * MUST BE CALLED AT LEAST ONCE
     */
    public function setDimensions(width : Float, height : Float) : Void
    {
        m_constraints.width = width;
        m_constraints.height = height;
    }
    
    /**
     * These are the fixed upper limits to the size of this view.
     * Differs from normal width and height in that the constraints are always fixed
     * regardless of the size of the display objects contained inside this view.
     */
    public function getConstraints() : Rectangle
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
    public function getUnitValueFromBarModelData(barModelData : BarModelData, excessPadding : Float = 0) : Float
    {
        var maxBarUnitValue : Float = barModelData.getMaxBarUnitValue();
        var desiredUnitLength : Float = (maxAllowableWidth - excessPadding) / (maxBarUnitValue * this.scaleFactor);
        return desiredUnitLength;
    }
    
    public function setBarModelData(barModelData : BarModelData) : Void
    {
        m_barModelData = barModelData;
        
        while (m_barWholeViews.length > 0)
        {
            var barWholeView : BarWholeView = m_barWholeViews.pop();
			if (barWholeView.parent != null) barWholeView.parent.removeChild(barWholeView);
            barWholeView.dispose();
        }
        
        while (m_verticalLabelViews.length > 0)
        {
            var barLabelView : BarLabelView = m_verticalLabelViews.pop();
            if (barLabelView.parent != null) barLabelView.parent.removeChild(barLabelView);
        }
    }
    
    public function createBarLabelView(barLabel : BarLabel) : BarLabelView
    {
        var leftBracketBitmapData : BitmapData = m_assetManager.getBitmapData("bracket_left_edge");
        var rightBracketBitmapData : BitmapData = m_assetManager.getBitmapData("bracket_right_edge");
        var middleBracketBitmapData : BitmapData = m_assetManager.getBitmapData("bracket_middle");
        var fullBracketBitmapData : BitmapData = m_assetManager.getBitmapData("bracket_full");
        
        var blankBitmapDataPadding : Float = 12;
        var blankBitmapData : BitmapData = m_assetManager.getBitmapData("wildcard");
        var blankNineSliceGrid : Rectangle = new Rectangle(blankBitmapDataPadding, blankBitmapDataPadding, blankBitmapData.width - 2 * blankBitmapDataPadding, blankBitmapData.height - 2 * blankBitmapDataPadding);
        
        var dottedLineCornerBitmapData : BitmapData = m_assetManager.getBitmapData("dotted_line_corner");
        var dottedLineSegmentBitmapData : BitmapData = m_assetManager.getBitmapData("dotted_line_segment");
        
        // Look at the expression symbol map for styling properties
        // Color text inside segment differently than outside
        var fontColor : Int = ((barLabel.bracketStyle == BarLabel.BRACKET_NONE)) ? 
        0x000000 : 0xFFFFFF;
        var symbolData : SymbolData = m_expressionSymbolMap.getSymbolDataFromValue(barLabel.value);
        
        var hiddenLabelImage : DottedRectangle = new DottedRectangle(blankBitmapData, blankNineSliceGrid, 1.0, dottedLineCornerBitmapData, dottedLineSegmentBitmapData);
        var labelImage : DisplayObject = null;
        if (barLabel.numImages > 1) 
        {
            var labelImageContainer : Sprite = new Sprite();
            var i : Int = 0;
            for (i in 0...barLabel.numImages){
                var cardSymbol : DisplayObject = m_expressionSymbolMap.getCardFromSymbolValue(barLabel.value);
                labelImageContainer.addChild(cardSymbol);
            }
            labelImage = labelImageContainer;
        }
        else 
        {
            labelImage = m_expressionSymbolMap.getCardFromSymbolValue(barLabel.value);
        }
        
        var barLabelView : BarLabelView = new BarLabelView(
			barLabel, 
			symbolData.fontName, 
			fontColor, 
			leftBracketBitmapData, 
			rightBracketBitmapData, 
			middleBracketBitmapData, 
			fullBracketBitmapData, 
			symbolData.abbreviatedName, 
			labelImage, 
			symbolData.symbolTextureName != null, 
			hiddenLabelImage
        );
        return barLabelView;
    }
    
    public function createBarComparisonView(barComparison : BarComparison) : BarComparisonView
    {
        var comparisonLeftBitmapData : BitmapData = m_assetManager.getBitmapData("comparison_left");
        var comparisonRightBitmapData : BitmapData = m_assetManager.getBitmapData("comparison_right");
        var comparisonFullBitmapData : BitmapData = m_assetManager.getBitmapData("comparison_full");
		
		var threeSlicePadding : Float = 28;
		var threeSliceGrid = new Rectangle(threeSlicePadding, 0, comparisonFullBitmapData.width - 2 * threeSlicePadding, comparisonFullBitmapData.height);
        
        var symbolData : SymbolData = m_expressionSymbolMap.getSymbolDataFromValue(barComparison.value);
        var fontName : String = symbolData.fontName;
        var textName : String = symbolData.name;
        var symbolImage : PivotSprite = new PivotSprite();
		symbolImage.addChild(m_expressionSymbolMap.getCardFromSymbolValue(barComparison.value));
        symbolImage.pivotX = 0;
        symbolImage.pivotY = 0;
        symbolImage.scaleX = symbolImage.scaleY = 0.6;
        var barComparisonView : BarComparisonView = new BarComparisonView(
			barComparison, 
			1, 
			textName, 
			fontName, 
			0xFFFFFF, 
			symbolImage, 
			threeSliceGrid,
			comparisonFullBitmapData
        );
        return barComparisonView;
    }
    
    public function getBarSegmentViewById(segmentId : String) : BarSegmentView
    {
        var matchingSegmentView : BarSegmentView = null;
        var numBarWholeViews : Int = m_barWholeViews.length;
        var i : Int = 0;
        var barWholeView : BarWholeView = null;
        for (i in 0...numBarWholeViews){
            barWholeView = m_barWholeViews[i];
            
            var j : Int = 0;
            var numSegmentViews : Int = barWholeView.segmentViews.length;
            var barSegmentView : BarSegmentView = null;
            for (j in 0...numSegmentViews){
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
    
    public function getBarLabelViewById(labelId : String) : BarLabelView
    {
        var matchingBarLabelView : BarLabelView = null;
        var numBarWholeViews : Int = m_barWholeViews.length;
        var i : Int = 0;
        var barWholeView : BarWholeView = null;
        for (i in 0...numBarWholeViews){
            barWholeView = m_barWholeViews[i];
            
            var j : Int = 0;
            var numBarLabelViews : Int = barWholeView.labelViews.length;
            var barLabelView : BarLabelView = null;
            for (j in 0...numBarLabelViews){
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
    
    public function getBarWholeViewById(barWholeId : String) : BarWholeView
    {
        var matchingBarWholeView : BarWholeView = null;
        var i : Int = 0;
        var numBarWholeViews : Int = m_barWholeViews.length;
        var barWholeView : BarWholeView = null;
        for (i in 0...numBarWholeViews){
            barWholeView = m_barWholeViews[i];
            if (barWholeView.data.id == barWholeId) 
            {
                matchingBarWholeView = barWholeView;
                break;
            }
        }
        
        return matchingBarWholeView;
    }
    
    public function getVerticalBarLabelViewById(verticalBarLabelId : String) : BarLabelView
    {
        var matchingBarLabelView : BarLabelView = null;
        var i : Int = 0;
        var numVerticalBarLabelViews : Int = m_verticalLabelViews.length;
        var verticalBarLabelView : BarLabelView = null;
        for (i in 0...numVerticalBarLabelViews){
            verticalBarLabelView = m_verticalLabelViews[i];
            if (verticalBarLabelView.data.id == verticalBarLabelId) 
            {
                matchingBarLabelView = verticalBarLabelView;
                break;
            }
        }
        
        return matchingBarLabelView;
    }
    
    public function getBarModelData() : BarModelData
    {
        return m_barModelData;
    }
    
    public function getBarWholeViews() : Array<BarWholeView>
    {
        return m_barWholeViews;
    }
    
    public function getVerticalBarLabelViews() : Array<BarLabelView>
    {
        return m_verticalLabelViews;
    }
    
    /**
     * Get back a layer in which any extra display objects added should appear on top of
     * the bar model pieces
     */
    public function getForegroundLayer() : DisplayObjectContainer
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
    public function checkAllBarSegmentsFitInView(barModelData : BarModelData) : Bool
    {
        // We first need to calculate the segment value of the longest total bar
        var i : Int = 0;
        var numBars : Int = barModelData.barWholes.length;
        var maxBarValue : Float = 0;
        for (i in 0...numBars){
            var barWhole : BarWhole = barModelData.barWholes[i];
            var barValue : Float = barWhole.getValue();
            if (barValue > maxBarValue) 
            {
                maxBarValue = barValue;
            }
        }  
		
		// Figure out the pixels per unit value if the longest total bar were to stretch  
        // out to fit the entire horizontal space of the bar
        var maxViewSpace : Float = this.getConstraints().width;
        var maxPixelsPerUnit : Float = maxViewSpace / maxBarValue;
        
        // Find the smallest possible bar segment and see if the unit value
        // we calculated would result in a box that would appear visible
		var minSegmentValue : Float = Math.pow(2, 30);
        for (i in 0...numBars){
            var barWhole = barModelData.barWholes[i];
            var barSegments : Array<BarSegment> = barWhole.barSegments;
            var j : Int = 0;
            for (j in 0...barSegments.length){
                var barSegment : BarSegment = barSegments[j];
                var barSegmentValue : Float = barSegment.getValue();
                if (minSegmentValue > barSegmentValue) 
                {
                    minSegmentValue = barSegmentValue;
                }
            }
        }
        
        var minPixelValue : Float = minSegmentValue * maxPixelsPerUnit;
        var minPixelThreshold : Float = 16;
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
    public function redraw(doDispatchEvent : Bool = true, centerContents : Bool = false) : Void
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
            var objectBounds : Rectangle = m_objectLayer.getBounds(this);
            m_objectLayer.x = (m_constraints.width - objectBounds.width) * 0.5 - leftBarPadding;
            m_objectLayer.y = (m_constraints.height - objectBounds.height) * 0.5 - topBarPadding;
            
            // Center may change the bounds as well
            this.recalculateBounds();
        } 
		
		// Dispatch event letting other objects know that the view has finished drawing and laying out the objects  
        if (doDispatchEvent) 
        {
            dispatchEvent(new Event(GameEvent.BAR_MODEL_AREA_REDRAWN));
        }
    }
    
    /**
     * Just looking at the existing views, this function should lay everything out again.
     * (Useful if a property of an existing part of the model changes and we need to resize or reposition but
     * do not need to create new visual objects)
     */
    public function layout() : Void
    {
        var prevScale : Float = this.scaleFactor;
        this.scaleFactor = 1.0;
        var hiddenSegmentStack : Array<BarSegmentView> = new Array<BarSegmentView>();
        var shownSegmentStack : Array<BarSegmentView> = new Array<BarSegmentView>();
        
        // The redraw function needs to first draw unscaled versions of the bars and their segments.
        var i : Int = 0;
        var numBarWholesViews : Int = this.getBarWholeViews().length;
        for (i in 0...numBarWholesViews){
            var barWholeView : BarWholeView = this.getBarWholeViews()[i];
            var xSegmentOffset : Float = 0;
            
            var j : Int = 0;
            var numSegmentViews : Int = barWholeView.segmentViews.length;
            
            // If bar whole should be group together hidden segments as one, then first re-order
            // the segments such that hidden ones are bunched to the right.
            // This is a special case only used to draw the dotted outline on a bar for tutorials
            if (!barWholeView.data.displayHiddenSegments) 
            {
                for (j in 0...numSegmentViews){
                    var barSegmentView = barWholeView.segmentViews[j];
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
                barWholeView.data.barSegments = new Array<BarSegment>();
				barWholeView.segmentViews = new Array<BarSegmentView>();
                while (shownSegmentStack.length > 0)
                {
                    var barSegmentView = shownSegmentStack.shift();
                    barWholeView.data.barSegments.push(barSegmentView.data);
                    barWholeView.segmentViews.push(barSegmentView);
                }
                
                while (hiddenSegmentStack.length > 0)
                {
                    var barSegmentView = hiddenSegmentStack.shift();
                    barWholeView.data.barSegments.push(barSegmentView.data);
                    barWholeView.segmentViews.push(barSegmentView);
                }
            }
			
			// resize and reposition the segments contained in this view  
            for (j in 0...numSegmentViews){
                var barSegmentView : BarSegmentView = barWholeView.segmentViews[j];
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
            var barLabelView : BarLabelView = null;
            var numLabelViews : Int = barWholeView.labelViews.length;
            for (j in 0...numLabelViews){
                barLabelView = barWholeView.labelViews[j];
                
                // Need to get the segment widths in order to calculate the label length
                // Combine the lengths of all segments between the start and end of the label
                // Note that label length also depends on whether the bar is scaled.
                var k : Int = 0;
                var labelLength : Float = 0;
                var startSegmentIndex : Int = barLabelView.data.startSegmentIndex;
                var endSegmentIndex : Int = barLabelView.data.endSegmentIndex;
                for (k in startSegmentIndex...endSegmentIndex + 1){
                    labelLength += barWholeView.data.barSegments[k].getValue() * this.unitLength;
                }
                
                barLabelView.rescaleAndRedraw(labelLength, -1, 1.0, 1.0);
            }
        }  
		
		// Once we have done a first pass creating all the bars and horizontal labels we need to determine their positioning  
		// and even their scaling within each whole bar. 
        // First orient the labels on the bars 
        for (i in 0...m_barWholeViews.length){
            var barWholeView = m_barWholeViews[i];
            m_objectLayer.addChild(barWholeView);
            
            var numLabelViews = barWholeView.labelViews.length;
            
            // First pass draw all the label on top of the bar, need to start backwards
            // as later ones are closer
            var yOffsetLabel : Float = 0;
            var numTopLabels : Int = 0;
            var j = numLabelViews - 1;
            while (j >= 0){
                var barLabelView = barWholeView.labelViews[j];
                
                if (barLabelView.data.isAboveSegment && barLabelView.data.bracketStyle != BarLabel.BRACKET_NONE) 
                {
                    barLabelView.y = yOffsetLabel;
                    barLabelView.x = barWholeView.segmentViews[barLabelView.data.startSegmentIndex].x;
                    
                    numTopLabels++;
                    yOffsetLabel += barLabelView.height;
                }
                j--;
            }  
			
			// Shift down all the segments by the new y-offset that was caused by the top labels  
            if (numTopLabels > 0) 
            {
                yOffsetLabel += 5;
            }
            
            var numSegmentViews = barWholeView.segmentViews.length;
            for (j in 0...numSegmentViews){
                barWholeView.segmentViews[j].y = yOffsetLabel;
            }  
			
			// Position all of the labels that go underneath the bar segment  
            yOffsetLabel += barWholeView.segmentViews[0].height;
            for (j in 0...numLabelViews){
                var barLabelView = barWholeView.labelViews[j];
                
                // Also take care of situations where the label should sit directly on top of the segment
                if (barLabelView.data.bracketStyle == BarLabel.BRACKET_NONE) 
                {
                    var targetSegmentView : BarSegmentView = barWholeView.segmentViews[barLabelView.data.startSegmentIndex];
                    barLabelView.x = targetSegmentView.x;
                    barLabelView.y = targetSegmentView.y;
                    barLabelView.rescaleAndRedraw(targetSegmentView.width, targetSegmentView.height, 1.0, 1.0);
                }
                else if (!barLabelView.data.isAboveSegment && barLabelView.data.bracketStyle != BarLabel.BRACKET_NONE) 
                {
                    // Need to get the segment widths in order to calculate the label length
                    // Combine the lengths of all segments between the start and end of the label
                    // Note that label length also depends on whether the bar is scaled.
                    var startIndex : Int = barLabelView.data.startSegmentIndex;
                    var endIndex : Int = barLabelView.data.endSegmentIndex;
                    var labelLength = 0;
                    for (k in startIndex...endIndex + 1){
                        labelLength += Std.int(barWholeView.segmentViews[k].data.getValue() * this.unitLength);
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
        var yOffsetBar : Float = topBarPadding;
        var boundingRectangleBuffer : Rectangle = new Rectangle();
        for (i in 0...m_barWholeViews.length){
            var barWholeView = m_barWholeViews[i];
            boundingRectangleBuffer = barWholeView.getBounds(this);
            
            barWholeView.x = this.leftBarPadding;
            barWholeView.y = yOffsetBar;
            
            // HACK: Do not apply gap if this bar has a bottom label or next one has a top label
            var gap : Float = this.barGap;
            var barLabelViews : Array<BarLabelView> = barWholeView.labelViews;
            for (barLabelView in barLabelViews)
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
        for (i in 0...m_barWholeViews.length){
            var barWholeView = m_barWholeViews[i];
            
            var segmentView : BarSegmentView = null;
            var segmentViews : Array<BarSegmentView> = barWholeView.segmentViews;
            var numSegmentViews = segmentViews.length;
            for (j in 0...numSegmentViews){
                segmentView = segmentViews[j];
                barWholeView.addChild(segmentView);  // Make sure segment view is added as part of the stage  
                boundingRectangleBuffer = segmentView.getBounds(this);
                segmentView.rigidBody.boundingRectangle.setTo(
                        boundingRectangleBuffer.x,
                        boundingRectangleBuffer.y,
                        boundingRectangleBuffer.width,
                        boundingRectangleBuffer.height
                        );
            }
            
            var labelView : BarLabelView = null;
            var labelViews : Array<BarLabelView> = barWholeView.labelViews;
            for (j in 0...labelViews.length){
                labelView = labelViews[j];
                barWholeView.addChild(labelView);  // Make sure label view is added as part of the stage  
                boundingRectangleBuffer = labelView.lineGraphicDisplayContainer.getBounds(this);
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
        var numBarWholeViews : Int = m_barWholeViews.length;
        for (i in 0...numBarWholeViews){
            var barWholeView = m_barWholeViews[i];
            
            var leftCompareEdge : Float = barWholeView.segmentViews[barWholeView.segmentViews.length - 1].rigidBody.boundingRectangle.right;
            var barComparisonView : BarComparisonView = barWholeView.comparisonView;
            if (barComparisonView != null) 
            {
                var barWholeViewToCompare : BarWholeView = null;
                for (j in 0...numBarWholeViews){
                    barWholeViewToCompare = m_barWholeViews[j];
                    if (barWholeViewToCompare.data.id == barComparisonView.data.barWholeIdComparedTo) 
                    {
                        var rightCompareEdge : Float = barWholeViewToCompare.segmentViews[barComparisonView.data.segmentIndexComparedTo].rigidBody.boundingRectangle.right;
                        barComparisonView.resizeToLength(rightCompareEdge - leftCompareEdge);
                        
                        var referenceSegmentView : BarSegmentView = barWholeView.segmentViews[0];
                        barComparisonView.y = referenceSegmentView.y + (referenceSegmentView.rigidBody.boundingRectangle.height - barComparisonView.height) * 0.5;
                        break;
                    }
                }
				
				// Set bounds for the comparison after it is done being positioned  
                boundingRectangleBuffer = barWholeView.comparisonView.lineGraphicDisplayContainer.getBounds(this);
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
        var startingXOffsetForVertical : Float = 0;
        for (i in 0...numBarWholesViews){
            var barWholeView = m_barWholeViews[i];
            boundingRectangleBuffer = barWholeView.getBounds(this);
            
            startingXOffsetForVertical = Math.max(startingXOffsetForVertical, boundingRectangleBuffer.right);
        }
        
        var verticalBarXOffset : Float = 20;
        var numVerticalBars : Int = m_barModelData.verticalBarLabels.length;
        for (i in 0...numVerticalBars){
            var barLabelView = this.getVerticalBarLabelViews()[i];
            var startSegmentIndex = barLabelView.data.startSegmentIndex;
            var endSegmentIndex = barLabelView.data.endSegmentIndex;
            
            var startingBarView : BarWholeView = m_barWholeViews[startSegmentIndex];
            var topY : Float = ((startingBarView.segmentViews.length > 0)) ? 
            startingBarView.segmentViews[0].rigidBody.boundingRectangle.top : 
            startingBarView.y;
            
            var endingBarView : BarWholeView = m_barWholeViews[endSegmentIndex];
            var bottomY : Float = ((endingBarView.segmentViews.length > 0)) ? 
            endingBarView.segmentViews[0].rigidBody.boundingRectangle.bottom : 
            endingBarView.y + endingBarView.height;
            
            barLabelView.rescaleAndRedraw(-1, bottomY - topY, 1.0, 1.0);
            barLabelView.x = startingXOffsetForVertical + verticalBarXOffset;
            barLabelView.y = topY;
            m_objectLayer.addChild(barLabelView);
            
            verticalBarXOffset += barLabelView.width;
        } 
		
		// Set up the bounding hit areas for the vertical labels  
        for (i in 0...m_verticalLabelViews.length){
            var labelView = m_verticalLabelViews[i];
            boundingRectangleBuffer = labelView.lineGraphicDisplayContainer.getBounds(this);
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
    
    private function _redraw() : Void
    {
        // As a simple first take, whenever redraw is called we dispose of everything
        // and recreate each view.
        while (m_barWholeViews.length > 0)
        {
			var barWholeView = m_barWholeViews.pop();
			if (barWholeView.parent != null) barWholeView.parent.removeChild(barWholeView);
			barWholeView = null;
        }
        
        while (m_verticalLabelViews.length > 0)
        {
            var verticalLabelView = m_verticalLabelViews.pop();
			if (verticalLabelView.parent != null) verticalLabelView.parent.removeChild(verticalLabelView);
			verticalLabelView = null;
        } 
		
		// The redraw function needs to first draw unscaled versions of the bars and their segments.  
        var i : Int = 0;
        var numBarWholes : Int = m_barModelData.barWholes.length;
        var segmentBitmapData : BitmapData = m_assetManager.getBitmapData("card_background_square");
        
        var blankBitmapDataPadding : Float = 12;
        var blankBitmapData : BitmapData = m_assetManager.getBitmapData("wildcard");
        var blankNineSliceGrid : Rectangle = new Rectangle(blankBitmapDataPadding,
			blankBitmapDataPadding,
			blankBitmapData.width - 2 * blankBitmapDataPadding,
			blankBitmapData.height - 2 * blankBitmapDataPadding
		);
        
        var dottedLineCornerBitmapData : BitmapData = m_assetManager.getBitmapData("dotted_line_corner");
        var dottedLineSegmentBitmapData : BitmapData = m_assetManager.getBitmapData("dotted_line_segment");
        
        for (i in 0...numBarWholes){
            var barWhole : BarWhole = m_barModelData.barWholes[i];
            
            // Draw and re-position the segments contained in this view
            var j : Int = 0;
            var barSegment : BarSegment = null;
            var numSegments : Int = barWhole.barSegments.length;
            var barWholeHiddenImage : DottedRectangle = new DottedRectangle(blankBitmapData, blankNineSliceGrid, 1, dottedLineCornerBitmapData, dottedLineSegmentBitmapData);
            var barWholeView : BarWholeView = new BarWholeView(barWhole, barWholeHiddenImage);
            for (j in 0...numSegments){
                barSegment = barWhole.barSegments[j];
                
                var hiddenSegment : DottedRectangle = new DottedRectangle(blankBitmapData, blankNineSliceGrid, 1, dottedLineCornerBitmapData, dottedLineSegmentBitmapData);
                var barSegmentView : BarSegmentView = new BarSegmentView(
					barSegment, 
					segmentBitmapData, 
					hiddenSegment
                );
                barWholeView.addSegmentView(barSegmentView);
            }  
			
			// Add the comparison view if it exists, it goes at the edge of the bar  
            // Its length requires looking at the other bar to compare against
            var barComparison : BarComparison = barWhole.barComparison;
            if (barComparison != null) 
            {
                var barComparisonView : BarComparisonView = this.createBarComparisonView(barComparison);
                barWholeView.addComparisonView(barComparisonView);
            }
            
            m_barWholeViews.push(barWholeView);
            
            // The horizontal labels can be drawn after the segments have been created.
            // However they cannot be fully positioned yet, as this may require knowledge about other bars first
            var barLabel : BarLabel = null;
            var numLabels : Int = barWhole.barLabels.length;
            for (j in 0...numLabels){
                barLabel = barWhole.barLabels[j];
                var barLabelView : BarLabelView = this.createBarLabelView(barLabel);
                barWholeView.addLabelView(barLabelView);
            }
        }  
		
		// Create and add the vertical labels, their position changes depending on the vertical position of all  
		// the items. 
		// The vertical bars should stack from left to right
        // The starting x offset should be the length of the longest bar
        var numVerticalBars : Int = m_barModelData.verticalBarLabels.length;
        for (i in 0...numVerticalBars){
            var barLabel = m_barModelData.verticalBarLabels[i];
            var barLabelView = this.createBarLabelView(barLabel);
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
    private function checkAndCorrectBarSpillover() : Void
    {
        // Look through all the bars and get their bounds relative to the view
        // Allow for extra padding at the edge of the constraints so pieces don't
        // sit exactly on the edge
        var maxAllowableHeight : Float = this.getConstraints().height - topBarPadding - bottomBarPadding;
        var boundsBuffer : Rectangle = new Rectangle();
        boundsBuffer = m_objectLayer.getBounds(this);
        
        // If current bounds of the bar object exceeds the max constraints, then we need to rescale
        // and redraw. Also handles the case where we want the object to go back to normal unscaled size
        // Find the amount to scale horizontally so the object fits
        // Find the amount to scale vertically so the object fits
        var verticalScaleFactor : Float = Math.min(1.0, maxAllowableHeight / (boundsBuffer.height / this.scaleFactor));
        var newScalefactor : Float = verticalScaleFactor;
        
        if (this.scaleFactor != newScalefactor) 
        {
            this.scaleFactor = newScalefactor;
            
            // Re-calculate bounds
            boundsBuffer = m_objectLayer.getBounds(this);
        }  
		
		// Force a redraw if the unit length was altered (This should take existing views and just reposition them  
		// to avoid recreating new views) 
		// Iterate through every bar, we want to find the one with the greatest value   
		// We also need to take into account scaling, since scaling down will shrink the segments such that they won't quite fit 
        // to the edge. 
        var maxScaledWidthOfLongestBar : Float = this.m_barModelData.getMaxBarUnitValue() * this.unitLength * this.scaleFactor;
        var excessPadding : Float = boundsBuffer.width - maxScaledWidthOfLongestBar;
        var desiredUnitLength : Float = this.getUnitValueFromBarModelData(m_barModelData, excessPadding);
        var newUnitLength : Float = m_unitLength;
        if (desiredUnitLength != this.unitLength && desiredUnitLength != Math.POSITIVE_INFINITY) 
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
    private function recalculateBounds() : Void
    {
        var i : Int = 0;
        var boundingRectangleBuffer : Rectangle = new Rectangle();
        for (i in 0...m_barWholeViews.length){
            var barWholeView : BarWholeView = m_barWholeViews[i];
            
            var segmentView : BarSegmentView = null;
            var segmentViews : Array<BarSegmentView> = barWholeView.segmentViews;
            var numSegmentViews : Int = segmentViews.length;
            var j : Int = 0;
            for (j in 0...numSegmentViews){
                segmentView = segmentViews[j];
                barWholeView.addChild(segmentView);  // Make sure segment view is added as part of the stage  
                boundingRectangleBuffer = segmentView.getBounds(this);
                segmentView.rigidBody.boundingRectangle.setTo(
                        boundingRectangleBuffer.x,
                        boundingRectangleBuffer.y,
                        boundingRectangleBuffer.width,
                        boundingRectangleBuffer.height
                        );
            }
            
            var labelView : BarLabelView = null;
            var labelViews : Array<BarLabelView> = barWholeView.labelViews;
            for (j in 0...labelViews.length){
                labelView = labelViews[j];
                barWholeView.addChild(labelView);  // Make sure label view is added as part of the stage  
                boundingRectangleBuffer = labelView.lineGraphicDisplayContainer.getBounds(this);
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
                boundingRectangleBuffer = barWholeView.comparisonView.lineGraphicDisplayContainer.getBounds(this);
                barWholeView.comparisonView.rigidBody.boundingRectangle.setTo(
                        boundingRectangleBuffer.x,
                        boundingRectangleBuffer.y,
                        boundingRectangleBuffer.width,
                        boundingRectangleBuffer.height
                        );
            }
        }  
		
		// Set up the bounding hit areas for the vertical labels  
        for (i in 0...m_verticalLabelViews.length){
            var labelView = m_verticalLabelViews[i];
            boundingRectangleBuffer = labelView.lineGraphicDisplayContainer.getBounds(this);
            labelView.rigidBody.boundingRectangle.setTo(
                    boundingRectangleBuffer.x,
                    boundingRectangleBuffer.y,
                    boundingRectangleBuffer.width,
                    boundingRectangleBuffer.height
                    );
        }
    }
}
