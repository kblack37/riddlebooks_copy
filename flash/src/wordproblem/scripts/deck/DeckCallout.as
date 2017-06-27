package wordproblem.scripts.deck
{
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
    public class DeckCallout extends BaseGameScript
    {
        private const m_globalMouseBuffer:Point = new Point();
        
        /**
         * Primary layer where individual symbols are added on top of
         */
        private var m_deckArea:DeckWidget;
        
        /**
         * Map from entity id of each deck element to a boolean of whether the callout
         * for that element was created by this script.
         * 
         * We need this so we don't accidently remove tooltips made by other parts
         */
        private var m_calloutCreatedInternallyMap:Object;
        
        /**
         * The text field is used to measure the size of the callout
         */
        private var m_measuringTextField:MeasuringTextField;
        
        private var m_localBoundsBuffer:Rectangle = new Rectangle();
        
        public function DeckCallout(gameEngine:IGameEngine, 
                                    expressionCompiler:IExpressionTreeCompiler, 
                                    assetManager:AssetManager, 
                                    id:String=null, 
                                    isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            
            m_calloutCreatedInternallyMap = {};
        }
        
        override public function visit():int
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
                    var mouseState:MouseState = m_gameEngine.getMouseState();
                    m_globalMouseBuffer.x = mouseState.mousePositionThisFrame.x;
                    m_globalMouseBuffer.y = mouseState.mousePositionThisFrame.y;
                    var noHitComponent:Boolean = true;
                    var hitObject:BaseTermWidget = m_deckArea.getObjectUnderPoint(m_globalMouseBuffer.x, m_globalMouseBuffer.y) as BaseTermWidget;
                    var components:Vector.<Component> = m_deckArea.componentManager.getComponentListForType(RenderableComponent.TYPE_ID);
                    var numComponents:int = components.length;
                    var i:int;
                    for (i = 0; i < numComponents; i++)
                    {
                        var renderComponent:RenderableComponent = components[i] as RenderableComponent;
                        var deckEntityId:String = renderComponent.entityId;
                        var calloutForHitObject:CalloutComponent = m_deckArea.componentManager.getComponentFromEntityIdAndType(
                            deckEntityId, CalloutComponent.TYPE_ID) as CalloutComponent;
                        if (hitObject != null && renderComponent.view == hitObject && !hitObject.getIsHidden() && !Layer.getDisplayObjectIsInInactiveLayer(hitObject))
                        {
                            // Additional case to make sure objects that are not part of the layering system but that are still above the card
                            // will prevent the callout from showing up. This is needed for a case like a character hint and callout appearing above the deck.
                            // We cannot add the character callout to the layer system so we have no choice but to add this work around
                            var topmostHitObject:DisplayObject = hitObject.stage.hitTest(m_globalMouseBuffer);
                            while (topmostHitObject != hitObject && topmostHitObject != null)
                            {
                                topmostHitObject = topmostHitObject.parent;
                            }
                            
                            if (topmostHitObject != hitObject)
                            {
                                continue;
                            }
                            
                            // Possible for a card to take a new value that no longer matches the text in the callout
                            // Occurs during card flip. In this case we discard the old callout
                            var symbolName:String = m_gameEngine.getExpressionSymbolResources().getSymbolName(hitObject.getNode().data);
                            if (calloutForHitObject != null)
                            {
                                // If an outside entity created the callout then do not override
                                // (i.e. if a tutorial hint added a callout over the card, we should not remove it)
                                if (!m_calloutCreatedInternallyMap.hasOwnProperty(deckEntityId) || !m_calloutCreatedInternallyMap[deckEntityId])
                                {
                                    continue;
                                }
                                
                                if ((calloutForHitObject.display as TextField).text != symbolName)
                                {
                                    m_deckArea.componentManager.removeComponentFromEntity(deckEntityId, CalloutComponent.TYPE_ID);
                                }
                            }
                            
                            // Create a new callout for the hit object if one does not already exist
                            if (calloutForHitObject == null)
                            {
                                // If the contents of the tool tip is exactly the same as the text that is on the card,
                                // then the tooltip is useless. Don't bother creating one for it
                                if (symbolName == m_gameEngine.getExpressionSymbolResources().getSymbolDataFromValue(hitObject.getNode().data).abbreviatedName)
                                {
                                    continue;
                                }
                                
                                // Checked if hit object is clipped by edge of view port, this will affect positioning
                                // of callout as the callout should point only to visible portion.
                                // Callout should point to middle of the VISIBLE portion only.
                                hitObject.getBounds(m_deckArea, m_localBoundsBuffer);
                                var calloutXOffset:Number = 0;
                                
                                // Check if hit object was clipped by view port edge
                                var deckViewport:Rectangle = m_deckArea.getViewport();
                                var originalMidX:Number = m_localBoundsBuffer.left + m_localBoundsBuffer.width * 0.5;
                                var clippedMidX:Number = originalMidX;
                                if (m_localBoundsBuffer.left < deckViewport.left)
                                {
                                    clippedMidX = m_localBoundsBuffer.right - (m_localBoundsBuffer.right - deckViewport.left) * 0.5;
                                }
                                else if (m_localBoundsBuffer.right > deckViewport.right)
                                {
                                    clippedMidX = deckViewport.right - (deckViewport.right - m_localBoundsBuffer.left) * 0.5;
                                }
                                calloutXOffset =  clippedMidX - originalMidX;
                                
                                // Need to get the main render component for the hit card. This provides us with the position
                                // at which we want to add the tooltip
                                m_measuringTextField.text = symbolName;
                                var backgroundPadding:Number = 8;
                                var textFormat:TextFormat = m_measuringTextField.defaultTextFormat;
                                var textField:TextField = new TextField(
                                    m_measuringTextField.textWidth + backgroundPadding * 2, 
                                    m_measuringTextField.textHeight * 2, 
                                    symbolName, 
                                    textFormat.font, 
                                    textFormat.size as int, 
                                    textFormat.color as uint
                                );
                                var calloutComponent:CalloutComponent = new CalloutComponent(deckEntityId);
                                calloutComponent.backgroundTexture = "button_white";
                                calloutComponent.backgroundColor = 0x000000;
                                calloutComponent.arrowTexture = "callout_arrow";
                                calloutComponent.edgePadding = -2.0;
                                calloutComponent.directionFromOrigin = Callout.DIRECTION_UP;
                                calloutComponent.display = textField;
                                calloutComponent.xOffset = calloutXOffset;
                                m_deckArea.componentManager.addComponentToEntity(calloutComponent);
                                
                                m_calloutCreatedInternallyMap[deckEntityId] = true;
                            }
                        }
                        else if (calloutForHitObject != null && m_calloutCreatedInternallyMap[deckEntityId])
                        {
                            m_calloutCreatedInternallyMap[deckEntityId] = false;
                            
                            // Make sure there is no callout bound to the entity
                            m_deckArea.componentManager.removeComponentFromEntity(deckEntityId, CalloutComponent.TYPE_ID);
                        }
                    }
                    
                    // If not hovering over any card, fade out a tooltip if it existed
                    // Note that the callout cannot call close while the card's position or dimension properties are changing,
                    // as a result need to just remove the callout from view
                }
            }
            
            return ScriptStatus.SUCCESS;
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            m_deckArea = m_gameEngine.getUiEntity("deckArea") as DeckWidget;
            m_measuringTextField = new MeasuringTextField();
            m_measuringTextField.defaultTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0xFFFFFF);
        }
    }
}