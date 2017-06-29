package wordproblem.engine.text.model;


import wordproblem.engine.constants.Alignment;

/**
 * Base class used to construct a DOM-like tree that represents the markup of the level's text
 * content.
 */
class DocumentNode
{
    /**
     * Child nodes, only valid for nodes that are composite like a div or paragraph.
     * For terminal nodes like images or text this is always empty.
     */
    public var children : Array<DocumentNode>;
    
    /**
     * The dirty flags are true whenever one of the properties of the node is altered.
     * Associated views will need to refresh themselves within some update loop.
     */
    public var visibleDirty : Bool;
    public var backgroundColorDirty : Bool;
    public var textDecorationDirty : Bool;
    
    /**
     * Flag to indicate whether or not the contents of this node are draggable.
     * By default it is true
     * 
     * Selectability of a node is an inherited attribute, meaning that if the level xml
     * does not explicitly define a value for an element, it will inherit it from its
     * parent. I.e. this is to make it possible for a situation where a paragraph is
     * not selectable but a span inside of it is.
     */
    private var selectable : Bool;
    
    /**
     * The unique identifier assigned to this node, it is set in the markup if the user
     * need to be able to fetch this exact part of the document.
     * 
     * Null if no id was assigned
     */
    public var id : String;
    
    /**
     * A list of class names, it is set in the markup if the user need to reference a collection
     * of documents parts.
     */
    public var classes : Array<String>;
    
    /**
     * Determine whether this node should be visible
     * 
     * Hidden items are always not selectable
     */
    private var visible : Bool;
    
    /**
     * The maximum width allowed for the component. 
     * 
     * By default width will be determined automatically
     * For images this means it will span the original image
     * width and for text it will span as large an area as defined by the root document
     */
    public var width : Float;
    
    /**
     * Maximum height allowed for the component.
     * 
     * Set a restricted height is only useful if we have a background image that we want
     * to have at a fixed size.
     */
    public var height : Float;
    
    public var x : Float = 0;
    public var y : Float = 0;
    
    /**
     * Float attribute is mainly to get somewhat intelligent text wrapping to work
     * Only has an effect when using relative layout
     */
    public var float : String = Alignment.NONE;
    public var paddingTop : Float = 0;
    public var paddingBottom : Float = 0;
    public var paddingLeft : Float = 0;
    public var paddingRight : Float = 0;
    
    /**
     * The static background image to paste at the bottom layer
     * of the node. If null then no image should be used.
     * 
     * Look at the comments in wordproblem.engine.text.TextParserUtil to find the format
     * of this object.
     */
    public var backgroundImage : Dynamic;
    
    /**
     * The 9 slice rectangle for the background image. The ordering is
     * paddings for top, right, bottom, left
     */
    public var background9Slice : Array<Int>;
    
    /**
     * A uniform color to apply behind this nodes total content area
     * If null or transparent then do not use a color
     */
    private var backgroundColor : String;
    
    /**
     * Apply visual change to text like linethrough or underline
     * If null text is unmodified.
     */
    private var m_textDecoration : String;
    
    /**
     * The desired color of any text elements represented by this node.
     * Children elements will inherit from this if not set in some other area
     */
    public var fontColor : Int = 0xFFFFFF;
    
    /**
     * The desired font size of any text elements represented by this node.
     * Children elements will inherit from this if not set in some other area.
     */
    public var fontSize : Int = 12;
    
    /**
     * The desired font to use on text element within this node.
     * Children elements will inherit from this if not set elsewhere.
     */
    public var fontName : String = "Verdana";
    
    /**
     * Type name of the node (perhaps redundant with the class type?)
     */
    private var m_tagName : String;
    
    /**
     * In our current implementation, certain attributes can be defined directly in the xml
     * or be added later via a css-like style object.
     * 
     * If defined directly in the xml, that node should always keep that value unless directly
     * overriden by a matching css. THere should be no implicit inheritence of that property.
     * For example text in a span should by default match the text style defined in the enclosing
     * paragraph.
     */
    private var m_shouldInheritProperty : Dynamic;
    
    public function new(tagName : String)
    {
        m_tagName = tagName;
        m_shouldInheritProperty = new Dynamic();
        this.id = null;
        this.classes = null;
        this.children = new Array<DocumentNode>();
        this.selectable = false;
        this.visible = true;
        this.backgroundColor = null;
        
        this.width = -1;
        this.height = -1;
    }
    
    public function getShouldInheritProperty(propertyName : String) : Bool
    {
        var shouldInherit : Bool = true;
        if (m_shouldInheritProperty.exists(propertyName)) 
        {
            shouldInherit = Reflect.field(m_shouldInheritProperty, propertyName);
        }
        
        return shouldInherit;
    }
    
    public function setShouldInheritProperty(propertyName : String, value : Bool) : Void
    {
        Reflect.setField(m_shouldInheritProperty, propertyName, value);
    }
    
    public function setIsVisible(value : Bool) : Void
    {
        this.visibleDirty = true;
        this.visible = value;
    }
    
    public function getIsVisible() : Bool
    {
        return this.visible;
    }
    
    public function setBackgroundColor(value : String) : Void
    {
        this.backgroundColorDirty = true;
        this.backgroundColor = value;
    }
    
    public function getBackgroundColor() : String
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
    public function setTextDecoration(value : String) : Void
    {
        this.textDecorationDirty = true;
        m_textDecoration = value;
    }
    
    public function getTextDecoration() : String
    {
        return m_textDecoration;
    }
    
    /**
     *
     * @param propagateToChildren
     *      If true, all children node should take the same selectable value
     */
    public function setSelectable(value : Bool, propagateToChildren : Bool = false) : Void
    {
        this.selectable = value;
        if (propagateToChildren && this.children.length > 0) 
        {
            for (childNode/* AS3HX WARNING could not determine type for var: childNode exp: EField(EIdent(this),children) type: null */ in this.children)
            {
                childNode.setSelectable(value, propagateToChildren);
            }
        }
    }
    
    public function getSelectable() : Bool
    {
        return this.selectable;
    }
    
    public function getTagName() : String
    {
        return m_tagName;
    }
    
    /**
     * A css style selector name
     * 
     * A '#' prefix is used for ids
     * A '.' prefix is used for classes
     */
    public function getMatchesSelector(selectorName : String) : Bool
    {
        var matchesSelector : Bool = false;
        
        var isClassSelector : Bool = (selectorName.charAt(0) == ".");
        if (isClassSelector && classes != null) 
        {
            for (className/* AS3HX WARNING could not determine type for var: className exp: EField(EIdent(this),classes) type: null */ in this.classes)
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
            var isIdSelector : Bool = (selectorName.charAt(0) == "#");
            matchesSelector = ((isIdSelector)) ? 
                    (selectorName == ("#" + this.id)) : (selectorName == m_tagName);
        }
        
        return matchesSelector;
    }
    
    
    /** Return the problem text in this document
     *   
     */
    public function getText() : String
    {
        var txt : String = "";
        for (i in 0...children.length){
            txt += children[i].getText();
        }
        return txt;
    }
}
