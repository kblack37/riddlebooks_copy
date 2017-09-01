package wordproblem.scripts.expression;


import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.ui.MouseState;

import openfl.text.TextField;
import openfl.text.TextFormat;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.CalloutComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.text.MeasuringTextField;
import wordproblem.engine.widget.TermAreaWidget;
import wordproblem.resource.AssetManager;

/**
 * This function will handle showing the tooltip callout ui on existing cards within
 * the term areas.
 */
class TermAreaCallout extends BaseTermAreaScript
{
    /**
     * Keep track of the last term area that got the most recent callout
     */
    private var m_lastPickedTermArea : TermAreaWidget;
    
    /**
     * Keep track of the card that currently has a callout pasted on top
     */
    private var m_lastPickedEntityId : String = null;
    
    /**
     * Map from entity id of each term area element to a boolean of whether the callout
     * for that element was created by this script.
     * 
     * We need this so we don't accidently remove tooltips made by other parts
     */
    private var m_calloutCreatedInternallyMap : Dynamic;
    
    private var m_measuringTextfield : MeasuringTextField;
    private var m_measuringTextFormat : TextFormat;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_measuringTextfield = new MeasuringTextField();
        m_measuringTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 16, 0xFFFFFF);
        m_calloutCreatedInternallyMap = { };
    }
    
    override public function visit() : Int
    {
        if (m_ready && m_isActive) 
        {
            var mouseState : MouseState = m_gameEngine.getMouseState();
            
            var numTermAreas : Int = m_termAreas.length;
            var pickedWidget : BaseTermWidget = null;
            var i : Int = 0;
            var termArea : TermAreaWidget = null;
            for (i in 0...numTermAreas){
                termArea = m_termAreas[i];
                
                // Create and show a brand new callout if the player is moused over something
                pickedWidget = termArea.pickWidgetUnderPoint(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y, false);
                if (pickedWidget != null) 
                {
                    var entityId : String = Std.string(pickedWidget.getNode().id);
                    var calloutForEntity : CalloutComponent = try cast(termArea.componentManager.getComponentFromEntityIdAndType(
                            entityId,
                            CalloutComponent.TYPE_ID
                            ), CalloutComponent) catch(e:Dynamic) null;
                    
                    // Do not show callout for cards used in previews (i.e. snapped cards for multiplication and division do not have expression
                    // nodes created for them so they also do not have the correct renderable component to bind the callout to)
                    if (entityId != m_lastPickedEntityId && calloutForEntity == null &&
                        termArea.componentManager.getComponentFromEntityIdAndType(entityId, RenderableComponent.TYPE_ID) != null) 
                    {
                        // Clear out old callout if it was visible and was created internally
                        if (m_lastPickedEntityId != null && Reflect.hasField(m_calloutCreatedInternallyMap, m_lastPickedEntityId) && Reflect.field(m_calloutCreatedInternallyMap, m_lastPickedEntityId)) 
                        {
                            Reflect.setField(m_calloutCreatedInternallyMap, m_lastPickedEntityId, false);
                            termArea.componentManager.removeComponentFromEntity(
                                    m_lastPickedEntityId,
                                    CalloutComponent.TYPE_ID
                                    );
                        }
                        
                        var name : String = m_gameEngine.getExpressionSymbolResources().getSymbolName(pickedWidget.getNode().data);
                        if (name != "" && name != null) 
                        {
                            m_measuringTextfield.defaultTextFormat = m_measuringTextFormat;
                            m_measuringTextfield.text = name;
                            
                            var calloutComponent : CalloutComponent = new CalloutComponent(entityId);
                            calloutComponent.backgroundTexture = "button_white";
                            calloutComponent.backgroundColor = 0x000000;
                            calloutComponent.arrowTexture = "callout_arrow";
							// TODO: this was replaced from the feathers Callout.DIRECTION_ and will
							// need to be replaced when the callout system is
                            calloutComponent.directionFromOrigin = "up";
							var calloutComponentDisplay : TextField = new TextField();
							calloutComponentDisplay.width = m_measuringTextfield.textWidth + 10;
							calloutComponentDisplay.height = m_measuringTextfield.textHeight + 10;
							calloutComponentDisplay.text = name;
							calloutComponentDisplay.setTextFormat(m_measuringTextFormat);
							calloutComponent.display = calloutComponentDisplay;
                            termArea.componentManager.addComponentToEntity(calloutComponent);
                            
                            m_lastPickedEntityId = entityId;
                            m_lastPickedTermArea = termArea;
                            Reflect.setField(m_calloutCreatedInternallyMap, entityId, true);
                        }
                    }
                    break;
                }
            }  
			
			// If didn't hit anything then don't show the callout anymore  
            // Make sure that the callout in question was created by this script  
            if (pickedWidget == null && m_lastPickedEntityId != null &&
                Reflect.hasField(m_calloutCreatedInternallyMap, m_lastPickedEntityId) && Reflect.field(m_calloutCreatedInternallyMap, m_lastPickedEntityId)) 
            {
                m_lastPickedTermArea.componentManager.removeComponentFromEntity(
                        m_lastPickedEntityId,
                        CalloutComponent.TYPE_ID
                        );
                m_lastPickedTermArea = null;
                m_lastPickedEntityId = null;
                Reflect.setField(m_calloutCreatedInternallyMap, m_lastPickedEntityId, false);
            }
        }
        
        return ScriptStatus.SUCCESS;
    }
}
