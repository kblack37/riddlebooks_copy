package wordproblem.engine.level;


/**
 * Default attributes used to create a card, this only occurs if a variable or
 * number did not have it's properties already set for it in the level definition
 */
class CardAttributes
{
    public var defaultPositiveCardBgId : String;
    public var defaultNegativeCardBgId : String;
    
    public var defaultPositiveCardColor : Int;
    public var defaultNegativeCardColor : Int;
    
    public var defaultPositiveTextColor : Int;
    public var defaultNegativeTextColor : Int;
    
    public var defaultFontSize : Int;
    public var defaultFontName : String;
    
    public function new(defaultPositiveCardBgId : String,
            defaultPositiveCardColor : Int,
            defaultPositiveTextColor : Int,
            defaultNegativeCardBgId : String,
            defaultNegativeCardColor : Int,
            defaultNegativeTextColor : Int,
            defaultFontSize : Int,
            defaultFontName : String)
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
    
    public static var DEFAULT_CARD_ATTRIBUTES : CardAttributes = new CardAttributes(
        "assets/card/card_background_square.png", 0xFFFFFF, 0x000000, 
        "assets/card/card_background_square_neg.png", 0xFFFFFF, 0xFFFFFF, 
        22, "Verdana");
}
