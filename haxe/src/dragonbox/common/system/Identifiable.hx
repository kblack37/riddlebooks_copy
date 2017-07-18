package dragonbox.common.system;

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
	
	public function get_id()
	{
		return this.id;
	}
	
	public function set_id(id)
	{
		return this.id = id;
	}
}