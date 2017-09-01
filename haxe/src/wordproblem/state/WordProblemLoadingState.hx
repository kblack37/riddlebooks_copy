package wordproblem.state;

import motion.Actuate;
import openfl.display.Bitmap;
import openfl.geom.Point;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import wordproblem.display.PivotSprite;

import dragonbox.common.particlesystem.zone.DiskZone;
import dragonbox.common.state.BaseState;
import dragonbox.common.state.IStateMachine;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;
import dragonbox.common.util.XColor;

import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.text.TextField;

import wordproblem.engine.text.GameFonts;
import wordproblem.resource.AssetManager;

/**
 * There is potentially some amount of time where the game needs to load resources
 * for a level. At this time we do not want any part of the screen to be visible.
 */
class WordProblemLoadingState extends BaseState
{
	private var m_ratioTextField : TextField;
	private var m_loadingTextField : TextField;
	private var m_assetManager : AssetManager;
	private var m_width : Float;
	private var m_height : Float;

	private var m_msSinceLastThoughtBubble : Int;
	private var m_thoughBubblePositions : Array<Point>;
	private var m_positionPicker : DiskZone;

	private static var THOUGHT_VERBS : Array<String>;
	private static var THOUGHT_NOUNS : Array<String>;

	private var m_activeAnimations : Array<DisplayObject>;
	private var m_thoughtBubbleColors : Array<Int>;

	public function new(stateMachine : IStateMachine,
						width : Float,
						height : Float,
						assetManager : AssetManager)
	{
		super(stateMachine);
		if (THOUGHT_VERBS == null)
		{
			THOUGHT_VERBS = new Array<String>();
			THOUGHT_VERBS.push("Adding");
			THOUGHT_VERBS.push("Putting in");
			THOUGHT_VERBS.push("Removing");
			THOUGHT_VERBS.push("Placing");
			THOUGHT_VERBS.push("Gathering");
			THOUGHT_VERBS.push("Creating");
			THOUGHT_VERBS.push("Thinking of");
			THOUGHT_VERBS.push("Positioning");
			THOUGHT_VERBS.push("Loading");
			THOUGHT_VERBS.push("Checking");
		}
		
		if (THOUGHT_NOUNS == null)
		{
			THOUGHT_NOUNS = new Array<String>();
			THOUGHT_NOUNS.push("words");
			THOUGHT_NOUNS.push("questions");
			THOUGHT_NOUNS.push("blocks");
			THOUGHT_NOUNS.push("numbers");
			THOUGHT_NOUNS.push("punctuation");
			THOUGHT_NOUNS.push("math");
			THOUGHT_NOUNS.push("equations");
			THOUGHT_NOUNS.push("names");
			THOUGHT_NOUNS.push("characters");
			THOUGHT_NOUNS.push("themes");
			THOUGHT_NOUNS.push("sentences");
			THOUGHT_NOUNS.push("phrases");
			THOUGHT_NOUNS.push("hints");
			THOUGHT_NOUNS.push("pictures");
			THOUGHT_NOUNS.push("parts");
			THOUGHT_NOUNS.push("unicorns");
			THOUGHT_NOUNS.push("gremlins");
			THOUGHT_NOUNS.push("rainbows");
			THOUGHT_NOUNS.push("spaceships");
			THOUGHT_NOUNS.push("colors");
		}
		
		m_width = width;
		m_height = height;
		m_assetManager = assetManager;
	}

	override public function enter(fromState : Dynamic, params : Array<Dynamic> = null) : Void
	{
		m_activeAnimations = new Array<DisplayObject>();
		m_thoughtBubbleColors = XColor.getCandidateColorsForSession();
		
		var backgroundBitmapData : BitmapData = m_assetManager.getBitmapData("login_background");
		var backgroundImage : Bitmap = new Bitmap(backgroundBitmapData);
		backgroundImage.width = m_width;
		backgroundImage.height = m_height;
		addChild(backgroundImage);
		
		m_ratioTextField = new TextField();
		m_ratioTextField.width = width;
		m_ratioTextField.height = height + 100;
		m_ratioTextField.text = "";
		m_ratioTextField.setTextFormat(new TextFormat("Verdana", 40, 0x000000, null, null, null, null, null, TextFormatAlign.START));
		
		m_loadingTextField = new TextField();
		m_loadingTextField.width = width;
		m_loadingTextField.height = height;
		m_loadingTextField.text = "Loading";
		m_loadingTextField.setTextFormat(new TextFormat("Verdana", 40, 0x000000, null, null, null, null, null, TextFormatAlign.START));
		
		m_msSinceLastThoughtBubble = Std.int(Math.pow(2, 30));
		
		m_thoughBubblePositions = new Array<Point>();
		m_positionPicker = new DiskZone(m_width * 0.5, m_height * 0.5, Math.min(m_width, m_height) * 0.45, Math.min(m_width, m_height) * 0.35, m_height / m_width);
	}

	override public function exit(toState : Dynamic) : Void
	{
		// Any existing tweens or though bubble images should be disposed of
		removeChildren(0, -1);
		
		for (animationObject in m_activeAnimations)
		{
			Actuate.stop(animationObject);
		}
	}

	override public function update(time : Time, mouseState : MouseState) : Void
	{
		if ((time.currentTimeMilliseconds % 1600) < 400)
		{
			m_loadingTextField.text = "Loading";
		}
		else if ((time.currentTimeMilliseconds % 1600) < 800)
		{
			m_loadingTextField.text = "Loading.";
		}
		else if ((time.currentTimeMilliseconds % 1600) < 1200)
		{
			m_loadingTextField.text = "Loading..";
		}
		else if ((time.currentTimeMilliseconds % 1600) < 1600)
		{
			m_loadingTextField.text = "Loading...";
		}
		
		m_loadingTextField.x = m_loadingTextField.width / 2 - 100;
		addChild(m_loadingTextField);
		
		// Check whether enough time has elapsed to add another thought bubble
		var fadeInDuration : Float = 1.0;
		var fadeOutDuration : Float = 1.0;
		var msBetweenThoughtBubbles : Float = 2000;
		if (m_msSinceLastThoughtBubble > msBetweenThoughtBubbles)
		{
			m_msSinceLastThoughtBubble = 0;
			
			var initialAlpha : Float = 0.6;
			var initialScaleFactor : Float = 0.5;
			
			var randomPosition : Point = m_positionPicker.getLocation();
			var selectedX : Float = randomPosition.x;
			var selectedY : Float = randomPosition.y;
			var newThoughtBubble : DisplayObject = getThoughtBubble();
			newThoughtBubble.alpha = initialAlpha;
			newThoughtBubble.scaleX = newThoughtBubble.scaleY = initialScaleFactor;
			newThoughtBubble.x = selectedX;
			newThoughtBubble.y = selectedY;
			
			Actuate.tween(newThoughtBubble, fadeInDuration, { alpha: 1, scaleX: 0.7, scaleY: 0.7 });
			addChild(newThoughtBubble);
			
			// Fade out should trigger at slightly random duration
			Actuate.tween(newThoughtBubble, fadeInDuration + Math.random() + 2.0, { alpha: 0 }).onComplete(function() : Void
				{
					removeChild(newThoughtBubble);
					
					// Assuming the head of the list always finishes first so it is the one to remove
					m_activeAnimations.shift();
				});
			
			m_activeAnimations.push(newThoughtBubble);
		}
		else
		{
			m_msSinceLastThoughtBubble += Std.int(time.frameDeltaMs());
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
	public function setLoadingRatio(ratio : Float) : Void
	{
		var percentage : String = Std.string(Std.int(ratio * 100)) + "%";
		addChild(m_ratioTextField);
		
		if (ratio <= 1.01)
		{
			m_ratioTextField.text = percentage;
			m_ratioTextField.x = m_ratioTextField.width / 2 - 60;
		}
	}

	private function getThoughtBubble() : DisplayObject
	{
		var thoughtBubbleContainer : PivotSprite = new PivotSprite();
		var thoughtBubbleBg : Bitmap = new Bitmap(m_assetManager.getBitmapData("thought_bubble"));
		
		// Pick random tint
		var color = m_thoughtBubbleColors[Math.floor(Math.random() * m_thoughtBubbleColors.length)];
		thoughtBubbleBg.transform.colorTransform = XColor.rgbToColorTransform(color);
		
		thoughtBubbleContainer.addChild(thoughtBubbleBg);
		
		var action : String = WordProblemLoadingState.THOUGHT_VERBS[Math.floor(Math.random() * WordProblemLoadingState.THOUGHT_VERBS.length)];
		var noun : String = WordProblemLoadingState.THOUGHT_NOUNS[Math.floor(Math.random() * WordProblemLoadingState.THOUGHT_NOUNS.length)];
		var textField : TextField = new TextField();
		textField.width = thoughtBubbleBg.width * 0.8;
		textField.height = thoughtBubbleBg.height;
		textField.text = action + " " + noun;
		textField.setTextFormat(new TextFormat("Verdana", 24, 0x000000));
		textField.x = (thoughtBubbleBg.width - textField.width) * 0.5;
		thoughtBubbleContainer.addChild(textField);
		
		thoughtBubbleContainer.pivotX = thoughtBubbleBg.width * 0.5;
		thoughtBubbleContainer.pivotY = thoughtBubbleBg.height * 0.5;
		
		return thoughtBubbleContainer;
	}
}
