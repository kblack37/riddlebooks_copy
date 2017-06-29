package dragonbox.common.state;


import dragonbox.common.display.ISprite;
import dragonbox.common.dispose.IDisposable;
import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

interface IState extends ISprite extends IDisposable
{

    /**
     * Called when this state is entered from the state machine
     * 
     * @param fromState
     *      The previous state object we were in before transitioning to this one
     * @param params
     *      A list of parameters to configure the new state. The param list is specific
     *      each subclass.
     */
    function enter(fromState : Dynamic, params : Array<Dynamic> = null) : Void;
    
    /**
     * Update the current state based on some timer tick held by the containing
     * state machine.
     */
    function update(time : Time, mouseState : MouseState) : Void;
    
    /**
     * Called when this state is exited
     * 
     * @param toState
     *      The next state to transition to (doesn't seem to have much use
     *      right now)
     */
    function exit(toState : Dynamic) : Void;
}
