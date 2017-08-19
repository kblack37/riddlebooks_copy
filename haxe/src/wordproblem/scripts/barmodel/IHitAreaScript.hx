package wordproblem.scripts.barmodel;


import openfl.geom.Rectangle;

import openfl.display.DisplayObjectContainer;

/**
 * All scripts that require using hit areas in the bar model construction area should implement
 * these functions. This allows for common code to render the hit areas when appropriate.
 */
interface IHitAreaScript
{

    /**
     * Get list of active hit areas that are possible for a gesture
     */
    function getActiveHitAreas() : Array<Rectangle>;
    
    /**
     * Get back whether the hit areas should be shown in a given frame
     */
    function getShowHitAreasForFrame() : Bool;
    
    /**
     * Sometimes a script will want to apply some extra visual effects to a hit area
     * In particular we want to add an image of the operator on top.
     * This function is called after the graphic for the hit area is created and placed and allows
     * for individual script to paste extra things on top.
     */
    function postProcessHitAreas(hitAreas : Array<Rectangle>, hitAreaGraphics : Array<DisplayObjectContainer>) : Void;
}
