package wordproblem.hints
{
    /**
     * This node class encapsulates the proper selection of the a hint process base on the current
     * game state.
     * 
     * This should be subclassed anytime we have custom picking logic
     */
    public class HintSelectorNode
    {
        private var m_children:Vector.<HintSelectorNode>;
        
        private var m_customGetHintFunction:Function;
        private var m_customGetHintParameters:Array;
        
        public function HintSelectorNode()
        {
            m_children = new Vector.<HintSelectorNode>();
        }
        
        public function addChild(child:HintSelectorNode):void
        {
            m_children.push(child);   
        }
        
        /**
         * Subclasses of this hint selector may need the visit function in order to
         * update or poll state on each frame. For example the selector might need to manually
         * examine clicks on the ui to figure out if it should give a hint.
         */
        public function visit():void
        {
            var i:int;
            var numChildren:int = m_children.length;
            for (i = 0; i < numChildren; i++)
            {
                m_children[i].visit();
            }
        }
        
        /**
         * Used if we want to inject custom logic in the caller object of how the hint script should
         * be generated
         * 
         * @param customGetHintFunction
         *      Must return null or a hint script
         * @param customGetHintParameters
         *      Array of objects to be passed to the custom function
         */
        public function setCustomGetHintFunction(customGetHintFunction:Function, customGetHintParameters:Array):void
        {
            m_customGetHintFunction = customGetHintFunction;
            m_customGetHintParameters = customGetHintParameters;
        }
        
        /**
         *
         * @return
         *      null if this node or any of its children do not have an appropriate hint at
         *      the time this function was called given the current game state.
         */
        public function getHint():HintScript
        {
            var hint:HintScript = null;
            
            if (m_customGetHintFunction)
            {
                hint = m_customGetHintFunction.apply(null, m_customGetHintParameters);
            }
            else
            {
                var i:int;
                for (i = 0; i < m_children.length; i++)
                {
                    hint = m_children[i].getHint();
                    if (hint != null)
                    {
                        break;
                    }
                }
            }
            
            return hint;
        }
        
        public function dispose():void
        {
            var i:int;
            for (i = 0; i < m_children.length; i++)
            {
                m_children[i].dispose();
            }
        }
    }
}