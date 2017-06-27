package wordproblem.engine.barmodel
{
    import wordproblem.engine.barmodel.model.BarComparison;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.barmodel.view.BarModelView;

    /**
     * This is a helper utility class used to draw the various bar model template
     */
    public class BarModelTypeDrawer
    {
        // Max allowable number of equal groups that can compose a single bar
        private const MAX_GROUP_VALUE:int = 30;
        
        // Color palette
        private const PINK:uint = 0xF5749A;
        private const ORANGE:uint = 0xF5A475;
        private const GOLD:uint = 0xDCC565;
        private const GREEN:uint = 0x99E871;
        private const CYAN:uint = 0x66FFFF;
        
        public function BarModelTypeDrawer()
        {
        }
        
        /**
         * The styling object
         * Maps from the elements to another object with properties of how to
         * draw the object (this includes properties like the color or proportion)
         * 
         * An example usage is a script calls this to get default information.
         * It then tweaks some properties before passing it into the draw function
         * 
         */
        public function getStyleObjectForType(type:String, colorMap:Object=null):Object
        {
            var style:Object = {};
            
            // Important: Certain types do not use the 'c' element
            var useCPart:Boolean = true;
            var partIds:Vector.<String> = Vector.<String>(['a', 'b', 'c', '?']);
            if (colorMap == null)
            {
                colorMap = {
                    'a': GOLD,
                    'b': CYAN,
                    'c': GREEN,
                    '?': PINK
                };
            }
            var i:int
            for (i = 0; i< partIds.length; i++)
            {
                var partId:String = partIds[i];
                var partProperties:BarModelTypeDrawerProperties = new BarModelTypeDrawerProperties();
                if (colorMap.hasOwnProperty(partId))
                {
                    partProperties.color = colorMap[partId];
                }
                
                // alias is always just the name of the part initially
                partProperties.alias = partId;
                
                style[partId] = partProperties;
            }
            
            // By default the ? is always just a string since it is a variable in the level
            style['?'].restrictions.type = String;
            
            switch(type)
            {
                case BarModelTypes.TYPE_1A:
                    style['a'].value = "2";
                    style['b'].value = "1";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Some amount";
                    style['b'].restrictions.type = Number;
                    style['b'].desc = "Some amount";
                    style['?'].desc = "Total amount";
                    useCPart = false;
                    break;
                case BarModelTypes.TYPE_1B:
                    style['a'].value = "2";
                    style['b'].value = "3";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Some amount";
                    style['b'].restrictions.type = Number;
                    style['b'].desc = "Total amount";
                    style['?'].desc = "Some amount";
                    useCPart = false;
                    break;
                case BarModelTypes.TYPE_2A:
                    // b must be greater than a
                    style['b'].value = "2";
                    style['b'].restrictions.gt = "a";
                    style['a'].value = "1";
                    style['a'].restrictions.lt = "b";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Smaller amount";
                    style['b'].restrictions.type = Number;
                    style['b'].desc = "Larger amount";
                    style['?'].desc = "Difference";
                    useCPart = false;
                    break;
                case BarModelTypes.TYPE_2B:
                    style['a'].value = "1";
                    style['b'].value = "2";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Some amount";
                    style['b'].restrictions.type = Number;
                    style['b'].desc = "Some amount";
                    style['?'].desc = "Total Amount";
                    useCPart = false;
                    break;
                case BarModelTypes.TYPE_2C:
                    // b must be greater than ?
                    style['b'].value = "2";
                    style['b'].restrictions.gt = "?";
                    style['a'].value = "1";
                    style['?'].restrictions.lt = "b";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Difference";
                    style['b'].restrictions.type = Number;
                    style['b'].desc = "Larger amount";
                    style['?'].desc = "Smaller amount";
                    useCPart = false;
                    break;
                case BarModelTypes.TYPE_2D:
                    // ? must be greater than a
                    style['b'].value = "1";
                    style['a'].value = "1";
                    style['a'].restrictions.lt = "?";
                    style['?'].restrictions.gt = "a";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Smaller amount";
                    style['b'].restrictions.type = Number;
                    style['b'].desc = "Difference";
                    style['?'].desc = "Larger amount";
                    useCPart = false;
                    break;
                case BarModelTypes.TYPE_2E:
                    style['a'].value = "2";
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Some amount";
                    style['b'].restrictions.type = Number;
                    style['b'].desc = "Total amount";
                    style['b'].value = "3";
                    style['?'].desc = "Some amount";
                    useCPart = false;
                    break;
                case BarModelTypes.TYPE_3A:
                    style['b'].value = "8";
                    style['b'].desc = "Total number of parts";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Amount of one part";
                    style['a'].priority = 1;
                    style['b'].restrictions.type = int;
                    style['b'].restrictions.min = 2;
                    style['b'].restrictions.max = MAX_GROUP_VALUE;
                    style['?'].desc = "Total amount";
                    useCPart = false;
                    break;
                case BarModelTypes.TYPE_3B:
                    style['a'].value = "8";
                    style['a'].desc = "Total number of parts";
                    
                    style['a'].restrictions.type = int;
                    style['a'].restrictions.min = 2;
                    style['a'].restrictions.max = MAX_GROUP_VALUE;
                    style['b'].restrictions.type = Number;
                    style['b'].desc = "Total amount";
                    style['?'].desc = "Amount of one part";
                    style['?'].priority = 1;
                    useCPart = false;
                    break;
                case BarModelTypes.TYPE_3C:
                    style['?'].value = "8";
                    style['?'].desc = "Total number of parts";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Amount of one part";
                    style['a'].priority = 1;
                    style['b'].restrictions.type = Number;
                    style['b'].desc = "Total amount";
                    useCPart = false;
                    break;
                case BarModelTypes.TYPE_4A:
                    style['b'].value = "8";
                    style['b'].desc = "Number of parts";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Amount of one part";
                    style['a'].priority = 1;
                    style['b'].restrictions.type = int;
                    style['b'].restrictions.min = 2;
                    style['b'].restrictions.max = MAX_GROUP_VALUE;
                    style['?'].desc = "Total amount";
                    useCPart = false;
                    break;
                case BarModelTypes.TYPE_4B:
                    style['b'].value = "8";
                    style['b'].desc = "Number of parts";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Total amount";
                    style['b'].restrictions.type = int;
                    style['b'].restrictions.min = 2;
                    style['b'].restrictions.max = MAX_GROUP_VALUE;
                    style['?'].desc = "Amount of one part";
                    style['?'].priority = 1;
                    useCPart = false;
                    break;
                case BarModelTypes.TYPE_4C:
                    style['b'].value = "8";
                    style['b'].desc = "Number of parts";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Amount of one part";
                    style['a'].priority = 1;
                    style['b'].restrictions.type = int;
                    style['b'].restrictions.min = 2;
                    style['b'].restrictions.max = MAX_GROUP_VALUE;
                    style['?'].desc = "Difference";
                    useCPart = false;
                    break;
                case BarModelTypes.TYPE_4D:
                    style['b'].value = "8";
                    style['b'].desc = "Number of parts";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Amount of one part";
                    style['a'].priority = 1;
                    style['b'].restrictions.type = int;
                    style['b'].restrictions.min = 2;
                    style['b'].restrictions.max = MAX_GROUP_VALUE;
                    style['?'].desc = "Total amount";
                    useCPart = false;
                    break;
                case BarModelTypes.TYPE_4E:
                    // b must be greater than one
                    style['b'].value = "8";
                    style['b'].desc = "Number of parts";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Difference";
                    style['b'].restrictions.type = int;
                    style['b'].restrictions.min = 2;
                    style['b'].restrictions.max = MAX_GROUP_VALUE;
                    style['?'].desc = "Amount of one part";
                    style['?'].priority = 1;
                    useCPart = false;
                    break;
                case BarModelTypes.TYPE_4F:
                    style['b'].value = "8";
                    style['b'].desc = "Number of parts";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Total amount";
                    style['b'].restrictions.type = int;
                    style['b'].restrictions.min = 2;
                    style['b'].restrictions.max = MAX_GROUP_VALUE;
                    style['?'].desc = "Amount of one part";
                    style['?'].priority = 1;
                    useCPart = false;
                    break;
                case BarModelTypes.TYPE_4G:
                    style['?'].value = "8";
                    style['?'].desc = "Number of parts";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Amount of one part";
                    style['a'].priority = 1;
                    style['b'].restrictions.type = Number;
                    style['b'].desc = "Total amount";
                    useCPart = false;
                    break;
                // a must be greater than c
                case BarModelTypes.TYPE_5A:
                    style['a'].restrictions.type = Number;
                    style['b'].restrictions.type = Number;
                    style['c'].restrictions.type = String;
                    style['b'].value = "5";
                    style['a'].value = "8";
                    
                    style['a'].desc = "Larger amount";
                    style['b'].desc = "Difference";
                    style['c'].desc = "Smaller amount";
                    style['?'].desc = "Total amount";
                    break;
                case BarModelTypes.TYPE_5C:
                    style['a'].restrictions.type = Number;
                    style['b'].restrictions.type = Number;
                    style['c'].restrictions.type = String;
                    style['b'].value = "16";
                    style['a'].value = "8";
                    
                    style['a'].desc = "Larger amount";
                    style['b'].desc = "Total amount";
                    style['c'].desc = "Smaller amount";
                    style['?'].desc = "Difference";
                    break;
                // c must be greater than a
                case BarModelTypes.TYPE_5B:
                    style['a'].value = "3";
                    style['b'].value = "5";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Amount of one part";
                    style['b'].restrictions.type = Number;
                    style['b'].desc = "Difference";
                    style['c'].restrictions.type = Number;
                    style['c'].desc = "Larger amount";
                    style['?'].desc = "Total amount";
                    break;
                // c must be greater than ?
                case BarModelTypes.TYPE_5D:
                    style['a'].value = "5";
                    style['b'].value = "16";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Difference";
                    style['b'].restrictions.type = Number;
                    style['b'].desc = "Total amount";
                    style['c'].restrictions.type = Number;
                    style['c'].desc = "Larger amount";
                    style['?'].desc = "Smaller amount";
                    break;
                // ? must be greater than c
                case BarModelTypes.TYPE_5E:
                    style['b'].value = "16";
                    style['a'].value = "5";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Difference";
                    style['b'].restrictions.type = Number;
                    style['b'].desc = "Total amount";
                    style['c'].restrictions.type = Number;
                    style['c'].desc = "Smaller amount";
                    style['?'].desc = "Larger amount";
                    break;
                case BarModelTypes.TYPE_5F:
                    style['b'].value = "8";
                    style['b'].desc = "Number of parts";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Total amount";
                    style['b'].restrictions.type = int;
                    style['b'].restrictions.min = 2;
                    style['b'].restrictions.max = MAX_GROUP_VALUE;
                    style['b'].desc = "Total amount in group";
                    style['c'].desc = "Amount of one part";
                    style['c'].priority = 1;
                    style['c'].restrictions.type = Number;
                    style['?'].desc = "Difference";
                    break;
                case BarModelTypes.TYPE_5G:
                    style['b'].value = "8";
                    style['b'].desc = "Number of parts";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Total amount of group";
                    style['b'].restrictions.type = int;
                    style['b'].restrictions.min = 2;
                    style['b'].restrictions.max = MAX_GROUP_VALUE;
                    style['c'].restrictions.type = Number;
                    style['c'].desc = "Amount of one part";
                    style['c'].priority = 1;
                    style['?'].desc = "Total amount";
                    break;
                case BarModelTypes.TYPE_5H:
                    style['b'].value = "8";
                    style['b'].desc = "Number of parts";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Difference";
                    style['b'].restrictions.type = int;
                    style['b'].restrictions.min = 2;
                    style['b'].restrictions.max = MAX_GROUP_VALUE;
                    style['c'].desc = "Amount of one part";
                    style['c'].restrictions.type = Number;
                    style['c'].priority = 1;
                    style['?'].desc = "Total amount of group";
                    break;
                case BarModelTypes.TYPE_5I:
                    style['b'].value = "8";
                    style['b'].desc = "Number of parts";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Difference";
                    style['b'].restrictions.type = int;
                    style['b'].restrictions.min = 2;
                    style['b'].restrictions.max = MAX_GROUP_VALUE;
                    style['c'].restrictions.type = Number;
                    style['c'].desc = "Amount of one part";
                    style['c'].priority = 1;
                    style['?'].desc = "Total amount";
                    break;
                case BarModelTypes.TYPE_5J:
                    style['b'].value = "8";
                    style['b'].desc = "Number of parts";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Total amount";
                    style['b'].restrictions.type = int;
                    style['b'].restrictions.min = 2;
                    style['b'].restrictions.max = MAX_GROUP_VALUE;
                    style['c'].desc = "Amount of one part";
                    style['c'].priority = 1;
                    style['c'].restrictions.type = Number;
                    style['?'].desc = "Total amount of group";
                    break;
                case BarModelTypes.TYPE_5K:
                    style['b'].value = "8";
                    style['b'].desc = "Number of parts";
                    
                    style['a'].restrictions.type = Number;
                    style['a'].desc = "Total amount";
                    style['b'].restrictions.type = int;
                    style['b'].restrictions.min = 2;
                    style['b'].restrictions.max = MAX_GROUP_VALUE;
                    style['c'].desc = "Amount of one part";
                    style['c'].priority = 1;
                    style['c'].restrictions.type = Number;
                    style['?'].desc = "Difference";
                    break;
                case BarModelTypes.TYPE_6A:
                    setCommon6Style(style);
                    style['b'].desc = "Total amount";
                    style['?'].desc = "Amount in colored group";
                    break;
                case BarModelTypes.TYPE_6B:
                    setCommon6Style(style);
                    style['b'].desc = "Total amount";
                    style['?'].desc = "Amount in non-colored group";
                    break;
                case BarModelTypes.TYPE_6C:
                    setCommon6Style(style);
                    style['b'].desc = "Amount in colored group";
                    style['?'].desc = "Total amount";
                    break;
                case BarModelTypes.TYPE_6D:
                    setCommon6Style(style);
                    style['b'].desc = "Amount in colored group";
                    style['?'].desc = "Amount in non-colored group";
                    break;
                // All type 7 models have shaded and unshaded boxes separeted into two bars
                case BarModelTypes.TYPE_7A:
                    setCommon7Style(style);
                    style['?'].desc = "Amount in non-colored group";
                    style['b'].desc = "Amount in colored group";
                    break;
                case BarModelTypes.TYPE_7B:
                    setCommon7Style(style);
                    style['?'].desc = "Total amount";
                    style['b'].desc = "Amount in colored group";
                    break;
                case BarModelTypes.TYPE_7C:
                    setCommon7Style(style);
                    style['b'].desc = "Amount in colored group";
                    style['?'].desc = "Difference";
                    break;
                case BarModelTypes.TYPE_7D_1:
                    setCommon7Style(style);
                    style['?'].desc = "Amount in non-colored group";
                    style['b'].desc = "Total amount";
                    break;
                case BarModelTypes.TYPE_7D_2:
                    setCommon7Style(style);
                    style['?'].desc = "Amount in colored group";
                    style['b'].desc = "Total amount";
                    break;
                case BarModelTypes.TYPE_7E:
                    setCommon7Style(style);
                    style['b'].desc = "Total amount";
                    style['?'].desc = "Difference";
                    break;
                case BarModelTypes.TYPE_7F_1:
                    setCommon7Style(style);
                    style['?'].desc = "Amount in non-colored group";
                    style['b'].desc = "Difference";
                    break;
                case BarModelTypes.TYPE_7F_2:
                    setCommon7Style(style);
                    style['?'].desc = "Amount in colored group";
                    style['b'].desc = "Difference";
                    break;
                case BarModelTypes.TYPE_7G:
                    setCommon7Style(style);
                    style['b'].desc = "Difference";
                    style['?'].desc = "Total amount";
                    break;
            }
            
            if (!useCPart)
            {
                delete style['c'];
            }
            
            return style;
        }

        private function setCommon6Style(style:Object):void
        {
            style['a'].value = "2";
            style['a'].desc = "Number of colored parts";
            style['c'].value = "6";
            style['c'].desc = "Total number of parts";
            
            style['a'].restrictions.type = int;
            style['a'].restrictions.min = 1;
            style['a'].restrictions.max = MAX_GROUP_VALUE;
            style['b'].restrictions.type = Number;
            style['c'].restrictions.type = int;
            style['c'].restrictions.min = 2;
            style['c'].restrictions.max = MAX_GROUP_VALUE;
        }
        
        private function setCommon7Style(style:Object):void
        {
            style['a'].value = "2";
            style['a'].desc = "Fraction of Whole";
            style['c'].value = "4";
            style['c'].desc = "Parts of Whole";
            
            style['a'].restrictions.type = int;
            style['a'].restrictions.min = 1;
            style['a'].restrictions.max = MAX_GROUP_VALUE;
            style['b'].restrictions.type = Number;
            style['c'].restrictions.type = int;
            style['c'].restrictions.min = 2;
            style['c'].restrictions.max = MAX_GROUP_VALUE;
        }
        
        /**
         * HACK: This function may modify the 'value' property of each style object.
         * The reason for this is certain elements may represent both a segment and a label,
         * that is they must provide a numeric value to render an appropriate segment length as well
         * as the string name for the label. This is problematic for something like an unknown which
         * is a string variable whose numeric value is dependent on other values (for example ? may
         * be a + b, where a and b are numbers). The numeric value of something of the unknown is
         * calculated here to render the boxes correctly, the calculation depends on the bar model type.
         * 
         * HACK: For types 1 and 2, the style object can contain properties a1....an and b1...bn.
         * For all other types, you are restricted to using just a, b, c, and ? as the keys
         * 
         * @param styleObject
         *      If not null, allow other scripts to customize parameters when drawing the model,
         *      for example if you want to swap out different names and colors pass in a custom object.
         *      Otherwise the default info for a particular type is used for the drawing.
         * @param outValueNamesToElementIds
         *      If not null, function populates a map that binds a name of a group of parts in a particular
         *      bar model type to a list of ids of the elements that were contructed
         */
        public function drawBarModelIntoViewFromType(type:String, 
                                                     view:BarModelView,
                                                     styleObject:Object=null,
                                                     outValueNamesToElementIds:Object=null):void
        {
            if (styleObject == null)
            {
                styleObject = this.getStyleObjectForType(type);
            }
            
            function getTotalValueForPrefix(prefix:String, styleObject:Object):Number
            {
                var totalValue:Number = 0.0;
                for (var key:String in styleObject)
                {
                    if (key.indexOf(prefix) == 0)
                    {
                        totalValue += parseFloat(styleObject[key].value);
                    }
                }
                return totalValue;
            }
            
            switch(type)
            {
                case BarModelTypes.TYPE_1A:
                    drawCommonType1(view, "a", "b", "?", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_1B:
                    styleObject["?"].value = (getTotalValueForPrefix("b", styleObject) - getTotalValueForPrefix("a", styleObject)).toString();
                    drawCommonType1(view, "a", "?", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_2A:
                    drawCommonType2a(view, "b", "a", "?", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_2B:
                    drawCommonType2b(view, "b", "a", "?", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_2C:
                    styleObject["?"].value = (getTotalValueForPrefix("b", styleObject) - getTotalValueForPrefix("a", styleObject)).toString();
                    drawCommonType2a(view, "b", "?", "a", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_2D:
                    styleObject["?"].value = (getTotalValueForPrefix("b", styleObject) + getTotalValueForPrefix("a", styleObject)).toString();
                    drawCommonType2a(view, "?", "a", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_2E:
                    styleObject["?"].value = (getTotalValueForPrefix("b", styleObject) - getTotalValueForPrefix("a", styleObject)).toString();
                    drawCommonType2b(view, "a", "?", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_3A:
                    drawCommonType3(view, "a", "?", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_3B:
                    drawCommonType3(view, "?", "b", "a", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_3C:
                    drawCommonType3(view, "a", "b", "?", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_4A:
                    drawCommonType4a(view, "?", "a", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_4B:
                    drawCommonType4a(view, "a", "?", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_4C:
                    drawCommonType4b(view, "a", "?", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_4D:
                    drawCommonType4c(view, "a", "?", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_4E:
                    drawCommonType4b(view, "?", "a", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_4F:
                    drawCommonType4c(view, "?", "a", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_4G:
                    drawCommonType4a(view, "a", "b", "?", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_5A:
                    styleObject["c"].value = (parseFloat(styleObject["a"].value) - parseFloat(styleObject["b"].value)).toString();
                    styleObject["?"].value = (parseFloat(styleObject["a"].value) + parseFloat(styleObject["c"].value)).toString();
                    drawCommonType5a(view, "a", "c", "b", "?", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_5B:
                    styleObject["c"].value = (parseFloat(styleObject["a"].value) + parseFloat(styleObject["b"].value)).toString();
                    styleObject["?"].value = (parseFloat(styleObject["a"].value) + parseFloat(styleObject["c"].value)).toString();
                    drawCommonType5a(view, "c", "a", "b", "?", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_5C:
                    styleObject["c"].value = (parseFloat(styleObject["b"].value) - parseFloat(styleObject["a"].value)).toString();
                    styleObject["?"].value = (parseFloat(styleObject["a"].value) - parseFloat(styleObject["c"].value)).toString();
                    drawCommonType5a(view, "a", "c", "?", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_5D:
                    styleObject["?"].value = ((parseFloat(styleObject["b"].value) - parseFloat(styleObject["a"].value)) * 0.5).toString();
                    styleObject["c"].value = (parseFloat(styleObject["?"].value) + parseFloat(styleObject["a"].value)).toString();
                    drawCommonType5a(view, "c", "?", "a", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_5E:
                    styleObject["c"].value = ((parseFloat(styleObject["b"].value) - parseFloat(styleObject["a"].value)) * 0.5).toString();
                    styleObject["?"].value = (parseFloat(styleObject["c"].value) + parseFloat(styleObject["a"].value)).toString();
                    drawCommonType5a(view, "?", "c", "a", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_5F:
                    drawCommonType5b(view, "c", "?", "a", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_5G:
                    drawCommonType5c(view, "c", "a", "?", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_5H:
                    drawCommonType5b(view, "c", "a", "?", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_5I:
                    drawCommonType5d(view, "c", "a", "?", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_5J:
                    drawCommonType5c(view, "c", "?", "a", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_5K:
                    drawCommonType5d(view, "c", "?", "a", "b", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_6A:
                    drawCommonType6a(view, "?", "b", "a", "c", true, styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_6B:
                    drawCommonType6a(view, "?", "b", "a", "c", false, styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_6C:
                    drawCommonType6a(view, "b", "?", "a", "c", true, styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_6D:
                    drawCommonType6b(view, "b", "?", "a", "c", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_7A:
                    drawCommonType7a(view, "?", "b", "a", "c", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_7B:
                    drawCommonType7b(view, "b", "?", "a", "c", false, styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_7C:
                    drawCommonType7c(view, "b", "?", "a", "c", false, styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_7D_1:
                    drawCommonType7b(view, "?", "b", "a", "c", false, styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_7D_2:
                    drawCommonType7b(view, "?", "b", "a", "c", true, styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_7E:
                    drawCommonType7d(view, "b", "?", "a", "c", styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_7F_1:
                    drawCommonType7c(view, "b", "?", "a", "c", true, styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_7F_2:
                    drawCommonType7c(view, "b", "?", "a", "c", false, styleObject, outValueNamesToElementIds);
                    break;
                case BarModelTypes.TYPE_7G:
                    drawCommonType7d(view, "?", "b", "a", "c", styleObject, outValueNamesToElementIds);
                    break;
            }
        }
        
        private function drawCommonType1(view:BarModelView, 
                                         firstSegmentIdPrefix:String, 
                                         secondSegmentIdPrefix:String, 
                                         labelValue:String,
                                         styleObject:Object,
                                         outValueNameToIds:Object):void
        {
            var barWhole:BarWhole = new BarWhole(false);
            var idsMatchingFirstPrefix:Vector.<String> = populateBarWholeWithSegmentsMatchingPrefixes(firstSegmentIdPrefix, styleObject, barWhole, view.normalizingFactor);
            var idsMatchingSecondPrefix:Vector.<String> = populateBarWholeWithSegmentsMatchingPrefixes(secondSegmentIdPrefix, styleObject, barWhole, view.normalizingFactor);
            
            var numSegments:int = barWhole.barSegments.length;
            var labelValueStyle:BarModelTypeDrawerProperties = styleObject[labelValue];
            if (labelValueStyle.visible)
            {
                barWhole.barLabels.push(new BarLabel(getLabelName(labelValue, labelValueStyle), 0, numSegments - 1, true, false, BarLabel.BRACKET_STRAIGHT, null, null, labelValueStyle.color));
            }
            
            if (numSegments > 0)
            {
                view.getBarModelData().barWholes.push(barWhole);
            }
            
            if (outValueNameToIds != null)
            {
                barWhole = view.getBarModelData().barWholes[0];
                
                var totalIds:Vector.<String> = idsMatchingFirstPrefix.concat(idsMatchingSecondPrefix);
                for (var i:int = 0; i < totalIds.length; i++)
                {
                    outValueNameToIds[totalIds[i]] = Vector.<String>([barWhole.barSegments[i].id, barWhole.barLabels[i].id]);
                }
                
                var numLabels:int = barWhole.barLabels.length;
                outValueNameToIds[labelValue] = Vector.<String>([barWhole.barLabels[numLabels - 1].id]);
            }
        }
 
        /**
         * Helper function that takes a create bar whole and populates it with segments with labels
         * on top. The number of segments added depends on how many elements in the given style object
         * has a key with a matching prefix.
         * 
         * This allows for multiple parts named something like 'a1', 'a2', 'a3' to be added together
         * to a bar whole.
         * 
         * @return
         *      List of ids in the style object that match the given set of prefixes
         */
        private function populateBarWholeWithSegmentsMatchingPrefixes(prefixId:String, 
                                                                      styleObject:Object, 
                                                                      barWhole:BarWhole, 
                                                                      normalizingFactor:Number):Vector.<String>
        {
            // For each prefix, search for the property that matches the prefix
            var idsMatchingPrefix:Vector.<String> = new Vector.<String>();
            for (var id:String in styleObject)
            {
                if (id.indexOf(prefixId) == 0)
                {
                    idsMatchingPrefix.push(id);
                }
            }
            
            // Add new segments with a label for each match
            var i:int;
            for (i = 0; i < idsMatchingPrefix.length; i++)
            {
                var idMatchingPrefix:String = idsMatchingPrefix[i];
                var segmentStyle:BarModelTypeDrawerProperties = styleObject[idMatchingPrefix];
                if (segmentStyle.visible)
                {
                    barWhole.barSegments.push(new BarSegment(parseFloat(segmentStyle.value), normalizingFactor, 
                        segmentStyle.color, null));
                    var labelIndex:int = barWhole.barSegments.length - 1;
                    barWhole.barLabels.push(new BarLabel(getLabelName(idMatchingPrefix, segmentStyle), labelIndex, labelIndex, true, false, BarLabel.BRACKET_NONE, null));
                }
            }
            
            return idsMatchingPrefix;
        }
        
        private function drawCommonType2a(view:BarModelView, 
                                          firstSegmentIdPrefix:String, 
                                          secondSegmentIdPrefix:String, 
                                          differenceId:String,
                                          styleObject:Object,
                                          outValueNameToIds:Object):void
        {
            var barWhole:BarWhole = new BarWhole(false, "firstBar");
            var idsMatchingFirstPrefix:Vector.<String> = populateBarWholeWithSegmentsMatchingPrefixes(firstSegmentIdPrefix, styleObject, barWhole, view.normalizingFactor);
            if (barWhole.barSegments.length > 0)
            {
                view.getBarModelData().barWholes.push(barWhole);
            }
            
            barWhole = new BarWhole(false, "secondBar");
            var idsMatchingSecondPrefix:Vector.<String> = populateBarWholeWithSegmentsMatchingPrefixes(secondSegmentIdPrefix, styleObject, barWhole, view.normalizingFactor);
            
            var differenceStyles:BarModelTypeDrawerProperties = styleObject[differenceId];
            if (differenceStyles.visible && barWhole.barSegments.length > 0)
            {
                barWhole.barComparison = new BarComparison(getLabelName(differenceId, differenceStyles), "firstBar", 0, null, differenceStyles.color);
            }
            
            if (barWhole.barSegments.length > 0)
            {
                view.getBarModelData().barWholes.push(barWhole);
            }
            
            if (outValueNameToIds != null)
            {
                barWhole = view.getBarModelData().barWholes[0];
                for (var i:int = 0; i < idsMatchingFirstPrefix.length; i++)
                {
                    outValueNameToIds[idsMatchingFirstPrefix[i]] = Vector.<String>([barWhole.barSegments[i].id, barWhole.barLabels[i].id]);
                }
                
                barWhole = view.getBarModelData().barWholes[1];
                for (i = 0; i < idsMatchingSecondPrefix.length; i++)
                {
                    outValueNameToIds[idsMatchingSecondPrefix[i]] = Vector.<String>([barWhole.barSegments[i].id, barWhole.barLabels[i].id]);
                }
                
                outValueNameToIds[differenceId] = Vector.<String>([barWhole.barComparison.id]);
            }
        }
        
        private function drawCommonType2b(view:BarModelView, 
                                          firstSegmentIdPrefix:String, 
                                          secondSegmentIdPrefix:String, 
                                          labelValue:String, 
                                          styleObject:Object,
                                          outValueNameToIds:Object):void
        {
            var barWhole:BarWhole = new BarWhole(false, "firstBar");
            var idsMatchingFirstPrefix:Vector.<String> = populateBarWholeWithSegmentsMatchingPrefixes(firstSegmentIdPrefix, styleObject, barWhole, view.normalizingFactor);
            if (barWhole.barSegments.length > 0)
            {
                view.getBarModelData().barWholes.push(barWhole);
            }
            
            barWhole = new BarWhole(false, "secondBar");
            var idsMatchingSecondPrefix:Vector.<String> = populateBarWholeWithSegmentsMatchingPrefixes(secondSegmentIdPrefix, styleObject, barWhole, view.normalizingFactor);
            if (barWhole.barSegments.length > 0)
            {
                view.getBarModelData().barWholes.push(barWhole);
            }
            
            var verticalLabelStyles:BarModelTypeDrawerProperties = styleObject[labelValue];
            var numBarWholes:int = view.getBarModelData().barWholes.length;
            if (verticalLabelStyles.visible && numBarWholes > 0)
            {
                var verticalLabel:BarLabel = new BarLabel(getLabelName(labelValue, verticalLabelStyles),
                    0, numBarWholes - 1, false, false, BarLabel.BRACKET_STRAIGHT, null, null, verticalLabelStyles.color);
                view.getBarModelData().verticalBarLabels.push(verticalLabel);
            }
            
            if (outValueNameToIds != null)
            {
                barWhole = view.getBarModelData().barWholes[0];
                for (var i:int = 0; i < idsMatchingFirstPrefix.length; i++)
                {
                    outValueNameToIds[idsMatchingFirstPrefix[i]] = Vector.<String>([barWhole.barSegments[i].id, barWhole.barLabels[i].id]);
                }
                
                barWhole = view.getBarModelData().barWholes[1];
                for (i = 0; i < idsMatchingSecondPrefix.length; i++)
                {
                    outValueNameToIds[idsMatchingSecondPrefix[i]] = Vector.<String>([barWhole.barSegments[i].id, barWhole.barLabels[i].id]);
                }
                
                outValueNameToIds[labelValue] = Vector.<String>([view.getBarModelData().verticalBarLabels[0]]);
            }
        }
        
        /**
         *
         * @param numPartsLabelValue
         *      For exemplar models dealing with a variable number of parts need to bind a name.
         *      ex.) b=num parts
         *      In the example drawing this makes it possible to point out parts of the model
         *      that do not have an explicit label for them
         */
        private function drawCommonType3(view:BarModelView, 
                                         firstSegmentId:String, 
                                         totalLabelId:String,
                                         totalPartsId:String,
                                         styleObject:Object,
                                         outValueNameToIds:Object):void
        {
            var numPartsProps:BarModelTypeDrawerProperties = styleObject[totalPartsId];
            var numParts:int = parseInt(numPartsProps.value);
            var barWhole:BarWhole = getBarWhole(numParts, 2, null, numPartsProps.color);
            
            // First box in the bar is a different color
            var firstSegmentProps:BarModelTypeDrawerProperties = styleObject[firstSegmentId];
            if (firstSegmentProps.visible)
            {
                barWhole.barSegments[0].color = firstSegmentProps.color;
                barWhole.barLabels.push(new BarLabel(getLabelName(firstSegmentId, firstSegmentProps), 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            }
            
            var totalLabelProps:BarModelTypeDrawerProperties = styleObject[totalLabelId];
            if (totalLabelProps.visible)
            {
                barWhole.barLabels.push(new BarLabel(getLabelName(totalLabelId, totalLabelProps), 0, numParts - 1, true, false, BarLabel.BRACKET_STRAIGHT, null, null, totalLabelProps.color));
            }
            view.getBarModelData().barWholes.push(barWhole);
            
            if (outValueNameToIds != null)
            {
                barWhole = view.getBarModelData().barWholes[0];
                outValueNameToIds[firstSegmentId] = Vector.<String>([barWhole.barSegments[0].id, barWhole.barLabels[0].id]);
                
                outValueNameToIds[totalLabelId] = Vector.<String>([barWhole.barLabels[1].id]);
                
                var numPartsIds:Vector.<String> = new Vector.<String>();
                for each (var barSegment:BarSegment in barWhole.barSegments)
                {
                    numPartsIds.push(barSegment.id);
                }
                outValueNameToIds[totalPartsId] = numPartsIds;
            }
        }
        
        private function drawCommonType4a(view:BarModelView, 
                                          totalLabelId:String, 
                                          unitId:String,
                                          totalPartsId:String,
                                          styleObject:Object,
                                          outValueNameToIds:Object):void
        {
            var totalPartsProps:BarModelTypeDrawerProperties = styleObject[totalPartsId];
            var numParts:int = parseInt(totalPartsProps.value);
            var barWhole:BarWhole = getBarWhole(numParts, 1, null, totalPartsProps.color);
            
            var totalLabelProps:BarModelTypeDrawerProperties = styleObject[totalLabelId];
            if (totalLabelProps.visible)
            {
                barWhole.barLabels.push(new BarLabel(getLabelName(totalLabelId, totalLabelProps), 0, numParts - 1, true, false, BarLabel.BRACKET_STRAIGHT, null, null, totalLabelProps.color));
            }
            view.getBarModelData().barWholes.push(barWhole);
            
            barWhole = new BarWhole(false);
            var unitProps:BarModelTypeDrawerProperties = styleObject[unitId];
            if (unitProps.visible)
            {
                barWhole.barSegments.push(new BarSegment(1, 1, unitProps.color, null));
                barWhole.barLabels.push(new BarLabel(getLabelName(unitId, unitProps), 0, 0, true, false, BarLabel.BRACKET_NONE, null));
                view.getBarModelData().barWholes.push(barWhole);
            }
            
            if (outValueNameToIds != null)
            {
                barWhole = view.getBarModelData().barWholes[0];
                var numPartsIds:Vector.<String> = new Vector.<String>();
                for each (var barSegment:BarSegment in barWhole.barSegments)
                {
                    numPartsIds.push(barSegment.id);
                }
                outValueNameToIds[totalPartsId] = numPartsIds;
                outValueNameToIds[totalLabelId] = Vector.<String>([barWhole.barLabels[0].id]);
                
                barWhole = view.getBarModelData().barWholes[1];
                outValueNameToIds[unitId] = Vector.<String>([barWhole.barSegments[0].id, barWhole.barLabels[0].id]);
            }
        }
        
        private function drawCommonType4b(view:BarModelView, 
                                          unitId:String, 
                                          differenceId:String, 
                                          totalPartsId:String,
                                          styleObject:Object,
                                          outValueNameToIds:Object):void
        {
            var totalPartsProps:BarModelTypeDrawerProperties = styleObject[totalPartsId];
            var numParts:int = parseInt(totalPartsProps.value);
            var barWhole:BarWhole = getBarWhole(numParts, 1, "firstBar", totalPartsProps.color);
            view.getBarModelData().barWholes.push(barWhole);
            
            barWhole = new BarWhole(false);
            var unitProps:BarModelTypeDrawerProperties = styleObject[unitId];
            if (unitProps.visible)
            {
                barWhole.barSegments.push(new BarSegment(1, 1, unitProps.color, null));
                barWhole.barLabels.push(new BarLabel(getLabelName(unitId, unitProps), 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            }
            
            var differenceProps:BarModelTypeDrawerProperties = styleObject[differenceId];
            if (differenceProps.visible)
            {
                barWhole.barComparison = new BarComparison(getLabelName(differenceId, differenceProps), "firstBar", numParts - 1, null, differenceProps.color);
            }
            
            if (barWhole.barSegments.length > 0)
            {
                view.getBarModelData().barWholes.push(barWhole);
            }
            
            if (outValueNameToIds != null)
            {
                barWhole = view.getBarModelData().barWholes[0];
                var numPartsIds:Vector.<String> = new Vector.<String>();
                for each (var barSegment:BarSegment in barWhole.barSegments)
                {
                    numPartsIds.push(barSegment.id);
                }
                outValueNameToIds[totalPartsId] = numPartsIds;
                
                if (view.getBarModelData().barWholes.length > 1)
                {
                    barWhole = view.getBarModelData().barWholes[1];
                    outValueNameToIds[unitId] = Vector.<String>([barWhole.barSegments[0].id, barWhole.barLabels[0].id]);
                    outValueNameToIds[differenceId] = Vector.<String>([barWhole.barComparison]);
                }
            }
        }
        
        private function drawCommonType4c(view:BarModelView, 
                                          unitId:String, 
                                          verticalId:String,
                                          totalPartsId:String,
                                          styleObject:Object,
                                          outValueNameToIds:Object):void
        {
            var totalPartsProps:BarModelTypeDrawerProperties = styleObject[totalPartsId];
            var numParts:int = parseInt(totalPartsProps.value);
            var barWhole:BarWhole = getBarWhole(numParts, 1, null, totalPartsProps.color);
            view.getBarModelData().barWholes.push(barWhole);
            
            barWhole = new BarWhole(false);
            var unitProps:BarModelTypeDrawerProperties = styleObject[unitId];
            if (unitProps.visible)
            {
                barWhole.barSegments.push(new BarSegment(1, 1, unitProps.color, null));
                barWhole.barLabels.push(new BarLabel(getLabelName(unitId, unitProps), 0, 0, true, false, BarLabel.BRACKET_NONE, null));
                view.getBarModelData().barWholes.push(barWhole);
            }
            
            var verticalProps:BarModelTypeDrawerProperties = styleObject[verticalId];
            if (verticalProps.visible)
            {
                view.getBarModelData().verticalBarLabels.push(new BarLabel(getLabelName(verticalId, verticalProps), 0, 1, false, false, BarLabel.BRACKET_STRAIGHT, null, null, verticalProps.color));
            }
            
            if (outValueNameToIds != null)
            {
                barWhole = view.getBarModelData().barWholes[0];
                var numPartsIds:Vector.<String> = new Vector.<String>();
                for each (var barSegment:BarSegment in barWhole.barSegments)
                {
                    numPartsIds.push(barSegment.id);
                }
                outValueNameToIds[totalPartsId] = numPartsIds;
                
                if (view.getBarModelData().barWholes.length > 1)
                {
                    barWhole = view.getBarModelData().barWholes[1];
                    outValueNameToIds[unitId] = Vector.<String>([barWhole.barSegments[0].id, barWhole.barLabels[0].id]);
                    
                    outValueNameToIds[verticalId] = Vector.<String>([view.getBarModelData().verticalBarLabels[0].id]);
                }
            }
        }
        
        private function drawCommonType5a(view:BarModelView, 
                                          firstSegmentId:String, 
                                          secondSegmentId:String, 
                                          differenceId:String, 
                                          verticalId:String, 
                                          styleObject:Object,
                                          outValueNameToIds:Object):void
        {
            var firstSegmentProps:BarModelTypeDrawerProperties = styleObject[firstSegmentId];
            var barWhole:BarWhole = new BarWhole(false, "firstBar");
            if (firstSegmentProps.visible)
            {
                var firstSegmentValue:Number = parseFloat(firstSegmentProps.value);
                barWhole.barSegments.push(new BarSegment(firstSegmentValue, view.normalizingFactor, firstSegmentProps.color, null));
                barWhole.barLabels.push(new BarLabel(getLabelName(firstSegmentId, firstSegmentProps), 0, 0, true, false, BarLabel.BRACKET_NONE, null));
                view.getBarModelData().barWholes.push(barWhole);
            }
            
            barWhole = new BarWhole(false);
            var secondSegmentProps:BarModelTypeDrawerProperties = styleObject[secondSegmentId];
            if (secondSegmentProps.visible)
            {
                var secondSegmentValue:Number = parseFloat(secondSegmentProps.value);
                barWhole.barSegments.push(new BarSegment(secondSegmentValue, view.normalizingFactor, secondSegmentProps.color, null));
                barWhole.barLabels.push(new BarLabel(getLabelName(secondSegmentId, secondSegmentProps), 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            }
            
            var differenceProps:BarModelTypeDrawerProperties = styleObject[differenceId];
            if (differenceProps.visible)
            {
                barWhole.barComparison = new BarComparison(getLabelName(differenceId, differenceProps), "firstBar", 0, null, differenceProps.color);
            }
            view.getBarModelData().barWholes.push(barWhole);
            
            var verticalProps:BarModelTypeDrawerProperties = styleObject[verticalId];
            if (verticalProps.visible)
            {
                view.getBarModelData().verticalBarLabels.push(new BarLabel(getLabelName(verticalId, verticalProps), 0, 1, false, false, BarLabel.BRACKET_STRAIGHT, null, null, verticalProps.color));
            }
            
            if (outValueNameToIds != null)
            {
                barWhole = view.getBarModelData().barWholes[0];
                outValueNameToIds[firstSegmentId] = Vector.<String>([barWhole.barSegments[0].id, barWhole.barLabels[0].id]);
                
                barWhole = view.getBarModelData().barWholes[1];
                outValueNameToIds[secondSegmentId] = Vector.<String>([barWhole.barSegments[0].id, barWhole.barLabels[0].id]);
                
                outValueNameToIds[differenceId] = Vector.<String>([barWhole.barComparison.id]);
                
                outValueNameToIds[verticalId] = Vector.<String>([view.getBarModelData().verticalBarLabels[0].id]);
            }
        }
        
        private function drawCommonType5b(view:BarModelView, 
                                          unitId:String, 
                                          differenceId:String, 
                                          totalLabelId:String,
                                          totalPartsId:String,
                                          styleObject:Object,
                                          outValueNameToIds:Object):void
        {
            var totalPartsProps:BarModelTypeDrawerProperties = styleObject[totalPartsId];
            var numParts:int = parseInt(totalPartsProps.value);
            var barWhole:BarWhole = getBarWhole(numParts, 1, "firstBar", totalPartsProps.color);
            
            var totalLabelProps:BarModelTypeDrawerProperties = styleObject[totalLabelId];
            if (totalLabelProps.visible)
            {
                barWhole.barLabels.push(new BarLabel(getLabelName(totalLabelId, totalLabelProps), 0, numParts - 1, true, true, BarLabel.BRACKET_STRAIGHT, null, null, totalLabelProps.color));
            }
            view.getBarModelData().barWholes.push(barWhole);
            
            barWhole = new BarWhole(false);
            var unitProps:BarModelTypeDrawerProperties = styleObject[unitId];
            if (unitProps.visible)
            {
                barWhole.barSegments.push(new BarSegment(1, 1, unitProps.color, null));
                barWhole.barLabels.push(new BarLabel(getLabelName(unitId, unitProps), 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            }
            
            var differenceProps:BarModelTypeDrawerProperties = styleObject[differenceId];
            if (differenceProps.visible)
            {
                barWhole.barComparison = new BarComparison(getLabelName(differenceId, differenceProps), "firstBar", numParts - 1, null, differenceProps.color);
            }
            view.getBarModelData().barWholes.push(barWhole);
            
            if (outValueNameToIds != null)
            {
                barWhole = view.getBarModelData().barWholes[0];
                var numPartsIds:Vector.<String> = new Vector.<String>();
                for each (var barSegment:BarSegment in barWhole.barSegments)
                {
                    numPartsIds.push(barSegment.id);
                }
                outValueNameToIds[totalPartsId] = numPartsIds;
                
                outValueNameToIds[totalLabelId] = Vector.<String>([barWhole.barLabels[0].id]);
                
                barWhole = view.getBarModelData().barWholes[1];
                outValueNameToIds[unitId] = Vector.<String>([barWhole.barSegments[0].id, barWhole.barLabels[0].id]);
                outValueNameToIds[differenceId] = Vector.<String>([barWhole.barComparison.id]);
            }
        }
        
        private function drawCommonType5c(view:BarModelView, 
                                          unitId:String, 
                                          horizontalId:String, 
                                          verticalId:String,
                                          totalPartsId:String,
                                          styleObject:Object,
                                          outValueNameToIds:Object):void
        {
            var totalPartsProps:BarModelTypeDrawerProperties = styleObject[totalPartsId];
            var numParts:int = parseInt(totalPartsProps.value);
            var barWhole:BarWhole = getBarWhole(numParts, 1, null, totalPartsProps.color);
            
            var horizontalProps:BarModelTypeDrawerProperties = styleObject[horizontalId];
            if (horizontalProps.visible)
            {
                barWhole.barLabels.push(new BarLabel(getLabelName(horizontalId, horizontalProps), 0, numParts - 1, true, true, BarLabel.BRACKET_STRAIGHT, null, null, horizontalProps.color));
            }
            view.getBarModelData().barWholes.push(barWhole);
            
            barWhole = new BarWhole(false);
            var unitProps:BarModelTypeDrawerProperties = styleObject[unitId];
            if (unitProps.visible)
            {
                barWhole.barSegments.push(new BarSegment(1, 1, unitProps.color, null));
                barWhole.barLabels.push(new BarLabel(getLabelName(unitId, unitProps), 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            }
            view.getBarModelData().barWholes.push(barWhole);
            
            var verticalProps:BarModelTypeDrawerProperties = styleObject[verticalId];
            if (verticalProps.visible)
            {
                view.getBarModelData().verticalBarLabels.push(new BarLabel(getLabelName(verticalId, verticalProps), 0, 1, false, false, BarLabel.BRACKET_STRAIGHT, null, null, verticalProps.color));
            }
            
            if (outValueNameToIds != null)
            {
                barWhole = view.getBarModelData().barWholes[0];
                var numPartsIds:Vector.<String> = new Vector.<String>();
                for each (var barSegment:BarSegment in barWhole.barSegments)
                {
                    numPartsIds.push(barSegment.id);
                }
                outValueNameToIds[totalPartsId] = numPartsIds;
                outValueNameToIds[horizontalId] = Vector.<String>([barWhole.barLabels[0].id]);
                
                barWhole = view.getBarModelData().barWholes[1];
                outValueNameToIds[unitId] = Vector.<String>([barWhole.barSegments[0].id, barWhole.barLabels[0].id]);
                
                outValueNameToIds[verticalId] = Vector.<String>([view.getBarModelData().verticalBarLabels[0].id]);
            }
        }
        
        private function drawCommonType5d(view:BarModelView, 
                                          unitId:String, 
                                          differenceId:String, 
                                          verticalId:String,
                                          totalPartsId:String,
                                          styleObject:Object,
                                          outValueNameToIds:Object):void
        {
            var totalPartsProps:BarModelTypeDrawerProperties = styleObject[totalPartsId];
            var numParts:int = parseInt(totalPartsProps.value);
            var barWhole:BarWhole = getBarWhole(numParts, 1, "firstBar", totalPartsProps.color);
            view.getBarModelData().barWholes.push(barWhole);
            
            barWhole = new BarWhole(false);
            var unitProps:BarModelTypeDrawerProperties = styleObject[unitId];
            if (unitProps.visible)
            {
                barWhole.barSegments.push(new BarSegment(1, 1, unitProps.color, null));
                barWhole.barLabels.push(new BarLabel(getLabelName(unitId, unitProps), 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            }
            
            var differenceProps:BarModelTypeDrawerProperties = styleObject[differenceId];
            if (differenceProps.visible)
            {
                barWhole.barComparison = new BarComparison(getLabelName(differenceId, differenceProps), "firstBar", numParts - 1, null, differenceProps.color);
            }
            view.getBarModelData().barWholes.push(barWhole);
            
            var verticalProps:BarModelTypeDrawerProperties = styleObject[verticalId];
            if (verticalProps.visible)
            {
                view.getBarModelData().verticalBarLabels.push(new BarLabel(getLabelName(verticalId, verticalProps), 0, 1, false, false, BarLabel.BRACKET_STRAIGHT, null, null, verticalProps.color));
            }
            
            if (outValueNameToIds != null)
            {
                barWhole = view.getBarModelData().barWholes[0];
                var numPartsIds:Vector.<String> = new Vector.<String>();
                for each (var barSegment:BarSegment in barWhole.barSegments)
                {
                    numPartsIds.push(barSegment.id);
                }
                outValueNameToIds[totalPartsId] = numPartsIds;
                
                barWhole = view.getBarModelData().barWholes[1];
                outValueNameToIds[unitId] = Vector.<String>([barWhole.barSegments[0].id, barWhole.barLabels[0].id]);
                outValueNameToIds[differenceId] = Vector.<String>([barWhole.barComparison.id]);
                
                outValueNameToIds[verticalId] = Vector.<String>([view.getBarModelData().verticalBarLabels[0].id]);
            }
        }
        
        private function drawCommonType6a(view:BarModelView, 
                                          fractionalLabelId:String, 
                                          totalLabelId:String,
                                          shadedPartsId:String,
                                          totalPartsId:String,
                                          fractionOverShadedPart:Boolean,
                                          styleObject:Object,
                                          outValueNameToIds:Object):void
        {
            var barWhole:BarWhole = new BarWhole(false);
            var i:int;
            
            // Single bar has some boxes shaded
            var totalPartsProps:BarModelTypeDrawerProperties = styleObject[totalPartsId];
            var totalParts:int = parseInt(totalPartsProps.value);
            var shadedPartsProps:BarModelTypeDrawerProperties = styleObject[shadedPartsId];
            var shadedParts:int = parseInt(shadedPartsProps.value);
            for (i = 0; i < totalParts; i++)
            {
                var color:uint = (i < shadedParts) ? shadedPartsProps.color : 0xFFFFFF;
                barWhole.barSegments.push(new BarSegment(1, 1, color, null));
            }
            
            var totalLabelProps:BarModelTypeDrawerProperties = styleObject[totalLabelId];
            if (totalLabelProps.visible)
            {
                barWhole.barLabels.push(new BarLabel(getLabelName(totalLabelId, totalLabelProps), 0, totalParts - 1, true, true, BarLabel.BRACKET_STRAIGHT, null, null, totalLabelProps.color));
            }
            
            var startFractionalLabelIndex:int = 0;
            var endFractionalLabelIndex:int = shadedParts - 1;
            if (!fractionOverShadedPart) 
            {
                startFractionalLabelIndex = shadedParts;
                endFractionalLabelIndex = totalParts - 1;
            }
            var fractionalLabelProps:BarModelTypeDrawerProperties = styleObject[fractionalLabelId];
            if (fractionalLabelProps.visible)
            {
                barWhole.barLabels.push(new BarLabel(getLabelName(fractionalLabelId, fractionalLabelProps), startFractionalLabelIndex, endFractionalLabelIndex, 
                    true, false, BarLabel.BRACKET_STRAIGHT, null, null, fractionalLabelProps.color));
            }
            view.getBarModelData().barWholes.push(barWhole);
            
            if (outValueNameToIds != null)
            {
                barWhole = view.getBarModelData().barWholes[0];
                
                var shadedPartsIds:Vector.<String> = new Vector.<String>();
                var numPartsIds:Vector.<String> = new Vector.<String>();
                for (i = 0; i < barWhole.barSegments.length; i++)
                {
                    var barSegment:BarSegment = barWhole.barSegments[i];
                    if (i < shadedParts)
                    {
                        shadedPartsIds.push(barSegment.id);
                    }
                    numPartsIds.push(barSegment.id);
                }
                outValueNameToIds[shadedPartsId] = shadedPartsIds;
                outValueNameToIds[totalPartsId] = numPartsIds;
                
                outValueNameToIds[totalLabelId] = Vector.<String>([barWhole.barLabels[0].id]);
                outValueNameToIds[fractionalLabelId] = Vector.<String>([barWhole.barLabels[1].id]);
            }
        }
        
        private function drawCommonType6b(view:BarModelView, 
                                          shadedLabelId:String, 
                                          remainderLabelId:String,
                                          shadedPartsId:String,
                                          totalPartsId:String,
                                          styleObject:Object,
                                          outValueNameToIds:Object):void
        {
            var totalPartsProps:BarModelTypeDrawerProperties = styleObject[totalPartsId];
            var totalParts:int = parseInt(totalPartsProps.value);
            var shadedPartsProps:BarModelTypeDrawerProperties = styleObject[shadedPartsId];
            var shadedParts:int = parseInt(shadedPartsProps.value);
            var barWhole:BarWhole = new BarWhole(false);
            var i:int;
            for (i = 0; i < totalParts; i++)
            {
                var color:uint = (i < shadedParts) ? shadedPartsProps.color : 0xFFFFFF;
                barWhole.barSegments.push(new BarSegment(1, 1, color, null));
            }
            
            var shadedLabelProps:BarModelTypeDrawerProperties = styleObject[shadedLabelId];
            if (shadedLabelProps.visible)
            {
                barWhole.barLabels.push(new BarLabel(getLabelName(shadedLabelId, shadedLabelProps), 0, shadedParts - 1, 
                    true, false, BarLabel.BRACKET_STRAIGHT, null, null, shadedLabelProps.color));
            }
            
            var remainderLabelProps:BarModelTypeDrawerProperties = styleObject[remainderLabelId];
            if (remainderLabelProps.visible)
            {
                barWhole.barLabels.push(new BarLabel(getLabelName(remainderLabelId, remainderLabelProps), shadedParts, totalParts - 1, 
                    true, true, BarLabel.BRACKET_STRAIGHT, null, null, remainderLabelProps.color));
            }
            
            view.getBarModelData().barWholes.push(barWhole);
            
            if (outValueNameToIds != null)
            {
                barWhole = view.getBarModelData().barWholes[0];
                
                var shadedPartsIds:Vector.<String> = new Vector.<String>();
                var numPartsIds:Vector.<String> = new Vector.<String>();
                for (i = 0; i < barWhole.barSegments.length; i++)
                {
                    var barSegment:BarSegment = barWhole.barSegments[i];
                    if (i < shadedParts)
                    {
                        shadedPartsIds.push(barSegment.id);
                    }
                    numPartsIds.push(barSegment.id);
                }
                outValueNameToIds[shadedPartsId] = shadedPartsIds;
                outValueNameToIds[totalPartsId] = numPartsIds;
                
                outValueNameToIds[shadedLabelId] = Vector.<String>([barWhole.barLabels[0].id]);
                outValueNameToIds[remainderLabelId] = Vector.<String>([barWhole.barLabels[1].id]);
            }
        }
        
        private function drawCommonType7a(view:BarModelView, 
                                          remainderLabelId:String, 
                                          shadedLabelId:String,
                                          shadedPartsId:String,
                                          unshadedPartsId:String,
                                          styleObject:Object,
                                          outValueNameToIds:Object):void
        {
            var unshadedProps:BarModelTypeDrawerProperties = styleObject[unshadedPartsId];
            var shadedProps:BarModelTypeDrawerProperties = styleObject[shadedPartsId];
            var numUnshadedParts:int = parseInt(unshadedProps.value);
            var numShadedParts:int = parseInt(shadedProps.value);
            var barWhole:BarWhole = getBarWhole(numUnshadedParts, 1, null, unshadedProps.color);
            var remainderLabelProps:BarModelTypeDrawerProperties = styleObject[remainderLabelId];
            if (remainderLabelProps.visible)
            {
                barWhole.barLabels.push(new BarLabel(getLabelName(remainderLabelId, remainderLabelProps), 0, numUnshadedParts - 1, true, false, BarLabel.BRACKET_STRAIGHT, null, null, remainderLabelProps.color));
            }
            view.getBarModelData().barWholes.push(barWhole);
            
            barWhole = getBarWhole(numShadedParts, 1, null, shadedProps.color);
            var shadedLabelProps:BarModelTypeDrawerProperties = styleObject[shadedLabelId];
            if (shadedLabelProps.visible)
            {
                barWhole.barLabels.push(new BarLabel(getLabelName(shadedLabelId, shadedLabelProps), 0, numShadedParts - 1, true, false, BarLabel.BRACKET_STRAIGHT, null, null, shadedLabelProps.color));
            }
            view.getBarModelData().barWholes.push(barWhole);
            
            if (outValueNameToIds != null)
            {
                barWhole = view.getBarModelData().barWholes[0];
                var unshadedPartsIds:Vector.<String> = new Vector.<String>();
                for each (var barSegment:BarSegment in barWhole.barSegments)
                {
                    unshadedPartsIds.push(barSegment.id);
                }
                outValueNameToIds[remainderLabelId] = Vector.<String>([barWhole.barLabels[0].id]);
                
                barWhole = view.getBarModelData().barWholes[1];
                var shadedPartsIds:Vector.<String> = new Vector.<String>();
                for each (barSegment in barWhole.barSegments)
                {
                    shadedPartsIds.push(barSegment.id);
                }
                outValueNameToIds[shadedPartsId] = shadedPartsIds;
                outValueNameToIds[unshadedPartsId] = unshadedPartsIds;
                
                outValueNameToIds[shadedLabelId] = Vector.<String>([barWhole.barLabels[0].id]);
            }
        }
        
        private function drawCommonType7b(view:BarModelView, 
                                          horizontalId:String, 
                                          verticalId:String,
                                          shadedPartsId:String,
                                          unshadedPartsId:String,
                                          labelFirstBar:Boolean,
                                          styleObject:Object,
                                          outValueNameToIds:Object):void
        {
            var unshadedProps:BarModelTypeDrawerProperties = styleObject[unshadedPartsId];
            var shadedProps:BarModelTypeDrawerProperties = styleObject[shadedPartsId];
            var numUnshadedParts:int = parseInt(unshadedProps.value);
            var numShadedParts:int = parseInt(shadedProps.value);
            var barToAddLabelTo:BarWhole = null;
            var barWhole:BarWhole = getBarWhole(numUnshadedParts, 1, null, unshadedProps.color);
            if (labelFirstBar)
            {
                barToAddLabelTo = barWhole;
            }
            view.getBarModelData().barWholes.push(barWhole);
            
            barWhole = getBarWhole(numShadedParts, 1, null, shadedProps.color);
            if (!labelFirstBar)
            {
                barToAddLabelTo = barWhole;
            }
            view.getBarModelData().barWholes.push(barWhole);
            
            var horizontalProps:BarModelTypeDrawerProperties = styleObject[horizontalId];
            barToAddLabelTo.barLabels.push(new BarLabel(getLabelName(horizontalId, horizontalProps), 0, barToAddLabelTo.barSegments.length - 1, true, false, BarLabel.BRACKET_STRAIGHT, null, null, horizontalProps.color));
            
            var verticalProps:BarModelTypeDrawerProperties = styleObject[verticalId];
            if (verticalProps.visible && view.getBarModelData().barWholes.length == 2)
            {
                view.getBarModelData().verticalBarLabels.push(new BarLabel(getLabelName(verticalId, verticalProps), 0, 1, false, false, BarLabel.BRACKET_STRAIGHT, null, null, verticalProps.color));
            }
            
            if (outValueNameToIds != null)
            {
                barWhole = view.getBarModelData().barWholes[0];
                var unshadedPartsIds:Vector.<String> = new Vector.<String>();
                for each (var barSegment:BarSegment in barWhole.barSegments)
                {
                    unshadedPartsIds.push(barSegment.id);
                }
                
                barWhole = view.getBarModelData().barWholes[1];
                var shadedPartsIds:Vector.<String> = new Vector.<String>();
                for each (barSegment in barWhole.barSegments)
                {
                    shadedPartsIds.push(barSegment.id);
                }
                
                outValueNameToIds[shadedPartsId] = shadedPartsIds;
                outValueNameToIds[unshadedPartsId] = unshadedPartsIds;
                
                var barWholeIndexWithLabel:int = (labelFirstBar) ? 0 : 1;
                outValueNameToIds[horizontalId] = Vector.<String>([view.getBarModelData().barWholes[barWholeIndexWithLabel].barLabels[0]]);
                outValueNameToIds[verticalId] = Vector.<String>([view.getBarModelData().verticalBarLabels[0].id]);
            }
        }
        
        private function drawCommonType7c(view:BarModelView, 
                                          horizontalId:String, 
                                          differenceId:String,
                                          shadedPartsId:String,
                                          unshadedPartsId:String,
                                          labelFirstBar:Boolean,
                                          styleObject:Object,
                                          outValueNameToIds:Object):void
        {
            var unshadedProps:BarModelTypeDrawerProperties = styleObject[unshadedPartsId];
            var shadedProps:BarModelTypeDrawerProperties = styleObject[shadedPartsId];
            var numUnshadedParts:int = parseInt(unshadedProps.value);
            var numShadedParts:int = parseInt(shadedProps.value);
            var barToAddLabelTo:BarWhole = null;
            var barWhole:BarWhole = getBarWhole(numUnshadedParts, 1, "firstBar", unshadedProps.color);
            if (labelFirstBar)
            {
                barToAddLabelTo = barWhole;
            }
            view.getBarModelData().barWholes.push(barWhole);
            
            barWhole = getBarWhole(numShadedParts, 1, null, shadedProps.color);
            if (!labelFirstBar)
            {
                barToAddLabelTo = barWhole;
            }
            
            var differenceProps:BarModelTypeDrawerProperties = styleObject[differenceId];
            if (differenceProps.visible)
            {
                barWhole.barComparison = new BarComparison(getLabelName(differenceId, differenceProps), "firstBar", numUnshadedParts - 1, null, differenceProps.color);
            }
            
            var horizontalProps:BarModelTypeDrawerProperties = styleObject[horizontalId];
            if (horizontalProps.visible)
            {
                barToAddLabelTo.barLabels.push(new BarLabel(getLabelName(horizontalId, horizontalProps), 0, 
                    barToAddLabelTo.barSegments.length - 1, true, false, BarLabel.BRACKET_STRAIGHT, null, null, horizontalProps.color));
            }
            
            view.getBarModelData().barWholes.push(barWhole);
            
            if (outValueNameToIds != null)
            {
                barWhole = view.getBarModelData().barWholes[0];
                var unshadedPartsIds:Vector.<String> = new Vector.<String>();
                for each (var barSegment:BarSegment in barWhole.barSegments)
                {
                    unshadedPartsIds.push(barSegment.id);
                }
                
                barWhole = view.getBarModelData().barWholes[1];
                var shadedPartsIds:Vector.<String> = new Vector.<String>();
                for each (barSegment in barWhole.barSegments)
                {
                    shadedPartsIds.push(barSegment.id);
                }
                outValueNameToIds[shadedPartsId] = shadedPartsIds;
                outValueNameToIds[unshadedPartsId] = unshadedPartsIds;
                outValueNameToIds[differenceId] = Vector.<String>([barWhole.barComparison.id]);
                
                var barWholeIndexWithLabel:int = (labelFirstBar) ? 0 : 1;
                outValueNameToIds[horizontalId] = Vector.<String>([view.getBarModelData().barWholes[barWholeIndexWithLabel].barLabels[0]]);
            }
        }
        
        private function drawCommonType7d(view:BarModelView, 
                                          verticalId:String, 
                                          differenceId:String,
                                          shadedPartsId:String,
                                          unshadedPartsId:String,
                                          styleObject:Object,
                                          outValueNameToIds:Object):void
        {
            var unshadedProps:BarModelTypeDrawerProperties = styleObject[unshadedPartsId];
            var shadedProps:BarModelTypeDrawerProperties = styleObject[shadedPartsId];
            var numUnshadedParts:int = parseInt(unshadedProps.value);
            var numShadedParts:int = parseInt(shadedProps.value);
            var barWhole:BarWhole = getBarWhole(numUnshadedParts, 1, "firstBar");
            view.getBarModelData().barWholes.push(barWhole);
            
            barWhole = getBarWhole(numShadedParts, 1, null, shadedProps.color);
            var differenceProps:BarModelTypeDrawerProperties = styleObject[differenceId];
            if (differenceProps.visible)
            {
                barWhole.barComparison = new BarComparison(getLabelName(differenceId, differenceProps), "firstBar", numUnshadedParts - 1, null, differenceProps.color);
            }
            view.getBarModelData().barWholes.push(barWhole);
            
            var verticalProps:BarModelTypeDrawerProperties = styleObject[verticalId];
            if (verticalProps.visible && view.getBarModelData().barWholes.length == 2)
            {
                view.getBarModelData().verticalBarLabels.push(new BarLabel(getLabelName(verticalId, verticalProps), 0, 1, false, false, BarLabel.BRACKET_STRAIGHT, null, null, verticalProps.color));
            }
            
            if (outValueNameToIds != null)
            {
                barWhole = view.getBarModelData().barWholes[0];
                var unshadedPartsIds:Vector.<String> = new Vector.<String>();
                for each (var barSegment:BarSegment in barWhole.barSegments)
                {
                    unshadedPartsIds.push(barSegment.id);
                }
                
                barWhole = view.getBarModelData().barWholes[1];
                var shadedPartsIds:Vector.<String> = new Vector.<String>();
                for each (barSegment in barWhole.barSegments)
                {
                    shadedPartsIds.push(barSegment.id);
                }
                outValueNameToIds[shadedPartsId] = shadedPartsIds;
                outValueNameToIds[unshadedPartsId] = unshadedPartsIds;
                outValueNameToIds[differenceId] = Vector.<String>([barWhole.barComparison.id]);
                outValueNameToIds[verticalId] = Vector.<String>([view.getBarModelData().verticalBarLabels[0].id]);
            }
        }
        
        /**
         * Helper to get a bar with n number of equal sized segments
         */
        private function getBarWhole(numParts:int = 1, 
                                     valuePerSegment:int = 1, 
                                     id:String=null, 
                                     color:uint=0xFFFFFF):BarWhole
        {
            var barWhole:BarWhole = new BarWhole(false, id);
            var i:int;
            for (i = 0; i < numParts; i++)
            {
                barWhole.barSegments.push(new BarSegment(valuePerSegment, 1, color, null));
            }
            return barWhole;
        }
        
        /*
        Helper functions that check restrictions for values in a particular type
        
        They all have in common that the last two parameters are the mapping from
        element id to bar model type properties AND
        the mapping from element id to an alias value assigned to it
        */
        private function checkValueGreaterThan(greaterElement:String, 
                                               lesserElement:String, 
                                               barModelTypeProperties:Object, 
                                               elementToAliasMap:Object):Boolean
        {
            var greaterElementValue:int = parseFloat(elementToAliasMap[greaterElement]);
            var lesserElementValue:int = parseFloat(elementToAliasMap[lesserElement]);
            return greaterElementValue > lesserElementValue;
        }
        
        private function checkValueInRange(element:String, 
                                           barModelTypeProperties:Object, 
                                           elementToAliasMap:Object):Boolean
        {
            var elementProperties:BarModelTypeDrawerProperties = barModelTypeProperties[element];
            var elementValue:Number = parseFloat(elementToAliasMap[element]);
            var restrictions:Object = elementProperties.restrictions;
            var inRange:Boolean = true;
            if (restrictions.hasOwnProperty("min"))
            {
                inRange = elementValue >= restrictions.min;
            }
            
            if (restrictions.hasOwnProperty("max"))
            {
                inRange = elementValue <= restrictions.max;   
            }
            return inRange;
        }
        
        private function getLabelName(id:String, styles:BarModelTypeDrawerProperties):String
        {
            if (styles.alias != null)
            {
                var name:String = styles.alias;
            }
            else if (styles.value != null)
            {
                name = styles.value;
            }
            else
            {
                name = id;
            }
            return name;
        }
    }
}