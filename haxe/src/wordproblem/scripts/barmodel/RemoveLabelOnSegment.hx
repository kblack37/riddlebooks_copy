package wordproblem.scripts.barmodel;


import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.ui.MouseState;

import motion.Actuate;

import openfl.display.DisplayObject;
import openfl.geom.Point;
import openfl.geom.Rectangle;

import wordproblem.display.Layer;
import wordproblem.display.PivotSprite;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.model.BarWhole;
import wordproblem.engine.barmodel.view.BarLabelView;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.barmodel.view.BarWholeView;
import wordproblem.engine.events.DataEvent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.resource.AssetManager;

/**
 * This script handles the removal of a label that is pasted directly on top
 * of a bar segment.
 */
class RemoveLabelOnSegment extends BaseBarModelScript implements IRemoveBarElement
{
    /**
     * When the user presses down this is the label that was selected.
     * Null if no valid label was selected on press
     */
    private var m_hitBarLabelView : BarLabelView;
    
    /**
     * To remove a label, we detect a press on the descrption area for that label
     */
    private var m_labelDescriptionBounds : Rectangle;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_labelDescriptionBounds = new Rectangle();
    }
    
    public function removeElement(element : DisplayObject) : Bool
    {
        var canRemove : Bool = false;
        if (Std.is(element, BarLabelView)) 
        {
            var hitBarLabelView : BarLabelView = try cast(element, BarLabelView) catch(e:Dynamic) null;
            if (hitBarLabelView.data.bracketStyle == BarLabel.BRACKET_NONE && hitBarLabelView.data.isHorizontal) 
            {
                canRemove = true;
                
                // Delete the label
                var barWholes : Array<BarWhole> = m_barModelArea.getBarModelData().barWholes;
                var numBarWholes : Int = barWholes.length;
                var i : Int = 0;
                var barWhole : BarWhole = null;
                var foundMatchingLabel : Bool = false;
                for (i in 0...numBarWholes){
                    barWhole = barWholes[i];
                    
                    var barLabels : Array<BarLabel> = barWhole.barLabels;
                    var numBarLabels : Int = barLabels.length;
                    var j : Int = 0;
                    var barLabel : BarLabel = null;
                    for (j in 0...numBarLabels){
                        barLabel = barLabels[j];
                        if (barLabel.id == hitBarLabelView.data.id) 
                        {
                            var referencedSegmentView : BarSegmentView = m_barModelArea.getBarWholeViews()[i].segmentViews[barLabel.startSegmentIndex];
                            var segementViewBounds : Rectangle = referencedSegmentView.rigidBody.boundingRectangle;
                            
                            // Create copy of the label for the animation, original gets disposed on redraw
                            var removedLabelView : BarLabelView = m_barModelArea.createBarLabelView(hitBarLabelView.data);
                            removedLabelView.rescaleAndRedraw(segementViewBounds.width, segementViewBounds.height, 1, 1);
                            removedLabelView.resizeToLength(hitBarLabelView.pixelLength);
                            var globalCoordinates : Point = hitBarLabelView.localToGlobal(new Point(0, 0));
							var removedLabelViewPivot : PivotSprite = new PivotSprite();
							removedLabelViewPivot.addChild(removedLabelView);
                            removedLabelViewPivot.pivotX = removedLabelView.width * 0.5;
                            removedLabelViewPivot.pivotY = removedLabelView.height * 0.5;
                            removedLabelViewPivot.x = globalCoordinates.x + removedLabelViewPivot.pivotX;
                            removedLabelViewPivot.y = globalCoordinates.y + removedLabelViewPivot.pivotY;
                            
							Actuate.tween(removedLabelViewPivot, 0.5,
								{ rotation: -90, alpha: 0, scaleX: 0.2, scaleY:0.2, x: removedLabelViewPivot.x - 200 }).smartRotation().onComplete(function() : Void
                                    {
										if (removedLabelViewPivot.parent != null) removedLabelViewPivot.parent.removeChild(removedLabelViewPivot);
										removedLabelViewPivot.dispose();
										removedLabelViewPivot = null;
                                    });
                            
                            m_gameEngine.getSprite().stage.addChild(removedLabelView);
                            
                            var previousModelDataSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
                            barWhole.barLabels.splice(j, 1);
                            m_gameEngine.dispatchEvent(new DataEvent(GameEvent.BAR_MODEL_AREA_CHANGE, {
                                        previousSnapshot : previousModelDataSnapshot
                                    }));
                            
                            m_barModelArea.redraw();
                            foundMatchingLabel = true;
                            break;
                        }
                    }
                    
                    if (foundMatchingLabel) 
                    {
                        break;
                    }
                }
            }
        }
        
        return canRemove;
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.FAIL;
        if (m_ready && m_isActive && !Layer.getDisplayObjectIsInInactiveLayer(m_barModelArea)) 
        {
            var mouseState : MouseState = m_gameEngine.getMouseState();
            m_globalMouseBuffer.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
            m_localMouseBuffer = m_barModelArea.globalToLocal(m_globalMouseBuffer);
            
            if (mouseState.leftMousePressedThisFrame) 
            {
                m_hitBarLabelView = checkHitLabel();
                if (m_hitBarLabelView != null) 
                {
                    m_hitBarLabelView.setBracketAndDescriptionAlpha(0.3);
                    //m_ringPulseAnimation.reset(m_localMouseBuffer.x, m_localMouseBuffer.y, m_barModelArea, 0xFF0000);
                    //Starling.current.juggler.add(m_ringPulseAnimation);
                    status = ScriptStatus.SUCCESS;
                }
            }
            else if ((mouseState.leftMouseDraggedThisFrame || mouseState.leftMouseReleasedThisFrame) && m_hitBarLabelView != null) 
            {
                if (removeElement(m_hitBarLabelView)) 
                {
                    status = ScriptStatus.SUCCESS;
                }
                
                m_hitBarLabelView = null;
            }
        }
        
        return status;
    }
    
    /**
     *
     * @return
     *      null if no label hit,
     */
    private function checkHitLabel() : BarLabelView
    {
        var hitLabel : BarLabelView = null;
        var barWholeViews : Array<BarWholeView> = m_barModelArea.getBarWholeViews();
        var numBarWholeViews : Int = barWholeViews.length;
        var i : Int = 0;
        for (i in 0...numBarWholeViews){
            var barLabelViews : Array<BarLabelView> = barWholeViews[i].labelViews;
            var numBarLabelViews : Int = barLabelViews.length;
            var j : Int = 0;
            var barLabelView : BarLabelView = null;
            for (j in 0...numBarLabelViews){
                barLabelView = barLabelViews[j];
                
                if (barLabelView.data.bracketStyle == BarLabel.BRACKET_NONE && m_barModelArea.stage != null) 
                {
                    // For labels directly on a segment we only factor in the label graphic
                    // since that is all that is there
                    var labelDescriptionDisplay : DisplayObject = barLabelView.getDescriptionDisplay();
                    m_labelDescriptionBounds = labelDescriptionDisplay.getBounds(m_barModelArea);
                    if (m_labelDescriptionBounds.containsPoint(m_localMouseBuffer)) 
                    {
                        hitLabel = barLabelView;
                        break;
                    }
                }
            }
            
            if (hitLabel != null) 
            {
                break;
            }
        }
        
        return hitLabel;
    }
}
