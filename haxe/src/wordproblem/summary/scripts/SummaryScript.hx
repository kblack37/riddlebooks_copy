package wordproblem.summary.scripts;

import openfl.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextFormat;
import openfl.display.Bitmap;

import cgs.audio.Audio;
import cgs.internationalization.StringTable;
import cgs.levelProgression.nodes.ICgsLevelNode;

import dragonbox.common.expressiontree.compile.LatexCompiler;
import dragonbox.common.math.vectorspace.RealsVectorSpace;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

import starling.animation.Juggler;
import starling.animation.Tween;
import starling.core.Starling;
import wordproblem.display.LabelButton;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;
import starling.filters.BlurFilter;
import starling.text.TextField;
import starling.textures.Texture;
import starling.utils.HAlign;
import starling.utils.VAlign;

import wordproblem.callouts.CalloutCreator;
import wordproblem.characters.HelperCharacterController;
//import wordproblem.currency.CurrencyAwardedAnimation;
import wordproblem.currency.CurrencyChangeAnimation;
import wordproblem.currency.CurrencyCounter;
import wordproblem.currency.PlayerCurrencyModel;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.animation.FireworksAnimation;
import wordproblem.engine.component.ComponentFactory;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.level.LevelStatistics;
import wordproblem.engine.level.WordProblemLevelData;
import wordproblem.engine.objectives.BaseObjective;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.systems.FreeTransformSystem;
import wordproblem.engine.systems.HelperCharacterRenderSystem;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.text.MeasuringTextField;
import wordproblem.engine.text.TextParser;
import wordproblem.engine.text.TextViewFactory;
import wordproblem.engine.widget.ConfirmationWidget;
import wordproblem.event.CommandEvent;
import wordproblem.items.ItemDataSource;
import wordproblem.items.ItemInventory;
import wordproblem.level.LevelNodeCompletionValues;
import wordproblem.level.controller.WordProblemCgsLevelManager;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.player.ButtonColorData;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseBufferEventScript;
import wordproblem.state.WordProblemGameState;
//import wordproblem.summary.NewNotificationScreen;
import wordproblem.summary.SummaryGradeWidget;
import wordproblem.summary.SummaryObjectivesWidget;
import wordproblem.summary.SummaryRewardsScreen;
//import wordproblem.summary.SummaryWidget;
import wordproblem.xp.PlayerXPBar;
import wordproblem.xp.PlayerXpBarAnimation;
import wordproblem.xp.PlayerXpModel;

/**
 * This script is responsible for showing the summary screen.
 *
 * Note that the summary is just a visualization of the progress/rewards that were calculated
 * when the player successfully completed a level.
 */
class SummaryScript extends BaseBufferEventScript
{
	private var m_gameState : WordProblemGameState;
	private var m_gameEngine : IGameEngine;
	private var m_assetManager : AssetManager;
	private var m_playerItemInventory : ItemInventory;
	private var m_playerXpModel : PlayerXpModel;
	private var m_playerCurrencyModel : PlayerCurrencyModel;

	/**
	 * The summary needs to show how many brain points the player earned after finishing the level.
	 */
	private var m_playerXpBar : PlayerXPBar;

	/**
	 * The animation of the player's xp bar filling up and changing levels.
	 */
	private var m_playerXpBarFillAnimation : PlayerXpBarAnimation;

	/**
	 * Show the coins that the player earned during the playthrough of the level.
	 */
	private var m_currencyCounter : CurrencyCounter;

	/**
	 * This is the canvas in which several of the end of level progress indicators
	 * should be pasted on top of.
	 */
	//private var m_summaryWidget : SummaryWidget;

	/**
	 * After the level summary is shown, sometimes we show another notification to tell the player
	 * some important message, like they finished all the levels in a chapter or a new world is unlocked.
	 */
	//private var m_newNotificationScreen : NewNotificationScreen;

	/**
	 * Extra layer to show extra details about the rewards earned by the player
	 */
	private var m_rewardsScreen : SummaryRewardsScreen;

	/**
	 * Animated background to bring attention to the reward button if it pops up
	 */
	private var m_rewardButtonBurstBackground : Image;
	private var m_rewardButtonBurstTween : Tween;

	/**
	 * Button to open up new rewards earned
	 */
	private var m_rewardsButton : LabelButton;

	/**
	 * Juggler controlling animation for the summary screen.
	 */
	private var m_summaryJuggler : Juggler;

	/**
	 * Juggler controlling animation for the new notice screen
	 */
	private var m_newNotificationJuggler : Juggler;

	/**
	 * Need a special time updater for our custom juggler
	 */
	private var m_time : Time;

	private var m_globalMousePoint : Point;

	private var m_fireworksAnimation : FireworksAnimation;

	/**
	 * This is needed to check whether the just completed level was completed for this first time.
	 * That data is stored in the node
	 */
	private var m_levelManager : WordProblemCgsLevelManager;

	/**
	 * Used to blur out the summary when the reward overlay is on top
	 */
	private var m_summaryBlurFilter : BlurFilter = new BlurFilter(5, 5);

	/**
	 * Used to control the characters flying around the screen
	 */
	private var m_helperCharacterController : HelperCharacterController;
	private var m_helperRenderer : HelperCharacterRenderSystem;
	private var m_freeTransformSystem : FreeTransformSystem;

	public var totalScreenWidth : Float = 800;
	public var totalScreenHeight : Float = 600;

	/**
	 * Apply custom color changes to buttons in the summary
	 */
	private var m_buttonColorData : ButtonColorData;

	/*
	Temp elements reconstructed each time the summary shows up
	*/

	/**
	 * The display area for objectives
	 */
	private var m_objectivesContainer : SummaryObjectivesWidget;

	/**
	 * The container for that shows the grade the player earned in a level
	 */
	private var m_gradeContainer : SummaryGradeWidget;

	public function new(gameState : WordProblemGameState,
						gameEngine : IGameEngine,
						levelManager : WordProblemCgsLevelManager,
						assetManager : AssetManager,
						playerItemInventory : ItemInventory,
						itemDataSource : ItemDataSource,
						playerXpModel : PlayerXpModel,
						playerCurrencyModel : PlayerCurrencyModel,
						allowExit : Bool,
						buttonColorData : ButtonColorData,
						id : String = null,
						isActive : Bool = true)
	{
		super(id, isActive);

		m_gameState = gameState;
		m_gameEngine = gameEngine;
		m_levelManager = levelManager;
		m_gameEngine.addEventListener(GameEvent.LEVEL_COMPLETE, bufferEvent);
		m_gameEngine.addEventListener(GameEvent.LEVEL_READY, bufferEvent);
		m_assetManager = assetManager;
		m_playerItemInventory = playerItemInventory;
		m_playerXpModel = playerXpModel;
		m_playerCurrencyModel = playerCurrencyModel;
		m_buttonColorData = buttonColorData;

		m_summaryJuggler = new Juggler();
		//m_summaryWidget = new SummaryWidget(
			//m_assetManager,
			//onNextClicked,
			//onExitClicked,
			//m_summaryJuggler,
			//allowExit,
			//totalScreenWidth,
			//totalScreenHeight,
			//buttonColorData
		//);

		m_newNotificationJuggler = new Juggler();

		m_rewardsScreen = new SummaryRewardsScreen(totalScreenWidth, totalScreenHeight,
				gameState.getSprite(),
				playerItemInventory, itemDataSource, assetManager, function() : Void
		{
			if (m_rewardsScreen.parent != null) m_rewardsScreen.parent.removeChild(m_rewardsScreen);
			//m_summaryWidget.filter = null;
		});

		m_rewardsButton = new LabelButton(m_assetManager.getBitmapData("present_bottom_yellow"));
		var presentIcon : Sprite = new Sprite();
		var presentBottom : Bitmap = new Bitmap(m_assetManager.getBitmapData("present_bottom_yellow"));
		var presentTop : Bitmap = new Bitmap(m_assetManager.getBitmapData("present_top_yellow"));
		presentIcon.addChild(presentBottom);
		presentIcon.addChild(presentTop);
		presentBottom.y += presentTop.height * 0.3;
		presentBottom.x += presentTop.width * 0.02;
		presentIcon.scaleX = presentIcon.scaleY = 0.5;

		m_rewardsButton.scaleWhenOver = 1.1;
		m_rewardsButton.scaleWhenDown = 0.95;
		m_rewardsButton.addEventListener(MouseEvent.CLICK, onRewardsOpen);

		m_rewardsButton.x = 100;
		m_rewardsButton.y = 420;

		var rewardButtonBurstTexture : Texture = m_assetManager.getTexture("burst_purple");
		m_rewardButtonBurstBackground = new Image(rewardButtonBurstTexture);
		m_rewardButtonBurstBackground.pivotX = rewardButtonBurstTexture.width * 0.5;
		m_rewardButtonBurstBackground.pivotY = rewardButtonBurstTexture.height * 0.5;
		m_rewardButtonBurstBackground.x = m_rewardsButton.x + presentIcon.width * 0.5;
		m_rewardButtonBurstBackground.y = m_rewardsButton.y + presentIcon.height * 0.5;
		m_rewardButtonBurstTween = new Tween(m_rewardButtonBurstBackground, 8);
		m_rewardButtonBurstTween.repeatCount = 0;
		m_rewardButtonBurstTween.animate("rotation", Math.PI * 2);

		m_time = new Time();
		m_globalMousePoint = new Point();

		m_playerXpBar = new PlayerXPBar(assetManager, 270);
		m_playerXpBarFillAnimation = new PlayerXpBarAnimation(m_playerXpBar, playerXpModel);

		m_currencyCounter = new CurrencyCounter(assetManager, 110, 40, 40);
		m_currencyCounter.x = 620;
		m_currencyCounter.y = 50;

		// Create separate coy of the helper character controls
		var characterComponentManager : ComponentManager = new ComponentManager();
		var componentFactory : ComponentFactory = new ComponentFactory(new LatexCompiler(new RealsVectorSpace()));
		var characterData : Dynamic = assetManager.getObject("characters");
		componentFactory.createAndAddComponentsForItemList(characterComponentManager, characterData.charactersLevelSelect);
		m_helperCharacterController = new HelperCharacterController(
			characterComponentManager,
			new CalloutCreator(new TextParser(), new TextViewFactory(assetManager, null))
		);
		m_freeTransformSystem = new FreeTransformSystem();
		m_helperRenderer = new HelperCharacterRenderSystem(assetManager, Starling.current.juggler, null);
	}

	// On visit we advance the time
	// Only useful in the situations where summary is showing and we need to advance the time of a custom
	// juggler.
	override public function visit() : Int
	{
		m_time.update();

		var timeStep : Float = m_time.currentDeltaSeconds;
		m_summaryJuggler.advanceTime(timeStep);
		m_newNotificationJuggler.advanceTime(timeStep);

		if (m_isActive)
		{
			iterateThroughBufferedEvents();

			var mouseState : MouseState = m_gameEngine.getMouseState();
			m_globalMousePoint.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);

			if (m_rewardsScreen.parent != null)
			{
				m_rewardsScreen.update(mouseState);
			}

			if (m_newNotificationScreen != null)
			{
				var characterComponentManager : ComponentManager = m_helperCharacterController.getComponentManager();
				m_freeTransformSystem.update(characterComponentManager);
				m_helperRenderer.update(characterComponentManager);
			}
		}

		return ScriptStatus.SUCCESS;
	}

	override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
	{
		// TODO: Remove these dependencies:
		// The item inventory belonging to the player has a buffer of new or modified items since the
		// last completed level.
		// This script looks at those changes to display them in the summary.
		if (eventType == GameEvent.LEVEL_COMPLETE)
		{
			// Check if new items were given to the player
			// Revealed items exist in the inventory but have a hidden tag.
			// We still want the summary to show them like they are a normal brand new item
			var outNewRewardItemIds : Array<String> = new Array<String>();
			for (item in m_playerItemInventory.outNewRewardItemIds) {
				outNewRewardItemIds.push(item);
			}
			
			// Check if any changes happened to an item that has stages
			var outChangedRewardEntityIds : Array<String> = new Array<String>();
			var outPreviousStages : Array<Int> = new Array<Int>();
			var outCurrentStages : Array<Int> = new Array<Int>();
			var i : Int = 0;
			for (i in 0...m_playerItemInventory.outChangedRewardEntityIds.length) {
				outChangedRewardEntityIds.push(m_playerItemInventory.outChangedRewardEntityIds[i]);
				outPreviousStages.push(m_playerItemInventory.outPreviousStages[i]);
				outCurrentStages.push(m_playerItemInventory.outCurrentStages[i]);
			}
			
			var currentLevel : WordProblemLevelData = m_gameEngine.getCurrentLevel();
			var levelNode : ICgsLevelNode = m_levelManager.getNodeByName(currentLevel.getName());
			
			// TODO: This assumes that the level node already exists
			var earnedNewStar : Bool = (levelNode.completionValue == LevelNodeCompletionValues.PLAYED_SUCCESS && currentLevel.statistics.previousCompletionStatus != LevelNodeCompletionValues.PLAYED_SUCCESS);
			m_rewardsScreen.setRewardsDataModels(
				earnedNewStar,
				outNewRewardItemIds,
				outChangedRewardEntityIds,
				outPreviousStages,
				outCurrentStages
			);
			this.applyChangesAtEndOfLevel(outNewRewardItemIds.length > 0 || outChangedRewardEntityIds.length > 0);
		}
		else if (eventType == GameEvent.LEVEL_READY)
		{
			// Clear the summary if displayed
			if (m_summaryWidget.parent != null)
			{
				onSummaryWidgetButtonPressed();
			}  // Clear the new notification if displayed

			if (m_newNotificationScreen != null)
			{
				m_newNotificationScreen.removeFromParent(true);
				m_newNotificationScreen = null;
			}
		}
	}

	private function applyChangesAtEndOfLevel(doShowRewards : Bool = false) : Void
	{
		// Show a basic summary of the goals the player achieved in the last playthrough
		var animationDelay : Float = 0.5;
		m_gameState.getSprite().addChild(m_summaryWidget);

		var currentLevel : WordProblemLevelData = m_gameEngine.getCurrentLevel();
		var objectivesToUseInSummary : Array<BaseObjective> = new Array<BaseObjective>();
		var i : Int;
		var numObjectives : Int = currentLevel.objectives.length;
		var objective : BaseObjective;
		for (i in 0...numObjectives)
		{
			objective = currentLevel.objectives[i];
			if (objective.useInSummary)
			{
				objectivesToUseInSummary.push(objective);
			}
		}
		
		// TODO: Having a separate summary widget might be uneccesary
		// Convert the grade score earned within all objectives to a letter score that can be shown in the summary
		m_gradeContainer = new SummaryGradeWidget(m_assetManager, m_summaryJuggler);
		m_objectivesContainer = new SummaryObjectivesWidget(m_assetManager, m_summaryJuggler);
		var objectivesNumberGrade : Int = currentLevel.statistics.gradeFromSummaryObjectives;
		function onSlideComplete() : Void
		{
			function onCharacterAnimationComplete() : Void
			{
				// Have the xp bar fade into view
				m_playerXpBar.x = m_gradeContainer.x + (m_gradeContainer.width - m_playerXpBar.width) * 0.5;
				m_playerXpBar.y = m_gradeContainer.y + m_gradeContainer.height;
				m_playerXpBar.startCycleAnimation();
				
				// We assume the xp model has already written out the xp earned from the last level.
				// To get the previous point, we take the difference this is required to visualize to
				// the player the change in xp from their accomplishments in the last level
				var xpEarnedInLevel : Int = m_gameEngine.getCurrentLevel().statistics.xpEarnedForLevel;
				var totalXpBeforeLevel : Int = m_playerXpModel.totalXP - xpEarnedInLevel;
				
				// Show xp bar, make sure it is at the correct start value BEFORE adding
				// the points added at this level
				var outXpData : Array<Int> = new Array<Int>();
				m_playerXpModel.getLevelAndRemainingXpFromTotalXp(totalXpBeforeLevel, outXpData);
				var xpForCurrentLevel : Int = m_playerXpModel.getTotalXpForLevel(outXpData[0]);
				var xpForNextLevel : Int = m_playerXpModel.getTotalXpForLevel(outXpData[0] + 1);
				m_playerXpBar.setFillRatio(outXpData[1] / (xpForNextLevel - xpForCurrentLevel));
				m_playerXpBar.getPlayerLevelTextField().setText(outXpData[0] + "");
				
				m_summaryWidget.addChild(m_playerXpBar);
				var xpBarAppearTween : Tween = new Tween(m_playerXpBar, 1);
				m_playerXpBar.alpha = 0.0;
				xpBarAppearTween.fadeTo(1.0);
				xpBarAppearTween.onComplete = function() : Void
				{
					m_playerXpBarFillAnimation.start(totalXpBeforeLevel, m_playerXpModel.totalXP, onXpLevelUp, function() : Void
					{
						// Only add rewards button if there is a new reward
						if (doShowRewards)
						{
							m_summaryWidget.addChild(m_rewardButtonBurstBackground);
							m_summaryWidget.addChild(m_rewardsButton);
							m_summaryJuggler.add(m_rewardButtonBurstTween);
						}
						
						// Animate adding currency (the previous currency amount is taken to be the current minus the amount
						// added since the start of this just completed level, which assumes coins are only added at the start)
						m_summaryWidget.addChild(m_currencyCounter);
						var currencyAnimation : CurrencyChangeAnimation = new CurrencyChangeAnimation(m_currencyCounter);
						var currencyAtStart : Int = m_playerCurrencyModel.totalCoins - m_playerCurrencyModel.getTotalCoinsEarnedSinceLastLevel();
						currencyAnimation.start(currencyAtStart, m_playerCurrencyModel.totalCoins);
						m_summaryJuggler.add(currencyAnimation);
					});
				};
				m_summaryJuggler.add(xpBarAppearTween);
			};
			
			function onObjectivesAnimationComplete() : Void
			{
				// Show the score earned for this level
				m_gradeContainer.scaleX = m_gradeContainer.scaleY = 0.9;
				m_gradeContainer.animateCharacter(objectivesNumberGrade, onCharacterAnimationComplete);
				m_gradeContainer.x = 430;
				m_gradeContainer.y = 60;
				m_summaryWidget.addChild(m_gradeContainer);
			};
			
			m_objectivesContainer.animateObjectives(objectivesToUseInSummary,
			onSingleObjectiveAnimationComplete, onObjectivesAnimationComplete);
			m_objectivesContainer.x = 50;
			m_objectivesContainer.y = 50;
			m_summaryWidget.addChild(m_objectivesContainer);
		};
		m_summaryWidget.show(onSlideComplete);
		
		Audio.instance.playSfx("win_level");
		
		// Disable the game screen
		m_gameEngine.setPaused(true);
		
		// Have a small smattering of fireword like explosions
		var fireWorksAnimation : FireworksAnimation = new FireworksAnimation(totalScreenWidth, totalScreenHeight, m_assetManager);
		fireWorksAnimation.play(m_summaryWidget);
		m_fireworksAnimation = fireWorksAnimation;
	}

	private function onXpLevelUp(newLevel : Int) : Void
	{
		var levelUpNotice : ConfirmationWidget = null;
		levelUpNotice = new ConfirmationWidget(800, 600,
		function() : DisplayObject
		{
			var levelUpContainer : Sprite = new Sprite();
			var coinsForLevelup : Int = m_playerCurrencyModel.getCoinsEarnedForLevelUp(Std.string(newLevel));

			var measuringText : MeasuringTextField = new MeasuringTextField();
			var textFormat : TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 20, 0xFFFFFF);
			var levelUpTextContent : String = "Good Effort! You reached level " + newLevel + "!";
			measuringText.text = levelUpTextContent;
			var levelUpText : TextField = new TextField(400, Std.int(measuringText.textHeight + 5), levelUpTextContent, textFormat.font, textFormat.size, try cast(textFormat.color, Int) catch (e:Dynamic) 0);
			levelUpText.vAlign = VAlign.TOP;
			levelUpContainer.addChild(levelUpText);

			var coinsEarnedTextContent : String = "+ " + coinsForLevelup;
			measuringText.text = coinsEarnedTextContent;
			var coinsEarnedText : TextField = new TextField(100, 40, coinsEarnedTextContent, textFormat.font, 32, try cast(textFormat.color, Int) catch (e:Dynamic) 0);
			coinsEarnedText.hAlign = HAlign.LEFT;

			coinsEarnedText.y = levelUpText.y + levelUpText.height + 50;
			var coinIcon : Image = new Image(m_assetManager.getTexture("coin"));
			coinIcon.scaleX = coinIcon.scaleY = 0.4;

			coinsEarnedText.x = (400 - (coinsEarnedText.width + coinIcon.width)) * 0.5;
			coinIcon.x = coinsEarnedText.x + coinsEarnedText.width;
			coinIcon.y = coinsEarnedText.y + (coinsEarnedText.height - coinIcon.height) * 0.5;
			levelUpContainer.addChild(coinsEarnedText);
			levelUpContainer.addChild(coinIcon);
			return levelUpContainer;
		},
		function() : Void
		{
			levelUpNotice.removeFromParent(true);
			m_playerXpBarFillAnimation.resumeAfterLevelUpPause();
		},
		null,
		m_assetManager, m_buttonColorData.getUpButtonColor(),
		// TODO: uncomment when cgs library is finished
		"",//StringTable.lookup("ok"),
		null, true);
		m_gameState.getSprite().addChild(levelUpNotice);
	}

	private function onSingleObjectiveAnimationComplete(objective : BaseObjective, objectiveDisplay : DisplayObject) : Void
	{
		// The successful completion of an objective should award some set of coins
		// Need a script that knows when to award coins, on the back end all the changes
		// should already taken place and this is just a visualization
		var objectiveIndex : Int = m_gameEngine.getCurrentLevel().objectives.indexOf(objective);
		if (objectiveIndex > -1 && m_playerCurrencyModel.coinsEarnedForObjectives.length > objectiveIndex)
		{
			var coinsEarned : Int = m_playerCurrencyModel.coinsEarnedForObjectives[objectiveIndex];

			// Only makes sense to show this when positive amount of coins earned
			if (coinsEarned > 0)
			{
				var objectiveBounds : Rectangle = objectiveDisplay.getBounds(m_summaryWidget);
				//var currencyAnimation : CurrencyAwardedAnimation = new CurrencyAwardedAnimation(coinsEarned, m_assetManager, m_summaryJuggler);
				//currencyAnimation.x = objectiveBounds.right;
				//currencyAnimation.y = objectiveBounds.top + objectiveBounds.height * 0.5;
				//m_summaryWidget.addChild(currencyAnimation);

				m_summaryJuggler.delayCall(function() : Void
				{
					var fadeAwayTween : Tween = new Tween(currencyAnimation, 0.5);
					fadeAwayTween.onComplete = function() : Void
					{
						currencyAnimation.removeFromParent(true);
					};
					fadeAwayTween.animate("alpha", 0.0);
					m_summaryJuggler.add(fadeAwayTween);
				}, 3);
			}
		}
	}

	/**
	 * The summary widget has a next and exit button. Once the player presses on one of them
	 * the summary should be closed and properly disposed on.
	 */
	private function onSummaryWidgetButtonPressed() : Void
	{
		m_gradeContainer.removeFromParent(true);
		m_objectivesContainer.removeFromParent(true);

		m_summaryWidget.removeFromParent(false);
		m_summaryWidget.reset();
		m_summaryWidget.filter = null;

		m_fireworksAnimation.dispose();
		m_summaryJuggler.remove(m_fireworksAnimation);

		// Delete everything in the rewards screen
		if (m_rewardButtonBurstBackground.parent != null) m_rewardButtonBurstBackground.parent.removeChild(m_rewardButtonBurstBackground);
		if (m_rewardsButton.parent != null) m_rewardsButton.parent.removeChild(m_rewardsButton);
		m_summaryJuggler.remove(m_rewardButtonBurstTween);
		m_rewardsScreen.close();

		// Clear coin counter
		if (m_currencyCounter.parent != null) m_currencyCounter.parent.removeChild(m_currencyCounter);

		// Clear the xp bar
		m_playerXpBarFillAnimation.stop();
		m_playerXpBar.endCycleAnimation();
		if (m_playerXpBar.parent != null) m_playerXpBar.parent.removeChild(m_playerXpBar);
	}

	private function onNextClicked() : Void
	{
		var loggingDetails : Dynamic = {
			buttonName : "NextButton"

		};
		m_gameEngine.dispatchEvent(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, false, loggingDetails);

		var levelStats : LevelStatistics = m_gameEngine.getCurrentLevel().statistics;
		if (levelStats.masteryIdAchieved > -1)
		{
			showMasteryNotificationScreen(levelStats.masteryIdAchieved, CommandEvent.GO_TO_NEXT_LEVEL);
		}
		else
		{
			// If do not need to show the notification screen, then
			// hitting next immediately goes to the next level.
			m_gameState.dispatchEvent(CommandEvent.GO_TO_NEXT_LEVEL);
		}

		onSummaryWidgetButtonPressed();
	}

	private function onExitClicked() : Void
	{
		var loggingDetails : Dynamic = {
			buttonName : "ExitButton"

		};
		m_gameEngine.dispatchEvent(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, false, loggingDetails);

		// Display special mastery message if last level triggered that event
		var levelStats : LevelStatistics = m_gameEngine.getCurrentLevel().statistics;
		if (levelStats.masteryIdAchieved > -1)
		{
			showMasteryNotificationScreen(levelStats.masteryIdAchieved, CommandEvent.LEVEL_QUIT_AFTER_COMPLETION);
		}
		else
		{
			m_gameState.dispatchEvent(CommandEvent.LEVEL_QUIT_AFTER_COMPLETION, false, {
				level : m_gameEngine.getCurrentLevel()

			});
		}
		onSummaryWidgetButtonPressed();
	}

	private function showMasteryNotificationScreen(masteryId : Int, commandNameOnContinue : String) : Void
	{
		// HACK: The conditions where this gets fired relies on version specific information
		// Each mastery links to a particular text content
		var noticeBackground : String = null;
		var leftPageText : String = "You've mastered a problem type.";
		var rightPageText : String = "New levels have been unlocked.";
		if (masteryId == 1)
		{
			noticeBackground = "level_select_bg_other";
		}
		else if (masteryId == 2)
		{
			noticeBackground = "level_select_bg_mystery";
		}
		else if (masteryId == 3)
		{
			noticeBackground = "level_select_bg_fantasy";
		}
		else if (masteryId == 4)
		{
			noticeBackground = "level_select_bg_fantasy";
		}
		else if (masteryId == 5)
		{
			noticeBackground = "level_select_bg_other";
		}
		// TODO: This behavior is version specific
		// One way to track is to get all edges that have the set action mastery.
		// Look at the starting nodes and check that they are completed
		// Dependency on the level progression
		// Completing ALL mastery levels show a special message
		// The only way to currently detect this is to check whether all the special mastery
		// nodes have been set as completed
		else if (masteryId == 6)
		{
			noticeBackground = "level_select_bg_scifi";
		}
		// Mastery 7
		else
		{
			noticeBackground = "level_select_bg_scifi";
		}

		if (masteryId == 7)
		{
			leftPageText = "Good job, you've mastered ALL the problem types.";
			rightPageText = "Replay some of the types to see new problems!";
		}  // Need to first check if a mastery screen should appear instead

		m_newNotificationScreen = new NewNotificationScreen(
			noticeBackground,
			leftPageText,
			rightPageText,
			m_assetManager,
			m_helperCharacterController,
			m_newNotificationJuggler,
			function() : Void
			{
				m_gameState.dispatchEvent(commandNameOnContinue);
				if (m_newNotificationScreen != null)
				{
					m_newNotificationScreen.removeFromParent(true);
					m_newNotificationScreen = null;
				}
			}
		);
		m_helperRenderer.setParentDisplay(m_newNotificationScreen);
		m_gameState.getSprite().addChild(m_newNotificationScreen);
	}

	private function onRewardsOpen() : Void
	{
		m_rewardsScreen.open();
		m_summaryWidget.filter = m_summaryBlurFilter;
	}
}
