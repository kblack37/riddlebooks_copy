package wordproblem.creator.scripts;


import flash.text.TextFormat;

import starling.animation.Transitions;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.Button;
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
class ShowExampleProblemScript extends BaseProblemCreateScript
{
    /**
     * Use this to get the proper colors to apply to each part of the example word problem
     */
    private var m_barModelTypeDrawer : BarModelTypeDrawer;
    
    private var m_exampleBarModelView : BarModelView;
    private var m_exampleExpressionSymbolMap : ExpressionSymbolMap;
    
    /**
     * There is a delay between
     */
    private var m_inMiddleOfSwitch : Bool;
    
    public function new(wordProblemCreateState : WordProblemCreateState,
            barModelTypeDrawer : BarModelTypeDrawer,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(wordProblemCreateState, assetManager, id, isActive);
        
        m_barModelTypeDrawer = barModelTypeDrawer;
    }
    
    override public function visit() : Int
    {
        return super.visit();
    }
    
    override public function setIsActive(value : Bool) : Void
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
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == ProblemCreateEvent.BACKGROUND_AND_STYLES_CHANGED) 
        {
            // If the example text is visible we should update the colors immediately
            redraw();
        }
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        setIsActive(m_isActive);
        
        // When the level is ready, need to bind a listener to the
        var currentLevel : ProblemCreateData = m_createState.getCurrentLevel();
        var barModelType : String = currentLevel.barModelType;
        
        // These defaults should be changed later
        var stylePropertiesForBarModelType : Dynamic = m_barModelTypeDrawer.getStyleObjectForType(barModelType);
        
        var showExampleButton : Button = try cast(m_createState.getWidgetFromId("showExampleButton"), Button) catch(e:Dynamic) null;
        showExampleButton.addEventListener(Event.TRIGGERED, onShowExampleClicked);
        
        // Go through the xml and extract id and value pairings
        var exampleHighlightDataList : Array<Dynamic> = new Array<Dynamic>();
        var exampleTextArea : EditableTextArea = try cast(m_createState.getWidgetFromId("exampleTextArea"), EditableTextArea) catch(e:Dynamic) null;
        
        // Pick the correct example xml based on the bar model type.
        // Assume there is a one to one mapping from a type to a singular example
        var exampleProblemXml : FastXML = m_assetManager.getXml("example_" + barModelType);
        
        // Assume the problem is composed of several paragraphs, each of these paragraphs should
        // go into their own text block
        var i : Int = 0;
        var paragraphElements : FastXMLList = exampleProblemXml.node.elements.innerData("p");
        for (i in 0...paragraphElements.length()){
            // Add new text block per paragraph
            // Show the content in the example (make sure the example is not editable)
            exampleTextArea.addTextBlock(exampleTextArea.getConstraints().width, exampleTextArea.getConstraints().height, false, false);
            
            var paragraphElement : FastXML = paragraphElements.get(i);
            var highlightDataAdded : Array<Dynamic> = WordProblemCreateUtil.addTextFromXmlToBlock(paragraphElement, exampleTextArea, i, stylePropertiesForBarModelType);
            for (highlightData in highlightDataAdded)
            {
                exampleHighlightDataList.push(highlightData);
            }
        }  // The example text is never editable  
        
        
        
        exampleTextArea.toggleEditMode(false);
        
        // The highlight objects contain all the aliases, which we will use to populate the example list
        // Note that each individual list element can be added at any other time
        m_exampleExpressionSymbolMap = new ExpressionSymbolMap(m_assetManager);
        m_exampleExpressionSymbolMap.setConfiguration(CardAttributes.DEFAULT_CARD_ATTRIBUTES);
        
        var expressionStyles : Dynamic = m_barModelTypeDrawer.getStyleObjectForType(barModelType);
        for (idForPart in Reflect.fields(expressionStyles))
        {
            // Alter the card colors to match with the colors in the style info
            var styleForPart : BarModelTypeDrawerProperties = Reflect.field(expressionStyles, idForPart);
            var symbolData : SymbolData = m_exampleExpressionSymbolMap.getSymbolDataFromValue(idForPart);
            symbolData.abbreviatedName = idForPart;
        }  // Adjust the style object so alias name gets drawn out in the example  
        
        
        
        for (i in 0...exampleHighlightDataList.length){
            highlightData = exampleHighlightDataList[i];
            
            var elementId : String = highlightData.id;
            Reflect.setField(expressionStyles, elementId, highlightData.value).value;
            Reflect.setField(expressionStyles, elementId, highlightData.value).alias;
            
            var aliasSymbolData : SymbolData = m_exampleExpressionSymbolMap.getSymbolDataFromValue(elementId);
            aliasSymbolData.abbreviatedName = Reflect.field(expressionStyles, elementId).alias;
        }
        
        var realBarModelView : BarModelAreaWidget = try cast(m_createState.getWidgetFromId("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        m_exampleBarModelView = new BarModelAreaWidget(m_exampleExpressionSymbolMap, m_assetManager, 
                50, 40, 
                realBarModelView.topBarPadding, 
                realBarModelView.bottomBarPadding, 
                realBarModelView.leftBarPadding, 
                realBarModelView.rightBarPadding, 
                realBarModelView.barGap);
        m_exampleBarModelView.setDimensions(realBarModelView.getConstraints().width, realBarModelView.getConstraints().height);
    }
    
    private function onShowExampleClicked(event : Event) : Void
    {
        var showExampleButton : Button = try cast(event.currentTarget, Button) catch(e:Dynamic) null;
        var uiContainer : Sprite = try cast(m_createState.getWidgetFromId("uiContainer"), Sprite) catch(e:Dynamic) null;
        
        // Clicking the example should hide the original text area (make sure no actions can be performed on it)
        // Show the example text area if it hasn't already been processed
        var exampleTextArea : EditableTextArea = try cast(m_createState.getWidgetFromId("exampleTextArea"), EditableTextArea) catch(e:Dynamic) null;
        var editableTextArea : EditableTextArea = try cast(m_createState.getWidgetFromId("editableTextArea"), EditableTextArea) catch(e:Dynamic) null;
        var realBarModelView : BarModelAreaWidget = try cast(m_createState.getWidgetFromId("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        var submitButton : DisplayObject = m_createState.getWidgetFromId("submitButton");
        if (exampleTextArea.parent == null) 
        {
            editableTextArea.toggleEditMode(false);
            
            // Make the example match the text style of the regular text
            var editableTextAreaStyle : TextFormat = editableTextArea.getTextFormat();
            exampleTextArea.setTextFormatProperties(try cast(editableTextAreaStyle.color, Int) catch(e:Dynamic) null, Std.parseInt(editableTextAreaStyle.size), editableTextAreaStyle.font);
            
            var textAreaToFadeout : DisplayObject = editableTextArea;
            var textAreaToFadein : DisplayObject = exampleTextArea;
            
            
            // Mimic the positions of the real parts
            m_exampleBarModelView.x = realBarModelView.x;
            m_exampleBarModelView.y = realBarModelView.y;
            uiContainer.addChild(m_exampleBarModelView);
            
            realBarModelView.visible = false;
            submitButton.visible = false;
            
            showExampleButton.text = "Hide Example";
            
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
            
            showExampleButton.text = "Show Example";
            
            m_createState.dispatchEventWith(ProblemCreateEvent.SHOW_EXAMPLE_END, false, null);
        }  // Figure out which parts to fade in or fade out    // Smoothly animate the text areas fading in or fading out  
        
        
        
        
        
        var fadeDuration : Float = 0.75;
        var fadeout : Tween = new Tween(textAreaToFadeout, fadeDuration, Transitions.LINEAR);
        textAreaToFadeout.alpha = 1.0;
        textAreaToFadein.alpha = 0.0;
        fadeout.fadeTo(0.0);
        fadeout.onComplete = function() : Void
                {
                    textAreaToFadeout.removeFromParent();
                    
                    m_createState.addChild(textAreaToFadein);
                    
                    Starling.juggler.remove(fadeout);
                    
                    var fadein : Tween = new Tween(textAreaToFadein, fadeDuration, Transitions.LINEAR);
                    fadein.fadeTo(1.0);
                    Starling.juggler.add(fadein);
                    
                    if (textAreaToFadein == editableTextArea) 
                    {
                        fadein.onComplete = function() : Void
                                {
                                    editableTextArea.toggleEditMode(true);
                                };
                    }
                };
        Starling.juggler.add(fadeout);
    }
    
    private function redraw() : Void
    {
        // Here the colors of the text highlights and the bar model should be adjusted so they match
        // the background styles
        var exampleTextArea : EditableTextArea = try cast(m_createState.getWidgetFromId("exampleTextArea"), EditableTextArea) catch(e:Dynamic) null;
        var currentHighlightColors : Dynamic = null;
        var backgroundStylesData : Dynamic = m_createState.getCurrentLevel().currentlySelectedBackgroundData;
        if (backgroundStylesData != null && backgroundStylesData.exists("highlightColors")) 
        {
            currentHighlightColors = Reflect.field(backgroundStylesData, "highlightColors");
        }
        
        if (currentHighlightColors != null) 
        {
            for (idForPart in Reflect.fields(currentHighlightColors))
            {
                m_exampleExpressionSymbolMap.resetTextureForValue(idForPart);
                var symbolData : SymbolData = m_exampleExpressionSymbolMap.getSymbolDataFromValue(idForPart);
                symbolData.backgroundColor = Reflect.field(currentHighlightColors, idForPart);
            }
        }
        
        var barModelType : String = m_createState.getCurrentLevel().barModelType;
        m_exampleBarModelView.getBarModelData().clear();
        m_barModelTypeDrawer.drawBarModelIntoViewFromType(barModelType,
                m_exampleBarModelView,
                m_barModelTypeDrawer.getStyleObjectForType(barModelType, currentHighlightColors));
        m_exampleBarModelView.redraw(false, true);
        
        if (currentHighlightColors != null) 
        {
            var activeHighlightsInText : Dynamic = exampleTextArea.getHighlightTextObjects();
            for (highlightId in Reflect.fields(activeHighlightsInText))
            {
                if (currentHighlightColors.exists(highlightId)) 
                {
                    Reflect.setField(activeHighlightsInText, highlightId, Reflect.field(currentHighlightColors, highlightId)).color;
                }
            }
            exampleTextArea.redrawHighlightsAtCurrentIndices();
        }
    }
}
