package wordproblem.engine.barmodel.view
{
    import dragonbox.common.dispose.IDisposable;
    
    import feathers.display.Scale3Image;
    import feathers.display.Scale9Image;
    import feathers.textures.Scale3Textures;
    import feathers.textures.Scale9Textures;
    
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.textures.Texture;
    
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.component.RigidBodyComponent;
    import wordproblem.display.DottedRectangle;
    
    /**
     * The most basic unit for drawing a segment
     */
    public class BarSegmentView extends Sprite implements IDisposable
    {
        public var data:BarSegment;
        
        /**
         * The bounds of the view relative to the bar area widget
         */
        public var rigidBody:RigidBodyComponent;
        
        private var m_nineSliceImage:Scale9Image;
        private var m_threeSliceHorizontalImage:Scale3Image;
        private var m_threeSliceVerticalImage:Scale3Image;
        private var m_originalImage:Image;
        
        /**
         * The image to use if the segment is supposed to be hidden
         */
        private var m_hiddenImage:DottedRectangle;
        
        public function BarSegmentView(barSegment:BarSegment,
                                       nineSliceTexture:Scale9Textures, 
                                       regularTexture:Texture, 
                                       hiddenImage:DottedRectangle)
        {
            super();
            
            this.data = barSegment;
            this.rigidBody = new RigidBodyComponent(barSegment.id);
            
            // Create the image for the segment
            // To make scaling of the segment look sharp we use nine slice
            // However this fails if one of the dimensions is LESS than the padding we start the slice from
            // (i.e. if non-scaling parts exceeds the desired width)
            // In this instance we need to fall back to drawing the unsliced image
            m_nineSliceImage = new Scale9Image(nineSliceTexture);
            m_threeSliceHorizontalImage = new Scale3Image(new Scale3Textures(regularTexture, nineSliceTexture.scale9Grid.left, nineSliceTexture.scale9Grid.width, "horizontal"));
            m_threeSliceVerticalImage = new Scale3Image(new Scale3Textures(regularTexture, nineSliceTexture.scale9Grid.top, nineSliceTexture.scale9Grid.height, "vertical"));
            m_originalImage = new Image(regularTexture);
            
            m_hiddenImage = hiddenImage;
        }
        
        public function resize(unitWidth:Number, height:Number):void
        {
            this.removeChildren();
            
            var nineSliceTexture:Scale9Textures = m_nineSliceImage.textures;
            var targetWidth:Number = unitWidth * data.getValue();
            var minimumWidthForNineSlice:Number = 2 * nineSliceTexture.scale9Grid.left; // Assume padding on left and right are the same
            var minimumHeightForNineSlice:Number = 2 * nineSliceTexture.scale9Grid.top;
            
            // HACK: To avoid having invisible segments we push up the width of a segment to one even
            // if it causes things to lose proportionality
            if (targetWidth < 3)
            {
                targetWidth = 3;
            }
            
            // If segment height less than slice padding, should also not scale vertically.
            // However should scale horizontally with 3-slice
            var segmentImage:DisplayObject;
            if (data.hiddenValue != null)
            {
                m_hiddenImage.resize(targetWidth, height, 12, 2);
                segmentImage = m_hiddenImage;
            }
            else
            {
                if (targetWidth >= minimumWidthForNineSlice && height >= minimumHeightForNineSlice)
                {
                    m_nineSliceImage.color = data.color;
                    segmentImage = m_nineSliceImage;
                }
                else if (targetWidth >= minimumWidthForNineSlice && height < minimumHeightForNineSlice)
                {
                    m_threeSliceHorizontalImage.color = data.color;
                    segmentImage = m_threeSliceHorizontalImage;
                }
                else if (targetWidth < minimumWidthForNineSlice && height >= minimumHeightForNineSlice)
                {
                    m_threeSliceVerticalImage.color = data.color;
                    segmentImage = m_threeSliceVerticalImage;
                }
                else
                {
                    m_originalImage.color = data.color;
                    segmentImage = m_originalImage;
                }
                
                segmentImage.width = targetWidth;
                segmentImage.height = height;
            }
            
            addChild(segmentImage);
        }
        
        override public function dispose():void
        {
            this.removeChildren();
            
            super.dispose();
        }
    }
}