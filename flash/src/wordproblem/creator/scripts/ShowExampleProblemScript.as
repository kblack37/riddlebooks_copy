package wordproblem.creator.scripts
{
    import flash.text.TextFormat;
    
    import feathers.controls.Button;
    
    import starling.animation.Transitions;
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.Sprite;
    import starling.events.Event;
    
    import wordproblem.creator.EditableTextArea;
    import wordproblem.creator.ProblemCreateData;
    import wordproblem.creator.ProblemCreateEvent;
    import wordproblem.creator.WordProblemCreateState;
    import wordproblem.creator.WordProblemCreateUtil;
    import wordproblem.engine.barmodel.BarModelTypeDrawer;
    import wordproblem.engine.barmodel.BarModelTypeDrawerProperties;
    import wordproblem.engine.barmodel.view.BarModelView;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.expression.SymbolData;
    import wordproblem.engine.level.CardAttributes;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.resource.AssetManager;
    
    /**
     * This script controls showing/hiding an example word problem that matches a particular
     * bar model type.
     */
    public class ShowExampleProblemScript extends BaseProblemCreateScript
    {
        /**
         * Use this to get the proper colors to apply to each part of the example word problem
         */
        private var m_barModelTypeDrawer:BarModelTypeDrawer;
        
        private var m_exampleBarModelView:BarModelView;
        private var m_exampleExpressionSymbolMap:ExpressionSymbolMap;
        
        /**
         * There is a delay between
         */
        private var m_inMiddleOfSwitch:Boolean;
        
        public function ShowExampleProblemScript(wordProblemCreateState:WordProblemCreateState,
                                                 barModelTypeDrawer:BarModelTypeDrawer,
                                                 assetManager:AssetManager,
                                                 id:String=null, 
                                                 isActive:Boolean=true)
        {
            super(wordProblemCreateState, assetManager, id, isActive);
            
            m_barModelTypeDrawer = barModelTypeDrawer;
        }
        
        override public function visit():int
        {
            return super.visit();
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            if (m_isReady)
            {
                m_createState.removeEventListener(ProblemCreateEvent.BACKGROUND_AND_STYLES_CHANGED, bufferEvent);
                if (value)
                {
                    m_createState.addEventListener(ProblemCreateEvent.BACKGROUND_AND_STYLES_CHANGED, bufferEvent);
                }
            }
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == ProblemCreateEvent.BACKGROUND_AND_STYLES_CHANGED)
            {
                // If the example text is visible we should update the colors immediately
                redraw();
            }
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            setIsActive(m_isActive);
            
            // When the level is ready, need to bind a listener to the
            var currentLevel:ProblemCreateData = m_createState.getCurrentLevel();
            var barModelType:String = currentLevel.barModelType;
            
            // These defaults should be changed later
            var stylePropertiesForBarModelType:Object = m_barModelTypeDrawer.getStyleObjectForType(barModelType);
            
            var showExampleButton:Button = m_createState.getWidgetFromId("showExampleButton") as Button;
            showExampleButton.addEventListener(Event.TRIGGERED, onShowExampleClicked);
            
            // Go through the xml and extract id and value pairings
            var exampleHighlightDataList:Vector.<Object> = new Vector.<Object>();
            var exampleTextArea:EditableTextArea = m_createState.getWidgetFromId("exampleTextArea") as EditableTextArea;
            
            // Pick the correct example xml based on the bar model type.
            // Assume there is a one to one mapping from a type to a singular example
            var exampleProblemXml:XML = m_assetManager.getXml("example_" + barModelType);
            
            // Assume the problem is composed of several paragraphs, each of these paragraphs should
            // go into their own text block
            var i:int;
            var paragraphElements:XMLList = exampleProblemXml.elements("p");
            for (i = 0; i < paragraphElements.length(); i++)
            {
                // Add new text block per paragraph
                // Show the content in the example (make sure the example is not editable)
                exampleTextArea.addTextBlock(exampleTextArea.getConstraints().width, exampleTextArea.getConstraints().height, false, false);
                
                var paragraphElement:XML = paragraphElements[i];
                var highlightDataAdded:Vector.<Object> = WordProblemCreateUtil.addTextFromXmlToBlock(paragraphElement, exampleTextArea, i, stylePropertiesForBarModelType);
                for each (var highlightData:Object in highlightDataAdded)
                {
                    exampleHighlightDataList.push(highlightData);
                }
            }
            
            // The example text is never editable
            exampleTextArea.toggleEditMode(false);
            
            // The highlight objects contain all the aliases, which we will use to populate the example list
            // Note that each individual list element can be added at any other time
            m_exampleExpressionSymbolMap = new ExpressionSymbolMap(m_assetManager);
            m_exampleExpressionSymbolMap.setConfiguration(CardAttributes.DEFAULT_CARD_ATTRIBUTES);
            
            var expressionStyles:Object = m_barModelTypeDrawer.getStyleObjectForType(barModelType);
            for (var idForPart:String in expressionStyles)
            {
                // Alter the card colors to match with the colors in the style info
                var styleForPart:BarModelTypeDrawerProperties = expressionStyles[idForPart];
                var symbolData:SymbolData = m_exampleExpressionSymbolMap.getSymbolDataFromValue(idForPart);
                symbolData.abbreviatedName = idForPart;
            }
            
            // Adjust the style object so alias name gets drawn out in the example
            for (i = 0; i < exampleHighlightDataList.length; i++)
            {
                highlightData = exampleHighlightDataList[i];
                
                var elementId:String = highlightData.id;
                expressionStyles[elementId].value = highlightData.value;
                expressionStyles[elementId].alias = highlightData.value;
                
                var aliasSymbolData:SymbolData = m_exampleExpressionSymbolMap.getSymbolDataFromValue(elementId);
                aliasSymbolData.abbreviatedName = expressionStyles[elementId].alias;
                //aliasSymbolData.backgroundColor = elementSymbolData.backgroundColor;
            }
            
            var realBarModelView:BarModelAreaWidget = m_createState.getWidgetFromId("barModelArea") as BarModelAreaWidget;
            m_exampleBarModelView = new BarModelAreaWidget(m_exampleExpressionSymbolMap, m_assetManager, 
                50, 40, 
                realBarModelView.topBarPadding, 
                realBarModelView.bottomBarPadding, 
                realBarModelView.leftBarPadding, 
                realBarModelView.rightBarPadding, 
                realBarModelView.barGap);
            m_exampleBarModelView.setDimensions(realBarModelView.getConstraints().width, realBarModelView.getConstraints().height);
        }
        
        private function onShowExampleClicked(event:Event):void
        {
            var showExampleButton:Button = event.currentTarget as Button;
            var uiContainer:Sprite = m_createState.getWidgetFromId("uiContainer") as Sprite;
            
            // Clicking the example should hide the original text area (make sure no actions can be performed on it)
            // Show the example text area if it hasn't already been processed
            var exampleTextArea:EditableTextArea = m_createState.getWidgetFromId("exampleTextArea") as EditableTextArea;
            var editableTextArea:EditableTextArea = m_createState.getWidgetFromId("editableTextArea") as EditableTextArea;
            var realBarModelView:BarModelAreaWidget = m_createState.getWidgetFromId("barModelArea") as BarModelAreaWidget;
            var submitButton:DisplayObject = m_createState.getWidgetFromId("submitButton");
            if (exampleTextArea.parent == null)
            {
                editableTextArea.toggleEditMode(false);
                
                // Make the example match the text style of the regular text
                var editableTextAreaStyle:TextFormat = editableTextArea.getTextFormat();
                exampleTextArea.setTextFormatProperties(editableTextAreaStyle.color as uint, editableTextAreaStyle.size as int, editableTextAreaStyle.font);
                
                var textAreaToFadeout:DisplayObject = editableTextArea;
                var textAreaToFadein:DisplayObject = exampleTextArea;
                

                // Mimic the positions of the real parts
                m_exampleBarModelView.x = realBarModelView.x;
                m_exampleBarModelView.y = realBarModelView.y;
                uiContainer.addChild(m_exampleBarModelView);
                
                realBarModelView.visible = false;
                submitButton.visible = false;
                
                showExampleButton.label = "Hide Example";
                
                redraw();
                
                m_createState.dispatchEventWith(ProblemCreateEvent.SHOW_EXAMPLE_START, false, null);
            }
            else
            {
                textAreaToFadeout = exampleTextArea;
                textAreaToFadein = editableTextArea;
                
                m_exampleBarModelView.removeFromParent();
                
                realBarModelView.visible = true;
                submitButton.visible = true;
                
                showExampleButton.label = "Show Example";
                
                m_createState.dispatchEventWith(ProblemCreateEvent.SHOW_EXAMPLE_END, false, null);
            }
            
            // Smoothly animate the text areas fading in or fading out
            // Figure out which parts to fade in or fade out
            var fadeDuration:Number = 0.75;
            var fadeout:Tween = new Tween(textAreaToFadeout, fadeDuration, Transitions.LINEAR);
            textAreaToFadeout.alpha = 1.0;
            textAreaToFadein.alpha = 0.0;
            fadeout.fadeTo(0.0);
            fadeout.onComplete = function():void
            {
                textAreaToFadeout.removeFromParent();
                
                m_createState.addChild(textAreaToFadein);
                
                Starling.juggler.remove(fadeout);
                
                var fadein:Tween = new Tween(textAreaToFadein, fadeDuration, Transitions.LINEAR);
                fadein.fadeTo(1.0);
                Starling.juggler.add(fadein);
                
                if (textAreaToFadein == editableTextArea)
                {
                    fadein.onComplete = function():void
                    {
                        editableTextArea.toggleEditMode(true);
                    };
                }
            };
            Starling.juggler.add(fadeout);
        }
        
        private function redraw():void
        {
            // Here the colors of the text highlights and the bar model should be adjusted so they match
            // the background styles
            var exampleTextArea:EditableTextArea = m_createState.getWidgetFromId("exampleTextArea") as EditableTextArea;
            var currentHighlightColors:Object = null;
            var backgroundStylesData:Object = m_createState.getCurrentLevel().currentlySelectedBackgroundData;
            if (backgroundStylesData != null && backgroundStylesData.hasOwnProperty("highlightColors"))
            {
                currentHighlightColors = backgroundStylesData["highlightColors"];
            }
            
            if (currentHighlightColors != null)
            {
                for (var idForPart:String in currentHighlightColors)
                {
                    m_exampleExpressionSymbolMap.resetTextureForValue(idForPart);
                    var symbolData:SymbolData = m_exampleExpressionSymbolMap.getSymbolDataFromValue(idForPart);
                    symbolData.backgroundColor = currentHighlightColors[idForPart];
                }
            }
            
            var barModelType:String = m_createState.getCurrentLevel().barModelType;
            m_exampleBarModelView.getBarModelData().clear();
            m_barModelTypeDrawer.drawBarModelIntoViewFromType(barModelType, 
                m_exampleBarModelView, 
                m_barModelTypeDrawer.getStyleObjectForType(barModelType, currentHighlightColors));
            m_exampleBarModelView.redraw(false, true);
            
            if (currentHighlightColors != null)
            {
                var activeHighlightsInText:Object = exampleTextArea.getHighlightTextObjects();
                for (var highlightId:String in activeHighlightsInText)
                {
                    if (currentHighlightColors.hasOwnProperty(highlightId))
                    {
                        activeHighlightsInText[highlightId].color = currentHighlightColors[highlightId];
                    }
                }
                exampleTextArea.redrawHighlightsAtCurrentIndices();
            }
        }
    }
}