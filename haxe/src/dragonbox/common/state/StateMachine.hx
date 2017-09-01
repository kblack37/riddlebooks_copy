package dragonbox.common.state;


import dragonbox.common.time.Time;
import dragonbox.common.ui.MouseState;

import haxe.Constraints.Function;

import openfl.display.Sprite;

/**
	 * This state machine is responsible for managing the various game screens visible
	 * to the player. In this instance a state is simply a top level view, for example
	 * the title screen, the level select, and game play screens which each be their own
	 * states.
	 */
class StateMachine extends Sprite implements IStateMachine
{
    private var states : Array<IState>;
    private var previousState : Dynamic;
    private var currentState : IState;
    
    /** Temp holder variable to remember what state to go to between animation frames */
    private var stateToTransitionTo : Dynamic;
    
    /** Temp holder variable to remember params to pass between animation frames */
    private var paramsForStateToGoTo : Array<Dynamic>;
    
    /**
     * 
     */
    private var transitionFunction : Function;
    
    private var transitionInProgress : Bool;
    
    public function new(stageWidth : Float, stageHeight : Float)
    {
        super();
        this.states = new Array<IState>();
    }
    
    public function register(state : IState) : Void
    {
        this.states.push(state);
    }
    
    public function changeState(state : Dynamic, params : Array<Dynamic> = null, transitionFunction : Function = null) : Void
    {
        // If we are already transitioning between states, any further calls will cause
        // us to jump immediately to the new state
        if (transitionInProgress || transitionFunction == null) 
        {
            // Stop the current transition
            transitionInProgress = false;
            
            goToState(state, params);
        }
        else 
        {
            // Functionality to have animated transitions between states
            if (this.currentState != null) 
            {
                stateToTransitionTo = state;
                paramsForStateToGoTo = params;
                transitionInProgress = true;
                
                // Immediately enter the new state and put it on top
                // since transitions may want to modify it
                var nextState : IState = this.getStateInstance(state);
                nextState.enter(this.currentState, params);
                this.addChild(nextState.getSprite());
                transitionFunction(this.currentState, nextState, finishTransition);
            }
            else 
            {
                // Immediately go to the new state screen
                goToState(state, params);
            }
        }
    }
    
    public function update(time : Time, mouseState : MouseState) : Void
    {
        if (!transitionInProgress && this.currentState != null) 
        {
            this.currentState.update(time, mouseState);
        }
    }
    
    public function getSprite() : Sprite
    {
        return this;
    }
    
    public function getStateInstance(state : Dynamic) : IState
    {
        var stateToReturn : IState = null;
        var i : Int = 0;
        var numStates : Int = this.states.length;
        for (i in 0...numStates){
            var stateToCompare : IState = this.states[i];
            if (state == stateToCompare || Std.is(state, Class) && Std.is(stateToCompare, (Type.getClass(state)))) 
            {
                stateToReturn = stateToCompare;
                break;
            }
        }
        return stateToReturn;
    }
    
    public function getCurrentState() : IState
    {
        return this.currentState;
    }
    
    public function dispose() : Void
    {
        if (this.currentState != null) 
        {
            this.removeChild(this.currentState.getSprite());
            currentState.exit(null);
        }
        
        for (state in this.states)
        {
            state.dispose();
        }
    }
    
    private function goToState(state : Dynamic, params : Array<Dynamic>) : Void
    {
        if (this.currentState != null) 
        {
            this.removeChild(this.currentState.getSprite());
            currentState.exit(state);
        }
        
        this.currentState = getStateInstance(state);
        
        // Making sure the state is on the display before enter, the reason is that
        // bubbled events might be triggered on enter
        this.addChild(currentState.getSprite());
        this.currentState.enter(this.previousState, params);
        
        this.previousState = state;
    }
    
    private function finishTransition() : Void
    {
        transitionInProgress = false;
        
        // Do not re-enter the current state
        if (this.currentState != null) 
        {
            this.removeChild(this.currentState.getSprite());
            currentState.exit(stateToTransitionTo);
        }
        this.currentState = getStateInstance(stateToTransitionTo);
        this.previousState = stateToTransitionTo;
    }
}
