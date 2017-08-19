package wordproblem.account;


import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.TextField;

import cgs.user.ICgsUser;

import dragonbox.common.dispose.IDisposable;

import haxe.Constraints.Function;

import wordproblem.display.LabelButton;

/**
 * This is the screen to display the reward that gets earned after registering a new account
 */
class RegisterRewardScreen extends Sprite implements IDisposable
{
    public var backgroundFactory : Function;
    public var animationFactory : Function;
    public var descriptionTextFactory : Function;
    public var okButtonFactory : Function;
    
    /**
     * Override this function to manually layout all the different components
     */
    public var layoutFunction : Function;
    
    /** The background image */
    private var m_background : DisplayObject;
    
    /** The animation showing the reward being given to the player */
    private var m_animation : MovieClip;
    
    /** Text about the reward */
    private var m_descriptionText : TextField;
    
    /** Button to continue with the game */
    private var m_okButton : LabelButton;
    
    /** Callback when the player want to close this screen */
    private var m_closeCallback : Function;
    
    /** In a somewhat roundabout fashion we need to forward the user back into the confirm callback */
    private var m_user : ICgsUser;
    
    public function new(closeCallback : Function, user : ICgsUser)
    {
        super();
        
        m_closeCallback = closeCallback;
        m_user = user;
    }
    
    public function dispose() : Void
    {
        m_okButton.removeEventListener(MouseEvent.CLICK, onOkButtonClick);
        
        while (this.numChildren > 0)
        {
            removeChildAt(0);
        }
    }
    
    public function drawAndLayout() : Void
    {
        m_background = backgroundFactory();
        
        m_animation = animationFactory();
        
        m_descriptionText = descriptionTextFactory();
        
        m_okButton = okButtonFactory();
        m_okButton.addEventListener(MouseEvent.CLICK, onOkButtonClick);
        
        layoutFunction(m_background, m_animation, m_descriptionText, m_okButton);
    }
    
    private function onOkButtonClick(event : Event) : Void
    {
        if (m_closeCallback != null) 
        {
            m_closeCallback(m_user);
        }
    }
}
