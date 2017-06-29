package wordproblem.items;


import dragonbox.common.expressiontree.compile.LatexCompiler;
import dragonbox.common.math.vectorspace.RealsVectorSpace;

import wordproblem.engine.component.ComponentFactory;
import wordproblem.engine.component.ComponentManager;

/**
 * This is an in memory representation about how every item has been defined.
 * 
 * These properties that are fixed across every instance of an item that has been created.
 * For example all blue fairytale dragon share some common set of attributes which can be accessed in
 * this class.
 * 
 * Note that these 'entities' don't exist as concrete objects in the game world, this is mainly
 * just a map. All the properties that are set here should be fixed for the entire duration of
 * the game.
 */
class ItemDataSource extends ComponentManager
{
    /**
     * @param rawData
     *      An array of json formatted objects describing items
     */
    public function new(rawData : Dynamic)
    {
        super();
        // Define all the attributes possibly contained by an item
        // Each item data has a rigid body component This is hacky, using this to store position in the bookshelf for each item
        super();
        
        var componentFactory : ComponentFactory = new ComponentFactory(new LatexCompiler(new RealsVectorSpace()));
        componentFactory.createAndAddComponentsForItemList(this, rawData);
    }
}
