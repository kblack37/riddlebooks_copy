package wordproblem.engine.level
{
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
    public class LevelCompiler
    {
        private var m_expressionCompiler:IExpressionTreeCompiler;
        
        /**
         * Mapping from a name of a layout to the attributes data to create that layout
         * The purpose of this is to provide levels with a menu of predefined ui configurations. Thus a level
         * xml just needs to define the layout name rather than re-specifying the entire ui xml structure.
         */
        private var m_predefinedLayoutMap:Dictionary;
        
        public function LevelCompiler(expressionCompiler:IExpressionTreeCompiler, predefinedLayoutData:String)
        {
            m_expressionCompiler = expressionCompiler;
            
            // Parse out layout options
            // Each option should have a name, levels can pick a predefined layout by referencing this name
            m_predefinedLayoutMap = new Dictionary();
            var predefinedLayoutXML:XML = new XML(predefinedLayoutData);
            var predefinedLayoutList:XMLList = predefinedLayoutXML.elements("layout");
            var predefinedLayout:XML;
            var numPredefinedLayouts:int = predefinedLayoutList.length();
            var i:int;
            for (i = 0; i < numPredefinedLayouts; i++)
            {
                predefinedLayout = predefinedLayoutList[i];
                
                var layoutName:String = predefinedLayout.@name.toString();
                m_predefinedLayoutMap[layoutName] = parseWidgetLayout(predefinedLayout);
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
        public function compileWordProblemLevel(levelConfig:XML,
                                                name:String,
                                                levelIndex:int,
                                                chapterIndex:int,
                                                genreId:String,
                                                config:AlgebraAdventureConfig, 
                                                scriptParser:ScriptParser, 
                                                textParser:TextParser, 
                                                objectives:Vector.<BaseObjective>=null):WordProblemLevelData
        {
            var levelId:int = -1;
            if (levelConfig.hasOwnProperty("@id"))
            {
                levelId = parseInt(levelConfig.@id);
            }
            else
            {
                trace("WARNING: The level " + name + " has no qid, log data may not be able to tell us which level was played!");
            }
            
            // Bar model levels will need to map to correct bin the pdf
            var barModelType:String = (levelConfig.hasOwnProperty("@barModelType")) ? levelConfig.@barModelType : null;
            
            // Parse out the variable symbols to use
            const vectorSpace:IVectorSpace = m_expressionCompiler.getVectorSpace();
            const symbolBindings:Vector.<SymbolData> = new Vector.<SymbolData>();
            const symbolBindingsList:XMLList = levelConfig.elements("symbols").elements("symbol");
            for each (var symbolBinding:XML in symbolBindingsList)
            {
                // Treat empty string as same as null for some values
                var symbolValue:String = symbolBinding.attribute("value");
                var symbolName:String = (symbolBinding.hasOwnProperty("@name")) ?
                    symbolBinding.attribute("name") : symbolValue;
                var symbolAbbreviatedName:String = (symbolBinding.hasOwnProperty("@abbreviatedName")) ?
                    symbolBinding.attribute("abbreviatedName") : symbolValue;
                var symbolTexture:String = (symbolBinding.hasOwnProperty("@symbolTexture")) ? 
                    symbolBinding.attribute("symbolTexture") : null;
                var symbolBackgroundTexturePositive:String = (symbolBinding.hasOwnProperty("@backgroundTexturePositive")) ?
                    symbolBinding.attribute("backgroundTexturePositive") : "card_background_square";
                if (symbolBackgroundTexturePositive == "")
                {
                    symbolBackgroundTexturePositive = "card_background_square";
                }
                var symbolBackgroundTextureNegative:String = (symbolBinding.hasOwnProperty("@backgroundTextureNegative")) ?
                    symbolBinding.attribute("backgroundTextureNegative") : symbolBackgroundTexturePositive;
                if (symbolBackgroundTextureNegative == "")
                {
                    symbolBackgroundTextureNegative = null;
                }
                
                // Set optional properties for font colors and size, if not set they go to default values
                var defaultSymbolAttributes:CardAttributes = CardAttributes.DEFAULT_CARD_ATTRIBUTES;
                var symbolBackgroundColor:uint = (symbolBinding.hasOwnProperty("@backgroundColor")) ?
                    parseInt(symbolBinding.attribute("backgroundColor"), 16) : 0xFFFFFF;
                var symbolFontName:String = (symbolBinding.hasOwnProperty("@fontName")) ?
                    symbolBinding.attribute("fontName") : defaultSymbolAttributes.defaultFontName;
                var symbolFontColorPositive:uint = (symbolBinding.hasOwnProperty("@fontColorPositive")) ?
                    parseInt(symbolBinding.attribute("fontColorPositive"), 16) : defaultSymbolAttributes.defaultPositiveTextColor;
                var symbolFontColorNegative:uint = (symbolBinding.hasOwnProperty("@fontColorNegative")) ?
                    parseInt(symbolBinding.attribute("fontColorNegative"), 16) : defaultSymbolAttributes.defaultNegativeTextColor;
                var symbolFontSize:int = (symbolBinding.hasOwnProperty("@fontSize")) ?
                    parseInt(symbolBinding.attribute("fontSize")) : defaultSymbolAttributes.defaultFontSize;
                
                
                // Need to create positive and negative binding at this point
                // TODO: May not always want to do this automatically, negative version are unnecessary in some cases
                // Allow in the config whether to create the negative symbol
                var positiveSymbolData:SymbolData = new SymbolData(
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
                positiveSymbolData.useCustomBarColor = (symbolBinding.hasOwnProperty("@useCustomBarColor")) ?
                    symbolBinding.attribute("useCustomBarColor") == "true" : false;
                if (symbolBinding.hasOwnProperty("@customBarColor"))
                {
                    var colorString:String = symbolBinding.attribute("customBarColor");
                    positiveSymbolData.customBarColor = parseInt(colorString, 16);
                }
                symbolBindings.push(positiveSymbolData);
                
                // If card is negative, append minus symbol to name and the abbreviation (if applicable)
                var negativeSymbolData:SymbolData = new SymbolData(
                    vectorSpace.getSubtractionOperator() + symbolValue,
                    (symbolName != "") ? "-" + symbolName : "",
                    (symbolAbbreviatedName != null) ? "-" + symbolAbbreviatedName : null,
                    symbolTexture,
                    symbolBackgroundTextureNegative,
                    symbolBackgroundColor,
                    symbolFontName
                );
                negativeSymbolData.fontColor = symbolFontColorNegative;
                negativeSymbolData.fontSize = symbolFontSize;
                symbolBindings.push(negativeSymbolData);
                
                // Optional setting if the texture itself should get a color
                var hasSymbolTextureColor:Boolean = symbolBinding.hasOwnProperty("@symbolColor");
                if (hasSymbolTextureColor)
                {
                    var symbolColor:uint = parseInt(symbolBinding.attribute("symbolColor"));
                    positiveSymbolData.symbolTextureColor = symbolColor;
                    negativeSymbolData.symbolTextureColor = symbolColor;
                }
                
                // Optional setting if terms of this type should have a specific bar color
                var hasCustomBarColor:Boolean = symbolBinding.hasOwnProperty("@barColor");
                if (hasCustomBarColor)
                {
                    var barColor:uint = parseInt(symbolBinding.attribute("barColor"), 16);
                    positiveSymbolData.customBarColor = barColor;
                    negativeSymbolData.customBarColor = barColor;
                }
            }
            
            // Parse scripting data
            var scriptXml:XML = levelConfig.elements("script")[0];
            var scriptHead:XML = scriptXml.elements("scriptedActions")[0];
            var scriptRoot:ScriptNode = scriptParser.parse(scriptHead);

            // TODO: This is hacky, default width should be part of the style info
            var defaultWidth:Number = 500;
            
            // Parse out the style json and apply the styles to the problem
            // Config should have provided default styles.
            // HACK: For now, if one of the three genres automatically use a default styling
            var cssObject:Object;
            var styleXML:XML = levelConfig.elements("style")[0];
            var defaultStyle:String = config.getDefaultTextStyle();
            var styleData:String = (styleXML != null) ? styleXML.text()[0] : defaultStyle;
            cssObject = JSON.parse(styleData);
            
            // Parse the main textual and visual content describing the word problem
            var paragraph:XML = levelConfig.elements("wordproblem")[0];
            var pageRootNodes:Vector.<DocumentNode> = new Vector.<DocumentNode>();
            var pageList:XMLList = paragraph.children();
            for (i = 0; i < pageList.length(); i++)
            {
                var pageXML:XML = pageList[i];
                pageRootNodes.push(textParser.parseDocument(pageXML, defaultWidth));
            }
            
            var imagesToLoad:Vector.<String> = new Vector.<String>();
            for each (var pageRoot:DocumentNode in pageRootNodes)
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
            var layoutXML:XML = levelConfig.elements("layout")[0];
            var layoutData:WidgetAttributesComponent;
            if (layoutXML != null)
            {
                if (layoutXML.hasOwnProperty("@name"))
                {
                    layoutData = getLayoutFromName(layoutXML.@name.toString()).clone(vectorSpace);
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
                var overrideLayoutAttributes:XML = levelConfig.elements("overrideLayoutAttributes")[0];
                if (overrideLayoutAttributes != null)
                {
                    if (overrideLayoutAttributes.hasOwnProperty("@name"))
                    {
                        layoutData = getLayoutFromName(overrideLayoutAttributes.@name.toString()).clone(vectorSpace);
                    }
                    else
                    {
                        layoutData = getLayoutFromName("default").clone(vectorSpace);
                    }
                    
                    const overrideChildren:XMLList = overrideLayoutAttributes.children();
                    const numOverrideChildren:int = overrideChildren.length();
                    var i:int;
                    for (i = 0; i < numOverrideChildren; i++)
                    {
                        // Find the id of component and overwrite the attributes specified in the file
                        const overrideChildXML:XML = overrideChildren[i];
                        const idToFind:String = overrideChildXML.@id;
                        const componentToOverride:WidgetAttributesComponent = getWidgetAttributeComponent(layoutData, idToFind);
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
            }
            
            // load up the background images for the various widgets
            loadImages(layoutData, imagesToLoad);
            function loadImages(widgetAttributes:WidgetAttributesComponent, outImages:Vector.<String>):void
            {
                const widgetSources:Vector.<Object> = widgetAttributes.getResourceSourceList();
                for (i = 0; i < widgetSources.length; i++)
                {
                    if (widgetSources[i].type == "url")
                    {
                        imagesToLoad.push(widgetSources[i].name);
                    }
                }
                
                if (widgetAttributes.children != null)
                {
                    for each (var childWidgetAttributes:WidgetAttributesComponent in widgetAttributes.children)
                    {
                        loadImages(childWidgetAttributes, outImages);
                    }
                }
            }
            
            // Parse all the resources required by the level script
            // This is required so the level can pre-load those assets even if its possible
            // the script using those resource is never executed
            const audioToLoad:Vector.<Object> = new Vector.<Object>();
            const textureAtlasesToLoad:Vector.<Vector.<String>> = new Vector.<Vector.<String>>();
            const resourcesXML:XML = levelConfig.elements("resources")[0];
            if (resourcesXML != null)
            {
                const resourceXMLList:XMLList = resourcesXML.children();
                var resourceXML:XML;
                for (i = 0; i < resourceXMLList.length(); i++)
                {
                    resourceXML = resourceXMLList[i];
                    const resourceType:String = resourceXML.name();
                    if (resourceType == "img")
                    {
                        imagesToLoad.push(resourceXML.@src);
                    }
                    else if (resourceType == "audio")
                    {
                        var audioSource:String = resourceXML.@src;
                        var audioType:String = resourcesXML.@type;
                        var audioData:Object = {
                            type: audioType,
                            src: audioSource
                        };
                        audioToLoad.push(audioData);
                    }
                    else if (resourceType == "textureAtlas")
                    {
                        textureAtlasesToLoad.push(Vector.<String>([resourceXML.@src, resourceXML.@xml]));
                    }
                }
            }
            
            // TODO: Add default audio, background music specific to the genre if none is specified
            if (audioToLoad.length == 0)
            {
                
            }
            
            // Check if the level overrides the default card rendering attributes.
            const cardXML:XML = levelConfig.elements("cardAttributes")[0];
            const defaultCardAttributes:CardAttributes = CardAttributes.DEFAULT_CARD_ATTRIBUTES;
            const cardAttributes:CardAttributes = (cardXML != null) ?
                parseCardAttributes(cardXML, defaultCardAttributes) : defaultCardAttributes;
            
            // Parse the level rules, see what initial values need to be overridden
            var rulesXml:XML = levelConfig.elements("rules")[0];
            var defaultRules:LevelRules = config.getDefaultLevelRules();
            var levelRules:LevelRules = (rulesXml != null) ?
                LevelRules.createRulesFromXml(rulesXml, defaultRules) : defaultRules;
            
            var levelData:WordProblemLevelData = new WordProblemLevelData(
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
            var objectivesXml:XML = levelConfig.elements("objectives")[0];
            if (objectivesXml != null)
            {
                ObjectivesFactory.getObjectivesFromXml(objectivesXml, levelData.objectives);
            }
            
            // Objectives are bound to a particular level, they are polled from the logic in the script node.
            if (scriptRoot is BaseCustomLevelScript)
            {
                (scriptRoot as BaseCustomLevelScript).getObjectives(levelData.objectives);
            }
            
            if (objectives != null)
            {
                for each (var additionalObjective:BaseObjective in objectives)
                {
                    levelData.objectives.push(additionalObjective);
                }
            }
            
            return levelData;
        }
        
        /**
         * Parse the attributes related to the rendering of the cards.
         */
        public function parseCardAttributes(xml:XML, 
                                            defaultAttributes:CardAttributes):CardAttributes
        {
            const defaultPositiveCardElement:XML = xml.elements("defaultCardPositiveBg")[0];
            if (defaultPositiveCardElement != null)
            {
                var defaultPositiveCardBgId:String = defaultPositiveCardElement.@src;
                var defaultPositiveCardColor:uint = parseInt(defaultPositiveCardElement.@color, 16);
                var defaultPostiveTextColor:uint = parseInt(defaultPositiveCardElement.@textColor, 16);
            }
            else
            {
                defaultPositiveCardBgId = defaultAttributes.defaultPositiveCardBgId;
                defaultPositiveCardColor = defaultAttributes.defaultPositiveCardColor;
                defaultPostiveTextColor = defaultAttributes.defaultPositiveTextColor;
            }
            
            const defaultNegativeCardElement:XML = xml.elements("defaultCardNegativeBg")[0];
            if (defaultNegativeCardElement != null)
            {
                var defaultNegativeCardBgId:String = defaultNegativeCardElement.@src;
                var defaultNegativeCardColor:uint = parseInt(defaultNegativeCardElement.@color, 16);
                var defaultNegativeTextColor:uint = parseInt(defaultNegativeCardElement.@textColor, 16);
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
                "Verdana"//GameFonts.DEFAULT_FONT_NAME
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
        public function parseWidgetLayout(xml:XML):WidgetAttributesComponent
        {
            // Create the attribute structure for the current element
            const widgetAttributes:WidgetAttributesComponent = parseWidgetAttributes(xml);
            
            // If the tag is a group, then it acts as a container for other widgets.
            // Note that we currently assume any containers have no other functionality other
            // than holding other widgets.
            const tagName:String = xml.name();
            if (tagName == "group" || tagName == "layout")
            {
                const childrenAttributes:Vector.<WidgetAttributesComponent> = new Vector.<WidgetAttributesComponent>();
                const childElements:XMLList = xml.children();
                const numChildren:int = childElements.length();
                var i:int;
                var childAttributes:WidgetAttributesComponent;
                for (i = 0; i < numChildren; i++)
                {
                    childAttributes = this.parseWidgetLayout(childElements[i]);
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
        private function getWidgetAttributeComponent(rootComponent:WidgetAttributesComponent, 
                                                     idToFind:String):WidgetAttributesComponent
        {
            var component:WidgetAttributesComponent;
            if (rootComponent != null)
            {
                if (rootComponent.entityId == idToFind)
                {
                    component = rootComponent;
                }
                else if (rootComponent.children != null)
                {
                    var i:int;
                    for (i = 0; i < rootComponent.children.length; i++)
                    {
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
        
        private function overwriteWidgetAttributes(xml:XML, component:WidgetAttributesComponent):void
        {
            if (xml.hasOwnProperty("@width"))
            {
                const widthExpression:String = xml.@width;
                component.widthRoot = m_expressionCompiler.compile(widthExpression).head;
            }
            
            if (xml.hasOwnProperty("@height"))
            {
                const heightExpression:String = xml.@height;
                component.heightRoot = m_expressionCompiler.compile(heightExpression).head;
            }
            
            if (xml.hasOwnProperty("@x"))
            {
                const xExpression:String = xml.@x;
                component.xRoot = m_expressionCompiler.compile(xExpression).head;
            }
            
            if (xml.hasOwnProperty("@y"))
            {
                const yExpression:String = xml.@y;
                component.yRoot = m_expressionCompiler.compile(yExpression).head; 
            }
            
            if (xml.hasOwnProperty("@viewportWidth"))
            {
                component.viewportWidth = parseInt(xml.@viewportWidth);
            }
            
            if (xml.hasOwnProperty("@viewportHeight"))
            {
                component.viewportHeight = parseInt(xml.@viewportHeight);
            }
            
            if (xml.hasOwnProperty("@src"))
            {
                component.setResourceSourceList(xml.@src);
            }
            
            if (xml.hasOwnProperty("@visible"))
            {
                component.visible = XString.stringToBool(xml.@visible);
            }
            
            if (xml.hasOwnProperty("@backgroundAttachment"))
            {
                component.extraData.backgroundAttachment = xml.@backgroundAttachment;   
            }
            
            if (xml.hasOwnProperty("@backgroundRepeat"))
            {
                component.extraData.backgroundRepeat = xml.@backgroundRepeat;   
            }
            
            if (xml.hasOwnProperty("@autoCenterPages"))
            {
                component.extraData.autoCenterPages = XString.stringToBool(xml.@autoCenterPages);   
            }
            
            if (xml.hasOwnProperty("@autoShowPrevNextButtons"))
            {
                component.extraData.autoShowPrevNextButtons = XString.stringToBool(xml.@autoShowPrevNextButtons);   
            }
            
            if (xml.hasOwnProperty("@allowScroll"))
            {
                component.extraData.allowScroll = XString.stringToBool(xml.@allowScroll); 
            }
        }
        
        /**
         * Parse the attributes of the given xml tag. Only looks at the top level tag, not
         * any potential children.
         */
        private function parseWidgetAttributes(xml:XML):WidgetAttributesComponent
        {
            const type:String = xml.name();
            const id:String = xml.@id;
            const width:ExpressionNode = xml.hasOwnProperty("@width") ? 
                m_expressionCompiler.compile(xml.@width).head : null;
            const height:ExpressionNode = xml.hasOwnProperty("@height") ?
                m_expressionCompiler.compile(xml.@height).head : null;
            const xExpression:String = xml.hasOwnProperty("@x") ? xml.@x : "0";
            const x:ExpressionNode = m_expressionCompiler.compile(xExpression).head;
            const yExpression:String = xml.hasOwnProperty("@y") ? xml.@y : "0";
            const y:ExpressionNode = m_expressionCompiler.compile(yExpression).head;
            const viewportWidth:Number = xml.hasOwnProperty("@viewportWidth") ? parseInt(xml.@viewportWidth) : -1;
            const viewportHeight:Number = xml.hasOwnProperty("@viewportHeight") ? parseInt(xml.@viewportHeight) : -1;
            const backgroundSource:String = xml.hasOwnProperty("@src") ? xml.@src : null;
            const visible:Boolean = xml.hasOwnProperty("@visible") ? XString.stringToBool(xml.@visible) : true;
            
            var extraData:Object = {};
            
            if (type == "textArea")
            {
                // Appending extra properties to the widget
                // (Right now this is just to get extra arguments into the text area)
                extraData.backgroundAttachment = xml.hasOwnProperty("@backgroundAttachment") ? xml.@backgroundAttachment : "scroll";
                extraData.backgroundRepeat = xml.hasOwnProperty("@backgroundRepeat") ? xml.@backgroundRepeat : "repeat";
                extraData.autoCenterPages = xml.hasOwnProperty("@autoCenterPages") ? XString.stringToBool(xml.@autoCenterPages) : true;
                extraData.allowScroll = xml.hasOwnProperty("@allowScroll") ? XString.stringToBool(xml.@allowScroll) : true;
            }
            
            if (type == "button")
            {
                extraData.label = xml.hasOwnProperty("@label") ? xml.@label : null;
                extraData.fontName = xml.hasOwnProperty("@fontName") ? xml.@fontName : "Verdana";
                extraData.fontColor = xml.hasOwnProperty("@fontColor") ? parseInt(xml.@fontColor, 16) : 0x000000;
                extraData.fontSize = xml.hasOwnProperty("@fontSize") ? parseInt(xml.@fontSize) : 12;
                extraData.nineSlice = xml.hasOwnProperty("@nineSlice") ? xml.@nineSlice : null;
            }
            
            if (type == "barModelArea")
            {
                extraData.unitLength = xml.hasOwnProperty("@unitLength") ? parseInt(xml.@unitLength) : 100;
                extraData.unitHeight = xml.hasOwnProperty("@unitHeight") ? parseInt(xml.@unitHeight) : 40;
                extraData.topBarPadding = xml.hasOwnProperty("@topBarPadding") ? parseInt(xml.@topBarPadding) : 10;
                extraData.leftBarPadding = xml.hasOwnProperty("@leftBarPadding") ? parseInt(xml.@leftBarPadding) : 60;
                extraData.barGap = xml.hasOwnProperty("@barGap") ? parseInt(xml.@barGap) : 30;
            }
            
            const attributes:WidgetAttributesComponent = new WidgetAttributesComponent(
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
        private function getLayoutFromName(layoutName:String):WidgetAttributesComponent
        {
            
            return (m_predefinedLayoutMap.hasOwnProperty(layoutName)) ?
                m_predefinedLayoutMap[layoutName] : m_predefinedLayoutMap["default"];
        }
    }
}