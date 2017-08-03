package wordproblem.state;


import flash.geom.Rectangle;
import flash.net.SharedObject;
import flash.text.TextFormat;

import cgs.CgsApi;
import cgs.audio.Audio;
import cgs.internationalization.StringTable;
import cgs.server.responses.CgsResponseStatus;
import cgs.server.responses.CgsUserResponse;
import cgs.user.CgsUserProperties;
import cgs.user.ICgsUser;

import dragonbox.common.expressiontree.compile.LatexCompiler;
import dragonbox.common.math.vectorspace.RealsVectorSpace;
import dragonbox.common.state.BaseState;
import dragonbox.common.state.IStateMachine;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;
import dragonbox.common.util.XColor;

import haxe.Constraints.Function;

import starling.animation.Juggler;
import starling.display.Button;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.events.Event;
import starling.text.TextField;
import starling.textures.Texture;
import starling.utils.HAlign;

import wordproblem.credits.CreditsWidget;
import wordproblem.engine.component.ComponentFactory;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.systems.HelperCharacterRenderSystem;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.widget.ConfirmationWidget;
import wordproblem.engine.widget.WidgetUtil;
import wordproblem.event.CommandEvent;
import wordproblem.log.AlgebraAdventureLogger;
import wordproblem.resource.AssetManager;
import wordproblem.settings.OptionsWidget;

/**
 * This is the title screen that is used for versions that do not allow the player
 * to manually create their own usernames but may optionally have an external login that
 * we can use to remember user across several different sessions.
 * 
 * We really just need to provide a button to continue progress or start a new game.
 * Note that any players that do not login externally to link their play data will be lost
 * on any reset (i.e. player starts a new game, later on another player comes in and starts
 * another new game, the player from before is lost for good)
 */
class ExternalLoginTitleScreenState extends BaseState
{
    private var m_assetManager : AssetManager;
    
    private var m_logger : AlgebraAdventureLogger;
    
    private var m_continueGameButton : Button;
    private var m_newGameButton : Button;
    
    /**
     * Have a custom juggler that animates all spritesheets in this screen
     * (Right now just the hamster characters)
     */
    private var m_spritesheetJuggler : Juggler;
    
    /**
     * Components on the characters
     */
    private var m_componentManager : ComponentManager;
    
    /**
     * Drawing system for the characters
     */
    private var m_helpRenderSystem : HelperCharacterRenderSystem;
    
    private var m_options : OptionsWidget;
    
    /**
     * Screen to show credits
     */
    private var m_credits : CreditsWidget;
    
    /**
     * Since we want every player to be assigned as a student, we need some dummy teacher
     * that will link to them.
     */
    private var m_teacherCode : String;
    private var m_saveCacheKey : String;
    private var m_saveDataToServer : Bool;
    
    /**
     * Prompt user if they are ok with losing previous save data by starting a new game
     */
    private var m_newGameConfirmationWidget : ConfirmationWidget;
    
    /**
     * We keep a reference to the local storage.
     * 
     * "userData"->
     * uid
     */
    private var m_localSharedObject : SharedObject;
    
    /**
     * Used to override behavior when the user clicks continue.
     */
    private var m_continueGameCallback : Function;
    
    /**
     * Used to override behavior when the user clicks to start a new game.
     */
    private var m_newGameCallback : Function;
    
    /**
     * This screen can be used for some external portals like Brainpop, where we can show something
     * like a message telling them to log into that portal first.
     */
    private var m_loginMessage : String;
    
    public function new(stateMachine : IStateMachine,
            assetManager : AssetManager,
            teacherCode : String,
            saveCacheKey : String,
            saveDataToServer : Bool,
            logger : AlgebraAdventureLogger,
            customOnContinueCallback : Function = null,
            customOnNewGameCallback : Function = null,
            customMessage : String = null)
    {
        super(stateMachine);
        
        m_assetManager = assetManager;
        m_teacherCode = teacherCode;
        m_saveCacheKey = saveCacheKey;
        m_saveDataToServer = saveDataToServer;
        m_logger = logger;
        
        m_continueGameCallback = ((customOnContinueCallback != null)) ? customOnContinueCallback : continueGuestUser;
        m_newGameCallback = ((customOnNewGameCallback != null)) ? customOnNewGameCallback : startNewGuestUser;
        m_loginMessage = customMessage;
        
        m_localSharedObject = SharedObject.getLocal("wordproblem_user");
        
        m_componentManager = new ComponentManager();
        
        var componentFactory : ComponentFactory = new ComponentFactory(new LatexCompiler(new RealsVectorSpace()));
        var characterData : Dynamic = assetManager.getObject("characters");
        componentFactory.createAndAddComponentsForItemList(m_componentManager, characterData.charactersTitle);
        
        m_spritesheetJuggler = new Juggler();
        m_helpRenderSystem = new HelperCharacterRenderSystem(assetManager, m_spritesheetJuggler, this.getSprite());
        
        var screenWidth : Float = 800;
        var screenHeight : Float = 600;
        
        // Screen to show credits
        var creditsWidget : CreditsWidget = new CreditsWidget(
			screenWidth, 
			screenHeight, 
			m_assetManager, 
			null, 
			XColor.ROYAL_BLUE
        );
        m_credits = creditsWidget;
        
        // Screen to confirm whether starting a new game is okay
        var confirmationWidget : ConfirmationWidget = new ConfirmationWidget(
			screenWidth, 
			screenHeight, 
			function() : DisplayObject
			{
				var contentTextField : TextField = new TextField(
					400, 
					200, 
					// TODO: uncomment once cgs library is finished
					"",//StringTable.lookup("start_new_warning"), 
					GameFonts.DEFAULT_FONT_NAME, 
					30, 
					0xFFFFFF 
				);
				return contentTextField;
			}, 
			function() : Void
			{
				// Continue with starting new game
				removeChild(m_newGameConfirmationWidget);
				m_newGameCallback();
			}, 
			function() : Void
			{
				// Decline
				removeChild(m_newGameConfirmationWidget);
			}, 
			// TODO: uncomment once cgs library is finished
			m_assetManager, XColor.ROYAL_BLUE, "", ""//StringTable.lookup("yes"), StringTable.lookup("no")
        );
        m_newGameConfirmationWidget = confirmationWidget;
    }
    
    override public function enter(fromState : Dynamic, params : Array<Dynamic> = null) : Void
    {
        // Play background music
        Audio.instance.playMusic("bg_home_music");
        
        var maxWidth : Float = 800;
        var maxHeight : Float = 600;
        
        // Create the options on top
        var optionsWidget : OptionsWidget = new OptionsWidget(
			m_assetManager, 
			[OptionsWidget.OPTION_MUSIC, OptionsWidget.OPTION_SFX, OptionsWidget.OPTION_CREDITS], 
			onCreditsClicked, 
			null, 
			XColor.ROYAL_BLUE
        );
        optionsWidget.x = 0;
        optionsWidget.y = maxHeight - optionsWidget.height;
        addChild(optionsWidget);
        m_options = optionsWidget;
        
        var bgTexture : Texture = m_assetManager.getTexture("login_background_with_ui.png");
        addChildAt(new Image(bgTexture), 0);
        
        // Without any external login info, a continue assumes that the returning player is the
        // same one who played the last session
        var allowContinue : Bool = m_localSharedObject.data.exists("uid");
        
        // Create a button to continue IF a user id was saved in the cache
        var baseContinueGameButtonTexture : Texture = m_assetManager.getTexture("button_green_up.png");
        var buttonTexturePadding : Float = 16;
        var nineSliceGrid : Rectangle = new Rectangle(
			buttonTexturePadding, 
			buttonTexturePadding, 
			baseContinueGameButtonTexture.width - 2 * buttonTexturePadding, 
			baseContinueGameButtonTexture.height - 2 * buttonTexturePadding
        );
        m_continueGameButton = WidgetUtil.createButton(
                        m_assetManager,
                        "button_green_up",
                        "button_green_over",
                        null,
                        "button_green_over",
                        "Guest Continue",
                        new TextFormat(GameFonts.DEFAULT_FONT_NAME, 24, 0x000000),
                        null,
                        nineSliceGrid
                        );
        m_continueGameButton.width = 250;
        m_continueGameButton.height = baseContinueGameButtonTexture.height;
        m_continueGameButton.addEventListener(Event.TRIGGERED, onContinueGameClick);
        
        if (allowContinue) 
        {
            m_continueGameButton.x = (maxWidth - m_continueGameButton.width) * 0.5;
            m_continueGameButton.y = maxHeight * 0.5 - m_continueGameButton.height;
            addChild(m_continueGameButton);
        }  // Create a button to register as a new student that auto-assigns a username  
        
        
        
        var baseNewGameButtonTexture : Texture = m_assetManager.getTexture("button_green_up.png");
        buttonTexturePadding = 16;
        nineSliceGrid = new Rectangle(
            buttonTexturePadding, 
            buttonTexturePadding, 
            baseNewGameButtonTexture.width - 2 * buttonTexturePadding, 
            baseNewGameButtonTexture.height - 2 * buttonTexturePadding
        );
        m_newGameButton = WidgetUtil.createButton(
            m_assetManager,
            "button_green_up",
            "button_green_over",
            null,
            "button_green_over",
            "New Guest",
            new TextFormat(GameFonts.DEFAULT_FONT_NAME, 36, 0x000000),
            null,
            nineSliceGrid
        );
        m_newGameButton.width = 330;
        m_newGameButton.addEventListener(Event.TRIGGERED, onNewGameClick);
        
        if (allowContinue) 
        {
            m_newGameButton.y = m_continueGameButton.y + baseContinueGameButtonTexture.height + 20;
        }
        else 
        {
            m_newGameButton.y = (maxHeight - baseContinueGameButtonTexture.height) * 0.5;
        }
        m_newGameButton.x = (maxWidth - m_newGameButton.width) * 0.5;
        addChild(m_newGameButton);
        
        // Add ui telling user to log into an external page to make sure their progress is bound
        // to an account they can use on several machines
        if (m_loginMessage != null) 
        {
            var messageTextfield : TextField = new TextField(Std.int(m_newGameButton.width), 80, m_loginMessage, GameFonts.DEFAULT_FONT_NAME, 24, 0xFFFFFF);
            messageTextfield.hAlign = HAlign.CENTER;
            messageTextfield.x = (maxWidth - messageTextfield.width) * 0.5;
            messageTextfield.y = ((allowContinue)) ? m_newGameButton.y + 80 : m_newGameButton.y + 100;
            addChild(messageTextfield);
        }
    }
    
    override public function exit(toState : Dynamic) : Void
    {
        m_continueGameButton.removeEventListener(Event.TRIGGERED, onContinueGameClick);
        m_newGameButton.removeEventListener(Event.TRIGGERED, onNewGameClick);
        
        while (numChildren > 0)
        {
            removeChildAt(0);
        }
    }
    
    override public function update(time : Time,
            mouseState : MouseState) : Void
    {
        m_spritesheetJuggler.advanceTime(time.currentDeltaSeconds);
        m_helpRenderSystem.update(m_componentManager);
        
        // If click outside the bounds of the options, the options menu should close
        if (mouseState.leftMousePressedThisFrame && m_options.isOpen()) 
        {
            var optionBounds : Rectangle = m_options.getBounds(m_options.stage);
            if (!optionBounds.contains(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y)) 
            {
                m_options.toggleOptionsOpen(false);
            }
        }
    }
    
    public function continueGuestUser() : Void
    {
        // Use the user id saved in the local cache
        if (m_localSharedObject.data.exists("uid")) 
        {
            var username : String = Reflect.field(m_localSharedObject.data, "uid");
            var password : String = null;
            
            var cgsApi : CgsApi = m_logger.getCgsApi();
            cgsApi.authenticateStudent(m_logger.getCgsUserProperties(m_saveDataToServer, m_saveCacheKey), username, m_teacherCode, password, 0, onAuthenticateStudent);
            dispatchEventWith(CommandEvent.WAIT_SHOW);
        }
    }
    
    public function startNewGuestUser() : Void
    {
        // WARNING: Anonymous accounts create entries in the ab table so they are no good
        // Create our own guids and hope there is no collision
        /*
        // Create a new student user (need to fetch an available user id from the server and use that
        // to help create the dummy account)
        var cgsUserProperties:CgsUserProperties = m_logger.getCgsUserProperties(m_saveDataToServer, m_saveCacheKey);
        cgsUserProperties.completeCallback = onAnonymousUserInitialized;
        
        m_logger.getCgsApi().initializeUser(cgsUserProperties);
        dispatchEventWith(CommandEvent.WAIT_SHOW);
        */
        
        dispatchEventWith(CommandEvent.WAIT_SHOW);
        
        // Save user id to the local cache
        var userId : String = createGuid("");
		Reflect.setField(m_localSharedObject.data, "uid", userId);
        m_localSharedObject.flush();
        
        // Use that user id to register a new student
        var cgsApi : CgsApi = m_logger.getCgsApi();
        var cgsUserProperties : CgsUserProperties = m_logger.getCgsUserProperties(m_saveDataToServer, m_saveCacheKey);
        
        // HACK: The fake grade must be greater than 2 to force the TOS to show up if such a document is required
        m_logger.getCgsApi().registerStudent(cgsUserProperties, userId, m_teacherCode, 4, onCreateAnonymousUserAccount, 0);
    }
    
    private function onContinueGameClick() : Void
    {
        Audio.instance.playSfx("button_click");
        m_continueGameCallback();
    }
    
    private function onNewGameClick() : Void
    {
        Audio.instance.playSfx("button_click");
        
        // Need to first clear out any local data (most important is the whatever user id was saved in the cache)
        // Local storage gets overwritten anyways so may not be necessary
        if (m_localSharedObject.data.exists("uid")) 
        {
            // Ask the player if they are okay with previous save data being lost
            addChild(m_newGameConfirmationWidget);
        }
        else 
        {
            m_newGameCallback();
        }
    }
    
    private function onCreditsClicked() : Void
    {
        addChild(m_credits);
    }
    
    private function onAuthenticateStudent(userResponse : CgsUserResponse) : Void
    {
        if (userResponse.success) 
        {
            dispatchEventWith(CommandEvent.USER_AUTHENTICATED);
        }
        else 
        {
            // Login failed
            
        }
        
        dispatchEventWith(CommandEvent.WAIT_HIDE);
    }
    
    private function onAnonymousUserInitialized(userResponse : CgsUserResponse) : Void
    {
        var anonymousUser : ICgsUser = userResponse.cgsUser;
        var userId : String = anonymousUser.userId;
        
        // Save user id to the local cache
		Reflect.setField(m_localSharedObject, "uid", userId);
        m_localSharedObject.flush();
        
        // Use that user id to register a new student
        var cgsApi : CgsApi = m_logger.getCgsApi();
        var cgsUserProperties : CgsUserProperties = m_logger.getCgsUserProperties(m_saveDataToServer, m_saveCacheKey);
        
        // Delete the anonymous user
        m_logger.getCgsApi().removeUser(anonymousUser);
        
        // HACK: The fake grade must be greater than 2 to force the TOS to show up if such a document is required
        m_logger.getCgsApi().registerStudent(cgsUserProperties, userId, m_teacherCode, 4, onCreateAnonymousUserAccount, 0);
    }
    
    private function onCreateAnonymousUserAccount(response : CgsResponseStatus) : Void
    {
        dispatchEventWith(CommandEvent.USER_AUTHENTICATED);
        dispatchEventWith(CommandEvent.WAIT_HIDE);
    }
    
    private function createGuid(prefix : String, value : Array<Dynamic> = null) : String
    {
        var uid : Array<Dynamic> = new Array<Dynamic>();
        var chars : Array<Dynamic> = [48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 65, 66, 67, 68, 69, 
        70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90];
        var separator : Int = 45;
        var template : Array<Dynamic> = value != null ? value : [8, 4, 4, 4, 12];
        
        for (a in 0...template.length){
            for (b in 0...template[a]){
                uid.push(chars[Math.floor(Math.random() * chars.length)]);
            }
            
            if (a < template.length - 1) 
            {
                uid.push(separator);
            }
        }
        
		var str = "";
		for (id in uid) str += String.fromCharCode(id);
		
        return prefix + str;
    }
}
