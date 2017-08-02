package wordproblem.engine.level;

import dragonbox.common.math.vectorspace.RealsVectorSpace;
import haxe.xml.Fast;
import wordproblem.engine.level.LevelRules;
import wordproblem.engine.level.WordProblemLevelData;

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
    private var m_predefinedLayoutMap : Map<String, WidgetAttributesComponent>;
    
    public function new(expressionCompiler : IExpressionTreeCompiler, predefinedLayoutData : String)
    {
        m_expressionCompiler = expressionCompiler;
        
        // Parse out layout options
        // Each option should have a name, levels can pick a predefined layout by referencing this name
        m_predefinedLayoutMap = new Map();
        var predefinedLayoutXML : Fast = new Fast(Xml.parse(predefinedLayoutData));
        var predefinedLayoutList = predefinedLayoutXML.node.layouts.nodes.layout;
        for (predefinedLayout in predefinedLayoutList){
            var layoutName : String = Std.string(predefinedLayout.att.name);
			m_predefinedLayoutMap.set(layoutName, parseWidgetLayout(predefinedLayout));
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
    public function compileWordProblemLevel(levelConfig : Xml,
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
		var fastLevelConfig = new Fast(levelConfig);
        if (levelConfig.exists("id")) 
        {
            levelId = Std.parseInt(fastLevelConfig.att.id);
        }
        else 
        {
            trace("WARNING: The level " + name + " has no qid, log data may not be able to tell us which level was played!");
        }
		
		// Bar model levels will need to map to correct bin the pdf  
        var barModelType : String = fastLevelConfig.has.barModelType ? fastLevelConfig.att.barModelType : null;
        
        // Parse out the variable symbols to use
        var vectorSpace : RealsVectorSpace = m_expressionCompiler.getVectorSpace();
        var symbolBindings : Array<SymbolData> = new Array<SymbolData>();
        var symbolBindingsList = fastLevelConfig.node.symbols.nodes.symbol;
        for (symbolBinding in symbolBindingsList)
        {
            // Treat empty string as same as null for some values
            var symbolValue : String = symbolBinding.att.value;
            var symbolName : String = symbolBinding.has.name ? 
				symbolBinding.att.name : symbolValue;
            var symbolAbbreviatedName : String = symbolBinding.has.abbreviatedName ? 
				symbolBinding.att.abbreviatedName : symbolValue;
            var symbolTexture : String = symbolBinding.has.symbolTexture ? 
				symbolBinding.att.symbolTexture : null;
            var symbolBackgroundTexturePositive : String = symbolBinding.has.backgroundTexturePositive ? 
				symbolBinding.att.backgroundTexturePositive : "card_background_square";
            if (symbolBackgroundTexturePositive == "") 
            {
                symbolBackgroundTexturePositive = "card_background_square";
            }
            var symbolBackgroundTextureNegative : String = symbolBinding.has.backgroundTextureNegative ? 
				symbolBinding.att.backgroundTextureNegative : symbolBackgroundTexturePositive;
            if (symbolBackgroundTextureNegative == "") 
            {
                symbolBackgroundTextureNegative = null;
            }
			
			// Set optional properties for font colors and size, if not set they go to default values  
            var defaultSymbolAttributes : CardAttributes = CardAttributes.DEFAULT_CARD_ATTRIBUTES;
            var symbolBackgroundColor : Int = symbolBinding.has.backgroundColor ? 
				Std.parseInt(symbolBinding.att.backgroundColor) : 0xFFFFFF;
            var symbolFontName : String = symbolBinding.has.fontName ? 
				symbolBinding.att.fontName : defaultSymbolAttributes.defaultFontName;
            var symbolFontColorPositive : Int = symbolBinding.has.fontColorPositive ? 
				Std.parseInt(symbolBinding.att.fontColorPositive) : defaultSymbolAttributes.defaultPositiveTextColor;
            var symbolFontColorNegative : Int = symbolBinding.has.fontColorNegative ? 
				Std.parseInt(symbolBinding.att.fontColorNegative) : defaultSymbolAttributes.defaultNegativeTextColor;
            var symbolFontSize : Int = symbolBinding.has.fontSize ? 
				Std.parseInt(symbolBinding.att.fontSize) : defaultSymbolAttributes.defaultFontSize;
            
            
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
            positiveSymbolData.useCustomBarColor = symbolBinding.has.useCustomBarColor ? 
                    symbolBinding.att.useCustomBarColor == "true" : false;
            if (symbolBinding.has.customBarColor) 
            {
                var colorString : String = symbolBinding.att.customBarColor;
                positiveSymbolData.customBarColor = Std.parseInt(colorString);
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
            var hasSymbolTextureColor : Bool = symbolBinding.has.symbolColor;
            if (hasSymbolTextureColor) 
            {
                var symbolColor : Int = Std.parseInt(symbolBinding.att.symbolColor);
                positiveSymbolData.symbolTextureColor = symbolColor;
                negativeSymbolData.symbolTextureColor = symbolColor;
            }  
			
			// Optional setting if terms of this type should have a specific bar color  
            var hasCustomBarColor : Bool = symbolBinding.has.barColor;
            if (hasCustomBarColor) 
            {
                var barColor : Int = Std.parseInt(symbolBinding.att.barColor);
                positiveSymbolData.customBarColor = barColor;
                negativeSymbolData.customBarColor = barColor;
            }
        }
		
		// Parse scripting data  
        var scriptXml : Fast = fastLevelConfig.node.script;
        var scriptHead : Fast = scriptXml.node.scriptedActions;
        var scriptRoot : ScriptNode = scriptParser.parse(scriptHead.x);
        
        // TODO: This is hacky, default width should be part of the style info
        var defaultWidth : Float = 500;
        
        // Parse out the style json and apply the styles to the problem
        // Config should have provided default styles.
        // HACK: For now, if one of the three genres automatically use a default styling
        var cssObject : Dynamic = null;
        var styleXML : Fast = fastLevelConfig.node.style;
        var defaultStyle : String = config.getDefaultTextStyle();
        var styleData : String = ((styleXML != null)) ? styleXML.innerData : defaultStyle;
        cssObject = haxe.Json.parse(styleData);
        
        // Parse the main textual and visual content describing the word problem
        var paragraph : Fast = fastLevelConfig.node.wordproblem;
        var pageRootNodes : Array<DocumentNode> = new Array<DocumentNode>();
        var pageList = paragraph.elements;
        for (pageXML in pageList){
            pageRootNodes.push(textParser.parseDocument(pageXML, defaultWidth));
        }
        
        var imagesToLoad : Array<String> = new Array<String>();
        for (pageRoot in pageRootNodes)
        {
            textParser.applyStyleAndLayout(pageRoot, cssObject);
            textParser.getImagesToLoad(pageRoot, imagesToLoad);
        }
		
		// A level can  
		// * choose to override properties from an existing ui layout using an override tag
		// * define its own layout using a layout tag (provide no name attribute)
		// * pick an existing ui layout from a predefined list without an override (add a name attribute)
		// * do nothing which just picks the default layout
        // Parse layout data and other miscellaneous assets needed by the level
        var layoutXML : Fast = fastLevelConfig.hasNode.layout ? fastLevelConfig.node.layout : null;
        var layoutData : WidgetAttributesComponent = null;
        if (layoutXML != null) 
        {
            if (layoutXML.has.name) 
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
            var overrideLayoutAttributes : Fast = fastLevelConfig.node.overrideLayoutAttributes;
            if (overrideLayoutAttributes != null) 
            {
                if (overrideLayoutAttributes.has.name) 
                {
                    layoutData = getLayoutFromName(overrideLayoutAttributes.att.name).clone(vectorSpace);
                }
                else 
                {
                    layoutData = getLayoutFromName("default").clone(vectorSpace);
                }
                
                var overrideChildren = overrideLayoutAttributes.elements;
                for (overrideChild in overrideChildren){
                    // Find the id of component and overwrite the attributes specified in the file
                    var idToFind : String = overrideChild.att.id;
                    var componentToOverride : WidgetAttributesComponent = getWidgetAttributeComponent(layoutData, idToFind);
                    if (componentToOverride != null) 
                    {
                        overwriteWidgetAttributes(overrideChild, componentToOverride);
                    }
                }
            }
            else 
            {
                layoutData = getLayoutFromName("default").clone(vectorSpace);
            }
        }
		
		// load up the background images for the various widgets  
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
        };
        
        loadImages(layoutData, imagesToLoad);
        
		// Parse all the resources required by the level script  ;
		// This is required so the level can pre-load those assets even if its possible
        // the script using those resource is never executed
        var audioToLoad : Array<Dynamic> = new Array<Dynamic>();
        var textureAtlasesToLoad : Array<Array<String>> = new Array<Array<String>>();
        var resourcesXML : Fast = fastLevelConfig.node.resources;
        if (resourcesXML != null) 
        {
            var resourceXMLList = resourcesXML.elements;
            for (resourceXML in resourceXMLList){
                var resourceType : String = resourceXML.name;
                if (resourceType == "img") 
                {
                    imagesToLoad.push(resourceXML.att.src);
                }
                else if (resourceType == "audio") 
                {
                    var audioSource : String = resourceXML.att.src;
                    var audioType : String = resourceXML.att.type;
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
        }
		
		// TODO: Add default audio, background music specific to the genre if none is specified  
        if (audioToLoad.length == 0) 
            { }
			
		// Check if the level overrides the default card rendering attributes.  
        var defaultCardAttributes : CardAttributes = CardAttributes.DEFAULT_CARD_ATTRIBUTES;
        var cardAttributes : CardAttributes = fastLevelConfig.hasNode.cardAttributes ? 
			parseCardAttributes(fastLevelConfig.node.cardAttributes, defaultCardAttributes) : defaultCardAttributes;
        
        // Parse the level rules, see what initial values need to be overridden
        var defaultRules : LevelRules = config.getDefaultLevelRules();
        var levelRules : LevelRules = fastLevelConfig.hasNode.rules ? 
			LevelRules.createRulesFromXml(fastLevelConfig.node.rules, defaultRules) : defaultRules;
        
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
        if (fastLevelConfig.hasNode.objectives) 
        {
            ObjectivesFactory.getObjectivesFromXml(fastLevelConfig.node.objectives, levelData.objectives);
        }
		
		// Objectives are bound to a particular level, they are polled from the logic in the script node.  
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
    public function parseCardAttributes(xml : Fast,
            defaultAttributes : CardAttributes) : CardAttributes
    {
        var defaultPositiveCardElement : Fast = xml.node.defaultCardPositiveBg;
		var defaultPositiveCardBgId : String = null;
		var defaultPositiveCardColor : Int = 0;
		var defaultPositiveTextColor : Int = 0;
        if (defaultPositiveCardElement != null) 
        {
            defaultPositiveCardBgId = defaultPositiveCardElement.att.src;
            defaultPositiveCardColor = Std.parseInt(defaultPositiveCardElement.att.color);
            defaultPositiveTextColor = Std.parseInt(defaultPositiveCardElement.att.textColor);
        }
        else 
        {
            defaultPositiveCardBgId = defaultAttributes.defaultPositiveCardBgId;
            defaultPositiveCardColor = defaultAttributes.defaultPositiveCardColor;
            defaultPositiveTextColor = defaultAttributes.defaultPositiveTextColor;
        }
        
        var defaultNegativeCardElement : Fast = xml.node.defaultCardNegativeBg;
		var defaultNegativeCardBgId : String = null;
		var defaultNegativeCardColor : Int = 0;
		var defaultNegativeTextColor : Int = 0;
        if (defaultNegativeCardElement != null) 
        {
            defaultNegativeCardBgId = defaultNegativeCardElement.att.src;
            defaultNegativeCardColor = Std.parseInt(defaultNegativeCardElement.att.color);
            defaultNegativeTextColor = Std.parseInt(defaultNegativeCardElement.att.textColor);
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
			defaultPositiveTextColor, 
			defaultNegativeCardBgId, 
			defaultNegativeCardColor, 
			defaultNegativeTextColor, 
			32, 
			"Verdana"  //GameFonts.DEFAULT_FONT_NAME
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
    public function parseWidgetLayout(xml : Fast) : WidgetAttributesComponent
    {
        // Create the attribute structure for the current element
        var widgetAttributes : WidgetAttributesComponent = parseWidgetAttributes(xml);
        
        // If the tag is a group, then it acts as a container for other widgets.
        // Note that we currently assume any containers have no other functionality other
        // than holding other widgets.
        var tagName : String = xml.name;
        if (tagName == "group" || tagName == "layout") 
        {
            var childrenAttributes : Array<WidgetAttributesComponent> = new Array<WidgetAttributesComponent>();
            var childElements = xml.elements;
            var childAttributes : WidgetAttributesComponent = null;
            for (childElement in childElements){
                childAttributes = this.parseWidgetLayout(childElement);
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
        var component : WidgetAttributesComponent = null;
        if (rootComponent != null) 
        {
            if (rootComponent.entityId == idToFind) 
            {
                component = rootComponent;
            }
            else if (rootComponent.children != null) 
            {
                var i : Int = 0;
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
    
    private function overwriteWidgetAttributes(xml : Fast, component : WidgetAttributesComponent) : Void
    {
        if (xml.has.width) 
        {
            var widthExpression : String = xml.att.width;
            component.widthRoot = m_expressionCompiler.compile(widthExpression);
        }
        
        if (xml.has.height) 
        {
            var heightExpression : String = xml.att.height;
            component.heightRoot = m_expressionCompiler.compile(heightExpression);
        }
        
        if (xml.has.x) 
        {
            var xExpression : String = xml.att.x;
            component.xRoot = m_expressionCompiler.compile(xExpression);
        }
        
        if (xml.has.y) 
        {
            var yExpression : String = xml.att.y;
            component.yRoot = m_expressionCompiler.compile(yExpression);
        }
        
        if (xml.has.viewportWidth) 
        {
            component.viewportWidth = Std.parseInt(xml.att.viewportWidth);
        }
        
        if (xml.has.viewportHeight) 
        {
            component.viewportHeight = Std.parseInt(xml.att.viewportHeight);
        }
        
        if (xml.has.src) 
        {
            component.setResourceSourceList(xml.att.src);
        }
        
        if (xml.has.visible) 
        {
            component.visible = XString.stringToBool(xml.att.visible);
        }
        
        if (xml.has.backgroundAttachment) 
        {
            component.extraData.backgroundAttachment = xml.att.backgroundAttachment;
        }
        
        if (xml.has.backgroundRepeat) 
        {
            component.extraData.backgroundRepeat = xml.att.backgroundRepeat;
        }
        
        if (xml.has.autoCenterPages) 
        {
            component.extraData.autoCenterPages = XString.stringToBool(xml.att.autoCenterPages);
        }
        
        if (xml.has.autoShowPrevNextButtons) 
        {
            component.extraData.autoShowPrevNextButtons = XString.stringToBool(xml.att.autoShowPrevNextButtons);
        }
        
        if (xml.has.allowScroll) 
        {
            component.extraData.allowScroll = XString.stringToBool(xml.att.allowScroll);
        }
    }
    
    /**
     * Parse the attributes of the given xml tag. Only looks at the top level tag, not
     * any potential children.
     */
    private function parseWidgetAttributes(xml : Fast) : WidgetAttributesComponent
    {
        var type : String = xml.name;
        var id : String = xml.att.id;
        var width : ExpressionNode = xml.has.width ? 
			m_expressionCompiler.compile(xml.att.width) : null;
        var height : ExpressionNode = xml.has.height ? 
			m_expressionCompiler.compile(xml.att.height) : null;
        var xExpression : String = xml.has.x ? xml.att.x : "0";
        var x : ExpressionNode = m_expressionCompiler.compile(xExpression);
        var yExpression : String = xml.has.y ? xml.att.y : "0";
        var y : ExpressionNode = m_expressionCompiler.compile(yExpression);
        var viewportWidth : Float = xml.has.viewportWidth ? Std.parseFloat(xml.att.viewportWidth) : -1;
        var viewportHeight : Float = xml.has.viewportHeight ? Std.parseFloat(xml.att.viewportHeight) : -1;
        var backgroundSource : String = xml.has.src ? xml.att.src : null;
        var visible : Bool = xml.has.visible ? XString.stringToBool(xml.att.visible) : true;
        
        var extraData : Dynamic = { };
        
        if (type == "textArea") 
        {
            // Appending extra properties to the widget
            // (Right now this is just to get extra arguments into the text area)
            extraData.backgroundAttachment = xml.has.backgroundAttachment ? xml.att.backgroundAttachment : "scroll";
            extraData.backgroundRepeat = xml.has.backgroundRepeat ? xml.att.backgroundRepeat : "repeat";
            extraData.autoCenterPages = xml.has.autoCenterPages ? XString.stringToBool(xml.att.autoCenterPages) : true;
            extraData.allowScroll = xml.has.allowScroll ? XString.stringToBool(xml.att.allowScroll) : true;
        }
        
        if (type == "button") 
        {
            extraData.label = xml.has.label ? xml.att.label : null;
            extraData.fontName = xml.has.fontName ? xml.att.fontName : "Verdana";
            extraData.fontColor = xml.has.fontColor ? Std.parseInt(xml.att.fontColor) : 0x000000;
            extraData.fontSize = xml.has.fontSize ? Std.parseInt(xml.att.fontSize) : 12;
            extraData.nineSlice = xml.has.nineSlice ? xml.att.nineSlice : null;
        }
        
        if (type == "barModelArea") 
        {
            extraData.unitLength = xml.has.unitLength ? Std.parseInt(xml.att.unitLength) : 100;
            extraData.unitHeight = xml.has.unitHeight ? Std.parseInt(xml.att.unitHeight) : 40;
            extraData.topBarPadding = xml.has.topBarPadding ? Std.parseInt(xml.att.topBarPadding) : 10;
            extraData.leftBarPadding = xml.has.leftBarPadding ? Std.parseInt(xml.att.leftBarPadding) : 60;
            extraData.barGap = xml.has.barGap ? Std.parseInt(xml.att.barGap) : 30;
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
			m_predefinedLayoutMap.get(layoutName) : m_predefinedLayoutMap.get("default");
    }
}
