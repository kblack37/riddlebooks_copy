package wordproblem.engine.systems;


import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.ScriptStatus;

class BaseSystemScript extends ScriptNode
{
    private var m_componentManagers : Array<ComponentManager>;
    
    public function new(id : String = null, isActive : Bool = true)
    {
        super(id, isActive);
        
        m_componentManagers = new Array<ComponentManager>();
    }
    
    override public function visit() : Int
    {
        var i : Int;
        var numComponentManagers : Int = m_componentManagers.length;
        for (i in 0...numComponentManagers){
            update(m_componentManagers[i]);
        }
        
        return ScriptStatus.RUNNING;
    }
    
    public function addComponentManager(manager : ComponentManager) : Void
    {
        m_componentManagers.push(manager);
    }
    
    public function clear() : Void
    {
		m_componentManagers = new Array<ComponentManager>();
    }
    
    /**
     * Should override to apply custom logic
     */
    public function update(componentManager : ComponentManager) : Void
    {
    }
}
