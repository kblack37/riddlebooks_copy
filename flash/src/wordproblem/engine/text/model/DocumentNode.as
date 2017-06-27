package wordproblem.engine.text.model
{
    import wordproblem.engine.constants.Alignment;
    
    /**
     * Base class used to construct a DOM-like tree that represents the markup of the level's text
     * content.
     */
    public class DocumentNode
    {        
        /**
         * Child nodes, only valid for nodes that are composite like a div or paragraph.
         * For terminal nodes like images or text this is always empty.
         */
        public var children:Vector.<DocumentNode>;
        
        /**
         * The dirty flags are true whenever one of the properties of the node is altered.
         * Associated views will need to refresh themselves within some update loop.
         */
        public var visibleDirty:Boolean;
        public var backgroundColorDirty:Boolean;
        public var textDecorationDirty:Boolean;
        
        /**
         * Flag to indicate whether or not the contents of this node are draggable.
         * By default it is true
         * 
         * Selectability of a node is an inherited attribute, meaning that if the level xml
         * does not explicitly define a value for an element, it will inherit it from its
         * parent. I.e. this is to make it possible for a situation where a paragraph is
         * not selectable but a span inside of it is.
         */
        private var selectable:Boolean;
        
        /**
         * The unique identifier assigned to this node, it is set in the markup if the user
         * need to be able to fetch this exact part of the document.
         * 
         * Null if no id was assigned
         */
        public var id:String;
        
        /**
         * A list of class names, it is set in the markup if the user need to reference a collection
         * of documents parts.
         */
        public var classes:Vector.<String>;
        
        /**
         * Determine whether this node should be visible
         * 
         * Hidden items are always not selectable
         */
        private var visible:Boolean;
        
        /**
         * The maximum width allowed for the component. 
         * 
         * By default width will be determined automatically
         * For images this means it will span the original image
         * width and for text it will span as large an area as defined by the root document
         */
        public var width:Number;
        
        /**
         * Maximum height allowed for the component.
         * 
         * Set a restricted height is only useful if we have a background image that we want
         * to have at a fixed size.
         */
        public var height:Number;
        
        public var x:Number = 0;
        public var y:Number = 0;
        
        /**
         * Float attribute is mainly to get somewhat intelligent text wrapping to work
         * Only has an effect when using relative layout
         */
        public var float:String = Alignment.NONE;
        public var paddingTop:Number = 0;
        public var paddingBottom:Number = 0;
        public var paddingLeft:Number = 0;
        public var paddingRight:Number = 0;
        
        /**
         * The static background image to paste at the bottom layer
         * of the node. If null then no image should be used.
         * 
         * Look at the comments in wordproblem.engine.text.TextParserUtil to find the format
         * of this object.
         */
        public var backgroundImage:Object;
        
        /**
         * The 9 slice rectangle for the background image. The ordering is
         * paddings for top, right, bottom, left
         */
        public var background9Slice:Vector.<int>;
        
        /**
         * A uniform color to apply behind this nodes total content area
         * If null or transparent then do not use a color
         */
        private var backgroundColor:String;
        
        /**
         * Apply visual change to text like linethrough or underline
         * If null text is unmodified.
         */
        private var m_textDecoration:String;
        
        /**
         * The desired color of any text elements represented by this node.
         * Children elements will inherit from this if not set in some other area
         */
        public var fontColor:uint = 0xFFFFFF;
        
        /**
         * The desired font size of any text elements represented by this node.
         * Children elements will inherit from this if not set in some other area.
         */
        public var fontSize:int = 12;
        
        /**
         * The desired font to use on text element within this node.
         * Children elements will inherit from this if not set elsewhere.
         */
        public var fontName:String = "Verdana";
        
        /**
         * Type name of the node (perhaps redundant with the class type?)
         */
        private var m_tagName:String;
        
        /**
         * In our current implementation, certain attributes can be defined directly in the xml
         * or be added later via a css-like style object.
         * 
         * If defined directly in the xml, that node should always keep that value unless directly
         * overriden by a matching css. THere should be no implicit inheritence of that property.
         * For example text in a span should by default match the text style defined in the enclosing
         * paragraph.
         */
        protected var m_shouldInheritProperty:Object;
        
        public function DocumentNode(tagName:String)
        {
            m_tagName = tagName;
            m_shouldInheritProperty = new Object();
            this.id = null;
            this.classes = null;
            this.children = new Vector.<DocumentNode>();
            this.selectable = false;
            this.visible = true;
            this.backgroundColor = null;
            
            this.width = -1;
            this.height = -1;
        }
        
        public function getShouldInheritProperty(propertyName:String):Boolean
        {
            var shouldInherit:Boolean = true;
            if (m_shouldInheritProperty.hasOwnProperty(propertyName))
            {
                shouldInherit = m_shouldInheritProperty[propertyName];
            }
            
            return shouldInherit;
        }
        
        public function setShouldInheritProperty(propertyName:String, value:Boolean):void
        {
            m_shouldInheritProperty[propertyName] = value;
        }

        public function setIsVisible(value:Boolean):void
        {
            this.visibleDirty = true;
            this.visible = value;
        }
        
        public function getIsVisible():Boolean
        {
            return this.visible;
        }
        
        public function setBackgroundColor(value:String):void
        {
            this.backgroundColorDirty = true;
            this.backgroundColor = value;
        }
        
        public function getBackgroundColor():String
        {
            return this.backgroundColor;
        }
        
        /**
         * Similar to the css 'text-decoration' property this is a way to specify minor modifications to
         * how the text appears. Supported Values:
         * line-through - draw a line going through the middle of the text
         * 
         * @param value
         *      If null no text decorations should be applied
         */
        public function setTextDecoration(value:String):void
        {
            this.textDecorationDirty = true;
            m_textDecoration = value;
        }
        
        public function getTextDecoration():String
        {
            return m_textDecoration;
        }
        
        /**
         *
         * @param propagateToChildren
         *      If true, all children node should take the same selectable value
         */
        public function setSelectable(value:Boolean, propagateToChildren:Boolean=false):void
        {
            this.selectable = value;
            if (propagateToChildren && this.children.length > 0)
            {
                for each (var childNode:DocumentNode in this.children)
                {
                    childNode.setSelectable(value, propagateToChildren);
                }
            }
        }
        
        public function getSelectable():Boolean
        {
            return this.selectable;
        }
        
        public function getTagName():String
        {
            return m_tagName;
        }
        
        /**
         * A css style selector name
         * 
         * A '#' prefix is used for ids
         * A '.' prefix is used for classes
         */
        public function getMatchesSelector(selectorName:String):Boolean
        {
            var matchesSelector:Boolean = false;
            
            const isClassSelector:Boolean = (selectorName.charAt(0) == ".");
            if (isClassSelector && classes != null)
            {
                for each (var className:String in this.classes)
                {
                    if ("." + className == selectorName)
                    {
                        matchesSelector = true;
                        break;
                    }
                }
            }
            else
            {
                const isIdSelector:Boolean = (selectorName.charAt(0) == "#");
                matchesSelector = (isIdSelector) ? 
                    (selectorName == ("#" + this.id)) : (selectorName == m_tagName);
            }
            
            return matchesSelector;
        }

        
        /** Return the problem text in this document
         *   
         */
        public function getText():String
        {
            var txt:String = "";            
            for (var i:int = 0; i < children.length; i++) {
                txt += children[i].getText();
            }            
            return txt;
        }
    }
}