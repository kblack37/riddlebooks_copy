package wordproblem.audio;


import flash.text.TextFormat;
import wordproblem.engine.events.DataEvent;

import cgs.audio.Audio;
import cgs.internationalization.StringTable;

import wordproblem.log.AlgebraAdventureLoggingConstants;
import wordproblem.resource.AssetManager;

class SfxToggleButton extends AudioButton
{
    public function new(width : Float,
            height : Float,
            textFormatUp : TextFormat,
            textFormatHover : TextFormat,
            assetManager : AssetManager,
            color : Int)
    {
		// TODO: uncomment once cgs library is fixed
        super(width, height, textFormatUp, textFormatHover, assetManager, /*StringTable.lookup("sfx") + ":"*/ "", color);
        
        // Adjust sfx based on the saved value
        if (Reflect.hasField(m_localSharedObject.data, "sfx")) 
        {
            Audio.instance.sfxOn = m_localSharedObject.data.sfx;
        }
        
        this.redrawLabel(Audio.instance.sfxOn);
    }
    
    override private function handleClick() : Void
    {
        // Toggle whether sfx is on
        var audioDriver : Audio = Audio.instance;
        audioDriver.sfxOn = !audioDriver.sfxOn;
        
        var loggingDetails : Dynamic = {
            buttonName : "SfxButton",
            toggleState : (audioDriver.sfxOn) ? "On" : "Off",

        };
        this.dispatchEvent(new DataEvent(AlgebraAdventureLoggingConstants.BUTTON_PRESSED_EVENT, loggingDetails));
        
        this.redrawLabel(Audio.instance.sfxOn);
        
        // Save value to shared object
        m_localSharedObject.data.sfx = audioDriver.sfxOn;
        m_localSharedObject.flush();
    }
}
