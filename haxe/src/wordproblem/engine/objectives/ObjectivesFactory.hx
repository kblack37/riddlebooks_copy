package wordproblem.engine.objectives;

import haxe.xml.Fast;
import wordproblem.engine.objectives.TimeLimitObjective;
import wordproblem.engine.objectives.TotalEquationAndBarModelMistakeObjective;

class ObjectivesFactory
{
    public static function getObjectivesFromXml(objectivesXml : Fast, outObjectives : Array<BaseObjective> = null) : Array<BaseObjective>
    {
        if (outObjectives == null) 
        {
            outObjectives = new Array<BaseObjective>();
        }
		
		var objectivesList = objectivesXml.elements;
		for (objective in objectivesList) {
			var objectiveType : String = objective.att.type;
			var newObjective : BaseObjective = createDefaultObjectiveFromName(objectiveType);
			
			if (newObjective != null) {
				newObjective.deserializeFromXml(objective);
				outObjectives.push(newObjective);
			}
		}
        
        return outObjectives;
    }
    
    public static function getObjectivesFromJsonArray(objectives : Array<Dynamic>, outObjectives : Array<BaseObjective> = null) : Array<BaseObjective>
    {
        if (outObjectives == null) 
        {
            outObjectives = new Array<BaseObjective>();
        }
        
        var i : Int = 0;
        var numObjectives : Int = objectives.length;
        for (i in 0...numObjectives){
            
            var objective : Dynamic = objectives[i];
            var objectiveType : String = objective.type;
            var newObjective : BaseObjective = createDefaultObjectiveFromName(objectiveType);
            
            if (newObjective != null) 
            {
                newObjective.deserializeFromJson(objective);
                outObjectives.push(newObjective);
            }
        }
        
        return outObjectives;
    }
    
    private static function createDefaultObjectiveFromName(objectiveType : String) : BaseObjective
    {
        var newObjective : BaseObjective = null;
        if (objectiveType == TimeLimitObjective.TYPE) 
        {
            newObjective = new TimeLimitObjective(-1, true);
        }
        else if (objectiveType == TotalEquationAndBarModelMistakeObjective.TYPE) 
        {
            newObjective = new TotalEquationAndBarModelMistakeObjective(-1, true);
        }
        else if (objectiveType == HintUsedObjective.TYPE) 
        {
            newObjective = new HintUsedObjective(-1, true);
        }
        
        return newObjective;
    }

    public function new()
    {
    }
}
