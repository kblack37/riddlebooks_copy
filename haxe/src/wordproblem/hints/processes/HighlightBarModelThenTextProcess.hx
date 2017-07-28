package wordproblem.hints.processes;


import starling.display.DisplayObject;

import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.barmodel.view.BarComparisonView;
import wordproblem.engine.barmodel.view.BarLabelView;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.barmodel.view.BarWholeView;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.component.HighlightComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.widget.BarModelAreaWidget;
import wordproblem.engine.widget.TextAreaWidget;

/**
 * Script made for Travis' experiment that takes in document ids mapping to parts of
 * a bar model template and attempts to highlight something in the bar model for that doc id
 * and then in the text if it can't find it in the model
 */
class HighlightBarModelThenTextProcess extends ScriptNode
{
    private var m_barModelArea : BarModelAreaWidget;
    private var m_textArea : TextAreaWidget;
    private var m_documentIds : Array<String>;
    private var m_barEntitiesWithHighlights : Array<String>;
    private var m_barEntityViews : Array<DisplayObject>;
    private var m_highlightColor : Int;
    
    public function new(textArea : TextAreaWidget,
            barModelArea : BarModelAreaWidget,
            documentIds : Array<String>,
            highlightColor : Int,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_textArea = textArea;
        m_barModelArea = barModelArea;
        m_documentIds = documentIds;
        m_barEntitiesWithHighlights = new Array<String>();
        m_barEntityViews = new Array<DisplayObject>();
        m_highlightColor = highlightColor;
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (!value) 
        {
            // Remove highlights on the bar model
            for (barEntityId in m_barEntitiesWithHighlights)
            {
                m_barModelArea.componentManager.removeComponentFromEntity(barEntityId, HighlightComponent.TYPE_ID);
            }  // Remove highlights on text  
            
            
            
            var textComponentManager : ComponentManager = m_textArea.componentManager;
            var i : Int;
            var numDocumentIds : Int = m_documentIds.length;
            for (i in 0...numDocumentIds){
                var documentId : String = m_documentIds[i];
                if (textComponentManager.getComponentFromEntityIdAndType(documentId, HighlightComponent.TYPE_ID) != null) 
                {
                    textComponentManager.removeComponentFromEntity(documentId, HighlightComponent.TYPE_ID);
                }
            }
        }
    }
    
    override public function visit() : Int
    {
        // Process can finish on a single frame
        
        // First determine if the doc id maps to an expression that is already present in the bar model
        // area
        var textComponentManager : ComponentManager = m_textArea.componentManager;
        var i : Int;
        var numDocumentIds : Int = m_documentIds.length;
        for (i in 0...numDocumentIds){
            var foundBarViewForDocId : Bool = false;
            var documentId : String = m_documentIds[i];
            var expressionComponent : ExpressionComponent = try cast(textComponentManager.getComponentFromEntityIdAndType(
                    documentId,
                    ExpressionComponent.TYPE_ID
                    ), ExpressionComponent) catch(e:Dynamic) null;
            if (expressionComponent != null) 
            {
                var entitiesToAddHighlights : Array<String> = new Array<String>();
                var expressionToFind : String = expressionComponent.expressionString;
                var viewsForDocId : Array<DisplayObject> = new Array<DisplayObject>();
                
                var barWholes : Array<BarWhole> = m_barModelArea.getBarModelData().barWholes;
                for (barWhole in barWholes)
                {
                    var labels : Array<BarLabel> = barWhole.barLabels;
                    for (label in labels)
                    {
                        if (label.value == expressionToFind) 
                        {
                            // If label is linked to a box, we should highlight that box
                            if (label.bracketStyle == BarLabel.BRACKET_NONE) 
                            {
                                var targetSegmentIndex : Int = label.startSegmentIndex;
                                var targetSegment : BarSegment = barWhole.barSegments[targetSegmentIndex];
                                var targetSegmentView : BarSegmentView = m_barModelArea.getBarSegmentViewById(targetSegment.id);
                                m_barEntityViews.push(targetSegmentView);
                                viewsForDocId.push(targetSegmentView);
                                entitiesToAddHighlights.push(targetSegment.id);
                            }
                            else 
                            {
                                var horizontalLabel : DisplayObject = m_barModelArea.getBarLabelViewById(label.id).getDescriptionDisplay();
                                m_barEntityViews.push(horizontalLabel);
                                viewsForDocId.push(horizontalLabel);
                                entitiesToAddHighlights.push(label.id);
                            }
                            foundBarViewForDocId = true;
                        }
                    }
                    
                    if (barWhole.barComparison != null && barWhole.barComparison.value == expressionToFind) 
                    {
                        var barWholeView : BarWholeView = m_barModelArea.getBarWholeViewById(barWhole.id);
                        var comparisonView : BarComparisonView = barWholeView.comparisonView;
                        m_barEntityViews.push(comparisonView);
                        viewsForDocId.push(comparisonView);
                        entitiesToAddHighlights.push(barWhole.barComparison.id);
                    }
                }
                
                var verticalLabels : Array<BarLabel> = m_barModelArea.getBarModelData().getVerticalBarLabelsByValue(expressionToFind);
                for (verticalLabel in verticalLabels)
                {
                    if (verticalLabel.value == expressionToFind) 
                    {
                        var verticalView : DisplayObject = m_barModelArea.getVerticalBarLabelViewById(verticalLabel.id).getDescriptionDisplay();
                        m_barEntityViews.push(verticalView);
                        viewsForDocId.push(verticalView);
                        entitiesToAddHighlights.push(verticalLabel.id);
                        foundBarViewForDocId = true;
                    }
                }  // For some reason the view component  
                
                
                
                var entityIndex : Int = 0;
                for (entityId in entitiesToAddHighlights)
                {
                    m_barEntitiesWithHighlights.push(entityId);
                    var renderComponent : RenderableComponent = try cast(m_barModelArea.componentManager.getComponentFromEntityIdAndType(
                            entityId, RenderableComponent.TYPE_ID), RenderableComponent) catch(e:Dynamic) null;
                    if (renderComponent == null) 
                    {
                        renderComponent = new RenderableComponent(entityId, RenderableComponent.TYPE_ID);
                        m_barModelArea.componentManager.addComponentToEntity(renderComponent);
                    }
                    renderComponent.view = viewsForDocId[entityIndex];
                    
                    m_barModelArea.componentManager.addComponentToEntity(new HighlightComponent(entityId, m_highlightColor, 1));
                    entityIndex++;
                }
            }
            
            if (!foundBarViewForDocId &&
                textComponentManager.getComponentFromEntityIdAndType(documentId, HighlightComponent.TYPE_ID) == null &&
                textComponentManager.getComponentFromEntityIdAndType(documentId, RenderableComponent.TYPE_ID) != null) 
            {
                var highlightComponent : HighlightComponent = new HighlightComponent(
					documentId, 
					m_highlightColor, 
					1
                );
                textComponentManager.addComponentToEntity(highlightComponent);
            }
        }
        
        return ScriptStatus.SUCCESS;
    }
}
