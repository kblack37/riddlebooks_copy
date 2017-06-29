package dragonbox.common.console;

import dragonbox.common.console.IConsoleInterfacable;

import dragonbox.common.dispose.IDisposable;

interface IConsole extends IDisposable
{

    function registerConsoleInterfacable(consoleInterfacable : IConsoleInterfacable) : Void;
}
