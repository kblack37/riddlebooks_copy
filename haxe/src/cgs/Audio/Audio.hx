package cgs.audio;

import flash.events.Event;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.media.SoundMixer;
import flash.media.SoundTransform;
import flash.net.URLRequest;

/**
	 * Properties and functions for game music and sound effects
	 * 
	 * @author Gordon, Tamir, Rich
	**/
class Audio
{
    public static var instance(get, never) : Audio;
    public var isMuffled(get, set) : Bool;
    public var globalVolume(get, set) : Float;
    public var musicOn(get, set) : Bool;
    public var sfxOn(get, set) : Bool;

    // Background audio
    private var _backgroundChannel : SoundChannel;
    private var _backgroundTransform : SoundTransform;
    private var _currentBackgroundType : MusicType;
    
    // Instance
    private static var _instance : Audio;
    
    // Music
    private var _musicChannel : SoundChannel;
    private var _musicTransform : SoundTransform;
    /** Current set of music sounds being played or paused at the moment */
    private var _currentMusicType : MusicType;
    
    // Stoppable sfx
    private var _lastStoppable : Int;
    private var _stoppableChannel : SoundChannel;
    
    // Variables
    private var _isMuffled : Bool;
    
    private var _musicOn : Bool = true;
    private var _musicTypes : MusicTypes;
    private var _musicStateCallback : Dynamic;
    
    private var _sfxOn : Bool = true;
    private var _loopedSfx : Array<Dynamic>;
    private var _sfxStateCallback : Dynamic;
    
    public function new()
    {
        _isMuffled = false;
        _lastStoppable = -1;
        
        _musicTypes = new MusicTypes();
        _loopedSfx = new Array<Dynamic>();
        _musicTransform = new SoundTransform();
        _backgroundTransform = new SoundTransform();
    }
    
    /*
		 *========================================================================================================
		 *
		 * Initialization
		 *
		 *========================================================================================================
		**/
    
    /**
		 * Initializes the Audio Engine by loading in the data from the given xmls. Requests Sound data from
		 * the given IAudioResource for data that is not streamed.
		**/
    public function init(xmls : Array<FastXML>, res : IAudioResource) : Void
    {
        reset();
        for (i in 0...xmls.length)
        {
            var xml : FastXML = xmls[i];
            loadMusicTypesFromXml(xml, res);
        }
    }
    
    /**
		 * Resets the Audio Engine, clearing out any presently running sounds.
		 * Stops the sound effects, music, and background.
		**/
    public function reset() : Void
    {
        for (i in 0..._loopedSfx.length)
        {
            cast((_loopedSfx[i][1]), SoundChannel).stop();
        }
        
        _loopedSfx = [];
        
        if (_musicChannel != null)
        {
            _musicChannel.stop();
            _musicChannel.removeEventListener(Event.SOUND_COMPLETE, musicComplete);
        }
        
        if (_backgroundChannel != null)
        {
            _backgroundChannel.stop();
            _backgroundChannel.removeEventListener(Event.SOUND_COMPLETE, backgroundComplete);
        }
        
        _currentBackgroundType = null;
        _currentMusicType = null;
    }
    
    /*
		 *========================================================================================================
		 *
		 * State
		 *
		 *========================================================================================================
		**/
    
    /**
		 * Returns the instance of this audio driver.
		**/
    private static function get_instance() : Audio
    {
        if (_instance == null)
        {
            _instance = new Audio();
        }
        return _instance;
    }
    
    /**
		 * Returns whether or not sounds of the game are muffled.
		**/
    private function get_isMuffled() : Bool
    {
        return _isMuffled;
    }
    
    /**
		 * Sets whether or not sounds of the game are muffled.
		**/
    private function set_isMuffled(value : Bool) : Bool
    {
        _isMuffled = value;
        return value;
    }
    
    /**
		 * Returns the global volume level of the game.
		**/
    private function get_globalVolume() : Float
    {
        return SoundMixer.soundTransform.volume;
    }
    
    /**
		 * Sets the global volume level of the game.
		**/
    private function set_globalVolume(volume : Float) : Float
    {
        var transform : SoundTransform = new SoundTransform();
        transform.volume = volume;
        SoundMixer.soundTransform = transform;
        return volume;
    }
    
    /**
		 * Set function to be called when music state changes.
		**/
    public function setMusicStateCallback(callback : Dynamic) : Void
    {
        _musicStateCallback = callback;
    }
    
    /**
		 * Returns whether or not music of the game is playing.
		**/
    private function get_musicOn() : Bool
    {
        return _musicOn;
    }
    
    /**
		 * Sets whether or not music of the game is playing.
		**/
    private function set_musicOn(value : Bool) : Bool
    {
        if (_musicOn != value)
        {
            _musicOn = value;
            if (_musicOn)
            {
                playRandomMusicLoop();
            }
            else
            {
                if (_musicChannel != null)
                {
                    _musicChannel.stop();
                }
                if (_backgroundChannel != null)
                {
                    _backgroundChannel.stop();
                }
            }
            if (_musicStateCallback != null)
            {
                _musicStateCallback(_musicOn);
            }
        }
        return value;
    }
    
    /**
		 * Set function to be called when sfx state changes.
		**/
    public function setSfxStateCallback(callback : Dynamic) : Void
    {
        _sfxStateCallback = callback;
    }
    
    /**
		 * Returns whether or not sounds of the game are playing.
		**/
    private function get_sfxOn() : Bool
    {
        return _sfxOn;
    }
    
    /**
		 * Sets whether or not sounds of the game are playing.
		**/
    private function set_sfxOn(value : Bool) : Bool
    {
        if (_sfxOn != value)
        {
            _sfxOn = value;
            if (!_sfxOn)
            {
                for (i in 0..._loopedSfx.length)
                {
                    cast((_loopedSfx[i][1]), SoundChannel).stop();
                }
                
                _loopedSfx = [];
            }
            if (_sfxStateCallback != null)
            {
                _sfxStateCallback(_sfxOn);
            }
        }
        return value;
    }
    
    /*
		 *========================================================================================================
		 *
		 * Helper Functions
		 *
		 *========================================================================================================
		**/
    
    /**
		 * Returns the specified music type.
		**/
    private function findMusicType(musicType : String) : MusicType
    {
        for (mt/* AS3HX WARNING could not determine type for var: mt exp: EField(EIdent(_musicTypes),types) type: null */ in _musicTypes.types)
        {
            if (mt.type == musicType)
            {
                return mt;
            }
        }
        return null;
    }
    
    /*
		 *========================================================================================================
		 *
		 * Loading Sounds and Music
		 *
		 *========================================================================================================
		**/
    
    /**
		 * Loads the music types from the given XML and loads their sound resources through the provided IAudioResource.
		**/
    private function loadMusicTypesFromXml(xml : FastXML, res : IAudioResource) : Void
    {
        var swfName : String = xml.node.attribute.innerData("swfName");
        var usePanning : Bool = xml.node.attribute.innerData("usePanning") == "true";
        _musicTypes.usePanning = usePanning;
        
        // Cycle through all the types
        var types : FastXMLList = xml.node.child.innerData("type");
        for (type in types)
        {
            var musicType : MusicType = new MusicType();
            
            // A music type
            musicType.type = type.node.attribute.innerData("name");
            musicType.volume = as3hx.Compat.parseFloat(type.node.attribute.innerData("volume"));
            musicType.previewMuffle = type.node.attribute.innerData("previewMuffle") == "true";
            musicType.symbols = new Array<Dynamic>();
            
            // Load the sound resources for this music type
            var sounds : FastXMLList = type.node.child.innerData("sound");
            for (sound in sounds)
            {
                var soundName : String = sound.node.attribute.innerData("name");
                var url : String = sound.node.attribute.innerData("url");
                var loadAtStart : Bool = sound.node.attribute.innerData("loadAtStart") == "true";
                if (soundName != null)
                {
                    // Get the sound resource through the provided IAudioResource
                    if (url == "")
                    {
                        var soundRes : Sound = res.getSoundResource(soundName);
                    }
                    else
                    {
                        // Load the sound from a URL immediatelyif (loadAtStart)
                        {
                            soundRes = new Sound();
                            soundRes.load(new URLRequest(url + soundName));
                        }
                        else
                        {
                            // Load the sound from a URL, but do it later
                            {
                                soundRes = null;
                            }
                        }
                    }
                    
                    musicType.symbols.push(soundName);
                    musicType.sounds.push(soundRes);
                    if (url != "")
                    {
                        musicType.urls.push(url + soundName);
                    }
                    else
                    {
                        // Null url means item was already loaded immediately
                        musicType.urls.push(null);
                    }
                }
                else
                {
                    trace("error, sound with no symbol name");
                }
            }
            
            // Save this new type to all the types we know about
            _musicTypes.types.push(musicType);
        }
    }
    
    /*
		 *========================================================================================================
		 *
		 * Play Background Sounds
		 *
		 *========================================================================================================
		**/
    
    /**
		 * The background sounds have finished playing, so lets play something new!
		**/
    private function backgroundComplete(event : Event) : Void
    {
        playRandomBackgroundLoop();
    }
    
    /**
		 * Begins looping background sounds of the given music type.
		**/
    public function selectBackgroundAudio(musicType : String) : Void
    {
        // Find the background sounds
        _currentBackgroundType = findMusicType(musicType);
        
        // Play the background sounds
        if (_currentBackgroundType != null)
        {
            playRandomBackgroundLoop();
        }
        else
        {
            // No background sounds were found...
            trace("WARNING: Background audio sound not found!");
        }
    }
    
    /**
		 * Plays background sounds from the currently selected background type in a random fashion.
		**/
    private function playRandomBackgroundLoop() : Void
    {
        var loop : Sound;
        
        // Look for some background sounds to play
        if (_currentBackgroundType != null && _currentBackgroundType.sounds.length >= 1)
        {
            // Randomly select between different loops for this background sound
            var randomLoop : Int = as3hx.Compat.parseInt(Math.random() * _currentBackgroundType.symbols.length);
            loop = _currentBackgroundType.sounds[randomLoop];
            
            // Play those background sounds!
            if (musicOn)
            {
                // Stop any playing background sounds
                if (_backgroundChannel != null)
                {
                    _backgroundChannel.stop();
                }
                
                // Update the volume and play the new background sounds
                _backgroundTransform.volume = _currentBackgroundType.volume;
                _backgroundChannel = loop.play(0, 1, _backgroundTransform);
                
                // Setup the loop, in case there is none yet
                if (_backgroundChannel != null)
                {
                    _backgroundChannel.addEventListener(Event.SOUND_COMPLETE, backgroundComplete);
                }
            }
        }
        else
        {
            // No background type is currently selected...
            {
                trace("WARNING: Could not loop background audio");
            }
        }
    }
    
    /*
		 *========================================================================================================
		 *
		 * Play Music
		 *
		 *========================================================================================================
		**/
    
    /**
		 * The music has finished playing, so lets play something new!
		**/
    private function musicComplete(event : Event) : Void
    {
        playRandomMusicLoop();
    }
    
    /**
		 * Begins looping music of the given music type.
		**/
    public function playMusic(musicType : String) : Void
    {
        // Find the music
        _currentMusicType = findMusicType(musicType);
        
        // Play the music
        if (_currentMusicType != null)
        {
            playRandomMusicLoop();
        }
        else
        {
            // No music was found...
            trace("WARNING: Music type " + musicType + " not found!");
        }
    }
    
    /**
		 * Plays music from the currently selected music type in a random fashion.
		**/
    private function playRandomMusicLoop() : Void
    {
        var loop : Sound;
        
        // Look for some music to play
        if (_currentMusicType != null && _currentMusicType.sounds.length >= 1)
        {
            // Randomly select between different loops for this type
            var randomLoop : Int = as3hx.Compat.parseInt(Math.random() * _currentMusicType.symbols.length);
            loop = _currentMusicType.sounds[randomLoop];
            
            // We need to stream the music before playing it
            if (loop == null)
            {
                loop = new Sound();
                loop.load(new URLRequest(_currentMusicType.urls[randomLoop]));
                
                // Save the new sound back to the music type so we dont have to streaming it again later
                _currentMusicType.sounds[randomLoop] = loop;
            }
            
            // Play that music!
            if (musicOn)
            {
                // Stop any playing music
                if (_musicChannel != null)
                {
                    _musicChannel.stop();
                }
                
                // Update the volume and play the new music
                _musicTransform.volume = _currentMusicType.volume;
                _musicChannel = loop.play(0, 1, _musicTransform);
                
                // Setup the loop, in case there is none yet
                if (_musicChannel != null)
                {
                    _musicChannel.addEventListener(Event.SOUND_COMPLETE, musicComplete);
                }
            }
        }
        else
        {
            // No music type is currently selected...
            {
                trace("WARNING: Could not loop music - no music type specified");
            }
        }
    }
    
    /**
		 * Get back the name of the current music type that is playing.
		 * Note that the type is actually the name of a set of sound resources.
		 * Each of those resources has it's own name as well.
		 * 
		 * @return
		 * 		Name of the type of music currently being played. Null if
		**/
    public function getCurrentMusicTypeName() : String
    {
        return ((_currentMusicType != null)) ? _currentMusicType.type : null;
    }
    
    /**
		 * Unload the resources related to a dynamically streamed music type.
		 * Resource needs to be re-streamed the next time.
		 * 
		 * @param musicTypeName
		 * 		The name of the set of music resources that should be unloaded.
		 */
    public function stopAndRemoveStreamedMusic(musicTypeName : String) : Void
    {
        var musicType : MusicType = findMusicType(musicTypeName);
        
        // For this music type, get the sounds in it that were streamed.
        // Can do this by checking which ones have urls
        if (musicType != null)
        {
            // First make sure the sound channel is closed otherwise the sound
            // won't unload
            if (_currentMusicType == musicType && _musicChannel != null)
            {
                _musicChannel.stop();
                _musicChannel = null;
            }
            
            var soundUrls : Array<Dynamic> = musicType.urls;
            var sounds : Array<Dynamic> = musicType.sounds;
            var numSounds : Int = soundUrls.length;
            var i : Int;
            var soundUrl : String;
            for (i in 0...numSounds)
            {
                soundUrl = soundUrls[i];
                
                // Close all the sound objects tied to the type
                if (soundUrl != null)
                {
                    var sound : Sound = sounds[i];
                    sound.close();
                    sounds[i] = null;
                }
            }
        }
    }
    
    /*
		 *========================================================================================================
		 *
		 * Play Sounds
		 *
		 *========================================================================================================
		**/
    
    /**
		 * Plays a sound effect of the specified type.
		**/
    public function playSfx(musicType : String, distFromMid : Float = -1000, loop : Bool = false, loopNum : Int = 99999) : Void
    {
        if (sfxOn)
        {
            // Find the sfx
            var sfxMt : MusicType = findMusicType(musicType);
            
            // Play the sfx!
            if (sfxMt != null)
            {
                var sfxSt : SoundTransform;
                var sfxChannel : SoundChannel;
                
                // Pan the sound if required and specified
                if (_musicTypes.usePanning && distFromMid >= -1 && distFromMid <= 1)
                {
                    sfxSt = new SoundTransform(sfxMt.volume, distFromMid);
                }
                else
                {
                    sfxSt = new SoundTransform(sfxMt.volume);
                }
                
                // Pick a sound to play
                var sfxSound : Sound;
                if (sfxMt.sounds.length == 1)
                {
                    // Only one option, lets choose it!
                    sfxSound = sfxMt.sounds[0];
                }
                else
                {
                    if (sfxMt.sounds.length > 1)
                    {
                        // Many options! Randomly select between different sfx for this type
                        var randomLoop : Int = as3hx.Compat.parseInt(Math.random() * sfxMt.symbols.length);
                        sfxSound = sfxMt.sounds[randomLoop];
                    }
                }
                
                //	Now play the sound, either looped or not
                if (sfxSound != null)
                {
                    //Determine if we need to muffle the sound
                    if (_isMuffled && sfxMt.previewMuffle)
                    {
                        sfxSt.volume *= 0.1;
                    }
                    
                    // Loop
                    if (loop)
                    {
                        sfxChannel = sfxSound.play(0, loopNum, sfxSt);
                        
                        if (sfxChannel != null)
                        {
                            _loopedSfx.push([sfxMt.type, sfxChannel]);
                        }
                    }
                    else
                    {
                        // No loop
                        {
                            sfxChannel = sfxSound.play(0, 1, sfxSt);
                        }
                    }
                }
                else
                {
                    // No sfx to play....
                    {
                        trace("WARNING: no sfx for " + musicType + "!");
                    }
                }
            }
            else
            {
                // No sfx was found...
                {
                    trace("WARNING: sfx " + musicType + " not found!");
                }
            }
        }
    }
    
    /**
		 * Stops the looped sound effect of the specified type, if it exists.
		**/
    public function stopSfx(type : String) : Void
    {
        var sfxChannel : SoundChannel;
        var found : Bool = false;
        
        // Look though the looped sounds for the one we want to kill
        for (i in 0..._loopedSfx.length)
        {
            // Found it!
            if (_loopedSfx[i][0] == type)
            {
                sfxChannel = _loopedSfx[i][1];
                
                // Turn it off
                if (sfxChannel != null)
                {
                    sfxChannel.stop();
                }
                
                // Remove it from the list of looped sounds
                _loopedSfx.splice(i, 1);
                
                found = true;
                break;
            }
        }
        
        // No sfx was found with the specified type...
        if (!found)
        {
            trace("WARNING: can't stop sfx " + type + " - not found!");
        }
    }
    
    /*
		 *========================================================================================================
		 *
		 * Play Stoppable Sounds
		 *
		 *========================================================================================================
		**/
    
    /**
		 * Plays a stoppable sound effect of the specified type.
		**/
    public function playStoppableSound(musicType : String) : Void
    {
        if (sfxOn)
        {
            //Find the sfx
            var sfxMt : MusicType = findMusicType(musicType);
            
            // Play the sfx!
            if (sfxMt != null)
            {
                var sfxSt : SoundTransform = new SoundTransform(sfxMt.volume);
                
                // Pick a sound to play
                var sfxSound : Sound;
                if (sfxMt.sounds.length == 1)
                {
                    // Only one option, lets choose it!
                    sfxSound = sfxMt.sounds[0];
                    _lastStoppable = -1;
                }
                else
                {
                    if (sfxMt.sounds.length > 1)
                    {
                        // Many options! Randomly select between different sfx for this type
                        var randomLoop : Int;
                        do
                        {
                            randomLoop = as3hx.Compat.parseInt(Math.random() * sfxMt.symbols.length);
                        }
                        while ((randomLoop == _lastStoppable)  // Remember what we choose so we don't choose it twice in a row  );
                        
                        
                        
                        _lastStoppable = randomLoop;
                        
                        sfxSound = sfxMt.sounds[randomLoop];
                    }
                }
                
                // Play the sound
                if (sfxSound != null)
                {
                    stopStoppableChannel();
                    
                    _stoppableChannel = sfxSound.play(0, 1, sfxSt);
                }
                else
                {
                    // No sfx to play...
                    {
                        trace("WARNING: no stoppable sfx for " + musicType + "!");
                    }
                }
            }
            else
            {
                // No sfx was found...
                {
                    trace("WARNING: stoppable sfx " + musicType + "  not found!");
                }
            }
        }
    }
    
    /**
		 * Stops the stoppable sfx channel if it is playing.
		**/
    public function stopStoppableChannel() : Void
    {
        if (_stoppableChannel != null)
        {
            _stoppableChannel.stop();
        }
    }
}
