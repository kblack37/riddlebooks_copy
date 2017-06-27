package wordproblem.hints.processes
{
    import starling.core.Starling;
    
    import wordproblem.characters.HelperCharacterController;
    import wordproblem.engine.scripting.graph.ScriptNode;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.scripting.graph.action.CustomVisitNode;
    import wordproblem.engine.scripting.graph.selector.SequenceSelector;
    
    public class MoveCharacterToProcess extends ScriptNode
    {
        private var m_characterController:HelperCharacterController;
        private var m_characterId:String;
        
        // If start is NaN, then do not move to the start
        private var m_startX:Number;
        private var m_startY:Number;
        
        private var m_endX:Number;
        private var m_endY:Number;
        private var m_velocity:Number;
        private var m_moveScheduled:Boolean;
        
        public function MoveCharacterToProcess(characterAndCalloutControl:HelperCharacterController,
                                               characterId:String,
                                               startX:Number,
                                               startY:Number,
                                               endX:Number,
                                               endY:Number,
                                               velocity:Number,
                                               id:String=null, 
                                               isActive:Boolean=true)
        {
            super(id, isActive);
            
            m_characterController = characterAndCalloutControl;
            m_characterId = characterId;
            m_startX = startX;
            m_startY = startY;
            m_endX = endX;
            m_endY = endY;
            m_velocity = velocity;
            m_moveScheduled = false;
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            if (!value)
            {
                m_characterController.setCharacterVisible({id: m_characterId, visible: false});
            }
        }
        
        override public function visit():int
        {
            var status:int = ScriptStatus.FAIL;
            if (!m_moveScheduled)
            {
                var sequenceSelector:SequenceSelector = new SequenceSelector("move_seq");
                
                // Jump to starting sequence
                if (!isNaN(m_startX) && !isNaN(m_startY))
                {
                    sequenceSelector.pushChild(new CustomVisitNode(m_characterController.setCharacterVisible, {id:m_characterId, visible:false}));
                    sequenceSelector.pushChild(new CustomVisitNode(m_characterController.moveCharacterTo, {id:m_characterId, x:m_startX, y:m_startY, velocity:-1}));
                    sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {duration:0.01}));
                }
                sequenceSelector.pushChild(new CustomVisitNode(m_characterController.setCharacterVisible, {id:m_characterId, visible:true}));
                sequenceSelector.pushChild(new CustomVisitNode(m_characterController.moveCharacterTo, {id:m_characterId, x:m_endX, y:m_endY, velocity:m_velocity}));
                sequenceSelector.pushChild(new CustomVisitNode(m_characterController.isStillMoving, {id:m_characterId}));
                
                pushChild(sequenceSelector);
                
                m_moveScheduled = true;
            }
            
            // Return success only if the move seq has finished executing
            var moveSeq:SequenceSelector = getNodeById("move_seq") as SequenceSelector;
            if (moveSeq)
            {
                if (moveSeq.allChildrenFinished())
                {
                    deleteChild(getNodeById("move_seq"));
                    status = ScriptStatus.SUCCESS;
                }
                else
                {
                    moveSeq.visit();
                    status = ScriptStatus.RUNNING;
                }
            }
            
            return status;
        }
        
        override public function reset():void
        {
            // Kill the move sequence on restart
            var moveSeq:ScriptNode = getNodeById("move_seq");
            if (moveSeq)
            {
                deleteChild(moveSeq);
            }
            m_moveScheduled = false;
        }
        
        /**
         * Wait for some number of seconds to elapse before continuing
         * 
         * @param param
         *      duration:Number of seconds to wait to elapse
         */
        protected function secondsElapsed(param:Object):int
        {
            // On the first visit
            if (!param.hasOwnProperty("completed"))
            {
                var duration:Number = param.duration;
                Starling.juggler.delayCall(function():void
                {
                    param["completed"] = true;
                },
                    duration
                );
                param["completed"] = false;
            }
            
            return (param["completed"]) ? ScriptStatus.SUCCESS : ScriptStatus.FAIL;
        }
    }
}