package wordproblem.hints.ai;

import wordproblem.characters.HelperCharacterController;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.analysis.BarModelClassifier;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.text.TextParser;
import wordproblem.engine.text.TextViewFactory;
import wordproblem.engine.widget.BarModelAreaWidget;
import wordproblem.engine.widget.TextAreaWidget;
import wordproblem.hints.HintCommonUtil;
import wordproblem.hints.HintScript;
import wordproblem.hints.HintSelectorNode;
import wordproblem.level.conditions.ICondition;
import wordproblem.level.conditions.KOutOfNProficientCondition;
import wordproblem.level.controller.WordProblemCgsLevelManager;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.barmodel.ValidateBarModelArea;

/**
 * ...
 * @author ...
 */

class AiPolicyHintSelector extends HintSelectorNode
{

	public inline static var POLICY_MAP_KEY:String = "storedPolicyMap";
	public inline static var HINT_DICT_KEY:String = "storedHintDict";
	public inline static var LOAD_ERROR_KEY:String = "storedAiLoadError_";
	private inline static var LAST_LEVEL_PREFIX:String = "lastLevel_";
	private inline static var TIMES_HINTED_PREFIX:String = "timesHinted_";
	private inline static var LAST_CLASS_PREFIX:String = "lastClass_";
	private inline static var LAST_CLASS_TIMES_PREFIX:String = "lastClassTimes_";
	private inline static var LAST_AI_HINT_PREFIX:String = "lastAiHint_";

	private var m_classifier : BarModelClassifier;
	private var m_gameEngine : IGameEngine;
	private var m_textViewFactory : TextViewFactory;
	private var m_characterController : HelperCharacterController;
	private var m_assetManager : AssetManager;
	private var m_textParser : TextParser;
	private var m_policyFiles : Array<Dynamic>;
	private var m_hintDicts : Array<Dynamic>;
	private var m_qid : Int;
	private var m_levelManager : WordProblemCgsLevelManager;
	private var m_validateBarModelArea : ValidateBarModelArea;

	//needs to be saved off & restored
	// private var m_timesHinted : Int;
	//private var m_lastClass:String;
	private var m_playerStatsAndSaveData:PlayerStatsAndSaveData;

	public inline static var NUM_PROGRESSION_INDICIES : Int = 2;

	public inline static var MAX_TIMES_AI_HINT_0 : Int = 10;
	public inline static var MAX_TIMES_AI_HINT_1 : Int = 20;

	public function getStartingTimeStep(progressionIndex : Int) : Int
	{
		if (progressionIndex == 1)
		{
			var oldTimesHinted : Int;
			try
			{
				var oldProgressionIndex : Int = 0;
				oldTimesHinted = Std.int(m_playerStatsAndSaveData.getPlayerDecision(TIMES_HINTED_PREFIX +oldProgressionIndex ));
			}
			catch (e : Dynamic)     //meaning no hints in first progression
			{
				oldTimesHinted = 0;
			}
			return oldTimesHinted + 1;//1 for bridge state timestep
		}
		else {
			return 0;
		}
	}

	public function AiPolicyHintSelector(gameEngine:IGameEngine, validateBarModelArea:ValidateBarModelArea,
										 modelType:String, qid : Int, characterController:HelperCharacterController, textviewFactory:TextViewFactory, assetManager:AssetManager, textParser:TextParser, levelManager:WordProblemCgsLevelManager, playerStats:PlayerStatsAndSaveData)
	{
		m_gameEngine = gameEngine;
		m_characterController = characterController;
		m_textViewFactory = textviewFactory;
		m_assetManager = assetManager;
		m_textParser = textParser;

		m_policyFiles = new Array<Dynamic>();
		m_hintDicts = new Array<Dynamic>();
		tryLoadMaps();

		m_qid = qid;
		m_playerStatsAndSaveData = playerStats;
		m_levelManager = levelManager;
		m_validateBarModelArea = validateBarModelArea;

		var progressionIndex : Int = getProgressionIndexFromQid(m_qid);
		if ((m_qid == 531 || m_qid == 701) && getLastLevel( progressionIndex) != m_qid)
		{
			trace("Restarting!");
			playerStats.setPlayerDecision(TIMES_HINTED_PREFIX + progressionIndex, getStartingTimeStep(progressionIndex));

		}
		if (getLastLevel( progressionIndex) != m_qid)
		{
			trace("New level!");
			playerStats.setPlayerDecision(LAST_CLASS_PREFIX + m_qid, null); //also invalidates last class times, last ai hint
		}
		playerStats.setPlayerDecision(LAST_LEVEL_PREFIX + progressionIndex, m_qid);
		trace("setting last level as" + m_qid + " using key " + (LAST_LEVEL_PREFIX + progressionIndex));

		try
		{
			m_classifier = new BarModelClassifier(m_gameEngine, validateBarModelArea, modelType, qid);
		}
		catch (e : Dynamic)
		{
			trace("Difficulty creating classifier!");
			m_classifier = null;
		}

	}

	private function tryLoadMaps() : Void
	{
		if (m_policyFiles[0] != null && m_policyFiles[1] != null  && m_hintDicts[0] != null && m_hintDicts[1] != null)
		{
			return;//everything loaded!
		}
		for (i in 0...NUM_PROGRESSION_INDICIES)
		{
			m_policyFiles[i] = m_assetManager.getObject(POLICY_MAP_KEY + "_" + i);
			m_hintDicts[i] = m_assetManager.getObject(HINT_DICT_KEY  + "_" + i);
		}
	}

	private function getProgressionIndexFromQid(qid : Int) : Int
	{
		switch (qid)
		{
			case 531:
				return 0;
			case 532:
				return 0;
			case 533:
				return 0;
			case 534:
				return 0;
			case 535:
				return 0;
			case 536:
				return 0;
			/*case 538:
				return 0;
			case 540:
				return 0;
			case 541:
				return 0;
			case 542:
				return 0;*/
			case 701:
				return 1;
			case 961:
				return 1;
			case 702:
				return 1;
			case 972:
				return 1;
			case 705:
				return 1;
			case 982:
				return 1;
			case 709:
				return 1;
			case 984:
				return 1;
			/**/
			default:
				trace("Unrecognized! qid=" + qid);
				return -1;
		}
	}
	private function getLevelIdFromQid(qid : Int) : Int
	{
		switch (qid)
		{
			case 531:
				return 0;
			case 532:
				return 1;
			case 533:
				return 2;
			case 534:
				return 3;
			case 535:
				return 4;
			case 536:
				return 5;
			/*case 538:
				return 0;
			case 540:
				return 0;
			case 541:
				return 0;
			case 542:
				return 0;*/
			case 701:
				return 0;
			case 961:
				return 1;
			case 702:
				return 2;
			case 972:
				return 3;
			case 705:
				return 4;
			case 982:
				return 5;
			case 709:
				return 6;
			case 984:
				return 7;
			default:
				trace("Unrecognized! qid=" + qid);
				return -1;
		}
	}

	private function getProficientCondition(progressionIndex : Int) : Array<KOutOfNProficientCondition>
	{
		var ret:Array<KOutOfNProficientCondition> = new Array<KOutOfNProficientCondition>();
		//trace("retvec0: " + ret);
		var edgeToCondition : Dynamic = m_levelManager.getEdgeIdToConditionsList();
		for (edgeID in Reflect.fields(edgeToCondition)) //TODO: To be safe check edgeID textually
		{
			trace("Found key " + edgeID);
			var vec:Array<ICondition> = Reflect.field(edgeToCondition, edgeID);
			for (cond in vec)
			{
				trace("Found condition of type " + cond.getType());
				if (cond.getType() == KOutOfNProficientCondition.TYPE)
				{
					ret.push(try cast(cond, KOutOfNProficientCondition) catch (e : Dynamic) null);
				}
			}
		}

		if ((ret.length != 1 && progressionIndex == 0) || (ret.length != 2  && progressionIndex == 1))
		{
			throw ("Wrong number of K of N conditions! there are " + ret.length + "  on prog index " + progressionIndex);
		}
		//trace("retvec: " + ret);
		return ret;

	}

	private function getProficientStringKOfN(proficientConditions:Array<KOutOfNProficientCondition>):String
	{
		var vecString:String = "";
		var proficientCondition:KOutOfNProficientCondition;
		for(proficientCondition in proficientConditions)
		{
			var vec:Array<Bool> = proficientCondition.getLevelProficientHistory();
			var b : Bool;

			for(b in vec)
			{
				if (b)
				{
					vecString += "t_";
				}
				else
				{
					vecString += "f_";
				}
			}
			if (vec.length == 0)
			{
				if (getLevelIdFromQid(m_qid) > 0)
				{
					trace("huh? should have some history!");
				}
				vecString = "?_";
			}
		}
		return vecString;
	}

	private function getProficientStringMasteredBoth(proficientConditions:Array<KOutOfNProficientCondition>):String
	{
		var vecString:String = "";
		var proficientCondition:KOutOfNProficientCondition;
		for(proficientCondition in proficientConditions)
		{
			if (proficientCondition.getSatisfied())
			{
				vecString += "t_";
			}
			else
			{
				vecString += "f_";
			}
		}
		return vecString;
	}

	private function getStateStringFromHintLoc(clas:String, hintsAtCurrentLoc : Int, progressionIndex : Int):String
	{
		//2_26_1_t_t_3

		var proficientConditions:Array<KOutOfNProficientCondition> = getProficientCondition(progressionIndex);
		var vecString:String;
		if (progressionIndex == 0)
		{
			vecString =  getProficientStringKOfN(proficientConditions);
		}
		else
		{
			vecString =  getProficientStringMasteredBoth(proficientConditions);
		}

		trace(vecString);

		var timesHinted : Int = getTimesHinted(progressionIndex);

		var lookup:String = "(" + getLevelIdFromQid(m_qid) + "_" + BarModelClassifier.getGroupNumber(clas) + "_" + hintsAtCurrentLoc + "_" + vecString + "0),"+timesHinted;
		//return "2_26_1_t_t_3";
		return lookup;
	}

	private function getLastLevel(progressionIndex : Int) : Int
	{
		var lastLevel : Int;
		try {
			lastLevel = Std.int(m_playerStatsAndSaveData.getPlayerDecision(LAST_LEVEL_PREFIX +progressionIndex ));
		}
		catch (e : Dynamic)
		{
			lastLevel = 0;
		}
		trace("retrieved last level as " + lastLevel + " using key " + (LAST_LEVEL_PREFIX +progressionIndex));
		return lastLevel;
	}

	private function getTimesHinted(progressionIndex : Int) : Int
	{
		var timesHinted : Int;
		try {
			timesHinted = Std.int(m_playerStatsAndSaveData.getPlayerDecision(TIMES_HINTED_PREFIX +progressionIndex ));

		}
		catch (e : Dynamic)
		{
			timesHinted = getStartingTimeStep(progressionIndex);
		}
		return timesHinted;
	}

	private function sampleHintIndexFromTable(lookup:String) : Int
	{
		var policyMap:Dynamic =  m_policyFiles[getProgressionIndexFromQid(m_qid)];
		if (policyMap != null && !policyMap.hasOwnProperty(lookup))
		{
			trace ("Not actually  missing!");
			return 0;
		}
		var probsStr:String = Reflect.field(policyMap, "lookup");
		var probsArr:Array<String> = probsStr.split(",");
		trace("Sampling from probs: " + probsArr);
		var choice:Float = Math.random();
		var sum:Float = 0.0;
		var i : Int = 0;
		for (prob in probsArr)
		{
			sum += Std.parseFloat(prob);
			if (sum > choice)
			{
				return i;
			}
			i++;
		}
		throw ("Should not occur " + sum + " " + choice + " pStr:" + probsStr);

	}

	private function lookupHintFromIndex(index : Int, clas:String):String
	{
		var hintDictKey:String = getLevelIdFromQid(m_qid) + "," + BarModelClassifier.getGroupNumber(clas);
		var hintListStr:String = Reflect.field(m_hintDicts[getProgressionIndexFromQid(m_qid)], hintDictKey);
		var tokens:Array<String> = hintListStr.split(",");
		trace("tokens0 " + tokens[0]);
		return tokens[index];

	}

	override public function getHint():HintScript
	{
		var defaultText:String = "Just keep going!";
		try {
			return getHintInternal(defaultText);
		}
		catch (e : Dynamic)
		{
			var loadError:String ;
			try
			{
				var progressionIndex : Int = getProgressionIndexFromQid(m_qid);
				loadError = try cast(m_assetManager.getObject(LOAD_ERROR_KEY + progressionIndex), String) catch (e : Dynamic) null;
			}
			catch (e : Dynamic)
			{
				loadError = "None (seemingly)";
			}
			trace("Error in AI Hint! " + e.name + " " + e.message + " LoadError? " + loadError);
			var hintData : Dynamic = {descriptionContent: (defaultText), erroredHint:(true), errorName:(e.name), errorMessage:(e.message), errorStackTrace:(loadError)};
			
			return HintCommonUtil.createHintFromMismatchData(hintData,
				m_characterController,
				m_assetManager,
				m_gameEngine.getMouseState(),
				m_textParser,
				m_textViewFactory,
				try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch (e : Dynamic) null,
				m_gameEngine, 200, 300);
		}
	}

	public function getHintUsingOld(oldHint:HintScript):HintScript
	{
		var defaultText:String = "Just keep going!";
		try {
			defaultText = Reflect.field(oldHint.getSerializedData(), "descriptionContent");
			return getHintInternal(defaultText);
		}
		catch (e : Dynamic)
		{
			var loadError:String ;
			try
			{
				var progressionIndex : Int = getProgressionIndexFromQid(m_qid);
				loadError = try cast(m_assetManager.getObject(LOAD_ERROR_KEY + progressionIndex), String) catch ( e : Dynamic) null;
			}
			catch (e : Dynamic)
			{
				loadError = "None (seemingly)";
			}
			trace("Error in AI Hint! " + e.name + " " + e.message + " LoadError? " + loadError);
			var hintData : Dynamic = {descriptionContent: (defaultText), erroredHint:(true), errorName:(e.name), errorMessage:(e.message), errorStackTrace:(loadError)};
			
			return HintCommonUtil.createHintFromMismatchData(hintData,
				m_characterController,
				m_assetManager,
				m_gameEngine.getMouseState(),
				m_textParser,
				m_textViewFactory,
				try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch (e : Dynamic) null,
				m_gameEngine, 200, 300);
		}
	}

	public function getHintInternal(oldHint:String):HintScript
	{
		tryLoadMaps();
		var timesHinted : Int;
		try {
			timesHinted = Std.int(m_playerStatsAndSaveData.getPlayerDecision(TIMES_HINTED_PREFIX + getProgressionIndexFromQid(m_qid)));
		}
		catch (e : Dynamic)
		{
			timesHinted = getStartingTimeStep(getProgressionIndexFromQid(m_qid));
		}
		if (getProgressionIndexFromQid(m_qid) ==0 && timesHinted >= MAX_TIMES_AI_HINT_0)
			return null;
		if (getProgressionIndexFromQid(m_qid) ==1 && timesHinted >= MAX_TIMES_AI_HINT_1)
			return null;
		trace("retrieved timesHinted as " + timesHinted);
		var hintsAtCurrentLoc : Int = 1;
		var lastClass:String = try cast(m_playerStatsAndSaveData.getPlayerDecision(LAST_CLASS_PREFIX + m_qid), String) catch (e : Dynamic) null;
		//trace("lookup using qid " + m_qid);
		var lastClassTimes : Int = 0;
		if (lastClass != null)
		{
			lastClassTimes = try cast(m_playerStatsAndSaveData.getPlayerDecision(LAST_CLASS_TIMES_PREFIX + m_qid), Int) catch (e : Dynamic) null;
		}

		var hintsUsed : Int = 1;

		var model:BarModelData = (try cast(m_gameEngine.getUiEntity("barModelArea"), BarModelAreaWidget) catch (e : Dynamic) null).getBarModelData().clone();
		var clas:String = m_classifier.getClassification(model);
		if (clas == null)
		{
			trace("invoked at unknown!");
			return null;
		}
		//trace("Asked for hint in class " + clas);

		//trace("Last class is " + lastClass + " last class times is " + lastClassTimes + " current class is " + clas);
		if (clas == lastClass)
		{
			if (lastClassTimes > 1)
			{
				//Already gave both levels of hints, no need to re-query
				hintsUsed = 0;
			}
			lastClassTimes++;

		}
		else
		{
			lastClassTimes = 0;
		}

		if (lastClassTimes > 2 && clas == lastClass)
		{
			var lastHint : Dynamic = m_playerStatsAndSaveData.getPlayerDecision(LAST_AI_HINT_PREFIX + m_qid);
			var lastHintData : Dynamic = {
				descriptionContent: Reflect.field(lastHint, 'descriptionContent'), highlightBarsThenTextFromDocIds: Reflect.field(lastHint, 'highlightBarsThenTextFromDocIds'),
				highlightValidateButton: Reflect.field(lastHint, 'highlightValidateButton'), highlightBarModelArea: Reflect.field(lastHint, 'highlightBarModelArea'),
				highlightBarsThenTextColor: Reflect.field(lastHint, 'highlightBarsThenTextColor'),
				question: Reflect.field(lastHint, 'question'),
				highlightBarModelAreaColor: Reflect.field(lastHint, 'highlightBarModelAreaColor'), highlightValidateButtonColor: Reflect.field(lastHint, 'highlightValidateButtonColor'),
				isOldHint:1
			};
			return HintCommonUtil.createHintFromMismatchData(lastHintData,
				m_characterController,
				m_assetManager,
				m_gameEngine.getMouseState(),
				m_textParser,
				m_textViewFactory,
				try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch (e : Dynamic) null,
				m_gameEngine, 200, 300);
		}

		//trace("LastClasTimes " + lastClassTimes);
		var progressionIndex : Int = getProgressionIndexFromQid(m_qid);

		var lookup:String = getStateStringFromHintLoc(clas, lastClassTimes, progressionIndex);

		var index : Int = 0;
		try{
			index = sampleHintIndexFromTable(lookup);
		}
		catch (e : Dynamic)
		{
			throw ("Unable to lookup string " + lookup + " at qid " + m_qid);
		}
		var hint:String;

		//trace("choosing from " + lookupHintFromIndex(0, clas) + " OR " + lookupHintFromIndex(1, clas) + " OR " + lookupHintFromIndex(2, clas) );

		if (index == 0)
		{
			hint = oldHint;
		}
		else {
			hint = lookupHintFromIndex(index, clas);
			hint = (new EReg("_", "g")).replace(hint, " ");
			hint = (new EReg("|", "g")).replace(hint, ",");
			hint = (new EReg("@", "g")).replace(hint, ":");
		}

		//hint += "<ans=unk>";//TODO:Remove!
		var hintDC:String = hint;

		var idToExpression : Dynamic = {};
		var textWidget:TextAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch (e : Dynamic) null;
		var expressionComponents:Array<Component> = textWidget.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
		for (expressionComponent in expressionComponents)
		{
			var castedExpressionComponent : ExpressionComponent = try cast(expressionComponent, ExpressionComponent) catch (e : Dynamic) null;
			Reflect.setField(idToExpression, castedExpressionComponent.entityId, castedExpressionComponent.expressionString);
			/// If desire abbrevName: m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(expressionComponent.expressionString).abbreviatedName
		}

		var highlightParts:Array<String> = new Array();
		var highlightCheck : Bool = false;
		var highlightBackground : Bool = false;

		if (hintDC.indexOf("<a>") >= 0)
		{
			hintDC = StringTools.replace(hintDC, '<a>', '');
			highlightParts.push("a1");
		}
		if (hintDC.indexOf("<b>") >= 0)
		{
			hintDC = StringTools.replace(hintDC, '<b>', '');
			highlightParts.push("b1");
		}
		if (hintDC.indexOf("<unk>") >= 0)
		{
			hintDC = StringTools.replace(hintDC, '<unk>', '');
			highlightParts.push("unk");
		}
		if (hintDC.indexOf("<check>") >= 0)
		{
			hintDC = StringTools.replace(hintDC, '<check>', '');
			highlightCheck = true;
		}
		if (hintDC.indexOf("<back>") >= 0)
		{
			hintDC = StringTools.replace(hintDC, '<back>', '');
			highlightBackground = true;
		}

		var questionType : Int = 0;
		var answer:String = "";

		if (hintDC.indexOf("<ans=a>") >= 0)
		{
			hintDC = StringTools.replace(hintDC, '<ans=a>', '');
			questionType = 1;
			answer = "a1";
		}
		if (hintDC.indexOf("<ans=b>") >= 0)
		{
			hintDC = StringTools.replace(hintDC, '<ans=b>', '');
			questionType = 1;
			answer = "b1";
		}
		if (hintDC.indexOf("<ans=unk>") >= 0)
		{
			hintDC = StringTools.replace(hintDC, '<ans=unk>', '');
			questionType = 1;
			answer = "unk";
		}
		if (hintDC.indexOf("<ans=yes>") >= 0)
		{
			hintDC = StringTools.replace(hintDC, '<ans=yes>', '');
			questionType = 2;
			answer = "yes";
		}
		if (hintDC.indexOf("<ans=no>") >= 0)
		{
			hintDC = StringTools.replace(hintDC, '<ans=no>', '');
			questionType = 2;
			answer = "no";
		}
		var question : Dynamic = null;
		if (questionType == 1)
		{
			trace("setting question type 1!");
			question= { "text": hintDC, "answers":[
				{"name":Reflect.field(idToExpression, 'a1'), "correct": (answer == 'a1')},
				{"name":Reflect.field(idToExpression, 'b1'), "correct": (answer == 'b1')},
				{"name":Reflect.field(idToExpression, 'unk'), "correct": (answer == 'unk')}
				]
			};
		}
		else if (questionType == 2)
		{
			trace("setting question type 2!");
			question= { "text": hintDC, "answers":[
				{"name":"yes", "correct": (answer ==  "yes")},
				{"name":"no", "correct":(answer == "no")}
				]
			};
		}

		trace("highlight background? " + highlightBackground);

		//This line enables Zoran's demo
		//hint = "Misconception: " + BarModelClassifier.getHumanReadable(clas) + ". (" + clas + ")";

		var modelSer : Dynamic = model.serialize();
		var valid : Bool = m_validateBarModelArea.getCurrentModelMatchesReference();

		var loggingString : String = (new EReg(",", "g")).replace(lookup, "_");
		loggingString = (new EReg(")", "g")).replace(loggingString, "");
		loggingString = (new EReg("(", "g")).replace(loggingString, "");
		trace("logging lookup as " + loggingString);
		var hintData : Dynamic = {descriptionContent: (hintDC), highlightBarsThenTextFromDocIds: (highlightParts),
							   highlightValidateButton: (highlightCheck), highlightBarModelArea: (highlightBackground), highlightBarsThenTextColor: (0xA5FF00),
							   highlightBarModelAreaColor: (0xA5FF00), highlightValidateButtonColor: (0xA5FF00),
							   barModelClassification: (clas), rlStateString: (loggingString), question: (question),
							   rlActionIndex: (index), barModel: (modelSer), isValid:(valid), version:(4)
							  };

		var hintToRun:HintScript = HintCommonUtil.createHintFromMismatchData(hintData,
			m_characterController,
			m_assetManager,
			m_gameEngine.getMouseState(),
			m_textParser,
			m_textViewFactory,
			try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch (e : Dynamic) null,
			m_gameEngine, 200, 300);
		m_playerStatsAndSaveData.setPlayerDecision(LAST_CLASS_PREFIX + m_qid, clas);
		//trace("save using qid " + m_qid);

		timesHinted += hintsUsed;
		trace("timesHinted being set to " + timesHinted);

		m_playerStatsAndSaveData.setPlayerDecision(TIMES_HINTED_PREFIX + getProgressionIndexFromQid(m_qid), timesHinted);

		m_playerStatsAndSaveData.setPlayerDecision(LAST_CLASS_TIMES_PREFIX + m_qid, lastClassTimes);

		m_playerStatsAndSaveData.setPlayerDecision(LAST_AI_HINT_PREFIX + m_qid, hintData);
		//m_lastClass = clas;
		return hintToRun;

	}

}