package wordproblem.hints.processes;


import starling.core.Starling;

import wordproblem.characters.HelperCharacterController;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.engine.scripting.graph.action.CustomVisitNode;
import wordproblem.engine.scripting.graph.selector.SequenceSelector;

class MoveCharacterToProcess extends ScriptNode
{
    private var m_characterController : HelperCharacterController;
    private var m_characterId : String;
    
    // If start is NaN, then do not move to the start
    private var m_startX : Float;
    private var m_startY : Float;
    
    private var m_endX : Float;
    private var m_endY : Float;
    private var m_velocity : Float;
    private var m_moveScheduled : Bool;
    
    public function new(characterAndCalloutControl : HelperCharacterController,
            characterId : String,
            startX : Float,
            startY : Float,
            endX : Float,
            endY : Float,
            velocity : Float,
            id : String = null,
            isActive : Bool = true)
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
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (!value) 
        {
            m_characterController.setCharacterVisible({
                        id : m_characterId,
                        visible : false,

                    });
        }
    }
    
    override public function visit() : Int
    {
        var status : Int = ScriptStatus.FAIL;
        if (!m_moveScheduled) 
        {
            var sequenceSelector : SequenceSelector = new SequenceSelector("move_seq");
            
            // Jump to starting sequence
            if (!Math.isNaN(m_startX) && !Math.isNaN(m_startY)) 
            {
                sequenceSelector.pushChild(new CustomVisitNode(m_characterController.setCharacterVisible, {
                            id : m_characterId,
                            visible : false,

                        }));
                sequenceSelector.pushChild(new CustomVisitNode(m_characterController.moveCharacterTo, {
                            id : m_characterId,
                            x : m_startX,
                            y : m_startY,
                            velocity : -1,

                        }));
                sequenceSelector.pushChild(new CustomVisitNode(secondsElapsed, {
                            duration : 0.01

                        }));
            }
            sequenceSelector.pushChild(new CustomVisitNode(m_characterController.setCharacterVisible, {
                        id : m_characterId,
                        visible : true,

                    }));
            sequenceSelector.pushChild(new CustomVisitNode(m_characterController.moveCharacterTo, {
                        id : m_characterId,
                        x : m_endX,
                        y : m_endY,
                        velocity : m_velocity,

                    }));
            sequenceSelector.pushChild(new CustomVisitNode(m_characterController.isStillMoving, {
                        id : m_characterId

                    }));
            
            pushChild(sequenceSelector);
            
            m_moveScheduled = true;
        }  // Return success only if the move seq has finished executing  
        
        
        
        var moveSeq : SequenceSelector = try cast(getNodeById("move_seq"), SequenceSelector) catch(e:Dynamic) null;
        if (moveSeq != null) 
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
    
    override public function reset() : Void
    {
        // Kill the move sequence on restart
        var moveSeq : ScriptNode = getNodeById("move_seq");
        if (moveSeq != null) 
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
    private function secondsElapsed(param : Dynamic) : Int
    {
        // On the first visit
        if (!param.exists("completed")) 
        {
            var duration : Float = param.duration;
            Starling.juggler.delayCall(function() : Void
                    {
                        Reflect.setField(param, "completed", true);
                    },
                    duration
                    );
            Reflect.setField(param, "completed", false);
        }
        
        return ((Reflect.field(param, "completed"))) ? ScriptStatus.SUCCESS : ScriptStatus.FAIL;
    }
}
