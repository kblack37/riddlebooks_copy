package wordproblem.scripts.deck;


import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextFormat;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.ui.MouseState;

import feathers.controls.Callout;

import starling.display.DisplayObject;
import starling.text.TextField;

import wordproblem.display.Layer;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.component.CalloutComponent;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.text.MeasuringTextField;
import wordproblem.engine.widget.DeckWidget;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;

/**
 * This class manages showing tooltips on pieces of the 'main' deck
 */
class DeckCallout extends BaseGameScript
{
    private var m_globalMouseBuffer : Point = new Point();
    
    /**
     * Primary layer where individual symbols are added on top of
     */
    private var m_deckArea : DeckWidget;
    
    /**
     * Map from entity id of each deck element to a boolean of whether the callout
     * for that element was created by this script.
     * 
     * We need this so we don't accidently remove tooltips made by other parts
     */
    private var m_calloutCreatedInternallyMap : Dynamic;
    
    /**
     * The text field is used to measure the size of the callout
     */
    private var m_measuringTextField : MeasuringTextField;
    
    private var m_localBoundsBuffer : Rectangle = new Rectangle();
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_calloutCreatedInternallyMap = { };
    }
    
    override public function visit() : Int
    {
        if (m_ready && m_isActive) 
        {
            // Tooltip rules:
            // Without dragging anything, a mouse over on an unhidden card should show a tooltip.
            // If player drags that card, the tooltip should persist and no other ones should show
            // on release the tooltip is closed.
            
            // Show a tooltip only for variables, numeric values are described exactly by the symbol on the card
            // Check for hover over a card, if activated for some period of time fade in
            // a tooltip for the name of the card.
            if (!m_deckArea.getAnimationPlaying()) 
            {
                // Check for hit in the object,
                // For all unhit object check if we had created
                var mouseState : MouseState = m_gameEngine.getMouseState();
                m_globalMouseBuffer.x = mouseState.mousePositionThisFrame.x;
                m_globalMouseBuffer.y = mouseState.mousePositionThisFrame.y;
                var noHitComponent : Bool = true;
                var hitObject : BaseTermWidget = try cast(m_deckArea.getObjectUnderPoint(m_globalMouseBuffer.x, m_globalMouseBuffer.y), BaseTermWidget) catch(e:Dynamic) null;
                var components : Array<Component> = m_deckArea.componentManager.getComponentListForType(RenderableComponent.TYPE_ID);
                var numComponents : Int = components.length;
                var i : Int;
                for (i in 0...numComponents){
                    var renderComponent : RenderableComponent = try cast(components[i], RenderableComponent) catch(e:Dynamic) null;
                    var deckEntityId : String = renderComponent.entityId;
                    var calloutForHitObject : CalloutComponent = try cast(m_deckArea.componentManager.getComponentFromEntityIdAndType(
                            deckEntityId, CalloutComponent.TYPE_ID), CalloutComponent) catch(e:Dynamic) null;
                    if (hitObject != null && renderComponent.view == hitObject && !hitObject.getIsHidden() && !Layer.getDisplayObjectIsInInactiveLayer(hitObject)) 
                    {
                        // Additional case to make sure objects that are not part of the layering system but that are still above the card
                        // will prevent the callout from showing up. This is needed for a case like a character hint and callout appearing above the deck.
                        // We cannot add the character callout to the layer system so we have no choice but to add this work around
                        var topmostHitObject : DisplayObject = hitObject.stage.hitTest(m_globalMouseBuffer);
                        while (topmostHitObject != hitObject && topmostHitObject != null)
                        {
                            topmostHitObject = topmostHitObject.parent;
                        }
                        
                        if (topmostHitObject != hitObject) 
                        {
                            continue;
                        }  // Occurs during card flip. In this case we discard the old callout    // Possible for a card to take a new value that no longer matches the text in the callout  
                        
                        
                        
                        
                        
                        var symbolName : String = m_gameEngine.getExpressionSymbolResources().getSymbolName(hitObject.getNode().data);
                        if (calloutForHitObject != null) 
                        {
                            // If an outside entity created the callout then do not override
                            // (i.e. if a tutorial hint added a callout over the card, we should not remove it)
                            if (!m_calloutCreatedInternallyMap.exists(deckEntityId) || !Reflect.field(m_calloutCreatedInternallyMap, deckEntityId)) 
                            {
                                continue;
                            }
                            
                            if ((try cast(calloutForHitObject.display, TextField) catch(e:Dynamic) null).text != symbolName) 
                            {
                                m_deckArea.componentManager.removeComponentFromEntity(deckEntityId, CalloutComponent.TYPE_ID);
                            }
                        }  // Create a new callout for the hit object if one does not already exist  
                        
                        
                        
                        if (calloutForHitObject == null) 
                        {
                            // If the contents of the tool tip is exactly the same as the text that is on the card,
                            // then the tooltip is useless. Don't bother creating one for it
                            if (symbolName == m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(hitObject.getNode().data).abbreviatedName) 
                            {
                                continue;
                            }  // Callout should point to middle of the VISIBLE portion only.    // of callout as the callout should point only to visible portion.    // Checked if hit object is clipped by edge of view port, this will affect positioning  
                            
                            
                            
                            
                            
                            
                            
                            hitObject.getBounds(m_deckArea, m_localBoundsBuffer);
                            var calloutXOffset : Float = 0;
                            
                            // Check if hit object was clipped by view port edge
                            var deckViewport : Rectangle = m_deckArea.getViewport();
                            var originalMidX : Float = m_localBoundsBuffer.left + m_localBoundsBuffer.width * 0.5;
                            var clippedMidX : Float = originalMidX;
                            if (m_localBoundsBuffer.left < deckViewport.left) 
                            {
                                clippedMidX = m_localBoundsBuffer.right - (m_localBoundsBuffer.right - deckViewport.left) * 0.5;
                            }
                            else if (m_localBoundsBuffer.right > deckViewport.right) 
                            {
                                clippedMidX = deckViewport.right - (deckViewport.right - m_localBoundsBuffer.left) * 0.5;
                            }
                            calloutXOffset = clippedMidX - originalMidX;
                            
                            // Need to get the main render component for the hit card. This provides us with the position
                            // at which we want to add the tooltip
                            m_measuringTextField.text = symbolName;
                            var backgroundPadding : Float = 8;
                            var textFormat : TextFormat = m_measuringTextField.defaultTextFormat;
                            var textField : TextField = new TextField(
                            m_measuringTextField.textWidth + backgroundPadding * 2, 
                            m_measuringTextField.textHeight * 2, 
                            symbolName, 
                            textFormat.font, 
                            Std.parseInt(textFormat.size), 
                            try cast(textFormat.color, Int) catch(e:Dynamic) null, 
                            );
                            var calloutComponent : CalloutComponent = new CalloutComponent(deckEntityId);
                            calloutComponent.backgroundTexture = "button_white";
                            calloutComponent.backgroundColor = 0x000000;
                            calloutComponent.arrowTexture = "callout_arrow";
                            calloutComponent.edgePadding = -2.0;
                            calloutComponent.directionFromOrigin = Callout.DIRECTION_UP;
                            calloutComponent.display = textField;
                            calloutComponent.xOffset = calloutXOffset;
                            m_deckArea.componentManager.addComponentToEntity(calloutComponent);
                            
                            Reflect.setField(m_calloutCreatedInternallyMap, deckEntityId, true);
                        }
                    }
                    else if (calloutForHitObject != null && Reflect.field(m_calloutCreatedInternallyMap, deckEntityId)) 
                    {
                        Reflect.setField(m_calloutCreatedInternallyMap, deckEntityId, false);
                        
                        // Make sure there is no callout bound to the entity
                        m_deckArea.componentManager.removeComponentFromEntity(deckEntityId, CalloutComponent.TYPE_ID);
                    }
                }  // as a result need to just remove the callout from view    // Note that the callout cannot call close while the card's position or dimension properties are changing,    // If not hovering over any card, fade out a tooltip if it existed  
            }
        }
        
        return ScriptStatus.SUCCESS;
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        m_deckArea = try cast(m_gameEngine.getUiEntity("deckArea"), DeckWidget) catch(e:Dynamic) null;
        m_measuringTextField = new MeasuringTextField();
        m_measuringTextField.defaultTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0xFFFFFF);
    }
}
