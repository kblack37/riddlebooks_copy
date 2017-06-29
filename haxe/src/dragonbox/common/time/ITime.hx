package dragonbox.common.time;


interface ITime
{

    function update() : Void;
    function frameDeltaMs() : Float;
    function frameDeltaSecs() : Float;
}
