package wordproblem.brainpop;


import com.brainpop.ScreenSender;

import flash.display.BitmapData;
import flash.display.Stage;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.events.TimerEvent;
import flash.geom.Matrix;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.utils.Timer;

import starling.core.Starling;
import starling.display.Stage;

import wordproblem.account.ExternalIdAuthenticator;
import wordproblem.log.AlgebraAdventureLogger;

/**
 * This class handles communicating with the simple brain pop api
 */
class BrainpopApi
{
    /**
     * This id is needed so we know a particular user account is coming from brainpop
     */
    public static inline var BRAINPOP_EXTERNAL_SOURCE_ID : Int = 8;
    
    private static inline var DOMAIN_SANDBOX : String = "qa.brainpop.com";  // change this is qa.brainpop from s4  
    private static inline var DOMAIN_PRODUCTION : String = "www.brainpop.com";
    private static inline var DOMAIN_LOCAL : String = "localhost/brainpop/dummy.php?command=checklogin";
    
    private static inline var REQUEST_CHECK_LOGIN : String = "/api/players/logged-in";
    
    /**
     * The domain to send requests to, there is only the brainpop sandbox and the production site
     */
    private var m_urlDomain : String;
    
    /**
     * The loader responsible for sending all login check requests
     */
    private var m_checkLoginUrlLoader : URLLoader;
    
    private var m_checkLoginCallback : Function;
    
    private var m_checkLoginPollTimer : Timer;
    private var m_loginPollSuccessCallback : Function;
    
    private var m_brainpopScreenSender : ScreenSender;
    private var m_starlingStage : starling.display.Stage;
    
    /**
     * Reference to the logger is needed to handle logic related to creating cgs account
     * based on
     */
    private var m_logger : AlgebraAdventureLogger;
    
    private var m_savedBrainpopId : String;
    
    private var m_loadedFromBrainpopDomain : Bool;
    
    private var m_overrideDomainCheck : Bool = false;
    
    private var m_externalIdAuthenticator : ExternalIdAuthenticator;
    
    public function new(logger : AlgebraAdventureLogger,
            dummyTeacherCode : String,
            serverDeployment : String,
            saveToServer : Bool,
            noSqlSaveKey : String,
            useHttps : Bool,
            flashStage : flash.display.Stage,
            starlingStage : starling.display.Stage)
    {
        // If brainpop is loading the entire html, then ignore the restriction
        var loadedDomainName : String = "";
        if (flashStage.loaderInfo.parameters.exists("parentDomain")) 
        {
            loadedDomainName = flashStage.loaderInfo.parameters.parentDomain;
        }
        
        if (loadedDomainName.search("qa.brainpop") >= 0) 
        {
            m_loadedFromBrainpopDomain = true;
            serverDeployment = "dev";
        }
        // Note that the sandbox brainpop api does not accept https, only use https if
        // both enabled in the config AND it is contacting the production server
        else if (loadedDomainName.search("brainpop.com") >= 0) 
        {
            m_loadedFromBrainpopDomain = true;
            serverDeployment = "prd";
        }
        else 
        {
            m_loadedFromBrainpopDomain = false;
            serverDeployment = "dev";
        }
        
        
        
        
        
        var prefix : String = "http";
        if (serverDeployment == "prd") 
        {
            prefix += "s";
        }
        m_urlDomain = prefix + "://";
        
        if (serverDeployment == "prd") 
        {
            m_urlDomain += DOMAIN_PRODUCTION;
        }
        else if (serverDeployment == "local") 
        {
            m_urlDomain += DOMAIN_LOCAL;
        }
        else 
        {
            m_urlDomain += DOMAIN_SANDBOX;
        }
        
        m_starlingStage = starlingStage;
        m_loginPollSuccessCallback = null;
        m_logger = logger;
        m_externalIdAuthenticator = new ExternalIdAuthenticator(m_logger, dummyTeacherCode, saveToServer, noSqlSaveKey, useHttps);
        
        // Initialize screen sender api for brainpop (this takes image captures)
        m_brainpopScreenSender = new ScreenSender(flashStage, takeSnapshot);
    }
    
    public function dispose() : Void
    {
        if (m_checkLoginUrlLoader != null) 
        {
            m_checkLoginUrlLoader.removeEventListener(Event.COMPLETE, onCheckLoginComplete);
            m_checkLoginUrlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
            m_checkLoginUrlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
        }
    }
    
    /**
     * Start polling the brainpop api service to see if a player is logged into brainpop.
     * Need to do a poll because there doesn't seem to be a way for this flash app to know
     * when the log into brainpop occurred.
     * 
     * @param secondsInterval
     *      The seconds in between each poll of the server
     * @param successCallback
     *      Callback triggered if a successful brainpop login has occurred
     *      Signature callback(brainpopId:String):void
     */
    public function startCheckLoginPoll(secondsInterval : Float, successCallback : Function) : Void
    {
        // Have timer that should continuously send updates until it detects that
        // the player has actually logged in
        m_checkLoginPollTimer = new Timer(secondsInterval * 1000, 0);
        m_checkLoginPollTimer.addEventListener(TimerEvent.TIMER, onTimerTick);
        m_loginPollSuccessCallback = successCallback;
        
        m_checkLoginPollTimer.start();
    }
    
    /**
     * Stop polling brainpop to check if player logged in. One usage may be to stop checking
     * once the user has started playing as a guest already.
     */
    public function stopCheckLoginPoll() : Void
    {
        if (m_checkLoginPollTimer != null) 
        {
            m_checkLoginPollTimer.stop();
            m_checkLoginPollTimer.removeEventListener(TimerEvent.TIMER, onTimerTick);
        }
    }
    
    /**
     * Brainpop will provide us just with a single string representing their external id.
     * We need to use this to bind it to cgs credentials, which will help us keep track
     * of logging data and save data on our side.
     * 
     * @param brainpopId
     *      Id provided from the brain pop login
     * @param successCallback
     *      Triggered if we could successfully link the given brainpopId to a cgs account
     * @param failCallback
     *      Triggered if we could not link the brainpopId to a cgs account
     */
    public function authenticateWithBrainpopId(brainpopId : String, successCallback : Function, failCallback : Function) : Void
    {
        m_savedBrainpopId = brainpopId;
        m_externalIdAuthenticator.authenticateWithExternalId(brainpopId, BrainpopApi.BRAINPOP_EXTERNAL_SOURCE_ID, successCallback, failCallback);
    }
    
    /**
     * Do a single poll of the brainpop api service to check if the player has logged in at
     * a given instant in time.
     * 
     * @param callback
     *      Signature callback(isLoggedIn:Boolean, brainpopId:String):void
     */
    public function checkLoginStatus(callback : Function) : Void
    {
        if (m_checkLoginUrlLoader == null) 
        {
            m_checkLoginUrlLoader = new URLLoader(null);
            m_checkLoginUrlLoader.addEventListener(Event.COMPLETE, onCheckLoginComplete);
            m_checkLoginUrlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
            m_checkLoginUrlLoader.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
        }
        
        m_checkLoginCallback = callback;
        
        if (m_loadedFromBrainpopDomain) 
        {
            var urlRequest : URLRequest = new URLRequest(getRequestCheckLoginUrl());
            m_checkLoginUrlLoader.load(urlRequest);
        }
        else 
        {
            if (m_checkLoginCallback != null) 
            {
                m_checkLoginCallback(false, null);
            }
        }
    }
    
    /**
     * This callback should be bound to a trigger that
     * automatically records the new snapshot.
     * 
     * The max dimensions for brainpop screen shot is 800 pixels in either direction.
     * Since the game is fixed at 800 x 600 this isn't to big an issue
     */
    public function takeSnapshot() : BitmapData
    {
        var totalWidth : Float = m_starlingStage.stageWidth;
        var totalHeight : Float = m_starlingStage.stageHeight;
        
        var scaleFactor : Float = 1.0;
        var maxDimension : Float = 800;
        if (totalWidth > maxDimension) 
        {
            scaleFactor = maxDimension / totalWidth;
        }
        // Force new rendering
        else if (totalHeight > maxDimension) 
        {
            scaleFactor = maxDimension / totalHeight;
        }
        
        
        
        var snapshotBitmapData : BitmapData = new BitmapData(totalWidth, totalHeight);
        Starling.current.stage.drawToBitmapData(snapshotBitmapData);
        
        // If the bitmap needs to be scaled down then we to draw a new one with the smaller dimensions
        if (scaleFactor < 1.0) 
        {
            var scaledBitmapData : BitmapData = new BitmapData(scaleFactor * totalWidth, scaleFactor * totalHeight);
            scaledBitmapData.draw(snapshotBitmapData, new Matrix(scaleFactor, 0, 0, scaleFactor));
            
            // Delete the unscaled verison
            snapshotBitmapData.dispose();
            snapshotBitmapData = scaledBitmapData;
        }
        
        return snapshotBitmapData;
    }
    
    private function getRequestCheckLoginUrl() : String
    {
        if (m_urlDomain.indexOf(DOMAIN_LOCAL) >= 0) 
        {
            return m_urlDomain;
        }
        else 
        {
            return m_urlDomain + BrainpopApi.REQUEST_CHECK_LOGIN;
        }
    }
    
    private function onTimerTick(event : TimerEvent) : Void
    {
        checkLoginStatus(function(isLoggedIn : Bool, brainpopId : String) : Void
                {
                    // Check if log in was detected since when the login polling was started
                    if (isLoggedIn) 
                    {
                        stopCheckLoginPoll();
                        if (m_loginPollSuccessCallback != null) 
                        {
                            m_loginPollSuccessCallback(brainpopId);
                        }
                    }
                });
    }
    
    private function onCheckLoginComplete(event : Event) : Void
    {
        // If student not logged in, the EntryID is an empty string and the
        // player_type property is also empty
        var returnedData : Dynamic = haxe.Json.parse(m_checkLoginUrlLoader.data);
        var isLoggedIn : Bool = false;
        var playerType : String = "";
        var brainpopId : String = "";
        if (returnedData.exists("EntryID") && returnedData.exists("player_type")) 
        {
            playerType = Reflect.field(returnedData, "player_type");
            brainpopId = Reflect.field(returnedData, "EntryID");
            isLoggedIn = brainpopId.length > 0;
        }
        
        if (m_checkLoginCallback != null) 
        {
            m_checkLoginCallback(isLoggedIn, brainpopId);
        }
    }
    
    private function onSecurityError(event : SecurityErrorEvent) : Void
    {
        if (m_checkLoginCallback != null) 
        {
            m_checkLoginCallback(false, null);
        }
    }
    
    private function onIoError(event : IOErrorEvent) : Void
    {
        if (m_checkLoginCallback != null) 
        {
            m_checkLoginCallback(false, null);
        }
    }
}
