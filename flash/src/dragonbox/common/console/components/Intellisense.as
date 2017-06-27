package dragonbox.common.console.components
{
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;

	public class Intellisense extends MovieClip
	{
		private static const ITEM:TextFormat = new TextFormat("Kalinga");
		ITEM.color = 0xffffff;
		ITEM.size = 14;
		ITEM.align = TextFormatAlign.LEFT;
		
		private var m_items:Vector.<String>;
		private var m_labels:Vector.<TextField>;
		private var m_selection:int;
		
		private var m_background:MovieClip;
		
		public function Intellisense()
		{
			m_items = new Vector.<String>();
			m_labels = new Vector.<TextField>();
			
			m_background = new MovieClip();
			addChild(m_background);
		}
		
		public function getSelectedText():String
		{
			return m_items[m_selection];
		}
		
		public function populate(items:Vector.<String>):void
		{
			m_items = items;
			m_selection = Math.max(0, Math.min(m_selection, m_items.length-1));
			
			repaint();
		}
		
		public function selectNext():void
		{
			deselect(m_selection);
			m_selection = Math.min(m_selection+1, m_items.length-1);
			select(m_selection);
		}
		
		public function selectPrevious():void
		{
			deselect(m_selection);
			m_selection = Math.max(0, m_selection-1);	
			select(m_selection);
		}
		
		private function deselect(index:int):void
		{
			if(m_labels.length > 0)
			{
				const label:TextField = m_labels[index];
				label.background = false;
			}
		}
		
		private function select(index:int):void
		{
			if(m_labels.length > 0)
			{
				const label:TextField = m_labels[index];
				label.background = true;
				label.backgroundColor = 0x7777dd;
			}
		}
		
		private function repaint():void
		{
			for each(var oldItemLabel:TextField in m_labels)
			{
				removeChild(oldItemLabel);
			}
			m_labels = new Vector.<TextField>();
			
			var backgroundWidth:Number = 0;
			var backgroundHeight:Number = 0;
			
			var y:Number = 0;
			for each(var item:String in m_items)
			{
				const itemLabel:TextField = new TextField();
				itemLabel.selectable = false;
				itemLabel.autoSize = TextFieldAutoSize.LEFT;
				itemLabel.text = item;
				itemLabel.setTextFormat(ITEM);
				itemLabel.y = y;
				
				y += itemLabel.textHeight;
				
				m_labels.push(itemLabel);
				this.addChild(itemLabel);
				
				backgroundHeight += itemLabel.height;
				if(itemLabel.width > backgroundWidth) 
				{
					backgroundWidth = itemLabel.width;
				}
			}
			
			m_background.graphics.clear();
			m_background.graphics.beginFill(0xdddd77, 0.95);
			m_background.graphics.drawRect(0, 0,  backgroundWidth,  backgroundHeight);
			m_background.graphics.endFill();
			
			select(m_selection);
		}
	}
}