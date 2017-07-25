package cgs.engine.game;


/**
	 * ...
	 * @author Rich
	 */
class CGSPriorityConstants
{
    // Updater priorities
    public static inline var PRIORITY_LOWEST : Int = 0;
    public static var PRIORITY_LOW : Int = as3hx.Compat.INT_MAX / 4;
    public static var PRIORITY_MEDIUM : Int = as3hx.Compat.INT_MAX / 2;
    public static var PRIORITY_HIGH : Int = (as3hx.Compat.INT_MAX / 4) * 3;
    public static var PRIORITY_HIGHEST : Int = as3hx.Compat.INT_MAX - 1;

    public function new()
    {
    }
}

