package wordproblem.summary;


import haxe.Constraints.Function;

import starling.animation.Juggler;
import starling.animation.Transitions;
import starling.animation.Tween;
import starling.display.Image;
import starling.display.Sprite;
import starling.text.TextField;
import starling.textures.Texture;

import wordproblem.engine.text.GameFonts;
import wordproblem.resource.AssetManager;

/**
 * This component shows the character and the grade
 */
class SummaryGradeWidget extends Sprite
{
    /**
     * Map a letter grade key to the an object with various rendering information
     * 
     * Object keys:
     * emotion:emotion snapshot the hamster character should be in.
     * For example A+ or A should show the happy character, D or F should show sad
     */
    private var m_gradeToInformationMap : Map<String, Dynamic>;
    
    private var m_assetManager : AssetManager;
    private var m_juggler : Juggler;
    
    private var m_tweensInstantiated : Array<Tween>;
    
    public function new(assetManager : AssetManager, juggler : Juggler)
    {
        super();
        
        m_assetManager = assetManager;
        m_juggler = juggler;
        m_tweensInstantiated = new Array<Tween>();
        
        // Setup the feedback given to the player depending on the grade
        m_gradeToInformationMap = new Map();
        Reflect.setField(m_gradeToInformationMap, "A+", {
            emotion : "happy",
            textColor : 0x339933,
            feedback : ["AMAZING!!!", "PERFECT!", "WOOOT!"],

        });
        Reflect.setField(m_gradeToInformationMap, "A", {
            emotion : "happy",
            textColor : 0x009999,
            feedback : ["Great job!", "Fantastic!"],

        });
        
        var neutralFeedback : Array<Dynamic> = ["Well done!", "Good work!", "You got it!"];
        Reflect.setField(m_gradeToInformationMap, "B", {
            emotion : "neutral",
            textColor : 0x3333CC,
            feedback : neutralFeedback,

        });
        
        var badFeedback : Array<Dynamic> = ["There's always next time.", "Don't worry!", "Good try!"];
        Reflect.setField(m_gradeToInformationMap, "C", {
            emotion : "neutral",
            textColor : 0xCC3300,
            feedback : badFeedback,

        });
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        this.removeChildren(0, -1, true);
        
        // Remove the tweens that were instantiated at the last call
        for (tween in m_tweensInstantiated)
        {
            m_juggler.remove(tween);
        }
		m_tweensInstantiated = new Array<Tween>();
    }
    
    public function animateCharacter(score : Int, onAnimationComplete : Function) : Void
    {
        // This needs to signal that the xp should show up
        // Convert score to letter grade key
        var letterGrade : String = "C";
        if (score == 100) 
        {
            letterGrade = "A+";
        }
        else if (score >= 85) 
        {
            letterGrade = "A";
        }
        // Position the grade and character in default positions
        else if (score >= 50) 
        {
            letterGrade = "B";
        }
        
        
        
        var gradeDisplayContainer : Sprite = new Sprite();
        var gradeStarTexture : Texture = m_assetManager.getTexture("assets/ui/win/star_large.png");
        var gradeStarImage : Image = new Image(gradeStarTexture);
        gradeStarImage.color = 0xFFFF66;
        var gradeStarTargetScale : Float = 300.0 / gradeStarTexture.width;
        gradeStarImage.scaleX = gradeStarImage.scaleY = gradeStarTargetScale;
        gradeDisplayContainer.addChild(gradeStarImage);
        var textColor : Int = Reflect.field(m_gradeToInformationMap, letterGrade).textColor;
        var scoreTextfield : TextField = new TextField(160, 160, score + "", GameFonts.DEFAULT_FONT_NAME, 84, textColor);
        scoreTextfield.x = (gradeStarImage.width - scoreTextfield.width) * 0.5;
        scoreTextfield.y = (gradeStarImage.height - scoreTextfield.height) * 0.5 + 15;
        gradeDisplayContainer.addChild(scoreTextfield);
        this.addChild(gradeDisplayContainer);
        
        gradeDisplayContainer.alpha = 0.0;
        var gradeFadeInTween : Tween = new Tween(gradeDisplayContainer, 1);
        gradeFadeInTween.fadeTo(1.0);
        gradeFadeInTween.onComplete = function() : Void
                {
                    onAnimationComplete();
                };
        startTween(gradeFadeInTween);
        
        // Show the appropriate character emotion depending on performance
        var characterNameToUse : String = ((Math.random() > 0.5)) ? "cookie" : "taco";
        var characterEmotionToUse : String = ((m_gradeToInformationMap.exists(letterGrade))) ? 
        Reflect.field(m_gradeToInformationMap, letterGrade).emotion : "neutral";
        var characterTextureName : String = characterNameToUse + "_" + characterEmotionToUse + "_still";
        var characterTexture : Texture = m_assetManager.getTexture(characterTextureName);
        var characterImage : Image = new Image(characterTexture);
        characterImage.pivotX = characterTexture.width * 0.5;
        characterImage.pivotY = characterTexture.height * 0.5;
        
        characterImage.x = gradeStarImage.width * 0.5;
        characterImage.y = this.height + 20;
        
        // Show the feed back from the character
        /*
        var feedbackList:Array = m_gradeToInformationMap[letterGrade].feedback;
        var randomFeedback:String = feedbackList[Math.floor(Math.random() * feedbackList.length)];
        var feedbackTextfield:DisplayObject = XTextField.createWordWrapTextfield(new TextFormat(GameFonts.DEFAULT_FONT_NAME, 36, 0xFFCCFF),
        randomFeedback, 300, 200);
        feedbackTextfield.rotation = Math.PI  * -0.05;
        feedbackTextfield.x = characterImage.x + characterImage.width * 0.5;
        feedbackTextfield.y = characterImage.y + 20;
        this.addChild(feedbackTextfield);
        */
        
        characterImage.scaleX = characterImage.scaleY = 0.3;
        var finalCharacterScale : Float = 0.8;
        var characterPopinTween : Tween = new Tween(characterImage, 0.3, Transitions.EASE_IN_OUT_ELASTIC);
        characterPopinTween.animate("scaleX", finalCharacterScale);
        characterPopinTween.animate("scaleY", finalCharacterScale);
        characterPopinTween.onComplete = function() : Void
                {
                    var swayDuration : Float = 2.0;
                    var characterSwayRightTween : Tween = new Tween(characterImage, swayDuration);
                    characterSwayRightTween.animate("rotation", Math.PI * -0.1);
                    characterSwayRightTween.onComplete = function() : Void
                            {
                                var characterSwayRepeatTween : Tween = new Tween(characterImage, swayDuration * 2.0);
                                characterSwayRepeatTween.animate("rotation", Math.PI * 0.1);
                                characterSwayRepeatTween.repeatCount = 0;
                                characterSwayRepeatTween.reverse = true;
                                startTween(characterSwayRepeatTween);
                            };
                    startTween(characterSwayRightTween);
                };
        startTween(characterPopinTween);
        
        // Character does a gentle sway back and forth
        this.addChild(characterImage);
    }
    
    private function startTween(tween : Tween) : Void
    {
        m_tweensInstantiated.push(tween);
        m_juggler.add(tween);
    }
}
