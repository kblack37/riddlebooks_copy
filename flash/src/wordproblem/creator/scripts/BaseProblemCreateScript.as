package wordproblem.creator.scripts
{
    import wordproblem.creator.ProblemCreateEvent;
    import wordproblem.creator.WordProblemCreateState;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.BaseBufferEventScript;
    
    public class BaseProblemCreateScript extends BaseBufferEventScript
    {
        protected var m_createState:WordProblemCreateState;
        protected var m_assetManager:AssetManager;
        protected var m_isReady:Boolean;
        
        public function BaseProblemCreateScript(createState:WordProblemCreateState,
                                                assetManager:AssetManager,
                                                id:String=null, 
                                                isActive:Boolean=true)
        {
            super(id, isActive);
            
            m_createState = createState;
            m_assetManager = assetManager;
            m_isReady = false;
            
            m_createState.addEventListener(ProblemCreateEvent.PROBLEM_CREATE_INIT, onLevelReady);
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_createState.removeEventListener(ProblemCreateEvent.PROBLEM_CREATE_INIT, onLevelReady);
        }
        
        protected function onLevelReady():void
        {
            m_isReady = true;
        }
    }
}