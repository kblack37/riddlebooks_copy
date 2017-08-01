package dragonbox.common.util;


class ListUtil
{
    /**
     * Subdivide a list of ids into smaller lists container at most n elements
     */
    public static function subdivideList(originalList : Array<String>, numItemsInGroup : Int, outSubdivisionList : Array<Array<String>>) : Void
    {
        var i : Int = 0;
        var numTotalElements : Int = originalList.length;
        var currentSubdivisionList : Array<String> = new Array<String>();
        for (i in 0...numTotalElements){
            if (currentSubdivisionList.length >= numItemsInGroup) 
            {
                outSubdivisionList.push(currentSubdivisionList);
                currentSubdivisionList = new Array<String>();
            }
            
            var element : String = originalList[i];
            currentSubdivisionList.push(element);
        }
        
        if (currentSubdivisionList.length > 0 && Lambda.indexOf(outSubdivisionList, currentSubdivisionList) == -1) 
        {
            outSubdivisionList.push(currentSubdivisionList);
        }
    }

    public function new()
    {
    }
}
