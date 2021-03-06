package wordproblem.scripts.expression.systems
{
    import flash.geom.Rectangle;
    
    import dragonbox.common.expressiontree.ExpressionNode;
    import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
    
    import starling.animation.Tween;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    
    import wordproblem.engine.IGameEngine;
    import wordproblem.engine.events.GameEvent;
    import wordproblem.engine.expression.tree.ExpressionTree;
    import wordproblem.engine.widget.TermAreaWidget;
    import wordproblem.resource.AssetManager;
    import wordproblem.scripts.BaseGameScript;
    import wordproblem.scripts.model.ModelSpecificEquation;
    
    /**
     * This script remembers the first correctly modeled equation that is part of an equation
     * set the player needs to model before finishing the level.
     * 
     * Makes the assumption there is only a left and right term area
     * and the level can have at most two different equations the player is trying to model
     */
    public class SaveEquationInSystem extends BaseGameScript
    {
        /**
         * This is like the buffer to hold the contents of the other equation
         */
        private var m_otherEquation:TermAreaWidget;
        
        public function SaveEquationInSystem(gameEngine:IGameEngine, 
                                             expressionCompiler:IExpressionTreeCompiler, 
                                             assetManager:AssetManager, 
                                             id:String=null, 
                                             isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
        }
        
        override public function dispose():void
        {
            super.dispose();
            
            m_otherEquation.removeFromParent(true);
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            if (m_ready)
            {
                m_gameEngine.removeEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
                if (value)
                {
                    m_gameEngine.addEventListener(GameEvent.EQUATION_MODEL_SUCCESS, bufferEvent);
                }
            }
        }
        
        override protected function onLevelReady():void
        {
            super.onLevelReady();
            
            // Create a smaller version of the term area to save the new equation
            var containerWidth:Number = 200;
            var containerHeight:Number = 70;
            m_otherEquation = new TermAreaWidget(
                new ExpressionTree(m_expressionCompiler.getVectorSpace(), null), 
                m_gameEngine.getExpressionSymbolResources(), 
                m_assetManager, 
                m_assetManager.getTexture("term_area_left"), 
                containerWidth, 
                containerHeight, 
                true
            );
            
            setIsActive(m_isActive);
        }
        
        override protected function processBufferedEvent(eventType:String, param:Object):void
        {
            if (eventType == GameEvent.EQUATION_MODEL_SUCCESS)
            {
                var totalScreenWidth:Number = 800;
                var modelEquationScript:ModelSpecificEquation = this.getNodeById("ModelSpecificEquation") as ModelSpecificEquation;
                if (modelEquationScript != null)
                {
                    // If after modeling an equation we still detect a set is not complete then we create a copy
                    if (!modelEquationScript.getAtLeastOneSetComplete())
                    {
                        // Buffer equation should be positioned just below the existing term areas
                        m_otherEquation.x = (totalScreenWidth - m_otherEquation.getConstraintsWidth()) * 0.5;
                        
                        var termAreaToSample:DisplayObject = m_gameEngine.getUiEntity("leftTermArea");
                        var parentToAdd:DisplayObjectContainer = termAreaToSample.parent;
                        m_otherEquation.y = termAreaToSample.y - m_otherEquation.getConstraintsHeight() - 2;
                        
                        parentToAdd.addChild(m_otherEquation);
                        
                        // Separate out the buffered equation into each of the term areas
                        var newBufferedRoot:ExpressionNode = m_gameEngine.getExpressionFromTermAreas();
                        m_otherEquation.setTree(new ExpressionTree(m_expressionCompiler.getVectorSpace(), newBufferedRoot));
                        m_otherEquation.redrawAfterModification();
                        
                        // Clear the current term areas
                        var leftTermArea:TermAreaWidget = m_gameEngine.getUiEntity("leftTermArea") as TermAreaWidget;
                        leftTermArea.setTree(new ExpressionTree(m_expressionCompiler.getVectorSpace(), null));
                        leftTermArea.redrawAfterModification();
                        var rightTermArea:TermAreaWidget = m_gameEngine.getUiEntity("rightTermArea") as TermAreaWidget;
                        rightTermArea.setTree(new ExpressionTree(m_expressionCompiler.getVectorSpace(), null));
                        rightTermArea.redrawAfterModification();
                        
                        // Have new equation fade into view
                        m_otherEquation.alpha = 0.0;
                        var tween:Tween = new Tween(m_otherEquation, 1);
                        tween.animate("alpha", 1.0);
                        Starling.juggler.add(tween);
                    }
                }
            }
        }
    }
}