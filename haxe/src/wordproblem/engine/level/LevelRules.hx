package wordproblem.engine.level;


import dragonbox.common.util.XString;
import haxe.xml.Fast;

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
    public static function createRulesFromXml(rulesXml : Fast, defaultRules : LevelRules = null) : LevelRules
    {
        // HACK: When default rules are constructed in the first place, it might be annoying to have to re-specify all
        // the rules in the config xml
        if (defaultRules == null) 
        {
            defaultRules = new LevelRules(true, true, true, true, false, true, true);
        }
        
        var allowSubtractElement : Fast = rulesXml.hasNode.allowSubtract ? rulesXml.node.allowSubtract : null;
        var allowSubtract : Bool = getBooleanValueFromElement(allowSubtractElement, defaultRules.allowSubtract);
        
        var allowMultiplyElement : Fast = rulesXml.hasNode.allowMultiply ? rulesXml.node.allowMultiply : null;
        var allowMultiply : Bool = getBooleanValueFromElement(allowMultiplyElement, defaultRules.allowMultiply);
        
        var allowDivideElement :Fast = rulesXml.hasNode.allowDivide ? rulesXml.node.allowDivide : null;
        var allowDivide : Bool = getBooleanValueFromElement(allowDivideElement, defaultRules.allowDivide);
        
        var allowCardFlipElement : Fast = rulesXml.hasNode.allowCardFlip ? rulesXml.node.allowCardFlip : null;
        var allowCardFlip : Bool = getBooleanValueFromElement(allowCardFlipElement, defaultRules.allowCardFlip);
        
        var autoSimplifyNumbersElement : Fast = rulesXml.hasNode.autoSimplifyNumbers ? rulesXml.node.autoSimplifyNumbers : null;
        var autoSimplifyNumbers : Bool = getBooleanValueFromElement(autoSimplifyNumbersElement, defaultRules.autoSimplifyNumbers);
        
        var allowImbalanceElement : Fast = rulesXml.hasNode.allowImbalance ? rulesXml.node.allowImbalance : null;
        var allowImbalance : Bool = getBooleanValueFromElement(allowImbalanceElement, defaultRules.allowImbalance);
        
        var allowParenthesisElement : Fast = rulesXml.hasNode.allowParenthesis ? rulesXml.node.allowParenthesis : null;
        var allowParenthesis : Bool = getBooleanValueFromElement(allowParenthesisElement, defaultRules.allowParenthesis);
        
        var levelRules : LevelRules = new LevelRules(
        allowSubtract, 
        allowMultiply, 
        allowDivide, 
        allowCardFlip, 
        autoSimplifyNumbers, 
        allowImbalance, 
        allowParenthesis
        );
        
        var allowAdditionElement : Fast = rulesXml.hasNode.allowAddition ? rulesXml.node.allowAddition : null;
        levelRules.allowAddition = getBooleanValueFromElement(allowAdditionElement, defaultRules.allowAddition);
        
        var allowAddNewSegmentsElement : Fast = rulesXml.hasNode.allowAddNewSegments ? rulesXml.node.allowAddNewSegments : null;
        levelRules.allowAddNewSegments = getBooleanValueFromElement(allowAddNewSegmentsElement, defaultRules.allowAddNewSegments);
        
        var allowAddBarComparisonElement : Fast = rulesXml.hasNode.allowAddBarComparison ? rulesXml.node.allowAddBarComparison : null;
        levelRules.allowAddBarComparison = getBooleanValueFromElement(allowAddBarComparisonElement, defaultRules.allowAddBarComparison);
        
        var allowAddUnitBarElement : Fast = rulesXml.hasNode.allowAddUnitBar ? rulesXml.node.allowAddUnitBar : null;
        levelRules.allowAddUnitBar = getBooleanValueFromElement(allowAddUnitBarElement, defaultRules.allowAddUnitBar);
        
        var allowAddHorizontalLabelsElement : Fast = rulesXml.hasNode.allowAddHorizontalLabels ? rulesXml.node.allowAddHorizontalLabels : null;
        levelRules.allowAddHorizontalLabels = getBooleanValueFromElement(allowAddHorizontalLabelsElement, defaultRules.allowAddHorizontalLabels);
        
        var allowAddVerticalLabelsElement : Fast = rulesXml.hasNode.allowAddVerticalLabels ? rulesXml.node.allowAddVerticalLabels : null;
        levelRules.allowAddVerticalLabels = getBooleanValueFromElement(allowAddVerticalLabelsElement, defaultRules.allowAddVerticalLabels);
        
        var allowCopyBarElement : Fast = rulesXml.hasNode.allowCopyBar ? rulesXml.node.allowCopyBar : null;
        levelRules.allowCopyBar = getBooleanValueFromElement(allowCopyBarElement, defaultRules.allowCopyBar);
        
        var allowSplitBarElement : Fast = rulesXml.hasNode.allowSplitBar ? rulesXml.node.allowSplitBar : null;
        levelRules.allowSplitBar = getBooleanValueFromElement(allowSplitBarElement, defaultRules.allowSplitBar);
        
        var allowCreateCardElement : Fast = rulesXml.hasNode.allowCreateCard ? rulesXml.node.allowCreateCard : null;
        levelRules.allowCreateCard = getBooleanValueFromElement(allowCreateCardElement, defaultRules.allowCreateCard);
        
        var allowResizeBracketsElement : Fast = rulesXml.hasNode.allowResizeBrackets ? rulesXml.node.allowResizeBrackets : null;
        levelRules.allowResizeBrackets = getBooleanValueFromElement(allowResizeBracketsElement, defaultRules.allowResizeBrackets);
        
        var autoResizeHorizontalBracketsElement : Fast = rulesXml.hasNode.autoResizeHorizontalBrackets ? rulesXml.node.autoResizeHorizontalBrackets : null;
        levelRules.autoResizeHorizontalBrackets = getBooleanValueFromElement(autoResizeHorizontalBracketsElement, defaultRules.autoResizeHorizontalBrackets);
        
        var autoResizeVerticalBracketsElement : Fast = rulesXml.hasNode.autoResizeVerticalBrackets ? rulesXml.node.autoResizeVerticalBrackets : null;
        levelRules.autoResizeVerticalBrackets = getBooleanValueFromElement(autoResizeVerticalBracketsElement, defaultRules.autoResizeVerticalBrackets);
        
        var maxBarRowsAllowedElement : Fast = rulesXml.hasNode.maxBarRowsAllowed ? rulesXml.node.maxBarRowsAllowed : null;
        levelRules.maxBarRowsAllowed = getIntValueFromElement(maxBarRowsAllowedElement, defaultRules.maxBarRowsAllowed);
        
        var restrictCardsElement : Fast = rulesXml.hasNode.restrictCardsInBarModel ? rulesXml.node.restrictCardsInBarModel : null;
        levelRules.restrictCardsInBarModel = getBooleanValueFromElement(restrictCardsElement, defaultRules.restrictCardsInBarModel);
        
        return levelRules;
    }
    
    private static function getBooleanValueFromElement(element : Fast, defaultValue : Bool) : Bool
    {
        var value : Bool = defaultValue;
        if (element != null) 
        {
            value = XString.stringToBool(element.att.value);
        }
        return value;
    }
    
    private static function getIntValueFromElement(element : Fast, defaultValue : Int) : Int
    {
        var value : Int = defaultValue;
        if (element != null) 
        {
            value = Std.parseInt(element.att.value);
            if (!Math.isNaN(value)) 
            {
                value = defaultValue;
            }
        }
        
        return value;
    }
}
