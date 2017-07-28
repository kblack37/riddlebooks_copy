package wordproblem.hints.processes;

import starling.display.DisplayObject;
import starling.textures.Texture;

import wordproblem.characters.HelperCharacterController;
import wordproblem.engine.component.CalloutComponent;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.resource.AssetManager;

class ShowCharacterTextProcess extends ScriptNode
{
    private var m_calloutContent : DisplayObject;
    private var m_characterController : HelperCharacterController;
    private var m_characterId : String;
    private var m_assetManager : AssetManager;
    
    public function new(calloutContent : DisplayObject,
            characterAndCalloutControl : HelperCharacterController,
            characterId : String,
            assetManager : AssetManager,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_calloutContent = calloutContent;
        m_characterController = characterAndCalloutControl;
        m_characterId = characterId;
        m_assetManager = assetManager;
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(true);
        if (!value) 
        {
            if (m_characterController.getComponentManager().getComponentFromEntityIdAndType(m_characterId, CalloutComponent.TYPE_ID) != null) 
            {
                m_characterController.getComponentManager().removeComponentFromEntity(m_characterId, CalloutComponent.TYPE_ID);
            }
        }
    }
    
    override public function visit() : Int
    {
        // Showing the callout can just execute on a single frame
        
        // Add callout to the character
        var calloutBackgroundName : String = "thought_bubble";
        var calloutComponent : CalloutComponent = new CalloutComponent(m_characterId);
        calloutComponent.backgroundTexture = calloutBackgroundName;
        
        // The allowable width of the content depends on the normal size of the thought bubble
        // that composes the background. Need to get the text to find the dimensions
        // However, imagine a box inside the thought bubble where content should actually go
        // to avoid overflowing the oval shaped edges. The is padding to the thought bubble
        // that must be accounted for.
        var measuringTexture : Texture = m_assetManager.getTexture(calloutBackgroundName);
        var paddingSide : Float = 10;
        
        calloutComponent.display = m_calloutContent;
		// TODO: this was replaced from the feathers Callout.DIRECTION_RIGHT and will
		// need to be replaced when the callout system is
        calloutComponent.directionFromOrigin = "right";
        calloutComponent.contentPadding = paddingSide;
        m_characterController.getComponentManager().addComponentToEntity(calloutComponent);
        
        return ScriptStatus.SUCCESS;
    }
}
