package wordproblem.state
{
    import flash.geom.Point;
    
    import dragonbox.common.particlesystem.zone.DiskZone;
    import dragonbox.common.state.BaseState;
    import dragonbox.common.state.IStateMachine;
    import dragonbox.common.time.Time;
    import dragonbox.common.ui.MouseState;
    import dragonbox.common.util.XColor;
    
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.display.Sprite;
    import starling.text.TextField;
    import starling.textures.Texture;
    import starling.utils.HAlign;
    
    import wordproblem.engine.text.GameFonts;
    import wordproblem.resource.AssetManager;
    
    /**
     * There is potentially some amount of time where the game needs to load resources
     * for a level. At this time we do not want any part of the screen to be visible.
     */
    public class WordProblemLoadingState extends BaseState
    {
        private var m_ratioTextField:TextField; 
        private var m_loadingTextField:TextField;
        private var m_assetManager:AssetManager;
        private var m_width:Number;
        private var m_height:Number;
        
        private var m_msSinceLastThoughtBubble:int;
        private var m_thoughBubblePositions:Vector.<Point>;
        private var m_positionPicker:DiskZone;

        private static var THOUGHT_VERBS:Vector.<String>;
        private static var THOUGHT_NOUNS:Vector.<String>;
        
        private var m_activeAnimations:Vector.<Object>;
        private var m_thoughtBubbleColors:Vector.<uint>;
        
        public function WordProblemLoadingState(stateMachine:IStateMachine, 
                                                width:Number, 
                                                height:Number, 
                                                assetManager:AssetManager)
        {
            super(stateMachine);
            
            if (THOUGHT_VERBS == null)
            {
                THOUGHT_VERBS = new Vector.<String>();
                THOUGHT_VERBS.push(
                    "Adding",
                    "Putting in",
                    "Removing",
                    "Placing",
                    "Gathering",
                    "Creating",
                    "Thinking of",
                    "Positioning",
                    "Loading",
                    "Checking"
                );
            }
            
            if (THOUGHT_NOUNS == null)
            {
                THOUGHT_NOUNS = new Vector.<String>();
                THOUGHT_NOUNS.push(
                    "words",
                    "questions",
                    "blocks",
                    "numbers",
                    "punctuation",
                    "math",
                    "equations",
                    "names",
                    "characters",
                    "themes",
                    "sentences",
                    "phrases",
                    "hints",
                    "pictures",
                    "parts",
                    "unicorns",
                    "gremlins",
                    "rainbows",
                    "spaceships",
                    "colors"
                );
            }
            
            m_width = width;
            m_height = height;
            m_assetManager = assetManager;
        }
        
        override public function enter(fromState:Object, params:Vector.<Object>=null):void
        {
            m_activeAnimations = new Vector.<Object>();
            m_thoughtBubbleColors = XColor.getCandidateColorsForSession();
            
            var backgroundTexture:Texture = m_assetManager.getTexture("login_background");
            var backgroundImage:Image = new Image(backgroundTexture);
            backgroundImage.width = m_width;
            backgroundImage.height = m_height;
            addChild(backgroundImage);
            
            m_ratioTextField = new TextField(width, height + 100, "", "Verdana", 40, 0x000000);
            m_ratioTextField.hAlign = HAlign.LEFT;
            
            m_loadingTextField = new TextField(width, height, "Loading", "Verdana", 40, 0x000000);
            m_loadingTextField.hAlign = HAlign.LEFT;
            
            m_msSinceLastThoughtBubble = int.MAX_VALUE;
            
            m_thoughBubblePositions = new Vector.<Point>();
            m_positionPicker = new DiskZone(m_width * 0.5, m_height * 0.5, Math.min(m_width, m_height) * 0.45, Math.min(m_width, m_height) * 0.35, m_height / m_width);
        }
        
        override public function exit(toState:Object):void
        {
            // Any existing tweens or though bubble images should be disposed of
            removeChildren(0, -1, true);
            
            for each (var animationObject:Object in m_activeAnimations)
            {
                if (animationObject.hasOwnProperty("start"))
                {
                    Starling.juggler.remove(animationObject.start);
                }
                
                if (animationObject.hasOwnProperty("end"))
                {
                    Starling.juggler.remove(animationObject.end);
                }
            }
        }
        
        override public function update(time:Time, mouseState:MouseState):void
        {
            if((time.currentTimeMilliseconds % 1600) < 400)
            {
                m_loadingTextField.text = "Loading";
            }
            else if((time.currentTimeMilliseconds % 1600) < 800)
            {
                m_loadingTextField.text = "Loading.";
            }
            else if((time.currentTimeMilliseconds % 1600) < 1200)
            {
                m_loadingTextField.text = "Loading..";
            }
            else if((time.currentTimeMilliseconds % 1600) < 1600)
            {
                m_loadingTextField.text = "Loading...";
            }
            

            m_loadingTextField.x = m_loadingTextField.width / 2 - 100;
            addChild(m_loadingTextField);
            
            // Check whether enough time has elapsed to add another thought bubble
            var fadeInDuration:Number = 1.0;
            var fadeOutDuration:Number = 1.0;
            var msBetweenThoughtBubbles:Number = 2000;
            if (m_msSinceLastThoughtBubble > msBetweenThoughtBubbles)
            {
                m_msSinceLastThoughtBubble = 0;

                var initialAlpha:Number = 0.6;
                var initialScaleFactor:Number = 0.5;
                
                var randomPosition:Point = m_positionPicker.getLocation();
                var selectedX:Number = randomPosition.x;
                var selectedY:Number = randomPosition.y;
                var newThoughtBubble:DisplayObject = getThoughtBubble();
                newThoughtBubble.alpha = initialAlpha;
                newThoughtBubble.scaleX = newThoughtBubble.scaleY = initialScaleFactor;
                newThoughtBubble.x = selectedX;
                newThoughtBubble.y = selectedY;
                
                var fadeInTween:Tween = new Tween(newThoughtBubble, fadeInDuration);
                fadeInTween.fadeTo(1.0);
                fadeInTween.scaleTo(0.7);
                Starling.juggler.add(fadeInTween);
                addChild(newThoughtBubble);
                
                // Fade out should trigger at slightly random duration
                var fadeOutTween:Tween = new Tween(newThoughtBubble, fadeOutDuration);
                fadeOutTween.fadeTo(0.0);
                fadeOutTween.delay = fadeInDuration + Math.random() + 2.0;
                fadeOutTween.onComplete = function():void
                {
                    removeChild(newThoughtBubble);
                    
                    // Assuming the head of the list always finishes first so it is the one to remove
                    m_activeAnimations.shift();
                };
                Starling.juggler.add(fadeOutTween);
                
                var animationObject:Object = {
                    start: fadeInTween,
                    end: fadeOutTween
                };
                m_activeAnimations.push(animationObject);
            }
            else
            {
                m_msSinceLastThoughtBubble += time.frameDeltaMs();
            }
        }
        
        /**
         * The loading screen should show some indication of progress if the application is
         * fetching an external resource.
         * 
         * @param ratio
         *      A number between 0.0 and 1.0 to indicate how much more resources need
         *      to be loaded
         */
        public function setLoadingRatio(ratio:Number):void
        {
            var percentage:String = String(int(ratio*100)) + "%";
            addChild(m_ratioTextField);
            
            if (ratio <= 1.01)
            {
                m_ratioTextField.text = percentage;
                m_ratioTextField.x = m_ratioTextField.width/2 - 60;
            }
        }
        
        private function getThoughtBubble():DisplayObject
        {
            var thoughtBubbleContainer:Sprite = new Sprite();
            var thoughtBubbleBg:Image = new Image(m_assetManager.getTexture("thought_bubble"));
            
            // Pick random tint
            thoughtBubbleBg.color = m_thoughtBubbleColors[Math.floor(Math.random() * m_thoughtBubbleColors.length)];
            
            thoughtBubbleContainer.addChild(thoughtBubbleBg);
            
            var action:String = WordProblemLoadingState.THOUGHT_VERBS[Math.floor(Math.random() * WordProblemLoadingState.THOUGHT_VERBS.length)];
            var noun:String = WordProblemLoadingState.THOUGHT_NOUNS[Math.floor(Math.random() * WordProblemLoadingState.THOUGHT_NOUNS.length)];
            var textField:TextField = new TextField(thoughtBubbleBg.width * 0.8, thoughtBubbleBg.height, action + " " + noun, "Verdana", 24, 0x000000);
            textField.x = (thoughtBubbleBg.width - textField.width) * 0.5
            thoughtBubbleContainer.addChild(textField);
            
            thoughtBubbleContainer.pivotX = thoughtBubbleBg.width * 0.5;
            thoughtBubbleContainer.pivotY = thoughtBubbleBg.height * 0.5;
            
            return thoughtBubbleContainer;
        }
    }
}