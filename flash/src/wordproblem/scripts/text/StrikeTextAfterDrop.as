package wordproblem.scripts.text 
{
	import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
	
	import starling.events.Event;
	
	import wordproblem.engine.IGameEngine;
	import wordproblem.engine.component.Component;
	import wordproblem.engine.component.ExpressionComponent;
	import wordproblem.engine.events.GameEvent;
	import wordproblem.engine.text.view.DocumentView;
	import wordproblem.engine.widget.TextAreaWidget;
	import wordproblem.resource.AssetManager;
	import wordproblem.scripts.BaseGameScript;
    
	/**
	 * Script that draws a line through a piece of text that is bound to a card.
     * 
	 * @author Nathaniel Swedberg
	 */
	public class StrikeTextAfterDrop extends BaseGameScript 
	{ 
		private var m_textAreaWidget:TextAreaWidget;
		
		public function StrikeTextAfterDrop(gameEngine:IGameEngine, compiler:IExpressionTreeCompiler, assetManager:AssetManager, id:String) 
		{
			super(gameEngine, compiler, assetManager, id);
		}
		
		/**
		 * When the level starts add eventlisteners and call up the super
		 */
		override protected function onLevelReady():void
        {
            super.onLevelReady();
            m_textAreaWidget = super.m_gameEngine.getUiEntity("textArea") as TextAreaWidget;
			super.m_gameEngine.addEventListener(GameEvent.EXPRESSION_REVEALED, onExpressionRevealed);
        }
		
		/**
		 * truggers when the event is called
		 * @param	event: the event 
		 * @param	param: passed in with the envent
		 */
		private function onExpressionRevealed(event:Event, param:Object):void 
		{
			var components:Vector.<Component> = m_textAreaWidget.componentManager.getComponentListForType(ExpressionComponent.TYPE_ID);
			var component:ExpressionComponent = param.component;
			for (var i:int = 0; i < components.length; i++) 
			{
				var documentId:ExpressionComponent = components[i] as ExpressionComponent;
				if (documentId.expressionString == component.expressionString)
				{
					var children:Vector.<DocumentView> = m_textAreaWidget.getDocumentViewsAtPageIndexById(documentId.entityId);
					for each (var c:DocumentView in children)
					{
						c.node.setTextDecoration("line-through");
						c.node.setSelectable(false);
					}
				} 
			}			
		}
		
		override public function dispose():void
		{
            super.dispose();
			super.m_gameEngine.removeEventListener(GameEvent.EXPRESSION_REVEALED, onExpressionRevealed)
		}
	}

}