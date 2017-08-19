package wordproblem.creator.scripts;


import wordproblem.creator.ProblemCreateEvent;
import wordproblem.creator.WordProblemCreateState;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.BaseBufferEventScript;

class BaseProblemCreateScript extends BaseBufferEventScript
{
    private var m_createState : WordProblemCreateState;
    private var m_assetManager : AssetManager;
    private var m_isReady : Bool;
    
    public function new(createState : WordProblemCreateState,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_createState = createState;
        m_assetManager = assetManager;
        m_isReady = false;
        
        m_createState.addEventListener(ProblemCreateEvent.PROBLEM_CREATE_INIT, onLevelReady);
    }
    
    override public function dispose() : Void
    {
        super.dispose();
        
        m_createState.removeEventListener(ProblemCreateEvent.PROBLEM_CREATE_INIT, onLevelReady);
    }
    
    private function onLevelReady(event : Dynamic) : Void
    {
        m_isReady = true;
    }
}
