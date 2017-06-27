package wordproblem.hints
{
    import wordproblem.engine.scripting.graph.ScriptStatus;

    /**
     * Tutorial have lots of one-off logic for hints.
     * 
     * The content that should be shown and the dismissal conditions are specific to that level.
     */
    public class CustomFillLogicHint extends HintScript
    {
        /**
         * Custom show should contain all logic to start showing parts of the hint on the screen
         */
        private var m_customShow:Function;
        private var m_customShowParams:Array;
        
        /**
         * The custom visit is also where dismissal logic should go as well as the custom logic that runs
         * on every frame.
         * 
         * Function is boolean that should return false if the hint should dismiss on this frame
         */
        private var m_customVisit:Function;
        private var m_customVisitParams:Array;
        
        /**
         * This is a clean up function
         */
        private var m_customHide:Function;
        private var m_customHideParams:Array;
        
        public function CustomFillLogicHint(customShow:Function,
                                            customShowParams:Array,
                                            customVisit:Function,
                                            customVisitParams:Array,
                                            customHide:Function,
                                            customHideParams:Array,
                                            unlocked:Boolean, 
                                            id:String=null, 
                                            isActive:Boolean=true)
        {
            super(unlocked, id, isActive);
            
            m_customShow = customShow;
            m_customVisit = customVisit;
            m_customHide = customHide;
            
            m_customShowParams = customShowParams;
            m_customVisitParams = customVisitParams;
            m_customHideParams = customHideParams;
        }
        
        override public function visit():int
        {
            var status:int = super.visit();
            
            // Must return fail if interrupt finished
            if (m_customVisit != null && !m_customVisit.apply(null, m_customVisitParams))
            {
                status = ScriptStatus.FAIL;
            }
            
            return status;
        }
        
        override public function show():void
        {
            if (m_customShow != null)
            {
                m_customShow.apply(null, m_customShowParams);
            }
        }
        
        override public function hide():void
        {
            if (m_customHide != null)
            {
                m_customHide.apply(null, m_customHideParams);
            }
        }
    }
}