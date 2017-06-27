package wordproblem.engine.barmodel.analysis 
{
    import dragonbox.common.system.Map;
    import flash.utils.Dictionary;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.BarModelTypes;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.level.WordProblemLevelData;
    import wordproblem.engine.widget.TextAreaWidget;
    import wordproblem.scripts.barmodel.ValidateBarModelArea;
    import wordproblem.engine.IGameEngine;
    import wordproblem.hints.selector.ShowHintOnBarModelMistake;
    import wordproblem.hints.HintSelectorNode;
        import flash.net.FileReference;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.events.Event;
    
    /**
     * Manually classify Bar Models into different categories for the purpose of hint generation
     * ...
     * @author Travis Mandel
     */
    public class BarModelClassifier 
    {
    
        /**
         * Need to keep a reference to this because on disposal the game engine purges itself of widgets.
         * Still want to properly clean up the components attached to it though.
         */
        private var m_textArea:TextAreaWidget;
        
         /**
         * Mapping from document id to an expression/term value
         * Relies on fact that document ids in a level can be directly mapped to elements in a
         * template of a bar model type. For example the doc id 'b1' refers to the number of
         * groups in any type 3a model.
         */
        private var m_documentIdToExpressionMap:Object;
        
        private var m_validateBarModelArea:ValidateBarModelArea;
        
        private var m_modelType:String;
        
        private var m_gameEngine:IGameEngine;
        private var m_qid:int;
        
        //private var m_level:WordProblemLevelData;
        
        
        public function BarModelClassifier(gameEngine:IGameEngine,
                                           validateBarModelArea:ValidateBarModelArea,
                                           modelType:String,
                                           qid:int) 
        {
            m_gameEngine = gameEngine;
            //m_level = level;
            m_qid = qid;
            m_textArea = gameEngine.getUiEntity("textArea") as TextAreaWidget;
            m_validateBarModelArea = validateBarModelArea;
            m_modelType = modelType;
            if (!isValidLevelType(m_modelType)) {
                throw new Error("model classifier should not be invoked on level of type " +  m_modelType);
            }
        }
        
        private function tryTest():void {
            var filename:String = "../assets/data/";
            if (m_qid == 520) {
                filename += "models520.out";
            } else if (m_qid == 853) {
                filename += "models853.out";
            } else {
                trace("out of range qid " + m_qid);
                return;
            }
            var url:URLRequest = new URLRequest(filename);


var loader:URLLoader = new URLLoader();
loader.load(url);

loader.addEventListener(Event.COMPLETE, loaderComplete);
//trace("Loading...");
function loaderComplete(e:Event):void
{
    trace("Done loading!");
    // The output of the text file is available via the data property
    // of URLLoader.
    var tokens:Array = loader.data.split("\n");
    trace(tokens.length + " lines!");
    var i:int;
    for (i = 0; i < tokens.length; i++ ) {
        var token:String = tokens[i];
        var model:BarModelData = new BarModelData();
        try{
        model.deserialize(JSON.parse(token));
        } catch (SyntaxError ) {
            trace("Syntax Error parsing line \"" + token +"\"");
            continue;
        }
        if (isValidModel(model)) {
            var clas:String = getClassification(model);
            if (clas == null) {
                
                trace("NULL class! " + token);
                //return;
            }
            //trace("valid class " + clas);
        }
    }
    trace("Done!")
}

}
        
         /**
         * Maps from an heriarchical categorization id (a1, c4, etc) to a human-readable description
         * 
         * @return
         *       human readable description of where the kid is stuck
         */
        public static function getHumanReadable(groupid:String):String {
            switch(groupid) {
                case "A1": return "A vertical pointing to B and unknown";
                case "A2": return "B vertical pointing to A and unknown";  
                case "A3": return "Unknown vertical pointing to A and B";  
                case "B1": return "A is the only thing placed"; 
                case "B2": return "B is the only thing placed";  
                case "B3": return "Unknown is the only thing placed";  
                case "C1": return "Unknown and B side-by-side"; 
                case "C2": return "Unknown and A side-by-side"; 
                case "C3": return "A and B side-by-side"; 
                case "D1": return "A, B, and unknown all side-by-side"; 
                case "E1": return "A horizontal pointing to B and unknown."; 
                case "E2": return "B horizontal pointing to A and unknown.";   
                case "E3": return "Unknown horizontal pointing to A and B";  
                case "F1": return "A pointing at B"; 
                case "F2": return "A pointing at Unknown"; 
                case "F3": return "B pointing at A"; 
                case "F4": return "B pointing at Unknown";
                case "F5": return "Unknown pointing at A";  
                case "F6": return "Unknown pointing at B";  
                case "G1": return "Unknown and B vertical"; 
                case "G2": return "Unknown and A vertical"; 
                case "G3": return "A and B vertical"; 
                case "H1": return "B and Unknown pointing to A"; 
                case "H2": return "A and Unknown pointing to B"; 
                case "H3": return "A and B pointing to Unknown"; 
                case "I1": return "A above/below Unknown, B"; 
                case "I2": return "B above/below Unknown, A"; 
                case "I3": return "Unknown above/below A,B"; 
                case "J1": return "Unknown, B vertical; A pointing at B"; 
                case "J2": return "Unknown, B vertical; A pointing at Unknown"; 
                case "J3": return "Unknown, A vertical; B pointing at A"; 
                case "J4": return "Unknown, A vertical; B pointing at Unknown";
                case "J5": return "A, B vertical; Unknown pointing at A";  
                case "J6": return "A, B vertical; Unknown pointing at B";  
                case "K1": return "Correct?!"; 
                case "K2": return "Correct?!"; 
                case "K3": return "Correct?!"; 
                case "L1": return "A, B, and unknown all vertical"; 
                case "M1": return "Nothing is placed"; 
                default: throw new Error("Unrecognized group id " + groupid); 
            }
        }
        
        
        /**
         * Maps from an heriarchical categorization id (a1, c4, etc) to a numeric id
         * 
         * @return
         *       numeric id to be used by machine learning hint generation system.
         */
        public static function getGroupNumber(groupid:String):int {
            switch(groupid) {
                case "A1": return 0; 
                case "A2": return 1; 
                case "A3": return 2; 
                case "B1": return 3; 
                case "B2": return 4; 
                case "B3": return 5; 
                case "C1": return 6; 
                case "C2": return 7; 
                case "C3": return 8; 
                case "D1": return 9; 
                case "E1": return 10; 
                case "E2": return 11; 
                case "E3": return 12;
                case "F1": return 13; 
                case "F2": return 14; 
                case "F3": return 15; 
                case "F4": return 16; 
                case "F5": return 17; 
                case "F6": return 18; 
                case "G1": return 19; 
                case "G2": return 20; 
                case "G3": return 21; 
                case "H1": return 22; 
                case "H2": return 23; 
                case "H3": return 24; 
                case "I1": return 25; 
                case "I2": return 26; 
                case "I3": return 27; 
                case "J1": return 28; 
                case "J2": return 29; 
                case "J3": return 30; 
                case "J4": return 31; 
                case "J5": return 32; 
                case "J6": return 33; 
                case "K1": return 34; 
                case "K2": return 35; 
                case "K3": return 36; 
                case "L1": return 37; 
                case "M1": return 38; 
                default: throw new Error("Unrecognized group id " + groupid); 
            }
        }
		
		private function extractInt(expression:String):int {
			var parts:Array = expression.split(" ");
			if (parts.length > 0)
			{
				 var expressionAsNumber:Number = parseInt(parts[0], 10);
				 if (!isNaN(expressionAsNumber))
				 {
					  return int(expressionAsNumber);
				 }
			}
			throw new Error("Number not at start of expression?  " + expression);
		}
        
        
         /**
         * Maps from an id (a(smaller value) , b (larger value), or total) to the specific name of the label as it will appear in the bar model diagram
         * 
         * @return
         *       the label value representing this part in this level's bar model.
         */
        private function getName(partid:String ):String {
            var akey:String;
            var bkey:String;
            var totalkey:String;
            if ( extractInt(m_documentIdToExpressionMap["a1"]) < extractInt(m_documentIdToExpressionMap["b1"])) {
                    akey = "a1";
                    bkey = "b1";
                } else {
                    akey = "b1";
                    bkey = "a1";
                }
                
                totalkey = "unk";
            /*if (m_modelType == BarModelTypes.TYPE_1A || m_modelType == BarModelTypes.TYPE_2B || m_modelType == BarModelTypes.TYPE_1B || m_modelType == BarModelTypes.TYPE_2E)
            {
                // b1 = b (part of sum), a1 = a (part of sum), unk = ? (total)
                if ( int(m_documentIdToExpressionMap["a1"]) < int(m_documentIdToExpressionMap["b1"])) {
                    akey = "a1";
                    bkey = "b1";
                } else {
                    akey = "b1";
                    bkey = "a1";
                }
                
                totalkey = "unk";
                
                
               
            }
           / // All Type2 problems can be changed to a sum model or have the smaller value and difference swapped out
            else if (m_modelType == BarModelTypes.TYPE_2A)
            {
                // b1 = b (larger value), a1 = a (smaller value), unk = ? (difference)
                akey = "a1";
                bkey = "b1";
                totalkey = "unk";
            }
            else if (m_modelType == BarModelTypes.TYPE_2C)
            {
                // b1 = b (larger value), a1 = a (difference), unk = ? (smaller value)
                akey = "unk";
                bkey = "b1"
                totalkey = "a1";
            }
            else if (m_modelType == BarModelTypes.TYPE_2D)
            {
                // b1 = b (difference), a1 = a (smaller value), unk = ? (larger value)
                akey = "a1";
                bkey = "unk"
                totalkey = "b1";
            }*/
            
            if ( int(m_documentIdToExpressionMap[bkey]) < int(m_documentIdToExpressionMap[akey])) {
                    throw new Error("a and b switched!")
            }
            
            //trace(m_modelType + " a1:" +  m_documentIdToExpressionMap["a1"] + " b1:" + m_documentIdToExpressionMap["b1"] + " unk:" + m_documentIdToExpressionMap["unk"]);
            
            switch(partid) {
                case "a": return m_documentIdToExpressionMap[akey];
                case "b": return m_documentIdToExpressionMap[bkey];
                case "total": return m_documentIdToExpressionMap[totalkey];
                default:throw new Error("unrecognized part id!");
            }
            
        }
        
         /**
         * Classifier only applies to a subset of levels (2-way addition/subtraction levels)
         * This identifies whether a level model pair is in this set
         * 
         * @return
         *       true iff this model is in the set the classifier is intended to classify
         */
        public static function isValidLevelDefinition(documentIdToExpressionMap:Object):Boolean {
            var c:int = 0;
            for (var key:Object in documentIdToExpressionMap){
                if (key != "a1" && key != "unk" && key != "b1") {
                    return false;
                }
                c++;
            }
            if (c != 3) {
                trace("Level contains " + c + " entities!"); 
                return false;
            }
            return true;
        }
        public static function isValidLevelType(modelType:String):Boolean {

            //TODO: Double-check Singapore types against progression (when defined)
            var modelTypes:Vector.<String> = new <String>[BarModelTypes.TYPE_1A, BarModelTypes.TYPE_1B, BarModelTypes.TYPE_2A, BarModelTypes.TYPE_2B,  BarModelTypes.TYPE_2C,  BarModelTypes.TYPE_2D,  BarModelTypes.TYPE_2E];
            //check level
            if (modelTypes.indexOf(modelType) < 0 ) { //!contains
                return false;
            }
            
            return  true;
        }

        
        
         /**
         * Classifier only applies to a subset of possible models (no duplicates, well formed)
         * This identifies whether a model is in this set
         * 
         * @return
         *       true iff this model is in the set the classifier is intended to classify
         */
        private function isValidModel(model:BarModelData):Boolean
        {
            
            
            
            
            
            var i:int;
            var j:int;
            var value:String;
            var label:BarLabel;
            //check labels
            var allLabels:Vector.<String> = new Vector.<String>;
            for (i = 0; i < model.barWholes.length; i++ ) {
                for (j = 0; j < model.barWholes[i].barLabels.length; j++ ){
                    label = model.barWholes[i].barLabels[j];
                    //bottom labels which partially span not valid
                    if ( label.bracketStyle == BarLabel.BRACKET_STRAIGHT && 
                    (label.startSegmentIndex !=  0  || label.endSegmentIndex != (model.barWholes[i].barSegments.length-1))) {
                        return false;
                        
                    }
                    value = label.value;
                    if (allLabels.indexOf(value) >= 0) { //contains
                        return false;
                    }
                    allLabels.push(value);
                }
            }
            for (i = 0; i < model.verticalBarLabels.length; i++ ) {
                value = model.verticalBarLabels[i].value;
                //bottom labels with same start and end not valid
                if (label.bracketStyle == BarLabel.BRACKET_STRAIGHT && label.startSegmentIndex == label.endSegmentIndex) {
                    return false;    
                }
                if (allLabels.indexOf(value) >= 0) { //contains
                        return false;
                }
                allLabels.push(value);
            }
            //trace("All Labels: " + allLabels);
            
            if (allLabels.length > 3)
                return false;
            
            //check labels against level
            var levelLabels:Vector.<String> = new Vector.<String>;
            levelLabels.push(getName("a"), getName("b"), getName("total"));
            //trace("Level Labels: " + levelLabels);
            var l:int;
            for (l = 0; l < allLabels.length; l++) {
                if (levelLabels.indexOf(allLabels[i]) < 0) { //!contains
                    throw new Error("model contains something not in level description!");
                }
            }
            
            
            return true;
        }
        
        
         /**
         * Classifies a model into one of several broader types.
         * This should be used as a way to reduce the space of where to give hints
         * 
         * @return
         *       a string indicating what type this model falls into, or null if not covered.
         *         Use the static method getGroupNumber() to turn this into a numeric value
         */
        public function getClassification(model:BarModelData):String
        {
            
            if (m_documentIdToExpressionMap == null)
            {
                m_documentIdToExpressionMap = m_textArea.getDocumentIdToExpressionMap();
                if (!isValidLevelDefinition(m_documentIdToExpressionMap)) {
                    throw new Error("model classifier should not be invoked on level of type " +  m_modelType);
                }
                //tryTest();//just for testing, make sure example models have a valid classification
            }
            
            model.replaceAllAliasValues(m_validateBarModelArea.getAliasValuesToTerms());
            if (!isValidModel(model))
                return null;
                //throw new Error("Invalid model!");
            
            var label:BarLabel;
            if (model.verticalBarLabels.length > 0) {
                if (model.verticalBarLabels.length > 1) {
                    throw new Error("More than one vertical label in 3 element diagram!");
                }
                if ( model.verticalBarLabels[0].value == getName("a")) {
                    return "A1";
                } else if ( model.verticalBarLabels[0].value == getName("b")) {
                    return "A2";
                } else if ( model.verticalBarLabels[0].value == getName("total")) {
                    return "A3";
                } else {
                    trace("Unrecognized value " + model.verticalBarLabels[0].value)
                    return null;
                }
            }
            
            if (model.barWholes.length == 0) {
                if (model.verticalBarLabels.length != 0) {
                    trace("how can there be vertical labels if no blocks?");
                    return null;
                }
                return "M1"
            }
            if (model.barWholes.length == 1) {
                //just one segment
                if (model.barWholes[0].barLabels.length == 1) {
                    
                    label = model.barWholes[0].barLabels[0];
                    if (label.startSegmentIndex != 0 || label.endSegmentIndex != 0) {
                        throw new Error("Huh?");
                    }
                    if (label.bracketStyle != BarLabel.BRACKET_NONE) {
                        trace("Unrecognized situation! Only one label, and label on bottom! " + label.bracketStyle);
                        return null;
                    }
                    if ( label.value == getName("a")) {
                        return "B1";
                    } else if ( label.value == getName("b")) {
                        return "B2";
                    } else if ( label.value  == getName("total")) {
                        return "B3";
                    } else {
                        trace("Unrecognized value " + label.value)
                        return null;
                    }
                }
                if (model.barWholes[0].barSegments.length == 1 && model.barWholes[0].barLabels.length == 2) {
                    //type F
                    var straightLabel:String = null;
                    var bracketLabel2:String = null;
                    for (j = 0; j < 2; j++) {
                        label = model.barWholes[0].barLabels[j];
                        if (label.startSegmentIndex != 0 || label.endSegmentIndex != 0) {
                            trace("Misaligned label!");
                                return null;
                        }
                        if (label.bracketStyle != BarLabel.BRACKET_STRAIGHT) {
                            if (label.bracketStyle != BarLabel.BRACKET_NONE) {
                                trace("Unrecognized bracket type!");
                                return null;
                            }
                            if (straightLabel != null) {
                                trace("Two straight labels but only one segment?");
                                return null;
                            }
                            straightLabel = label.value;
                            
                        } else {
                            if (bracketLabel2 != null) {
                                trace("Two curved brackets but only two labels?");
                                return null;
                            }
                            bracketLabel2 = label.value;
                        }
                        
                        
                    }
                    if ( bracketLabel2 == getName("a") && straightLabel == getName("b")) {
                        return "F1";
                    } else if  ( bracketLabel2 == getName("a") && straightLabel == getName("total")) {
                        return "F2";
                    } else if ( bracketLabel2 == getName("b") && straightLabel == getName("a")) {
                        return "F3";
                    } else if ( bracketLabel2 == getName("b") && straightLabel == getName("total")) {
                        return "F4";
                    } else if ( bracketLabel2 == getName("total") && straightLabel == getName("a")) {
                        return "F5";
                    } else if ( bracketLabel2 == getName("total") && straightLabel == getName("b")) {
                        return "F6";
                    } else {
                        trace("Unrecognized bracket pair! ")
                        return null;
                    }
                    
                }
                if (model.barWholes[0].barSegments.length == 1 && model.barWholes[0].barLabels.length == 3) {
                    //stacked brackets, type H
                    var regLabel:String = null;
                    var j2:int;
                    for (j2 = 0; j2 < 3; j2++) {
                        label = model.barWholes[0].barLabels[j2];
                        if (label.bracketStyle != BarLabel.BRACKET_NONE) {
                            if (label.bracketStyle != BarLabel.BRACKET_STRAIGHT) {
                                trace("Unrecognized bracket type!");
                                return null;
                            }
                            continue;
                        }
                        if (label.startSegmentIndex != 0 || label.endSegmentIndex != 0) {
                            trace("Misaligned label!");
                                return null;
                        }
                        if (regLabel != null) {
                            trace("Two straight brackets on one segment?");
                            return null;
                        }
                        regLabel = label.value;
                    }
                    
                    if ( regLabel == getName("a")) {
                        return "H1";
                    } else if ( regLabel == getName("b")) {
                        return "H2";
                    } else if ( regLabel  == getName("total")) {
                        return "H3";
                    } else {
                        trace("Unrecognized value " + regLabel)
                        return null;
                    }
                }
                if (model.barWholes[0].barSegments.length == 2 && model.barWholes[0].barLabels.length == 2) {
                    var labelVec:Vector.<String> = new Vector.<String>();
                    var j:int;
                    if (model.barWholes[0].barLabels[0].startSegmentIndex == model.barWholes[0].barLabels[1].startSegmentIndex) {
                        trace("Two labels in same place?")
                        return null;
                    }
                    for (j = 0; j < 2; j++) {
                        label = model.barWholes[0].barLabels[j];
                        if ((label.startSegmentIndex != 0 && label.startSegmentIndex != 1) || 
                            (label.startSegmentIndex != label.endSegmentIndex)) {
                                trace("Strange segement index")
                                return null;
                            }
                            
                        if (label.bracketStyle != BarLabel.BRACKET_NONE) {
                            trace("Unrecognized situation! Not enough top labels for boxes! ");
                            return null;
                        }
                            
                        if (labelVec.indexOf( label.value) >= 0) {
                            trace("Duplicate label!")
                            return null;
                        }
                        labelVec.push(label.value);
                    }
                    if ( labelVec.indexOf(getName("a")) < 0) {
                        return "C1";
                    } else if ( labelVec.indexOf(getName("b")) < 0) {
                        return "C2";
                    } else if ( labelVec.indexOf(getName("total")) < 0) {
                        return "C3";
                    } else {
                        trace("Huh? Not missing anything, but only 2 parts! ")
                        return null;
                    }
                    
                }
                if (model.barWholes[0].barSegments.length == 2 && model.barWholes[0].barLabels.length == 3) {
                    var bracketLabel:String = null;
                    for (j2 = 0; j2 < 3; j2++) {
                        label = model.barWholes[0].barLabels[j2];
                        if (label.bracketStyle != BarLabel.BRACKET_STRAIGHT) {
                            if (label.bracketStyle != BarLabel.BRACKET_NONE) {
                                trace("Unrecognized bracket type!");
                                return null;
                            }
                            continue;
                        }
                        if (label.startSegmentIndex != 0 || label.endSegmentIndex != 1) {
                            trace("Misaligned label!");
                                return null;
                        }
                        if (bracketLabel != null) {
                            trace("Two curved brackets but also two segements?");
                            return null;
                        }
                        bracketLabel = label.value;
                    }
                    
                    if ( bracketLabel == getName("a")) {
                        return "E1";
                    } else if ( bracketLabel == getName("b")) {
                        return "E2";
                    } else if ( bracketLabel  == getName("total")) {
                        return "E3";
                    } else {
                        trace("Unrecognized value " + label.value)
                        return null;
                    }
                
                }
                
                if (model.barWholes[0].barSegments.length == 3) {
                    if (model.barWholes[0].barLabels.length != 3) {
                        trace("huh? 3 bars but not 3 labels!");
                        return null;
                    }
                    return "D1";
                }
            }
            if (model.barWholes.length == 2) {
                if (model.barWholes[0].barSegments.length == 1 && model.barWholes[1].barSegments.length == 1 
                && model.barWholes[0].barLabels.length == 1 && model.barWholes[1].barLabels.length == 1 && 
                model.barWholes[0].barComparison == null && model.barWholes[1].barComparison == null) {
                    labelVec = new Vector.<String>();
                    var j3:int;
                    for (j3 = 0; j3 < 2; j3++) {
                        label = model.barWholes[j3].barLabels[0];
                        if (label.startSegmentIndex != 0  || label.endSegmentIndex != 0) {
                                trace("Misaligned segement index")
                                return null;
                            }
                            
                        if (label.bracketStyle != BarLabel.BRACKET_NONE) {
                            trace("Weird situation! Not enough top labels for boxes! ");
                            return null;
                        }
                            
                        if (labelVec.indexOf( label.value) >= 0) {
                            trace("Duplicate label not allowed!")
                            return null;
                        }
                        labelVec.push(label.value);
                    }
                    if ( labelVec.indexOf(getName("a")) < 0) {
                        return "G1";
                    } else if ( labelVec.indexOf(getName("b")) < 0) {
                        return "G2";
                    } else if ( labelVec.indexOf(getName("total")) < 0) {
                        return "G3";
                    } else {
                        trace("Huh? Not missing anything, but only 2 vertical parts! ")
                        return null;
                    }
                }
                if ((model.barWholes[0].barSegments.length == 2 && model.barWholes[1].barSegments.length == 1)  || 
                    (model.barWholes[0].barSegments.length == 1 && model.barWholes[1].barSegments.length == 2  )) {
                    var aloneLabel:String = null;
                    var j4:int;
                    for (j4 = 0; j4 < 2; j4++) {
                        if (model.barWholes[j4].barSegments.length != 1) {
                            continue;
                        }
                        label = model.barWholes[j4].barLabels[0];
                        if (label.startSegmentIndex != 0 || label.endSegmentIndex != 0) {
                            trace("Misaligned label!");
                                return null;
                        }
                        if (aloneLabel != null) {
                            trace("Huh?");
                            return null;
                        }
                        aloneLabel = label.value;
                    }
                    if ( aloneLabel == getName("a")) {
                        return "I1";
                    } else if ( aloneLabel == getName("b")) {
                        return "I2";
                    } else if ( aloneLabel  == getName("total")) {
                        return "I3";
                    } else {
                        trace("Unrecognized value " + aloneLabel)
                        return null;
                    }
                } else if ((model.barWholes[0].barLabels.length == 2 && model.barWholes[1].barLabels.length == 1)  || 
                    (model.barWholes[0].barLabels.length == 1 && model.barWholes[1].barLabels.length == 2 ) ) {
                    for (j2 = 0; j2 < 2; j2++) {
                        if (model.barWholes[j2].barLabels.length < 2)
                            continue;
                            
                        for (j = 0; j < 2; j++) {
                            label = model.barWholes[j2].barLabels[j];
                            if (label.startSegmentIndex != 0 || label.endSegmentIndex != 0) {
                                trace("Misaligned label!");
                                    return null;
                            }
                            if (label.bracketStyle != BarLabel.BRACKET_STRAIGHT) {
                                if (label.bracketStyle != BarLabel.BRACKET_NONE) {
                                    trace("Unrecognized bracket type!");
                                    return null;
                                }
                                if (straightLabel != null) {
                                    trace("Two straight labels but only one segment?");
                                    return null;
                                }
                                straightLabel = label.value;
                                
                            } else {
                                if (bracketLabel2 != null) {
                                    trace("Two curved brackets but only two labels?");
                                    return null;
                                }
                                bracketLabel2 = label.value;
                            }
                            
                            
                        }
                    }
                    
                    if ( bracketLabel2 == getName("a") && straightLabel == getName("b")) {
                        return "J1";
                    } else if  ( bracketLabel2 == getName("a") && straightLabel == getName("total")) {
                        return "J2";
                    } else if ( bracketLabel2 == getName("b") && straightLabel == getName("a")) {
                        return "J3";
                    } else if ( bracketLabel2 == getName("b") && straightLabel == getName("total")) {
                        return "J4";
                    } else if ( bracketLabel2 == getName("total") && straightLabel == getName("a")) {
                        return "J5";
                    } else if ( bracketLabel2 == getName("total") && straightLabel == getName("b")) {
                        return "J6";
                    } else {
                        trace("Unrecognized bracket pair! ")
                        return null;
                    }
                }
                if (model.barWholes[0].barComparison != null || model.barWholes[1].barComparison != null) {
                    if (model.barWholes[0].barSegments.length != 1 || model.barWholes[1].barSegments.length != 1 
                    || model.barWholes[0].barLabels.length != 1 || model.barWholes[1].barLabels.length != 1) {
                        trace("Hmm, comparison struct in strange model!");
                        return null;
                    }
                    //var unkval:int = m_level.termValueToBarModelValue["unk"];
                    var clabel:String = null;
                    for (j2 = 0; j2 < 2; j2++) {
                        if (model.barWholes[j2].barComparison == null)
                            continue;
                        if (clabel != null) {
                            trace("Multiple c labels!");
                            return null;
                        }
                        clabel = model.barWholes[j2].barComparison.value;
                    }
                    if ( clabel == getName("a")) {
                        return "K1";
                    } else if ( clabel == getName("b")) {
                        return "K2";
                    } else if ( clabel  == getName("total")) {
                        return "K3";
                    } else {
                        trace("Unrecognized value " + clabel)
                        return null;
                    }
                    
                    
                    
                }
            }
            if (model.barWholes.length == 3) {
                if (model.barWholes[0].barSegments.length != 1 || model.barWholes[1].barSegments.length != 1 ||model.barWholes[2].barSegments.length != 1 
                    || model.barWholes[0].barLabels.length != 1 || model.barWholes[1].barLabels.length != 1  || model.barWholes[2].barLabels.length != 1) {
                        trace("Malformed triple vertical!");
                        return null;
                    }
                return "L1";
            }
            
            
            
            return null;
        }
        
        
        
        
    }

}