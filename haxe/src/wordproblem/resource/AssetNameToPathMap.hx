package wordproblem.resource;

/**
 * A simple, albeit long map for the asset manager that allows
 * its clients to use a short name in place of the full asset path
 * @author kristen autumn blackburn
 */
class AssetNameToPathMap {

	/**
	 * The asset path where the initialization data lies
	 */
	private inline static var INITIALIZE_DATA_PATH : String = "";
	
	/**
	 * The backing map structure
	 */
	private var m_nameToPathMap : Map<String, String>;
	
	public function new() {
		initializeMap(INITIALIZE_DATA_PATH);
	}
	
	/**
	 * Resets the map if already initialized and initializes
	 * the map from the data in the given asset path. Exposed
	 * in case it's desired to initialize the map with separate data
	 */
	public var initializeMap(sourcePath : String) {
		
	}
}