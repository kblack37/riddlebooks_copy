package dragonbox.common.command
{
	public interface ICommandProvider
	{
		/**
		 * Add a command to be performed on a next update.
		 * 
		 * @param command
		 */
		function issueCommand(command:Command):void;
		
		/**
		 * Get a list of commands to execute of the next update. The list should
		 * be ordered chronologically based on when the commands were issued.
		 */
		function getFrameCommands():Vector.<Command>;
		
		/**
		 * Clean up all commands in the command buffer.
		 * This should be called once all commands in an update frame are executed
		 * in order to prevent them from being incorrectly executed repeated times. 
		 */
		function clearFrameCommands():void;
	}
}