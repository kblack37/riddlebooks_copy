package wordproblem.scripts.barmodel;


import flash.geom.Point;
import flash.geom.Rectangle;

import dragonbox.common.dispose.IDisposable;
import dragonbox.common.ui.MouseState;

import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;
import starling.filters.ColorMatrixFilter;
import starling.textures.Texture;

import wordproblem.engine.IGameEngine;
import wordproblem.engine.animation.FollowPathAnimation;
import wordproblem.resource.AssetManager;

class ModalButtonControl implements IDisposable
{
    private var m_gameEngine : IGameEngine;
    
    /**
     * Get whether the bar model remove gestures should be allowed
     */
    private var m_modeIsActive : Bool;
    
    /**
     * Reference to the actual button that when clicked
     */
    private var m_modalButton : Sprite;
    
    /**
     * Buffer to store the bounds of the modal button
     */
    private var m_modalButtonBounds : Rectangle;
    
    /**
     * Buffer to store the global coordinates of the mouse on each frame
     */
    private var m_globalPointBuffer : Point;
    
    /**
     * For a click to register on the button, a press AND release must be detected
     * over the button.
     */
    private var m_pressStartedInButton : Bool;
    
    /**
     * Callback when the mode value has changed
     */
    private var m_onModeChangeCallback : Function;
    
    private var m_inactiveColor : Int = 0x6AA2C8;
    private var m_activeColor : Int = 0x6AB24B;
    
    private var m_particleEffect : FollowPathAnimation;
    
    public function new(gameEngine : IGameEngine,
            assetManager : AssetManager,
            iconTextureName : String,
            onModeChangeCallback : Function)
    {
        m_gameEngine = gameEngine;
        m_onModeChangeCallback = onModeChangeCallback;
        m_modeIsActive = false;
        m_globalPointBuffer = new Point();
        m_modalButtonBounds = new Rectangle();
        
        var maxButtonDimension : Float = 48;
        var mainButtonBgTexture : Texture = assetManager.getTexture("card_background_circle");
        var deleteIconTexture : Texture = assetManager.getTexture(iconTextureName);
        
        // Need to define the max bounds of the button
        var buttonImageContainer : Sprite = new Sprite();
        var upImage : Image = new Image(mainButtonBgTexture);
        upImage.scaleX = upImage.scaleY = maxButtonDimension / mainButtonBgTexture.width;
        upImage.color = m_inactiveColor;
        buttonImageContainer.addChild(upImage);
        
        var deleteIcon : Image = new Image(deleteIconTexture);
        deleteIcon.scaleX = deleteIcon.scaleY = maxButtonDimension * 0.6 / deleteIconTexture.width;
        deleteIcon.x = (upImage.width - deleteIcon.width) * 0.5;
        deleteIcon.y = (upImage.height - deleteIcon.height) * 0.5;
        buttonImageContainer.addChild(deleteIcon);
        
        // Move reference to center
        buttonImageContainer.pivotX = buttonImageContainer.width * 0.5;
        buttonImageContainer.pivotY = buttonImageContainer.height * 0.5;
        buttonImageContainer.x = buttonImageContainer.pivotX;
        buttonImageContainer.y = buttonImageContainer.pivotY;
        
        // Add custom created modal button to container
        m_modalButton = buttonImageContainer;
        
        var padding : Float = 3;
        m_particleEffect = new FollowPathAnimation(assetManager, buttonImageContainer, new Rectangle(
                padding, padding, buttonImageContainer.width - 2 * padding, buttonImageContainer.height - 2 * padding), 0);
    }
    
    public function onEnterFrame() : Void
    {
        // Check for mouse interaction with the modal button
        var mouseState : MouseState = m_gameEngine.getMouseState();
        m_globalPointBuffer.x = mouseState.mousePositionThisFrame.x;
        m_globalPointBuffer.y = mouseState.mousePositionThisFrame.y;
        m_modalButton.getBounds(m_modalButton.stage, m_modalButtonBounds);
        if (m_modalButtonBounds.containsPoint(m_globalPointBuffer)) 
        {
            if (mouseState.leftMousePressedThisFrame) 
            {
                m_pressStartedInButton = true;
            }
            // This is a button click
            else if (mouseState.leftMouseReleasedThisFrame && m_pressStartedInButton) 
            {
                m_pressStartedInButton = false;
                setActiveMode(!m_modeIsActive);
                
                if (m_onModeChangeCallback != null) 
                {
                    m_onModeChangeCallback();
                }
            }
            
            if (mouseState.leftMouseDown) 
            {
                // On down keep modal button in contracted state
                m_modalButton.scaleX = m_modalButton.scaleY = 0.95;
            }
            else 
            {
                // On hover keep button in an expanded state
                m_modalButton.scaleX = m_modalButton.scaleY = 1.05;
            }
        }
        else 
        {
            m_pressStartedInButton = false;
            
            // Set button to out state
            m_modalButton.scaleX = m_modalButton.scaleY = 1.0;
        }
    }
    
    /**
     * @return
     *      True if the button is in an active mode
     */
    public function getModeIsActive() : Bool
    {
        return m_modeIsActive;
    }
    
    /**
     * Get back the main button graphic
     */
    public function getButton() : DisplayObject
    {
        return m_modalButton;
    }
    
    /**
     * Expose this function publically if a script want to manually set whether the model button appears active
     * 
     * @param isActive
     *      true if the modal button should be in it's active mode
     */
    public function setActiveMode(isActive : Bool) : Void
    {
        var buttonColor : Int = m_inactiveColor;
        if (isActive) 
                {
                    buttonColor = m_activeColor;
                    
                    m_particleEffect.play();
                    Starling.juggler.add(m_particleEffect);
                }
                else 
                {
                    // Make sure particles are removed
                    m_particleEffect.pause();
                    Starling.juggler.remove(m_particleEffect);
                }(try cast(m_modalButton.getChildAt(0), Image) catch(e:Dynamic) null).color = buttonColor;
        m_modeIsActive = isActive;
    }
    
    /**
     * This toggles appearance of the button
     */
    public function setButtonEnabled(enabled : Bool) : Void
    {
        if (enabled) 
        {
            // If active have it appear with regular color
            m_modalButton.filter = null;
            m_modalButton.alpha = 1.0;
        }
        else 
        {
            // If inactive apply a greyscale filter
            var colorMatrixFilter : ColorMatrixFilter = new ColorMatrixFilter();
            colorMatrixFilter.adjustSaturation(-1);
            m_modalButton.filter = colorMatrixFilter;
            m_modalButton.alpha = 0.5;
            
            // If disabled the button should automatically go back to the not-active mode, since we
            // assume a disabled button also means the actions for that mode should also be disabled.
            // Not in the enabled part since an enabled button does not mean the mode should also
            // be active, it just means it should not be clickable
            setActiveMode(false);
        }
    }
    
    public function dispose() : Void
    {
        Starling.juggler.remove(m_particleEffect);
        m_particleEffect.dispose();
    }
}
