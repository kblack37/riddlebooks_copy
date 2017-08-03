package wordproblem.summary;

import flash.geom.Point;
import flash.text.TextFormat;

import dragonbox.common.util.PMPRNG;
import dragonbox.common.util.XColor;

import haxe.Constraints.Function;

import starling.animation.Juggler;
import starling.animation.Transitions;
import starling.animation.Tween;
import starling.display.Button;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;
import starling.text.TextField;
import starling.textures.Texture;

import wordproblem.characters.HelperCharacterController;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.widget.WidgetUtil;
import wordproblem.resource.AssetManager;

/**
 * This screen is used to display messages like the player has achieved a new level of mastery
 * or they have finished with all the regular levels.
 */
class NewNotificationScreen extends Sprite
{
    /**
     * Button to dismiss the screen
     */
    private var m_continueButton : Button;
    
    /**
     * Callback that should be triggered when the continue button is pressed
     */
    private var m_onContinueClickedCallback : Function;
    
    /**
     * Main title running at the top of the screen
     */
    private var m_titleText : TextField;
    
    /**
     * Description text appearing on the left page
     */
    private var m_leftPageTextfield : TextField;
    
    /**
     * Description text appearing on the right page
     */
    private var m_rightPageTextfield : TextField;
    
    private var m_helperCharacterController : HelperCharacterController;
    
    private var m_starImages : Array<Image>;
    private var m_juggler : Juggler;
    
    public function new(backgroundName : String,
            leftPageText : String,
            rightPageText : String,
            assetManager : AssetManager,
            helperCharacterController : HelperCharacterController,
            juggler : Juggler,
            onContinueClickedCallback : Function)
    {
        super();
        
        m_helperCharacterController = helperCharacterController;
        m_juggler = juggler;
        m_onContinueClickedCallback = onContinueClickedCallback;
        
        var backgroundImageName : String = backgroundName;
        
        // As the background for this screen, use one of the embedded level select pictures
        var backgroundImage : Image = new Image(assetManager.getTexture(backgroundImageName));
        addChild(backgroundImage);
        
        var totalScreenWidth : Float = 800;
        var totalScreenHeight : Float = 600;
        m_continueButton = WidgetUtil.createGenericColoredButton(
            assetManager,
            XColor.ROYAL_BLUE,
            "Next",
            new TextFormat(GameFonts.DEFAULT_FONT_NAME, 32, 0xFFFFFF),
            null
        );
        m_continueButton.width = 200;
        m_continueButton.height = 70;
        m_continueButton.x = (totalScreenWidth - m_continueButton.width) * 0.5;
        m_continueButton.y = totalScreenHeight - m_continueButton.height * 1.5;
        m_continueButton.addEventListener(Event.TRIGGERED, onContinueClick);
        m_continueButton.enabled = false;
        addChild(m_continueButton);
        
        // Randomly plop down several stars that play a continuous color shift animation
        m_starImages = new Array<Image>();
        
        var starPositions : Array<Point> = new Array<Point>();
        starPositions.push(new Point(600, 50));
        starPositions.push(new Point(40, 60));
        starPositions.push(new Point(50, 300));
        starPositions.push(new Point(400, 400));
        starPositions.push(new Point(730, 370));
        starPositions.push(new Point(700, 530));
        starPositions.push(new Point(40, 550));
        starPositions.push(new Point(190, 530));
        starPositions.push(new Point(540, 550));
        
        
        var i : Int = 0;
        var numStars : Int = starPositions.length;
        var starTexture : Texture = assetManager.getTexture("star_small_white.png");
        var randomGenerator : PMPRNG = PMPRNG.createGen(null);
        for (i in 0...numStars){
            var position : Point = starPositions[i];
            var starImage : Image = new Image(starTexture);
            starImage.pivotX = starTexture.width * 0.5;
            starImage.pivotY = starTexture.height * 0.5;
            starImage.x = position.x;
            starImage.y = position.y;
            addChild(starImage);
            m_starImages.push(starImage);
            
            // The way color shift works is we pick a start and an end color
            // Over time we adjust the ratio from 1.0 to 0.0 which shifts how much
            // of the
            var ratioObject : Dynamic = {
                image : starImage,
                ratio : 1.0,
                startColor : XColor.getDistributedHsvColor(Math.random()),
                endColor : XColor.getDistributedHsvColor(Math.random()),

            };
            var colorShiftTween : Tween = new Tween(ratioObject, 1);
            colorShiftTween.repeatCount = 0;
            colorShiftTween.animate("ratio", 0);
            colorShiftTween.onUpdate = onUpdateColorShift;
            colorShiftTween.onUpdateArgs = [ratioObject];
            colorShiftTween.onRepeat = onRepeatColorShift;
            colorShiftTween.onRepeatArgs = [ratioObject];
            juggler.add(colorShiftTween);
            
            var transformTween : Tween = new Tween(starImage, randomGenerator.nextDoubleRange(1, 2));
            transformTween.repeatCount = 0;
            transformTween.reverse = true;
            starImage.scaleX = starImage.scaleY = randomGenerator.nextDoubleRange(0.7, 0.9);
            transformTween.scaleTo(randomGenerator.nextDoubleRange(1, 1.3));
            juggler.add(transformTween);
            
            // The stars should fade in
            var fadeInTween : Tween = new Tween(starImage, 0.7);
            starImage.alpha = 0.0;
            fadeInTween.fadeTo(1.0);
            juggler.add(fadeInTween);
        }  // Thought bubbles for character should pop in one by one  
        
        
        
        var yOffset : Float = 240;
        var leftDialogContainer : Sprite = new Sprite();
        var cookieThought : Image = createThoughtBubble(0xC79BC7, assetManager, 300, 200);
        leftDialogContainer.addChild(cookieThought);
        m_leftPageTextfield = new TextField(290, 200, leftPageText, GameFonts.DEFAULT_FONT_NAME, 22, 0);
        m_leftPageTextfield.pivotX = m_leftPageTextfield.width * 0.5;
        m_leftPageTextfield.pivotY = m_leftPageTextfield.height * 0.5;
        leftDialogContainer.addChild(m_leftPageTextfield);
        leftDialogContainer.x = totalScreenWidth * 0.25;
        leftDialogContainer.y = yOffset;
        addChild(leftDialogContainer);
        
        var rightDialogContainer : Sprite = new Sprite();
        var tacoThought : Image = createThoughtBubble(0x8ECAA9, assetManager, 300, 200);
        rightDialogContainer.addChild(tacoThought);
        m_rightPageTextfield = new TextField(290, 200, rightPageText, GameFonts.DEFAULT_FONT_NAME, 22, 0);
        m_rightPageTextfield.pivotX = m_rightPageTextfield.width * 0.5;
        m_rightPageTextfield.pivotY = m_rightPageTextfield.height * 0.5;
        rightDialogContainer.addChild(m_rightPageTextfield);
        rightDialogContainer.x = totalScreenWidth * 0.75;
        rightDialogContainer.y = yOffset;
        addChild(rightDialogContainer);
        
        // Title should fade and pop in
        m_titleText = new TextField(Std.int(totalScreenWidth), 80, "Nice Work!", GameFonts.DEFAULT_FONT_NAME, 48, 0xFFFFFF);
        m_titleText.pivotY = m_titleText.height * 0.5;
        m_titleText.y = 80;
        addChild(m_titleText);
        
        // Need to force the characters to be shown on the top layer again
        m_helperCharacterController.setCharacterVisible({
                    id : "Cookie",
                    visible : true,
                });
        m_helperCharacterController.setCharacterVisible({
                    id : "Taco",
                    visible : true,
                });
        m_helperCharacterController.moveCharacterTo({
                    id : "Cookie",
                    x : leftDialogContainer.x,
                    y : leftDialogContainer.y + leftDialogContainer.height,
                    velocity : -1,
                });
        m_helperCharacterController.moveCharacterTo({
                    id : "Taco",
                    x : rightDialogContainer.x,
                    y : rightDialogContainer.y + rightDialogContainer.height,
                    velocity : -1,
                });
        
        m_titleText.scaleY = 0;
        var expandTitleTween : Tween = new Tween(m_titleText, 1, Transitions.LINEAR);
        expandTitleTween.delay = 0.5;
        expandTitleTween.animate("scaleY", 1);
        juggler.add(expandTitleTween);
        
        var showLeftDialogTween : Tween = new Tween(leftDialogContainer, 1, Transitions.EASE_OUT_ELASTIC);
        leftDialogContainer.scaleX = leftDialogContainer.scaleY = 0.0;
        showLeftDialogTween.delay = 1.0;
        showLeftDialogTween.scaleTo(1.0);
        juggler.add(showLeftDialogTween);
        
        rightDialogContainer.scaleX = rightDialogContainer.scaleY = 0.0;
        var showRightDialogTween : Tween = new Tween(rightDialogContainer, 1, Transitions.EASE_OUT_ELASTIC);
        showRightDialogTween.delay = showLeftDialogTween.delay + showLeftDialogTween.totalTime + 1;
        showRightDialogTween.scaleTo(1.0);
        juggler.add(showRightDialogTween);
        
        var continueButtonFadeTween : Tween = new Tween(m_continueButton, 1);
        m_continueButton.alpha = 0;
        continueButtonFadeTween.fadeTo(1.0);
        continueButtonFadeTween.delay = showRightDialogTween.delay + showRightDialogTween.totalTime;
        continueButtonFadeTween.onComplete = function() : Void
                {
                    m_continueButton.enabled = true;
                };
        juggler.add(continueButtonFadeTween);
    }
    
    private function createThoughtBubble(color : Int, assetManager : AssetManager, width : Float, height : Float) : Image
    {
        var thoughtBubbleTexture : Texture = assetManager.getTexture("thought_bubble.png");
        var thoughtBubble : Image = new Image(thoughtBubbleTexture);
        thoughtBubble.pivotX = thoughtBubbleTexture.width * 0.5;
        thoughtBubble.pivotY = thoughtBubbleTexture.height * 0.5;
        thoughtBubble.scaleX = width / thoughtBubbleTexture.width;
        thoughtBubble.scaleY = height / thoughtBubbleTexture.height;
        thoughtBubble.color = color;
        return thoughtBubble;
    }
    
    override public function dispose() : Void
    {
        m_continueButton.removeEventListener(Event.TRIGGERED, onContinueClick);
        
        // Make sure all tweens are killed
        m_juggler.purge();
        
        // Remove all star images and their associated tweens
        var i : Int = 0;
        var numStars : Int = m_starImages.length;
        for (i in 0...numStars){
            m_starImages[i].removeFromParent(true);
        }
		m_starImages = new Array<Image>();
        
        // Turn off visibility of characters
        m_helperCharacterController.setCharacterVisible({
                    id : "Cookie",
                    visible : false,
                });
        m_helperCharacterController.setCharacterVisible({
                    id : "Taco",
                    visible : false,
                });
        
        super.dispose();
    }
    
    private function onContinueClick() : Void
    {
        if (m_onContinueClickedCallback != null) 
        {
            m_onContinueClickedCallback();
        }
    }
    
    private function onUpdateColorShift(param : Dynamic) : Void
    {
        var image : Image = param.image;
        image.color = XColor.interpolateColors(
                        param.startColor,
                        param.endColor,
                        param.ratio
                        );
    }
    
    private function onRepeatColorShift(param : Dynamic) : Void
    {
        // On repeat swap colors, the previous end color becomes the start
        // and a new end color is selected
        param.startColor = param.endColor;
        param.endColor = XColor.getDistributedHsvColor(Math.random());
    }
}
