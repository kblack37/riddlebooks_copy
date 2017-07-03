package utils.expressiontree;

import openfl.geom.Vector3D;
import utils.math.RealsVectorSpace;

/**
 * A wild card represents a node that at the time is an indeterminate value.
 * 
 * The data value of this node represents the actual value it should eventually take,
 * however it can be set to null if the actual value is unknown.
 * 
 * IMPORTANT: If data of a wild card is null, it means it does match anything in particular.
 * Note that regular wild cards can match to a specific value OR be indeterminate. 
 * For example ?_a would parse out to a wild card that should represent a.
 * @author Roy
 */
class WildCardNode extends ExpressionNode 
{
	/** Match any terminal node */
	public static var TYPE_TERMINAL_ANY:String = "$TA";
	/** Match any terminal node that is a number */
	public static var TYPE_TERMINAL_NUMBER:String = "$TN";
	/** Match any terminal node that is a variable */
	public static var TYPE_TERMINAL_VARIABLE:String = "$TV";
	/** Match any subtree node */
	public static var TYPE_SUBTREE_ANY:String = "$SA";
	
	/** Matches blank slotted wild card nodes, these are the same as found in normal dragonbox */
	public static var TYPE_REGULAR:String = "?";
	
	public static var WILD_CARD_SYMBOLS:Array<String> = new Array<String>(["$", "?"]);
	
	/**
	 * Callback that is repsonsible for creating appropriate wild card nodes when signaled
	 * by the expression compiler.
	 * 
	 */
	public static function createWildCardNode(vectorSpace:RealsVectorSpace, data:String):ExpressionNode
	{
		// Data format for regex dynamic variables is generally <type>_<id>
		// type is required and contains the special prefix character while id can be ignored
		var dataParts:Array<String> = data.split("_", 2);
		var wildCardType:String = dataParts[0];
		var wildCardId:String = null;
		if (dataParts.length == 2)
		{
			var prefixCharacter:String = data.charAt(0);
			if (prefixCharacter == "?")
			{
				data = dataParts[1];
			}
			else if (prefixCharacter == "$")
			{
				wildCardId = dataParts[1];
			}
		}
		else
		{
			// A wild card that is not a placeholder for a particular value has null data
			data = null;
		}
		var wildCardNode:WildCardNode = new WildCardNode(vectorSpace, wildCardType, wildCardId, data);
		return wildCardNode;
	}
	
	/**
	 * Get the priority of a node. Higher priority value means it should be applied
	 * first.
	 * 
	 * @param node
	 *      The node to get the priority of
	 * @return
	 *      Priority of node.
	 */
	public static function getTypePriority(node:ExpressionNode):Int
	{
		var priorityValue:Int = 100;
		
		// FIXME:
		if (Std.instance(node, WildCardNode) != null)//node is WildCardNode)
		{
			var type:String = cast(node, WildCardNode).wildCardType;
			if (type == WildCardNode.TYPE_SUBTREE_ANY)
			{
				priorityValue = 0;
			}
			else if (type == WildCardNode.TYPE_TERMINAL_ANY)
			{
				priorityValue = 1;
			}
			else if (type == WildCardNode.TYPE_TERMINAL_NUMBER || type == WildCardNode.TYPE_TERMINAL_VARIABLE)
			{
				priorityValue = 5;
			}
		}
		
		return priorityValue;
	}
	
	/**
	 * Type value used to attribute general characteristics to this node.
	 * 
	 * For example when using regular expressions we can specify this wildcard type
	 * matches any arbitrary subtree.
	 * 
	 * A value of ? means that it is a regular wild card. 
	 */
	public var wildCardType:String;
	
	/**
	 * Regular expressions require each wild card to be tagged with a known id at
	 * compile time.
	 * 
	 * This was ONLY used for a function to compare expression trees via a regex like syntax.
	 */
	public var wildCardId:String;
	
	public function new(vectorSpace:RealsVectorSpace, 
						wildCardType:String, 
						wildCardId:String,
						data:String=null, 
						id:Int=-1)
	{
		super(vectorSpace, data, id);
		
		this.wildCardType = wildCardType;
		this.wildCardId = wildCardId;
	}
	
	override public function clone():ExpressionNode
	{
		var clone:ExpressionNode = new WildCardNode(
			this.vectorSpace, 
			this.wildCardType, 
			this.wildCardId, 
			this.data, 
			this.id
		);
		clone.wrapInParentheses = this.wrapInParentheses;
		clone.hidden = hidden;
		clone.unit = this.unit;
		clone.position = new Vector3D(this.position.x, this.position.y);
		return clone;
	}
	
	/**
	 * The string value of a wildcard that can be pushed out into a decompiled
	 * expression form.
	 */
	override public function toString():String
	{
		// This function should be the reverse of the createWildCard function,
		// pieces together data parts into a single string that should contain
		// all information that we need to later parse back into a node.
		
		// The $ character in the type indicates its a regex type wildcard
		var contents:String;
		var prefixCharacter:String = wildCardType.charAt(0);
		if (prefixCharacter == "$")
		{
			contents = wildCardType + "_" + wildCardId;
		}
		// The ? character indicates it is a placeholder
		else if (prefixCharacter == "?")
		{
			contents = wildCardType;
			if (data != null)
			{
				contents += "_" + this.data;
			}
		}
		
		return contents;
	}
}