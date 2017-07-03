package utils.system;

/**
 * ...
 * @author Roy
 */
class Identifiable 
{
	@:isVar private var id(get, set):Int;
	
	public function new(id:Int) 
	{
		this.id = id;
	}
	
	function get_id()
	{
		return this.id;
	}
	
	function set_id(id)
	{
		return this.id = id;
	}
}