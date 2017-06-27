package dragonbox.common.console
{
	import dragonbox.common.dispose.IDisposable;

	public interface IConsole extends IDisposable
	{
		function registerConsoleInterfacable(consoleInterfacable:IConsoleInterfacable):void;
	}
}