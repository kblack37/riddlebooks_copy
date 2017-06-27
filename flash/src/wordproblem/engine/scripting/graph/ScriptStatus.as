package wordproblem.engine.scripting.graph
{
	public class ScriptStatus
	{
        /**
         * Status indicating that a script successfully performed an action or has
         * finished executing all its logic
         */
		public static const SUCCESS:int = 1;
        
        /**
         * Status indicating a script is in the middle of performing some action.
         */
		public static const RUNNING:int = 2;
        
        /**
         * Status indicating a script has failed to perform its intended actions.
         */
		public static const FAIL:int = 3;
        
        /**
         * Status indicating some unexpected condition interrupted the logic
         * (This isn't any different than fail really...)
         */
		public static const ERROR:int = 4;
	}
}