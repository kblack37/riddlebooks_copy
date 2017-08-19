package wordproblem.engine.events;

import openfl.events.Event;

/**
 * A simple extension of openfl events that allows dispatched
 * events to send data along with them
 * @author kristen autumn blackburn
 */
class DataEvent extends Event {

	/**
	 * Any data the event might need to send
	 */
	private var data : Dynamic;
	
	public function new(type:String, data:Dynamic, bubbles:Bool=false, cancelable:Bool=false) {
		super(type, bubbles, cancelable);
		this.data = data;
	}
	
	public function getData() : Dynamic {
		return data;
	}
	
}