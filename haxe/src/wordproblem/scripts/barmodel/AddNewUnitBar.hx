package wordproblem.scripts.barmodel;

import wordproblem.scripts.barmodel.BaseBarModelScript;
import wordproblem.scripts.barmodel.IHitAreaScript;

import flash.geom.Point;
import flash.geom.Rectangle;

import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.expressiontree.ExpressionUtil;
import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.system.RectanglePool;
import dragonbox.common.ui.MouseState;

import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.events.EventDispatcher;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarSegment;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.barmodel.view.BarModelView;
import wordproblem.engine.barmodel.view.BarWholeView;
import wordproblem.engine.component.BlinkComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.expression.SymbolData;
import wordproblem.engine.expression.widget.term.BaseTermWidget;
import wordproblem.engine.expression.widget.term.SymbolTermWidget;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.widget.BarModelAreaWidget;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.drag.WidgetDragSystem;

/**
 * Add a bar that is already split into equal sized segments. The number of segments is based on the number
 * that was dropped.
 * 
 * The way this works is that the segments in the very first bar act as a reference length or an arbitrary width is used.
 * This script creates multiples of a segment to form a new bar.
 */
class AddNewUnitBar extends BaseBarModelScript implements IHitAreaScript
{
    /**
     * The is a constraint to prevent the creation of too many segments at once that might
     * cause the system to crash.
     * 
     * (At high numbers viewing each individual box is probably not useful anyways)
     */
    private static inline var MAX_ALLOWABLE_UNITS : Int = 40;
    
    /**
     * The limit to the number of barwholes that can be in the bar model area at the same time.
     * If less than zero, an unlimited number of bars are allowed.
     */
    private var m_maxBarsAllowed : Int;
    
    /**
     * The color that is used for the preview should be the same one used when the actual
     * segment is created.
     */
    private var m_previewColor : Int;
    
    /**
     * The dimensions of the hit box used to figure out whether a drop of a card should
     * trigger add a new unit bar.
     */
    private var m_addUnitHitAreas : Array<Rectangle>;
    
    private var m_hitAreaPool : RectanglePool;
    
    /**
     * Should hit areas for this action be shown in at the start of a frame
     */
    private var m_showHitAreas : Bool;
    
    private var m_expressionSymbolMap : ExpressionSymbolMap;
    
    /**
     * HACK: Specify a fixed unit value if a script wants to use this logic independent of the game engine
     */
    private var m_fixedDefaultUnitValue : Int;
    
    private inline var PREVIEW_NEW_BAR_ID : String = "preview_unit_bar";
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            maxBarsAllowed : Int,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        m_previewColor = 0xFFFFFF;
        m_maxBarsAllowed = maxBarsAllowed;
        m_addUnitHitAreas = new Array<Rectangle>();
        m_hitAreaPool = new RectanglePool();
    }
    
    public function setParams(barModelArea : BarModelAreaWidget,
            widgetDragSystem : WidgetDragSystem,
            mouseState : MouseState,
            expressionSymbolMap : ExpressionSymbolMap,
            fixedDefaultUnitValue : Int,
            eventDispatcher : EventDispatcher) : Void
    {
        super.setCommonParams(barModelArea, widgetDragSystem, eventDispatcher, mouseState);
        m_expressionSymbolMap = expressionSymbolMap;
        m_fixedDefaultUnitValue = fixedDefaultUnitValue;
    }
    
    /**
     * Expose this so tutorials can freely change this restriction during course of a level.
     * Useful also if the script gets created before rules have been parsed (perhaps some
     * data gets loaded later)
     */
    public function setMaxBarsAllowed(value : Int) : Void
    {
        m_maxBarsAllowed = value;
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.FAIL;
        m_showHitAreas = false;
        if (m_ready && m_isActive) 
        {
            m_globalMouseBuffer.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
            m_barModelArea.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
            
            var barWholeViews : Array<BarWholeView> = m_barModelArea.getBarWholeViews();
            var valuePerSegment : Int = ((m_gameEngine == null)) ? m_fixedDefaultUnitValue : m_gameEngine.getCurrentLevel().defaultUnitValue;
            
            // The hit area of add unit bar is to the left of the horizontal starting bar
            // and just underneath the last whole bar.
            // Note that a unit bar only make sense if there is one bar already placed down that
            // acts as a reference
            var allowAddNewBar : Bool = (m_maxBarsAllowed < 0 || m_barModelArea.getBarWholeViews().length < m_maxBarsAllowed);
            if (m_eventTypeBuffer.length > 0) 
            {
                var data : Dynamic = m_eventParamBuffer[0];
                var releasedWidget : BaseTermWidget = data.widget;
                
                if (Std.is(releasedWidget, SymbolTermWidget) && checkHitArea(m_localMouseBuffer) && allowAddNewBar) 
                {
                    if (ExpressionUtil.isNodeNumeric(releasedWidget.getNode()) &&
                        parseFloat(releasedWidget.getNode().data) < AddNewUnitBar.MAX_ALLOWABLE_UNITS) 
                    {
                        m_barModelArea.showPreview(false);
                        m_didActivatePreview = false;
                        
                        var numSegments : Int = parseInt(releasedWidget.getNode().data);
                        var targetNumeratorValue : Float = ((valuePerSegment > -1)) ? valuePerSegment : 1;
                        var targetDenominatorValue : Float = ((valuePerSegment > -1)) ? m_barModelArea.normalizingFactor : 1;
                        if (barWholeViews.length > 0) 
                        {
                            var referenceBar : BarWhole = barWholeViews[0].data;
                            var referenceSegment : BarSegment = referenceBar.barSegments[0];
                            targetNumeratorValue = referenceSegment.numeratorValue;
                            targetDenominatorValue = referenceSegment.denominatorValue;
                        }
                        
                        var previousModelDataSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
                        addNewUnitBar(
                                m_barModelArea.getBarModelData().barWholes,
                                releasedWidget.getNode().data,
                                targetNumeratorValue,
                                targetDenominatorValue,
                                numSegments,
                                m_previewColor
                                );
                        
                        if (m_gameEngine != null) 
                        {
                            m_gameEngine.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {
                                        previousSnapshot : previousModelDataSnapshot

                                    });
                            m_barModelArea.redraw();
                            
                            // Log addition of new unit bar
                            m_gameEngine.dispatchEventWith(AlgebraAdventureLoggingConstants.ADD_NEW_UNIT_BAR, false, {
                                        barModel : m_barModelArea.getBarModelData().serialize(),
                                        value : releasedWidget.getNode().data,

                                    });
                        }
                        
                        status = ScriptStatus.SUCCESS;
                    }
                }
                
                reset();
            }
            else if (m_widgetDragSystem.getWidgetSelected() != null && Std.is(m_widgetDragSystem.getWidgetSelected(), SymbolTermWidget)) 
            {
                var draggedExpressionNode : ExpressionNode = m_widgetDragSystem.getWidgetSelected().getNode();
                if (allowAddNewBar &&
                    ExpressionUtil.isNodeNumeric(draggedExpressionNode) &&
                    !draggedExpressionNode.isNegative() &&
                    parseFloat(draggedExpressionNode.data) < AddNewUnitBar.MAX_ALLOWABLE_UNITS) 
                {
                    m_showHitAreas = true;
                    if (checkHitArea(m_localMouseBuffer)) 
                    {
                        // This check shows the preview if either it was not showing already OR a lower priority
                        // script had activated it but we want to overwrite it.
                        if (!m_barModelArea.getPreviewShowing() || !m_didActivatePreview) 
                        {
                            targetNumeratorValue = ((valuePerSegment > -1)) ? valuePerSegment : 1;
                            targetDenominatorValue = ((valuePerSegment > -1)) ? m_barModelArea.normalizingFactor : 1;
                            if (m_barModelArea.getBarWholeViews().length > 0) 
                            {
                                referenceBar = m_barModelArea.getBarWholeViews()[0].data;
                                referenceSegment = referenceBar.barSegments[0];
                                targetNumeratorValue = referenceSegment.numeratorValue;
                                targetDenominatorValue = referenceSegment.denominatorValue;
                            }
                            
                            var previewView : BarModelView = m_barModelArea.getPreviewView(true);
                            numSegments = parseInt(draggedExpressionNode.data);
                            var extraDragParams : Dynamic = m_widgetDragSystem.getExtraParams();
                            var symbolDataForDragged : SymbolData = m_expressionSymbolMap.getSymbolDataFromValue(draggedExpressionNode.data);
                            if (extraDragParams != null && extraDragParams.exists("color")) 
                            {
                                m_previewColor = Reflect.field(extraDragParams, "color");
                            }
                            else if (symbolDataForDragged != null && symbolDataForDragged.useCustomBarColor) 
                            {
                                m_previewColor = symbolDataForDragged.customBarColor;
                            }
                            else 
                            {
                                m_previewColor = super.getRandomColorForSegment();
                            }
                            addNewUnitBar(previewView.getBarModelData().barWholes,
                                    draggedExpressionNode.data,
                                    targetNumeratorValue,
                                    targetDenominatorValue,
                                    numSegments,
                                    m_previewColor,
                                    PREVIEW_NEW_BAR_ID
                                    );
                            m_barModelArea.showPreview(true);
                            m_didActivatePreview = true;
                            
                            // Need to get at the bar view so we can blink it to indicate it is the new element
                            var newWholeBarView : BarWholeView = previewView.getBarWholeViewById(PREVIEW_NEW_BAR_ID);
                            m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(PREVIEW_NEW_BAR_ID));
                            var renderComponent : RenderableComponent = new RenderableComponent(PREVIEW_NEW_BAR_ID);
                            renderComponent.view = newWholeBarView;
                            m_barModelArea.componentManager.addComponentToEntity(renderComponent);
                        }
                        
                        status = ScriptStatus.SUCCESS;
                    }
                    else if (m_didActivatePreview) 
                    {
                        // Remove the preview if it was showing
                        m_barModelArea.showPreview(false);
                        m_didActivatePreview = false;
                        m_barModelArea.componentManager.removeAllComponentsFromEntity(PREVIEW_NEW_BAR_ID);
                    }
                }
            }
        }
        
        return status;
    }
    
    public function getActiveHitAreas() : Array<Rectangle>
    {
        this.calculateHitAreas();
        return m_addUnitHitAreas;
    }
    
    public function getShowHitAreasForFrame() : Bool
    {
        return m_showHitAreas;
    }
    
    public function postProcessHitAreas(hitAreas : Array<Rectangle>, hitAreaGraphics : Array<DisplayObjectContainer>) : Void
    {
        for (i in 0...hitAreaGraphics.length){
            var icon : Image = new Image(m_assetManager.getTexture("multiply_x"));
            var hitArea : Rectangle = hitAreas[i];
            icon.pivotX = icon.width * 0.5;
            icon.pivotY = icon.height * 0.5;
            icon.x = hitArea.width * 0.5;
            icon.y = hitArea.height * 0.5;
            hitAreaGraphics[i].addChild(icon);
        }
    }
    
    private function calculateHitAreas() : Void
    {
        m_hitAreaPool.returnRectangles(m_addUnitHitAreas);
        
        var newBarY : Float = m_barModelArea.topBarPadding;
        
        // Create the hit bounds which is just below the final view and to the left edge
        var barWholeViews : Array<BarWholeView> = m_barModelArea.getBarWholeViews();
        var numBarWholeViews : Int = barWholeViews.length;
        if (numBarWholeViews > 0) 
        {
            // the y should be where the new bar is expected to go
            var lastBarWholeView : BarWholeView = barWholeViews[numBarWholeViews - 1];
            var barWholeViewBounds : Rectangle = m_hitAreaPool.getRectangle();
            lastBarWholeView.getBounds(m_barModelArea, barWholeViewBounds);
            newBarY = barWholeViewBounds.bottom + m_barModelArea.barGap;
        }
        
        var hitAreaWidth : Float = m_barModelArea.leftBarPadding;
        var hitAreaHeight : Float = 50;
        var hitArea : Rectangle = m_hitAreaPool.getRectangle();
        hitArea.setTo(0, newBarY, hitAreaWidth, hitAreaHeight);
        m_addUnitHitAreas.push(hitArea);
    }
    
    /**
     *
     * @param mousePoint
     *      The mouse point in coordinates relative to the bar model area
     */
    private function checkHitArea(mousePoint : Point) : Bool
    {
        this.calculateHitAreas();
        var didHit : Bool = false;
        if (m_addUnitHitAreas.length > 0) 
        {
            didHit = m_addUnitHitAreas[0].containsPoint(mousePoint);
        }
        return didHit;
    }
    
    public function addNewUnitBar(barWholes : Array<BarWhole>,
            labelName : String,
            numeratorValuePerSegment : Float,
            denominatorValuePerSegment : Float,
            numSegments : Int,
            color : Int,
            id : String = null) : Void
    {
        var newBarWhole : BarWhole = new BarWhole(true, id);
        
        var i : Int;
        for (i in 0...numSegments){
            var newBarSegment : BarSegment = new BarSegment(numeratorValuePerSegment, denominatorValuePerSegment, color, null);
            newBarWhole.barSegments.push(newBarSegment);
        }
        
        barWholes.push(newBarWhole);
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        m_expressionSymbolMap = m_gameEngine.getExpressionSymbolResources();
    }
}
