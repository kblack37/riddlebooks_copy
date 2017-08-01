package dragonbox.common.console.components;


import dragonbox.common.console.expression.DynamicInvokeEvent;
import dragonbox.common.console.expression.MethodExpression;

import flash.display.MovieClip;
import flash.events.EventDispatcher;
import flash.events.KeyboardEvent;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.ui.Keyboard;

class InputWindow extends MovieClip
{
    // Constant
    private static var UNKNOWN_FORMAT : TextFormat = new TextFormat("Kalinga");
    
    
    
    
    
    private static var OBJECT_ALIAS : TextFormat = new TextFormat("Kalinga");
    
    
    
    
    private static var METHOD_FORMAT : TextFormat = new TextFormat("Kalinga");
    
    
    
    
    private static var ARGUMENT_FORMAT : TextFormat = new TextFormat("Kalinga");
    
    
    
    
    
    private static var MALFORMED_EXPRESSION : TextFormat = new TextFormat("Kalinga");
    
    
    
    
    
    // View
    private var m_inputField : TextField;
    
    public function new()
    {
        super();
        m_inputField = new TextField();
        m_inputField.wordWrap = false;
        addChild(m_inputField);
    }
    
    public function repaint() : Void
    {
        if (m_inputField.text.length == 0) 
        {
            removeChild(m_inputField);
            m_inputField.text = " ";
            m_inputField.setTextFormat(UNKNOWN_FORMAT);
            m_inputField.height = m_inputField.textHeight + 2;
            m_inputField.text = "";
            addChild(m_inputField);
        }
        else 
        {
            m_inputField.height = m_inputField.textHeight + 2;
        }
        
        m_inputField.width = stage.stageWidth;
        
        this.graphics.clear();
        this.graphics.lineStyle(1, 0xffffff, 0.8);
        this.graphics.beginFill(0x444444, 0.65);
        this.graphics.drawRect(1, 1, m_inputField.width - 2, m_inputField.height - 2);
        this.graphics.endFill();
    }
    
    public function getCurrentExpression() : MethodExpression
    {
        return parseStatement(m_inputField.text);
    }
    
    public function getInputField() : TextField
    {
        return m_inputField;
    }
    
    public function completeStatementPartial(part : String) : Void
    {
        var methodExpression : MethodExpression = parseStatement(m_inputField.text);
        
        if (methodExpression.endAliasIndex == 0) 
        {
            m_inputField.text = part + ".";
        }
        else if (methodExpression.endAliasIndex != 0 && methodExpression.endMethodIndex == 0) 
        {
            m_inputField.text = this.m_inputField.text.split(".")[0] + "." + part + "(";
        }
        
        applySyntaxHilighting();
    }
    
    public function onKeyPress(e : KeyboardEvent) : Void
    {
        var _sw0_ = (e.keyCode);        

        switch (_sw0_)
        {
            case Keyboard.ENTER:
            {
                var statement : String = m_inputField.text;
                
                var methodExpression : MethodExpression = parseStatement(statement);
                
                var dynamicInvokeEvent : DynamicInvokeEvent = new DynamicInvokeEvent(methodExpression);
                dispatchEvent(dynamicInvokeEvent);
                
                m_inputField.text = "";
                m_inputField.setTextFormat(UNKNOWN_FORMAT);
            }
            case Keyboard.BACKSPACE:
            {
                if (m_inputField.text.length > 0) 
                {
                    m_inputField.text = m_inputField.text.substr(0, m_inputField.length - 1);
                }
            }
            default:
                {
                    // Syntax highlighting :)  For each of these strings to recieve valid input
                    m_inputField.appendText(String.fromCharCode(e.charCode));
                }
        }
        
        applySyntaxHilighting();
    }
    
    public function applySyntaxHilighting() : Void
    {
        var methodExpression : MethodExpression = parseStatement(m_inputField.text);
        if (methodExpression.wellFormed) 
        {
            m_inputField.setTextFormat(UNKNOWN_FORMAT);
            if (methodExpression.objectAlias.length > 0) 
            {
                m_inputField.setTextFormat(OBJECT_ALIAS, methodExpression.startAliasIndex, methodExpression.endAliasIndex);
                if (methodExpression.methodAlias.length > 0) 
                {
                    m_inputField.setTextFormat(METHOD_FORMAT, methodExpression.startMethodIndex, methodExpression.endMethodIndex);
                    var numArguments : Int = methodExpression.arguments.length;
                    for (i in 0...numArguments){
                        var argumentStartIndex : Int = methodExpression.startArgumentIndices[i];
                        var argumentEndIndex : Int = methodExpression.endArgumentIndices[i];
                        m_inputField.setTextFormat(ARGUMENT_FORMAT, argumentStartIndex, argumentEndIndex);
                    }
                }
            }
        }
        else 
        {
            m_inputField.setTextFormat(MALFORMED_EXPRESSION, 0, m_inputField.text.length);
        }
    }
    
    // Note: We may want to eventually generalize 'Expression' to an abc or interface.
    private function parseStatement(statementString : String) : MethodExpression
    {
        var wellFormed : Bool = true;
        
        var startObjectIndex : Int = 0;
        var methodObject : String = "";
        var endObjectIndex : Int = 0;
        
        var startMethodIndex : Int = 0;
        var methodName : String = "";
        var endMethodIndex : Int = 0;
        
        var startArgumentsIndices : Array<Int> = new Array<Int>();
        var arguments : Array<String> = new Array<String>();
        var endArgumentsIndices : Array<Int> = new Array<Int>();
        
        // This is the current part of an expression that is being parsed at any given time.
        var startExpressionIndex : Int = 0;
        var expression : String = "";
        
        var statementLength : Int = statementString.length;
        for (i in 0...statementLength){
            var token : String = statementString.charAt(i);
            switch (token)
            {
                case ".":
                {
                    if (endObjectIndex == 0) 
                    {
                        startObjectIndex = startExpressionIndex;
                        methodObject = expression;
                        endObjectIndex = i;
                        
                        expression = "";
                        startExpressionIndex = i;
                    }
                    else 
                    {
                        wellFormed = false;
                    }
                }
                case "(":
                {
                    if (endMethodIndex == 0) 
                    {
                        startMethodIndex = startExpressionIndex;
                        methodName = expression;
                        endMethodIndex = i;
                        
                        expression = "";
                        startExpressionIndex = i + 1;
                    }
                    else 
                    {
                        wellFormed = false;
                    }
                }
                case ",", ")":
                {
                    startArgumentsIndices.push(startExpressionIndex);
                    arguments.push(expression);
                    endArgumentsIndices.push(i);
                    
                    expression = "";
                    startExpressionIndex = i + 1;  // skip the comma  
                    break;
                }
                default:
                    {
                        expression += token;
                        break;
                    }
            }
            
            if (!wellFormed) 
            {
                break;
            }
        }
        
        return new MethodExpression(statementString, wellFormed, 
        startObjectIndex, methodObject, endObjectIndex, 
        startMethodIndex, methodName, endMethodIndex, 
        startArgumentsIndices, arguments, endArgumentsIndices);
    }
    private static var init = {
        UNKNOWN_FORMAT.color = 0xffffff;
        UNKNOWN_FORMAT.size = 14;
        UNKNOWN_FORMAT.align = TextFormatAlign.LEFT;
        UNKNOWN_FORMAT.italic = false;
        UNKNOWN_FORMAT.bold = false;
        OBJECT_ALIAS.color = 0xaaaaff;
        OBJECT_ALIAS.size = 14;
        OBJECT_ALIAS.align = TextFormatAlign.LEFT;
        OBJECT_ALIAS.bold = true;
        METHOD_FORMAT.color = 0xaaffaa;
        METHOD_FORMAT.size = 14;
        METHOD_FORMAT.align = TextFormatAlign.LEFT;
        METHOD_FORMAT.bold = true;
        ARGUMENT_FORMAT.color = 0xffffaa;
        ARGUMENT_FORMAT.size = 14;
        ARGUMENT_FORMAT.align = TextFormatAlign.LEFT;
        ARGUMENT_FORMAT.bold = true;
        ARGUMENT_FORMAT.italic = true;
        MALFORMED_EXPRESSION.color = 0xffaaaa;
        MALFORMED_EXPRESSION.size = 14;
        MALFORMED_EXPRESSION.align = TextFormatAlign.LEFT;
        MALFORMED_EXPRESSION.italic = true;
    }

}
