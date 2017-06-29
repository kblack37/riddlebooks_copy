package wordproblem.engine.widget;


import dragonbox.common.dispose.IDisposable;

import wordproblem.engine.component.ComponentManager;

/**
 * This interface allows for the game to add and apply dynamic properties
 * with new components.
 */
interface IBaseWidget extends IDisposable
{
    
    var componentManager(get, never) : ComponentManager;

}
