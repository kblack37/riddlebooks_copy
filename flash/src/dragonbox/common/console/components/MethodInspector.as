package dragonbox.common.console.components
{
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;

	public class MethodInspector extends MovieClip
	{
		public static const MAX_WIDTH:int = 250;
		
		private static const FORMAT:TextFormat = new TextFormat("Kalinga");
		FORMAT.color = 0xffffff;
		FORMAT.size = 14;
		FORMAT.align = TextFormatAlign.LEFT;
		
		private var m_background:MovieClip;
		private var m_contentLabel:TextField;
		
		public function MethodInspector()
		{
			m_background = new MovieClip();
			
			m_contentLabel = new TextField();
			m_contentLabel.selectable = false;
			m_contentLabel.wordWrap = true;
			m_contentLabel.width = MAX_WIDTH;
			
			addChild(m_background);
			addChild(m_contentLabel);
		}
		
		public function populate(content:String):void
		{
			m_contentLabel.text = content;
			m_contentLabel.setTextFormat(FORMAT);
			m_contentLabel.height = m_contentLabel.textHeight + 5; // Bug: Without the +5, the last line can't be displayed (flash bug?)
			
			m_background.graphics.clear();
			m_background.graphics.beginFill(0x999977, 0.95);
			m_background.graphics.drawRect(-1, -1,  m_contentLabel.width+2,  m_contentLabel.height+2);
			m_background.graphics.endFill();
		}
	}
}