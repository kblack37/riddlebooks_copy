package wordproblem.audio;


import flash.text.TextFormat;

import cgs.audio.Audio;
import cgs.internationalization.StringTable;

import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;

class MusicToggleButton extends AudioButton
{
    public function new(width : Float,
            height : Float,
            textFormatUp : TextFormat,
            textFormatHover : TextFormat,
            assetManager : AssetManager,
            color : Int)
    {
        super(width, height, textFormatUp, textFormatHover, assetManager, StringTable.lookup("music") + ":", color);
        
        // Adjust music based on the saved value
        if (m_localSharedObject.data.exists("music")) 
        {
            Audio.instance.musicOn = m_localSharedObject.data["music"];
        }
        
        this.redrawLabel(Audio.instance.musicOn);
    }
    
    override private function handleClick() : Void
    {
        // Toggle whether music is on
        var audioDriver : Audio = Audio.instance;
        audioDriver.musicOn = !audioDriver.musicOn;
        
        var loggingDetails : Dynamic = {
            buttonName : "MusicButton",
            toggleState : (audioDriver.musicOn) ? "On" : "Off",

        };
        this.dispatchEventWith(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, false, loggingDetails);
        
        this.redrawLabel(Audio.instance.musicOn);
        
        // Save value to shared object
        m_localSharedObject.data["music"] = audioDriver.musicOn;
        m_localSharedObject.flush();
    }
}
