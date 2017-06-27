package wordproblem.audio
{
    import flash.text.TextFormat;
    
    import cgs.Audio.Audio;
    import cgs.internationalization.StringTable;
    
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.resource.AssetManager;
    
    public class MusicToggleButton extends AudioButton
    {
        public function MusicToggleButton(width:Number, 
                                          height:Number, 
                                          textFormatUp:TextFormat, 
                                          textFormatHover:TextFormat, 
                                          assetManager:AssetManager,
                                          color:uint)
        {
            super(width, height, textFormatUp, textFormatHover, assetManager, StringTable.lookup("music") + ":", color);
            
            // Adjust music based on the saved value
            if (m_localSharedObject.data.hasOwnProperty("music"))
            {
                Audio.instance.musicOn = m_localSharedObject.data["music"];
            }
            
            this.redrawLabel(Audio.instance.musicOn);
        }
        
        override protected function handleClick():void
        {
            // Toggle whether music is on
            var audioDriver:Audio = Audio.instance;
            audioDriver.musicOn = !audioDriver.musicOn;
            
            var loggingDetails:Object = {buttonName:"MusicButton", toggleState:audioDriver.musicOn ? "On" : "Off"}            
            this.dispatchEventWith(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, false, loggingDetails);
            
            this.redrawLabel(Audio.instance.musicOn);
            
            // Save value to shared object
            m_localSharedObject.data["music"] = audioDriver.musicOn;
            m_localSharedObject.flush();
        }
    }
}