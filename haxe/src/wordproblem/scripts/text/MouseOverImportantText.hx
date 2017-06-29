package wordproblem.scripts.text;


import flash.geom.Point;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.ui.MouseState;

import starling.display.DisplayObject;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.ExpressionComponent;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.text.view.DocumentView;
import wordproblem.engine.widget.TextAreaWidget;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;

/**
 * Script to detect mouse over important parts of the text (ones where there is some expression value
 * bound to the text)
 * 
 * Other parts of the game can attach callbacks whenever text parts bound to important terms are moused
 * in and out.
 */
class MouseOverImportantText extends BaseGameScript
{
    /**
     * Reference to the text area so we can detect mouse events on it
     */
    private var m_textAreaWidget : TextAreaWidget;
    
    /**
     * Global coordinates of the mouse
     */
    private var m_mousePoint : Point = new Point();
    
    /**
     * A temp variable that remember the last view that was pressed down on.
     * Is unset as soon as the mouse is released or a drag is started
     */
    private var m_viewLastUnderMouse : DocumentView;
    
    /**
     * A temp variable to remember the last point that was pressed down on.
     */
    private var m_lastMouseDownPoint : Point;
    
    /**
     * Accepts params for the view moused over, view moused out, docId moused over, docId moused out
     * Either can be null.
     */
    private var m_onMouseOverChange : Function;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            onMouseOverChange : Function,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_onMouseOverChange = onMouseOverChange;
    }
    
    override public function visit() : Int
    {
        if (super.m_ready && super.m_isActive) 
        {
            if (m_textAreaWidget == null) 
            {
                var textAreas : Array<DisplayObject> = m_gameEngine.getUiEntitiesByClass(TextAreaWidget);
                if (textAreas.length > 0) 
                {
                    m_textAreaWidget = try cast(textAreas[0], TextAreaWidget) catch(e:Dynamic) null;
                }
            }  // On every frame, check if the mouse is over some part of the text  
            
            
            
            var mouseState : MouseState = super.m_gameEngine.getMouseState();
            m_mousePoint.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
            
            // The hit test should return the document view furthest down in the tree structure.
            var hitView : DocumentView = m_textAreaWidget.hitTestDocumentView(m_mousePoint);
            if (hitView != m_viewLastUnderMouse) 
            {
                // New view was hit, trigger callback for mouse over new view
                // If current view is null trigger callback of mouse out
                if (m_onMouseOverChange != null) 
                {
                    var docIdMouseOver : String = ((hitView != null)) ? 
                    getDocumentIdForView(hitView) : null;
                    var docIdMouseOut : String = ((m_viewLastUnderMouse != null)) ? 
                    getDocumentIdForView(m_viewLastUnderMouse) : null;
                    m_onMouseOverChange(hitView, m_viewLastUnderMouse, docIdMouseOver, docIdMouseOut);
                }
                
                m_viewLastUnderMouse = hitView;
            }
        }
        
        return ScriptStatus.SUCCESS;
    }
    
    private function getDocumentIdForView(documentView : DocumentView) : String
    {
        var documentId : String = null;
        var textComponentManager : ComponentManager = m_textAreaWidget.componentManager;
        var components : Array<Component> = textComponentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
        var numComponents : Int = components.length;
        for (i in 0...numComponents){
            var expressionComponent : ExpressionComponent = try cast(components[i], ExpressionComponent) catch(e:Dynamic) null;
            var documentIdBoundToExpression : String = expressionComponent.entityId;
            
            if (m_textAreaWidget.getViewIsInContainer(documentView, documentIdBoundToExpression)) 
            {
                documentId = documentIdBoundToExpression;
                break;
            }
        }
        return documentId;
    }
}
