package dragonbox.common.state;

import dragonbox.common.state.IState;
import dragonbox.common.state.IStateMachine;

import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

import haxe.Constraints.Function;

import starling.display.Sprite;

import wordproblem.display.Layer;

class BaseState extends Layer implements IState
{
    private var m_stateMachine : IStateMachine;
    
    public function new(stateMachine : IStateMachine)
    {
        super();
        m_stateMachine = stateMachine;
    }
    
    public function enter(fromState : Dynamic, params : Array<Dynamic> = null) : Void
    {
    }
    
    public function update(time : Time, mouseState : MouseState) : Void
    {
    }
    
    public function exit(toState : Dynamic) : Void
    {
    }
    
    public function getSprite() : Sprite
    {
        return this;
    }
    
    override public function dispose() : Void
    {
        removeEventListeners();
        super.dispose();
    }
    
    private function getStateMachine() : IStateMachine
    {
        return m_stateMachine;
    }
    
    private function changeState(classDefinition : Dynamic, params : Array<Dynamic>, transitionFunction : Function = null) : Void
    {
        m_stateMachine.changeState(classDefinition, params, transitionFunction);
    }
}
