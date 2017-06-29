package wordproblem.engine.barmodel;

import wordproblem.engine.barmodel.BarModelTypeDrawerProperties;

import wordproblem.engine.barmodel.model.BarComparison;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.barmodel.view.BarModelView;

/**
 * This is a helper utility class used to draw the various bar model template
 */
class BarModelTypeDrawer
{
    // Max allowable number of equal groups that can compose a single bar
    private inline var MAX_GROUP_VALUE : Int = 30;
    
    // Color palette
    private inline var PINK : Int = 0xF5749A;
    private inline var ORANGE : Int = 0xF5A475;
    private inline var GOLD : Int = 0xDCC565;
    private inline var GREEN : Int = 0x99E871;
    private inline var CYAN : Int = 0x66FFFF;
    
    public function new()
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
    public function getStyleObjectForType(type : String, colorMap : Dynamic = null) : Dynamic
    {
        var style : Dynamic = { };
        
        // Important: Certain types do not use the 'c' element
        var useCPart : Bool = true;
        var partIds : Array<String> = ["a", "b", "c", "?"];
        if (colorMap == null) 
        {
            colorMap = {
                        a : GOLD,
                        b : CYAN,
                        c : GREEN,
                        ? : PINK,

                    };
        }
        var i : Int;
        for (i in 0...partIds.length){
            var partId : String = partIds[i];
            var partProperties : BarModelTypeDrawerProperties = new BarModelTypeDrawerProperties();
            if (colorMap.exists(partId)) 
            {
                partProperties.color = Reflect.field(colorMap, partId);
            }  // alias is always just the name of the part initially  
            
            
            
            partProperties.alias = partId;
            
            Reflect.setField(style, partId, partProperties);
        }  // By default the ? is always just a string since it is a variable in the level  
        
        
        
        Reflect.setField(style, "?", String).restrictions.type;
        
        switch (type)
        {
            case BarModelTypes.TYPE_1A:
                Reflect.setField(style, "a", "2").value;
                Reflect.setField(style, "b", "1").value;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Some amount").desc;
                Reflect.setField(style, "b", Float).restrictions.type;
                Reflect.setField(style, "b", "Some amount").desc;
                Reflect.setField(style, "?", "Total amount").desc;
                useCPart = false;
            case BarModelTypes.TYPE_1B:
                Reflect.setField(style, "a", "2").value;
                Reflect.setField(style, "b", "3").value;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Some amount").desc;
                Reflect.setField(style, "b", Float).restrictions.type;
                Reflect.setField(style, "b", "Total amount").desc;
                Reflect.setField(style, "?", "Some amount").desc;
                useCPart = false;
            case BarModelTypes.TYPE_2A:
                // b must be greater than a
                Reflect.setField(style, "b", "2").value;
                Reflect.setField(style, "b", "a").restrictions.gt;
                Reflect.setField(style, "a", "1").value;
                Reflect.setField(style, "a", "b").restrictions.lt;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Smaller amount").desc;
                Reflect.setField(style, "b", Float).restrictions.type;
                Reflect.setField(style, "b", "Larger amount").desc;
                Reflect.setField(style, "?", "Difference").desc;
                useCPart = false;
            case BarModelTypes.TYPE_2B:
                Reflect.setField(style, "a", "1").value;
                Reflect.setField(style, "b", "2").value;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Some amount").desc;
                Reflect.setField(style, "b", Float).restrictions.type;
                Reflect.setField(style, "b", "Some amount").desc;
                Reflect.setField(style, "?", "Total Amount").desc;
                useCPart = false;
            case BarModelTypes.TYPE_2C:
                // b must be greater than ?
                Reflect.setField(style, "b", "2").value;
                Reflect.setField(style, "b", "?").restrictions.gt;
                Reflect.setField(style, "a", "1").value;
                Reflect.setField(style, "?", "b").restrictions.lt;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Difference").desc;
                Reflect.setField(style, "b", Float).restrictions.type;
                Reflect.setField(style, "b", "Larger amount").desc;
                Reflect.setField(style, "?", "Smaller amount").desc;
                useCPart = false;
            case BarModelTypes.TYPE_2D:
                // ? must be greater than a
                Reflect.setField(style, "b", "1").value;
                Reflect.setField(style, "a", "1").value;
                Reflect.setField(style, "a", "?").restrictions.lt;
                Reflect.setField(style, "?", "a").restrictions.gt;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Smaller amount").desc;
                Reflect.setField(style, "b", Float).restrictions.type;
                Reflect.setField(style, "b", "Difference").desc;
                Reflect.setField(style, "?", "Larger amount").desc;
                useCPart = false;
            case BarModelTypes.TYPE_2E:
                Reflect.setField(style, "a", "2").value;
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Some amount").desc;
                Reflect.setField(style, "b", Float).restrictions.type;
                Reflect.setField(style, "b", "Total amount").desc;
                Reflect.setField(style, "b", "3").value;
                Reflect.setField(style, "?", "Some amount").desc;
                useCPart = false;
            case BarModelTypes.TYPE_3A:
                Reflect.setField(style, "b", "8").value;
                Reflect.setField(style, "b", "Total number of parts").desc;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Amount of one part").desc;
                Reflect.setField(style, "a", 1).priority;
                Reflect.setField(style, "b", Int).restrictions.type;
                Reflect.setField(style, "b", 2).restrictions.min;
                Reflect.setField(style, "b", MAX_GROUP_VALUE).restrictions.max;
                Reflect.setField(style, "?", "Total amount").desc;
                useCPart = false;
            case BarModelTypes.TYPE_3B:
                Reflect.setField(style, "a", "8").value;
                Reflect.setField(style, "a", "Total number of parts").desc;
                
                Reflect.setField(style, "a", Int).restrictions.type;
                Reflect.setField(style, "a", 2).restrictions.min;
                Reflect.setField(style, "a", MAX_GROUP_VALUE).restrictions.max;
                Reflect.setField(style, "b", Float).restrictions.type;
                Reflect.setField(style, "b", "Total amount").desc;
                Reflect.setField(style, "?", "Amount of one part").desc;
                Reflect.setField(style, "?", 1).priority;
                useCPart = false;
            case BarModelTypes.TYPE_3C:
                Reflect.setField(style, "?", "8").value;
                Reflect.setField(style, "?", "Total number of parts").desc;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Amount of one part").desc;
                Reflect.setField(style, "a", 1).priority;
                Reflect.setField(style, "b", Float).restrictions.type;
                Reflect.setField(style, "b", "Total amount").desc;
                useCPart = false;
            case BarModelTypes.TYPE_4A:
                Reflect.setField(style, "b", "8").value;
                Reflect.setField(style, "b", "Number of parts").desc;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Amount of one part").desc;
                Reflect.setField(style, "a", 1).priority;
                Reflect.setField(style, "b", Int).restrictions.type;
                Reflect.setField(style, "b", 2).restrictions.min;
                Reflect.setField(style, "b", MAX_GROUP_VALUE).restrictions.max;
                Reflect.setField(style, "?", "Total amount").desc;
                useCPart = false;
            case BarModelTypes.TYPE_4B:
                Reflect.setField(style, "b", "8").value;
                Reflect.setField(style, "b", "Number of parts").desc;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Total amount").desc;
                Reflect.setField(style, "b", Int).restrictions.type;
                Reflect.setField(style, "b", 2).restrictions.min;
                Reflect.setField(style, "b", MAX_GROUP_VALUE).restrictions.max;
                Reflect.setField(style, "?", "Amount of one part").desc;
                Reflect.setField(style, "?", 1).priority;
                useCPart = false;
            case BarModelTypes.TYPE_4C:
                Reflect.setField(style, "b", "8").value;
                Reflect.setField(style, "b", "Number of parts").desc;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Amount of one part").desc;
                Reflect.setField(style, "a", 1).priority;
                Reflect.setField(style, "b", Int).restrictions.type;
                Reflect.setField(style, "b", 2).restrictions.min;
                Reflect.setField(style, "b", MAX_GROUP_VALUE).restrictions.max;
                Reflect.setField(style, "?", "Difference").desc;
                useCPart = false;
            case BarModelTypes.TYPE_4D:
                Reflect.setField(style, "b", "8").value;
                Reflect.setField(style, "b", "Number of parts").desc;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Amount of one part").desc;
                Reflect.setField(style, "a", 1).priority;
                Reflect.setField(style, "b", Int).restrictions.type;
                Reflect.setField(style, "b", 2).restrictions.min;
                Reflect.setField(style, "b", MAX_GROUP_VALUE).restrictions.max;
                Reflect.setField(style, "?", "Total amount").desc;
                useCPart = false;
            case BarModelTypes.TYPE_4E:
                // b must be greater than one
                Reflect.setField(style, "b", "8").value;
                Reflect.setField(style, "b", "Number of parts").desc;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Difference").desc;
                Reflect.setField(style, "b", Int).restrictions.type;
                Reflect.setField(style, "b", 2).restrictions.min;
                Reflect.setField(style, "b", MAX_GROUP_VALUE).restrictions.max;
                Reflect.setField(style, "?", "Amount of one part").desc;
                Reflect.setField(style, "?", 1).priority;
                useCPart = false;
            case BarModelTypes.TYPE_4F:
                Reflect.setField(style, "b", "8").value;
                Reflect.setField(style, "b", "Number of parts").desc;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Total amount").desc;
                Reflect.setField(style, "b", Int).restrictions.type;
                Reflect.setField(style, "b", 2).restrictions.min;
                Reflect.setField(style, "b", MAX_GROUP_VALUE).restrictions.max;
                Reflect.setField(style, "?", "Amount of one part").desc;
                Reflect.setField(style, "?", 1).priority;
                useCPart = false;
            case BarModelTypes.TYPE_4G:
                Reflect.setField(style, "?", "8").value;
                Reflect.setField(style, "?", "Number of parts").desc;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Amount of one part").desc;
                Reflect.setField(style, "a", 1).priority;
                Reflect.setField(style, "b", Float).restrictions.type;
                Reflect.setField(style, "b", "Total amount").desc;
                useCPart = false;
            // a must be greater than c
            case BarModelTypes.TYPE_5A:
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "b", Float).restrictions.type;
                Reflect.setField(style, "c", String).restrictions.type;
                Reflect.setField(style, "b", "5").value;
                Reflect.setField(style, "a", "8").value;
                
                Reflect.setField(style, "a", "Larger amount").desc;
                Reflect.setField(style, "b", "Difference").desc;
                Reflect.setField(style, "c", "Smaller amount").desc;
                Reflect.setField(style, "?", "Total amount").desc;
            case BarModelTypes.TYPE_5C:
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "b", Float).restrictions.type;
                Reflect.setField(style, "c", String).restrictions.type;
                Reflect.setField(style, "b", "16").value;
                Reflect.setField(style, "a", "8").value;
                
                Reflect.setField(style, "a", "Larger amount").desc;
                Reflect.setField(style, "b", "Total amount").desc;
                Reflect.setField(style, "c", "Smaller amount").desc;
                Reflect.setField(style, "?", "Difference").desc;
            // c must be greater than a
            case BarModelTypes.TYPE_5B:
                Reflect.setField(style, "a", "3").value;
                Reflect.setField(style, "b", "5").value;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Amount of one part").desc;
                Reflect.setField(style, "b", Float).restrictions.type;
                Reflect.setField(style, "b", "Difference").desc;
                Reflect.setField(style, "c", Float).restrictions.type;
                Reflect.setField(style, "c", "Larger amount").desc;
                Reflect.setField(style, "?", "Total amount").desc;
            // c must be greater than ?
            case BarModelTypes.TYPE_5D:
                Reflect.setField(style, "a", "5").value;
                Reflect.setField(style, "b", "16").value;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Difference").desc;
                Reflect.setField(style, "b", Float).restrictions.type;
                Reflect.setField(style, "b", "Total amount").desc;
                Reflect.setField(style, "c", Float).restrictions.type;
                Reflect.setField(style, "c", "Larger amount").desc;
                Reflect.setField(style, "?", "Smaller amount").desc;
            // ? must be greater than c
            case BarModelTypes.TYPE_5E:
                Reflect.setField(style, "b", "16").value;
                Reflect.setField(style, "a", "5").value;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Difference").desc;
                Reflect.setField(style, "b", Float).restrictions.type;
                Reflect.setField(style, "b", "Total amount").desc;
                Reflect.setField(style, "c", Float).restrictions.type;
                Reflect.setField(style, "c", "Smaller amount").desc;
                Reflect.setField(style, "?", "Larger amount").desc;
            case BarModelTypes.TYPE_5F:
                Reflect.setField(style, "b", "8").value;
                Reflect.setField(style, "b", "Number of parts").desc;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Total amount").desc;
                Reflect.setField(style, "b", Int).restrictions.type;
                Reflect.setField(style, "b", 2).restrictions.min;
                Reflect.setField(style, "b", MAX_GROUP_VALUE).restrictions.max;
                Reflect.setField(style, "b", "Total amount in group").desc;
                Reflect.setField(style, "c", "Amount of one part").desc;
                Reflect.setField(style, "c", 1).priority;
                Reflect.setField(style, "c", Float).restrictions.type;
                Reflect.setField(style, "?", "Difference").desc;
            case BarModelTypes.TYPE_5G:
                Reflect.setField(style, "b", "8").value;
                Reflect.setField(style, "b", "Number of parts").desc;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Total amount of group").desc;
                Reflect.setField(style, "b", Int).restrictions.type;
                Reflect.setField(style, "b", 2).restrictions.min;
                Reflect.setField(style, "b", MAX_GROUP_VALUE).restrictions.max;
                Reflect.setField(style, "c", Float).restrictions.type;
                Reflect.setField(style, "c", "Amount of one part").desc;
                Reflect.setField(style, "c", 1).priority;
                Reflect.setField(style, "?", "Total amount").desc;
            case BarModelTypes.TYPE_5H:
                Reflect.setField(style, "b", "8").value;
                Reflect.setField(style, "b", "Number of parts").desc;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Difference").desc;
                Reflect.setField(style, "b", Int).restrictions.type;
                Reflect.setField(style, "b", 2).restrictions.min;
                Reflect.setField(style, "b", MAX_GROUP_VALUE).restrictions.max;
                Reflect.setField(style, "c", "Amount of one part").desc;
                Reflect.setField(style, "c", Float).restrictions.type;
                Reflect.setField(style, "c", 1).priority;
                Reflect.setField(style, "?", "Total amount of group").desc;
            case BarModelTypes.TYPE_5I:
                Reflect.setField(style, "b", "8").value;
                Reflect.setField(style, "b", "Number of parts").desc;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Difference").desc;
                Reflect.setField(style, "b", Int).restrictions.type;
                Reflect.setField(style, "b", 2).restrictions.min;
                Reflect.setField(style, "b", MAX_GROUP_VALUE).restrictions.max;
                Reflect.setField(style, "c", Float).restrictions.type;
                Reflect.setField(style, "c", "Amount of one part").desc;
                Reflect.setField(style, "c", 1).priority;
                Reflect.setField(style, "?", "Total amount").desc;
            case BarModelTypes.TYPE_5J:
                Reflect.setField(style, "b", "8").value;
                Reflect.setField(style, "b", "Number of parts").desc;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Total amount").desc;
                Reflect.setField(style, "b", Int).restrictions.type;
                Reflect.setField(style, "b", 2).restrictions.min;
                Reflect.setField(style, "b", MAX_GROUP_VALUE).restrictions.max;
                Reflect.setField(style, "c", "Amount of one part").desc;
                Reflect.setField(style, "c", 1).priority;
                Reflect.setField(style, "c", Float).restrictions.type;
                Reflect.setField(style, "?", "Total amount of group").desc;
            case BarModelTypes.TYPE_5K:
                Reflect.setField(style, "b", "8").value;
                Reflect.setField(style, "b", "Number of parts").desc;
                
                Reflect.setField(style, "a", Float).restrictions.type;
                Reflect.setField(style, "a", "Total amount").desc;
                Reflect.setField(style, "b", Int).restrictions.type;
                Reflect.setField(style, "b", 2).restrictions.min;
                Reflect.setField(style, "b", MAX_GROUP_VALUE).restrictions.max;
                Reflect.setField(style, "c", "Amount of one part").desc;
                Reflect.setField(style, "c", 1).priority;
                Reflect.setField(style, "c", Float).restrictions.type;
                Reflect.setField(style, "?", "Difference").desc;
            case BarModelTypes.TYPE_6A:
                setCommon6Style(style);
                Reflect.setField(style, "b", "Total amount").desc;
                Reflect.setField(style, "?", "Amount in colored group").desc;
            case BarModelTypes.TYPE_6B:
                setCommon6Style(style);
                Reflect.setField(style, "b", "Total amount").desc;
                Reflect.setField(style, "?", "Amount in non-colored group").desc;
            case BarModelTypes.TYPE_6C:
                setCommon6Style(style);
                Reflect.setField(style, "b", "Amount in colored group").desc;
                Reflect.setField(style, "?", "Total amount").desc;
            case BarModelTypes.TYPE_6D:
                setCommon6Style(style);
                Reflect.setField(style, "b", "Amount in colored group").desc;
                Reflect.setField(style, "?", "Amount in non-colored group").desc;
            // All type 7 models have shaded and unshaded boxes separeted into two bars
            case BarModelTypes.TYPE_7A:
                setCommon7Style(style);
                Reflect.setField(style, "?", "Amount in non-colored group").desc;
                Reflect.setField(style, "b", "Amount in colored group").desc;
            case BarModelTypes.TYPE_7B:
                setCommon7Style(style);
                Reflect.setField(style, "?", "Total amount").desc;
                Reflect.setField(style, "b", "Amount in colored group").desc;
            case BarModelTypes.TYPE_7C:
                setCommon7Style(style);
                Reflect.setField(style, "b", "Amount in colored group").desc;
                Reflect.setField(style, "?", "Difference").desc;
            case BarModelTypes.TYPE_7D_1:
                setCommon7Style(style);
                Reflect.setField(style, "?", "Amount in non-colored group").desc;
                Reflect.setField(style, "b", "Total amount").desc;
            case BarModelTypes.TYPE_7D_2:
                setCommon7Style(style);
                Reflect.setField(style, "?", "Amount in colored group").desc;
                Reflect.setField(style, "b", "Total amount").desc;
            case BarModelTypes.TYPE_7E:
                setCommon7Style(style);
                Reflect.setField(style, "b", "Total amount").desc;
                Reflect.setField(style, "?", "Difference").desc;
            case BarModelTypes.TYPE_7F_1:
                setCommon7Style(style);
                Reflect.setField(style, "?", "Amount in non-colored group").desc;
                Reflect.setField(style, "b", "Difference").desc;
            case BarModelTypes.TYPE_7F_2:
                setCommon7Style(style);
                Reflect.setField(style, "?", "Amount in colored group").desc;
                Reflect.setField(style, "b", "Difference").desc;
            case BarModelTypes.TYPE_7G:
                setCommon7Style(style);
                Reflect.setField(style, "b", "Difference").desc;
                Reflect.setField(style, "?", "Total amount").desc;
        }
        
        if (!useCPart) 
        {
            ;
        }
        
        return style;
    }
    
    private function setCommon6Style(style : Dynamic) : Void
    {
        Reflect.setField(style, "a", "2").value;
        Reflect.setField(style, "a", "Number of colored parts").desc;
        Reflect.setField(style, "c", "6").value;
        Reflect.setField(style, "c", "Total number of parts").desc;
        
        Reflect.setField(style, "a", Int).restrictions.type;
        Reflect.setField(style, "a", 1).restrictions.min;
        Reflect.setField(style, "a", MAX_GROUP_VALUE).restrictions.max;
        Reflect.setField(style, "b", Float).restrictions.type;
        Reflect.setField(style, "c", Int).restrictions.type;
        Reflect.setField(style, "c", 2).restrictions.min;
        Reflect.setField(style, "c", MAX_GROUP_VALUE).restrictions.max;
    }
    
    private function setCommon7Style(style : Dynamic) : Void
    {
        Reflect.setField(style, "a", "2").value;
        Reflect.setField(style, "a", "Fraction of Whole").desc;
        Reflect.setField(style, "c", "4").value;
        Reflect.setField(style, "c", "Parts of Whole").desc;
        
        Reflect.setField(style, "a", Int).restrictions.type;
        Reflect.setField(style, "a", 1).restrictions.min;
        Reflect.setField(style, "a", MAX_GROUP_VALUE).restrictions.max;
        Reflect.setField(style, "b", Float).restrictions.type;
        Reflect.setField(style, "c", Int).restrictions.type;
        Reflect.setField(style, "c", 2).restrictions.min;
        Reflect.setField(style, "c", MAX_GROUP_VALUE).restrictions.max;
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
    public function drawBarModelIntoViewFromType(type : String,
            view : BarModelView,
            styleObject : Dynamic = null,
            outValueNamesToElementIds : Dynamic = null) : Void
    {
        if (styleObject == null) 
        {
            styleObject = this.getStyleObjectForType(type);
        }
        
        function getTotalValueForPrefix(prefix : String, styleObject : Dynamic) : Float
        {
            var totalValue : Float = 0.0;
            for (key in Reflect.fields(styleObject))
            {
                if (key.indexOf(prefix) == 0) 
                {
                    totalValue += parseFloat(Reflect.field(styleObject, key).value);
                }
            }
            return totalValue;
        };
        
        switch (type)
        {
            case BarModelTypes.TYPE_1A:
                drawCommonType1(view, "a", "b", "?", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_1B:
                Reflect.setField(styleObject, "?", Std.string((getTotalValueForPrefix("b", styleObject) - getTotalValueForPrefix("a", styleObject)))).value;
                drawCommonType1(view, "a", "?", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_2A:
                drawCommonType2a(view, "b", "a", "?", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_2B:
                drawCommonType2b(view, "b", "a", "?", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_2C:
                Reflect.setField(styleObject, "?", Std.string((getTotalValueForPrefix("b", styleObject) - getTotalValueForPrefix("a", styleObject)))).value;
                drawCommonType2a(view, "b", "?", "a", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_2D:
                Reflect.setField(styleObject, "?", Std.string((getTotalValueForPrefix("b", styleObject) + getTotalValueForPrefix("a", styleObject)))).value;
                drawCommonType2a(view, "?", "a", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_2E:
                Reflect.setField(styleObject, "?", Std.string((getTotalValueForPrefix("b", styleObject) - getTotalValueForPrefix("a", styleObject)))).value;
                drawCommonType2b(view, "a", "?", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_3A:
                drawCommonType3(view, "a", "?", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_3B:
                drawCommonType3(view, "?", "b", "a", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_3C:
                drawCommonType3(view, "a", "b", "?", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_4A:
                drawCommonType4a(view, "?", "a", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_4B:
                drawCommonType4a(view, "a", "?", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_4C:
                drawCommonType4b(view, "a", "?", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_4D:
                drawCommonType4c(view, "a", "?", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_4E:
                drawCommonType4b(view, "?", "a", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_4F:
                drawCommonType4c(view, "?", "a", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_4G:
                drawCommonType4a(view, "a", "b", "?", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_5A:
                Reflect.setField(styleObject, "c", Std.string((parseFloat(Reflect.field(styleObject, "a").value) - parseFloat(Reflect.field(styleObject, "b").value)))).value;
                Reflect.setField(styleObject, "?", Std.string((parseFloat(Reflect.field(styleObject, "a").value) + parseFloat(Reflect.field(styleObject, "c").value)))).value;
                drawCommonType5a(view, "a", "c", "b", "?", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_5B:
                Reflect.setField(styleObject, "c", Std.string((parseFloat(Reflect.field(styleObject, "a").value) + parseFloat(Reflect.field(styleObject, "b").value)))).value;
                Reflect.setField(styleObject, "?", Std.string((parseFloat(Reflect.field(styleObject, "a").value) + parseFloat(Reflect.field(styleObject, "c").value)))).value;
                drawCommonType5a(view, "c", "a", "b", "?", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_5C:
                Reflect.setField(styleObject, "c", Std.string((parseFloat(Reflect.field(styleObject, "b").value) - parseFloat(Reflect.field(styleObject, "a").value)))).value;
                Reflect.setField(styleObject, "?", Std.string((parseFloat(Reflect.field(styleObject, "a").value) - parseFloat(Reflect.field(styleObject, "c").value)))).value;
                drawCommonType5a(view, "a", "c", "?", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_5D:
                Reflect.setField(styleObject, "?", Std.string(((parseFloat(Reflect.field(styleObject, "b").value) - parseFloat(Reflect.field(styleObject, "a").value)) * 0.5))).value;
                Reflect.setField(styleObject, "c", Std.string((parseFloat(Reflect.field(styleObject, "?").value) + parseFloat(Reflect.field(styleObject, "a").value)))).value;
                drawCommonType5a(view, "c", "?", "a", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_5E:
                Reflect.setField(styleObject, "c", Std.string(((parseFloat(Reflect.field(styleObject, "b").value) - parseFloat(Reflect.field(styleObject, "a").value)) * 0.5))).value;
                Reflect.setField(styleObject, "?", Std.string((parseFloat(Reflect.field(styleObject, "c").value) + parseFloat(Reflect.field(styleObject, "a").value)))).value;
                drawCommonType5a(view, "?", "c", "a", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_5F:
                drawCommonType5b(view, "c", "?", "a", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_5G:
                drawCommonType5c(view, "c", "a", "?", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_5H:
                drawCommonType5b(view, "c", "a", "?", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_5I:
                drawCommonType5d(view, "c", "a", "?", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_5J:
                drawCommonType5c(view, "c", "?", "a", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_5K:
                drawCommonType5d(view, "c", "?", "a", "b", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_6A:
                drawCommonType6a(view, "?", "b", "a", "c", true, styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_6B:
                drawCommonType6a(view, "?", "b", "a", "c", false, styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_6C:
                drawCommonType6a(view, "b", "?", "a", "c", true, styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_6D:
                drawCommonType6b(view, "b", "?", "a", "c", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_7A:
                drawCommonType7a(view, "?", "b", "a", "c", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_7B:
                drawCommonType7b(view, "b", "?", "a", "c", false, styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_7C:
                drawCommonType7c(view, "b", "?", "a", "c", false, styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_7D_1:
                drawCommonType7b(view, "?", "b", "a", "c", false, styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_7D_2:
                drawCommonType7b(view, "?", "b", "a", "c", true, styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_7E:
                drawCommonType7d(view, "b", "?", "a", "c", styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_7F_1:
                drawCommonType7c(view, "b", "?", "a", "c", true, styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_7F_2:
                drawCommonType7c(view, "b", "?", "a", "c", false, styleObject, outValueNamesToElementIds);
            case BarModelTypes.TYPE_7G:
                drawCommonType7d(view, "?", "b", "a", "c", styleObject, outValueNamesToElementIds);
        }
    }
    
    private function drawCommonType1(view : BarModelView,
            firstSegmentIdPrefix : String,
            secondSegmentIdPrefix : String,
            labelValue : String,
            styleObject : Dynamic,
            outValueNameToIds : Dynamic) : Void
    {
        var barWhole : BarWhole = new BarWhole(false);
        var idsMatchingFirstPrefix : Array<String> = populateBarWholeWithSegmentsMatchingPrefixes(firstSegmentIdPrefix, styleObject, barWhole, view.normalizingFactor);
        var idsMatchingSecondPrefix : Array<String> = populateBarWholeWithSegmentsMatchingPrefixes(secondSegmentIdPrefix, styleObject, barWhole, view.normalizingFactor);
        
        var numSegments : Int = barWhole.barSegments.length;
        var labelValueStyle : BarModelTypeDrawerProperties = Reflect.field(styleObject, labelValue);
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
            
            var totalIds : Array<String> = idsMatchingFirstPrefix.concat(idsMatchingSecondPrefix);
            for (i in 0...totalIds.length){
                Reflect.setField(outValueNameToIds, Std.string(totalIds[i]), [barWhole.barSegments[i].id, barWhole.barLabels[i].id]);
            }
            
            var numLabels : Int = barWhole.barLabels.length;
            Reflect.setField(outValueNameToIds, labelValue, [barWhole.barLabels[numLabels - 1].id]);
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
    private function populateBarWholeWithSegmentsMatchingPrefixes(prefixId : String,
            styleObject : Dynamic,
            barWhole : BarWhole,
            normalizingFactor : Float) : Array<String>
    {
        // For each prefix, search for the property that matches the prefix
        var idsMatchingPrefix : Array<String> = new Array<String>();
        for (id in Reflect.fields(styleObject))
        {
            if (id.indexOf(prefixId) == 0) 
            {
                idsMatchingPrefix.push(id);
            }
        }  // Add new segments with a label for each match  
        
        
        
        var i : Int;
        for (i in 0...idsMatchingPrefix.length){
            var idMatchingPrefix : String = idsMatchingPrefix[i];
            var segmentStyle : BarModelTypeDrawerProperties = Reflect.field(styleObject, idMatchingPrefix);
            if (segmentStyle.visible) 
            {
                barWhole.barSegments.push(new BarSegment(parseFloat(segmentStyle.value), normalizingFactor, 
                        segmentStyle.color, null));
                var labelIndex : Int = barWhole.barSegments.length - 1;
                barWhole.barLabels.push(new BarLabel(getLabelName(idMatchingPrefix, segmentStyle), labelIndex, labelIndex, true, false, BarLabel.BRACKET_NONE, null));
            }
        }
        
        return idsMatchingPrefix;
    }
    
    private function drawCommonType2a(view : BarModelView,
            firstSegmentIdPrefix : String,
            secondSegmentIdPrefix : String,
            differenceId : String,
            styleObject : Dynamic,
            outValueNameToIds : Dynamic) : Void
    {
        var barWhole : BarWhole = new BarWhole(false, "firstBar");
        var idsMatchingFirstPrefix : Array<String> = populateBarWholeWithSegmentsMatchingPrefixes(firstSegmentIdPrefix, styleObject, barWhole, view.normalizingFactor);
        if (barWhole.barSegments.length > 0) 
        {
            view.getBarModelData().barWholes.push(barWhole);
        }
        
        barWhole = new BarWhole(false, "secondBar");
        var idsMatchingSecondPrefix : Array<String> = populateBarWholeWithSegmentsMatchingPrefixes(secondSegmentIdPrefix, styleObject, barWhole, view.normalizingFactor);
        
        var differenceStyles : BarModelTypeDrawerProperties = Reflect.field(styleObject, differenceId);
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
            for (i in 0...idsMatchingFirstPrefix.length){
                Reflect.setField(outValueNameToIds, Std.string(idsMatchingFirstPrefix[i]), [barWhole.barSegments[i].id, barWhole.barLabels[i].id]);
            }
            
            barWhole = view.getBarModelData().barWholes[1];
            for (i in 0...idsMatchingSecondPrefix.length){
                Reflect.setField(outValueNameToIds, Std.string(idsMatchingSecondPrefix[i]), [barWhole.barSegments[i].id, barWhole.barLabels[i].id]);
            }
            
            Reflect.setField(outValueNameToIds, differenceId, [barWhole.barComparison.id]);
        }
    }
    
    private function drawCommonType2b(view : BarModelView,
            firstSegmentIdPrefix : String,
            secondSegmentIdPrefix : String,
            labelValue : String,
            styleObject : Dynamic,
            outValueNameToIds : Dynamic) : Void
    {
        var barWhole : BarWhole = new BarWhole(false, "firstBar");
        var idsMatchingFirstPrefix : Array<String> = populateBarWholeWithSegmentsMatchingPrefixes(firstSegmentIdPrefix, styleObject, barWhole, view.normalizingFactor);
        if (barWhole.barSegments.length > 0) 
        {
            view.getBarModelData().barWholes.push(barWhole);
        }
        
        barWhole = new BarWhole(false, "secondBar");
        var idsMatchingSecondPrefix : Array<String> = populateBarWholeWithSegmentsMatchingPrefixes(secondSegmentIdPrefix, styleObject, barWhole, view.normalizingFactor);
        if (barWhole.barSegments.length > 0) 
        {
            view.getBarModelData().barWholes.push(barWhole);
        }
        
        var verticalLabelStyles : BarModelTypeDrawerProperties = Reflect.field(styleObject, labelValue);
        var numBarWholes : Int = view.getBarModelData().barWholes.length;
        if (verticalLabelStyles.visible && numBarWholes > 0) 
        {
            var verticalLabel : BarLabel = new BarLabel(getLabelName(labelValue, verticalLabelStyles), 
            0, numBarWholes - 1, false, false, BarLabel.BRACKET_STRAIGHT, null, null, verticalLabelStyles.color);
            view.getBarModelData().verticalBarLabels.push(verticalLabel);
        }
        
        if (outValueNameToIds != null) 
        {
            barWhole = view.getBarModelData().barWholes[0];
            for (i in 0...idsMatchingFirstPrefix.length){
                Reflect.setField(outValueNameToIds, Std.string(idsMatchingFirstPrefix[i]), [barWhole.barSegments[i].id, barWhole.barLabels[i].id]);
            }
            
            barWhole = view.getBarModelData().barWholes[1];
            for (i in 0...idsMatchingSecondPrefix.length){
                Reflect.setField(outValueNameToIds, Std.string(idsMatchingSecondPrefix[i]), [barWhole.barSegments[i].id, barWhole.barLabels[i].id]);
            }
            
            Reflect.setField(outValueNameToIds, labelValue, [view.getBarModelData().verticalBarLabels[0]]);
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
    private function drawCommonType3(view : BarModelView,
            firstSegmentId : String,
            totalLabelId : String,
            totalPartsId : String,
            styleObject : Dynamic,
            outValueNameToIds : Dynamic) : Void
    {
        var numPartsProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, totalPartsId);
        var numParts : Int = parseInt(numPartsProps.value);
        var barWhole : BarWhole = getBarWhole(numParts, 2, null, numPartsProps.color);
        
        // First box in the bar is a different color
        var firstSegmentProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, firstSegmentId);
        if (firstSegmentProps.visible) 
        {
            barWhole.barSegments[0].color = firstSegmentProps.color;
            barWhole.barLabels.push(new BarLabel(getLabelName(firstSegmentId, firstSegmentProps), 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        }
        
        var totalLabelProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, totalLabelId);
        if (totalLabelProps.visible) 
        {
            barWhole.barLabels.push(new BarLabel(getLabelName(totalLabelId, totalLabelProps), 0, numParts - 1, true, false, BarLabel.BRACKET_STRAIGHT, null, null, totalLabelProps.color));
        }
        view.getBarModelData().barWholes.push(barWhole);
        
        if (outValueNameToIds != null) 
        {
            barWhole = view.getBarModelData().barWholes[0];
            Reflect.setField(outValueNameToIds, firstSegmentId, [barWhole.barSegments[0].id, barWhole.barLabels[0].id]);
            
            Reflect.setField(outValueNameToIds, totalLabelId, [barWhole.barLabels[1].id]);
            
            var numPartsIds : Array<String> = new Array<String>();
            for (barSegment/* AS3HX WARNING could not determine type for var: barSegment exp: EField(EIdent(barWhole),barSegments) type: null */ in barWhole.barSegments)
            {
                numPartsIds.push(barSegment.id);
            }
            Reflect.setField(outValueNameToIds, totalPartsId, numPartsIds);
        }
    }
    
    private function drawCommonType4a(view : BarModelView,
            totalLabelId : String,
            unitId : String,
            totalPartsId : String,
            styleObject : Dynamic,
            outValueNameToIds : Dynamic) : Void
    {
        var totalPartsProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, totalPartsId);
        var numParts : Int = parseInt(totalPartsProps.value);
        var barWhole : BarWhole = getBarWhole(numParts, 1, null, totalPartsProps.color);
        
        var totalLabelProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, totalLabelId);
        if (totalLabelProps.visible) 
        {
            barWhole.barLabels.push(new BarLabel(getLabelName(totalLabelId, totalLabelProps), 0, numParts - 1, true, false, BarLabel.BRACKET_STRAIGHT, null, null, totalLabelProps.color));
        }
        view.getBarModelData().barWholes.push(barWhole);
        
        barWhole = new BarWhole(false);
        var unitProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, unitId);
        if (unitProps.visible) 
        {
            barWhole.barSegments.push(new BarSegment(1, 1, unitProps.color, null));
            barWhole.barLabels.push(new BarLabel(getLabelName(unitId, unitProps), 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            view.getBarModelData().barWholes.push(barWhole);
        }
        
        if (outValueNameToIds != null) 
        {
            barWhole = view.getBarModelData().barWholes[0];
            var numPartsIds : Array<String> = new Array<String>();
            for (barSegment/* AS3HX WARNING could not determine type for var: barSegment exp: EField(EIdent(barWhole),barSegments) type: null */ in barWhole.barSegments)
            {
                numPartsIds.push(barSegment.id);
            }
            Reflect.setField(outValueNameToIds, totalPartsId, numPartsIds);
            Reflect.setField(outValueNameToIds, totalLabelId, [barWhole.barLabels[0].id]);
            
            barWhole = view.getBarModelData().barWholes[1];
            Reflect.setField(outValueNameToIds, unitId, [barWhole.barSegments[0].id, barWhole.barLabels[0].id]);
        }
    }
    
    private function drawCommonType4b(view : BarModelView,
            unitId : String,
            differenceId : String,
            totalPartsId : String,
            styleObject : Dynamic,
            outValueNameToIds : Dynamic) : Void
    {
        var totalPartsProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, totalPartsId);
        var numParts : Int = parseInt(totalPartsProps.value);
        var barWhole : BarWhole = getBarWhole(numParts, 1, "firstBar", totalPartsProps.color);
        view.getBarModelData().barWholes.push(barWhole);
        
        barWhole = new BarWhole(false);
        var unitProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, unitId);
        if (unitProps.visible) 
        {
            barWhole.barSegments.push(new BarSegment(1, 1, unitProps.color, null));
            barWhole.barLabels.push(new BarLabel(getLabelName(unitId, unitProps), 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        }
        
        var differenceProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, differenceId);
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
            var numPartsIds : Array<String> = new Array<String>();
            for (barSegment/* AS3HX WARNING could not determine type for var: barSegment exp: EField(EIdent(barWhole),barSegments) type: null */ in barWhole.barSegments)
            {
                numPartsIds.push(barSegment.id);
            }
            Reflect.setField(outValueNameToIds, totalPartsId, numPartsIds);
            
            if (view.getBarModelData().barWholes.length > 1) 
            {
                barWhole = view.getBarModelData().barWholes[1];
                Reflect.setField(outValueNameToIds, unitId, [barWhole.barSegments[0].id, barWhole.barLabels[0].id]);
                Reflect.setField(outValueNameToIds, differenceId, [barWhole.barComparison]);
            }
        }
    }
    
    private function drawCommonType4c(view : BarModelView,
            unitId : String,
            verticalId : String,
            totalPartsId : String,
            styleObject : Dynamic,
            outValueNameToIds : Dynamic) : Void
    {
        var totalPartsProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, totalPartsId);
        var numParts : Int = parseInt(totalPartsProps.value);
        var barWhole : BarWhole = getBarWhole(numParts, 1, null, totalPartsProps.color);
        view.getBarModelData().barWholes.push(barWhole);
        
        barWhole = new BarWhole(false);
        var unitProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, unitId);
        if (unitProps.visible) 
        {
            barWhole.barSegments.push(new BarSegment(1, 1, unitProps.color, null));
            barWhole.barLabels.push(new BarLabel(getLabelName(unitId, unitProps), 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            view.getBarModelData().barWholes.push(barWhole);
        }
        
        var verticalProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, verticalId);
        if (verticalProps.visible) 
        {
            view.getBarModelData().verticalBarLabels.push(new BarLabel(getLabelName(verticalId, verticalProps), 0, 1, false, false, BarLabel.BRACKET_STRAIGHT, null, null, verticalProps.color));
        }
        
        if (outValueNameToIds != null) 
        {
            barWhole = view.getBarModelData().barWholes[0];
            var numPartsIds : Array<String> = new Array<String>();
            for (barSegment/* AS3HX WARNING could not determine type for var: barSegment exp: EField(EIdent(barWhole),barSegments) type: null */ in barWhole.barSegments)
            {
                numPartsIds.push(barSegment.id);
            }
            Reflect.setField(outValueNameToIds, totalPartsId, numPartsIds);
            
            if (view.getBarModelData().barWholes.length > 1) 
            {
                barWhole = view.getBarModelData().barWholes[1];
                Reflect.setField(outValueNameToIds, unitId, [barWhole.barSegments[0].id, barWhole.barLabels[0].id]);
                
                Reflect.setField(outValueNameToIds, verticalId, [view.getBarModelData().verticalBarLabels[0].id]);
            }
        }
    }
    
    private function drawCommonType5a(view : BarModelView,
            firstSegmentId : String,
            secondSegmentId : String,
            differenceId : String,
            verticalId : String,
            styleObject : Dynamic,
            outValueNameToIds : Dynamic) : Void
    {
        var firstSegmentProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, firstSegmentId);
        var barWhole : BarWhole = new BarWhole(false, "firstBar");
        if (firstSegmentProps.visible) 
        {
            var firstSegmentValue : Float = parseFloat(firstSegmentProps.value);
            barWhole.barSegments.push(new BarSegment(firstSegmentValue, view.normalizingFactor, firstSegmentProps.color, null));
            barWhole.barLabels.push(new BarLabel(getLabelName(firstSegmentId, firstSegmentProps), 0, 0, true, false, BarLabel.BRACKET_NONE, null));
            view.getBarModelData().barWholes.push(barWhole);
        }
        
        barWhole = new BarWhole(false);
        var secondSegmentProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, secondSegmentId);
        if (secondSegmentProps.visible) 
        {
            var secondSegmentValue : Float = parseFloat(secondSegmentProps.value);
            barWhole.barSegments.push(new BarSegment(secondSegmentValue, view.normalizingFactor, secondSegmentProps.color, null));
            barWhole.barLabels.push(new BarLabel(getLabelName(secondSegmentId, secondSegmentProps), 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        }
        
        var differenceProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, differenceId);
        if (differenceProps.visible) 
        {
            barWhole.barComparison = new BarComparison(getLabelName(differenceId, differenceProps), "firstBar", 0, null, differenceProps.color);
        }
        view.getBarModelData().barWholes.push(barWhole);
        
        var verticalProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, verticalId);
        if (verticalProps.visible) 
        {
            view.getBarModelData().verticalBarLabels.push(new BarLabel(getLabelName(verticalId, verticalProps), 0, 1, false, false, BarLabel.BRACKET_STRAIGHT, null, null, verticalProps.color));
        }
        
        if (outValueNameToIds != null) 
        {
            barWhole = view.getBarModelData().barWholes[0];
            Reflect.setField(outValueNameToIds, firstSegmentId, [barWhole.barSegments[0].id, barWhole.barLabels[0].id]);
            
            barWhole = view.getBarModelData().barWholes[1];
            Reflect.setField(outValueNameToIds, secondSegmentId, [barWhole.barSegments[0].id, barWhole.barLabels[0].id]);
            
            Reflect.setField(outValueNameToIds, differenceId, [barWhole.barComparison.id]);
            
            Reflect.setField(outValueNameToIds, verticalId, [view.getBarModelData().verticalBarLabels[0].id]);
        }
    }
    
    private function drawCommonType5b(view : BarModelView,
            unitId : String,
            differenceId : String,
            totalLabelId : String,
            totalPartsId : String,
            styleObject : Dynamic,
            outValueNameToIds : Dynamic) : Void
    {
        var totalPartsProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, totalPartsId);
        var numParts : Int = parseInt(totalPartsProps.value);
        var barWhole : BarWhole = getBarWhole(numParts, 1, "firstBar", totalPartsProps.color);
        
        var totalLabelProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, totalLabelId);
        if (totalLabelProps.visible) 
        {
            barWhole.barLabels.push(new BarLabel(getLabelName(totalLabelId, totalLabelProps), 0, numParts - 1, true, true, BarLabel.BRACKET_STRAIGHT, null, null, totalLabelProps.color));
        }
        view.getBarModelData().barWholes.push(barWhole);
        
        barWhole = new BarWhole(false);
        var unitProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, unitId);
        if (unitProps.visible) 
        {
            barWhole.barSegments.push(new BarSegment(1, 1, unitProps.color, null));
            barWhole.barLabels.push(new BarLabel(getLabelName(unitId, unitProps), 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        }
        
        var differenceProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, differenceId);
        if (differenceProps.visible) 
        {
            barWhole.barComparison = new BarComparison(getLabelName(differenceId, differenceProps), "firstBar", numParts - 1, null, differenceProps.color);
        }
        view.getBarModelData().barWholes.push(barWhole);
        
        if (outValueNameToIds != null) 
        {
            barWhole = view.getBarModelData().barWholes[0];
            var numPartsIds : Array<String> = new Array<String>();
            for (barSegment/* AS3HX WARNING could not determine type for var: barSegment exp: EField(EIdent(barWhole),barSegments) type: null */ in barWhole.barSegments)
            {
                numPartsIds.push(barSegment.id);
            }
            Reflect.setField(outValueNameToIds, totalPartsId, numPartsIds);
            
            Reflect.setField(outValueNameToIds, totalLabelId, [barWhole.barLabels[0].id]);
            
            barWhole = view.getBarModelData().barWholes[1];
            Reflect.setField(outValueNameToIds, unitId, [barWhole.barSegments[0].id, barWhole.barLabels[0].id]);
            Reflect.setField(outValueNameToIds, differenceId, [barWhole.barComparison.id]);
        }
    }
    
    private function drawCommonType5c(view : BarModelView,
            unitId : String,
            horizontalId : String,
            verticalId : String,
            totalPartsId : String,
            styleObject : Dynamic,
            outValueNameToIds : Dynamic) : Void
    {
        var totalPartsProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, totalPartsId);
        var numParts : Int = parseInt(totalPartsProps.value);
        var barWhole : BarWhole = getBarWhole(numParts, 1, null, totalPartsProps.color);
        
        var horizontalProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, horizontalId);
        if (horizontalProps.visible) 
        {
            barWhole.barLabels.push(new BarLabel(getLabelName(horizontalId, horizontalProps), 0, numParts - 1, true, true, BarLabel.BRACKET_STRAIGHT, null, null, horizontalProps.color));
        }
        view.getBarModelData().barWholes.push(barWhole);
        
        barWhole = new BarWhole(false);
        var unitProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, unitId);
        if (unitProps.visible) 
        {
            barWhole.barSegments.push(new BarSegment(1, 1, unitProps.color, null));
            barWhole.barLabels.push(new BarLabel(getLabelName(unitId, unitProps), 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        }
        view.getBarModelData().barWholes.push(barWhole);
        
        var verticalProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, verticalId);
        if (verticalProps.visible) 
        {
            view.getBarModelData().verticalBarLabels.push(new BarLabel(getLabelName(verticalId, verticalProps), 0, 1, false, false, BarLabel.BRACKET_STRAIGHT, null, null, verticalProps.color));
        }
        
        if (outValueNameToIds != null) 
        {
            barWhole = view.getBarModelData().barWholes[0];
            var numPartsIds : Array<String> = new Array<String>();
            for (barSegment/* AS3HX WARNING could not determine type for var: barSegment exp: EField(EIdent(barWhole),barSegments) type: null */ in barWhole.barSegments)
            {
                numPartsIds.push(barSegment.id);
            }
            Reflect.setField(outValueNameToIds, totalPartsId, numPartsIds);
            Reflect.setField(outValueNameToIds, horizontalId, [barWhole.barLabels[0].id]);
            
            barWhole = view.getBarModelData().barWholes[1];
            Reflect.setField(outValueNameToIds, unitId, [barWhole.barSegments[0].id, barWhole.barLabels[0].id]);
            
            Reflect.setField(outValueNameToIds, verticalId, [view.getBarModelData().verticalBarLabels[0].id]);
        }
    }
    
    private function drawCommonType5d(view : BarModelView,
            unitId : String,
            differenceId : String,
            verticalId : String,
            totalPartsId : String,
            styleObject : Dynamic,
            outValueNameToIds : Dynamic) : Void
    {
        var totalPartsProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, totalPartsId);
        var numParts : Int = parseInt(totalPartsProps.value);
        var barWhole : BarWhole = getBarWhole(numParts, 1, "firstBar", totalPartsProps.color);
        view.getBarModelData().barWholes.push(barWhole);
        
        barWhole = new BarWhole(false);
        var unitProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, unitId);
        if (unitProps.visible) 
        {
            barWhole.barSegments.push(new BarSegment(1, 1, unitProps.color, null));
            barWhole.barLabels.push(new BarLabel(getLabelName(unitId, unitProps), 0, 0, true, false, BarLabel.BRACKET_NONE, null));
        }
        
        var differenceProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, differenceId);
        if (differenceProps.visible) 
        {
            barWhole.barComparison = new BarComparison(getLabelName(differenceId, differenceProps), "firstBar", numParts - 1, null, differenceProps.color);
        }
        view.getBarModelData().barWholes.push(barWhole);
        
        var verticalProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, verticalId);
        if (verticalProps.visible) 
        {
            view.getBarModelData().verticalBarLabels.push(new BarLabel(getLabelName(verticalId, verticalProps), 0, 1, false, false, BarLabel.BRACKET_STRAIGHT, null, null, verticalProps.color));
        }
        
        if (outValueNameToIds != null) 
        {
            barWhole = view.getBarModelData().barWholes[0];
            var numPartsIds : Array<String> = new Array<String>();
            for (barSegment/* AS3HX WARNING could not determine type for var: barSegment exp: EField(EIdent(barWhole),barSegments) type: null */ in barWhole.barSegments)
            {
                numPartsIds.push(barSegment.id);
            }
            Reflect.setField(outValueNameToIds, totalPartsId, numPartsIds);
            
            barWhole = view.getBarModelData().barWholes[1];
            Reflect.setField(outValueNameToIds, unitId, [barWhole.barSegments[0].id, barWhole.barLabels[0].id]);
            Reflect.setField(outValueNameToIds, differenceId, [barWhole.barComparison.id]);
            
            Reflect.setField(outValueNameToIds, verticalId, [view.getBarModelData().verticalBarLabels[0].id]);
        }
    }
    
    private function drawCommonType6a(view : BarModelView,
            fractionalLabelId : String,
            totalLabelId : String,
            shadedPartsId : String,
            totalPartsId : String,
            fractionOverShadedPart : Bool,
            styleObject : Dynamic,
            outValueNameToIds : Dynamic) : Void
    {
        var barWhole : BarWhole = new BarWhole(false);
        var i : Int;
        
        // Single bar has some boxes shaded
        var totalPartsProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, totalPartsId);
        var totalParts : Int = parseInt(totalPartsProps.value);
        var shadedPartsProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, shadedPartsId);
        var shadedParts : Int = parseInt(shadedPartsProps.value);
        for (i in 0...totalParts){
            var color : Int = ((i < shadedParts)) ? shadedPartsProps.color : 0xFFFFFF;
            barWhole.barSegments.push(new BarSegment(1, 1, color, null));
        }
        
        var totalLabelProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, totalLabelId);
        if (totalLabelProps.visible) 
        {
            barWhole.barLabels.push(new BarLabel(getLabelName(totalLabelId, totalLabelProps), 0, totalParts - 1, true, true, BarLabel.BRACKET_STRAIGHT, null, null, totalLabelProps.color));
        }
        
        var startFractionalLabelIndex : Int = 0;
        var endFractionalLabelIndex : Int = shadedParts - 1;
        if (!fractionOverShadedPart) 
        {
            startFractionalLabelIndex = shadedParts;
            endFractionalLabelIndex = totalParts - 1;
        }
        var fractionalLabelProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, fractionalLabelId);
        if (fractionalLabelProps.visible) 
        {
            barWhole.barLabels.push(new BarLabel(getLabelName(fractionalLabelId, fractionalLabelProps), startFractionalLabelIndex, endFractionalLabelIndex, 
                    true, false, BarLabel.BRACKET_STRAIGHT, null, null, fractionalLabelProps.color));
        }
        view.getBarModelData().barWholes.push(barWhole);
        
        if (outValueNameToIds != null) 
        {
            barWhole = view.getBarModelData().barWholes[0];
            
            var shadedPartsIds : Array<String> = new Array<String>();
            var numPartsIds : Array<String> = new Array<String>();
            for (i in 0...barWhole.barSegments.length){
                var barSegment : BarSegment = barWhole.barSegments[i];
                if (i < shadedParts) 
                {
                    shadedPartsIds.push(barSegment.id);
                }
                numPartsIds.push(barSegment.id);
            }
            Reflect.setField(outValueNameToIds, shadedPartsId, shadedPartsIds);
            Reflect.setField(outValueNameToIds, totalPartsId, numPartsIds);
            
            Reflect.setField(outValueNameToIds, totalLabelId, [barWhole.barLabels[0].id]);
            Reflect.setField(outValueNameToIds, fractionalLabelId, [barWhole.barLabels[1].id]);
        }
    }
    
    private function drawCommonType6b(view : BarModelView,
            shadedLabelId : String,
            remainderLabelId : String,
            shadedPartsId : String,
            totalPartsId : String,
            styleObject : Dynamic,
            outValueNameToIds : Dynamic) : Void
    {
        var totalPartsProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, totalPartsId);
        var totalParts : Int = parseInt(totalPartsProps.value);
        var shadedPartsProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, shadedPartsId);
        var shadedParts : Int = parseInt(shadedPartsProps.value);
        var barWhole : BarWhole = new BarWhole(false);
        var i : Int;
        for (i in 0...totalParts){
            var color : Int = ((i < shadedParts)) ? shadedPartsProps.color : 0xFFFFFF;
            barWhole.barSegments.push(new BarSegment(1, 1, color, null));
        }
        
        var shadedLabelProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, shadedLabelId);
        if (shadedLabelProps.visible) 
        {
            barWhole.barLabels.push(new BarLabel(getLabelName(shadedLabelId, shadedLabelProps), 0, shadedParts - 1, 
                    true, false, BarLabel.BRACKET_STRAIGHT, null, null, shadedLabelProps.color));
        }
        
        var remainderLabelProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, remainderLabelId);
        if (remainderLabelProps.visible) 
        {
            barWhole.barLabels.push(new BarLabel(getLabelName(remainderLabelId, remainderLabelProps), shadedParts, totalParts - 1, 
                    true, true, BarLabel.BRACKET_STRAIGHT, null, null, remainderLabelProps.color));
        }
        
        view.getBarModelData().barWholes.push(barWhole);
        
        if (outValueNameToIds != null) 
        {
            barWhole = view.getBarModelData().barWholes[0];
            
            var shadedPartsIds : Array<String> = new Array<String>();
            var numPartsIds : Array<String> = new Array<String>();
            for (i in 0...barWhole.barSegments.length){
                var barSegment : BarSegment = barWhole.barSegments[i];
                if (i < shadedParts) 
                {
                    shadedPartsIds.push(barSegment.id);
                }
                numPartsIds.push(barSegment.id);
            }
            Reflect.setField(outValueNameToIds, shadedPartsId, shadedPartsIds);
            Reflect.setField(outValueNameToIds, totalPartsId, numPartsIds);
            
            Reflect.setField(outValueNameToIds, shadedLabelId, [barWhole.barLabels[0].id]);
            Reflect.setField(outValueNameToIds, remainderLabelId, [barWhole.barLabels[1].id]);
        }
    }
    
    private function drawCommonType7a(view : BarModelView,
            remainderLabelId : String,
            shadedLabelId : String,
            shadedPartsId : String,
            unshadedPartsId : String,
            styleObject : Dynamic,
            outValueNameToIds : Dynamic) : Void
    {
        var unshadedProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, unshadedPartsId);
        var shadedProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, shadedPartsId);
        var numUnshadedParts : Int = parseInt(unshadedProps.value);
        var numShadedParts : Int = parseInt(shadedProps.value);
        var barWhole : BarWhole = getBarWhole(numUnshadedParts, 1, null, unshadedProps.color);
        var remainderLabelProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, remainderLabelId);
        if (remainderLabelProps.visible) 
        {
            barWhole.barLabels.push(new BarLabel(getLabelName(remainderLabelId, remainderLabelProps), 0, numUnshadedParts - 1, true, false, BarLabel.BRACKET_STRAIGHT, null, null, remainderLabelProps.color));
        }
        view.getBarModelData().barWholes.push(barWhole);
        
        barWhole = getBarWhole(numShadedParts, 1, null, shadedProps.color);
        var shadedLabelProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, shadedLabelId);
        if (shadedLabelProps.visible) 
        {
            barWhole.barLabels.push(new BarLabel(getLabelName(shadedLabelId, shadedLabelProps), 0, numShadedParts - 1, true, false, BarLabel.BRACKET_STRAIGHT, null, null, shadedLabelProps.color));
        }
        view.getBarModelData().barWholes.push(barWhole);
        
        if (outValueNameToIds != null) 
        {
            barWhole = view.getBarModelData().barWholes[0];
            var unshadedPartsIds : Array<String> = new Array<String>();
            for (barSegment/* AS3HX WARNING could not determine type for var: barSegment exp: EField(EIdent(barWhole),barSegments) type: null */ in barWhole.barSegments)
            {
                unshadedPartsIds.push(barSegment.id);
            }
            Reflect.setField(outValueNameToIds, remainderLabelId, [barWhole.barLabels[0].id]);
            
            barWhole = view.getBarModelData().barWholes[1];
            var shadedPartsIds : Array<String> = new Array<String>();
            for (barSegment/* AS3HX WARNING could not determine type for var: barSegment exp: EField(EIdent(barWhole),barSegments) type: null */ in barWhole.barSegments)
            {
                shadedPartsIds.push(barSegment.id);
            }
            Reflect.setField(outValueNameToIds, shadedPartsId, shadedPartsIds);
            Reflect.setField(outValueNameToIds, unshadedPartsId, unshadedPartsIds);
            
            Reflect.setField(outValueNameToIds, shadedLabelId, [barWhole.barLabels[0].id]);
        }
    }
    
    private function drawCommonType7b(view : BarModelView,
            horizontalId : String,
            verticalId : String,
            shadedPartsId : String,
            unshadedPartsId : String,
            labelFirstBar : Bool,
            styleObject : Dynamic,
            outValueNameToIds : Dynamic) : Void
    {
        var unshadedProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, unshadedPartsId);
        var shadedProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, shadedPartsId);
        var numUnshadedParts : Int = parseInt(unshadedProps.value);
        var numShadedParts : Int = parseInt(shadedProps.value);
        var barToAddLabelTo : BarWhole = null;
        var barWhole : BarWhole = getBarWhole(numUnshadedParts, 1, null, unshadedProps.color);
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
        
        var horizontalProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, horizontalId);
        barToAddLabelTo.barLabels.push(new BarLabel(getLabelName(horizontalId, horizontalProps), 0, barToAddLabelTo.barSegments.length - 1, true, false, BarLabel.BRACKET_STRAIGHT, null, null, horizontalProps.color));
        
        var verticalProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, verticalId);
        if (verticalProps.visible && view.getBarModelData().barWholes.length == 2) 
        {
            view.getBarModelData().verticalBarLabels.push(new BarLabel(getLabelName(verticalId, verticalProps), 0, 1, false, false, BarLabel.BRACKET_STRAIGHT, null, null, verticalProps.color));
        }
        
        if (outValueNameToIds != null) 
        {
            barWhole = view.getBarModelData().barWholes[0];
            var unshadedPartsIds : Array<String> = new Array<String>();
            for (barSegment/* AS3HX WARNING could not determine type for var: barSegment exp: EField(EIdent(barWhole),barSegments) type: null */ in barWhole.barSegments)
            {
                unshadedPartsIds.push(barSegment.id);
            }
            
            barWhole = view.getBarModelData().barWholes[1];
            var shadedPartsIds : Array<String> = new Array<String>();
            for (barSegment/* AS3HX WARNING could not determine type for var: barSegment exp: EField(EIdent(barWhole),barSegments) type: null */ in barWhole.barSegments)
            {
                shadedPartsIds.push(barSegment.id);
            }
            
            Reflect.setField(outValueNameToIds, shadedPartsId, shadedPartsIds);
            Reflect.setField(outValueNameToIds, unshadedPartsId, unshadedPartsIds);
            
            var barWholeIndexWithLabel : Int = ((labelFirstBar)) ? 0 : 1;
            Reflect.setField(outValueNameToIds, horizontalId, [view.getBarModelData().barWholes[barWholeIndexWithLabel].barLabels[0]]);
            Reflect.setField(outValueNameToIds, verticalId, [view.getBarModelData().verticalBarLabels[0].id]);
        }
    }
    
    private function drawCommonType7c(view : BarModelView,
            horizontalId : String,
            differenceId : String,
            shadedPartsId : String,
            unshadedPartsId : String,
            labelFirstBar : Bool,
            styleObject : Dynamic,
            outValueNameToIds : Dynamic) : Void
    {
        var unshadedProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, unshadedPartsId);
        var shadedProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, shadedPartsId);
        var numUnshadedParts : Int = parseInt(unshadedProps.value);
        var numShadedParts : Int = parseInt(shadedProps.value);
        var barToAddLabelTo : BarWhole = null;
        var barWhole : BarWhole = getBarWhole(numUnshadedParts, 1, "firstBar", unshadedProps.color);
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
        
        var differenceProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, differenceId);
        if (differenceProps.visible) 
        {
            barWhole.barComparison = new BarComparison(getLabelName(differenceId, differenceProps), "firstBar", numUnshadedParts - 1, null, differenceProps.color);
        }
        
        var horizontalProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, horizontalId);
        if (horizontalProps.visible) 
        {
            barToAddLabelTo.barLabels.push(new BarLabel(getLabelName(horizontalId, horizontalProps), 0, 
                    barToAddLabelTo.barSegments.length - 1, true, false, BarLabel.BRACKET_STRAIGHT, null, null, horizontalProps.color));
        }
        
        view.getBarModelData().barWholes.push(barWhole);
        
        if (outValueNameToIds != null) 
        {
            barWhole = view.getBarModelData().barWholes[0];
            var unshadedPartsIds : Array<String> = new Array<String>();
            for (barSegment/* AS3HX WARNING could not determine type for var: barSegment exp: EField(EIdent(barWhole),barSegments) type: null */ in barWhole.barSegments)
            {
                unshadedPartsIds.push(barSegment.id);
            }
            
            barWhole = view.getBarModelData().barWholes[1];
            var shadedPartsIds : Array<String> = new Array<String>();
            for (barSegment/* AS3HX WARNING could not determine type for var: barSegment exp: EField(EIdent(barWhole),barSegments) type: null */ in barWhole.barSegments)
            {
                shadedPartsIds.push(barSegment.id);
            }
            Reflect.setField(outValueNameToIds, shadedPartsId, shadedPartsIds);
            Reflect.setField(outValueNameToIds, unshadedPartsId, unshadedPartsIds);
            Reflect.setField(outValueNameToIds, differenceId, [barWhole.barComparison.id]);
            
            var barWholeIndexWithLabel : Int = ((labelFirstBar)) ? 0 : 1;
            Reflect.setField(outValueNameToIds, horizontalId, [view.getBarModelData().barWholes[barWholeIndexWithLabel].barLabels[0]]);
        }
    }
    
    private function drawCommonType7d(view : BarModelView,
            verticalId : String,
            differenceId : String,
            shadedPartsId : String,
            unshadedPartsId : String,
            styleObject : Dynamic,
            outValueNameToIds : Dynamic) : Void
    {
        var unshadedProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, unshadedPartsId);
        var shadedProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, shadedPartsId);
        var numUnshadedParts : Int = parseInt(unshadedProps.value);
        var numShadedParts : Int = parseInt(shadedProps.value);
        var barWhole : BarWhole = getBarWhole(numUnshadedParts, 1, "firstBar");
        view.getBarModelData().barWholes.push(barWhole);
        
        barWhole = getBarWhole(numShadedParts, 1, null, shadedProps.color);
        var differenceProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, differenceId);
        if (differenceProps.visible) 
        {
            barWhole.barComparison = new BarComparison(getLabelName(differenceId, differenceProps), "firstBar", numUnshadedParts - 1, null, differenceProps.color);
        }
        view.getBarModelData().barWholes.push(barWhole);
        
        var verticalProps : BarModelTypeDrawerProperties = Reflect.field(styleObject, verticalId);
        if (verticalProps.visible && view.getBarModelData().barWholes.length == 2) 
        {
            view.getBarModelData().verticalBarLabels.push(new BarLabel(getLabelName(verticalId, verticalProps), 0, 1, false, false, BarLabel.BRACKET_STRAIGHT, null, null, verticalProps.color));
        }
        
        if (outValueNameToIds != null) 
        {
            barWhole = view.getBarModelData().barWholes[0];
            var unshadedPartsIds : Array<String> = new Array<String>();
            for (barSegment/* AS3HX WARNING could not determine type for var: barSegment exp: EField(EIdent(barWhole),barSegments) type: null */ in barWhole.barSegments)
            {
                unshadedPartsIds.push(barSegment.id);
            }
            
            barWhole = view.getBarModelData().barWholes[1];
            var shadedPartsIds : Array<String> = new Array<String>();
            for (barSegment/* AS3HX WARNING could not determine type for var: barSegment exp: EField(EIdent(barWhole),barSegments) type: null */ in barWhole.barSegments)
            {
                shadedPartsIds.push(barSegment.id);
            }
            Reflect.setField(outValueNameToIds, shadedPartsId, shadedPartsIds);
            Reflect.setField(outValueNameToIds, unshadedPartsId, unshadedPartsIds);
            Reflect.setField(outValueNameToIds, differenceId, [barWhole.barComparison.id]);
            Reflect.setField(outValueNameToIds, verticalId, [view.getBarModelData().verticalBarLabels[0].id]);
        }
    }
    
    /**
     * Helper to get a bar with n number of equal sized segments
     */
    private function getBarWhole(numParts : Int = 1,
            valuePerSegment : Int = 1,
            id : String = null,
            color : Int = 0xFFFFFF) : BarWhole
    {
        var barWhole : BarWhole = new BarWhole(false, id);
        var i : Int;
        for (i in 0...numParts){
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
    private function checkValueGreaterThan(greaterElement : String,
            lesserElement : String,
            barModelTypeProperties : Dynamic,
            elementToAliasMap : Dynamic) : Bool
    {
        var greaterElementValue : Int = parseFloat(Reflect.field(elementToAliasMap, greaterElement));
        var lesserElementValue : Int = parseFloat(Reflect.field(elementToAliasMap, lesserElement));
        return greaterElementValue > lesserElementValue;
    }
    
    private function checkValueInRange(element : String,
            barModelTypeProperties : Dynamic,
            elementToAliasMap : Dynamic) : Bool
    {
        var elementProperties : BarModelTypeDrawerProperties = Reflect.field(barModelTypeProperties, element);
        var elementValue : Float = parseFloat(Reflect.field(elementToAliasMap, element));
        var restrictions : Dynamic = elementProperties.restrictions;
        var inRange : Bool = true;
        if (restrictions.exists("min")) 
        {
            inRange = elementValue >= restrictions.min;
        }
        
        if (restrictions.exists("max")) 
        {
            inRange = elementValue <= restrictions.max;
        }
        return inRange;
    }
    
    private function getLabelName(id : String, styles : BarModelTypeDrawerProperties) : String
    {
        if (styles.alias != null) 
        {
            var name : String = styles.alias;
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
