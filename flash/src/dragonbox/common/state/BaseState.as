package dragonbox.common.state
{
	import dragonbox.common.time.Time;
	import dragonbox.common.ui.MouseState;
	
	import starling.display.Sprite;
	
	import wordproblem.display.Layer;
	
	public class BaseState extends Layer implements IState
	{
		private var m_stateMachine:IStateMachine;
		
		public function BaseState(stateMachine:IStateMachine)
		{
			m_stateMachine = stateMachine;
		}
		
		public function enter(fromState:Object, params:Vector.<Object>=null):void
		{
		}
		
		public function update(time:Time, mouseState:MouseState):void
		{
		}
		
		public function exit(toState:Object):void
		{
		}
		
		public function getSprite():Sprite
		{
			return this;
		}
		
		override public function dispose():void
		{
			removeEventListeners();
            super.dispose();
		}
		
		protected function getStateMachine():IStateMachine
		{
			return m_stateMachine;
		}
		
		protected function changeState(classDefinition:Object, params:Vector.<Object>, transitionFunction:Function=null):void
		{
			m_stateMachine.changeState(classDefinition, params, transitionFunction);
		}
	}
}