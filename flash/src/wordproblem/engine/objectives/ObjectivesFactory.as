package wordproblem.engine.objectives
{
    public class ObjectivesFactory
    {
        public static function getObjectivesFromXml(objectivesXml:XML, outObjectives:Vector.<BaseObjective>=null):Vector.<BaseObjective>
        {
            if (outObjectives == null) 
            {
                outObjectives = new Vector.<BaseObjective>();
            }
            
            var i:int;
            var objectivesList:XMLList = objectivesXml.children();
            var numObjectives:int = objectivesList.length();
            for (i = 0; i < numObjectives; i++)
            {
                var objective:XML = objectivesList[i];
                var objectiveType:String = objective.@type;
                var newObjective:BaseObjective = createDefaultObjectiveFromName(objectiveType);

                if (newObjective != null)
                {
                    newObjective.deserializeFromXml(objective);
                    outObjectives.push(newObjective);
                }
            }
            
            return outObjectives;
        }
        
        public static function getObjectivesFromJsonArray(objectives:Array, outObjectives:Vector.<BaseObjective>=null):Vector.<BaseObjective>
        {
            if (outObjectives == null) 
            {
                outObjectives = new Vector.<BaseObjective>();
            }
            
            var i:int;
            var numObjectives:int = objectives.length;
            for (i = 0; i < numObjectives; i++)
            {
                
                var objective:Object = objectives[i];
                var objectiveType:String = objective.type;
                var newObjective:BaseObjective = createDefaultObjectiveFromName(objectiveType);
                
                if (newObjective != null)
                {
                    newObjective.deserializeFromJson(objective);
                    outObjectives.push(newObjective);
                }
            }
            
            return outObjectives;
        }
        
        private static function createDefaultObjectiveFromName(objectiveType:String):BaseObjective
        {
            var newObjective:BaseObjective = null;
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
    }
}