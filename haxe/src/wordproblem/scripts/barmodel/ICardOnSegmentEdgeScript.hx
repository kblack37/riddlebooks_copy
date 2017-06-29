package wordproblem.scripts.barmodel;


import starling.display.DisplayObject;

interface ICardOnSegmentEdgeScript
{

    function canPerformAction(draggedWidget : DisplayObject, barWholeId : String) : Bool;
    function performAction(draggedWidget : DisplayObject, extraParams : Dynamic, barWholeId : String) : Void;
    function hidePreview() : Void;
    function showPreview(draggedWidget : DisplayObject, extraParams : Dynamic, barWholeId : String) : Void;
}
