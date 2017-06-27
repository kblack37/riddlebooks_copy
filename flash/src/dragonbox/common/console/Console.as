package dragonbox.common.console
{
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.ui.Keyboard;
	
	import dragonbox.common.console.components.HistoryWindow;
	import dragonbox.common.console.components.InputWindow;
	import dragonbox.common.console.components.Intellisense;
	import dragonbox.common.console.components.MethodInspector;
	import dragonbox.common.console.expression.DynamicInvokeEvent;
	import dragonbox.common.console.expression.MethodExpression;

	public class Console extends MovieClip implements IConsole
	{
		public static const HELP_FORMAT:TextFormat = new TextFormat("Kalinga");
		HELP_FORMAT.color = 0xffee88;
		HELP_FORMAT.size = 14;
		HELP_FORMAT.align = TextFormatAlign.LEFT;
		
		private var m_consoleInterfacables:Vector.<IConsoleInterfacable>;
		private var m_historyWindow:HistoryWindow;
		private var m_inputWindow:InputWindow;
		private var m_intellisense:Intellisense;
		private var m_methodInspector:MethodInspector;
		
		private var m_history:Vector.<String>;
		private var m_historyPointer:int;
		
		public function Console(stage:Stage)
		{
			width = stage.stageWidth;
			height = stage.stageHeight;
			
			m_consoleInterfacables = new Vector.<IConsoleInterfacable>();
			
			m_historyWindow = new HistoryWindow();
			addChild(m_historyWindow);
			
			m_inputWindow = new InputWindow();
			addChild(m_inputWindow);
			
			m_intellisense = new Intellisense();
			m_intellisense.visible = false;
			m_inputWindow.addChild(m_intellisense);
			
			m_methodInspector = new MethodInspector();
			m_methodInspector.visible = false;
			m_inputWindow.addChild(m_methodInspector);
			
			m_history = new Vector.<String>();
			m_historyPointer = 0;
			
			stage.addChild(this);
			
			repaint();
			
			stage.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onStageKeyDown);
			
			m_inputWindow.addEventListener(DynamicInvokeEvent.EVENT_TYPE, onDynamicInvoke)
			const inputField:TextField = m_inputWindow.getInputField();
			inputField.addEventListener(KeyboardEvent.KEY_DOWN, onInputWindowKeyDown);
			inputField.addEventListener(KeyboardEvent.KEY_UP, onInputWindowKeyUp);
			
			visible = false;
			
			m_historyWindow.pushLine("For a list of available objects type 'help'", HELP_FORMAT);
		}
		
		public function registerConsoleInterfacable(consoleInterfacable:IConsoleInterfacable):void
		{
			this.m_consoleInterfacables.push(consoleInterfacable);	
		}
		
		public function dispose():void
		{
			m_consoleInterfacables = null;
			
			while(this.numChildren > 0)
			{
				this.removeChildAt(0);
			}
			
			m_inputWindow.removeEventListener(DynamicInvokeEvent.EVENT_TYPE, onDynamicInvoke)
			const inputField:TextField = m_inputWindow.getInputField();
			inputField.removeEventListener(KeyboardEvent.KEY_DOWN, onInputWindowKeyDown);
			inputField.removeEventListener(KeyboardEvent.KEY_UP, onInputWindowKeyUp);
		}
		
		private function handleCommand(command:String):void
		{
			switch(command)
			{
				case "help":
				{
					for each(var consoleInterfacable:IConsoleInterfacable in m_consoleInterfacables)
					{
						const objectAlias:String = consoleInterfacable.getObjectAlias();
						m_historyWindow.pushLine("  " + objectAlias, HELP_FORMAT);
					}
					break;
				}
			}
		}
		
		private function onAddedToStage(e:Event):void
		{
			stage.removeChild(this);
			stage.addChild(this);
			
			repaint();
		}
		
		private function onStageKeyDown(e:KeyboardEvent):void
		{
			const tilde:int = 192;
			if(e.keyCode == tilde)
			{
				this.visible = !this.visible;
				this.stage.focus = m_inputWindow.getInputField();
				dispatchEvent(new ConsoleVisibilityEvent(this.visible));
			}
		}
		
		private function onInputWindowKeyDown(e:KeyboardEvent):void
		{
			const tilde:int = 96;
			switch(e.keyCode)
			{
				case tilde:
				{
					this.visible = !this.visible;
					this.stage.focus = m_inputWindow.getInputField();
					dispatchEvent(new ConsoleVisibilityEvent(this.visible));
					break;
				}
				case Keyboard.UP:
				{
					if(m_intellisense.visible)
					{
						m_intellisense.selectPrevious();
					}
					else
					{
						previousHistory();
					}
					break;
				}
				case Keyboard.DOWN:
				{
					if(m_intellisense.visible)
					{
						m_intellisense.selectNext();
					}
					else
					{
						nextHistory();	
					}
					break;
				}
				case Keyboard.ENTER:
				{
					if(m_intellisense.visible)
					{
						// Intellisense needs to replace a certain part of the statement based on the current expression.
						const selectedText:String = m_intellisense.getSelectedText();
						m_inputWindow.completeStatementPartial(selectedText);
						m_intellisense.visible = false;
						m_methodInspector.visible = false;
					}
					else
					{
						const command:String = m_inputWindow.getInputField().text;
						
						m_history.push(command);
						m_historyPointer = m_history.length;
						m_inputWindow.onKeyPress(e);
						
						handleCommand(command);	
					}
					
					break;
				}
				default:
				{
					const zero:int = 48;
					const nine:int = 57;
					const a:int = 65;
					const z:int = 90;
					const comma:int = 188;
					const minus:int = 189;
					const period:int = 190;
					
					if((e.keyCode >= a && e.keyCode <= z) ||
						(e.keyCode >= zero && e.keyCode <= nine) ||
						e.keyCode == Keyboard.BACKSPACE ||
						e.keyCode == period ||
						e.keyCode == comma ||
						e.keyCode == minus)
					{
						m_inputWindow.onKeyPress(e);
					}
					break;
				}
			}
			
			e.stopImmediatePropagation(); // We have to do this, otherwise the flex framework will dispatch a second event. Sigh.
		}
		
		private function onInputWindowKeyUp(e:KeyboardEvent):void
		{
			switch(e.keyCode)
			{
				case(Keyboard.ESCAPE):
				{
					if(m_intellisense.visible)
					{
						m_intellisense.visible = false;
					}
					if(m_methodInspector.visible)
					{
						m_methodInspector.visible = false;
					}
					break;
				}
				default:
				{
					const inputTextField:TextField = m_inputWindow.getInputField();
					
					m_intellisense.visible = false;
					m_methodInspector.visible = false;
					
					const methodExpression:MethodExpression = m_inputWindow.getCurrentExpression();
					if(methodExpression.endAliasIndex == 0 && methodExpression.statement.length > 0)
					{
						const matchingInterfacables:Vector.<IConsoleInterfacable> = findAliasesStartingWith(methodExpression.statement);
						const matchingAliases:Vector.<String> = new Vector.<String>();
						for each(var matchingInterfacable:IConsoleInterfacable in matchingInterfacables)
						{
							matchingAliases.push(matchingInterfacable.getObjectAlias());
						}
						
						if(matchingAliases.length > 0)
						{
							m_intellisense.populate(matchingAliases);
							showIntellisense();
						}
					}
					else if(methodExpression.endAliasIndex > 0 && methodExpression.endMethodIndex == 0)
					{
						const objectAlias:String = methodExpression.objectAlias; 
						const object:IConsoleInterfacable = getInterfacableByAlias(objectAlias);
						var methodPartial:String = "";
						const parts:Array =  methodExpression.statement.split(".");
						if(parts.length > 0)
						{
							methodPartial = parts[1];
						}
						const supportedMethods:Vector.<String> = findSupportedMethodsStartingWith(object, methodPartial);
						m_intellisense.populate(supportedMethods);
						showIntellisense();
					}
					else if(methodExpression.endMethodIndex > 0)
					{
						const methodAlias:String = methodExpression.methodAlias;
						const methodObject:IConsoleInterfacable = getInterfacableByAlias(methodExpression.objectAlias);
						if(methodObject != null)
						{
							const methodDetails:String = methodObject.getMethodDetails(methodAlias);
							if(methodDetails.length > 0)
							{
								m_methodInspector.populate(methodDetails);
								showMethodInsepctor();
							}
						}
					}
					
					break;
				}
			}
		}
		
		private function showIntellisense():void
		{
			const inputField:TextField = m_inputWindow.getInputField();
			m_intellisense.x = inputField.textWidth;
			m_intellisense.y = inputField.textHeight;
			
			m_intellisense.visible = true;
		}
		
		private function showMethodInsepctor():void
		{
			const inputField:TextField = m_inputWindow.getInputField();
			m_methodInspector.x = inputField.textWidth;
			m_methodInspector.y = inputField.textHeight;
			
			m_methodInspector.visible = true;
		}
		
		private function nextHistory():void
		{
			if(m_history.length > 0)
			{
				
 				m_historyPointer = Math.min(m_historyPointer+1, m_history.length-1);
				m_inputWindow.getInputField().text = m_history[m_historyPointer];
				m_inputWindow.applySyntaxHilighting();
			}
		}
		
		private function previousHistory():void
		{
			if(m_history.length > 0)
			{
				m_historyPointer = Math.max(0, m_historyPointer-1);
				m_inputWindow.getInputField().text = m_history[m_historyPointer];
				m_inputWindow.applySyntaxHilighting();
			}
		}
		
		private function getInterfacableByAlias(alias:String):IConsoleInterfacable
		{
			var object:IConsoleInterfacable = null;
			for each(var consoleInterfacable:IConsoleInterfacable in m_consoleInterfacables)
			{
				if(consoleInterfacable.getObjectAlias() == alias)
				{
					object = consoleInterfacable;
					break;
				}
			}
			return object;
		}
		
		private function findAliasesStartingWith(partial:String):Vector.<IConsoleInterfacable>
		{
			const matchingInterfacables:Vector.<IConsoleInterfacable> = new Vector.<IConsoleInterfacable>();
			
			for each(var consoleInterfacable:IConsoleInterfacable in m_consoleInterfacables)
			{
				const interfacableAlias:String = consoleInterfacable.getObjectAlias();
				var match:Boolean = interfacableAlias != partial;
				if(match) // We really only want partial matches.
				{
					const partialLength:int = partial.length;
					for(var i:int = 0; i < partialLength; i++)
					{
						if(partial.charAt(i) != interfacableAlias.charAt(i))
						{
							match = false;
							break;
						}
					}
					
					if(match)
					{
						matchingInterfacables.push(consoleInterfacable);
					}
				}
			}
			
			return matchingInterfacables;
		}
		
		private function findSupportedMethodsStartingWith(object:IConsoleInterfacable, methodPartial:String):Vector.<String>
		{
			const methods:Vector.<String> = new Vector.<String>();
			
			if(object != null)
			{
				const supportedMethods:Vector.<String> = object.getSupportedMethods();
				
				for each(var supportedMethod:String in supportedMethods)
				{
					var match:Boolean = supportedMethod != methodPartial;
					if(match) // We really only want partial matches.
					{
						const partialLength:int = methodPartial.length;
						for(var i:int = 0; i < partialLength; i++)
						{
							if(methodPartial.charAt(i) != supportedMethod.charAt(i))
							{
								match = false;
								break;
							}
						}
						
						if(match)
						{
							methods.push(supportedMethod);
						}
					}
				}
			}
			
			return methods;
		}
		
		private function onDynamicInvoke(e:DynamicInvokeEvent):void
		{
			const methodExpression:MethodExpression = e.methodExpression;
			if(methodExpression.wellFormed)
			{
				const objectAlias:String = methodExpression.objectAlias;
				
				m_historyWindow.pushMethodExpression(methodExpression);
				
				for each(var consoleInterfacable:IConsoleInterfacable in m_consoleInterfacables)
				{
					if(consoleInterfacable.getObjectAlias() == objectAlias)
					{
						try
						{
							consoleInterfacable.invoke(methodExpression);
						}
						catch(error:Error)
						{
							m_historyWindow.pushLine(error.toString(), HistoryWindow.ERROR_FORMAT);
						}
						break;
					}
				}
			}
			else
			{
				m_historyWindow.pushLine("Synatx error, expected: Object.method(arg0, arg1, ... argN)", HistoryWindow.ERROR_FORMAT);
			}
		}
		
		private function repaint():void
		{
			m_historyWindow.repaint();
			m_inputWindow.repaint();
			
			m_inputWindow.y = m_historyWindow.height;
			
			width = stage.stageWidth;
			height = m_historyWindow.height + m_inputWindow.height;
		}
	}
}