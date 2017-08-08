package dragonbox.common.console;

import dragonbox.common.console.ConsoleVisibilityEvent;
import dragonbox.common.console.IConsole;
import dragonbox.common.console.IConsoleInterfacable;
import flash.errors.Error;

import dragonbox.common.console.components.HistoryWindow;
import dragonbox.common.console.components.InputWindow;
import dragonbox.common.console.components.Intellisense;
import dragonbox.common.console.components.MethodInspector;
import dragonbox.common.console.expression.DynamicInvokeEvent;
import dragonbox.common.console.expression.MethodExpression;

import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.ui.Keyboard;

import starling.core.Starling;
import starling.display.Sprite;
import starling.events.Event;
import starling.events.KeyboardEvent;
import starling.text.TextField;

class Console extends Sprite implements IConsole
{
    public static var HELP_FORMAT : TextFormat = new TextFormat("Kalinga");
    
    
    
    
    private var m_consoleInterfacables : Array<IConsoleInterfacable>;
    private var m_historyWindow : HistoryWindow;
    private var m_inputWindow : InputWindow;
    private var m_intellisense : Intellisense;
    private var m_methodInspector : MethodInspector;
    
    private var m_history : Array<String>;
    private var m_historyPointer : Int;
    
    public function new()
    {
        super();
        width = Starling.current.stage.stageWidth;
        height = Starling.current.stage.stageHeight;
        
        m_consoleInterfacables = new Array<IConsoleInterfacable>();
        
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
        
        m_history = new Array<String>();
        m_historyPointer = 0;
        
        Starling.current.stage.addChild(this);
        
        repaint();
        
        Starling.current.stage.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        Starling.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, onStageKeyDown);
        
		// TODO: Starling KeyboardEvents are dispatched only to the stage, so this
		// may not work
        m_inputWindow.addEventListener(DynamicInvokeEvent.EVENT_TYPE, onDynamicInvoke);
        var inputField : TextField = m_inputWindow.getInputField();
        inputField.addEventListener(KeyboardEvent.KEY_DOWN, onInputWindowKeyDown);
        inputField.addEventListener(KeyboardEvent.KEY_UP, onInputWindowKeyUp);
        
        visible = false;
        
        m_historyWindow.pushLine("For a list of available objects type 'help'", HELP_FORMAT);
    }
    
    public function registerConsoleInterfacable(consoleInterfacable : IConsoleInterfacable) : Void
    {
        this.m_consoleInterfacables.push(consoleInterfacable);
    }
    
    override public function dispose() : Void
    {
        m_consoleInterfacables = null;
        
        while (this.numChildren > 0)
        {
            this.removeChildAt(0);
        }
        
        m_inputWindow.removeEventListener(DynamicInvokeEvent.EVENT_TYPE, onDynamicInvoke);
        var inputField : TextField = m_inputWindow.getInputField();
        inputField.removeEventListener(KeyboardEvent.KEY_DOWN, onInputWindowKeyDown);
        inputField.removeEventListener(KeyboardEvent.KEY_UP, onInputWindowKeyUp);
    }
    
    private function handleCommand(command : String) : Void
    {
        switch (command)
        {
            case "help":
            {
                for (consoleInterfacable in m_consoleInterfacables)
                {
                    var objectAlias : String = consoleInterfacable.getObjectAlias();
                    m_historyWindow.pushLine("  " + objectAlias, HELP_FORMAT);
                }
            }
        }
    }
    
    private function onAddedToStage(e : Event) : Void
    {
        Starling.current.stage.removeChild(this);
        Starling.current.stage.addChild(this);
        
        repaint();
    }
    
    private function onStageKeyDown(e : KeyboardEvent) : Void
    {
        var tilde : UInt = 192;
        if (e.keyCode == tilde) 
        {
            this.visible = !this.visible;
			// TODO: Starling Stage has no equivalent to this
            //this.stage.focus = m_inputWindow.getInputField();
            dispatchEvent(new ConsoleVisibilityEvent(this.visible));
        }
    }
    
    private function onInputWindowKeyDown(e : KeyboardEvent) : Void
    {
        var tilde : UInt = 96;
        var _sw0_ : UInt = (e.keyCode);
		
        switch (_sw0_)
        {
            case tilde:
            {
                this.visible = !this.visible;
				// TODO: the Starling Stage has no equivalent for this
                //this.stage.focus = m_inputWindow.getInputField();
                dispatchEvent(new ConsoleVisibilityEvent(this.visible));
            }
            case Keyboard.UP:
            {
                if (m_intellisense.visible) 
                {
                    m_intellisense.selectPrevious();
                }
                else 
                {
                    previousHistory();
                }
            }
            case Keyboard.DOWN:
            {
                if (m_intellisense.visible) 
                {
                    m_intellisense.selectNext();
                }
                else 
                {
                    nextHistory();
                }
            }
            case Keyboard.ENTER:
            {
                if (m_intellisense.visible) 
                {
                    // Intellisense needs to replace a certain part of the statement based on the current expression.
                    var selectedText : String = m_intellisense.getSelectedText();
                    m_inputWindow.completeStatementPartial(selectedText);
                    m_intellisense.visible = false;
                    m_methodInspector.visible = false;
                }
                else 
                {
                    var command : String = m_inputWindow.getInputField().text;
                    
                    m_history.push(command);
                    m_historyPointer = m_history.length;
                    m_inputWindow.onKeyPress(e);
                    
                    handleCommand(command);
                }
            }
            default:
                {
                    var zero : Int = 48;
                    var nine : Int = 57;
                    var a : Int = 65;
                    var z : Int = 90;
                    var comma : Int = 188;
                    var minus : Int = 189;
                    var period : Int = 190;
                    
                    if ((e.keyCode >= a && e.keyCode <= z) ||
                        (e.keyCode >= zero && e.keyCode <= nine) ||
                        e.keyCode == Keyboard.BACKSPACE ||
                        e.keyCode == period ||
                        e.keyCode == comma ||
                        e.keyCode == minus) 
                    {
                        m_inputWindow.onKeyPress(e);
                    }
                }
        }
        
        e.stopImmediatePropagation();
    }
    
    private function onInputWindowKeyUp(e : KeyboardEvent) : Void
    {
        var _sw1_ = (e.keyCode);        

        switch (_sw1_)
        {
            case (Keyboard.ESCAPE):
            {
                if (m_intellisense.visible) 
                {
                    m_intellisense.visible = false;
                }
                if (m_methodInspector.visible) 
                {
                    m_methodInspector.visible = false;
                }
            }
            default:
                {
                    var inputTextField : TextField = m_inputWindow.getInputField();
                    
                    m_intellisense.visible = false;
                    m_methodInspector.visible = false;
                    
                    var methodExpression : MethodExpression = m_inputWindow.getCurrentExpression();
                    if (methodExpression.endAliasIndex == 0 && methodExpression.statement.length > 0) 
                    {
                        var matchingInterfacables : Array<IConsoleInterfacable> = findAliasesStartingWith(methodExpression.statement);
                        var matchingAliases : Array<String> = new Array<String>();
                        for (matchingInterfacable in matchingInterfacables)
                        {
                            matchingAliases.push(matchingInterfacable.getObjectAlias());
                        }
                        
                        if (matchingAliases.length > 0) 
                        {
                            m_intellisense.populate(matchingAliases);
                            showIntellisense();
                        }
                    }
                    else if (methodExpression.endAliasIndex > 0 && methodExpression.endMethodIndex == 0) 
                    {
                        var objectAlias : String = methodExpression.objectAlias;
                        var object : IConsoleInterfacable = getInterfacableByAlias(objectAlias);
                        var methodPartial : String = "";
                        var parts : Array<Dynamic> = methodExpression.statement.split(".");
                        if (parts.length > 0) 
                        {
                            methodPartial = parts[1];
                        }
                        var supportedMethods : Array<String> = findSupportedMethodsStartingWith(object, methodPartial);
                        m_intellisense.populate(supportedMethods);
                        showIntellisense();
                    }
                    else if (methodExpression.endMethodIndex > 0) 
                    {
                        var methodAlias : String = methodExpression.methodAlias;
                        var methodObject : IConsoleInterfacable = getInterfacableByAlias(methodExpression.objectAlias);
                        if (methodObject != null) 
                        {
                            var methodDetails : String = methodObject.getMethodDetails(methodAlias);
                            if (methodDetails.length > 0) 
                            {
                                m_methodInspector.populate(methodDetails);
                                showMethodInsepctor();
                            }
                        }
                    }
                }
        }
    }
    
    private function showIntellisense() : Void
    {
        var inputField : TextField = m_inputWindow.getInputField();
        m_intellisense.x = inputField.width;
        m_intellisense.y = inputField.height;
        
        m_intellisense.visible = true;
    }
    
    private function showMethodInsepctor() : Void
    {
        var inputField : TextField = m_inputWindow.getInputField();
        m_methodInspector.x = inputField.width;
        m_methodInspector.y = inputField.height;
        
        m_methodInspector.visible = true;
    }
    
    private function nextHistory() : Void
    {
        if (m_history.length > 0) 
        {
            
            m_historyPointer = Std.int(Math.min(m_historyPointer + 1, m_history.length - 1));
            m_inputWindow.getInputField().text = m_history[m_historyPointer];
            m_inputWindow.applySyntaxHilighting();
        }
    }
    
    private function previousHistory() : Void
    {
        if (m_history.length > 0) 
        {
            m_historyPointer = Std.int(Math.max(0, m_historyPointer - 1));
            m_inputWindow.getInputField().text = m_history[m_historyPointer];
            m_inputWindow.applySyntaxHilighting();
        }
    }
    
    private function getInterfacableByAlias(alias : String) : IConsoleInterfacable
    {
        var object : IConsoleInterfacable = null;
        for (consoleInterfacable in m_consoleInterfacables)
        {
            if (consoleInterfacable.getObjectAlias() == alias) 
            {
                object = consoleInterfacable;
                break;
            }
        }
        return object;
    }
    
    private function findAliasesStartingWith(partial : String) : Array<IConsoleInterfacable>
    {
        var matchingInterfacables : Array<IConsoleInterfacable> = new Array<IConsoleInterfacable>();
        
        for (consoleInterfacable in m_consoleInterfacables)
        {
            var interfacableAlias : String = consoleInterfacable.getObjectAlias();
            var match : Bool = interfacableAlias != partial;
            if (match)   // We really only want partial matches.  
            {
                var partialLength : Int = partial.length;
                for (i in 0...partialLength){
                    if (partial.charAt(i) != interfacableAlias.charAt(i)) 
                    {
                        match = false;
                        break;
                    }
                }
                
                if (match) 
                {
                    matchingInterfacables.push(consoleInterfacable);
                }
            }
        }
        
        return matchingInterfacables;
    }
    
    private function findSupportedMethodsStartingWith(object : IConsoleInterfacable, methodPartial : String) : Array<String>
    {
        var methods : Array<String> = new Array<String>();
        
        if (object != null) 
        {
            var supportedMethods : Array<String> = object.getSupportedMethods();
            
            for (supportedMethod in supportedMethods)
            {
                var match : Bool = supportedMethod != methodPartial;
                if (match)   // We really only want partial matches.  
                {
                    var partialLength : Int = methodPartial.length;
                    for (i in 0...partialLength){
                        if (methodPartial.charAt(i) != supportedMethod.charAt(i)) 
                        {
                            match = false;
                            break;
                        }
                    }
                    
                    if (match) 
                    {
                        methods.push(supportedMethod);
                    }
                }
            }
        }
        
        return methods;
    }
    
    private function onDynamicInvoke(e : DynamicInvokeEvent) : Void
    {
        var methodExpression : MethodExpression = e.methodExpression;
        if (methodExpression.wellFormed) 
        {
            var objectAlias : String = methodExpression.objectAlias;
            
            m_historyWindow.pushMethodExpression(methodExpression);
            
            for (consoleInterfacable in m_consoleInterfacables)
            {
                if (consoleInterfacable.getObjectAlias() == objectAlias) 
                {
                    try
                    {
                        consoleInterfacable.invoke(methodExpression);
                    }                    catch (error : Error)
                    {
                        m_historyWindow.pushLine(Std.string(error), HistoryWindow.ERROR_FORMAT);
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
    
    private function repaint() : Void
    {
        m_historyWindow.repaint();
        m_inputWindow.repaint();
        
        m_inputWindow.y = m_historyWindow.height;
        
        width = Starling.current.stage.stageWidth;
        height = m_historyWindow.height + m_inputWindow.height;
    }
    private static var init = {
        HELP_FORMAT.color = 0xffee88;
        HELP_FORMAT.size = 14;
        HELP_FORMAT.align = TextFormatAlign.LEFT;
    }

}
