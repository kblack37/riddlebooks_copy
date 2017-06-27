package wordproblem.engine.level
{
    /**
     * Default attributes used to create a card, this only occurs if a variable or
     * number did not have it's properties already set for it in the level definition
     */
    public class CardAttributes
    {
        public var defaultPositiveCardBgId:String;
        public var defaultNegativeCardBgId:String;
        
        public var defaultPositiveCardColor:uint;
        public var defaultNegativeCardColor:uint;
        
        public var defaultPositiveTextColor:uint;
        public var defaultNegativeTextColor:uint;
        
        public var defaultFontSize:uint;
        public var defaultFontName:String;
        
        public function CardAttributes(defaultPositiveCardBgId:String,
                                       defaultPositiveCardColor:uint,
                                       defaultPositiveTextColor:uint,
                                       defaultNegativeCardBgId:String, 
                                       defaultNegativeCardColor:uint, 
                                       defaultNegativeTextColor:uint, 
                                       defaultFontSize:uint, 
                                       defaultFontName:String)
        {
            this.defaultPositiveCardBgId = defaultPositiveCardBgId;
            this.defaultPositiveCardColor = defaultPositiveCardColor;
            this.defaultPositiveTextColor = defaultPositiveTextColor;
            this.defaultNegativeCardBgId = defaultNegativeCardBgId;
            this.defaultNegativeCardColor = defaultNegativeCardColor;
            this.defaultNegativeTextColor = defaultNegativeTextColor;
            this.defaultFontSize = defaultFontSize;
            this.defaultFontName = defaultFontName;
        }
        
        public static const DEFAULT_CARD_ATTRIBUTES:CardAttributes = new CardAttributes(
            "card_background_square", 0xFFFFFF, 0x000000,
            "card_background_square_neg", 0xFFFFFF, 0xFFFFFF,
            22, "Verdana");
    }
}