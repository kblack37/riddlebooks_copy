package dragonbox.common.state;


import dragonbox.common.display.ISprite;
import dragonbox.common.dispose.IDisposable;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

import haxe.Constraints.Function;

interface IStateMachine extends ISprite extends IDisposable
{

    /**
     * Add a new possible state to the collection
     * 
     * @param state
     *      A created instance of a state
     */
    function register(state : IState) : Void;
    
    /**
     * Transition to a new state
     * 
     * @param state
     *      The class definition of the state to go to
     * @param params
     *      List of parameters to pass to the state to go to
     * @param transitionFunction
     *      Signature callback(prevState:IState, nextState:IState, finishCallback:Function)
     *      prevState is the state switching from
     *      nextState is the state to switch to
     *      finishCallback MUST BE CALLED when the app has finished the transition
     */
    function changeState(state : Dynamic, params : Array<Dynamic> = null, transitionFunction : Function = null) : Void;
    
    /**
     * Get the instance of a state object based on the class definition
     * 
     * @param state
     *      The class definition of the state to retrieve
     * @return
     *      The instance of the state held by the machine
     */
    function getStateInstance(state : Dynamic) : IState;
    function getCurrentState() : IState;
    
    function update(time : Time, mouseState : MouseState) : Void;
}
