package wordproblem.engine.component
{
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.ExpressionUtil;
    import dragonbox.common.math.vectorspace.IVectorSpace;
    
    import wordproblem.engine.text.TextParserUtil;

    /**
     * Storage for the information describing the attributes of a widget or ui element in the modeling paragraph
     * game state. Example attributes are dimensions and positioning of the element.
     * 
     * TODO: Some attributes should be described as expressions
     */
    public class WidgetAttributesComponent extends Component
    {
        public static const TYPE_ID:String = "WidgetAttributesComponent";
        
        /**
         * The children widgets contained within this one
         * Null if this is a leaf widget
         */
        public var children:Vector.<WidgetAttributesComponent>;
        
        /**
         * The reference to the parent container of this widget node
         */
        public var parent:WidgetAttributesComponent;
        
        /**
         * The type of the widget bound to this component
         */
        public var widgetType:String;
        
        /**
         * If null, the widget should get the width set by starling
         */
        public var widthRoot:ExpressionNode;
        
        /**
         * If null, the widget should get the height set by starling
         */
        public var heightRoot:ExpressionNode;
        public var xRoot:ExpressionNode;
        public var yRoot:ExpressionNode;
        
        public var viewportWidth:Number;
        public var viewportHeight:Number;
        
        // TODO: Somewhat copying css conventions, the image source string should look like
        // <type>(<data>) 
        // for example: 
        // url(sample_image.png) indicates a dynamically loaded image
        // embed(sample_class_name) indicates an embedded class
        // When it comes time to load the texture for that image, the full string content is unnecessary
        // we just need the stuff in the parens with maybe some other meta data
        // Still have the problem where these image resources have multiple parts to them
        // some struct may be necessary to hold them all
        // {type:<one of url, embed, embed_atlas>, name:<primary name of content used to fetch resource>, extra props}
        // Have some static parser that converts the image string above to the object
        // The object is what is used
        private var m_sourceList:Vector.<Object>;
        
        /**
         * If a widget is not visible then it should not contribute to the layout
         * of other widgets.
         */
        public var visible:Boolean;
        
        /**
         * Extra data
         * Currently only used for the text area, it describes whether the background image should even scroll
         * 
         * Values possible are
         * 'fixed'-No scrolling
         * 'scroll'-Allow scrolling
         */
        // backgroundAttachment:String;
        
        /**
         * Extra data
         * Currently only used for the text area, it describes whether the background image should repeat
         * in the y-direction to fill the view port.
         * 
         * Values possible are
         * 'repeat'-Repeat in along y axis
         * 'no-repeat'-No repeating of the image
         */
        // backgroundRepeat:String;
        
        /**
         * Extra data
         * Currently only used for the text area, it describes whether the text should be allowed to scroll
         */
        // allowScroll:String;
        
        /**
         * Extra data
         * Currently only used for the text area, it describes whether each page of the text area should
         * should be automatically centered in the viewport or appear at the top every time.
         */
        // autoCenterPages:Boolean
        
        /**
         * Extra data
         * Currently used only for buttons, it describes the label that should be put on a button
         */
        //label:String
        
        /**
         * Extra data
         * Currently used only for buttons, these describe button style information
         */
        // fontName:String, fontColor:uint, fontSize:int
        
        /**
         * Extra data
         * Currently used only for buttons, this is how to nine-slice the graphics
         * Comma separated list of values to put in a rectangle
         */
        // nineSlice:String
        
        /**
         * Extra properties that each widget can stuff with customized data
         */
        public var extraData:Object;
        
        public function WidgetAttributesComponent(id:String,
                                                  widgetType:String,
                                                  width:ExpressionNode, 
                                                  height:ExpressionNode, 
                                                  x:ExpressionNode, 
                                                  y:ExpressionNode, 
                                                  viewportWidth:Number, 
                                                  viewportHeight:Number, 
                                                  backgroundSource:String,
                                                  visible:Boolean, 
                                                  extraData:Object)
        {
            super(id, TYPE_ID);

            this.widgetType = widgetType;
            this.widthRoot = width;
            this.heightRoot = height;
            this.xRoot = x;
            this.yRoot = y;
            this.viewportWidth = viewportWidth;
            this.viewportHeight = viewportHeight;
            this.visible = visible;
            this.setResourceSourceList(backgroundSource);
            
            this.extraData = extraData;
        }
        
        /**
         * Return a deep copy of the attributes component
         */
        public function clone(vectorSpace:IVectorSpace):WidgetAttributesComponent
        {
            var sourceResult:String = null;
            const sourceList:Vector.<Object> = m_sourceList;
            var i:int;
            var sourceObject:Object;
            for (i = 0; i < sourceList.length; i++)
            {
                sourceObject = sourceList[i];
                var sourceObjectToString:String = sourceObject.type + "(" + sourceObject.name + ")";
                if (i > 0)
                {
                    sourceResult += "," + sourceObjectToString;   
                }
                else
                {
                    sourceResult = sourceObjectToString;
                }
            }
            
            // Clone custom object properties
            var clonedExtraData:Object = {};
            for (var key:String in this.extraData)
            {
                clonedExtraData[key] = this.extraData[key];
            }
            
            const clone:WidgetAttributesComponent = new WidgetAttributesComponent(
                this.entityId,
                this.widgetType,
                ExpressionUtil.copy(this.widthRoot, vectorSpace),
                ExpressionUtil.copy(this.heightRoot, vectorSpace),
                ExpressionUtil.copy(this.xRoot, vectorSpace),
                ExpressionUtil.copy(this.yRoot, vectorSpace),
                this.viewportWidth,
                this.viewportHeight,
                sourceResult,
                this.visible,
                clonedExtraData
            );

            if (this.children != null)
            {
                const cloneChildren:Vector.<WidgetAttributesComponent> = new Vector.<WidgetAttributesComponent>();
                for (i = 0; i < this.children.length; i++)
                {
                    var childClone:WidgetAttributesComponent = this.children[i].clone(vectorSpace);
                    cloneChildren.push(childClone);
                    
                    childClone.parent = clone;
                }
                clone.children = cloneChildren;
            }
            
            return clone;
        }
        
        /**
         * Get back a list of sources for the resources used by this widget.
         * The usage of a resource at any particular index depends on the widget
         * type. For example a button widget might expect three resources string,
         * the one at zero represents the normal state, while the next ones represent
         * click or inactive states.
         * 
         * @return
         *      List of resource source strings.
         */
        public function getResourceSourceList():Vector.<Object>
        {
            return m_sourceList;
        }
        
        public function setResourceSourceList(source:String):void
        {
            // Parse the new source string into resource objects
            m_sourceList = TextParserUtil.parseResourceSourceString(source)
        }
    }
}