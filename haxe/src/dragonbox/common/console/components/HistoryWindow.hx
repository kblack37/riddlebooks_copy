package dragonbox.common.console.components;


import dragonbox.common.console.expression.MethodExpression;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

import openfl.display.Sprite;

class HistoryWindow extends Sprite
{
    public static var UNKNOWN_FORMAT : TextFormat = new TextFormat("Kalinga");
    
    
    
    
    public static var ERROR_FORMAT : TextFormat = new TextFormat("Kalinga");
    
    
    
    
    private var m_historyView : TextField;
    
    private var m_historyBufferSize : Int;
    private var m_historyLines : Array<String>;
    private var m_historyLineFormats : Array<TextFormat>;
    
    public function new(historyBufferSize : Int = 100)
    {
        super();
        m_historyView = new TextField();
		m_historyView.width = 0;
		m_historyView.height = 0;
		m_historyView.text = "";
        m_historyView.selectable = true;
        m_historyView.wordWrap = false;
        
        addChild(m_historyView);
        
        m_historyBufferSize = historyBufferSize;
        m_historyLines = new Array<String>();
        m_historyLineFormats = new Array<TextFormat>();
    }
    
    public function pushLine(line : String, format : TextFormat) : Void
    {
        var lineCount : Int = m_historyLines.push(line);
        m_historyLineFormats.push(format);
        
        if (lineCount > m_historyBufferSize) 
        {
            m_historyLines.splice(0, 1);
            m_historyLineFormats.splice(0, 1);
        }
        
        repaint();
    }
    
    public function pushMethodExpression(methodExpression : MethodExpression) : Void
    {
        pushLine(methodExpression.statement, UNKNOWN_FORMAT);
    }
    
    public function repaint() : Void
    {
        m_historyView.width = stage.stageWidth;
        m_historyView.height = stage.stageHeight / 3;
		
		m_historyView.border = true;
		m_historyView.borderColor = 0x444444;
        
        var historyString : String = "";
        for (historyLine in m_historyLines)
        {
            historyString += historyLine + "\n";
        }
        
		// TODO: not sure if this was a correct conversion
		//historyString = historyString.split(m_historyLines.length - 1)[0];
        historyString = historyString.split("\n")[m_historyLines.length - 2];
        
        m_historyView.text = historyString;
        
        var characterOffset : Int = 0;
        var numLines : Int = m_historyLines.length;
        for (i in 0...numLines){
            var line : String = m_historyLines[i];
            var lineLength : Int = line.length;
            if (i + 1 < numLines) 
            {
                lineLength++;
            }
            var format : TextFormat = m_historyLineFormats[i];
            
            // TODO: This crashes
            //m_historyView.setTextFormat(format, characterOffset, characterOffset + lineLength);
            characterOffset += lineLength;
        }
        
        if (m_historyView.height > stage.stageHeight / 3) 
        {
            m_historyView.height = m_historyView.height + 2;
            m_historyView.y = -(m_historyView.height - stage.stageHeight / 3);
        }
    }
    private static var init = {
        UNKNOWN_FORMAT.color = 0xffffff;
        UNKNOWN_FORMAT.size = 14;
        UNKNOWN_FORMAT.align = TextFormatAlign.LEFT;
        ERROR_FORMAT.color = 0xffaaaa;
        ERROR_FORMAT.size = 14;
        ERROR_FORMAT.align = TextFormatAlign.LEFT;
    }

}
