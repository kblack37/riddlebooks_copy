package wordproblem.creator.scripts
{
    import flash.geom.Rectangle;
    
    import dragonbox.common.ui.MouseState;
    
    import feathers.display.Scale9Image;
    import feathers.textures.Scale9Textures;
    
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.events.Event;
    import starling.textures.Texture;
    
    import wordproblem.creator.ProblemCreateEvent;
    import wordproblem.creator.WordProblemCreateState;
    import wordproblem.resource.AssetManager;
    
    /**
     * When the user is actively trying to highlight something in the text area, we should add a graphic just below the
     * mouse
     */
    public class ChangeMouseOnHighlightActive extends BaseProblemCreateScript
    {
        private var m_mouseState:MouseState;
        
        private var m_highlightActive:Boolean;
        private var m_highlightIndicatorImage:Scale9Image;
        private var m_highlightIndicatorTween:Tween;

        public function ChangeMouseOnHighlightActive(createState:WordProblemCreateState, 
                                                     assetManager:AssetManager,
                                                     mouseState:MouseState,
                                                     id:String=null, 
                                                     isActive:Boolean=true)
        {
            super(createState, assetManager, id, isActive);
            
            m_mouseState = mouseState;
            m_highlightActive = false;
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            if (m_isReady)
            {
                m_createState.removeEventListener(ProblemCreateEvent.USER_HIGHLIGHT_STARTED, onHighlightStarted);
                m_createState.removeEventListener(ProblemCreateEvent.USER_HIGHLIGHT_CANCELLED, onHighlightFinished);
                m_createState.removeEventListener(ProblemCreateEvent.USER_HIGHLIGHT_FINISHED, onHighlightFinished);
                if (value)
                {
                    m_createState.addEventListener(ProblemCreateEvent.USER_HIGHLIGHT_STARTED, onHighlightStarted);
                    m_createState.addEventListener(ProblemCreateEvent.USER_HIGHLIGHT_CANCELLED, onHighlightFinished);
                    m_createState.addEventListener(ProblemCreateEvent.USER_HIGHLIGHT_FINISHED, onHighlightFinished);
                }
            }
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_highlightIndicatorImage.removeFromParent(true);
            Starling.juggler.remove(m_highlightIndicatorTween);
        }
        
        override public function visit():int
        {
            if (m_isActive && m_isReady)
            {
                if (m_highlightActive)
                {
                    if (!m_highlightIndicatorImage.parent)
                    {
                        m_createState.addChild(m_highlightIndicatorImage);
                    }
                    
                    m_highlightIndicatorImage.x = m_mouseState.mousePositionThisFrame.x;
                    m_highlightIndicatorImage.y = m_mouseState.mousePositionThisFrame.y;
                    
                    if (m_mouseState.leftMouseDown)
                    {
                        m_highlightIndicatorImage.alpha = 0.4;
                    }
                    else
                    {
                        m_highlightIndicatorImage.alpha = 1.0;
                    }
                }
            }
            return super.visit();
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            setIsActive(m_isActive);
            
            var padding:Number = 4;
            var indicatorTexture:Texture = m_assetManager.getTexture("card_background_square");
            var scale9Texture:Scale9Textures = new Scale9Textures(indicatorTexture,
                new Rectangle(padding, padding, indicatorTexture.width - 2 * padding, indicatorTexture.height - 2 * padding));
            var indicatorImage:Scale9Image = new Scale9Image(scale9Texture);
            indicatorImage.pivotX = indicatorTexture.width * 0.5;
            indicatorImage.pivotY = indicatorTexture.height * 0.5;
            
            var desiredWidth:Number = 32;
            indicatorImage.scaleX = indicatorImage.scaleY = (desiredWidth / indicatorTexture.width);
            
            m_highlightIndicatorImage = indicatorImage;
            
            m_highlightIndicatorTween = new Tween(m_highlightIndicatorImage, 0.5);
            m_highlightIndicatorTween.animate("scaleX", indicatorImage.scaleX * 1.3);
            m_highlightIndicatorTween.animate("scaleY", indicatorImage.scaleX * 1.3);
            m_highlightIndicatorTween.repeatCount = 0;
            m_highlightIndicatorTween.reverse = true;
        }
        
        private function onHighlightStarted(event:Event, params:Object):void
        {
            // Get the color of the highlight based on the id
            var barPartName:String = params.id;
            var styleInformation:Object = m_createState.getCurrentLevel().currentlySelectedBackgroundData;
            if (styleInformation != null && styleInformation.hasOwnProperty("highlightColors"))
            {
                m_highlightIndicatorImage.color = styleInformation["highlightColors"][barPartName];
            }
            
            m_highlightActive = true;
            
            Starling.juggler.add(m_highlightIndicatorTween);
        }
        
        // TODO: highlight finished does not trigger if the user clicks on the bar model element to toggle off the highlight
        private function onHighlightFinished():void
        {
            m_highlightActive = false;
            m_highlightIndicatorImage.removeFromParent();
            
            Starling.juggler.remove(m_highlightIndicatorTween);
        }
    }
}