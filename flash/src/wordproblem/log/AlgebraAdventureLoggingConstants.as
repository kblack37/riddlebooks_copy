package wordproblem.log 
{
	import flash.utils.Dictionary;
	
	import cgs.server.logging.GameServerData;
	
	/**
	 * ...
	 * @author Rich
	 */
	public class AlgebraAdventureLoggingConstants 
	{
		// Game information
        public static const SKEY:String = "4047346551f969e5c329dd2eececbcd8";
        public static const SKEY_HASH:int = GameServerData.DATA_SKEY_HASH;
        public static const GAME_NAME:String = "wordproblems";
        public static const GAME_ID:int = 17;
		
		// Action Events
        public static const PHRASE_PICKUP_EVENT:String         = "phrasePickup_logActionEvent";
        public static const PHRASE_DROP_EVENT:String           = "phraseDrop_logActionEvent";
        public static const EXPRESSION_PICKUP_EVENT:String     = "expressionPickup_logActionEvent";
        public static const EXPRESSION_DROP_EVENT:String       = "expressionDrop_logActionEvent";
        
        /**
         * Pressed exit button before level was completed
         */
        public static const EXIT_BEFORE_COMPLETION:String = "exit_before_complete";
        
        /**
         * Pressed skip button
         */
        public static const SKIP:String = "skip";
        
        /**
         * Fired when the player attempts to submit their constructed equation model as an answer
         * 
         * param: {isCorrect:Boolean if modeled equation was correct, 
         * setComplete:Boolean if all equation in a goal set were complete, 
         * equation: string version of the equation submitted,
         * goalEquation: string version of the equation they were trying to match with
         * }
         */
        public static const VALIDATE_EQUATION_MODEL:String      = "equationModeled_logActionEvent";
        public static const EXPRESSION_FOUND_EVENT:String      = "expressionFound_logActionEvent";
        public static const ALL_EXPRESSIONS_FOUND_EVENT:String = "allExpressionsFound_logActionEvent";
        public static const NEGATE_EXPRESSION_EVENT:String     = "negateExpression_logActionEvent";
        public static const EQUATION_CHANGED_EVENT:String      = "equationChanged_logActionEvent";
        public static const BUTTON_PRESSED_EVENT:String        = "buttonPressed_logActionEvent";
        public static const LEVEL_FINISHED_EVENT:String        = "levelFinished_logActionEvent";
        public static const EQUALS_CLICKED_EVENT:String        = "equalsClicked_logActionEvent"; // IS or EQUALS button clicked
        public static const TUTORIAL_PROGRESS_EVENT:String     = "tutorialProgress_logActionEvent"; // Any type of tutorial level progress cause by the player, ie picking a text field or clicking anywhere on the screen when told to
        public static const UNDO_EQUATION:String   = "undoEquation";
		public static const RESET_EQUATION:String  = "resetEquation";
		
        /*
        The bar model actions have a barModel parameter that is a json formatted representation of a bar model
        */
        public static const ADD_NEW_BAR:String = "addNewBar";
        public static const ADD_NEW_BAR_COMPARISON:String = "addNewBarComparison";
        public static const ADD_NEW_BAR_SEGMENT:String = "addNewBarSegment";
        public static const ADD_NEW_HORIZONTAL_LABEL:String = "addNewHorizontalLabel";
        public static const ADD_NEW_VERTICAL_LABEL:String = "addNewVerticalLabel";
        public static const ADD_NEW_UNIT_BAR:String = "addNewUnitBar";
        public static const MULTIPLY_BAR:String = "multiplyBar";
        
        public static const REMOVE_BAR_COMPARISON:String = "removeBarComparison";
        public static const REMOVE_BAR_SEGMENT:String = "removeBarSegment";
        public static const REMOVE_HORIZONTAL_LABEL:String = "removeHorizontalLabel";
        public static const REMOVE_VERTICAL_LABEL:String = "removeVerticalLabel";
        
        public static const RESIZE_BAR_COMPARISON:String = "resizeBarComparison";
        public static const RESIZE_HORIZONTAL_LABEL:String = "resizeHorizontalLabel";
        public static const RESIZE_VERTICAL_LABEL:String = "resizeVerticalLabel";
        
        public static const SPLIT_BAR_SEGMENT:String = "splitBarSegment";
        public static const ADD_LABEL_ON_BAR_SEGMENT:String = "addLabelOnSegment";
        
        /**
         * Fired whenever the player attempts to submit their constructed bar model as
         * an answer.
         * 
         * param: {isCorrect:Boolean, barModel: serialized version of the bar model}
         */
        public static const VALIDATE_BAR_MODEL:String = "validateBarModel";
        public static const UNDO_BAR_MODEL:String = "undoBarModel";
		public static const RESET_BAR_MODEL:String = "resetBarModel";
        
        /**
         * Fired when the player presses on the hint button to request help
         * 
         * param: data blob representing serialized form of hint.
         * includes
         * id:
         * content:
         */
        public static const HINT_REQUESTED_BARMODEL:String = "hintRequestedBarmodel";
        
        /**
         * Fired when the player triggers a hint that is part of the equation modeling portion
         */
        public static const HINT_REQUESTED_EQUATION:String = "hintRequestedEquation";
        
        public static const HINT_BUTTON_HIGHLIGHTED:String = "hintButtonHighlighted";
        
		/**
		 * Returns the AID for the given loggingEventType.
		 * @param	loggingEventType
		 * @return
		 */
		public static function getAidForLogEvent(loggingEventType:String):int
		{
			return instance.m_actionMapping[loggingEventType];
		}
		
		// Instance
		private static var m_instance:AlgebraAdventureLoggingConstants;
		private static function get instance():AlgebraAdventureLoggingConstants
		{
			if (m_instance == null)
			{
				m_instance = new AlgebraAdventureLoggingConstants();
			}
			return m_instance;
		}
		
		// State
		private var m_actionMapping:Dictionary;
		
		public function AlgebraAdventureLoggingConstants()
		{
			// Build action mapping
			m_actionMapping = new Dictionary();
			m_actionMapping[PHRASE_PICKUP_EVENT]          = 1;
			m_actionMapping[PHRASE_DROP_EVENT]            = 2;
			m_actionMapping[EXPRESSION_PICKUP_EVENT]      = 3;
			m_actionMapping[EXPRESSION_DROP_EVENT]        = 4;
			m_actionMapping[VALIDATE_EQUATION_MODEL]       = 5;
			m_actionMapping[EXPRESSION_FOUND_EVENT]       = 6;
			m_actionMapping[ALL_EXPRESSIONS_FOUND_EVENT]  = 7;
			m_actionMapping[NEGATE_EXPRESSION_EVENT]      = 8;
            m_actionMapping[EQUATION_CHANGED_EVENT]       = 9;
            m_actionMapping[BUTTON_PRESSED_EVENT]         = 10;
            m_actionMapping[LEVEL_FINISHED_EVENT]         = 11;
            m_actionMapping[EQUALS_CLICKED_EVENT]         = 12;
            m_actionMapping[TUTORIAL_PROGRESS_EVENT]      = 13;
            m_actionMapping[UNDO_EQUATION]    = 14;
			m_actionMapping[RESET_EQUATION]   = 16;
            
            m_actionMapping[ADD_NEW_BAR] = 17;
            m_actionMapping[ADD_NEW_BAR_COMPARISON] = 18;
            m_actionMapping[ADD_NEW_BAR_SEGMENT] = 19;
            m_actionMapping[ADD_NEW_HORIZONTAL_LABEL] = 20;
            m_actionMapping[ADD_NEW_VERTICAL_LABEL] = 21;
            m_actionMapping[ADD_NEW_UNIT_BAR] = 22;
            
            m_actionMapping[REMOVE_BAR_COMPARISON] = 23;
            m_actionMapping[REMOVE_BAR_SEGMENT] = 24;
            m_actionMapping[REMOVE_HORIZONTAL_LABEL] = 25;
            m_actionMapping[REMOVE_VERTICAL_LABEL] = 26;
            
            m_actionMapping[RESIZE_BAR_COMPARISON] = 27;
            m_actionMapping[RESIZE_HORIZONTAL_LABEL] = 28;
            m_actionMapping[RESIZE_VERTICAL_LABEL] = 29;
            m_actionMapping[SPLIT_BAR_SEGMENT] = 30;
            m_actionMapping[VALIDATE_BAR_MODEL] = 31;
            m_actionMapping[UNDO_BAR_MODEL] = 32;
            
            m_actionMapping[HINT_REQUESTED_BARMODEL] = 33;
            m_actionMapping[ADD_LABEL_ON_BAR_SEGMENT] = 34;
            m_actionMapping[MULTIPLY_BAR] = 35;
            m_actionMapping[HINT_REQUESTED_EQUATION] = 36;
            m_actionMapping[RESET_BAR_MODEL] = 37;
            m_actionMapping[HINT_BUTTON_HIGHLIGHTED] = 38;
		}
	}

}