package wordproblem.engine.level
{
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
    public class LevelRules
    {
        /**
         * Can the player perform addition in the equation modeling
         */
        public var allowAddition:Boolean;
        
        /**
         * Can the player perform subtraction in the equation modeling
         */
        public var allowSubtract:Boolean;
        
        /**
         * Can the player perform multiplication in the equation modeling
         */
        public var allowMultiply:Boolean;
        
        /**
         * Can the player perform division in the equation modeling
         */
        public var allowDivide:Boolean;
        
        /**
         * When the player is evaluating existing expressions, are they allowed to perform actions
         * that leave an unexpression is an unbalanced and incorrect state.
         */
        public var allowImbalance:Boolean;
        
        /**
         * Can the player flip cards in the deck between positive and negative representations
         */
        public var allowCardFlip:Boolean;
        
        /**
         * When the player is modeling equations should any numbers be compressed into as 
         * small values as possible.
         */
        public var autoSimplifyNumbers:Boolean;
        
        /**
         * Can the player create and remove the parenthesis in an expression.
         * This will determine whether the ui and gestures related to parenthesis will be active in a level.
         */
        public var allowParenthesis:Boolean;
        
        /**
         * List of term values that the player is not allowed to remove from the
         * term area
         */
        public var termsNotRemovable:Vector.<String>;
        
        /**
         * List of term values that the player is not allowed to multiply with
         */
        public var termsNotMultipliable:Vector.<String>;
        
        /**
         * List of term values that the player is not allowed to divide with
         */
        public var termsNotDivideable:Vector.<String>;
        
        /**
         * For levels involving bar modeling, should user be allowed to append new bar segments to
         * existing bars.
         */
        public var allowAddNewSegments:Boolean;
        
        /**
         * For levels involving bar modeling, should adding a comparison between bars be allowed
         */
        public var allowAddBarComparison:Boolean;
        
        /**
         * For levels involving bar modeling, should adding a bar made of several units be allowed
         */
        public var allowAddUnitBar:Boolean;
        
        /**
         * For levels involving bar modeling, should adding horizontal bracket labels be allowed 
         */
        public var allowAddHorizontalLabels:Boolean;
        
        /**
         * For levels involving bar modeling, should adding vertical labels be allowed
         */
        public var allowAddVerticalLabels:Boolean;
        
        /**
         * For levels involving bar modeling, should allow splitting of a bar segment into smaller equal pieces
         */
        public var allowSplitBar:Boolean;
        
        /**
         * Should level show the copy modal button
         */
        public var allowCopyBar:Boolean;
        
        /**
         * Some levels it might be useful for the user to create custom values
         */
        public var allowCreateCard:Boolean;
        
        /**
         * Should user be allowed to change the number of boxes/rows that a bracket structure
         * spans after it has been added
         */
        public var allowResizeBrackets:Boolean;
        
        /**
         * Set to true if we want the horizontal brackets to always span the entire length
         * of the segments in a row.
         */
        public var autoResizeHorizontalBrackets:Boolean;
        
        /**
         * Set to true if we want the vertical brackets to always span all the rows of bars
         */
        public var autoResizeVerticalBrackets:Boolean;
        
        /**
         * The number of rows of bar segments the user can have in their model.
         */
        public var maxBarRowsAllowed:int;
        
        /**
         * If true, we should make it so that each card is only enabled to be draggable from the text or deck
         * if it does not appear as a name in the bar diagram. That is, it hints that each part can only be used once.
         * Should be false if the parts can be used multiple times, which is necessary for some of the addition and
         * subtraction problems that involve multiple parts.
         */
        public var restrictCardsInBarModel:Boolean;
        
        public function LevelRules(allowSubtract:Boolean,
                                   allowMultiply:Boolean,
                                   allowDivide:Boolean,
                                   allowCardFlip:Boolean, 
                                   autoSimplifyNumbers:Boolean, 
                                   allowImbalance:Boolean, 
                                   allowParenthesis:Boolean)
        {
            this.allowAddition = true;
            this.allowSubtract = allowSubtract;
            this.allowMultiply = allowMultiply;
            this.allowDivide = allowDivide;
            this.allowCardFlip = allowCardFlip;
            this.autoSimplifyNumbers = autoSimplifyNumbers;
            this.allowImbalance = allowImbalance;
            this.allowParenthesis = allowParenthesis;
            this.termsNotRemovable = new Vector.<String>();
            this.termsNotMultipliable = new Vector.<String>();
            this.termsNotDivideable = new Vector.<String>();
            
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
        public static function createRulesFromXml(rulesXml:XML, defaultRules:LevelRules=null):LevelRules
        {
            // HACK: When default rules are constructed in the first place, it might be annoying to have to re-specify all
            // the rules in the config xml
            if (defaultRules == null)
            {
                defaultRules = new LevelRules(true, true, true, true, false, true, true);
            }
            
            var allowSubtractElement:XML = rulesXml.elements("allowSubtract")[0];
            var allowSubtract:Boolean = getBooleanValueFromElement(allowSubtractElement, defaultRules.allowSubtract);
            
            var allowMultiplyElement:XML = rulesXml.elements("allowMultiply")[0];
            var allowMultiply:Boolean = getBooleanValueFromElement(allowMultiplyElement, defaultRules.allowMultiply);
            
            var allowDivideElement:XML = rulesXml.elements("allowDivide")[0];
            var allowDivide:Boolean = getBooleanValueFromElement(allowDivideElement, defaultRules.allowDivide);
            
            var allowCardFlipElement:XML = rulesXml.elements("allowCardFlip")[0];
            var allowCardFlip:Boolean = getBooleanValueFromElement(allowCardFlipElement, defaultRules.allowCardFlip);
            
            var autoSimplifyNumbersElement:XML = rulesXml.elements("autoSimplifyNumbers")[0];
            var autoSimplifyNumbers:Boolean = getBooleanValueFromElement(autoSimplifyNumbersElement, defaultRules.autoSimplifyNumbers);
            
            var allowImbalanceElement:XML = (rulesXml.elements("allowImbalance")[0]);
            var allowImbalance:Boolean = getBooleanValueFromElement(allowImbalanceElement, defaultRules.allowImbalance);
            
            var allowParenthesisElement:XML = (rulesXml.elements("allowParenthesis")[0]);
            var allowParenthesis:Boolean = getBooleanValueFromElement(allowParenthesisElement, defaultRules.allowParenthesis);
            
            var levelRules:LevelRules = new LevelRules(
                allowSubtract,
                allowMultiply,
                allowDivide,
                allowCardFlip,
                autoSimplifyNumbers,
                allowImbalance,
                allowParenthesis
            );
            
            var allowAdditionElement:XML = rulesXml.elements("allowAddition")[0];
            levelRules.allowAddition = getBooleanValueFromElement(allowAdditionElement, defaultRules.allowAddition);
            
            var allowAddNewSegmentsElement:XML = rulesXml.elements("allowAddNewSegments")[0];
            levelRules.allowAddNewSegments = getBooleanValueFromElement(allowAddNewSegmentsElement, defaultRules.allowAddNewSegments);
            
            var allowAddBarComparisonElement:XML = rulesXml.elements("allowAddBarComparison")[0];
            levelRules.allowAddBarComparison = getBooleanValueFromElement(allowAddBarComparisonElement, defaultRules.allowAddBarComparison);
            
            var allowAddUnitBarElement:XML = rulesXml.elements("allowAddUnitBar")[0];
            levelRules.allowAddUnitBar = getBooleanValueFromElement(allowAddUnitBarElement, defaultRules.allowAddUnitBar);
            
            var allowAddHorizontalLabelsElement:XML = rulesXml.elements("allowAddHorizontalLabels")[0];
            levelRules.allowAddHorizontalLabels = getBooleanValueFromElement(allowAddHorizontalLabelsElement, defaultRules.allowAddHorizontalLabels);
            
            var allowAddVerticalLabelsElement:XML = rulesXml.elements("allowAddVerticalLabel")[0];
            levelRules.allowAddVerticalLabels = getBooleanValueFromElement(allowAddVerticalLabelsElement, defaultRules.allowAddVerticalLabels);
            
            var allowCopyBarElement:XML = rulesXml.elements("allowCopyBar")[0];
            levelRules.allowCopyBar = getBooleanValueFromElement(allowCopyBarElement, defaultRules.allowCopyBar);
            
            var allowSplitBarElement:XML = rulesXml.elements("allowSplitBar")[0];
            levelRules.allowSplitBar = getBooleanValueFromElement(allowSplitBarElement, defaultRules.allowSplitBar);
            
            var allowCreateCardElement:XML = rulesXml.elements("allowCreateCard")[0];
            levelRules.allowCreateCard = getBooleanValueFromElement(allowCreateCardElement, defaultRules.allowCreateCard);
            
            var allowResizeBracketsElement:XML = rulesXml.elements("allowResizeBrackets")[0];
            levelRules.allowResizeBrackets = getBooleanValueFromElement(allowResizeBracketsElement, defaultRules.allowResizeBrackets);
            
            var autoResizeHorizontalBracketsElement:XML = rulesXml.elements("autoResizeHorizontalBrackets")[0];
            levelRules.autoResizeHorizontalBrackets = getBooleanValueFromElement(autoResizeHorizontalBracketsElement, defaultRules.autoResizeHorizontalBrackets);
            
            var autoResizeVerticalBracketsElement:XML = rulesXml.elements("autoResizeVerticalBrackets")[0];
            levelRules.autoResizeVerticalBrackets = getBooleanValueFromElement(autoResizeVerticalBracketsElement, defaultRules.autoResizeVerticalBrackets);
            
            var maxBarRowsAllowedElement:XML = rulesXml.elements("maxBarRowsAllowed")[0];
            levelRules.maxBarRowsAllowed = getIntValueFromElement(maxBarRowsAllowedElement, defaultRules.maxBarRowsAllowed);
            
            var restrictCardsElement:XML = rulesXml.elements("restrictCardsInBarModel")[0];
            levelRules.restrictCardsInBarModel = getBooleanValueFromElement(restrictCardsElement, defaultRules.restrictCardsInBarModel);
            
            return levelRules;
        }
        
        private static function getBooleanValueFromElement(element:XML, defaultValue:Boolean):Boolean
        {
            var value:Boolean = defaultValue;
            if (element != null)
            {
                value = XString.stringToBool(element.@value);
            }
            return value;
        }
        
        private static function getIntValueFromElement(element:XML, defaultValue:int):int
        {
            var value:int = defaultValue;
            if (element != null)
            {
                value = parseInt(element.@value);
                if (!isNaN(value))
                {
                    value = defaultValue;
                }
            }
            
            return value;
        }
    }
}