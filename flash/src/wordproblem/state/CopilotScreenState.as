package wordproblem.state
{
	import cgs.Audio.Audio;
	
	import dragonbox.common.state.BaseState;
	import dragonbox.common.state.IStateMachine;
	import dragonbox.common.time.Time;
	import dragonbox.common.ui.MouseState;
	import dragonbox.common.util.XColor;
	
	import starling.display.Image;
	import starling.textures.Texture;
	
	import wordproblem.resource.AssetManager;
	import wordproblem.settings.OptionsWidget;
	
    /**
     * This is the first page that the player sees when they first load up the application.
     * 
     * This screen contains the login prompt and will force the user to go through the
     * authentication process before they are allowed to continue.
     * 
     * THIS IS IMPORTANT:
     * Player specific information may be important for other parts of the game to set up properly
     * 
     * A piece of this that is tricky is that the login popup relies on flash display objects, meaning that they can only be
     * added onto the flash stage. This means that the login popup will always appear on top of all the Stage3D content.
     */
	public class CopilotScreenState extends BaseState
	{
        /**
         * Fetch image texture to be placed on the Stage3D layer.
         */
        private var m_assetManager:AssetManager;
        
        /**
         * Constructor for the Copilot Screen State. The Copilot wants a blank top-level screen to display, but it does
		 * not need anything fancy. This is a stripped down clone of TitleScreenState.
		 * @param	stateMachine
		 * @param	assetManager
		 */
		public function CopilotScreenState(stateMachine:IStateMachine,
                                           assetManager:AssetManager)
		{
			super(stateMachine);
            
            m_assetManager = assetManager;
		}
		
		override public function enter(fromState:Object, params:Vector.<Object>=null):void
		{
            // Play background music
            Audio.instance.playMusic("bg_home_music");
            
            // Create the options on top
            var optionsWidget:OptionsWidget = new OptionsWidget(
                m_assetManager, 
                Vector.<String>([OptionsWidget.OPTION_MUSIC, OptionsWidget.OPTION_SFX]),
				null,
                null, XColor.ROYAL_BLUE
            );
            optionsWidget.x = 0;
            optionsWidget.y = 600 - 40;
            addChild(optionsWidget);
            
            var bgTexture:Texture = m_assetManager.getTexture("login_background");
            addChildAt(new Image(bgTexture), 0);
		}
		
		override public function exit(toState:Object):void
		{
			while (numChildren > 0)
			{
				removeChildAt(0);
			}
		}
		
		override public function update(time:Time, 
										mouseState:MouseState):void
		{
		}
	}
}