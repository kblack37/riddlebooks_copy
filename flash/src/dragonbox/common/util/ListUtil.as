package dragonbox.common.util
{
    public class ListUtil
    {
        /**
         * Subdivide a list of ids into smaller lists container at most n elements
         */
        public static function subdivideList(originalList:Vector.<String>, numItemsInGroup:int, outSubdivisionList:Vector.<Vector.<String>>):void
        {
            var i:int;
            var numTotalElements:int = originalList.length;
            var currentSubdivisionList:Vector.<String> = new Vector.<String>();
            for (i = 0; i < numTotalElements; i++)
            {
                if (currentSubdivisionList.length >= numItemsInGroup)
                {
                    outSubdivisionList.push(currentSubdivisionList);
                    currentSubdivisionList = new Vector.<String>();
                }
                
                var element:String = originalList[i];
                currentSubdivisionList.push(element);
            }
            
            if (currentSubdivisionList.length > 0 && outSubdivisionList.indexOf(currentSubdivisionList) == -1)
            {
                outSubdivisionList.push(currentSubdivisionList);
            }
        }
    }
}