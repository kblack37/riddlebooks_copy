package wordproblem.account;


import flash.display.DisplayObject;
import flash.display.Sprite;

import cgs.logotos.TosUi;
import cgs.server.data.UserTosStatus;
import cgs.user.ICgsUser;

import dragonbox.common.dispose.IDisposable;

import gameconfig.commonresource.EmbeddedBundle1X;

class RegisterTosScreen extends Sprite implements IDisposable
{
    /**
     * Callback when the tos is accepted, do not allow them to continue if they decline
     */
    private var m_acceptTosCallback : Function;
    
    public function new(user : ICgsUser,
            acceptTosCallback : Function,
            width : Float,
            height : Float)
    {
        super();
        
        m_acceptTosCallback = acceptTosCallback;
        
        // Place the background
        var background : DisplayObject = new embeddedbundle1x.SummaryBackground();
        background.width = width;
        background.height = height;
        addChild(background);
        
        // Paste tos on top
        var userTosStatus : UserTosStatus = user.tosStatus;
        var tosUi : TosUi = new TosUi(user, userTosStatus, tosComplete, "Riddle Books");
        addChild(tosUi);
        tosUi.load();
        
        function tosComplete() : Void
        {
            removeChild(tosUi);
            if (m_acceptTosCallback != null) 
            {
                m_acceptTosCallback();
            }
        };
    }
    
    public function dispose() : Void
    {
    }
}
