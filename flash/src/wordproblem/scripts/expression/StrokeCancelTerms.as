package wordproblem.scripts.expression
{
    import flash.geom.Point;
    
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    import dragonbox.common.ui.MouseState;
    
    import wordproblem.resource.AssetManager
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.expression.widget.manager.CancelManager;
    import wordproblem.engine.expression.widget.term.BaseTermWidget;
    import wordproblem.engine.scripting.graph.ScriptStatus;
    import wordproblem.engine.widget.TermAreaWidget;
    
    public class StrokeCancelTerms extends BaseTermAreaScript
    {
        private var m_cancelManagers:Vector.<CancelManager>;
        
        public function StrokeCancelTerms(gameEngine:IGameEngine, 
                                          expressionCompiler:IExpressionTreeCompiler, 
                                          assetManager:AssetManager, 
                                          id:String=null, 
                                          isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
        }
        
        private const mousePoint:Point = new Point();
        override public function visit():int
        {
            var mouseState:MouseState = m_gameEngine.getMouseState();
            mousePoint.setTo(mouseState.mousePositionThisFrame.x, mouseState.mousePositionThisFrame.y);
            
            // Assuming each term area has a snap and cancel component
            for (var i:int = 0; i < m_termAreas.length; i++)
            {
                const cancelManager:CancelManager = m_cancelManagers[i];
                cancelManager.update(mouseState);
            }
            
            return ScriptStatus.SUCCESS;
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            m_cancelManagers = new Vector.<CancelManager>();
            for (var i:int = 0; i < m_termAreas.length; i++)
            {
                const termArea:TermAreaWidget = m_termAreas[i];
                m_cancelManagers.push(new CancelManager(
                    termArea,
                    m_assetManager,
                    onCancelStrokeFinished
                ));
            }
        }
        
        private function onCancelStrokeFinished(cancelManager:CancelManager):void
        {
            // Look through the list of nodes that were marked for cancellation
            // Find out the combination of nodes that are able to simplify
            var cancelledWidgets:Vector.<BaseTermWidget> = cancelManager.getWidgetsMarkedForCancel();
            
            var nodes:Vector.<ExpressionNode> = new Vector.<ExpressionNode>();
            for each (var cancelledWidget:BaseTermWidget in cancelledWidgets)
            {
                nodes.push(cancelledWidget.getNode());
            }
            
            const termAreaIndex:int = m_cancelManagers.indexOf(cancelManager);
            const termArea:TermAreaWidget = m_termAreas[termAreaIndex];
            termArea.simplify(cancelledWidgets);
            
            cancelManager.clear();
        }
    }
}