package wordproblem.hints.tips;

import dragonbox.common.math.vectorspace.RealsVectorSpace;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.errors.Error;
import openfl.text.TextFormatAlign;

import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.TextFormat;

import dragonbox.common.eventsequence.EventSequencer;
import dragonbox.common.expressiontree.ExpressionNode;
import dragonbox.common.math.vectorspace.IVectorSpace;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.EventDispatcher;
import openfl.text.TextField;

import wordproblem.engine.expression.ExpressionSymbolMap;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.text.MeasuringTextField;
import wordproblem.hints.scripts.IShowableScript;
import wordproblem.hints.tips.util.SimulatedMouseVisualizer;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.drag.WidgetDragSystem;

/**
 * Common code for a tip showing a simple gesture along with a short title and description.
 * 
 * Includes basic utility methods that base classes can refer to
 */
class GestureAndTextTip extends ScriptNode implements IShowableScript
{
    
    /**
     * Main part to paste graphic onto
     */
    private var m_canvas : DisplayObjectContainer;
    
    /**
     * Mouse that is manually controlled programatically
     */
    private var m_simulatedMouseState : MouseState;
    
    /**
     * A ticking timer so we can figure out how much time elapsed on
     * each update frame.
     */
    private var m_simulatedTimer : Time;
    
    /**
     * Display part containing all the visual elements related to this tip.
     */
    private var m_mainDisplay : Sprite;
    
    /**
     * The label name that should show up what is being demonstrated by the tip
     */
    private var m_titleText : String;
    
    /**
     * Text for more detailed description of what the tip is actually showing
     */
    private var m_descriptionText : String;
    
    /**
     * This is the list of actions that should be taken over the course of time.
     * (A bit hacky this is mainly a way to control the mouse state for scripts that
     * need such control)
     */
    private var m_playbackEvents : EventSequencer;
    
    /**
     * Any script that uses this MUST call update AFTER it is done executing the children
     */
    private var m_simulatedMouseVisualizer : SimulatedMouseVisualizer;
    
    private var m_assetManager : AssetManager;
    
    private var m_gameEnginePlaceholderEventDispatcher : EventDispatcher;
    
    public function new(expressionSymbolMap : ExpressionSymbolMap,
            canvas : DisplayObjectContainer,
            mouseState : MouseState,
            time : Time,
            assetManager : AssetManager,
            titleText : String,
            descriptionText : String,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_mainDisplay = new Sprite();
        m_gameEnginePlaceholderEventDispatcher = new EventDispatcher();
        m_canvas = canvas;
        
        m_simulatedMouseState = mouseState;
        m_simulatedTimer = time;
        m_assetManager = assetManager;
        
        m_titleText = titleText;
        m_descriptionText = descriptionText;
        
        m_simulatedMouseVisualizer = new SimulatedMouseVisualizer(mouseState, canvas, assetManager);
    }
    
    override public function visit() : Int
    {
        // Reset simulated mouse on every frame
        m_simulatedMouseState.onEnterFrame(null);
        
        // Heavy Lifting done here
        // The mouse needs to take the dragged object and move it to
        if (m_playbackEvents != null) 
        {
            m_playbackEvents.update(m_simulatedTimer);
        }
        m_simulatedMouseVisualizer.update();
        
        return ScriptStatus.SUCCESS;
    }
    
    public function show() : Void
    {
        throw new Error("Must override");
    }
    
    public function hide() : Void
    {
        m_simulatedMouseVisualizer.hide();
        
        m_mainDisplay.removeChildren();
        if (m_mainDisplay.parent != null) m_mainDisplay.parent.removeChild(m_mainDisplay);
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        m_simulatedMouseVisualizer.dispose();
    }
    
    private function drawTextOnMainDisplay(maxTitleWidth : Float,
            titleX : Float,
            titleY : Float,
            descriptionX : Float,
            descriptionY : Float,
            descriptionWidth : Float = 400) : Void
    {
        var measuringText : MeasuringTextField = new MeasuringTextField();
        var textFormat : TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 32, 0xFFFFFF);
        measuringText.defaultTextFormat = textFormat;
        measuringText.wordWrap = false;
        measuringText.width = maxTitleWidth;
        measuringText.text = m_titleText;
        
        var titleTextfield : TextField = new TextField();
		titleTextfield.width = maxTitleWidth;
		titleTextfield.height = measuringText.textHeight + 10;
		titleTextfield.text = m_titleText;
		titleTextfield.setTextFormat(new TextFormat(textFormat.font, textFormat.size, textFormat.color, null, null, null, null, null, TextFormatAlign.CENTER));
		titleTextfield.y = titleY;
		titleTextfield.x = titleX;
		m_mainDisplay.addChild(titleTextfield);
        
        // Need some space between the text and the outline
        var outlinePadding : Float = 15;
        measuringText.wordWrap = true;
        measuringText.width = descriptionWidth - 2 * outlinePadding;
        measuringText.text = m_descriptionText;
        
        var descriptionTextField : TextField = new TextField();
		descriptionTextField.width = measuringText.width;
		descriptionTextField.height = measuringText.textHeight + 10;
		descriptionTextField.text = m_descriptionText;
		descriptionTextField.setTextFormat(new TextFormat(textFormat.font, 26, textFormat.color));
        var scale9Padding : Float = 12;
        
        // TEMP: No chalk outline as it may cause unneeded clutter
		var chalkOutlineBitmapData : BitmapData = m_assetManager.getBitmapData("chalk_outline");
        var chalkOutline : Bitmap = new Bitmap(chalkOutlineBitmapData);
		chalkOutline.scale9Grid = new Rectangle(scale9Padding, scale9Padding, chalkOutlineBitmapData.width - 2 * scale9Padding, chalkOutlineBitmapData.height - 2 * scale9Padding);
        chalkOutline.width = descriptionWidth;
        chalkOutline.height = descriptionTextField.height + outlinePadding * 2;
        chalkOutline.x = descriptionX;
        chalkOutline.y = descriptionY;
        //m_mainDisplay.addChild(chalkOutline);
        
        descriptionTextField.x = chalkOutline.x + outlinePadding;
        descriptionTextField.y = chalkOutline.y + outlinePadding;
        m_mainDisplay.addChild(descriptionTextField);
    }
    
    /*
    Common helper function used by several tips
    */
    
    /**
     * @param startLocation
     *      The start location of the drag in global coordinates
     */
    private function pressAndStartDragOfExpression(startLocation : Point,
            draggedExpression : String,
            widgetDragSystem : WidgetDragSystem,
            vectorSpace : RealsVectorSpace) : Void
    {
        setMouseLocation(startLocation);
        
        widgetDragSystem.selectAndStartDrag(new ExpressionNode(vectorSpace, draggedExpression), startLocation.x, startLocation.y, null, null);
        m_simulatedMouseState.leftMousePressedThisFrame = true;
    }
    
    private function setMouseLocation(startLocation : Point) : Void
    {
        m_simulatedMouseState.mousePositionThisFrame.x = startLocation.x;
        m_simulatedMouseState.mousePositionThisFrame.y = startLocation.y;
    }
    
    private function pressMouseAtCurrentPoint() : Void
    {
        m_simulatedMouseState.leftMousePressedThisFrame = true;
        m_simulatedMouseState.leftMouseDown = true;
    }
    
    private function releaseMouse() : Void
    {
        m_simulatedMouseState.leftMouseReleasedThisFrame = true;
    }
    
    private function holdDownMouse() : Void
    {
        m_simulatedMouseState.leftMouseDown = true;
    }
}
