package wordproblem.account;


import flash.display.DisplayObject;
import flash.display.Sprite;

import cgs.logotos.TosUi;
import cgs.server.data.IUserTosStatus;
import cgs.user.ICgsUser;

import dragonbox.common.dispose.IDisposable;

import haxe.Constraints.Function;

import gameconfig.commonresource.EmbeddedBundle1X;

import starling.display.Image;

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
		// TODO: update this to work with the new AssetManager and without embedded resources
        //var background : DisplayObject = Type.createInstance(EmbeddedBundle1X.summary_background, [ ]);
        //background.width = width;
        //background.height = height;
        //addChild(background);
        
        // Paste tos on top
		// TODO: uncomment when cgs library is finished
        //var userTosStatus : IUserTosStatus = user.tosStatus;
        //var tosUi : TosUi = new TosUi(user, userTosStatus, tosComplete, "Riddle Books");
        //addChild(tosUi);
        //tosUi.load();
        //
        //function tosComplete() : Void
        //{
            //removeChild(tosUi);
            //if (m_acceptTosCallback != null) 
            //{
                //m_acceptTosCallback();
            //}
        //};
    }
    
    public function dispose() : Void
    {
    }
}
