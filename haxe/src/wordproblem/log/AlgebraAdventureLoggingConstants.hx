package wordproblem.log;

import cgs.server.logging.GameServerData;
import cgs.server.logging.IGameServerData.SkeyHashVersion;

/**
	 * ...
	 * @author Rich
	 */
class AlgebraAdventureLoggingConstants
{
    private static var instance(get, never) : AlgebraAdventureLoggingConstants;

    // Game information
    public static inline var SKEY : String = "4047346551f969e5c329dd2eececbcd8";
	// TODO: uncomment once cgs library is finished
    public static var SKEY_HASH : SkeyHashVersion = SKEY_HASH; //GameServerData.skeyHashVersion;
    public static inline var GAME_NAME : String = "wordproblems";
    public static inline var GAME_ID : Int = 17;
    
    // Action Events
    public static inline var PHRASE_PICKUP_EVENT : String = "phrasePickup_logActionEvent";
    public static inline var PHRASE_DROP_EVENT : String = "phraseDrop_logActionEvent";
    public static inline var EXPRESSION_PICKUP_EVENT : String = "expressionPickup_logActionEvent";
    public static inline var EXPRESSION_DROP_EVENT : String = "expressionDrop_logActionEvent";
    
    /**
     * Pressed exit button before level was completed
     */
    public static inline var EXIT_BEFORE_COMPLETION : String = "exit_before_complete";
    
    /**
     * Pressed skip button
     */
    public static inline var SKIP : String = "skip";
    
    /**
     * Fired when the player attempts to submit their constructed equation model as an answer
     * 
     * param: {isCorrect:Boolean if modeled equation was correct, 
     * setComplete:Boolean if all equation in a goal set were complete, 
     * equation: string version of the equation submitted,
     * goalEquation: string version of the equation they were trying to match with
     * }
     */
    public static inline var VALIDATE_EQUATION_MODEL : String = "equationModeled_logActionEvent";
    public static inline var EXPRESSION_FOUND_EVENT : String = "expressionFound_logActionEvent";
    public static inline var ALL_EXPRESSIONS_FOUND_EVENT : String = "allExpressionsFound_logActionEvent";
    public static inline var NEGATE_EXPRESSION_EVENT : String = "negateExpression_logActionEvent";
    public static inline var EQUATION_CHANGED_EVENT : String = "equationChanged_logActionEvent";
    public static inline var BUTTON_PRESSED_EVENT : String = "buttonPressed_logActionEvent";
    public static inline var LEVEL_FINISHED_EVENT : String = "levelFinished_logActionEvent";
    public static inline var EQUALS_CLICKED_EVENT : String = "equalsClicked_logActionEvent";  // IS or EQUALS button clicked  
    public static inline var TUTORIAL_PROGRESS_EVENT : String = "tutorialProgress_logActionEvent";  // Any type of tutorial level progress cause by the player, ie picking a text field or clicking anywhere on the screen when told to  
    public static inline var UNDO_EQUATION : String = "undoEquation";
    public static inline var RESET_EQUATION : String = "resetEquation";
    
    /*
    The bar model actions have a barModel parameter that is a json formatted representation of a bar model
    */
    public static inline var ADD_NEW_BAR : String = "addNewBar";
    public static inline var ADD_NEW_BAR_COMPARISON : String = "addNewBarComparison";
    public static inline var ADD_NEW_BAR_SEGMENT : String = "addNewBarSegment";
    public static inline var ADD_NEW_HORIZONTAL_LABEL : String = "addNewHorizontalLabel";
    public static inline var ADD_NEW_VERTICAL_LABEL : String = "addNewVerticalLabel";
    public static inline var ADD_NEW_UNIT_BAR : String = "addNewUnitBar";
    public static inline var MULTIPLY_BAR : String = "multiplyBar";
    
    public static inline var REMOVE_BAR_COMPARISON : String = "removeBarComparison";
    public static inline var REMOVE_BAR_SEGMENT : String = "removeBarSegment";
    public static inline var REMOVE_HORIZONTAL_LABEL : String = "removeHorizontalLabel";
    public static inline var REMOVE_VERTICAL_LABEL : String = "removeVerticalLabel";
    
    public static inline var RESIZE_BAR_COMPARISON : String = "resizeBarComparison";
    public static inline var RESIZE_HORIZONTAL_LABEL : String = "resizeHorizontalLabel";
    public static inline var RESIZE_VERTICAL_LABEL : String = "resizeVerticalLabel";
    
    public static inline var SPLIT_BAR_SEGMENT : String = "splitBarSegment";
    public static inline var ADD_LABEL_ON_BAR_SEGMENT : String = "addLabelOnSegment";
    
    /**
     * Fired whenever the player attempts to submit their constructed bar model as
     * an answer.
     * 
     * param: {isCorrect:Boolean, barModel: serialized version of the bar model}
     */
    public static inline var VALIDATE_BAR_MODEL : String = "validateBarModel";
    public static inline var UNDO_BAR_MODEL : String = "undoBarModel";
    public static inline var RESET_BAR_MODEL : String = "resetBarModel";
    
    /**
     * Fired when the player presses on the hint button to request help
     * 
     * param: data blob representing serialized form of hint.
     * includes
     * id:
     * content:
     */
    public static inline var HINT_REQUESTED_BARMODEL : String = "hintRequestedBarmodel";
    
    /**
     * Fired when the player triggers a hint that is part of the equation modeling portion
     */
    public static inline var HINT_REQUESTED_EQUATION : String = "hintRequestedEquation";
    
    public static inline var HINT_BUTTON_HIGHLIGHTED : String = "hintButtonHighlighted";
    
    /**
		 * Returns the AID for the given loggingEventType.
		 * @param	loggingEventType
		 * @return
		 */
    public static function getAidForLogEvent(loggingEventType : String) : Int
    {
        return instance.m_actionMapping[loggingEventType];
    }
    
    // Instance
    private static var m_instance : AlgebraAdventureLoggingConstants;
    private static function get_instance() : AlgebraAdventureLoggingConstants
    {
        if (m_instance == null) 
        {
            m_instance = new AlgebraAdventureLoggingConstants();
        }
        return m_instance;
    }
    
    // State
    private var m_actionMapping : Map<String, Int>;
    
    public function new()
    {
        // Build action mapping
        m_actionMapping = new Map<String, Int>();
        Reflect.setField(m_actionMapping, PHRASE_PICKUP_EVENT, 1);
        Reflect.setField(m_actionMapping, PHRASE_DROP_EVENT, 2);
        Reflect.setField(m_actionMapping, EXPRESSION_PICKUP_EVENT, 3);
        Reflect.setField(m_actionMapping, EXPRESSION_DROP_EVENT, 4);
        Reflect.setField(m_actionMapping, VALIDATE_EQUATION_MODEL, 5);
        Reflect.setField(m_actionMapping, EXPRESSION_FOUND_EVENT, 6);
        Reflect.setField(m_actionMapping, ALL_EXPRESSIONS_FOUND_EVENT, 7);
        Reflect.setField(m_actionMapping, NEGATE_EXPRESSION_EVENT, 8);
        Reflect.setField(m_actionMapping, EQUATION_CHANGED_EVENT, 9);
        Reflect.setField(m_actionMapping, BUTTON_PRESSED_EVENT, 10);
        Reflect.setField(m_actionMapping, LEVEL_FINISHED_EVENT, 11);
        Reflect.setField(m_actionMapping, EQUALS_CLICKED_EVENT, 12);
        Reflect.setField(m_actionMapping, TUTORIAL_PROGRESS_EVENT, 13);
        Reflect.setField(m_actionMapping, UNDO_EQUATION, 14);
        Reflect.setField(m_actionMapping, RESET_EQUATION, 16);
        
        Reflect.setField(m_actionMapping, ADD_NEW_BAR, 17);
        Reflect.setField(m_actionMapping, ADD_NEW_BAR_COMPARISON, 18);
        Reflect.setField(m_actionMapping, ADD_NEW_BAR_SEGMENT, 19);
        Reflect.setField(m_actionMapping, ADD_NEW_HORIZONTAL_LABEL, 20);
        Reflect.setField(m_actionMapping, ADD_NEW_VERTICAL_LABEL, 21);
        Reflect.setField(m_actionMapping, ADD_NEW_UNIT_BAR, 22);
        
        Reflect.setField(m_actionMapping, REMOVE_BAR_COMPARISON, 23);
        Reflect.setField(m_actionMapping, REMOVE_BAR_SEGMENT, 24);
        Reflect.setField(m_actionMapping, REMOVE_HORIZONTAL_LABEL, 25);
        Reflect.setField(m_actionMapping, REMOVE_VERTICAL_LABEL, 26);
        
        Reflect.setField(m_actionMapping, RESIZE_BAR_COMPARISON, 27);
        Reflect.setField(m_actionMapping, RESIZE_HORIZONTAL_LABEL, 28);
        Reflect.setField(m_actionMapping, RESIZE_VERTICAL_LABEL, 29);
        Reflect.setField(m_actionMapping, SPLIT_BAR_SEGMENT, 30);
        Reflect.setField(m_actionMapping, VALIDATE_BAR_MODEL, 31);
        Reflect.setField(m_actionMapping, UNDO_BAR_MODEL, 32);
        
        Reflect.setField(m_actionMapping, HINT_REQUESTED_BARMODEL, 33);
        Reflect.setField(m_actionMapping, ADD_LABEL_ON_BAR_SEGMENT, 34);
        Reflect.setField(m_actionMapping, MULTIPLY_BAR, 35);
        Reflect.setField(m_actionMapping, HINT_REQUESTED_EQUATION, 36);
        Reflect.setField(m_actionMapping, RESET_BAR_MODEL, 37);
        Reflect.setField(m_actionMapping, HINT_BUTTON_HIGHLIGHTED, 38);
    }
}

