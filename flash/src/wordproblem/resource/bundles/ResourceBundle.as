package wordproblem.resource.bundles
{
    /**
     * A bundle is a collection of either statically embedded classes or url locations for resources.
     * Since bundles are compiled into the code they should only incorporate items that are necessary to
     * start the game regardless of level types. For example common images, configuration files, or
     * localization text should be parts of a bundle.
     * 
     * The resource manager is supposed to parse out the contents of the bundles, load them, and place
     * usable assets inside out.
     * 
     * (All subclasses of this should be part of the gameconfig package)
     */
    public class ResourceBundle
    {
        // IMPORTANT: When embedding text files, make sure you set the correct mime-type
        
        /**
         * This indicates that all the resources that are part of the bundle can be loaded
         * with the default Starling asset manager. These range from sound, to images, to
         * spritesheet+atlas information. Look here to view types allowed in this bundle:
         * http://doc.starling-framework.org/core/starling/utils/AssetManager.html#enqueue()
         */
        public static const STARLING_ASSET_COMPATIBLE:String = "starling_compatible";
        
        /**
         * This indicates all resources that are part of the bundle are to be loaded dynamically.
         * This bundle should contain a list of urls to load at runtime.
         */
        public static const URL_ASSETS:String = "url_assets";
        
        /**
         * When passing in a class, the starling asset manager can automatically parse out
         * and store the embedded asset tags.
         * 
         * However a bundle can choose to include additional resources such as
         * url strings
         * 
         * Key: Name to apply to a resource
         * Value: The resource itself (includes url strings to a resource)
         */
        protected var m_nameToResourceMap:Object;
        
        public function ResourceBundle()
        {
            m_nameToResourceMap = {};
        }
        
        /**
         * Get an array of either class objects or url strings that are
         * part of the bundle.
         * 
         * @return
         *      If object is empty, no additional resource other than those embedded are needed
         */
        public function getNameToResourceMap():Object
        {
            return m_nameToResourceMap;
        }
    }
}