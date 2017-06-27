package wordproblem.engine.expression
{
    /**
     * A simple struct storing rendering information about a single term value.
     * Contains the necessary information to properly draw the card representing that
     * term.
     * 
     * Note that 'a' and '-a' would be two separate objects
     */
	public class SymbolData
	{
        /**
         * A unique identifier for a symbol in a given level.
         */
		public var value:String;
        
        /**
         * Used for player readable identification of a term in various ui
         * screens.
         */
		public var name:String;
        
        /**
         * The abbreviated name to display on top of cards.
         * Can just be the same as the regular name in the case of numeric symbols
         */
        public var abbreviatedName:String;
        
        /**
         * The name of the texture for the symbol to be pasted on top.
         * 
         * Can be null if we do not want the symbol to be represented by any icon
         */
        public var symbolTextureName:String;
        
        /**
         * The color or tint to apply to the symbol (used to tint the operator textures,
         * like wanting the add symbol to be black)
         */
        private var m_symbolTextureColor:uint;
        
        /**
         * Should the symbol texture get a tint applied to it.
         */
        private var m_useSymbolTextureColor:Boolean;
        
        /**
         * The name of the background texture, symbols can all have different
         * shapes if specified.
         * 
         * Can be null if we do not want the symbol to have any background
         */
        public var backgroundTextureName:String;
        
        /**
         * If null use default font
         */
        public var fontName:String;
        
        /**
         * If null use default color
         */
        public var fontColor:uint;
        
        /**
         * If null use default size
         */
        public var fontSize:int;
        
        /**
         * The color to apply to the background of the card
         */
        public var backgroundColor:uint;
		
        /**
         * Used only for the bar model. If true then all bar segments created to represent this
         * term should use a specific color
         */
        private var m_useCustomBarColor:Boolean;
        
        /**
         * Specific color to apply to bar segments created from this symbol value
         */
        private var m_customBarColor:uint;
        
		public function SymbolData(uid:String, 
                                   name:String,
                                   abbreviatedName:String,
                                   symbolTextureName:String,
                                   backgroundTextureName:String,
                                   backgroundColor:uint,
                                   fontName:String)
        {
            this.value = uid;
            this.name = name;
            this.abbreviatedName = abbreviatedName;
            this.symbolTextureName = symbolTextureName;
            this.backgroundTextureName = backgroundTextureName;
            this.backgroundColor = backgroundColor;
            this.fontName = fontName;
            
            m_useSymbolTextureColor = false;
            m_symbolTextureColor = 0;
            m_useCustomBarColor = false;
            m_customBarColor = 0;
		}
        
        /**
         * Get whether the symbol should be using a specific bar color
         */
        public function get useCustomBarColor():Boolean
        {
            return m_useCustomBarColor;
        }
        
        public function set useCustomBarColor(value:Boolean):void
        {
            m_useCustomBarColor = value;
        }
        
        public function get customBarColor():uint
        {
            return m_customBarColor;
        }
        
        public function set customBarColor(value:uint):void
        {
            m_customBarColor = value;
            m_useCustomBarColor = true;
        }
        
        /**
         * Get whether the symbol should get a color applied to it
         */
        public function get useSymbolTextureColor():Boolean
        {
            return m_useSymbolTextureColor;
        }
        
        public function get symbolTextureColor():uint
        {
            return m_symbolTextureColor;
        }
        
        public function set symbolTextureColor(value:uint):void
        {
            m_symbolTextureColor = value;
            m_useSymbolTextureColor = true;
        }
        
        public function clone():SymbolData
        {
            var clone:SymbolData = new SymbolData(this.value,
                this.name,
                this.abbreviatedName,
                this.symbolTextureName,
                this.backgroundTextureName,
                this.backgroundColor,
                this.fontName
                );
            clone.fontColor = this.fontColor;
            clone.fontSize = this.fontSize;
            
            if (clone.useSymbolTextureColor)
            {
                clone.symbolTextureColor = this.symbolTextureColor;
            }
            
            if (clone.useCustomBarColor)
            {
                clone.customBarColor = this.customBarColor;
            }
            return clone;
        }
	}
}