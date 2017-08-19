package wordproblem.scripts.level;


import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.time.Time;

import motion.Actuate;

import openfl.display.DisplayObject;
import openfl.events.Event;
import openfl.geom.Rectangle;

import wordproblem.callouts.CalloutCreator;
import wordproblem.characters.HelperCharacterController;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.level.LevelRules;
import wordproblem.engine.objectives.BaseObjective;
import wordproblem.engine.objectives.HintUsedObjective;
import wordproblem.engine.objectives.TotalEquationAndBarModelMistakeObjective;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.scripting.graph.action.CustomVisitNode;
import wordproblem.engine.scripting.graph.selector.PrioritySelector;
import wordproblem.engine.scripting.graph.selector.SequenceSelector;
import wordproblem.engine.text.view.DocumentView;
import wordproblem.engine.widget.TextAreaWidget;
import wordproblem.hints.HintScript;
import wordproblem.hints.HintSelectorNode;
import wordproblem.hints.scripts.HelpController;
import wordproblem.hints.scripts.HighlightHintButtonScript;
import wordproblem.hints.selector.ExpressionModelHintSelector;
import wordproblem.hints.selector.HighlightTextHintSelector;
import wordproblem.player.PlayerStatsAndSaveData;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;
import wordproblem.scripts.deck.DeckCallout;
import wordproblem.scripts.deck.DeckController;
import wordproblem.scripts.deck.DiscoverTerm;
import wordproblem.scripts.equationtotext.EquationToText;
import wordproblem.scripts.expression.AddAndChangeParenthesis;
import wordproblem.scripts.expression.AddTerm;
import wordproblem.scripts.expression.FlipTerm;
import wordproblem.scripts.expression.PressToChangeOperator;
import wordproblem.scripts.expression.RemoveTerm;
import wordproblem.scripts.expression.ResetTermArea;
import wordproblem.scripts.expression.TermAreaCallout;
import wordproblem.scripts.expression.UndoTermArea;
import wordproblem.scripts.level.util.ChangeTextStyleAndSelectabilityControl;
import wordproblem.scripts.model.ModelSpecificEquation;
import wordproblem.scripts.text.DragText;
import wordproblem.scripts.text.HighlightTextForCard;
import wordproblem.scripts.text.TextToCard;

/**
 * This script will handle the execution of the logic for simple levels that we expect to be
 * be generated from some external source.
 * 
 * The restrictions for these levels is that they display a single paragraph and they model a single equation which
 * when created will end it.
 */
class GenericModelLevelScript extends BaseCustomLevelScript
{
    /**
     * This is the data containing all level specific parameters.
     */
    private var m_data : Dynamic;
    
    /**
     * External time tick that can be shared amongst several level scripts
     */
    private var m_time : Time;
    
    /**
     * Variable + Expression hints attached to this level
     */
    private var m_hintingScript : HelpController;
    
    /**
     * Need to hold reference because we bound an event listener to it
     */
    private var m_textAreaWidget : TextAreaWidget;
    
    /**
     * For generic levels we want to have text be revealed one section at a time, player
     * clicks to continue revealing the next part.
     * 
     * To accomodate this, each level using the generic structure should be tagged
     * with a special class id that will also us to concretely order parts that we
     * should show.
     */
    private var m_documentViewsMatchingHideableClass : Array<DocumentView>;
    
    private var m_foundFinalAnswer : Bool = false;
    
    public function new(data : Dynamic,
            gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            playerStatsAndSaveData : PlayerStatsAndSaveData)
    {
        super(gameEngine, expressionCompiler, assetManager, playerStatsAndSaveData);
        
        // Store level data to be parsed out later
        m_data = data;
        
        m_time = new Time();
        
        super.pushChild(new DeckController(m_gameEngine, m_expressionCompiler, m_assetManager, "DeckController"));
        super.pushChild(new DeckCallout(m_gameEngine, m_expressionCompiler, m_assetManager));
        // Add logic to only accept the model of a particular equation
        super.pushChild(new ModelSpecificEquation(gameEngine, expressionCompiler, assetManager, "ModelSpecificEquation"));
        // Add logic to handle adding new cards (only active after all cards discovered)
        super.pushChild(new AddTerm(gameEngine, expressionCompiler, assetManager));
        
        // Other scripts to get the game to function
        super.pushChild(new DiscoverTerm(m_gameEngine, m_assetManager, "DiscoverTerm"));
        super.pushChild(new HighlightTextForCard(m_gameEngine, m_assetManager));
        super.pushChild(new DragText(m_gameEngine, null, m_assetManager, "DragText"));
        super.pushChild(new TextToCard(m_gameEngine, m_expressionCompiler, m_assetManager, "TextToCard"));
        
        super.pushChild(new UndoTermArea(m_gameEngine, m_expressionCompiler, m_assetManager, "UndoTermArea"));
        super.pushChild(new ResetTermArea(m_gameEngine, m_expressionCompiler, m_assetManager));
        super.pushChild(new EquationToText(m_gameEngine, m_expressionCompiler, m_assetManager));
        super.pushChild(new TermAreaCallout(m_gameEngine, m_expressionCompiler, m_assetManager));
        
        m_documentViewsMatchingHideableClass = new Array<DocumentView>();
    }
    
    override public function visit() : Int
    {
        m_time.update();
        return super.visit();
    }
    
    override public function getObjectives(outObjectives : Array<BaseObjective>) : Void
    {
        super.getObjectives(outObjectives);
        outObjectives.push(new HintUsedObjective(0, true));
        outObjectives.push(new TotalEquationAndBarModelMistakeObjective(3, true));
    }
    
    override public function dispose() : Void
    {
        m_textAreaWidget.removeEventListener(GameEvent.TEXT_AREA_REDRAWN, onTextAreaRedrawn);
        m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_SUCCESS, onEquationModeled);
        super.dispose();
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        
        // Add in more custom scripts
        // We need to label a priority to each one so that we can short-circuit ones that we don't care about
        // If a high priority one returns success, we don't need to visit the ones
        // The important thing is that each of these scripts listen for event but cannot do anything until the next call to visit
        // if they never execute on that visit then they should never attempt to perform the action
        var newGameScript : BaseGameScript = null;
        var termAreaPrioritySelector : PrioritySelector = new PrioritySelector();
        super.pushChild(termAreaPrioritySelector);
        
        var levelRules : LevelRules = m_gameEngine.getCurrentLevel().getLevelRules();
        if (levelRules.allowParenthesis) 
        {
            newGameScript = new AddAndChangeParenthesis(m_gameEngine, m_expressionCompiler, m_assetManager, "AddAndChangeParenthesis");
            termAreaPrioritySelector.pushChild(newGameScript);
            newGameScript.overrideLevelReady({ });
        }
        
        if (levelRules.allowCardFlip) 
        {
            newGameScript = new FlipTerm(m_gameEngine, m_expressionCompiler, m_assetManager);
            termAreaPrioritySelector.pushChild(newGameScript);
            newGameScript.overrideLevelReady({ });
        }
        
        newGameScript = new PressToChangeOperator(m_gameEngine, m_expressionCompiler, m_assetManager);
        termAreaPrioritySelector.pushChild(newGameScript);
        newGameScript.overrideLevelReady({ });
        
        newGameScript = new RemoveTerm(m_gameEngine, m_expressionCompiler, m_assetManager, "RemoveTerm");
        termAreaPrioritySelector.pushChild(newGameScript);
        newGameScript.overrideLevelReady({ });
        
        // Create a hinting child
        var helperCharacterController : HelperCharacterController = new HelperCharacterController(
        m_gameEngine.getCharacterComponentManager(), 
        new CalloutCreator(m_textParser, m_textViewFactory));
        var hintSelector : HintSelectorNode = new HintSelectorNode();
        
        // Add the single equation to model
        var modelSpecificEquationScript : ModelSpecificEquation = try cast(this.getNodeById("ModelSpecificEquation"), ModelSpecificEquation) catch(e:Dynamic) null;
        var equationString : String = Reflect.field(m_data, "equation");
        if (modelSpecificEquationScript != null) 
        {
            modelSpecificEquationScript.addEquation("1", equationString, false, true);
        }
        var expressionModelHint : ExpressionModelHintSelector = new ExpressionModelHintSelector(
			m_gameEngine, m_assetManager, helperCharacterController, m_expressionCompiler, modelSpecificEquationScript, 200, 370);
		var highlightTextHint : HighlightTextHintSelector = new HighlightTextHintSelector(m_gameEngine, m_assetManager, null, helperCharacterController, 
			m_textParser, m_textViewFactory);
		
		hintSelector.setCustomGetHintFunction(function() : HintScript
        {
            var hintScript : HintScript = highlightTextHint.getHint();
            if (hintScript == null) 
            {
                hintScript = expressionModelHint.getHint();
            }
            return hintScript;
        }, null);
        
		hintSelector.addChild(expressionModelHint);
        hintSelector.addChild(highlightTextHint);
        
        m_hintingScript = new HelpController(m_gameEngine, m_expressionCompiler, m_assetManager);
        super.pushChild(m_hintingScript);
        m_hintingScript.overrideLevelReady({ });
        m_hintingScript.setRootHintSelectorNode(hintSelector);
        
        var highlightHintButton : HighlightHintButtonScript = new HighlightHintButtonScript(m_gameEngine, m_expressionCompiler, m_assetManager, m_hintingScript, m_time);
        super.pushChild(highlightHintButton);
        highlightHintButton.overrideLevelReady({ });
        
        // Bind variables to parts of the text
        // Need an array of pairs
        var termsToDocumentIds : Array<Dynamic> = Reflect.field(m_data, "documentIds");
        for (termDocumentPair in termsToDocumentIds)
        {
            m_gameEngine.addTermToDocument(Reflect.field(termDocumentPair, "termValue"), Reflect.field(termDocumentPair, "documentId"));
        }
		
		// Listen for the equation modeled  
        m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, onEquationModeled);
        
        // Hide the equation layer below the viewport at the start
        // Encourage user to read the text first
        var equationLayer : DisplayObject = m_gameEngine.getUiEntity("equationLayer");
        equationLayer.y = 230;
        
        var leftTermArea : DisplayObject = m_gameEngine.getUiEntity("leftTermArea");
        leftTermArea.visible = false;
        var rightTermArea : DisplayObject = m_gameEngine.getUiEntity("rightTermArea");
        rightTermArea.visible = false;
        var modelButton : DisplayObject = m_gameEngine.getUiEntity("modelEquationButton");
        modelButton.visible = false;
        var undoButton : DisplayObject = m_gameEngine.getUiEntity("undoButton");
        undoButton.visible = false;
        var resetButton : DisplayObject = m_gameEngine.getUiEntity("resetButton");
        resetButton.visible = false;
        var parenthesisButton : DisplayObject = m_gameEngine.getUiEntity("parenthesisButton");
        parenthesisButton.visible = false;
        
        // Note changing the text style in another script causes a redraw that kills the existing views
        // we need to listen for the last redraw before hiding the specified classes
        m_textAreaWidget = try cast(m_gameEngine.getUiEntity("textArea"), TextAreaWidget) catch(e:Dynamic) null;
        m_textAreaWidget.addEventListener(GameEvent.TEXT_AREA_REDRAWN, onTextAreaRedrawn);
        
        var changeTextSelectability : ChangeTextStyleAndSelectabilityControl = new ChangeTextStyleAndSelectabilityControl(m_gameEngine);
        changeTextSelectability.resetStyleForTerm();
        changeTextSelectability.setOnlyClassNameAsSelectable();
    }
    
    // HACK: Multiple redraws screws this up completely
    private function onTextAreaRedrawn(params : Dynamic) : Void
    {
		m_documentViewsMatchingHideableClass = new Array<DocumentView>();
        m_textAreaWidget.getDocumentViewsByClass("delay_reveal", m_documentViewsMatchingHideableClass);
        var numDocumentViewsMatchingClass : Int = m_documentViewsMatchingHideableClass.length;
        
        // Hide all but the first one
        var documentViewMatchingClass : DocumentView = null;
        var i : Int = 0;
        for (i in 1...numDocumentViewsMatchingClass){
            documentViewMatchingClass = m_documentViewsMatchingHideableClass[i];
            documentViewMatchingClass.alpha = 0.1;
            
            // Cascade selectability of the documents views to be false
            documentViewMatchingClass.node.setSelectable(false);
        }
		
		// Color for click to continue matches those defined by the paragraph text style  
        var textStyle : Dynamic = m_gameEngine.getCurrentLevel().getCssStyleObject();
        var clickToContinueColor : Int = 0;
        if (textStyle != null && textStyle.exists("p")) 
        {
            var paragraphStyle : Dynamic = Reflect.field(textStyle, "p");
            if (paragraphStyle.exists("color")) 
            {
                clickToContinueColor = Reflect.field(paragraphStyle, "color");
            }
        }
        
        var revealTextGraduallySequence : SequenceSelector = new SequenceSelector();
        
        // For each sentence to reveal, add a click to continue listener
        // The click to continue text should appear below the last visible view
        // (This assumes everything is visible at once)
        var furthestView : DocumentView = m_textAreaWidget.getPageViews()[m_textAreaWidget.getCurrentPageIndex()].getFurthestDocumentView();
        var furthestViewBounds : Rectangle = furthestView.getBounds(m_textAreaWidget);
        for (i in 1...numDocumentViewsMatchingClass){
            
            var clickToContinueParams : Dynamic = {
                x : m_textAreaWidget.getViewport().width * 0.4,
                y : furthestViewBounds.bottom,
                parent : m_textAreaWidget,
                color : clickToContinueColor,
            };
            revealTextGraduallySequence.pushChild(new CustomVisitNode(clickToContinue, clickToContinueParams));
            
			function revealEquationUi(param : Dynamic) : Int
			{
				goToEquationModelMode();
				return ScriptStatus.SUCCESS;
			};
			
            if (i == 1) 
            {
                revealTextGraduallySequence.pushChild(new CustomVisitNode(revealEquationUi, null));
            }
            
            revealTextGraduallySequence.pushChild(new CustomVisitNode(showHiddenClassDocumentViewByIndex, {
                        index : i
                    }));
            revealTextGraduallySequence.pushChild(new CustomVisitNode(secondsElapsed, {
                        duration : 0.1
                    }));
        }
        super.pushChild(revealTextGraduallySequence);
    }
    
    private function showHiddenClassDocumentViewByIndex(param : Dynamic) : Int
    {
        var documentViewToReveal : DocumentView = m_documentViewsMatchingHideableClass[param.index];
		Actuate.tween(documentViewToReveal, 0.5, { alpha : 1.0 }).onComplete(function() : Void
            {
                documentViewToReveal.node.setSelectable(true);
            }
        );
        return ScriptStatus.SUCCESS;
    }
    
    private function onEquationModeled(event : Dynamic) : Void
    {
        if (!m_foundFinalAnswer) 
        {
            m_foundFinalAnswer = true;
            m_gameEngine.dispatchEvent(new Event(GameEvent.LEVEL_SOLVED));
            
            // Wait for some short time before marking the level as totally complete
			Actuate.timer(1.5).onComplete(function() : Void
                {
                    m_gameEngine.dispatchEvent(new Event(GameEvent.LEVEL_COMPLETE));
                }
            );
        }
    }
    
    private function goToEquationModelMode() : Void
    {
        // Assuming we don't care about the space for the inventory in these levels
        // since we always deal with one equation.
        var equationLayer : DisplayObject = m_gameEngine.getUiEntity("equationLayer");
		Actuate.tween(equationLayer, 0.5, { y : 0 });
        
        // Show all the parts needed for modeling
        var leftTermArea : DisplayObject = m_gameEngine.getUiEntity("leftTermArea");
        leftTermArea.visible = true;
        var rightTermArea : DisplayObject = m_gameEngine.getUiEntity("rightTermArea");
        rightTermArea.visible = true;
        var modelButton : DisplayObject = m_gameEngine.getUiEntity("modelEquationButton");
        modelButton.visible = true;
        
        // Unhide the undo and reset buttons
        var undoButton : DisplayObject = m_gameEngine.getUiEntity("undoButton");
        undoButton.visible = true;
        var resetButton : DisplayObject = m_gameEngine.getUiEntity("resetButton");
        resetButton.visible = true;
        
        // Unhide the parenthesis button
        var parenthesisButton : DisplayObject = m_gameEngine.getUiEntity("parenthesisButton");
        parenthesisButton.visible = true;
    }
}
