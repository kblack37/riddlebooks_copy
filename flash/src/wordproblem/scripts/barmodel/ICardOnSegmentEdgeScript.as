package wordproblem.scripts.barmodel
{
    import starling.display.DisplayObject;

    public interface ICardOnSegmentEdgeScript
    {
        function canPerformAction(draggedWidget:DisplayObject, barWholeId:String):Boolean;
        function performAction(draggedWidget:DisplayObject, extraParams:Object, barWholeId:String):void;
        function hidePreview():void;
        function showPreview(draggedWidget:DisplayObject, extraParams:Object, barWholeId:String):void;
    }
}