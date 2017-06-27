package dragonbox.common.state
{
	import dragonbox.common.display.ISprite;
	import dragonbox.common.dispose.IDisposable;
	import dragonbox.common.time.Time;
	import dragonbox.common.ui.MouseState;

	public interface IState extends ISprite, IDisposable
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
		function enter(fromState:Object, params:Vector.<Object>=null):void;
        
        /**
         * Update the current state based on some timer tick held by the containing
         * state machine.
         */
		function update(time:Time, mouseState:MouseState):void;
        
        /**
         * Called when this state is exited
         * 
         * @param toState
         *      The next state to transition to (doesn't seem to have much use
         *      right now)
         */
		function exit(toState:Object):void;
	}
}