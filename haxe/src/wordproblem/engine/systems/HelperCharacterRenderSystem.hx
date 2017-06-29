package wordproblem.engine.systems;


import flash.utils.Dictionary;

import starling.animation.Juggler;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.MovieClip;
import starling.textures.TextureAtlas;

import wordproblem.engine.component.AnimatedTextureAtlasStateComponent;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.component.TextureCollectionComponent;
import wordproblem.engine.component.TransformComponent;
import wordproblem.resource.AssetManager;

/**
 * This class takes care of drawing the helper characters that float around in various screens.
 * These entities behave slightly different than items which is why they cannot recycle the renderer
 * for them.
 * 
 * First they are not bound to any genre and can freely move anywhere.
 * Second, they may have several animation cycles which requires switching active spritesheets
 * 
 */
class HelperCharacterRenderSystem extends BaseSystemScript
{
    /**
     * Used to grab assets related to the helpers
     */
    private var m_assetManager : AssetManager;
    
    /**
     * We leverage the juggler since we are using starling movie clips to render our spritesheets
     */
    private var m_spriteSheetJuggler : Juggler;
    
    /**
     * To detect changes on each visit, for each entity id we map to the state
     * value it was on the last visit.
     */
    private var m_previousStateValue : Dictionary;
    
    private var m_parentDisplay : DisplayObjectContainer;
    
    public function new(assetManager : AssetManager,
            spriteSheetJuggler : Juggler,
            parentDisplay : DisplayObjectContainer)
    {
        super("HelperCharacterRenderSystem");
        
        m_assetManager = assetManager;
        m_spriteSheetJuggler = spriteSheetJuggler;
        m_previousStateValue = new Dictionary();
        setParentDisplay(parentDisplay);
    }
    
    public function setParentDisplay(parentDisplay : DisplayObjectContainer) : Void
    {
        m_parentDisplay = parentDisplay;
    }
    
    override public function update(componentManager : ComponentManager) : Void
    {
        // First get the render component, this is the canvas where the image of the character is saved
        var renderComponents : Array<Component> = componentManager.getComponentListForType(RenderableComponent.TYPE_ID);
        var numRenderComponents : Int = renderComponents.length;
        var renderComponent : RenderableComponent;
        var i : Int;
        for (i in 0...numRenderComponents){
            renderComponent = try cast(renderComponents[i], RenderableComponent) catch(e:Dynamic) null;
            if (renderComponent.isVisible) 
            {
                var indexInCollection : Int = renderComponent.renderStatus;
                var entityId : String = renderComponent.entityId;
                
                var drawNewImage : Bool = false;
                // Get the current state the entity is in, this will be used
                // to determine how it should be drawn.
                var textureCollectionComponent : TextureCollectionComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                        entityId,
                        TextureCollectionComponent.TYPE_ID
                        ), TextureCollectionComponent) catch(e:Dynamic) null;
                
                // HACK: Switching the animation cycles, we stay at the idle frame longer than the active hover frame
                if (textureCollectionComponent.textureCollection.length > 1) 
                {
                    // To detect whether a helper character should progress to another animation cycle, we
                    // need to detect how many cycle on the current state they have already finished
                    var textureAtlasStateComponent : AnimatedTextureAtlasStateComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                            entityId,
                            AnimatedTextureAtlasStateComponent.TYPE_ID
                            ), AnimatedTextureAtlasStateComponent) catch(e:Dynamic) null;
                    
                    if (textureAtlasStateComponent.currentCyclesComplete >= 1) 
                    {
                        textureAtlasStateComponent.currentCyclesComplete = 0;
                        renderComponent.renderStatus = ((renderComponent.renderStatus == 0)) ? 1 : 0;
                        indexInCollection = renderComponent.renderStatus;
                    }
                }  // Set previous state to initial value if not present in map  
                
                
                
                var previousStateValue : Int = ((m_previousStateValue.exists(entityId))) ? Reflect.field(m_previousStateValue, entityId) : -1;
                var currentStateValue : Int = renderComponent.renderStatus;
                Reflect.setField(m_previousStateValue, entityId, currentStateValue);
                
                // If current state differs from previous then we need to draw a new image, discard the old on
                if (previousStateValue != currentStateValue) 
                {
                    if (renderComponent.view != null) 
                    {
                        m_spriteSheetJuggler.remove(try cast(renderComponent.view, MovieClip) catch(e:Dynamic) null);
                        renderComponent.view.removeFromParent(true);
                    }
                    
                    drawNewImage = true;
                }  // Depending on the type of object draw the character  
                
                
                
                var textureData : Dynamic = textureCollectionComponent.textureCollection[indexInCollection];
                if (textureData.type == "SpriteSheetAnimated") 
                {
                    // Create the movieclip and run it once if not already playing
                    // On visit we just need to update the time
                    if (drawNewImage) 
                    {
                        var textureAtlas : TextureAtlas = m_assetManager.getTextureAtlas(textureData.textureName);
                        var movieClip : MovieClip = new MovieClip(textureAtlas.getTextures(), 30);
                        movieClip.pivotX = movieClip.width * 0.5;
                        movieClip.pivotY = movieClip.height * 0.5;
                        movieClip.loop = true;
                        renderComponent.view = movieClip;
                        
                        movieClip.play();
                        m_spriteSheetJuggler.add(movieClip);
                    }
                    
                    if (textureAtlasStateComponent != null) 
                    {
                        textureAtlasStateComponent.currentFrameCounter++;
                        if (textureAtlasStateComponent.currentFrameCounter >= (try cast(renderComponent.view, MovieClip) catch(e:Dynamic) null).numFrames) 
                        {
                            textureAtlasStateComponent.currentFrameCounter = 0;
                            textureAtlasStateComponent.currentCyclesComplete++;
                        }
                    }  // Advance the time of the movieclip  
                    
                    
                    
                    var view : DisplayObject = renderComponent.view;
                    
                    // Re-position the helper character to the right spot
                    var positionComponent : TransformComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                            entityId,
                            TransformComponent.TYPE_ID
                            ), TransformComponent) catch(e:Dynamic) null;
                    
                    view.scaleX = view.scaleY = positionComponent.scale;
                    view.x = positionComponent.x;
                    view.y = positionComponent.y;
                    view.rotation = positionComponent.rotation;
                }  // Re-add view  
                
                
                
                if (view.parent == null || view.parent != m_parentDisplay) 
                {
                    m_parentDisplay.addChild(view);
                }
            }
            else if (renderComponent.view != null && renderComponent.view.parent != null) 
            {
                renderComponent.view.removeFromParent();
                m_spriteSheetJuggler.remove(try cast(renderComponent.view, MovieClip) catch(e:Dynamic) null);
                ;
            }
        }
    }
}
