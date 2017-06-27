package wordproblem.scripts.barmodel
{
    import starling.display.DisplayObject;

    /**
     * All scripts that remove elements must implement this.
     * This is to allow the hold to copy script to manually apply remove actions
     * at any given instant without having to run visit
     */
    public interface IRemoveBarElement
    {
        /**
         * Normal usage is to directly call this to immediately trigger a delete that
         * includes all the necessary animations
         * 
         * @param element
         *      The view element in the current bar model area that should be removed
         * @return
         *      True if the passed in element can be removed
         */
        function removeElement(element:DisplayObject):Boolean;
    }
}