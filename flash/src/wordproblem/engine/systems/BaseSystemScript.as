package wordproblem.engine.systems
{
    import wordproblem.engine.component.ComponentManager;
    import wordproblem.engine.scripting.graph.ScriptNode;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    
    public class BaseSystemScript extends ScriptNode
    {
        private var m_componentManagers:Vector.<ComponentManager>;
        
        public function BaseSystemScript(id:String=null, isActive:Boolean=true)
        {
            super(id, isActive);
            
            m_componentManagers = new Vector.<ComponentManager>();
        }
        
        override public function visit():int
        {
            var i:int;
            var numComponentManagers:int = m_componentManagers.length;
            for (i = 0; i < numComponentManagers; i++)
            {
                update(m_componentManagers[i]);
            }
            
            return ScriptStatus.RUNNING;
        }
        
        public function addComponentManager(manager:ComponentManager):void
        {
            m_componentManagers.push(manager);
        }
        
        public function clear():void
        {
            m_componentManagers.length = 0;
        }
        
        /**
         * Should override to apply custom logic
         */
        public function update(componentManager:ComponentManager):void
        {
        }
    }
}