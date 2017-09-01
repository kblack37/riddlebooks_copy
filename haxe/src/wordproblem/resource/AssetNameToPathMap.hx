package wordproblem.resource;
import haxe.Json;
import openfl.Assets;

/**
 * A simple, albeit long map for the asset manager that allows
 * its clients to use a short name in place of the full asset path
 * @author kristen autumn blackburn
 */
class AssetNameToPathMap {

	/**
	 * The asset path where the initialization data lies
	 */
	private inline static var INITIALIZE_DATA_PATH : String = "assets/strings/asset_name_paths.txt";
	
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
	public function initializeMap(sourcePath : String) {
		m_nameToPathMap = new Map<String, String>();
		
		var nameToPathJSON = Json.parse(Assets.getText(sourcePath));
		
		for (name in Reflect.fields(nameToPathJSON)) {
			m_nameToPathMap.set(name, Reflect.field(nameToPathJSON, name));
		}
	}

	public function hasPathForName(name : String) : Bool {
		return m_nameToPathMap.exists(name);
	}
	
	/**
	 * Returns the path associated with the given name, or null if none exists
	 */
	public function getPathForName(name : String) : String {
		return m_nameToPathMap.get(name);
	}
}