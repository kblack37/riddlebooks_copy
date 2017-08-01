package wordproblem.levelselect.scripts;


import openfl.geom.Rectangle;
import openfl.Vector;

import starling.animation.Juggler;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.MovieClip;
import starling.textures.Texture;
import starling.textures.TextureAtlas;

import wordproblem.engine.component.AnimatedTextureAtlasStateComponent;
import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.GenreIdComponent;
import wordproblem.engine.component.ItemIdComponent;
import wordproblem.engine.component.RenderableComponent;
import wordproblem.engine.component.RigidBodyComponent;
import wordproblem.engine.component.TextureCollectionComponent;
import wordproblem.engine.scripting.graph.ScriptNode;
import wordproblem.engine.scripting.graph.ScriptStatus;
import wordproblem.items.ItemDataSource;
import wordproblem.items.ItemInventory;
import wordproblem.resource.AssetManager;
import wordproblem.state.WordProblemSelectState;

/**
 * This class draws all the reward items earned by the player on the level select book shelf.
 * 
 * Needs to handle several different methods to render something.
 * (Logic to switch between animations is dependent on the item type but needs to be handled here)
 * 
 * IMPORTANT: This script is performing texture disposal which means if any other part of the game is showing
 * that texture an error will appear. Thus we are relying on the assumption that no other parts are using
 * the textures that this script is using.
 */
class DrawItemsOnShelves extends ScriptNode
{
    /**
     * The layer on which to add the rewards
     */
    private var m_levelSelectState : WordProblemSelectState;
    
    /**
     * Items tied to a a game player instance, include both reward items and common object like dragonbox prop
     */
    private var m_playerItemInventory : ItemInventory;
    
    private var m_itemDataSource : ItemDataSource;
    private var m_assetManager : AssetManager;
    
    /**
     * The juggler is used to play starling movie clips
     */
    private var m_spriteSheetJuggler : Juggler;
    
    /**
     * Each system is responsible for noticing that entity wants to change the base texture used to
     * draw it. (Cannot use a dirty bit in the component since it is unclear when that bit should be flipped off)
     * 
     * Maps from entity id to an integer state value
     */
    private var m_previousStateValue : Map<String, Int>;
    
    /**
     * Buffer to store which textures were active on the last update frame.
     * This is required to compare with textures that become active on the next frame.
     * 
     * key: texture name
     * value: true if texture atlas, false otherwise
     */
    private var m_activeTextureNamesOnLastFrame : Map<String, Bool>;
    
    /**
     * Buffer to store active textures on the current pass
     * 
     * key: texture name
     * value: true if texture atlas, false otherwise
     */
    private var m_activeTextureNamesOnCurrentFrame : Map<String, Bool>;
    
    public function new(levelSelectState : WordProblemSelectState,
            playerItemInventory : ItemInventory,
            itemDataSource : ItemDataSource,
            assetManager : AssetManager,
            spriteSheetJuggler : Juggler,
            id : String = null,
            isActive : Bool = true)
    {
        super(id, isActive);
        
        m_levelSelectState = levelSelectState;
        m_playerItemInventory = playerItemInventory;
        m_itemDataSource = itemDataSource;
        m_assetManager = assetManager;
        m_spriteSheetJuggler = spriteSheetJuggler;
        m_previousStateValue = new Map();
        
        m_activeTextureNamesOnLastFrame = new Map();
        m_activeTextureNamesOnCurrentFrame = new Map();
    }
    
    override public function visit() : Int
    {
        redraw(m_playerItemInventory.componentManager);
        
        return ScriptStatus.SUCCESS;
    }
    
    override public function setIsActive(value : Bool) : Void
    {
        super.setIsActive(value);
        
        if (!m_isActive) 
        {
            // Clearing previous state will force a redraw
			// Clear out all currently visible views  
            var renderComponents : Array<Component> = m_playerItemInventory.componentManager.getComponentListForType(RenderableComponent.TYPE_ID);
            var numRenderComponents : Int = renderComponents.length;
            var renderComponent : RenderableComponent = null;
            var i : Int = 0;
            for (i in 0...numRenderComponents){
                renderComponent = try cast(renderComponents[i], RenderableComponent) catch(e:Dynamic) null;
                if (renderComponent.view != null) 
                {
                    renderComponent.view.removeFromParent(true);
                    
                    if (Std.is(renderComponent.view, MovieClip)) 
                    {
                        m_spriteSheetJuggler.remove(try cast(renderComponent.view, MovieClip) catch(e:Dynamic) null);
                    }
                }
            } 
        }
    }
    
    private function redraw(componentManager : ComponentManager) : Void
    {
        var renderComponents : Array<Component> = componentManager.getComponentListForType(RenderableComponent.TYPE_ID);
        var numRenderComponents : Int = renderComponents.length;
        var renderComponent : RenderableComponent = null;
        var i : Int = 0;
        for (i in 0...numRenderComponents){
            renderComponent = try cast(renderComponents[i], RenderableComponent) catch(e:Dynamic) null;
            
            var entityId : String = renderComponent.entityId;
            
            // Collectables have instance/entity ids exactly the same as their item ids
            // We should ignore them completely in the shelf item drawing.
            // Get the associated item component to in order to access general information about the item,
            // namely the set of textures it has
            var itemIdComponent : ItemIdComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                    entityId,
                    ItemIdComponent.TYPE_ID
                    ), ItemIdComponent) catch(e:Dynamic) null;
            if (m_itemDataSource.getComponentFromEntityIdAndType(itemIdComponent.itemId, GenreIdComponent.TYPE_ID) == null) 
            {
                continue;
            }  // See if the previous render state differs from the current one, at the start this is always true  
            
            
            
            var previousStateValue : Int = ((m_previousStateValue.exists(entityId))) ? Reflect.field(m_previousStateValue, entityId) : -1;
            var currentStateValue : Int = renderComponent.renderStatus;
            Reflect.setField(m_previousStateValue, entityId, currentStateValue);
            
            // If the state has changed then discard the previous image if it exists
            var createNewView : Bool = false;
            if (previousStateValue != currentStateValue) 
            {
                // Properly dispose of the old image
                if (renderComponent.view != null) 
                {
                    // Discard the previous texture from memory and the asset manager
                    // This is most important when dealing with the sprite sheets, since we have limited
                    // space for active textures.
                    renderComponent.view.removeFromParent(true);
                    
                    if (Std.is(renderComponent.view, MovieClip)) 
                    {
                        m_spriteSheetJuggler.remove(try cast(renderComponent.view, MovieClip) catch(e:Dynamic) null);
                    }
                }
                
                createNewView = true;
            }  // Need to identify the data object that will tell us how to draw the item in it's current state  
            
            
            
            var textureCollectionComponent : TextureCollectionComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(
                    itemIdComponent.itemId,
                    TextureCollectionComponent.TYPE_ID
                    ), TextureCollectionComponent) catch(e:Dynamic) null;
            var textureDataObject : Dynamic = textureCollectionComponent.textureCollection[currentStateValue];
            var textureDataType : String = textureDataObject.type;
            if (textureDataType == "SpriteSheetAnimated") 
            {
                var frameDelay : Int = textureDataObject.delay;
                var animationHasDelay : Bool = frameDelay > 0;
                if (createNewView) 
                {
                    var movieClip : MovieClip = createSpriteSheetAnimatedView(textureDataObject, m_assetManager, 30);
                    m_spriteSheetJuggler.add(movieClip);
                    movieClip.loop = false;
                    renderComponent.view = movieClip;
                    
                    if (animationHasDelay) 
                    {
                        movieClip.pause();
                    }
                    else 
                    {
                        movieClip.play();
                    }
                }
                
                m_activeTextureNamesOnCurrentFrame[textureDataObject.textureName] = true;
                
                // Here we check the delay to apply to an already playing clip, do not play the movie clip until the
                // delay is finished
                var movieClip = try cast(renderComponent.view, MovieClip) catch(e:Dynamic) null;
                
                var spriteSheetStateComponent : AnimatedTextureAtlasStateComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                        entityId,
                        AnimatedTextureAtlasStateComponent.TYPE_ID
                        ), AnimatedTextureAtlasStateComponent) catch(e:Dynamic) null;
                if (animationHasDelay && spriteSheetStateComponent.currentDelayCounter >= 0) 
                {
                    // If the delay counter exceeds the threshold then play the animation
                    // otherwise hold it such that the image stays paused at the first texture
                    spriteSheetStateComponent.currentDelayCounter++;
                    if (spriteSheetStateComponent.currentDelayCounter > frameDelay) 
                    {
                        movieClip.play();
                        spriteSheetStateComponent.currentDelayCounter = -1;
                    }
                }
                
                if (movieClip.isComplete) 
                {
                    movieClip.stop();
                    if (animationHasDelay) 
                    {
                        spriteSheetStateComponent.currentDelayCounter = 0;
                    }
                    else 
                    {
                        movieClip.play();
                    }
                }
            }
            else if (textureDataType == "SpriteSheetStatic") 
            {
                if (createNewView) 
                {
                    renderComponent.view = createSpriteSheetStaticView(textureDataObject, m_assetManager);
                }
                
                m_activeTextureNamesOnCurrentFrame[textureDataObject.textureName] = true;
            }
            else if (textureDataType == "ImageStatic") 
            {
                if (createNewView) 
                {
                    renderComponent.view = createImageStaticView(textureDataObject, m_assetManager);
                }
                
                m_activeTextureNamesOnCurrentFrame[textureDataObject.textureName] = false;
            }
            
            var view : DisplayObject = renderComponent.view;
            
            // TODO: There are a few edge cases where this is failing, need to figure out why
            if (view == null) 
            {
                return;
            }  // The location of the image depends on the genre the item is attached to.    // proper area in the shelf    // After the visual has been setup with the correct texture, need to place it on the  
            
            
            
            
            
            
            
            var genreIdComponent : GenreIdComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(
                    itemIdComponent.itemId,
                    GenreIdComponent.TYPE_ID
                    ), GenreIdComponent) catch(e:Dynamic) null;
            
            // A separate data file tells us how the level selection screen is laid out.
            // We go through all the section specified in that file and find one that links to the genre id.
            var genreId : String = genreIdComponent.genreId;
            var genreData : Dynamic = null;
            var shelvesInLevelSelect : Array<Dynamic> = m_assetManager.getObject("level_select_config").sections;
            for (section in shelvesInLevelSelect)
            {
                if (section.linkToId == genreId) 
                {
                    genreData = section;
                    break;
                }
            }  // The position of the item on the bookshelf is another property of the item via the rigid body component  
            
            
            
            var rigidBody : RigidBodyComponent = try cast(m_itemDataSource.getComponentFromEntityIdAndType(
                    itemIdComponent.itemId,
                    RigidBodyComponent.TYPE_ID
                    ), RigidBodyComponent) catch(e:Dynamic) null;
            
            var boundingRectangle : Rectangle = rigidBody.boundingRectangle;
            view.x = genreData.hitArea.x + boundingRectangle.x;
            view.y = genreData.hitArea.y + boundingRectangle.y;
            
            // Apply scale to the image if the width or height constraint was specified in the item description
            // This involves expensive operation so only do it when a new view is created
            if (createNewView) 
            {
                var scaleFactor : Float = 1.0;
                if (boundingRectangle.height > 0) 
                {
                    scaleFactor = boundingRectangle.height / view.height;
                }
                else if (boundingRectangle.width > 0) 
                {
                    scaleFactor = boundingRectangle.width / view.width;
                }
                
                view.scaleX = view.scaleY = scaleFactor;
            }
            
            renderComponent.view = view;
            
            // Add the item to the reward layer in the book shelf
            if (renderComponent.view.parent == null) 
            {
                m_levelSelectState.getRewardLayer().addChild(renderComponent.view);
                
                if (Std.is(renderComponent.view, MovieClip)) 
                {
                    m_spriteSheetJuggler.add(try cast(renderComponent.view, MovieClip) catch(e:Dynamic) null);
                }
            }
        }
		
		// Clear out the textures that are no longer visible  
        for (textureName in Reflect.fields(m_activeTextureNamesOnLastFrame))
        {
            // Found a texture that can be released
            if (!m_activeTextureNamesOnCurrentFrame.exists(textureName)) 
            {
                var isTextureAtlas : Bool = try cast(Reflect.field(m_activeTextureNamesOnLastFrame, textureName), Bool) catch(e:Dynamic) false;
                if (isTextureAtlas) 
                {
                    m_assetManager.removeTextureAtlas(textureName, true);
                }
                else 
                {
                    m_assetManager.removeTexture(textureName, true, false);
                }
            }
            
            ;
        }
		
		// swap the current frame buffer to be the last frame buffer  
        var swapBuffer : Map<String, Bool> = m_activeTextureNamesOnLastFrame;
        m_activeTextureNamesOnLastFrame = m_activeTextureNamesOnCurrentFrame;
        m_activeTextureNamesOnCurrentFrame = swapBuffer;
    }
    
    public static function createSpriteSheetAnimatedView(textureDataObject : Dynamic, assetManager : AssetManager, fps : Int, center : Bool = false) : MovieClip
    {
        var textureAtlas : TextureAtlas = assetManager.getTextureAtlas(textureDataObject.textureName);
        
        // Get back list of all subtextures in the given atlas
        var subtextures : Vector<Texture> = textureAtlas.getTextures();
        var movieClip : MovieClip = new MovieClip(subtextures, fps);
        if (center) 
        {
            var dummySampleTexture : Texture = subtextures[0];
            movieClip.pivotX = dummySampleTexture.width * 0.5;
            movieClip.pivotY = dummySampleTexture.height * 0.5;
        }
        
        return movieClip;
    }
    
    public static function createSpriteSheetStaticView(textureDataObject : Dynamic, assetManager : AssetManager) : DisplayObject
    {
        var textureAtlas : TextureAtlas = assetManager.getTextureAtlas(textureDataObject.textureName);
        var texture : Texture = textureAtlas.getTexture(textureDataObject.subtexture);
        
        // Apply further cropping to the texture if necessary
        if (textureDataObject.exists("crop")) 
        {
            var cropData : Dynamic = Reflect.field(textureDataObject, "crop");
            texture = Texture.fromTexture(texture, new Rectangle(cropData.x, cropData.y, cropData.width, cropData.height));
        }
        
        return new Image(texture);
    }
    
    public static function createImageStaticView(textureDataObject : Dynamic, assetManager : AssetManager) : DisplayObject
    {
        var texture : Texture = assetManager.getTextureWithReferenceCount(textureDataObject.textureName);
        return new Image(texture);
    }
}
