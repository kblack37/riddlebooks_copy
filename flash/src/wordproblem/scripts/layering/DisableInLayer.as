package wordproblem.scripts.layering
{
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import starling.display.DisplayObject;
    
    import wordproblem.display.Layer;
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.BaseGameScript;
    
    /**
     * This script is intended to be part of a larger sequence of actions that are part of a selector.
     * It's sole purpose is to be executed before some other set of scripts and interrupt those scripts from
     * being run IF a particular ui component is in a disabled layer.
     * 
     * For example suppose we have a number pad that pops up in front of the bar model area. Clicks should not
     * be able to 'pierce' through the number pad and hit objects in the bar model.
     */
    public class DisableInLayer extends BaseGameScript
    {
        /**
         * The ui piece that we want to check is in a layer that is disabled
         */
        private var m_displayObjectToCheck:DisplayObject;
        
        public function DisableInLayer(displayObjectToCheck:DisplayObject,
                                       gameEngine:IGameEngine, 
                                       expressionCompiler:IExpressionTreeCompiler, 
                                       assetManager:AssetManager, 
                                       id:String=null, 
                                       isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            m_displayObjectToCheck = displayObjectToCheck;
        }
        
        override public function visit():int
        {
            var status:int = ScriptStatus.FAIL;
            
            // Return success on if the target display object is within a disabled layer
            if (m_ready && m_isActive)
            {
                status = (Layer.getDisplayObjectIsInInactiveLayer(m_displayObjectToCheck)) ? ScriptStatus.SUCCESS : ScriptStatus.FAIL;
            }
            
            return status;
        }
    }
}