package wordproblem.engine.level;

import wordproblem.engine.level.LevelRules;
import wordproblem.engine.level.WordProblemLevelData;

import flash.utils.Dictionary;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.math.vectorspace.IVectorSpace;
import dragonbox.common.util.XString;

import wordproblem.AlgebraAdventureConfig;
import wordproblem.engine.component.WidgetAttributesComponent;
import wordproblem.engine.expression.SymbolData;
import wordproblem.engine.objectives.BaseObjective;
import wordproblem.engine.objectives.ObjectivesFactory;
import wordproblem.engine.scripting.ScriptParser;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.text.TextParser;
import wordproblem.engine.text.model.DocumentNode;
import wordproblem.scripts.level.BaseCustomLevelScript;

/**
 * The compiler reads in raw formatted level configurations like xml or json and
 * converts them into the data structures readable for other parts of the game.
 */
class LevelCompiler
{
    private var m_expressionCompiler : IExpressionTreeCompiler;
    
    /**
     * Mapping from a name of a layout to the attributes data to create that layout
     * The purpose of this is to provide levels with a menu of predefined ui configurations. Thus a level
     * xml just needs to define the layout name rather than re-specifying the entire ui xml structure.
     */
    private var m_predefinedLayoutMap : Dictionary;
    
    public function new(expressionCompiler : IExpressionTreeCompiler, predefinedLayoutData : String)
    {
        m_expressionCompiler = expressionCompiler;
        
        // Parse out layout options
        // Each option should have a name, levels can pick a predefined layout by referencing this name
        m_predefinedLayoutMap = new Dictionary();
        var predefinedLayoutXML : FastXML = new FastXML(predefinedLayoutData);
        var predefinedLayoutList : FastXMLList = predefinedLayoutXML.node.elements.innerData("layout");
        var predefinedLayout : FastXML;
        var numPredefinedLayouts : Int = predefinedLayoutList.length();
        var i : Int;
        for (i in 0...numPredefinedLayouts){
            predefinedLayout = predefinedLayoutList.get(i);
            
            var layoutName : String = Std.string(predefinedLayout.att.name);
            Reflect.setField(m_predefinedLayoutMap, layoutName, parseWidgetLayout(predefinedLayout));
        }
    }
    
    /**
     * Compile a single configuration for the word problem mode
     * 
     * @param levelConfig
     *      The XML definition of a word problem level
     * @param name
     *      The name is a way to link this level data to a level progression system so we can locate
     *      where the player is in the progression graph just from the compiled data
     * @param levelIndex
     *      The zero based index of this level in the parent chapter. Used for level labeling purposes
     * @param chapterIndex
     *      The zero based index of the chapter that contains this level. Used for level labeling purposes.
     *      Negative if no chapter.
     * @param genreId
     *      The name of the genre/shelf that contains this level. Used primarily for stylistic settings,
     *      like how the summary screen should be drawn.
     * @param config
     *      The config holds default values that are applied to each level unless explicitly
     *      overridden
     * @param objectives
     *      List of custom goal objectives not baked into the xml (mostly from the level manager in order to apply
     *      goals across many levels in the same set)
     */
    public function compileWordProblemLevel(levelConfig : FastXML,
            name : String,
            levelIndex : Int,
            chapterIndex : Int,
            genreId : String,
            config : AlgebraAdventureConfig,
            scriptParser : ScriptParser,
            textParser : TextParser,
            objectives : Array<BaseObjective> = null) : WordProblemLevelData
    {
        var levelId : Int = -1;
        if (levelConfig.node.exists.innerData("@id")) 
        {
            levelId = parseInt(levelConfig.att.id);
        }
        else 
        {
            trace("WARNING: The level " + name + " has no qid, log data may not be able to tell us which level was played!");
        }  // Bar model levels will need to map to correct bin the pdf  
        
        
        
        var barModelType : String = ((levelConfig.node.exists.innerData("@barModelType"))) ? levelConfig.att.barModelType : null;
        
        // Parse out the variable symbols to use
        var vectorSpace : IVectorSpace = m_expressionCompiler.getVectorSpace();
        var symbolBindings : Array<SymbolData> = new Array<SymbolData>();
        var symbolBindingsList : FastXMLList = levelConfig.node.elements.innerData("symbols").elements("symbol");
        for (symbolBinding in symbolBindingsList)
        {
            // Treat empty string as same as null for some values
            var symbolValue : String = symbolBinding.node.attribute.innerData("value");
            var symbolName : String = ((symbolBinding.node.exists.innerData("@name"))) ? 
            symbolBinding.node.attribute.innerData("name") : symbolValue;
            var symbolAbbreviatedName : String = ((symbolBinding.node.exists.innerData("@abbreviatedName"))) ? 
            symbolBinding.node.attribute.innerData("abbreviatedName") : symbolValue;
            var symbolTexture : String = ((symbolBinding.node.exists.innerData("@symbolTexture"))) ? 
            symbolBinding.node.attribute.innerData("symbolTexture") : null;
            var symbolBackgroundTexturePositive : String = ((symbolBinding.node.exists.innerData("@backgroundTexturePositive"))) ? 
            symbolBinding.node.attribute.innerData("backgroundTexturePositive") : "card_background_square";
            if (symbolBackgroundTexturePositive == "") 
            {
                symbolBackgroundTexturePositive = "card_background_square";
            }
            var symbolBackgroundTextureNegative : String = ((symbolBinding.node.exists.innerData("@backgroundTextureNegative"))) ? 
            symbolBinding.node.attribute.innerData("backgroundTextureNegative") : symbolBackgroundTexturePositive;
            if (symbolBackgroundTextureNegative == "") 
            {
                symbolBackgroundTextureNegative = null;
            }  // Set optional properties for font colors and size, if not set they go to default values  
            
            
            
            var defaultSymbolAttributes : CardAttributes = CardAttributes.DEFAULT_CARD_ATTRIBUTES;
            var symbolBackgroundColor : Int = ((symbolBinding.node.exists.innerData("@backgroundColor"))) ? 
            parseInt(symbolBinding.node.attribute.innerData("backgroundColor"), 16) : 0xFFFFFF;
            var symbolFontName : String = ((symbolBinding.node.exists.innerData("@fontName"))) ? 
            symbolBinding.node.attribute.innerData("fontName") : defaultSymbolAttributes.defaultFontName;
            var symbolFontColorPositive : Int = ((symbolBinding.node.exists.innerData("@fontColorPositive"))) ? 
            parseInt(symbolBinding.node.attribute.innerData("fontColorPositive"), 16) : defaultSymbolAttributes.defaultPositiveTextColor;
            var symbolFontColorNegative : Int = ((symbolBinding.node.exists.innerData("@fontColorNegative"))) ? 
            parseInt(symbolBinding.node.attribute.innerData("fontColorNegative"), 16) : defaultSymbolAttributes.defaultNegativeTextColor;
            var symbolFontSize : Int = ((symbolBinding.node.exists.innerData("@fontSize"))) ? 
            parseInt(symbolBinding.node.attribute.innerData("fontSize")) : defaultSymbolAttributes.defaultFontSize;
            
            
            // Need to create positive and negative binding at this point
            // TODO: May not always want to do this automatically, negative version are unnecessary in some cases
            // Allow in the config whether to create the negative symbol
            var positiveSymbolData : SymbolData = new SymbolData(
            symbolValue, 
            symbolName, 
            symbolAbbreviatedName, 
            symbolTexture, 
            symbolBackgroundTexturePositive, 
            symbolBackgroundColor, 
            symbolFontName
            );
            positiveSymbolData.fontColor = symbolFontColorPositive;
            positiveSymbolData.fontSize = symbolFontSize;
            positiveSymbolData.useCustomBarColor = ((symbolBinding.node.exists.innerData("@useCustomBarColor"))) ? 
                    symbolBinding.node.attribute.innerData("useCustomBarColor") == "true" : false;
            if (symbolBinding.node.exists.innerData("@customBarColor")) 
            {
                var colorString : String = symbolBinding.node.attribute.innerData("customBarColor");
                positiveSymbolData.customBarColor = parseInt(colorString, 16);
            }
            symbolBindings.push(positiveSymbolData);
            
            // If card is negative, append minus symbol to name and the abbreviation (if applicable)
            var negativeSymbolData : SymbolData = new SymbolData(
            vectorSpace.getSubtractionOperator() + symbolValue, 
            ((symbolName != "")) ? "-" + symbolName : "", 
            ((symbolAbbreviatedName != null)) ? "-" + symbolAbbreviatedName : null, 
            symbolTexture, 
            symbolBackgroundTextureNegative, 
            symbolBackgroundColor, 
            symbolFontName
            );
            negativeSymbolData.fontColor = symbolFontColorNegative;
            negativeSymbolData.fontSize = symbolFontSize;
            symbolBindings.push(negativeSymbolData);
            
            // Optional setting if the texture itself should get a color
            var hasSymbolTextureColor : Bool = symbolBinding.node.exists.innerData("@symbolColor");
            if (hasSymbolTextureColor) 
            {
                var symbolColor : Int = parseInt(symbolBinding.node.attribute.innerData("symbolColor"));
                positiveSymbolData.symbolTextureColor = symbolColor;
                negativeSymbolData.symbolTextureColor = symbolColor;
            }  // Optional setting if terms of this type should have a specific bar color  
            
            
            
            var hasCustomBarColor : Bool = symbolBinding.node.exists.innerData("@barColor");
            if (hasCustomBarColor) 
            {
                var barColor : Int = parseInt(symbolBinding.node.attribute.innerData("barColor"), 16);
                positiveSymbolData.customBarColor = barColor;
                negativeSymbolData.customBarColor = barColor;
            }
        }  // Parse scripting data  
        
        
        
        var scriptXml : FastXML = levelConfig.nodes.elements("script")[0];
        var scriptHead : FastXML = scriptXml.nodes.elements("scriptedActions")[0];
        var scriptRoot : ScriptNode = scriptParser.parse(scriptHead);
        
        // TODO: This is hacky, default width should be part of the style info
        var defaultWidth : Float = 500;
        
        // Parse out the style json and apply the styles to the problem
        // Config should have provided default styles.
        // HACK: For now, if one of the three genres automatically use a default styling
        var cssObject : Dynamic;
        var styleXML : FastXML = levelConfig.nodes.elements("style")[0];
        var defaultStyle : String = config.getDefaultTextStyle();
        var styleData : String = ((styleXML != null)) ? styleXML.nodes.text()[0] : defaultStyle;
        cssObject = haxe.Json.parse(styleData);
        
        // Parse the main textual and visual content describing the word problem
        var paragraph : FastXML = levelConfig.nodes.elements("wordproblem")[0];
        var pageRootNodes : Array<DocumentNode> = new Array<DocumentNode>();
        var pageList : FastXMLList = paragraph.node.children.innerData();
        for (i in 0...pageList.length()){
            var pageXML : FastXML = pageList.get(i);
            pageRootNodes.push(textParser.parseDocument(pageXML, defaultWidth));
        }
        
        var imagesToLoad : Array<String> = new Array<String>();
        for (pageRoot in pageRootNodes)
        {
            textParser.applyStyleAndLayout(pageRoot, cssObject);
            textParser.getImagesToLoad(pageRoot, imagesToLoad);
        }  // Parse layout data and other miscellaneous assets needed by the level    // * do nothing which just picks the default layout    // * pick an existing ui layout from a predefined list without an override (add a name attribute)    // * define its own layout using a layout tag (provide no name attribute)    // * choose to override properties from an existing ui layout using an override tag    // A level can  
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        var layoutXML : FastXML = levelConfig.nodes.elements("layout")[0];
        var layoutData : WidgetAttributesComponent;
        if (layoutXML != null) 
        {
            if (layoutXML.node.exists.innerData("@name")) 
            {
                layoutData = getLayoutFromName(Std.string(layoutXML.att.name)).clone(vectorSpace);
            }
            else 
            {
                layoutData = parseWidgetLayout(layoutXML);
            }
        }
        else 
        {
            // It is possible that a level just wants to override a few of the properties of
            // several widgets without wanting to respecify the entire layout again.
            // To facilitate this, we search for an override tag. Components with a matching id
            // will take on the new values specified in the override. This does not affect the
            // layout structure though.
            var overrideLayoutAttributes : FastXML = levelConfig.nodes.elements("overrideLayoutAttributes")[0];
            if (overrideLayoutAttributes != null) 
            {
                if (overrideLayoutAttributes.node.exists.innerData("@name")) 
                {
                    layoutData = getLayoutFromName(Std.string(overrideLayoutAttributes.att.name)).clone(vectorSpace);
                }
                else 
                {
                    layoutData = getLayoutFromName("default").clone(vectorSpace);
                }
                
                var overrideChildren : FastXMLList = overrideLayoutAttributes.node.children.innerData();
                var numOverrideChildren : Int = overrideChildren.length();
                var i : Int;
                for (i in 0...numOverrideChildren){
                    // Find the id of component and overwrite the attributes specified in the file
                    var overrideChildXML : FastXML = overrideChildren.get(i);
                    var idToFind : String = overrideChildXML.att.id;
                    var componentToOverride : WidgetAttributesComponent = getWidgetAttributeComponent(layoutData, idToFind);
                    if (componentToOverride != null) 
                    {
                        overwriteWidgetAttributes(overrideChildXML, componentToOverride);
                    }
                }
            }
            else 
            {
                layoutData = getLayoutFromName("default").clone(vectorSpace);
            }
        }  // load up the background images for the various widgets  
        
        
        
        loadImages(layoutData, imagesToLoad);
        function loadImages(widgetAttributes : WidgetAttributesComponent, outImages : Array<String>) : Void
        {
            var widgetSources : Array<Dynamic> = widgetAttributes.getResourceSourceList();
            for (i in 0...widgetSources.length){
                if (widgetSources[i].type == "url") 
                {
                    imagesToLoad.push(widgetSources[i].name);
                }
            }
            
            if (widgetAttributes.children != null) 
            {
                for (childWidgetAttributes/* AS3HX WARNING could not determine type for var: childWidgetAttributes exp: EField(EIdent(widgetAttributes),children) type: null */ in widgetAttributes.children)
                {
                    loadImages(childWidgetAttributes, outImages);
                }
            }
        }  // the script using those resource is never executed    // This is required so the level can pre-load those assets even if its possible    // Parse all the resources required by the level script  ;
        
        
        
        
        
        
        
        var audioToLoad : Array<Dynamic> = new Array<Dynamic>();
        var textureAtlasesToLoad : Array<Array<String>> = new Array<Array<String>>();
        var resourcesXML : FastXML = levelConfig.nodes.elements("resources")[0];
        if (resourcesXML != null) 
        {
            var resourceXMLList : FastXMLList = resourcesXML.node.children.innerData();
            var resourceXML : FastXML;
            for (i in 0...resourceXMLList.length()){
                resourceXML = resourceXMLList.get(i);
                var resourceType : String = resourceXML.node.name.innerData();
                if (resourceType == "img") 
                {
                    imagesToLoad.push(resourceXML.att.src);
                }
                else if (resourceType == "audio") 
                {
                    var audioSource : String = resourceXML.att.src;
                    var audioType : String = resourcesXML.att.type;
                    var audioData : Dynamic = {
                        type : audioType,
                        src : audioSource,

                    };
                    audioToLoad.push(audioData);
                }
                else if (resourceType == "textureAtlas") 
                {
                    textureAtlasesToLoad.push([resourceXML.att.src, resourceXML.att.xml]);
                }
            }
        }  // TODO: Add default audio, background music specific to the genre if none is specified  
        
        
        
        if (audioToLoad.length == 0) 
            { }  // Check if the level overrides the default card rendering attributes.  
        
        
        
        var cardXML : FastXML = levelConfig.nodes.elements("cardAttributes")[0];
        var defaultCardAttributes : CardAttributes = CardAttributes.DEFAULT_CARD_ATTRIBUTES;
        var cardAttributes : CardAttributes = ((cardXML != null)) ? 
        parseCardAttributes(cardXML, defaultCardAttributes) : defaultCardAttributes;
        
        // Parse the level rules, see what initial values need to be overridden
        var rulesXml : FastXML = levelConfig.nodes.elements("rules")[0];
        var defaultRules : LevelRules = config.getDefaultLevelRules();
        var levelRules : LevelRules = ((rulesXml != null)) ? 
        LevelRules.createRulesFromXml(rulesXml, defaultRules) : defaultRules;
        
        var levelData : WordProblemLevelData = new WordProblemLevelData(
        levelId, 
        levelIndex, 
        chapterIndex, 
        genreId, 
        name, 
        pageRootNodes, 
        cssObject, 
        symbolBindings, 
        scriptRoot, 
        imagesToLoad, 
        audioToLoad, 
        textureAtlasesToLoad, 
        layoutData, 
        cardAttributes, 
        levelRules, 
        barModelType
        );
        
        // TODO: Should overwriting be occuring? Right now just append everything
        // Objectives can either be encoded in the xml, the attached script, or get passed in
        // as extra data from another script
        
        // Parse out objectives that have been manually defined in a level
        // Objectives are not only goals the player can view at the end, but they are also
        // thesholds to determine satisfactory completion.
        var objectivesXml : FastXML = levelConfig.nodes.elements("objectives")[0];
        if (objectivesXml != null) 
        {
            ObjectivesFactory.getObjectivesFromXml(objectivesXml, levelData.objectives);
        }  // Objectives are bound to a particular level, they are polled from the logic in the script node.  
        
        
        
        if (Std.is(scriptRoot, BaseCustomLevelScript)) 
        {
            (try cast(scriptRoot, BaseCustomLevelScript) catch(e:Dynamic) null).getObjectives(levelData.objectives);
        }
        
        if (objectives != null) 
        {
            for (additionalObjective in objectives)
            {
                levelData.objectives.push(additionalObjective);
            }
        }
        
        return levelData;
    }
    
    /**
     * Parse the attributes related to the rendering of the cards.
     */
    public function parseCardAttributes(xml : FastXML,
            defaultAttributes : CardAttributes) : CardAttributes
    {
        var defaultPositiveCardElement : FastXML = xml.nodes.elements("defaultCardPositiveBg")[0];
        if (defaultPositiveCardElement != null) 
        {
            var defaultPositiveCardBgId : String = defaultPositiveCardElement.att.src;
            var defaultPositiveCardColor : Int = parseInt(defaultPositiveCardElement.att.color, 16);
            var defaultPostiveTextColor : Int = parseInt(defaultPositiveCardElement.att.textColor, 16);
        }
        else 
        {
            defaultPositiveCardBgId = defaultAttributes.defaultPositiveCardBgId;
            defaultPositiveCardColor = defaultAttributes.defaultPositiveCardColor;
            defaultPostiveTextColor = defaultAttributes.defaultPositiveTextColor;
        }
        
        var defaultNegativeCardElement : FastXML = xml.nodes.elements("defaultCardNegativeBg")[0];
        if (defaultNegativeCardElement != null) 
        {
            var defaultNegativeCardBgId : String = defaultNegativeCardElement.att.src;
            var defaultNegativeCardColor : Int = parseInt(defaultNegativeCardElement.att.color, 16);
            var defaultNegativeTextColor : Int = parseInt(defaultNegativeCardElement.att.textColor, 16);
        }
        else 
        {
            defaultNegativeCardBgId = defaultAttributes.defaultNegativeCardBgId;
            defaultNegativeCardColor = defaultAttributes.defaultNegativeCardColor;
            defaultNegativeTextColor = defaultAttributes.defaultNegativeTextColor;
        }
        
        return new CardAttributes(
        defaultPositiveCardBgId, 
        defaultPositiveCardColor, 
        defaultPostiveTextColor, 
        defaultNegativeCardBgId, 
        defaultNegativeCardColor, 
        defaultNegativeTextColor, 
        32, 
        "Verdana"  //GameFonts.DEFAULT_FONT_NAME  , 
        );
    }
    
    /**
     * Parse the xml describing the layout structure
     * 
     * @param xml
     *      The xml representing the a node in the layout tree
     * @return
     *      The layout component struct containing the attributes for the layout node.
     *      Nested inside of it is the children widgets inside of it.
     */
    public function parseWidgetLayout(xml : FastXML) : WidgetAttributesComponent
    {
        // Create the attribute structure for the current element
        var widgetAttributes : WidgetAttributesComponent = parseWidgetAttributes(xml);
        
        // If the tag is a group, then it acts as a container for other widgets.
        // Note that we currently assume any containers have no other functionality other
        // than holding other widgets.
        var tagName : String = xml.node.name.innerData();
        if (tagName == "group" || tagName == "layout") 
        {
            var childrenAttributes : Array<WidgetAttributesComponent> = new Array<WidgetAttributesComponent>();
            var childElements : FastXMLList = xml.node.children.innerData();
            var numChildren : Int = childElements.length();
            var i : Int;
            var childAttributes : WidgetAttributesComponent;
            for (i in 0...numChildren){
                childAttributes = this.parseWidgetLayout(childElements.get(i));
                childAttributes.parent = widgetAttributes;
                childrenAttributes.push(childAttributes);
            }
            
            widgetAttributes.children = childrenAttributes;
        }
        
        return widgetAttributes;
    }
    
    /**
     * Find the component with the matching id within the given component layout structure
     * 
     * @return
     *      null if no component matches the given id
     */
    private function getWidgetAttributeComponent(rootComponent : WidgetAttributesComponent,
            idToFind : String) : WidgetAttributesComponent
    {
        var component : WidgetAttributesComponent;
        if (rootComponent != null) 
        {
            if (rootComponent.entityId == idToFind) 
            {
                component = rootComponent;
            }
            else if (rootComponent.children != null) 
            {
                var i : Int;
                for (i in 0...rootComponent.children.length){
                    component = getWidgetAttributeComponent(rootComponent.children[i], idToFind);
                    if (component != null) 
                    {
                        break;
                    }
                }
            }
        }
        
        return component;
    }
    
    private function overwriteWidgetAttributes(xml : FastXML, component : WidgetAttributesComponent) : Void
    {
        if (xml.node.exists.innerData("@width")) 
        {
            var widthExpression : String = xml.att.width;
            component.widthRoot = m_expressionCompiler.compile(widthExpression).head;
        }
        
        if (xml.node.exists.innerData("@height")) 
        {
            var heightExpression : String = xml.att.height;
            component.heightRoot = m_expressionCompiler.compile(heightExpression).head;
        }
        
        if (xml.node.exists.innerData("@x")) 
        {
            var xExpression : String = xml.att.x;
            component.xRoot = m_expressionCompiler.compile(xExpression).head;
        }
        
        if (xml.node.exists.innerData("@y")) 
        {
            var yExpression : String = xml.att.y;
            component.yRoot = m_expressionCompiler.compile(yExpression).head;
        }
        
        if (xml.node.exists.innerData("@viewportWidth")) 
        {
            component.viewportWidth = parseInt(xml.att.viewportWidth);
        }
        
        if (xml.node.exists.innerData("@viewportHeight")) 
        {
            component.viewportHeight = parseInt(xml.att.viewportHeight);
        }
        
        if (xml.node.exists.innerData("@src")) 
        {
            component.setResourceSourceList(xml.att.src);
        }
        
        if (xml.node.exists.innerData("@visible")) 
        {
            component.visible = XString.stringToBool(xml.att.visible);
        }
        
        if (xml.node.exists.innerData("@backgroundAttachment")) 
        {
            component.extraData.backgroundAttachment = xml.att.backgroundAttachment;
        }
        
        if (xml.node.exists.innerData("@backgroundRepeat")) 
        {
            component.extraData.backgroundRepeat = xml.att.backgroundRepeat;
        }
        
        if (xml.node.exists.innerData("@autoCenterPages")) 
        {
            component.extraData.autoCenterPages = XString.stringToBool(xml.att.autoCenterPages);
        }
        
        if (xml.node.exists.innerData("@autoShowPrevNextButtons")) 
        {
            component.extraData.autoShowPrevNextButtons = XString.stringToBool(xml.att.autoShowPrevNextButtons);
        }
        
        if (xml.node.exists.innerData("@allowScroll")) 
        {
            component.extraData.allowScroll = XString.stringToBool(xml.att.allowScroll);
        }
    }
    
    /**
     * Parse the attributes of the given xml tag. Only looks at the top level tag, not
     * any potential children.
     */
    private function parseWidgetAttributes(xml : FastXML) : WidgetAttributesComponent
    {
        var type : String = xml.node.name.innerData();
        var id : String = xml.att.id;
        var width : ExpressionNode = (xml.node.exists.innerData("@width")) ? 
        m_expressionCompiler.compile(xml.att.width).head : null;
        var height : ExpressionNode = (xml.node.exists.innerData("@height")) ? 
        m_expressionCompiler.compile(xml.att.height).head : null;
        var xExpression : String = (xml.node.exists.innerData("@x")) ? xml.att.x : "0";
        var x : ExpressionNode = m_expressionCompiler.compile(xExpression).head;
        var yExpression : String = (xml.node.exists.innerData("@y")) ? xml.att.y : "0";
        var y : ExpressionNode = m_expressionCompiler.compile(yExpression).head;
        var viewportWidth : Float = (xml.node.exists.innerData("@viewportWidth")) ? parseInt(xml.att.viewportWidth) : -1;
        var viewportHeight : Float = (xml.node.exists.innerData("@viewportHeight")) ? parseInt(xml.att.viewportHeight) : -1;
        var backgroundSource : String = (xml.node.exists.innerData("@src")) ? xml.att.src : null;
        var visible : Bool = (xml.node.exists.innerData("@visible")) ? XString.stringToBool(xml.att.visible) : true;
        
        var extraData : Dynamic = { };
        
        if (type == "textArea") 
        {
            // Appending extra properties to the widget
            // (Right now this is just to get extra arguments into the text area)
            extraData.backgroundAttachment = (xml.node.exists.innerData("@backgroundAttachment")) ? xml.att.backgroundAttachment : "scroll";
            extraData.backgroundRepeat = (xml.node.exists.innerData("@backgroundRepeat")) ? xml.att.backgroundRepeat : "repeat";
            extraData.autoCenterPages = (xml.node.exists.innerData("@autoCenterPages")) ? XString.stringToBool(xml.att.autoCenterPages) : true;
            extraData.allowScroll = (xml.node.exists.innerData("@allowScroll")) ? XString.stringToBool(xml.att.allowScroll) : true;
        }
        
        if (type == "button") 
        {
            extraData.label = (xml.node.exists.innerData("@label")) ? xml.att.label : null;
            extraData.fontName = (xml.node.exists.innerData("@fontName")) ? xml.att.fontName : "Verdana";
            extraData.fontColor = (xml.node.exists.innerData("@fontColor")) ? parseInt(xml.att.fontColor, 16) : 0x000000;
            extraData.fontSize = (xml.node.exists.innerData("@fontSize")) ? parseInt(xml.att.fontSize) : 12;
            extraData.nineSlice = (xml.node.exists.innerData("@nineSlice")) ? xml.att.nineSlice : null;
        }
        
        if (type == "barModelArea") 
        {
            extraData.unitLength = (xml.node.exists.innerData("@unitLength")) ? parseInt(xml.att.unitLength) : 100;
            extraData.unitHeight = (xml.node.exists.innerData("@unitHeight")) ? parseInt(xml.att.unitHeight) : 40;
            extraData.topBarPadding = (xml.node.exists.innerData("@topBarPadding")) ? parseInt(xml.att.topBarPadding) : 10;
            extraData.leftBarPadding = (xml.node.exists.innerData("@leftBarPadding")) ? parseInt(xml.att.leftBarPadding) : 60;
            extraData.barGap = (xml.node.exists.innerData("@barGap")) ? parseInt(xml.att.barGap) : 30;
        }
        
        var attributes : WidgetAttributesComponent = new WidgetAttributesComponent(
        id, 
        type, 
        width, 
        height, 
        x, 
        y, 
        viewportWidth, 
        viewportHeight, 
        backgroundSource, 
        visible, 
        extraData
        );
        
        return attributes;
    }
    
    /**
     * Get a particular ui layout from a name
     * 
     * @return
     *      The default layout if no layout with the given name is found
     */
    private function getLayoutFromName(layoutName : String) : WidgetAttributesComponent
    {
        
        return ((m_predefinedLayoutMap.exists(layoutName))) ? 
        Reflect.field(m_predefinedLayoutMap, layoutName) : Reflect.field(m_predefinedLayoutMap, "default");
    }
}
