package dragonbox.common.ui;

import dragonbox.common.ui.TextButton;

import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFormat;

import cgs.audio.Audio;
import cgs.user.ICgsUser;

import dragonbox.common.dispose.IDisposable;

import wordproblem.engine.text.GameFonts;

/**
 * A small ui component to allow the player to see their username and logout.
 * Also hacked this to include a create account button for situations where the user is a guest.
 */
class LogoutWidget extends Sprite implements IDisposable
{
    private var m_nameLabel : TextField;
    
    /**
     * If the user has member credentials then they can logout
     */
    private var m_logoutButton : TextButton;
    private var m_logoutCallback : Function;
    
    /**
     * If the user is detected as being a guest, then allow them to create an account.
     */
    private var m_createAccountButton : TextButton;
    private var m_createAccountCallback : Function;
    
    public function new(user : ICgsUser,
            showName : Bool,
            nameTextFormat : TextFormat,
            logoutTextFormat : TextFormat,
            logoutHoverTextFormat : TextFormat,
            logoutCallback : Function,
            createAccountCallback : Function)
    {
        super();
        
        var isGuest : Bool = (user == null || user.username == null);
        var name : String = ((isGuest)) ? "Guest" : user.username;
        
        m_nameLabel = new TextField();
        m_nameLabel.selectable = false;
        m_nameLabel.embedFonts = GameFonts.getFontIsEmbedded(nameTextFormat.font);
        m_nameLabel.defaultTextFormat = nameTextFormat;
        m_nameLabel.text = "Welcome " + name;
        m_nameLabel.width = m_nameLabel.textWidth * 1.1;
        m_nameLabel.height = m_nameLabel.textHeight;
        if (showName) 
        {
            addChild(m_nameLabel);
        }
        
        m_logoutButton = new TextButton();
        m_logoutButton.embedFonts = GameFonts.getFontIsEmbedded(logoutTextFormat.font);
        m_logoutButton.textFormat = logoutTextFormat;
        m_logoutButton.hoverTextFormat = logoutHoverTextFormat;
        m_logoutButton.text = "Sign Out";
        m_logoutButton.addEventListener(MouseEvent.CLICK, onLogoutClick);
        m_logoutButton.x = ((showName)) ? (m_nameLabel.width - m_logoutButton.width) * 0.5 : 0;
        m_logoutButton.y = ((showName)) ? (m_nameLabel.y + m_nameLabel.height) : 0;
        
        m_logoutCallback = logoutCallback;
        
        m_createAccountButton = new TextButton();
        m_createAccountButton.embedFonts = GameFonts.getFontIsEmbedded(logoutTextFormat.font);
        m_createAccountButton.textFormat = logoutTextFormat;
        m_createAccountButton.hoverTextFormat = logoutHoverTextFormat;
        m_createAccountButton.text = "Save Progress";
        m_createAccountButton.addEventListener(MouseEvent.CLICK, onCreateAccountClick);
        m_createAccountButton.x = ((showName)) ? (m_nameLabel.width - m_createAccountButton.width) * 0.5 : 0;
        m_createAccountButton.y = ((showName)) ? (m_nameLabel.y + m_nameLabel.height) : 0;
        
        m_createAccountCallback = createAccountCallback;
        
        if (isGuest) 
        {
            //addChild(m_createAccountButton);
            
        }
        else 
        {
            addChild(m_logoutButton);
        }
    }
    
    public function dispose() : Void
    {
        m_logoutButton.dispose();
        m_logoutButton.removeEventListener(MouseEvent.CLICK, onLogoutClick);
        
        m_createAccountButton.dispose();
        m_createAccountButton.removeEventListener(MouseEvent.CLICK, onCreateAccountClick);
    }
    
    private function onLogoutClick(event : MouseEvent) : Void
    {
        Audio.instance.playSfx("button_click");
        if (m_logoutCallback != null) 
        {
            m_logoutCallback();
        }
    }
    
    private function onCreateAccountClick(event : MouseEvent) : Void
    {
        Audio.instance.playSfx("button_click");
        if (m_createAccountCallback != null) 
        {
            m_createAccountCallback();
        }
    }
}
