package wordproblem.state
{
    import flash.display.Stage;
    
    import cgs.logotos.TosUi;
    import cgs.server.data.UserTosStatus;
    import cgs.user.ICgsUser;
    
    import dragonbox.common.state.BaseState;
    import dragonbox.common.state.IStateMachine;
    
    import starling.display.Image;
    import starling.textures.Texture;
    
    import wordproblem.resource.AssetManager;
    
    /**
     * When releasing to third party sites, it may be necessary to show a terms of service
     */
    public class TOSState extends BaseState
    {
        private var m_assetManager:AssetManager;
        
        /**
         * The TOS is a normal flash component, so it can only be added
         */
        private var m_nativeFlashStage:Stage;
        
        /**
         * This has the actual widget to pick
         */
        private var m_tosUi:TosUi;
        private var m_tosUiActive:Boolean;
        
        /**
         * Callback when the user accepts the tos, accepts no parameters
         */
        private var m_onTosAccepted:Function;
        
        public function TOSState(stateMachine:IStateMachine,
                                 assetManager:AssetManager,
                                 nativeStage:Stage, 
                                 onTosAccepted:Function)
        {
            super(stateMachine);
            
            m_assetManager = assetManager;
            m_nativeFlashStage = nativeStage;
            m_onTosAccepted = onTosAccepted;
            m_tosUiActive = true;
        }
        
        override public function enter(fromState:Object, 
                                       params:Vector.<Object>=null):void
        {
            var cgsUser:ICgsUser = null;
            if (params.length > 0)
            {
                cgsUser = params[0] as ICgsUser;
            }
            
            // Add background
            var width:Number = 800;
            var height:Number = 600;
            var backgroundTexture:Texture = m_assetManager.getTexture("login_background");
            var backgroundImage:Image = new Image(backgroundTexture);
            backgroundImage.width = width;
            backgroundImage.height = height;
            addChild(backgroundImage);
            
            if (cgsUser != null)
            {
                var tosStatus:UserTosStatus = cgsUser.tosStatus;
                m_tosUi = new TosUi(cgsUser, tosStatus, onTosComplete, "Riddle Books");
                
                // We have a problem if there is no TOS to show, the complete callback is 
                // called immediately and the tos ui pieces are disposed of (i.e. the ui is no
                // longer usable after this happens)
                if (m_tosUiActive)
                {
                    m_nativeFlashStage.addChild(m_tosUi);
                    m_tosUi.load();
                }
                
                // If tos already finished or is not needed at all, then just return as complete
                if (tosStatus.accepted || !tosStatus.acceptanceRequired)
                {
                    onTosComplete();   
                }
                
            }
        }
        
        override public function exit(toState:Object):void
        {
            if (m_tosUi != null && m_tosUi.parent)
            {
                m_tosUi.parent.removeChild(m_tosUi);
                m_tosUi = null;
            }
            
            this.removeChildren(0, -1, true);
        }
        
        private function onTosComplete():void
        {
            if (m_onTosAccepted)
            {
                m_onTosAccepted();
            }
            m_tosUiActive = false;
        }
    }
}