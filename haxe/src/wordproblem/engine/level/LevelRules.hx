package wordproblem.engine.level;


import dragonbox.common.util.XString;

/**
 * These are the list of rules to be applied to a single level.
 * 
 * They are modifiable to allow for cases where we want to change rules in the
 * middle of a level. For example we don't want to let the player to be able to multiply
 * terms until they have flipped a card.
 * 
 * Modifying rules as the level is played will need to be done via the script classes.
 */
class LevelRules
{
    /**
     * Can the player perform addition in the equation modeling
     */
    public var allowAddition : Bool;
    
    /**
     * Can the player perform subtraction in the equation modeling
     */
    public var allowSubtract : Bool;
    
    /**
     * Can the player perform multiplication in the equation modeling
     */
    public var allowMultiply : Bool;
    
    /**
     * Can the player perform division in the equation modeling
     */
    public var allowDivide : Bool;
    
    /**
     * When the player is evaluating existing expressions, are they allowed to perform actions
     * that leave an unexpression is an unbalanced and incorrect state.
     */
    public var allowImbalance : Bool;
    
    /**
     * Can the player flip cards in the deck between positive and negative representations
     */
    public var allowCardFlip : Bool;
    
    /**
     * When the player is modeling equations should any numbers be compressed into as 
     * small values as possible.
     */
    public var autoSimplifyNumbers : Bool;
    
    /**
     * Can the player create and remove the parenthesis in an expression.
     * This will determine whether the ui and gestures related to parenthesis will be active in a level.
     */
    public var allowParenthesis : Bool;
    
    /**
     * List of term values that the player is not allowed to remove from the
     * term area
     */
    public var termsNotRemovable : Array<String>;
    
    /**
     * List of term values that the player is not allowed to multiply with
     */
    public var termsNotMultipliable : Array<String>;
    
    /**
     * List of term values that the player is not allowed to divide with
     */
    public var termsNotDivideable : Array<String>;
    
    /**
     * For levels involving bar modeling, should user be allowed to append new bar segments to
     * existing bars.
     */
    public var allowAddNewSegments : Bool;
    
    /**
     * For levels involving bar modeling, should adding a comparison between bars be allowed
     */
    public var allowAddBarComparison : Bool;
    
    /**
     * For levels involving bar modeling, should adding a bar made of several units be allowed
     */
    public var allowAddUnitBar : Bool;
    
    /**
     * For levels involving bar modeling, should adding horizontal bracket labels be allowed 
     */
    public var allowAddHorizontalLabels : Bool;
    
    /**
     * For levels involving bar modeling, should adding vertical labels be allowed
     */
    public var allowAddVerticalLabels : Bool;
    
    /**
     * For levels involving bar modeling, should allow splitting of a bar segment into smaller equal pieces
     */
    public var allowSplitBar : Bool;
    
    /**
     * Should level show the copy modal button
     */
    public var allowCopyBar : Bool;
    
    /**
     * Some levels it might be useful for the user to create custom values
     */
    public var allowCreateCard : Bool;
    
    /**
     * Should user be allowed to change the number of boxes/rows that a bracket structure
     * spans after it has been added
     */
    public var allowResizeBrackets : Bool;
    
    /**
     * Set to true if we want the horizontal brackets to always span the entire length
     * of the segments in a row.
     */
    public var autoResizeHorizontalBrackets : Bool;
    
    /**
     * Set to true if we want the vertical brackets to always span all the rows of bars
     */
    public var autoResizeVerticalBrackets : Bool;
    
    /**
     * The number of rows of bar segments the user can have in their model.
     */
    public var maxBarRowsAllowed : Int;
    
    /**
     * If true, we should make it so that each card is only enabled to be draggable from the text or deck
     * if it does not appear as a name in the bar diagram. That is, it hints that each part can only be used once.
     * Should be false if the parts can be used multiple times, which is necessary for some of the addition and
     * subtraction problems that involve multiple parts.
     */
    public var restrictCardsInBarModel : Bool;
    
    public function new(allowSubtract : Bool,
            allowMultiply : Bool,
            allowDivide : Bool,
            allowCardFlip : Bool,
            autoSimplifyNumbers : Bool,
            allowImbalance : Bool,
            allowParenthesis : Bool)
    {
        this.allowAddition = true;
        this.allowSubtract = allowSubtract;
        this.allowMultiply = allowMultiply;
        this.allowDivide = allowDivide;
        this.allowCardFlip = allowCardFlip;
        this.autoSimplifyNumbers = autoSimplifyNumbers;
        this.allowImbalance = allowImbalance;
        this.allowParenthesis = allowParenthesis;
        this.termsNotRemovable = new Array<String>();
        this.termsNotMultipliable = new Array<String>();
        this.termsNotDivideable = new Array<String>();
        
        // Bar model parameters
        this.allowAddNewSegments = true;
        this.allowAddBarComparison = true;
        this.allowAddUnitBar = true;
        this.allowAddHorizontalLabels = true;
        this.allowAddVerticalLabels = true;
        this.allowSplitBar = true;
        this.allowCopyBar = true;
        this.allowCreateCard = false;
        this.allowResizeBrackets = false;
        this.autoResizeHorizontalBrackets = true;
        this.autoResizeVerticalBrackets = true;
        this.restrictCardsInBarModel = true;
        
        this.maxBarRowsAllowed = 5;
    }
    
    /**
     * Create a level rules object from an xml structure. If the xml does not have a rule specified
     * it fallbacks to the value provided by a default rule set.
     * 
     * @param rulesXml
     * @param defaultRules
     *      The default values to use if a rule is not in the xml. Note if this is null, the xml must
     *      contain every rule.
     */
    public static function createRulesFromXml(rulesXml : FastXML, defaultRules : LevelRules = null) : LevelRules
    {
        // HACK: When default rules are constructed in the first place, it might be annoying to have to re-specify all
        // the rules in the config xml
        if (defaultRules == null) 
        {
            defaultRules = new LevelRules(true, true, true, true, false, true, true);
        }
        
        var allowSubtractElement : FastXML = rulesXml.nodes.elements("allowSubtract")[0];
        var allowSubtract : Bool = getBooleanValueFromElement(allowSubtractElement, defaultRules.allowSubtract);
        
        var allowMultiplyElement : FastXML = rulesXml.nodes.elements("allowMultiply")[0];
        var allowMultiply : Bool = getBooleanValueFromElement(allowMultiplyElement, defaultRules.allowMultiply);
        
        var allowDivideElement : FastXML = rulesXml.nodes.elements("allowDivide")[0];
        var allowDivide : Bool = getBooleanValueFromElement(allowDivideElement, defaultRules.allowDivide);
        
        var allowCardFlipElement : FastXML = rulesXml.nodes.elements("allowCardFlip")[0];
        var allowCardFlip : Bool = getBooleanValueFromElement(allowCardFlipElement, defaultRules.allowCardFlip);
        
        var autoSimplifyNumbersElement : FastXML = rulesXml.nodes.elements("autoSimplifyNumbers")[0];
        var autoSimplifyNumbers : Bool = getBooleanValueFromElement(autoSimplifyNumbersElement, defaultRules.autoSimplifyNumbers);
        
        var allowImbalanceElement : FastXML = (rulesXml.nodes.elements("allowImbalance")[0]);
        var allowImbalance : Bool = getBooleanValueFromElement(allowImbalanceElement, defaultRules.allowImbalance);
        
        var allowParenthesisElement : FastXML = (rulesXml.nodes.elements("allowParenthesis")[0]);
        var allowParenthesis : Bool = getBooleanValueFromElement(allowParenthesisElement, defaultRules.allowParenthesis);
        
        var levelRules : LevelRules = new LevelRules(
        allowSubtract, 
        allowMultiply, 
        allowDivide, 
        allowCardFlip, 
        autoSimplifyNumbers, 
        allowImbalance, 
        allowParenthesis, 
        );
        
        var allowAdditionElement : FastXML = rulesXml.nodes.elements("allowAddition")[0];
        levelRules.allowAddition = getBooleanValueFromElement(allowAdditionElement, defaultRules.allowAddition);
        
        var allowAddNewSegmentsElement : FastXML = rulesXml.nodes.elements("allowAddNewSegments")[0];
        levelRules.allowAddNewSegments = getBooleanValueFromElement(allowAddNewSegmentsElement, defaultRules.allowAddNewSegments);
        
        var allowAddBarComparisonElement : FastXML = rulesXml.nodes.elements("allowAddBarComparison")[0];
        levelRules.allowAddBarComparison = getBooleanValueFromElement(allowAddBarComparisonElement, defaultRules.allowAddBarComparison);
        
        var allowAddUnitBarElement : FastXML = rulesXml.nodes.elements("allowAddUnitBar")[0];
        levelRules.allowAddUnitBar = getBooleanValueFromElement(allowAddUnitBarElement, defaultRules.allowAddUnitBar);
        
        var allowAddHorizontalLabelsElement : FastXML = rulesXml.nodes.elements("allowAddHorizontalLabels")[0];
        levelRules.allowAddHorizontalLabels = getBooleanValueFromElement(allowAddHorizontalLabelsElement, defaultRules.allowAddHorizontalLabels);
        
        var allowAddVerticalLabelsElement : FastXML = rulesXml.nodes.elements("allowAddVerticalLabel")[0];
        levelRules.allowAddVerticalLabels = getBooleanValueFromElement(allowAddVerticalLabelsElement, defaultRules.allowAddVerticalLabels);
        
        var allowCopyBarElement : FastXML = rulesXml.nodes.elements("allowCopyBar")[0];
        levelRules.allowCopyBar = getBooleanValueFromElement(allowCopyBarElement, defaultRules.allowCopyBar);
        
        var allowSplitBarElement : FastXML = rulesXml.nodes.elements("allowSplitBar")[0];
        levelRules.allowSplitBar = getBooleanValueFromElement(allowSplitBarElement, defaultRules.allowSplitBar);
        
        var allowCreateCardElement : FastXML = rulesXml.nodes.elements("allowCreateCard")[0];
        levelRules.allowCreateCard = getBooleanValueFromElement(allowCreateCardElement, defaultRules.allowCreateCard);
        
        var allowResizeBracketsElement : FastXML = rulesXml.nodes.elements("allowResizeBrackets")[0];
        levelRules.allowResizeBrackets = getBooleanValueFromElement(allowResizeBracketsElement, defaultRules.allowResizeBrackets);
        
        var autoResizeHorizontalBracketsElement : FastXML = rulesXml.nodes.elements("autoResizeHorizontalBrackets")[0];
        levelRules.autoResizeHorizontalBrackets = getBooleanValueFromElement(autoResizeHorizontalBracketsElement, defaultRules.autoResizeHorizontalBrackets);
        
        var autoResizeVerticalBracketsElement : FastXML = rulesXml.nodes.elements("autoResizeVerticalBrackets")[0];
        levelRules.autoResizeVerticalBrackets = getBooleanValueFromElement(autoResizeVerticalBracketsElement, defaultRules.autoResizeVerticalBrackets);
        
        var maxBarRowsAllowedElement : FastXML = rulesXml.nodes.elements("maxBarRowsAllowed")[0];
        levelRules.maxBarRowsAllowed = getIntValueFromElement(maxBarRowsAllowedElement, defaultRules.maxBarRowsAllowed);
        
        var restrictCardsElement : FastXML = rulesXml.nodes.elements("restrictCardsInBarModel")[0];
        levelRules.restrictCardsInBarModel = getBooleanValueFromElement(restrictCardsElement, defaultRules.restrictCardsInBarModel);
        
        return levelRules;
    }
    
    private static function getBooleanValueFromElement(element : FastXML, defaultValue : Bool) : Bool
    {
        var value : Bool = defaultValue;
        if (element != null) 
        {
            value = XString.stringToBool(element.att.value);
        }
        return value;
    }
    
    private static function getIntValueFromElement(element : FastXML, defaultValue : Int) : Int
    {
        var value : Int = defaultValue;
        if (element != null) 
        {
            value = parseInt(element.att.value);
            if (!Math.isNaN(value)) 
            {
                value = defaultValue;
            }
        }
        
        return value;
    }
}
