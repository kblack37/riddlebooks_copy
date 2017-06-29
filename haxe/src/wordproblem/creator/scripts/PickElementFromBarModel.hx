package wordproblem.creator.scripts;


import flash.geom.Point;
import flash.geom.Rectangle;

import dragonbox.common.ui.MouseState;

import wordproblem.creator.ProblemCreateEvent;
import wordproblem.creator.WordProblemCreateState;
import wordproblem.display.Layer;
import wordproblem.engine.barmodel.BarModelTypeDrawer;
import wordproblem.engine.barmodel.BarModelTypeDrawerProperties;
import wordproblem.engine.barmodel.view.BarComparisonView;
import wordproblem.engine.barmodel.view.BarLabelView;
import wordproblem.engine.barmodel.view.BarSegmentView;
import wordproblem.engine.barmodel.view.BarWholeView;
import wordproblem.engine.widget.BarModelAreaWidget;
import wordproblem.resource.AssetManager;
import wordproblem.scripts.barmodel.BarModelHitAreaUtil;

class PickElementFromBarModel extends BaseProblemCreateScript
{
    private var m_barModelArea : BarModelAreaWidget;
    private var m_mouseState : MouseState;
    
    private var m_outParamsBuffer : Array<Dynamic>;
    private var m_globalMousePoint : Point;
    private var m_localMousePoint : Point;
    private var m_boundsBuffer : Rectangle;
    
    private var m_elementIdMouseIsOverLastFrame : String;
    
    /**
     * Need the style data just to get general priority and restrictions data for a bar model type
     */
    private var m_partNameToStyleAndData : Dynamic;
    
    public function new(createState : WordProblemCreateState,
            assetManager : AssetManager,
            mouseState : MouseState,
            id : String = null,
            isActive : Bool = true)
    {
        super(createState, assetManager, id, isActive);
        
        m_mouseState = mouseState;
        
        m_outParamsBuffer = new Array<Dynamic>();
        m_globalMousePoint = new Point();
        m_localMousePoint = new Point();
        m_boundsBuffer = new Rectangle();
        m_elementIdMouseIsOverLastFrame = null;
    }
    
    override public function visit() : Int
    {
        // Ignore mouse/picking events if the bar model is behind something
        if (m_isActive && m_isReady && !Layer.getDisplayObjectIsInInactiveLayer(m_barModelArea)) 
        {
            m_globalMousePoint.x = m_mouseState.mousePositionThisFrame.x;
            m_globalMousePoint.y = m_mouseState.mousePositionThisFrame.y;
            
            m_barModelArea.globalToLocal(m_globalMousePoint, m_localMousePoint);
            
            // Check if the mouse is over any of the elements of the bar model
            as3hx.Compat.setArrayLength(m_outParamsBuffer, 0);
            BarModelHitAreaUtil.getBarElementUnderPoint(m_outParamsBuffer, m_barModelArea, m_localMousePoint, m_boundsBuffer, false);
            var targetElementId : String = null;
            if (m_outParamsBuffer.length > 0) 
            {
                var hitElement : Dynamic = m_outParamsBuffer[0];
                var hitElementIndex : Int = Std.parseInt(m_outParamsBuffer[1]);
                var hitBarView : BarWholeView = try cast(m_outParamsBuffer[2], BarWholeView) catch(e:Dynamic) null;
                
                if (hitBarView != null) 
                {
                    if (hitElement != null) 
                    {
                        if (Std.is(hitElement, BarSegmentView)) 
                        {
                            targetElementId = (try cast(hitElement, BarSegmentView) catch(e:Dynamic) null).data.id;
                        }
                        else if (Std.is(hitElement, BarLabelView)) 
                        {
                            targetElementId = (try cast(hitElement, BarLabelView) catch(e:Dynamic) null).data.id;
                        }
                        else if (Std.is(hitElement, BarComparisonView)) 
                        {
                            targetElementId = (try cast(hitElement, BarComparisonView) catch(e:Dynamic) null).data.id;
                        }
                    }
                }
                // Check if it is a vertical bar
                else if (hitElement != null) 
                {
                    if (Std.is(hitElement, BarLabelView)) 
                    {
                        targetElementId = (try cast(hitElement, BarLabelView) catch(e:Dynamic) null).data.id;
                    }
                }
            }  // In this case we prioritize the unit over the group    // of groups AND for the symbol for a single group value    // name, in particular a bar segment can be attached to the symbol for total number    // Note that a single bar model element might be associated with more than one part    // of the bar model. Is it a, b, c, or ?    // Need to map the selected element being moused over to the to the part name id  
            
            
            
            
            
            
            
            
            
            
            
            
            
            if (targetElementId != null && m_mouseState.leftMousePressedThisFrame) 
            {
                var matchingPartName : String = getPartIdFromElementId(targetElementId);
                m_createState.dispatchEventWith(ProblemCreateEvent.SELECT_BAR_ELEMENT, false, {
                            id : matchingPartName

                        });
            }
            
            if (targetElementId != m_elementIdMouseIsOverLastFrame) 
            {
                if (m_elementIdMouseIsOverLastFrame != null) 
                {
                    var data : Dynamic = {
                        partId : getPartIdFromElementId(m_elementIdMouseIsOverLastFrame),
                        elementId : m_elementIdMouseIsOverLastFrame,

                    };
                    m_createState.dispatchEventWith(ProblemCreateEvent.MOUSE_OUT_BAR_ELEMENT, false, data);
                }
                
                if (targetElementId != null) 
                {
                    data = {
                                partId : getPartIdFromElementId(targetElementId),
                                elementId : targetElementId,

                            };
                    m_createState.dispatchEventWith(ProblemCreateEvent.MOUSE_OVER_BAR_ELEMENT, false, data);
                }
            }
            
            m_elementIdMouseIsOverLastFrame = targetElementId;
        }
        
        return super.visit();
    }
    
    override private function onLevelReady() : Void
    {
        super.onLevelReady();
        
        m_barModelArea = try cast(m_createState.getWidgetFromId("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        
        var barModelDrawer : BarModelTypeDrawer = new BarModelTypeDrawer();
        m_partNameToStyleAndData = barModelDrawer.getStyleObjectForType(m_createState.getCurrentLevel().barModelType);
        
        setIsActive(m_isActive);
    }
    
    private function getPartIdFromElementId(targetElementId : String) : String
    {
        var matchingPartName : String = null;
        var partNameToElementIds : Dynamic = m_createState.getCurrentLevel().getPartNameToIdsMap();
        var matchedPartPriority : Int = Int.MIN_VALUE;
        for (partName in Reflect.fields(partNameToElementIds))
        {
            var elementIdsForPart : Array<String> = Reflect.field(partNameToElementIds, partName);
            var propertiesForPartName : BarModelTypeDrawerProperties = Reflect.field(m_partNameToStyleAndData, partName);
            if (propertiesForPartName.priority > matchedPartPriority) 
            {
                for (elementId in elementIdsForPart)
                {
                    if (targetElementId == elementId) 
                    {
                        matchingPartName = partName;
                        matchedPartPriority = propertiesForPartName.priority;
                        break;
                    }
                }
            }
        }
        
        return matchingPartName;
    }
}
