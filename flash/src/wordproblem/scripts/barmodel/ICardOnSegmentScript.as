package wordproblem.scripts.barmodel
{
    /**
     * The interface describes scripts that involve the user dragging a card ontop
     * of a segment to perform some action.
     * 
     * This is needed to implement the radial menu functionality where we have a set of different actions
     * that can be selected when the player releases a card on a segment
     */
    public interface ICardOnSegmentScript
    {
        /**
         * Check whether this given script can perform any action using a
         * given card and segment combo
         * 
         * @param cardValue
         *      The expression on the card that was dropped
         * @param segmentId
         *      Id of the bar segment element to put the card expression value onto
         * @return
         *      True if this script allows the expression to modify the given segment
         */
        function canPerformAction(cardValue:String, segmentId:String):Boolean;
        
        function showPreview(cardValue:String, segmentId:String):void;
        function hidePreview():void;
        
        function performAction(cardValue:String, segmentId:String):void;
        
        /**
         * The name of the action to better inform the user of the change being applied
         */
        function getName():String;
    }
}