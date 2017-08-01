package wordproblem.hints;

import haxe.Constraints.Function;

import starling.display.DisplayObject;

import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.ScriptStatus;

/**
 * This is the base script class for all runnable hints that are in the game.
 * 
 * All of the possible hints should extend this base script and fill it in with the
 * custom logic needed to get that particular to activate the appropriate parts of the game.
 * 
 * (Should avoid any extra level of inheritance beyond a direct child subclass of this as common code
 * would be better placed in shared modules rather than in parent classes)
 * 
 * IMPORTANT: The visit function of a hinting script should return a success status as long as the hint
 * is still visible and running. It should return a fail once the hint has been dismissed, like the player
 * clicks a close button to get rid of it or another action renders the hint invalid.
 * Once fail is returned the hint is removed by a controller.
 */
class HintScript extends ScriptNode
{
    /**
     * In the hint screen we may not want to show all the hints at once.
     * The unlock flag indicates that the hint has been fetched by the user
     */
    public var unlocked : Bool;
    
    /**
     * For all scripts that do not have an interrupt sequence setup, the a call to interrupt and end this
     * script should immediately tell the next visit call to return false to indicate this script is finished
     * executing.
     * 
     * Any subclass of this that overrides the visit function AND does not provide a way to terminate itself via custom
     * interrupt logic will need to manually read this flag to know when to return failure.
     */
    private var m_defaultInterruptFinishedOnFrame : Bool;
    
    public function new(unlocked : Bool, id : String = null, isActive : Bool = true)
    {
        super(id, isActive);
        
        this.unlocked = unlocked;
        m_defaultInterruptFinishedOnFrame = false;
    }
    
    override public function visit() : Int
    {
        // Execute children scripts
        var i : Int = 0;
        var numChildren : Int = m_children.length;
        for (i in 0...numChildren){
            m_children[i].visit();
        }
        
        var status : Int = ScriptStatus.SUCCESS;
        if (m_defaultInterruptFinishedOnFrame) 
        {
            status = ScriptStatus.FAIL;
            m_defaultInterruptFinishedOnFrame = false;
        }
        
        return status;
    }
    
    /**
     * OVERRIDE
     * Purely for logging purposes, we want some compact representation of the contents of
     * hints that were displayed
     */
    public function getSerializedData() : Dynamic
    {
        return null;
    }
    
    /**
     * OVERRIDE
     * There are some hints where we want an external call to dismiss a hint but the dismissal
     * of the hint to need to run some processes that take multiple frames (most notably
     * this would be a character with the text hint needed to move off the screen)
     * 
     * Calling this function will execute that processes to dismiss and send a signal back when
     * it is completed
     * 
     * @param onInterruptFinished
     *      Callback when the dismiss process as finished and the hint is presumably ready to be removed.
     *      Accepts no parameters.
     */
    public function interruptSmoothly(onInterruptFinished : Function) : Void
    {
        // Default immediately trigger the end.
        if (onInterruptFinished != null) 
        {
            onInterruptFinished();
            m_defaultInterruptFinishedOnFrame = true;
        }
    }
    
    /**
     * OVERRIDE
     * Get back a rendering of the main description of the hint that gets shown in the
     * help screen.
     * 
     * @param width
     *      Maximum width of the display
     * @param height
     *      Maximum height of the display
     */
    public function getDescription(width : Float, height : Float) : DisplayObject
    {
        return null;
    }
    
    /**
     * A script can do any arbitrarily complex rendering for it's description, however
     * this means proper cleanup of the ui is important.
     * 
     * For example the description involved creating new textures, this needs to clean out
     * those textures when the hint is no longer active.
     */
    public function disposeDescription(description : DisplayObject) : Void
    {
    }
    
    /**
     * OVERRIDE
     * The setup function to display the hint within a running level.
     * This should contain all the logic to setup the game so it looks like the
     * hint is running from the start.
     */
    public function show() : Void
    {
    }
    
    /**
     * OVERRIDE
     * The cleanup function to remove the hint within a running level.
     * This should contain all logic to reset the game state before this hint was
     * ever run as well as cleanup resources instantiated
     */
    public function hide() : Void
    {
    }
    
    /**
     * OVERRIDE
     * We may want the player to only be able to unlock a hint after the level has passed a
     * certain state. For simplicity whether a hint is useful is defined in absolute terms, no
     * concept of a hint being more useful than another. Comparison of hint utility can be done
     * just by listing them out else where and picking the first one in a list.
     * 
     * ex.) Suppose we have a hint about equation modeling, we do not want to show it until
     * after the player has successfully built the bar model.
     * 
     * @return
     *      true if the hint is useful to show given the current state and progress of the
     *      level. 
     */
    public function isUsefulForCurrentState() : Bool
    {
        return true;
    }
    
    /**
     * This determines whether the hint does have logic where it can be shown during a level and
     * not just in the hint screen.
     */
    public function canShow() : Bool
    {
        return true;
    }
}
