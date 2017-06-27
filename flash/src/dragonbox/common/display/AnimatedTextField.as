package dragonbox.common.display
{
	import cgs.Audio.Audio;
	
	import dragonbox.common.dispose.IDisposable;
	import dragonbox.common.time.Time;
	
	import flash.text.TextField;
	
	public class AnimatedTextField extends TextField implements IDisposable
	{
		private var m_originalText:String;
		private var m_currentCharacterIndex:int;
		private var m_animationPlaying:Boolean;
		
		private var m_audioDriver:Audio;
        private var m_playAudio:Boolean;
        private var m_audioName:String;
		
		public function AnimatedTextField(playAudio:Boolean,
                                          audioDriver:Audio,
                                          audioName:String)
		{
			m_audioDriver = audioDriver;
            m_playAudio = playAudio;
            m_audioName = audioName;
			m_animationPlaying = false;
            
            this.selectable = false;
            this.embedFonts = true;
			super();
		}
		
		public function play():void
		{
			m_originalText = this.text;
			m_currentCharacterIndex = 0;
			this.text = "";
			m_animationPlaying = true;
			
			if (m_playAudio) 
			{
				m_audioDriver.playSfx(m_audioName, -1000, true);
			}
		}
		
		public function stop():void
		{
			if (m_animationPlaying)
			{
				m_animationPlaying = false;
				if (this.text != m_originalText)
				{
					this.text = m_originalText;
				}
				
				if (m_playAudio) 
				{
					m_audioDriver.stopSfx(m_audioName);
				}
			}
		}
		
		public function update(time:Time):void
		{
			if (m_animationPlaying)
			{
                // Check if we have to play the animation
                // If we do then we grab the next character from the original
                // text and append it to the text displayed on the screen
				if (m_currentCharacterIndex < m_originalText.length)
				{
					this.text += m_originalText.charAt(m_currentCharacterIndex);
					m_currentCharacterIndex++;
				}
				else
				{
					stop();
				}
			}
		}
        
        public function getIsAnimating():Boolean
        {
            return m_animationPlaying;
        }
		
		public function dispose():void
		{
			stop();
		}
	}
}