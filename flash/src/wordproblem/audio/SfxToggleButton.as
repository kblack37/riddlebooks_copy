package wordproblem.audio
{
    import flash.text.TextFormat;
    
    import cgs.Audio.Audio;
    import cgs.internationalization.StringTable;
    
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.resource.AssetManager;
    
    public class SfxToggleButton extends AudioButton
    {
        public function SfxToggleButton(width:Number, 
                                        height:Number, 
                                        textFormatUp:TextFormat, 
                                        textFormatHover:TextFormat, 
                                        assetManager:AssetManager,
                                        color:uint)
        {
            super(width, height, textFormatUp, textFormatHover, assetManager, StringTable.lookup("sfx") + ":", color);
            
            // Adjust sfx based on the saved value
            if (m_localSharedObject.data.hasOwnProperty("sfx"))
            {
                Audio.instance.sfxOn = m_localSharedObject.data["sfx"];
            }
            
            this.redrawLabel(Audio.instance.sfxOn);
        }
        
        override protected function handleClick():void
        {
            // Toggle whether sfx is on
            var audioDriver:Audio = Audio.instance;
            audioDriver.sfxOn = !audioDriver.sfxOn;
            
            var loggingDetails:Object = {buttonName:"SfxButton", toggleState:audioDriver.sfxOn ? "On" : "Off"}            
            this.dispatchEventWith(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, false, loggingDetails);

            this.redrawLabel(Audio.instance.sfxOn);
            
            // Save value to shared object
            m_localSharedObject.data["sfx"] = audioDriver.sfxOn;
            m_localSharedObject.flush();
        }
    }
}