package dragonbox.common.time
{
	public interface ITime
	{
		function update():void;
		function frameDeltaMs():Number;
		function frameDeltaSecs():Number;
	}
}