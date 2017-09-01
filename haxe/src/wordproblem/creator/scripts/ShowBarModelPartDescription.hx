package wordproblem.creator.scripts;


import flash.text.TextFormat;

import feathers.controls.Callout;

import starling.display.DisplayObject;
import starling.text.TextField;

import wordproblem.creator.ProblemCreateEvent;
import wordproblem.creator.WordProblemCreateState;
import wordproblem.engine.barmodel.BarModelTypeDrawer;
import wordproblem.engine.barmodel.BarModelTypeDrawerProperties;
import wordproblem.engine.barmodel.view.BarWholeView;
import wordproblem.engine.component.CalloutComponent;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.text.GameFonts;
import wordproblem.engine.text.MeasuringTextField;
import wordproblem.engine.widget.BarModelAreaWidget;
import wordproblem.resource.AssetManager;

/**
 * On mouse over a particular bar model part, show a callout describing what that particular
 * part represents. For example, does it reresent the number or groups, a total, a differernce, etc.
 */
class ShowBarModelPartDescription extends BaseProblemCreateScript
{
    private var m_barModelArea : BarModelAreaWidget;
    
    /**
     * The text field is used to measure the size of the callout
     */
    private var m_measuringTextField : MeasuringTextField;
    
    private var m_partIdToAttributes : Dynamic;
    
    public function new(createState : WordProblemCreateState,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(createState, assetManager, id, isActive);
    }
    
    /*
    Problem: The mouse events are constantly being dispatched even if the bar model is obscured
    by another layer on top.
    
    
    */
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        if (m_isReady) 
        {
            m_createState.removeEventListener(ProblemCreateEvent.MOUSE_OUT_BAR_ELEMENT, bufferEvent);
            m_createState.removeEventListener(ProblemCreateEvent.MOUSE_OVER_BAR_ELEMENT, bufferEvent);
            if (value) 
            {
                m_createState.addEventListener(ProblemCreateEvent.MOUSE_OUT_BAR_ELEMENT, bufferEvent);
                m_createState.addEventListener(ProblemCreateEvent.MOUSE_OVER_BAR_ELEMENT, bufferEvent);
            }
        }
    }
    
    override public function visit() : Int
    {
        if (m_isReady && m_isActive) 
            { }
        
        return super.visit();
    }
    
    override private function onLevelReady(event : Dynamic) : Void
    {
        super.onLevelReady(event);
        
        m_barModelArea = try cast(m_createState.getWidgetFromId("barModelArea"), BarModelAreaWidget) catch(e:Dynamic) null;
        m_measuringTextField = new MeasuringTextField();
        m_measuringTextField.defaultTextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 18, 0xFFFFFF);
        
        // Get the description names to be used in the callout
        var drawer : BarModelTypeDrawer = new BarModelTypeDrawer();
        m_partIdToAttributes = drawer.getStyleObjectForType(m_createState.getCurrentLevel().barModelType);
        
        setIsActive(m_isActive);
    }
    
    override private function processBufferedEvent(eventType : String, param : Dynamic) : Void
    {
        if (eventType == ProblemCreateEvent.MOUSE_OUT_BAR_ELEMENT) 
        {
            // Delete a callout for element if it exists
            componentManager = m_barModelArea.componentManager;
            componentManager.removeComponentFromEntity(param.elementId, CalloutComponent.TYPE_ID);
        }
        else if (eventType == ProblemCreateEvent.MOUSE_OVER_BAR_ELEMENT) 
        {
            var partId : String = param.partId;
            var propertiesForPartId : BarModelTypeDrawerProperties = Reflect.field(m_partIdToAttributes, partId);
            var componentManager : ComponentManager = m_barModelArea.componentManager;
            
            // Make sure render component is created for this part first
            // Need to associate the id with the correct view in the bar model
            var elementId : String = param.elementId;
            var viewFromId : DisplayObject = getViewFromId(elementId);
            if (viewFromId != null) 
            {
                var renderComponentForElement : RenderableComponent = new RenderableComponent(elementId);
                renderComponentForElement.view = viewFromId;
                componentManager.addComponentToEntity(renderComponentForElement);
                
                m_measuringTextField.text = propertiesForPartId.desc;
                var backgroundPadding : Float = 8;
                var textFormat : TextFormat = m_measuringTextField.defaultTextFormat;
                var textField : TextField = new TextField(
                m_measuringTextField.textWidth + backgroundPadding * 2, 
                m_measuringTextField.textHeight * 2, 
                m_measuringTextField.text, 
                textFormat.font, 
                Std.parseInt(textFormat.size), 
                try cast(textFormat.color, Int) catch(e:Dynamic) null, 
                );
                var calloutComponent : CalloutComponent = new CalloutComponent(elementId);
                calloutComponent.backgroundTexture = "button_white";
                calloutComponent.backgroundColor = 0x000000;
                calloutComponent.arrowTexture = "callout_arrow";
                calloutComponent.edgePadding = -2.0;
                calloutComponent.directionFromOrigin = Callout.DIRECTION_UP;
                calloutComponent.display = textField;
                calloutComponent.xOffset = 0;
                componentManager.addComponentToEntity(calloutComponent);
            }
        }
    }
    
    private function getViewFromId(elementId : String) : DisplayObject
    {
        var matchingView : DisplayObject = null;
        matchingView = m_barModelArea.getBarSegmentViewById(elementId);
        
        if (matchingView == null) 
        {
            matchingView = m_barModelArea.getBarLabelViewById(elementId);
        }
        
        if (matchingView == null) 
        {
            for (barWholeView/* AS3HX WARNING could not determine type for var: barWholeView exp: ECall(EField(EIdent(m_barModelArea),getBarWholeViews),[]) type: null */ in m_barModelArea.getBarWholeViews())
            {
                if (barWholeView.comparisonView && barWholeView.comparisonView.data.id == elementId) 
                {
                    matchingView = barWholeView.comparisonView;
                    break;
                }
            }
        }
        
        if (matchingView == null) 
        {
            matchingView = m_barModelArea.getVerticalBarLabelViewById(elementId);
        }
        
        return matchingView;
    }
}
