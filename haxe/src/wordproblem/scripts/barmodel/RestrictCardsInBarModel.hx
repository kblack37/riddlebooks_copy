package wordproblem.scripts.barmodel;


import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;

import starling.display.DisplayObject;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.text.view.DocumentView;
import wordproblem.engine.widget.DeckWidget;
import wordproblem.engine.widget.TextAreaWidget;
import wordproblem.resource.AssetManager;

/**
 * Script to handle disabling certain cards from being usable in the bar model area.
 * For example, supose we only want a term value to only be used once. If it has been
 * placed already, it should no longer be draggable from either the deck or the text.
 */
class RestrictCardsInBarModel extends BaseBarModelScript
{
    private var m_termValuesAndNamesUsedBuffer : Array<String>;
    private var m_outUiEntityBuffer : Array<DisplayObject>;
    private var m_outDocumentViewsBuffer : Array<DocumentView>;
    
    /**
     * For tutorial/custom levels, we want to disable a term if it is used as a bar multiplier
     * or bar split value. List contains terms that should be disabled even if they don't explicitly
     * appear as a value in the bar model (i.e. its name does not appear)
     */
    private var m_termValuesManuallyDisabled : Array<String>;
    
    /**
     * This script has the side effect of automatically setting parts to be selectable anytime
     * the bar model has changed.
     */
    private var m_termValuesToIgnore : Array<String>;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        m_termValuesAndNamesUsedBuffer = new Array<String>();
        m_outUiEntityBuffer = new Array<DisplayObject>();
        m_outDocumentViewsBuffer = new Array<DocumentView>();
        m_termValuesManuallyDisabled = new Array<String>();
        m_termValuesToIgnore = new Array<String>();
    }
    
    /**
     * This will clear all previously set term values.
     */
    public function setTermValuesManuallyDisabled(termValues : Array<String>) : Void
    {
		m_termValuesManuallyDisabled = new Array<String>();
        
        if (termValues != null) 
        {
            for (termValue in termValues)
            {
                m_termValuesManuallyDisabled.push(termValue);
            }
            checkValuesToApplyRestrictions(false);
        }
    }
    
    /**
     * In some tutorials we do not want this script to be automatically adjusting whether terms are selectable.
     * Add the values here to they are ignored
     * 
     * @termValues
     *      Note that the list will overwrite previous values
     */
    public function setTermValuesToIgnore(termValues : Array<String>) : Void
    {
		m_termValuesToIgnore = new Array<String>();
        
        if (termValues != null) 
        {
            for (termValue in termValues)
            {
                m_termValuesToIgnore.push(termValue);
            }
            checkValuesToApplyRestrictions(false);
        }
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_ready) 
        {
            if (value) 
            {
                m_barModelArea.addEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
            }
            else 
            {
                m_barModelArea.removeEventListener(GameEvent.BAR_MODEL_AREA_REDRAWN, bufferEvent);
                
                // Disable all active effects of the restrictions
                // Problem if some other script did these changes, this would overwrite all these things
                checkValuesToApplyRestrictions(true, false);
            }
        }
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        this.setIsActive(m_isActive);
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == GameEvent.BAR_MODEL_AREA_REDRAWN) 
        {
            checkValuesToApplyRestrictions(false);
        }
    }
    
    /**
     *
     * @param forceSetToValue
     *      If true, we force the restrictions to automatically update to a particular value
     */
    private function checkValuesToApplyRestrictions(forceSetToValue : Bool, forceValue : Bool = false) : Void
    {
        // Iterate through the labels that have been used
		m_termValuesAndNamesUsedBuffer = new Array<String>();
        
        if (m_barModelArea == null) 
        {
            return;
        }
        
        var barWholes : Array<BarWhole> = m_barModelArea.getBarModelData().barWholes;
        for (barWhole in barWholes)
        {
            for (barLabel/* AS3HX WARNING could not determine type for var: barLabel exp: EField(EIdent(barWhole),barLabels) type: null */ in barWhole.barLabels)
            {
                if (Lambda.indexOf(m_termValuesAndNamesUsedBuffer, barLabel.value) < 0) 
                {
                    m_termValuesAndNamesUsedBuffer.push(barLabel.value);
                }
            }
            
            if (barWhole.barComparison != null) 
            {
                if (Lambda.indexOf(m_termValuesAndNamesUsedBuffer, barWhole.barComparison.value) < 0) 
                {
                    m_termValuesAndNamesUsedBuffer.push(barWhole.barComparison.value);
                }
            }
        }
        var verticalLabels : Array<BarLabel> = m_barModelArea.getBarModelData().verticalBarLabels;
        for (barLabel in verticalLabels)
        {
            if (Lambda.indexOf(m_termValuesAndNamesUsedBuffer, barLabel.value) < 0) 
            {
                m_termValuesAndNamesUsedBuffer.push(barLabel.value);
            }
        } 
		
		// Add in the manually restricted elements  
        for (manuallyRestrictedTerm in m_termValuesManuallyDisabled)
        {
            m_termValuesAndNamesUsedBuffer.push(manuallyRestrictedTerm);
        }  // Otherwise re-enable it    // If an expression is in the deck and is used somewhere in the bar model as a name, disable it  
        
        
        
        
        
		m_outUiEntityBuffer = new Array<DisplayObject>();
        m_gameEngine.getUiEntitiesByClass(DeckWidget, m_outUiEntityBuffer);
        if (m_outUiEntityBuffer.length > 0 && Std.is(m_outUiEntityBuffer[0], DeckWidget)) 
        {
            var deckWidget : DeckWidget = try cast(m_outUiEntityBuffer[0], DeckWidget) catch(e:Dynamic) null;
            var expressionComponents : Array<Component> = deckWidget.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
            for (i in 0...expressionComponents.length){
                var expressionComponent : ExpressionComponent = try cast(expressionComponents[i], ExpressionComponent) catch(e:Dynamic) null;
                var expressionUsedInBarModel : Bool = Lambda.indexOf(m_termValuesAndNamesUsedBuffer, expressionComponent.expressionString) >= 0;
                if (forceSetToValue) 
                {
                    expressionUsedInBarModel = forceValue;
                }
                deckWidget.toggleSymbolEnabled(!expressionUsedInBarModel, expressionComponent.expressionString);
            }
        }
		
		// If an expression is draggable from the text and is used somewhere in the bar model as a name,  
        // then disable it. Otherwise re-enable it 
		m_outUiEntityBuffer = new Array<DisplayObject>();
        m_gameEngine.getUiEntitiesByClass(TextAreaWidget, m_outUiEntityBuffer);
        if (m_outUiEntityBuffer.length > 0 && Std.is(m_outUiEntityBuffer[0], TextAreaWidget)) 
        {
            var textAreaWidget : TextAreaWidget = try cast(m_outUiEntityBuffer[0], TextAreaWidget) catch(e:Dynamic) null;
            var expressionComponents = textAreaWidget.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
            for (i in 0...expressionComponents.length){
                var expressionComponent = try cast(expressionComponents[i], ExpressionComponent) catch(e:Dynamic) null;
                
                var expressionValue : String = expressionComponent.expressionString;
                if (Lambda.indexOf(m_termValuesToIgnore, expressionValue) < 0) 
                {
                    var expressionUsedInBarModel = Lambda.indexOf(m_termValuesAndNamesUsedBuffer, expressionValue) >= 0;
                    if (forceSetToValue) 
                    {
                        expressionUsedInBarModel = forceValue;
                    }
					m_outDocumentViewsBuffer = new Array<DocumentView>();
                    textAreaWidget.getDocumentViewsAtPageIndexById(expressionComponent.entityId, m_outDocumentViewsBuffer);
                    for (documentView in m_outDocumentViewsBuffer)
                    {
                        documentView.node.setSelectable(!expressionUsedInBarModel, true);
                        documentView.node.setTextDecoration(((expressionUsedInBarModel)) ? "line-through" : null);
                        documentView.alpha = ((expressionUsedInBarModel)) ? 0.3 : 1.0;
                    }
                }
            }
        }
    }
}
