package wordproblem.hints.scripts;


import cgs.audio.Audio;

import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;

import wordproblem.display.LabelButton;
import wordproblem.display.Layer;
import wordproblem.engine.IGameEngine;
import wordproblem.engine.events.DataEvent;
import wordproblem.engine.events.GameEvent;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseGameScript;

/**
 * This script listens for triggers from the currently running level and pastes an animated sequence
 * of how to perform a single gesture on top of everything.
 */
class ShowTipFromLink extends BaseGameScript
{
    private var m_simulatedMouseState : MouseState;
    private var m_simulatedTimer : Time;
    
    private var m_currentlyPlayingScript : ScriptNode;
    
    private var m_mainDisplayContainer : Sprite;
    
    // Reference background so we can detect clicks outside of it
    private var m_backgroundImage : DisplayObject;
    private var m_hintDisplayContainer : Sprite;
    private var m_disablingQuad : Bitmap;
    private var m_closeButton : LabelButton;
    
    private var m_screenWidth : Float = 800;
    private var m_screenHeight : Float = 600;
    private var m_mousePoint : Point;
    private var m_pressedOutsideBackground : Bool;
    
    public function new(gameEngine : IGameEngine,
            expressionCompiler : IExpressionTreeCompiler,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(gameEngine, expressionCompiler, assetManager, id, isActive);
        
        m_mainDisplayContainer = new Layer();
        var blockingQuad : Bitmap = new Bitmap(new BitmapData(Std.int(m_screenWidth), Std.int(m_screenHeight), false, 0x000000));
        blockingQuad.alpha = 0.7;
        m_mainDisplayContainer.addChild(blockingQuad);
        var backgroundImage : Bitmap = new Bitmap(m_assetManager.getBitmapData("summary_background"));
        backgroundImage.width = m_screenWidth * 0.8;
        backgroundImage.height = m_screenHeight * 0.8;
        backgroundImage.x = (m_screenWidth - backgroundImage.width) * 0.5;
        backgroundImage.y = (m_screenHeight - backgroundImage.height) * 0.5;
        m_backgroundImage = backgroundImage;
        m_mainDisplayContainer.addChild(backgroundImage);
        
        m_hintDisplayContainer = new Sprite();
        m_hintDisplayContainer.x = backgroundImage.x;
        m_hintDisplayContainer.y = backgroundImage.y;
        m_mainDisplayContainer.addChild(m_hintDisplayContainer);
        
        m_simulatedMouseState = new MouseState(null);
        m_simulatedTimer = new Time();
        
        var closeWidth : Float = 40;
        var closeIconBitmapData : BitmapData = assetManager.getBitmapData("wrong");
        var closeIcon : Bitmap = new Bitmap(closeIconBitmapData);
        m_closeButton = new LabelButton(closeIcon);
        m_closeButton.scaleWhenOver = 1.2;
        m_closeButton.scaleWhenDown = 0.8;
        m_closeButton.width = m_closeButton.height = closeWidth;
        m_closeButton.addEventListener(MouseEvent.CLICK, onCloseClicked);
        
        // The button needs to be positioned such that the edges just slightly touch the wooden border of the
        // screen (need to hardcode the width of the borders)
        var woodBorderThickness : Float = 27;
        m_closeButton.x = (backgroundImage.x + backgroundImage.width) - closeWidth;
        m_closeButton.y = backgroundImage.y;
        m_mainDisplayContainer.addChild(m_closeButton);
        
        m_mousePoint = new Point();
        m_pressedOutsideBackground = false;
    }
    
    override public function visit() : Int
    {
        m_simulatedMouseState.onEnterFrame({ });
        m_simulatedTimer.update();
        
        if (m_currentlyPlayingScript != null) 
        {
            m_currentlyPlayingScript.visit();
        } 
		
		// If click outside the boundary, dismiss the tip  
        var mouseState : MouseState = m_gameEngine.getMouseState();
        m_mousePoint.x = mouseState.mousePositionThisFrame.x;
        m_mousePoint.y = mouseState.mousePositionThisFrame.y;
        if (mouseState.leftMousePressedThisFrame) 
        {
            if (m_mousePoint.x < m_backgroundImage.x || m_mousePoint.y < m_backgroundImage.y ||
                m_mousePoint.x > m_backgroundImage.width + m_backgroundImage.x || m_mousePoint.y > m_backgroundImage.height + m_backgroundImage.y) 
            {
                m_pressedOutsideBackground = true;
            }
            else 
            {
                m_pressedOutsideBackground = false;
            }
        }
        else if (mouseState.leftMouseReleasedThisFrame && m_pressedOutsideBackground) 
        {
            if (m_mousePoint.x < m_backgroundImage.x || m_mousePoint.y < m_backgroundImage.y ||
                m_mousePoint.x > m_backgroundImage.width + m_backgroundImage.x || m_mousePoint.y > m_backgroundImage.height + m_backgroundImage.y) 
            {
                onCloseClicked({ });
            }
            m_pressedOutsideBackground = false;
        }
        
        return ScriptStatus.FAIL;
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        
        if (m_ready) 
        {
            m_gameEngine.removeEventListener(GameEvent.LINK_TO_TIP, onLinkToTip);
            if (value) 
            {
                m_gameEngine.addEventListener(GameEvent.LINK_TO_TIP, onLinkToTip);
            }
        }
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
		if (m_mainDisplayContainer.parent != null) m_mainDisplayContainer.parent.removeChild(m_mainDisplayContainer);
		m_mainDisplayContainer = null;
        m_closeButton.removeEventListener(MouseEvent.CLICK, onCloseClicked);
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        
        setIsActive(m_isActive);
    }
    
    private function onLinkToTip(event : Dynamic) : Void
    {
		if (Std.is(event, DataEvent)) {
			// The bounds to put the replay should be the same as the background
			var screenBounds : Rectangle = new Rectangle(0, 0, m_screenWidth - m_hintDisplayContainer.x * 2, m_screenHeight - m_hintDisplayContainer.y * 2);
			var tipName : String = (try cast(event, DataEvent) catch (e : Dynamic) null).getData().tipName;
			var tipScript : IShowableScript = TipsViewer.getTipScriptFromName(tipName, m_gameEngine.getExpressionSymbolResources(),
					m_hintDisplayContainer, m_simulatedMouseState, m_simulatedTimer, m_assetManager, screenBounds);
			tipScript.show();
			m_currentlyPlayingScript = try cast(tipScript, ScriptNode) catch(e:Dynamic) null;
			
			(try cast(m_gameEngine.getUiEntity("topLayer"), DisplayObjectContainer) catch(e:Dynamic) null).addChild(m_mainDisplayContainer);
		}
    }
    
    private function onCloseClicked(event : Dynamic) : Void
    {
        Audio.instance.playSfx("button_click");
        if (m_currentlyPlayingScript != null) 
        {
            m_currentlyPlayingScript.dispose();
            m_currentlyPlayingScript = null;
        }
        
        if (m_mainDisplayContainer.parent != null) m_mainDisplayContainer.parent.removeChild(m_mainDisplayContainer);
    }
}
