package wordproblem.scripts.barmodel;


import cgs.audio.Audio;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.util.XColor;

import haxe.Constraints.Function;

import motion.Actuate;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.events.MouseEvent;
import openfl.filters.BitmapFilter;

import wordproblem.callouts.TooltipControl;
import wordproblem.display.LabelButton;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.widget.WidgetUtil;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;

/**
 * Handles the logic involved with sliding a portion of the ui up and down to switch between
 * bar modeling and equation modeling.
 */
class SwitchBetweenBarAndEquationModel extends BaseGameScript
{
    private var m_switchModelButton : LabelButton;
    
    /**
     * Need to remember if the ui is in a down state or an up state.
     * 
     * This is true if ui is in a down state where the equation model portion is
     * presumably hidden.
     */
    private var m_inSlideDownState : Bool;
    
    /**
     * Callback when the sliding is completed
     * 
     * Callback accepts boolean that is true if the ui is in bar model mode
     * and false if it is in equation mode
     */
    private var m_onSwitchModelClick : Function;
    
    /**
     * Original y location of the ui container
     */
    private var m_deckAndTermContainerOriginalY : Float;
    
    private var m_tooltipControl : TooltipControl;
    private inline static var TOOLTIP_SHOW_EQUATION : String = "Show Equation";
    private inline static var TOOLTIP_SHOW_TEXT : String = "Show Problem";
    
    /**
     * The y value of the ui that is should move to when revealing the model area
     */
    public var targetY : Float = 30;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            onSwitchModelClick : Function,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        m_onSwitchModelClick = onSwitchModelClick;
    }
    
    /**
     * Due to timing issues of when this script gets called vs other scripts messing with the
     * positioning of the container, have this extra function that explicitly sets the 'resting value'
     * of the container
     */
    public function setContainerOriginalY(value : Float) : Void
    {
        m_deckAndTermContainerOriginalY = value;
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        
        if (m_ready) 
        {
            // Set whether the button is enabled
            m_switchModelButton.enabled = value;
            m_switchModelButton.removeEventListener(MouseEvent.CLICK, onSwitchModelClicked);
            if (value) 
            {
                m_switchModelButton.addEventListener(MouseEvent.CLICK, onSwitchModelClicked);
                
                // Set color to normal
				m_switchModelButton.filters = new Array<BitmapFilter>();
                m_switchModelButton.alpha = 1.0;
            }
            else 
            {
                // Set color to grey scale
				var filters = new Array<BitmapFilter>();
				filters.push(XColor.getGrayscaleFilter());
				m_switchModelButton.filters = filters;
                m_switchModelButton.alpha = 0.5;
            }
        }
    }
    
    override public function visit() : Int
    {
        if (m_ready && m_isActive) 
        {
            m_tooltipControl.onEnterFrame();
        }
        return ScriptStatus.SUCCESS;
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_tooltipControl.dispose();
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        
        // We perform the drawing of the button here since it's graphics require some special drawing
        var switchModelCanvas : DisplayObjectContainer = try cast(m_gameEngine.getUiEntity("switchModelButton"), DisplayObjectContainer) catch(e:Dynamic) null;
        var switchModelButton : LabelButton = WidgetUtil.createButton(
                m_assetManager,
                "button_sidebar_maximize",
                "button_sidebar_maximize_click",
                null,
                "button_sidebar_maximize_mouseover",
                null,
                null
                );
        switchModelButton.width = switchModelButton.height = 52;
        switchModelButton.pivotX = switchModelButton.width * 0.5;
        switchModelButton.pivotY = switchModelButton.height * 0.5;
        
        // Initial graphic has arrow pointing to the right
        // Make it point down
        switchModelButton.rotation = Math.PI * 0.5;
        m_inSlideDownState = true;
        
        switchModelButton.x += switchModelButton.pivotX;
        switchModelButton.y += switchModelButton.pivotY;
        
        m_switchModelButton = switchModelButton;
        switchModelCanvas.addChild(switchModelButton);
        
        m_tooltipControl = new TooltipControl(m_gameEngine, "switchModelButton", TOOLTIP_SHOW_EQUATION, "Verdana", 14);
        
        // Reset active flag
        this.setIsActive(m_isActive);
    }
    
    public function onSwitchModelClicked(event : Dynamic) : Void
    {
        Audio.instance.playSfx("page_flip");
        
        // Perform animation of the button rotating between pointing up and down.
        var uiContainer : DisplayObject = m_gameEngine.getUiEntity("deckAndTermContainer");
        var targetRotation : Float = 0.0;
        var targetY : Float = 0.0;
        if (m_inSlideDownState) 
        {
            targetRotation = -90;
            targetY = this.targetY;
            m_tooltipControl.setText(TOOLTIP_SHOW_TEXT);
        }
        else 
        {
            targetRotation = 90;
            targetY = m_deckAndTermContainerOriginalY;
            m_tooltipControl.setText(TOOLTIP_SHOW_EQUATION);
        }
        m_inSlideDownState = !m_inSlideDownState;
        
        if (m_onSwitchModelClick != null) 
        {
            m_onSwitchModelClick(m_inSlideDownState);
        }
        
        var rotateDuration : Float = 0.2;
		Actuate.tween(m_switchModelButton, rotateDuration, { rotation: targetRotation }).smartRotation();
		
		Actuate.tween(uiContainer, rotateDuration, { y: targetY });
    }
}
