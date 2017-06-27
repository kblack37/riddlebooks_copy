package wordproblem.hints.ai
{
    
    import dragonbox.common.system.Map;
    import flash.utils.Dictionary;
    import wordproblem.engine.barmodel.analysis.BarModelClassifier;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.BarModelTypes;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.level.WordProblemLevelData;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.hints.HintScript;
    import wordproblem.level.conditions.ICondition;
    import wordproblem.level.controller.WordProblemCgsLevelManager;
    import wordproblem.player.PlayerStatsAndSaveData;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.barmodel.ValidateBarModelArea;
    import wordproblem.engine.IGameEngine;
    import wordproblem.hints.selector.ShowHintOnBarModelMistake;
    import wordproblem.hints.HintSelectorNode;
    import flash.net.FileReference;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.events.Event;
    import wordproblem.hints.HintCommonUtil;
    import wordproblem.characters.HelperCharacterController;
    import wordproblem.engine.component.ExpressionComponent;
	import wordproblem.engine.component.Component;
    import wordproblem.engine.text.TextViewFactory;
    import wordproblem.engine.text.TextParser;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.level.conditions.KOutOfNProficientCondition;
    
    /**
     * ...
     * @author ...
     */
    
    public class AiPolicyHintSelector extends HintSelectorNode
    {
        
        public static const POLICY_MAP_KEY:String = "storedPolicyMap";
        public static const HINT_DICT_KEY:String = "storedHintDict";
		public static const LOAD_ERROR_KEY:String = "storedAiLoadError_";
		private static const LAST_LEVEL_PREFIX:String = "lastLevel_";
        private static const TIMES_HINTED_PREFIX:String = "timesHinted_";
        private static const LAST_CLASS_PREFIX:String = "lastClass_";
        private static const LAST_CLASS_TIMES_PREFIX:String = "lastClassTimes_";
         private static const LAST_AI_HINT_PREFIX:String = "lastAiHint_";
		 
        private var m_classifier:BarModelClassifier;
        private var m_gameEngine:IGameEngine;
        private var m_textViewFactory:TextViewFactory;
        private var m_characterController:HelperCharacterController;
        private var m_assetManager:AssetManager;
        private var m_textParser:TextParser;
        private var m_policyFiles:Vector.<Object>;
        private var m_hintDicts:Vector.<Object>;
        private var m_qid:int;
        private var m_levelManager:WordProblemCgsLevelManager;
		private var m_validateBarModelArea:ValidateBarModelArea;
        
        //needs to be saved off & restored
        // private var m_timesHinted:int;
        //private var m_lastClass:String;
        private var m_playerStatsAndSaveData:PlayerStatsAndSaveData;
        
		public static const NUM_PROGRESSION_INDICIES:int = 2;
		
        public static const MAX_TIMES_AI_HINT_0:int = 10;
		public static const MAX_TIMES_AI_HINT_1:int = 20;
		
		public function getStartingTimeStep(progressionIndex:int):int {
			if (progressionIndex == 1) {
				var oldTimesHinted:int;
				 try {
					 var oldProgressionIndex: int = 0;
					 oldTimesHinted = int(m_playerStatsAndSaveData.getPlayerDecision(TIMES_HINTED_PREFIX +oldProgressionIndex ));
				} catch (TypeError) { //meaning no hints in first progression
					oldTimesHinted = 0;
				}
				return oldTimesHinted + 1;//1 for bridge state timestep
			} else {
				return 0;
			}
		}
        
        public function AiPolicyHintSelector(gameEngine:IGameEngine, validateBarModelArea:ValidateBarModelArea, 
		modelType:String, qid:int, characterController:HelperCharacterController, textviewFactory:TextViewFactory, assetManager:AssetManager, textParser:TextParser, levelManager:WordProblemCgsLevelManager, playerStats:PlayerStatsAndSaveData)
        {
            m_gameEngine = gameEngine;
            m_characterController = characterController;
            m_textViewFactory = textviewFactory;
            m_assetManager = assetManager;
            m_textParser = textParser;
			
			m_policyFiles = new Vector.<Object>(2, true);
			m_hintDicts = new Vector.<Object>(2, true);
			tryLoadMaps();
			
			 m_qid = qid;
            m_playerStatsAndSaveData = playerStats;
            m_levelManager = levelManager;
			m_validateBarModelArea = validateBarModelArea;
			
			
			var progressionIndex:int = getProgressionIndexFromQid(m_qid);
			if ((m_qid == 531 || m_qid == 701) && getLastLevel( progressionIndex) != m_qid) {
				trace("Restarting!");
				playerStats.setPlayerDecision(TIMES_HINTED_PREFIX + progressionIndex, getStartingTimeStep(progressionIndex));
				
			}
			if (getLastLevel( progressionIndex) != m_qid) {
				trace("New level!");
				playerStats.setPlayerDecision(LAST_CLASS_PREFIX + m_qid, null); //also invalidates last class times, last ai hint
			}
			playerStats.setPlayerDecision(LAST_LEVEL_PREFIX + progressionIndex, m_qid);
			trace("setting last level as" + m_qid + " using key " + (LAST_LEVEL_PREFIX + progressionIndex));
            
			
			 
           
            try{
				m_classifier = new BarModelClassifier(m_gameEngine, validateBarModelArea, modelType, qid);
			} catch (err:Error) {
				trace("Difficulty creating classifier!");
				m_classifier = null;
			}
        
        }
		
		private function tryLoadMaps():void {
			if (m_policyFiles[0] != null && m_policyFiles[1] != null  && m_hintDicts[0] != null && m_hintDicts[1] != null) {
				return;//everything loaded!
			}
			for (var i:int = 0; i < NUM_PROGRESSION_INDICIES; i++) {
				  m_policyFiles[i] = m_assetManager.getObject(POLICY_MAP_KEY + "_" + i);
				  m_hintDicts[i] = m_assetManager.getObject(HINT_DICT_KEY  + "_" + i);
			}
		}
        
        private function getProgressionIndexFromQid(qid:int):int
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
        private function getLevelIdFromQid(qid:int):int
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
        
        private function getProficientCondition(progressionIndex:int):Vector.<KOutOfNProficientCondition>
        {
            var ret:Vector.<KOutOfNProficientCondition> = new Vector.<KOutOfNProficientCondition>();
			//trace("retvec0: " + ret);
            var edgeToCondition:Object = m_levelManager.getEdgeIdToConditionsList();
            for (var edgeID:String in edgeToCondition) //TODO: To be safe check edgeID textually
            {
				trace("Found key " + edgeID);
                var vec:Vector.<ICondition> = edgeToCondition[edgeID];
                for each (var cond:ICondition in vec)
                {
					trace("Found condition of type " + cond.getType());
                    if (cond.getType() == KOutOfNProficientCondition.TYPE)
                    {
                        
                        ret.push(cond as KOutOfNProficientCondition);
                    }
                }
            }
			
			
			if ((ret.length != 1 && progressionIndex == 0) || (ret.length != 2  && progressionIndex == 1))
			{
				throw new Error("Wrong number of K of N conditions! there are " + ret.length + "  on prog index " + progressionIndex);
			}
			//trace("retvec: " + ret);
            return ret;
        
        }
		
		private function getProficientStringKOfN(proficientConditions:Vector.<KOutOfNProficientCondition>):String {
			var vecString:String = "";
			var proficientCondition:KOutOfNProficientCondition;
			for each (proficientCondition in proficientConditions) {
				 var vec:Vector.<Boolean> = proficientCondition.getLevelProficientHistory();
				var b:Boolean;
				
				for each (b in vec)
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
		
		private function getProficientStringMasteredBoth(proficientConditions:Vector.<KOutOfNProficientCondition>):String {
			var vecString:String = "";
			var proficientCondition:KOutOfNProficientCondition;
			for each (proficientCondition in proficientConditions) {
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
        
        private function getStateStringFromHintLoc(clas:String, hintsAtCurrentLoc:int, progressionIndex:int):String
        {
            //2_26_1_t_t_3
            
            
            var proficientConditions:Vector.<KOutOfNProficientCondition> = getProficientCondition(progressionIndex);
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
            
			var timesHinted:int = getTimesHinted(progressionIndex);
           
           
            
            var lookup:String = "(" + getLevelIdFromQid(m_qid) + "_" + BarModelClassifier.getGroupNumber(clas) + "_" + hintsAtCurrentLoc + "_" + vecString + "0),"+timesHinted;
            //return "2_26_1_t_t_3";
            return lookup;
        }
		
		private function getLastLevel(progressionIndex:int):int 
		{
			 var lastLevel:int;
             try {
                lastLevel = int(m_playerStatsAndSaveData.getPlayerDecision(LAST_LEVEL_PREFIX +progressionIndex ));
            } catch (TypeError) {
                lastLevel = 0;
            }
			trace("retrieved last level as " + lastLevel + " using key " + (LAST_LEVEL_PREFIX +progressionIndex));
			return lastLevel;
		}
		
		private function getTimesHinted(progressionIndex:int):int 
		{
			 var timesHinted:int;
             try {
				timesHinted = int(m_playerStatsAndSaveData.getPlayerDecision(TIMES_HINTED_PREFIX +progressionIndex ));
                
            } catch (TypeError) {
                timesHinted = getStartingTimeStep(progressionIndex);
            }
			return timesHinted;
		}
        
        private function sampleHintIndexFromTable(lookup:String):int
		{
			var policyMap:Object =  m_policyFiles[getProgressionIndexFromQid(m_qid)];
			if (policyMap != null && !policyMap.hasOwnProperty(lookup)) {
				trace ("Not actually  missing!");
				return 0;
			} 
            var probsStr:String = policyMap[lookup];
            var probsArr:Array = probsStr.split(",");
			trace("Sampling from probs: " + probsArr);
            var choice:Number = Math.random();
            var sum:Number = 0.0;
            var i:int;
            for (i = 0; i < probsArr.length; i++)
            {
                sum += Number(probsArr[i]);
                if (sum > choice)
                {
                    return i;
                }
            }
            throw new Error("Should not occur " + sum + " " + choice + " pStr:" + probsStr);
        
        }
        
        private function lookupHintFromIndex(index:int, clas:String):String
        {
            var hintDictKey:String = getLevelIdFromQid(m_qid) + "," + BarModelClassifier.getGroupNumber(clas);
            var hintListStr:String = m_hintDicts[getProgressionIndexFromQid(m_qid)][hintDictKey];
            var tokens:Array = hintListStr.split(",");
            trace("tokens0 " + tokens[0])
            return tokens[index];
        
        }
        
		
		override public function getHint():HintScript
		{
			var defaultText:String = "Just keep going!";
			try {
				return getHintInternal(defaultText);
			} catch (err:Error){
				
				var loadError:String ;
				try {
					var progressionIndex:int = getProgressionIndexFromQid(m_qid);
					loadError = (String)(m_assetManager.getObject(LOAD_ERROR_KEY + progressionIndex));
				} catch (err2:Error) {
					loadError = "None (seemingly)";
				}
				trace("Error in AI Hint! " + err.name + " " + err.message + " LoadError? " + loadError);
				var hintData:Object = {descriptionContent: (defaultText), erroredHint:(true), errorName:(err.name), errorMessage:(err.message), errorStackTrace:(loadError)};
            
				return HintCommonUtil.createHintFromMismatchData(hintData, m_characterController, m_assetManager, m_gameEngine.getMouseState(), m_textParser, m_textViewFactory, (m_gameEngine.getUiEntity("textArea") as TextAreaWidget), m_gameEngine, 200, 300);
            
			}
		}
		
		public function getHintUsingOld(oldHint:HintScript):HintScript
        {
			var defaultText:String = "Just keep going!";
			try {
				defaultText = oldHint.getSerializedData()["descriptionContent"];
				return getHintInternal(defaultText);
			} catch (err:Error){
				var loadError:String ;
				try {
					var progressionIndex:int = getProgressionIndexFromQid(m_qid);
					loadError = (String)(m_assetManager.getObject(LOAD_ERROR_KEY + progressionIndex));
				} catch (err2:Error) {
					loadError = "None (seemingly)";
				}
				trace("Error in AI Hint! " + err.name + " " + err.message + " LoadError? " + loadError);
				var hintData:Object = {descriptionContent: (defaultText), erroredHint:(true), errorName:(err.name), errorMessage:(err.message), errorStackTrace:(loadError)};
            
				return HintCommonUtil.createHintFromMismatchData(hintData, m_characterController, m_assetManager, m_gameEngine.getMouseState(), m_textParser, m_textViewFactory, (m_gameEngine.getUiEntity("textArea") as TextAreaWidget), m_gameEngine, 200, 300);
			}
		}
		
        public function getHintInternal(oldHint:String):HintScript
        {
			tryLoadMaps();
             var timesHinted:int;
             try {
                timesHinted = int(m_playerStatsAndSaveData.getPlayerDecision(TIMES_HINTED_PREFIX + getProgressionIndexFromQid(m_qid)));
            } catch (TypeError) {
                timesHinted = getStartingTimeStep(getProgressionIndexFromQid(m_qid));
            }
             if (getProgressionIndexFromQid(m_qid) ==0 && timesHinted >= MAX_TIMES_AI_HINT_0)
                return null;
			if (getProgressionIndexFromQid(m_qid) ==1 && timesHinted >= MAX_TIMES_AI_HINT_1)
                return null;
            trace("retrieved timesHinted as " + timesHinted)
            var hintsAtCurrentLoc:int = 1;
            var lastClass:String = m_playerStatsAndSaveData.getPlayerDecision(LAST_CLASS_PREFIX + m_qid) as String;
			//trace("lookup using qid " + m_qid);
            var lastClassTimes:int = 0;
            if (lastClass != null)
            {
                lastClassTimes = m_playerStatsAndSaveData.getPlayerDecision(LAST_CLASS_TIMES_PREFIX + m_qid) as int;
            }
           
            
            var hintsUsed:int = 1;
            
           
            
            
            var model:BarModelData = (m_gameEngine.getUiEntity("barModelArea") as BarModelAreaWidget).getBarModelData().clone();
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
                { //Already gave both levels of hints, no need to re-query
                    hintsUsed = 0;
                } 
                lastClassTimes++;
                
               
            }
            else
            {
                lastClassTimes = 0;
            }
            
             if (lastClassTimes > 2 && clas == lastClass) {
                var lastHint:Object = m_playerStatsAndSaveData.getPlayerDecision(LAST_AI_HINT_PREFIX + m_qid);
                var lastHintData:Object = {descriptionContent: (lastHint['descriptionContent']), highlightBarsThenTextFromDocIds: (lastHint['highlightBarsThenTextFromDocIds']), 
					highlightValidateButton: (lastHint['highlightValidateButton']), highlightBarModelArea: (lastHint['highlightBarModelArea']), 
					highlightBarsThenTextColor: (lastHint['highlightBarsThenTextColor']),
					question: (lastHint['question']),
					highlightBarModelAreaColor: (lastHint['highlightBarModelAreaColor']), highlightValidateButtonColor: (lastHint['highlightValidateButtonColor']), 
					isOldHint:1};
                return HintCommonUtil.createHintFromMismatchData(lastHintData, m_characterController, m_assetManager, m_gameEngine.getMouseState(), m_textParser, m_textViewFactory, (m_gameEngine.getUiEntity("textArea") as TextAreaWidget), m_gameEngine, 200, 300);
            }
			
			
            //trace("LastClasTimes " + lastClassTimes);
			var progressionIndex:int = getProgressionIndexFromQid(m_qid);
            
            var lookup:String = getStateStringFromHintLoc(clas, lastClassTimes, progressionIndex);
			
            var index:int = 0;
			try{
				index = sampleHintIndexFromTable(lookup);
			} catch (err:Error) {
				throw new Error("Unable to lookup string " + lookup + " at qid " + m_qid);
			}
            var hint:String;
		 
			
			//trace("choosing from " + lookupHintFromIndex(0, clas) + " OR " + lookupHintFromIndex(1, clas) + " OR " + lookupHintFromIndex(2, clas) );
			
			if (index == 0) {
				hint = oldHint;
			} else {
				hint = lookupHintFromIndex(index, clas);
				hint = hint.replace(/_/g, " ").replace(/\|/g, ',').replace(/@/g, ':');
			}
			
			//hint += "<ans=unk>";//TODO:Remove!
			var hintDC:String = hint;
			
			
			
			var idToExpression:Object = {};
			var textWidget:TextAreaWidget = (m_gameEngine.getUiEntity("textArea") as TextAreaWidget);
			var expressionComponents:Vector.<Component> = textWidget.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
			for each (var expressionComponent:ExpressionComponent in expressionComponents)
			{
				idToExpression[expressionComponent.entityId] = expressionComponent.expressionString;
				/// If desire abbrevName: m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(expressionComponent.expressionString).abbreviatedName
			}
			
			
			
			var highlightParts:Array = new Array();
			var highlightCheck:Boolean = false;
			var highlightBackground:Boolean = false;
			
			if (hintDC.indexOf("<a>") >= 0) {
				hintDC = hintDC.replace('<a>', '');
				highlightParts.push("a1");
			}
			if (hintDC.indexOf("<b>") >= 0) {
				hintDC = hintDC.replace('<b>', '');
				highlightParts.push("b1");
			}
			if (hintDC.indexOf("<unk>") >= 0) {
				hintDC = hintDC.replace('<unk>', '');
				highlightParts.push("unk");
			}
			if (hintDC.indexOf("<check>") >= 0) {
				hintDC = hintDC.replace('<check>', '');
				highlightCheck = true;
			}
			if (hintDC.indexOf("<back>") >= 0) {
				hintDC = hintDC.replace('<back>', '');
				highlightBackground = true;
			}
			
			
			var questionType:int = 0;
			var answer:String = "";
			
			if (hintDC.indexOf("<ans=a>") >= 0) {
				hintDC = hintDC.replace('<ans=a>', '');
				questionType = 1;
				answer = "a1";
			}
			if (hintDC.indexOf("<ans=b>") >= 0) {
				hintDC = hintDC.replace('<ans=b>', '');
				questionType = 1;
				answer = "b1";
			}
			if (hintDC.indexOf("<ans=unk>") >= 0) {
				hintDC = hintDC.replace('<ans=unk>', '');
				questionType = 1;
				answer = "unk";
			}
			if (hintDC.indexOf("<ans=yes>") >= 0) {
				hintDC = hintDC.replace('<ans=yes>', '');
				questionType = 2;
				answer = "yes";
			}
			if (hintDC.indexOf("<ans=no>") >= 0) {
				hintDC = hintDC.replace('<ans=no>', '');
				questionType = 2;
				answer = "no";
			}
			var question:Object = null;
			if (questionType == 1) {
				trace("setting question type 1!");
				question={ "text": hintDC, "answers":[
						{"name":idToExpression['a1'], "correct": (answer == 'a1')}, 
						{"name":idToExpression['b1'], "correct": (answer == 'b1')}, 
						{"name":idToExpression['unk'], "correct": (answer == 'unk')}
					]
			   };
			} else if (questionType == 2) {
				trace("setting question type 2!");
				question={ "text": hintDC, "answers":[
						{"name":"yes", "correct": (answer ==  "yes")}, 
						{"name":"no", "correct":(answer == "no")}
					]
				};
			}
			
			
			trace("highlight background? " + highlightBackground);
			
			//This line enables Zoran's demo
			//hint = "Misconception: " + BarModelClassifier.getHumanReadable(clas) + ". (" + clas + ")";
			
			var modelSer:Object = model.serialize();
			var valid:Boolean = m_validateBarModelArea.getCurrentModelMatchesReference();
            
			var loggingString:String = lookup.replace(/,/g, "_").replace(/\)/g, "").replace(/\(/g, "");
			trace("logging lookup as " + loggingString);
            var hintData:Object = {descriptionContent: (hintDC), highlightBarsThenTextFromDocIds: (highlightParts), 
					highlightValidateButton: (highlightCheck), highlightBarModelArea: (highlightBackground), highlightBarsThenTextColor: (0XA5FF00),
					highlightBarModelAreaColor: (0XA5FF00), highlightValidateButtonColor: (0XA5FF00),
					barModelClassification: (clas), rlStateString: (loggingString), question: (question),
					rlActionIndex: (index), barModel: (modelSer), isValid:(valid), version:(4)};
            
            
            
            
            var hintToRun:HintScript = HintCommonUtil.createHintFromMismatchData(hintData, m_characterController, m_assetManager, m_gameEngine.getMouseState(), m_textParser, m_textViewFactory, (m_gameEngine.getUiEntity("textArea") as TextAreaWidget), m_gameEngine, 200, 300);
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

}