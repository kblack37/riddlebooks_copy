package wordproblem.scripts.barmodel
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import dragonbox.common.expressiontree.ExpressionNode;
	import dragonbox.common.expressiontree.compile.IExpressionTreeCompiler;
	
	import starling.display.DisplayObjectContainer;
	import starling.textures.Texture;
	
	import wordproblem.engine.IGameEngine;
	import wordproblem.engine.barmodel.model.BarLabel;
	import wordproblem.engine.barmodel.model.BarModelData;
	import wordproblem.engine.barmodel.view.BarLabelView;
	import wordproblem.engine.barmodel.view.BarModelView;
	import wordproblem.engine.barmodel.view.BarSegmentView;
	import wordproblem.engine.barmodel.view.BarWholeView;
	import wordproblem.engine.component.BlinkComponent;
	import wordproblem.engine.component.RenderableComponent;
	import wordproblem.engine.events.GameEvent;
	import wordproblem.engine.expression.widget.term.BaseTermWidget;
	import wordproblem.engine.expression.widget.term.SymbolTermWidget;
	import wordproblem.engine.scripting.graph.ScriptStatus;
	import wordproblem.log.AlgebraAdventureLoggingConstants;
	import wordproblem.resource.AssetManager;
    
    /**
     * This script handles the addition of brand new bars in the model
     * 
     * The hit area is between each pair of bar starting at the end of the longer bar
     */
    public class AddNewVerticalLabel extends BaseBarModelScript implements IHitAreaScript
    {
        private static const PREVIEW_NEW_VERTICAL_LABEL_ID:String = "new_vertical_label_id";
        
        /**
         * The maximum number of vertical labels that can appear together at any one time.
         * If negative, then there is no limit to the number of labels.
         */
        private var m_maxVerticalBrackets:int;
        
        /**
         * We only have one hit area, this is just a wrapper so the show hit area script
         * has a common value it can get
         */
        private var m_hitAreas:Vector.<Rectangle>;
        private var m_hitAreaBuffer:Rectangle;
        
        /**
         * Should hit areas for this action be shown in at the start of a frame
         */
        private var m_showHitAreas:Boolean;
        
        public function AddNewVerticalLabel(gameEngine:IGameEngine, 
                                            expressionCompiler:IExpressionTreeCompiler, 
                                            assetManager:AssetManager, 
                                            maxBrackets:int,
                                            id:String=null, 
                                            isActive:Boolean=true)
        {
            super(gameEngine, expressionCompiler, assetManager, id, isActive);
            
            m_maxVerticalBrackets = maxBrackets;
            m_hitAreaBuffer = new Rectangle();
            m_hitAreas = Vector.<Rectangle>([m_hitAreaBuffer]);
        }
        
        override public function visit():int
        {
            var status:int = ScriptStatus.FAIL;
            m_showHitAreas = false;
            if (m_ready && m_isActive)
            {
                m_globalMouseBuffer.setTo(m_mouseState.mousePositionThisFrame.x, m_mouseState.mousePositionThisFrame.y);
                m_barModelArea.globalToLocal(m_globalMouseBuffer, m_localMouseBuffer);
                
                if (m_eventTypeBuffer.length > 0)
                {
                    var data:Object = m_eventParamBuffer[0];
                    var releasedWidget:BaseTermWidget = data.widget;
                    var releasedExpressionNode:ExpressionNode = releasedWidget.getNode();
                    
                    if (checkHit(m_localMouseBuffer) && releasedWidget is SymbolTermWidget)
                    {
                        m_barModelArea.showPreview(false);
                        m_didActivatePreview = false;
                        
                        // If the value is a number use it directly, for variables check if there is a more descriptive name
                        var previousModelDataSnapshot:BarModelData = m_barModelArea.getBarModelData().clone();
                        addNewVerticalBracket(m_barModelArea.getBarModelData().verticalBarLabels, releasedExpressionNode.data, m_barModelArea.getBarModelData().barWholes.length - 1);
                        m_eventDispatcher.dispatchEventWith(GameEvent.BAR_MODEL_AREA_CHANGE, false, {previousSnapshot:previousModelDataSnapshot});
                        m_barModelArea.redraw();
                        
                        // Log addition to new label spanning whole bars
                        m_eventDispatcher.dispatchEventWith(AlgebraAdventureLoggingConstants.ADD_NEW_VERTICAL_LABEL, false, {
                            barModel:m_barModelArea.getBarModelData().serialize(),
                            value:releasedExpressionNode.data
                        });
                        
                        status = ScriptStatus.SUCCESS;
                    }
                    
                    reset();
                }
                else if (m_widgetDragSystem.getWidgetSelected() != null && m_widgetDragSystem.getWidgetSelected() is SymbolTermWidget)
				{
                    m_showHitAreas = true;
					if (checkHit(m_localMouseBuffer))
					{
                        // This check shows the preview if either it was not showing already OR a lower priority
                        // script had activated it but we want to overwrite it.
                        if (!m_barModelArea.getPreviewShowing() || !m_didActivatePreview)
                        {
                            var draggedExpressionNode:ExpressionNode = m_widgetDragSystem.getWidgetSelected().getNode();
                            var previewView:BarModelView = m_barModelArea.getPreviewView(true);
                            addNewVerticalBracket(previewView.getBarModelData().verticalBarLabels, draggedExpressionNode.data, previewView.getBarModelData().barWholes.length - 1, PREVIEW_NEW_VERTICAL_LABEL_ID);
                            m_barModelArea.showPreview(true);
                            m_didActivatePreview = true;
                            
                            // Need to get at the new bar label view
                            var newBarLabelView:BarLabelView = previewView.getVerticalBarLabelViewById(PREVIEW_NEW_VERTICAL_LABEL_ID);
                            m_barModelArea.componentManager.addComponentToEntity(new BlinkComponent(PREVIEW_NEW_VERTICAL_LABEL_ID));
                            var renderComponent:RenderableComponent = new RenderableComponent(PREVIEW_NEW_VERTICAL_LABEL_ID);
                            renderComponent.view = newBarLabelView;
                            m_barModelArea.componentManager.addComponentToEntity(renderComponent);
                            
                            super.setDraggedWidgetVisible(false);
                        }
                        
                        // Show preview
                        status = ScriptStatus.SUCCESS;
					}
                    else if (m_didActivatePreview)
                    {
                        m_barModelArea.showPreview(false);
                        m_didActivatePreview = false;
                        m_barModelArea.componentManager.removeAllComponentsFromEntity(PREVIEW_NEW_VERTICAL_LABEL_ID);
                        super.setDraggedWidgetVisible(true);
                    }
				}
            }
            return status;
        }
        
        override public function reset():void
        {
            super.reset();
            
            m_barModelArea.componentManager.removeAllComponentsFromEntity(PREVIEW_NEW_VERTICAL_LABEL_ID);
            m_showHitAreas = false;
        }
        
        public function getActiveHitAreas():Vector.<Rectangle>
        {
            calculateHitArea();
            return m_hitAreas;
        }
        
        public function getShowHitAreasForFrame():Boolean
        {
            return m_showHitAreas;
        }
        
        public function postProcessHitAreas(hitAreas:Vector.<Rectangle>, hitAreaGraphics:Vector.<DisplayObjectContainer>):void
        {
            var leftBracketTexture:Texture = m_assetManager.getTexture("brace_left_end");
            var rightBracketTexture:Texture = m_assetManager.getTexture("brace_right_end");
            var middleBracketTexture:Texture = m_assetManager.getTexture("brace_center");
            var fullBracketTexture:Texture = m_assetManager.getTexture("brace_full");
            var i:int;
            var numHitAreas:int = hitAreas.length;
            for (i = 0; i < numHitAreas; i++)
            {
                var hitArea:Rectangle = hitAreas[i];
                var dummyBarLabel:BarLabel = new BarLabel(null, 0, 0, false, false, BarLabel.BRACKET_STRAIGHT, null);
                var bracketView:BarLabelView = new BarLabelView(dummyBarLabel, "Verdana", 0xFFFFFF, 
                    leftBracketTexture, rightBracketTexture, middleBracketTexture, fullBracketTexture, 
                    null, null, false, null);
                
                var verticalPadding:Number = 4;
                bracketView.resizeToLength(hitArea.height - 2 * verticalPadding);
                bracketView.y = verticalPadding;
                bracketView.x = (hitArea.width - bracketView.width) * 0.5;
                
                // Make sure the brack fits the width constraints
                if (bracketView.width > hitArea.width)
                {
                    bracketView.scaleX = hitArea.width / bracketView.width;
                }
                
                hitAreaGraphics[i].addChild(bracketView);
            }
        }
        
        private function calculateHitArea():void
        {
            // The new hit area for the vertical label should be directly to the left of the longest bar
            var barWholeViews:Vector.<BarWholeView> = m_barModelArea.getBarWholeViews();
            var numBarWholeViews:int = barWholeViews.length;
            
            if (numBarWholeViews > 1 && (m_maxVerticalBrackets > m_barModelArea.getVerticalBarLabelViews().length || m_maxVerticalBrackets < 0))
            {
                // The longest end defines the a left most limit
                var longestBarIndex:int = -1;
                var longestRightXEdge:Number = 0;
                var i:int;
                for (i = 0; i < numBarWholeViews; i++)
                {
                    var barWholeView:BarWholeView = barWholeViews[i];
                    var segmentViews:Vector.<BarSegmentView> = barWholeView.segmentViews;
                    var rightXEdge:Number = segmentViews[segmentViews.length - 1].rigidBody.boundingRectangle.right;
                    if (longestBarIndex == -1 || rightXEdge > longestRightXEdge)
                    {
                        longestBarIndex = i;
                        longestRightXEdge = rightXEdge;
                    }
                }
                
                // The top of the first bar and bottom of the last bar define the vertical
                // limits of the hit area
                var firstBar:BarWholeView = barWholeViews[0];
                var lastBar:BarWholeView = barWholeViews[barWholeViews.length - 1];
                var topEdge:Number = firstBar.segmentViews[0].rigidBody.boundingRectangle.top;
                var bottomEdge:Number = lastBar.segmentViews[0].rigidBody.boundingRectangle.bottom;
                
                var hitAreaWidth:Number = 80;
                var hitAreaHeight:Number = bottomEdge - topEdge;
                m_hitAreaBuffer.setTo(longestRightXEdge + 20, topEdge, hitAreaWidth, hitAreaHeight);
                if (m_hitAreas.length == 0)
                {
                    m_hitAreas.push(m_hitAreaBuffer);
                }
            }
            else
            {
                m_hitAreas.length = 0;
            }
        }
        
		private function checkHit(mouseLocal:Point):Boolean
        {
            calculateHitArea();
			return m_hitAreas.length > 0 && m_hitAreas[0].containsPoint(m_localMouseBuffer);
		}
        
        private function addNewVerticalBracket(verticalBarLabels:Vector.<BarLabel>, value:String, endIndex:int, id:String=null):void
        {
            var newVerticalBracket:BarLabel = new BarLabel(value, 0, endIndex, false, false, BarLabel.BRACKET_STRAIGHT, null, id);
            verticalBarLabels.push(newVerticalBracket);
        }
    }
}