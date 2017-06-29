package wordproblem.characters;


import flash.geom.Point;

import wordproblem.callouts.CalloutCreator;
import wordproblem.engine.component.CalloutComponent;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.MoveableComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.component.RotatableComponent;
import wordproblem.engine.scripting.graph.ScriptStatus;

class HelperCharacterController
{
    private var m_characterComponentManager : ComponentManager;
    private var m_calloutCreator : CalloutCreator;
    
    public function new(characterComponentManager : ComponentManager, calloutCreator : CalloutCreator)
    {
        m_characterComponentManager = characterComponentManager;
        m_calloutCreator = calloutCreator;
    }
    
    public function getCalloutCreator() : CalloutCreator
    {
        return m_calloutCreator;
    }
    
    public function getComponentManager() : ComponentManager
    {
        return m_characterComponentManager;
    }
    
    /**
     * Check whether a character is still moving towards some destination point
     */
    public function isStillMoving(param : Dynamic) : Int
    {
        var moveableComponent : MoveableComponent = try cast(m_characterComponentManager.getComponentFromEntityIdAndType(
                param.id,
                MoveableComponent.TYPE_ID
                ), MoveableComponent) catch(e:Dynamic) null;
        return ((moveableComponent.isActive)) ? ScriptStatus.FAIL : ScriptStatus.SUCCESS;
    }
    
    /**
     * Important to note that this function should not be called multiple times on the same update frame.
     * Otherwise the change in position from the previous calls will not be applied to the entity data.
     * This is because that logic is executed on a frame after this call was made.
     * Example: 
     * call to move to (0, 800) then to (600, 300) will ignore the first move
     */
    public function moveCharacterTo(param : Dynamic) : Int
    {
        var moveableComponent : MoveableComponent = try cast(m_characterComponentManager.getComponentFromEntityIdAndType(
                param.id,
                MoveableComponent.TYPE_ID
                ), MoveableComponent) catch(e:Dynamic) null;
        moveableComponent.setDestinationAndVelocity(param.x, param.y, param.velocity);
        return ScriptStatus.SUCCESS;
    }
    
    public function rotateCharacterTo(param : Dynamic) : Int
    {
        var rotatableComponent : RotatableComponent = try cast(m_characterComponentManager.getComponentFromEntityIdAndType(
                param.id,
                RotatableComponent.TYPE_ID
                ), RotatableComponent) catch(e:Dynamic) null;
        rotatableComponent.setRotation(param.rotation, param.velocity);
        return ScriptStatus.SUCCESS;
    }
    
    public function setCharacterVisible(param : Dynamic) : Int
    {
        var renderComponent : RenderableComponent = try cast(m_characterComponentManager.getComponentFromEntityIdAndType(
                param.id,
                RenderableComponent.TYPE_ID
                ), RenderableComponent) catch(e:Dynamic) null;
        renderComponent.isVisible = param.visible;
        return ScriptStatus.SUCCESS;
    }
    
    public function showDialogForCharacter(param : Dynamic) : Int
    {
        if (!param.exists("width")) 
        {
            param.width = 300;
        }
        var calloutComponent : CalloutComponent = m_calloutCreator.createCalloutComponentFromText(param);
        m_characterComponentManager.addComponentToEntity(calloutComponent);
        return ScriptStatus.SUCCESS;
    }
    
    public function removeDialogForCharacter(param : Dynamic) : Int
    {
        m_characterComponentManager.removeComponentFromEntity(param.id, CalloutComponent.TYPE_ID);
        return ScriptStatus.SUCCESS;
    }
}
