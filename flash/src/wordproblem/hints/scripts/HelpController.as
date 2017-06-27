package wordproblem.hints.scripts
{
    import cgs.Audio.Audio;
    
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import feathers.controls.Button;
    
    import starling.display.DisplayObject;
    import starling.events.Event;
    import starling.filters.ColorMatrixFilter;
    
    import wordproblem.callouts.TooltipControl;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.hints.HintCommonUtil;
    import wordproblem.hints.HintScript;
    import wordproblem.hints.HintSelectorNode;
    import wordproblem.log.AlgebraAdventureLoggingConstants;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.BaseGameScript;
    
    /**
     * Controls the generic hint visualization and controls within a level.
     * Shows a screen with all available help as well as controlling the hint button.
     * 
     * The control assumes that one hint related script is executing at any given times. If a hint needs
     * many things to happen at once or has complex logic it should be possible to create
     * something like a container script which executes many other threads of logic.
     * 
     * IMPORTANT:
     * All hint scripts passed into this system get disposed on hide, this means it is not
     * possible to re-use those scripts
     */
    public class HelpController extends BaseGameScript
    {
        /**
         * The ui element the player clicks on to open up the help menu
         */
        private var m_getHelpButton:DisplayObject;
        
        /**
         * Assuming we can only run one hint on the screen at a time, keep track of what is running
         * so we can update and dispose of it when necessary.
         * If null, no hint is displayed.
         */
        private var m_currentlyRunningHint:HintScript;
        
        /**
         * The structure of this node subtree will determine what kinds of hints can be generated for
         * a level.
         */
        private var m_rootHintSelectorNode:HintSelectorNode;
        
        /**
         * Logic to control tooltip on the help button
         */
        private var m_tooltipControl:TooltipControl;
        
        /**
         * True if we are in the middle of dismissing the current hint.
         * Flag is useful to prevent situations where we attempt to dismiss the current hint twice,
         * for example while the current hint is in the middle of a smooth dismissal and during that
         * time another dismissal is triggered.
         */
        private var m_smoothInterruptInProgress:Boolean;
        
        private var m_bufferedNextHintScriptToShow:HintScript;
        
        public function HelpController(gameEngine:IGameEngine, 
                                       expressionCompiler:IExpressionTreeCompiler, 
                                       assetManager:AssetManager,
                                       id:String=null, 
                                       isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
        }
        
        public function setRootHintSelectorNode(rootNode:HintSelectorNode):void
        {
            m_rootHintSelectorNode = rootNode;
        }
        
        override public function visit():int
        {
            var status:int = ScriptStatus.SUCCESS;
            if (m_ready && m_isActive)
            {
                status = super.visit();
                
                if (m_rootHintSelectorNode != null)
                {
                    m_rootHintSelectorNode.visit();
                }
                
                if (m_currentlyRunningHint != null)
                {
                    var runningHintStatus:int = m_currentlyRunningHint.visit();
                    
                    // Use convention that once a hint script returns fails, it should be removed immediately.
                    // Animations that smoothly animate it going SHOULD NOT return a fail, only when they are completely finished
                    if (runningHintStatus == ScriptStatus.FAIL)
                    {
                        m_currentlyRunningHint.hide();
                        m_currentlyRunningHint.dispose();
                        m_currentlyRunningHint = null;
                    }
                }
                
                // Start running the buffered hint only if there is no other hint active
                // (i.e. the previous hint has completely finished cleaning itself up)
                if (m_currentlyRunningHint == null && m_bufferedNextHintScriptToShow != null)
                {
                    m_currentlyRunningHint = m_bufferedNextHintScriptToShow;
                    m_currentlyRunningHint.show();
                    m_bufferedNextHintScriptToShow = null;
                }
                
                m_tooltipControl.onEnterFrame();
            }
            return status;
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            // Hide the currently runnining hint, which is to kill it
            if (m_currentlyRunningHint != null)
            {
                m_currentlyRunningHint.hide();
                m_currentlyRunningHint.dispose();
            }
            
            // All available hints must be cleaned up, the better place to put this is the
            // level scripts that create the hints in the first place
            if (m_rootHintSelectorNode != null)
            {
                m_rootHintSelectorNode.dispose();
            }
            
            m_tooltipControl.dispose();
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            if (m_ready)
            {
                if (m_getHelpButton != null)
                {
                    m_gameEngine.removeEventListener(GameEvent.SHOW_HINT, bufferEvent);
                    m_gameEngine.removeEventListener(GameEvent.REMOVE_HINT, bufferEvent);
                    m_getHelpButton.removeEventListener(Event.TRIGGERED, bufferEvent);
                    if (m_getHelpButton is Button)
                    {
                        (m_getHelpButton as Button).isEnabled = value;
                    }
                    if (value)
                    {
                        m_gameEngine.addEventListener(GameEvent.SHOW_HINT, bufferEvent);
                        m_gameEngine.addEventListener(GameEvent.REMOVE_HINT, bufferEvent);
                        m_getHelpButton.addEventListener(Event.TRIGGERED, bufferEvent);
                        m_getHelpButton.filter = null;
                        m_getHelpButton.alpha = 1.0;
                    }
                    else
                    {
                        // Set color to grey scale
                        var colorMatrixFilter:ColorMatrixFilter = new ColorMatrixFilter();
                        colorMatrixFilter.adjustSaturation(-1);
                        m_getHelpButton.filter = colorMatrixFilter;
                        m_getHelpButton.alpha = 0.5;
                    }
                }
            }
        }
        
        override protected function bufferEvent(event:Event, param:Object):void
        {
            var type:String = event.type;
            var smoothlyRemove:Boolean = false;
            if (type == GameEvent.SHOW_HINT)
            {
                if (param.hasOwnProperty("smoothlyRemove"))
                {
                    smoothlyRemove = param.smoothlyRemove;
                }
                manuallyShowHint(param.hint, smoothlyRemove);
            }
            else if (type == GameEvent.REMOVE_HINT)
            {
                // Smoothly delete hint
                if (param.hasOwnProperty("smoothlyRemove"))
                {
                    smoothlyRemove = param.smoothlyRemove;
                }
                manuallyRemoveAllHints(smoothlyRemove);
            }
            else if (type == Event.TRIGGERED)
            {
                if (m_isActive)
                {
                    m_gameEngine.dispatchEventWith(GameEvent.HINT_BUTTON_SELECTED);
                    Audio.instance.playSfx("button_click");
                    m_gameEngine.dispatchEventWith(GameEvent.GET_NEW_HINT);
                }
                
                // The selection of the next hint to show is a simple iteration through the
                // list of hint scripts
                var hintScript:HintScript = m_rootHintSelectorNode.getHint();
                if (hintScript != null)
                {
                    manuallyShowHint(hintScript, true);
                    
                    // Log the hint displayed (figure out what modeling mode that player is in)
                    var hintLoggingType:String = (HintCommonUtil.getLevelStillNeedsBarModelToSolve(m_gameEngine)) ?
                        AlgebraAdventureLoggingConstants.HINT_REQUESTED_BARMODEL : AlgebraAdventureLoggingConstants.HINT_REQUESTED_EQUATION;
                    m_gameEngine.dispatchEventWith(hintLoggingType, false, hintScript.getSerializedData());
                }   
            }
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            // Get the hint button and add the event listener to it
            m_getHelpButton = m_gameEngine.getUiEntity("hintButton");
            
            // Need to reset this to bind the listener
            this.setIsActive(m_isActive);
            
            m_tooltipControl = new TooltipControl(m_gameEngine, "hintButton", "Help");
        }
        
        /**
         * Hack for tutorials to show custom hints, also is a way for
         * hints to force themselves to be shown (for example the hints in which
         * the mistake in the bar model automatically shows up)
         */
        public function manuallyShowHint(hint:HintScript, smoothlyRemoveCurrent:Boolean=false):void
        {
            // Remove the previous hint, check if it should be removed smoothly
            if (m_currentlyRunningHint != null)
            {
                // Note that this callback is triggered on a call to visit, which is performed in this script.
                // WE CANNOT immediately change to the next
                m_bufferedNextHintScriptToShow = hint;
                manuallyRemoveAllHints(smoothlyRemoveCurrent);
            }
            else
            {
                m_currentlyRunningHint = hint;
                m_currentlyRunningHint.show();
            }
        }
        
        /**
         * Hack for tutorials to remove active hints.
         */
        public function manuallyRemoveAllHints(smoothlyRemoveCurrent:Boolean=false, removeBufferedHints:Boolean=false):void
        {
            if (m_currentlyRunningHint != null)
            {
                if (smoothlyRemoveCurrent)
                {
                    m_smoothInterruptInProgress = true;
                    m_currentlyRunningHint.interruptSmoothly(function():void
                    {
                        m_smoothInterruptInProgress = false;
                    });
                }
                else
                {
                    m_currentlyRunningHint.hide();
                    m_currentlyRunningHint.dispose();
                    m_currentlyRunningHint = null;
                }
            }
            
            if (removeBufferedHints && m_bufferedNextHintScriptToShow != null)
            {
                m_bufferedNextHintScriptToShow = null;
            }
        }
        
        /**
         * Hack for tutorials that want to automatically show hints.
         */
        public function getCurrentlyShownHint():HintScript
        {
            return m_currentlyRunningHint;
        }
    }
}