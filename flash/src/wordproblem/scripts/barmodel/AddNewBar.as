package wordproblem.scripts.barmodel
{
    import flash.geom.Rectangle;
    
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.ui.MouseState;
    
    import starling.display.DisplayObjectContainer;
    import starling.display.Image;
    import starling.events.EventDispatcher;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.barmodel.BarModelDataUtil;
    import wordproblem.engine.barmodel.model.BarLabel;
    import wordproblem.engine.barmodel.model.BarModelData;
    import wordproblem.engine.barmodel.model.BarSegment;
    import wordproblem.engine.barmodel.model.BarWhole;
    import wordproblem.engine.barmodel.view.BarModelView;
    import wordproblem.engine.barmodel.view.BarWholeView;
    import wordproblem.engine.component.BlinkComponent;
    import wordproblem.engine.component.RenderableComponent;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.ExpressionSymbolMap;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.expression.widget.term.SymbolTermWidget;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.widget.BarModelAreaWidget;
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.drag.WidgetDragSystem;
    
    /**
     * This script handles the addition of brand new bars in the model
     */
    public class AddNewBar extends BaseBarModelScript implements IHitAreaScript
    {
        private var m_hitAreas:Vector.<Rectangle>;
        
        /**
         * Should hit areas for this action be shown in at the start of a frame
         */
        private var m_showHitAreas:Boolean;
        
        /**
         * The color that is used for the preview should be the same one used when the actual
         * segment is created.
         */
        private var m_previewColor:uint;
        
        /**
         * The label used on top of a 
         */
        private var m_previewLabelOnTop:String;
        
        /**
         * The limit to the number of barwholes that can be in the bar model area at the same time.
         * If less than zero, an unlimited number of bars are allowed.
         */
        private var m_maxBarsAllowed:int;
        
        /**
         * Some of the tutorial levels may want to add the bar with different settings than what occurs by default.
         * For example, one of the tutorials would automatically add a horizontal label.
         */
        private var m_customAddBarFunction:Function;
        
        /**
         * Using the id so we can fetch it later
         */
        private static const PREVIEW_NEW_BAR_ID:String = "new_bar";
        
        private var m_expressionSymbolMap:ExpressionSymbolMap;
        private var m_termToValueMap:Object;
        
        /**
         *
         * @param customAddBarFunction
         *      Signature callback(barWholes:Vector.<BarWhole>, data:String, height:Number, color:uint, addLabelOnTop:Boolean, id:String=null)
         */
        public function AddNewBar(gameEngine:IGameEngine, 
                                  expressionCompiler:IExpressionTreeCompiler, 
                                  assetManager:AssetManager,
                                  maxBarsAllowed:int,
                                  id:String=null, 
                                  isActive:Boolean=true, 
                                  customAddBarFunction:Function=null)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            m_maxBarsAllowed = maxBarsAllowed;
            m_previewColor = 0xFFFFFF;
            m_customAddBarFunction = (customAddBarFunction != null) ? customAddBarFunction : addNewBar;
            m_hitAreas = new Vector.<Rectangle>();
        }
        
        public function setParams(barModelArea:BarModelAreaWidget, 
                                  widgetDragSystem:WidgetDragSystem, 
                                  eventDispatcher:EventDispatcher,
                                  mouseState:MouseState, 
                                  expressionSymbolMap:ExpressionSymbolMap, 
                                  termToValueMap:Object):void
        {
            super.setCommonParams(barModelArea, widgetDragSystem, eventDispatcher, mouseState);
            m_expressionSymbolMap = expressionSymbolMap;
            m_termToValueMap = termToValueMap;
        }
        
        /**
         * Expose this so tutorials can freely change this restriction during course of a level.
         * Used mainly to switch mode when player drops a bar to make a choice and when they are making an actual model
         */
        public function setMaxBarsAllowed(value:int):void
        {
            m_maxBarsAllowed = value;   
        }
        
        override public function visit():int
        {
            m_showHitAreas = false;
            var status:int = ScriptStatus.FAIL;
            if (m_ready && m_isActive)
            {
                m_globalMouseBuffer.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
                m_barModelArea.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);

                if (m_eventTypeBuffer.length > 0)
                {
                    var args:Object = m_eventParamBuffer[0];
                    var releasedWidget:BaseTermWidget = args.widget;
                    var releasedExpressionNode:ExpressionNode = releasedWidget.getNode();
                    
                    if (checkHitArea())
                    {
                        m_barModelArea.showPreview(false);
                        m_didActivatePreview = false;
                        
                        labelOnTopValue = null;
                        if (releasedWidget is SymbolTermWidget)
                        {
                            labelOnTopValue = releasedExpressionNode.data;
                        }
                        else if (args.hasOwnProperty("label"))
                        {
                            labelOnTopValue = args["label"];   
                        }
                        
                        var previousModelDataSnapshot:BarModelData = m_barModelArea.getBarModelData().clone();
                        m_customAddBarFunction(m_barModelArea.getBarModelData().barWholes, 
                            releasedExpressionNode.data, 
                            m_previewColor, 
                            labelOnTopValue);
                        if (m_gameEngine != null && m_gameEngine.getCurrentLevel().getLevelRules().autoResizeVerticalBrackets)
                        {
                            BarModelDataUtil.stretchVerticalBrackets(m_barModelArea.getBarModelData());
                        }
                        
                        m_eventDispatcher.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {previousSnapshot:previousModelDataSnapshot});
                        m_barModelArea.redraw();
                        
                        // Log new bar was added
                        m_eventDispatcher.dispatchEventWith(AlgebraAdventureLoggingConstants.ADD_NEW_BAR, false, {
                            barModel:m_barModelArea.getBarModelData().serialize(),
                            value:releasedExpressionNode.data
                        });
                        
                        status = ScriptStatus.SUCCESS;
                    }
                    
                    reset();
                }
                else if (m_widgetDragSystem.getWidgetSelected() != null)
                {
                    m_showHitAreas = true;
                    if (checkHitArea())
                    {
                        // This check shows the preview if either it was not showing already OR a lower priority
                        // script had activated it but we want to overwrite it.
                        if (!m_barModelArea.getPreviewShowing() || !m_didActivatePreview)
                        {
                            releasedWidget = m_widgetDragSystem.getWidgetSelected();
                            releasedExpressionNode = releasedWidget.getNode();
                            
                            var previewView:BarModelView = m_barModelArea.getPreviewView(true);
                            var extraDragParams:Object = m_widgetDragSystem.getExtraParams();
                            var expressionSymbolMap:ExpressionSymbolMap =  (m_gameEngine != null) ?
                                m_gameEngine.getExpressionSymbolResources() : m_expressionSymbolMap;
                            
                            var labelOnTopValue:String = null;
                            if (releasedWidget is SymbolTermWidget)
                            {
                                labelOnTopValue = releasedExpressionNode.data;
                            }
                            else if (extraDragParams.hasOwnProperty("label"))
                            {
                                labelOnTopValue = extraDragParams["label"];   
                            }
                            
                            m_previewColor = super.getBarColor(labelOnTopValue, extraDragParams);
                            m_customAddBarFunction(previewView.getBarModelData().barWholes, 
                                releasedExpressionNode.data, 
                                m_previewColor, 
                                labelOnTopValue, 
                                PREVIEW_NEW_BAR_ID);
                            if (m_gameEngine != null && m_gameEngine.getCurrentLevel().getLevelRules().autoResizeVerticalBrackets)
                            {
                                BarModelDataUtil.stretchVerticalBrackets(previewView.getBarModelData());
                            }
                            m_barModelArea.showPreview(true);
                            m_didActivatePreview = true;
                            
                            // Need to get at the bar view so we can blink it to indicate it is the new element
                            var newWholeBarView:BarWholeView = previewView.getBarWholeViewById(PREVIEW_NEW_BAR_ID);
                            m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(PREVIEW_NEW_BAR_ID));
                            var renderComponent:RenderableComponent = new RenderableComponent(PREVIEW_NEW_BAR_ID);
                            renderComponent.view = newWholeBarView;
                            m_barModelArea.componentManager.addComponentToEntity(renderComponent);
                            
                            this.setDraggedWidgetVisible(false);
                        }
                        
                        status = ScriptStatus.SUCCESS;
                    }
                    else if (m_didActivatePreview)
                    {
                        m_barModelArea.showPreview(false);
                        m_didActivatePreview = false;
                        this.setDraggedWidgetVisible(true);
                        m_barModelArea.componentManager.removeAllComponentsFromEntity(PREVIEW_NEW_BAR_ID);
                    }
                }
            }
            return status;
        }
        
        override public function reset():void
        {
            super.reset();
            m_showHitAreas = false;
            m_barModelArea.componentManager.removeAllComponentsFromEntity(PREVIEW_NEW_BAR_ID);
        }
        
        public function getActiveHitAreas():Vector.<Rectangle>
        {
            checkHitArea();
            return m_hitAreas;
        }
        
        public function getShowHitAreasForFrame():Boolean
        {
            return m_showHitAreas;
        }
        
        public function postProcessHitAreas(hitAreas:Vector.<Rectangle>, hitAreaGraphics:Vector.<DisplayObjectContainer>):void
        {
            for (var i:int = 0; i < hitAreas.length; i++)
            {
                var icon:Image = new Image(m_assetManager.getTexture("add"));
                var hitArea:Rectangle = hitAreas[i];
                icon.pivotX = icon.width * 0.5;
                icon.pivotY = icon.height * 0.5;
                icon.x = hitArea.width * 0.5;
                icon.y = hitArea.height * 0.5;
                
                var scaleFactor:Number = 1.0;
                if (icon.width > hitArea.width)
                {
                    scaleFactor = Math.min(scaleFactor, hitArea.width / icon.width);
                }
                
                if (icon.height > hitArea.height)
                {
                    scaleFactor = Math.min(scaleFactor, hitArea.height / icon.height);   
                }
                icon.scaleX = icon.scaleY = scaleFactor;
                
                hitAreaGraphics[i].addChild(icon);
            }
        }
        
        /**
         * Determine whether the buffered release event was within the hit area
         * 
         * @return
         *      true if the mouse hit the designated area and successfully triggered the action
         */
        private function checkHitArea():Boolean
        {
            m_hitAreas.length = 0;
            var doAddNewBar:Boolean = false;
            
            // Check if the number of whole bars is below the limit
            if (m_maxBarsAllowed < 0 || m_barModelArea.getBarModelData().barWholes.length < m_maxBarsAllowed)
            {
                // First we need to check whether the area of release allows for the addition of a new bar.
                // If the model area is empty and is in the bounds of the model area then always add a new bar
                // otherwise, check if the card is dropped below the bounds of the LAST whole bar
                // If mouse point is inside the bar model area bounds then we are ok
                var barWholeViews:Vector.<BarWholeView> = m_barModelArea.getBarWholeViews();
                
                // Calculate the hit areas, size depends on whether there are existing bars
                if (barWholeViews.length > 0)
                {
                    var lastBarWholeView:BarWholeView = barWholeViews[barWholeViews.length - 1];
                    var barWholeViewBounds:Rectangle = lastBarWholeView.getBounds(m_barModelArea);
                    
                    // HACK: Hit area looks nicer if there is some side padding and if it doesn't intersect with
                    // the add horizontal label hit area
                    var bottomPadding:Number = 8;
                    var rightPadding:Number = 15;
                    var topPadding:Number = 35; // TODO: Dependent on knowing the size of the add horizontal label hit area
                    
                    var minDimension:Number = 4;
                    var hitAreaWidth:Number = m_barModelArea.getConstraints().width - barWholeViewBounds.left - rightPadding;
                    if (hitAreaWidth < minDimension)
                    {
                        hitAreaWidth = minDimension;
                    }
                    var hitAreaHeight:Number = m_barModelArea.getConstraints().height - barWholeViewBounds.bottom - topPadding - bottomPadding;
                    if (hitAreaHeight < minDimension)
                    {
                        hitAreaHeight = minDimension;
                    }
                    m_hitAreas.push(new Rectangle(barWholeViewBounds.left, barWholeViewBounds.bottom + topPadding,
                        hitAreaWidth, hitAreaHeight));
                }
                else
                {
                    m_hitAreas.push(m_barModelArea.getConstraints());
                }
                
                // HACK: Hit area and the bounding boxes do not exactly match, extra padding left of the bars is ignored
                var modelAreaBounds:Rectangle = m_barModelArea.getBounds(m_barModelArea);
                if (modelAreaBounds.containsPoint(m_localMouseBuffer))
                {
                    doAddNewBar = true;
                    if (barWholeViewBounds != null)
                    {
                        doAddNewBar = m_localMouseBuffer.y > barWholeViewBounds.bottom;
                    }
                }
            }
            
            return doAddNewBar;
        }
        
        public function addNewBar(barWholes:Vector.<BarWhole>, 
                                  data:String,
                                  color:uint,
                                  labelValueOnTop:String,
                                  id:String=null):void
        {
            var value:Number = parseFloat(data);
            
            // Any non numeric cards default to a unit of 1
            // (This value can be set in the extra data field of a level file)
            var targetNumeratorValue:Number = 1;
            var targetDenominatorValue:Number = 1;
            if (!isNaN(value))
            {
                // Possible the value is negative, right now don't have this affect the ratio
                targetNumeratorValue = Math.abs(value);
                targetDenominatorValue = m_barModelArea.normalizingFactor;
            }
            else
            {
                var termToValueMap:Object = (m_gameEngine != null) ? m_gameEngine.getCurrentLevel().termValueToBarModelValue : m_termToValueMap;
                if (termToValueMap != null && termToValueMap.hasOwnProperty(data))
                {
                    targetNumeratorValue = termToValueMap[data];
                    targetDenominatorValue = m_barModelArea.normalizingFactor;
                }
            }

            var newBarWhole:BarWhole = new BarWhole(true, id);
            var newBarSegment:BarSegment = new BarSegment(targetNumeratorValue, targetDenominatorValue, color, null);
            newBarWhole.barSegments.push(newBarSegment);
            
            if (labelValueOnTop != null)
            {
                var newBarLabel:BarLabel = new BarLabel(labelValueOnTop, 0, 0, true, false, BarLabel.BRACKET_NONE, null);
                newBarWhole.barLabels.push(newBarLabel);
            }
            
            barWholes.push(newBarWhole);
        }
    }
}