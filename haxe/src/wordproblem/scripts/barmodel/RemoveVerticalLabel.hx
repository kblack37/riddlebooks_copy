package wordproblem.scripts.barmodel;


import openfl.geom.Point;
import openfl.geom.Rectangle;
import wordproblem.engine.events.DataEvent;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.ui.MouseState;

import openfl.display.DisplayObject;

import wordproblem.display.Layer;
import wordproblem.engine.IGameEngine;
//import wordproblem.engine.animation.RingPulseAnimation;
import wordproblem.engine.barmodel.animation.RemoveResizeableBarPieceAnimation;
import wordproblem.engine.barmodel.model.BarLabel;
import wordproblem.engine.barmodel.model.BarModelData;
import wordproblem.engine.barmodel.view.BarLabelView;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;

// TODO: revisit animation when more basic display elements are working

class RemoveVerticalLabel extends BaseBarModelScript implements IRemoveBarElement
{
    /**
     * When the user presses down this is the label that was selected.
     * Null if no valid label was selected on press
     */
    private var m_hitBarLabelView : BarLabelView;
    
    /**
     * Pulse that plays when user presses on an edge that resizes
     */
    //private var m_ringPulseAnimation : RingPulseAnimation;
    
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
        
        //m_ringPulseAnimation = new RingPulseAnimation(assetManager.getTexture("ring"), onRingPulseAnimationComplete);
        m_labelDescriptionBounds = new Rectangle();
    }
    
    public function removeElement(element : DisplayObject) : Bool
    {
        var canRemove : Bool = false;
        if (Std.is(element, BarLabelView)) 
        {
            var hitBarLabelView : BarLabelView = try cast(element, BarLabelView) catch(e:Dynamic) null;
            if (hitBarLabelView.data.bracketStyle == BarLabel.BRACKET_STRAIGHT && !hitBarLabelView.data.isHorizontal) 
            {
                canRemove = true;
                
                // Remove on drag out
                var verticalBarLabels : Array<BarLabel> = m_barModelArea.getBarModelData().verticalBarLabels;
                var numVerticalBarLabels : Int = verticalBarLabels.length;
                var i : Int = 0;
                var verticalBarLabel : BarLabel = null;
                for (i in 0...numVerticalBarLabels){
                    verticalBarLabel = verticalBarLabels[i];
                    if (verticalBarLabel.id == hitBarLabelView.data.id) 
                    {
                        // Create animation where the label quickly shrinks in size like it is being rolled up before
                        // falling off the edge (Need to create a clone of the label as the original is disposed on a redraw)
                        var removedLabelView : BarLabelView = m_barModelArea.createBarLabelView(hitBarLabelView.data);
                        removedLabelView.resizeToLength(hitBarLabelView.pixelLength);
                        var globalCoordinates : Point = hitBarLabelView.localToGlobal(new Point(0, 0));
                        removedLabelView.x = globalCoordinates.x;
                        removedLabelView.y = globalCoordinates.y;
                        var removeBarLabelAnimation : RemoveResizeableBarPieceAnimation = new RemoveResizeableBarPieceAnimation(function() : Void
                        {
							if (removedLabelView.parent != null) removedLabelView.parent.removeChild(removedLabelView);
							removedLabelView.dispose();
                        });
                        removedLabelView.scaleX = removedLabelView.scaleY = m_barModelArea.scaleFactor;
                        m_gameEngine.getSprite().addChild(removedLabelView);
                        removeBarLabelAnimation.play(removedLabelView);
                        
                        var previousModelDataSnapshot : BarModelData = m_barModelArea.getBarModelData().clone();
                        verticalBarLabels.splice(i, 1);
                        m_gameEngine.dispatchEvent(new DataEvent(GameEvent.BAR_MODEL_AREA_CHANGE, {
                                    previousSnapshot : previousModelDataSnapshot
                                }));
                        m_barModelArea.redraw();
                        
                        // Log removal of a label across whole bars
                        m_gameEngine.dispatchEvent(new DataEvent(AlgebraAdventureLoggingConstants.REMOVE_VERTICAL_LABEL, {
                                    barModel : m_barModelArea.getBarModelData().serialize()
                                }));
                        
                        break;
                    }
                }
            }
        }
        
        return canRemove;
    }
    
    override public function reset() : Void
    {
        super.reset();
        
        if (m_hitBarLabelView != null) 
        {
            m_hitBarLabelView.setBracketAndDescriptionAlpha(1.0);
            m_hitBarLabelView = null;
        }
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
                m_hitBarLabelView = checkHitVerticalLabel();
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
                
                m_hitBarLabelView.setBracketAndDescriptionAlpha(1.0);
                m_hitBarLabelView = null;
            }
        }
        return status;
    }
    
    /**
     * Function checks if the current mouse point (with frame of reference to the bar model area) has
     * hit the appropriate area of a horizontal label.
     * 
     * @return
     *      null if no label hit, else the bar label view that was struck
     */
    private function checkHitVerticalLabel() : BarLabelView
    {
        var hitLabel : BarLabelView = null;
        var verticalBarLabelViews : Array<BarLabelView> = m_barModelArea.getVerticalBarLabelViews();
        var numVerticalBarLabels : Int = verticalBarLabelViews.length;
        var i : Int = 0;
        var verticalBarLabelView : BarLabelView = null;
        for (i in 0...numVerticalBarLabels){
            verticalBarLabelView = verticalBarLabelViews[i];
            
            if (verticalBarLabelView.data.bracketStyle != BarLabel.BRACKET_NONE && m_barModelArea.stage != null) 
            {
                // The rigid body property accounts for the brackets
                var didHitLabel : Bool = verticalBarLabelView.rigidBody.boundingRectangle.containsPoint(m_localMouseBuffer);
                
                if (!didHitLabel) 
                {
                    // We also factor in the label graphic
                    var labelDescriptionDisplay : DisplayObject = verticalBarLabelView.getDescriptionDisplay();
                    m_labelDescriptionBounds = labelDescriptionDisplay.getBounds(m_barModelArea);
                    didHitLabel = m_labelDescriptionBounds.containsPoint(m_localMouseBuffer);
                }
                
                if (didHitLabel) 
                {
                    hitLabel = verticalBarLabelView;
                    break;
                }
            }
        }
        
        return hitLabel;
    }
    
    private function onRingPulseAnimationComplete() : Void
    {
        // Make sure animation isn't showing
        //Starling.current.juggler.remove(m_ringPulseAnimation);
    }
}
