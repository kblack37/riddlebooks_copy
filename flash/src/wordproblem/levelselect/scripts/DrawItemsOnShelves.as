package wordproblem.levelselect.scripts
{
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;
    
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
    public class DrawItemsOnShelves extends ScriptNode
    {
        /**
         * The layer on which to add the rewards
         */
        private var m_levelSelectState:WordProblemSelectState;
        
        /**
         * Items tied to a a game player instance, include both reward items and common object like dragonbox prop
         */
        private var m_playerItemInventory:ItemInventory;
        
        private var m_itemDataSource:ItemDataSource;
        private var m_assetManager:AssetManager;
        
        /**
         * The juggler is used to play starling movie clips
         */
        private var m_spriteSheetJuggler:Juggler;
        
        /**
         * Each system is responsible for noticing that entity wants to change the base texture used to
         * draw it. (Cannot use a dirty bit in the component since it is unclear when that bit should be flipped off)
         * 
         * Maps from entity id to an integer state value
         */
        private var m_previousStateValue:Dictionary;
        
        /**
         * Buffer to store which textures were active on the last update frame.
         * This is required to compare with textures that become active on the next frame.
         * 
         * key: texture name
         * value: true if texture atlas, false otherwise
         */
        private var m_activeTextureNamesOnLastFrame:Dictionary;
        
        /**
         * Buffer to store active textures on the current pass
         * 
         * key: texture name
         * value: true if texture atlas, false otherwise
         */
        private var m_activeTextureNamesOnCurrentFrame:Dictionary;
        
        public function DrawItemsOnShelves(levelSelectState:WordProblemSelectState, 
                                           playerItemInventory:ItemInventory,
                                           itemDataSource:ItemDataSource, 
                                           assetManager:AssetManager,
                                           spriteSheetJuggler:Juggler,
                                           id:String=null, 
                                           isActive:Boolean=true)
        {
            super(id, isActive);
            
            m_levelSelectState = levelSelectState;
            m_playerItemInventory = playerItemInventory;
            m_itemDataSource = itemDataSource;
            m_assetManager = assetManager;
            m_spriteSheetJuggler = spriteSheetJuggler;
            m_previousStateValue = new Dictionary();
            
            m_activeTextureNamesOnLastFrame = new Dictionary();
            m_activeTextureNamesOnCurrentFrame = new Dictionary();
        }
        
        override public function visit():int
        {
            redraw(m_playerItemInventory.componentManager);
            
            return ScriptStatus.SUCCESS;
        }
        
        override public function setIsActive(value:Boolean):void
        {
            super.setIsActive(value);
            
            if (!m_isActive)
            {
                // Clearing previous state will force a redraw
                for (var entityId:String in m_previousStateValue)
                {
                    delete m_previousStateValue[entityId];
                }
                
                // Clear out all currently visible views
                var renderComponents:Vector.<Component> = m_playerItemInventory.componentManager.getComponentListForType(RenderableComponent.TYPE_ID);
                var numRenderComponents:int = renderComponents.length;
                var renderComponent:RenderableComponent;
                var i:int;
                for (i = 0; i < numRenderComponents; i++)
                {
                    renderComponent = renderComponents[i] as RenderableComponent;
                    if (renderComponent.view != null)
                    {
                        renderComponent.view.removeFromParent(true);
                        
                        if (renderComponent.view is MovieClip)
                        {
                            m_spriteSheetJuggler.remove(renderComponent.view as MovieClip);
                        }
                    }
                }
                
                //TODO: Do we need to remove the textures as well?
                for (var textureName:String in m_activeTextureNamesOnLastFrame)
                {
                    delete m_activeTextureNamesOnLastFrame[textureName];
                }
            }
        }
        
        private function redraw(componentManager:ComponentManager):void
        {
            var renderComponents:Vector.<Component> = componentManager.getComponentListForType(RenderableComponent.TYPE_ID);
            var numRenderComponents:int = renderComponents.length;
            var renderComponent:RenderableComponent;
            var i:int;
            for (i = 0; i < numRenderComponents; i++)
            {
                renderComponent = renderComponents[i] as RenderableComponent;
                
                var entityId:String = renderComponent.entityId;
                
                // Collectables have instance/entity ids exactly the same as their item ids
                // We should ignore them completely in the shelf item drawing.
                // Get the associated item component to in order to access general information about the item,
                // namely the set of textures it has
                var itemIdComponent:ItemIdComponent = componentManager.getComponentFromEntityIdAndType(
                    entityId,
                    ItemIdComponent.TYPE_ID
                ) as ItemIdComponent;
                if (m_itemDataSource.getComponentFromEntityIdAndType(itemIdComponent.itemId, GenreIdComponent.TYPE_ID) == null)
                {
                    continue;
                }
                
                // See if the previous render state differs from the current one, at the start this is always true
                var previousStateValue:int = (m_previousStateValue.hasOwnProperty(entityId)) ? m_previousStateValue[entityId] : -1;
                var currentStateValue:int = renderComponent.renderStatus;
                m_previousStateValue[entityId] = currentStateValue;
                
                // If the state has changed then discard the previous image if it exists
                var createNewView:Boolean = false;
                if (previousStateValue != currentStateValue)
                {
                    // Properly dispose of the old image
                    if (renderComponent.view != null)
                    {
                        // Discard the previous texture from memory and the asset manager
                        // This is most important when dealing with the sprite sheets, since we have limited
                        // space for active textures.
                        renderComponent.view.removeFromParent(true);
                        
                        if (renderComponent.view is MovieClip)
                        {
                            m_spriteSheetJuggler.remove(renderComponent.view as MovieClip);
                        }
                    }
                    
                    createNewView = true;
                }
                
                // Need to identify the data object that will tell us how to draw the item in it's current state
                var textureCollectionComponent:TextureCollectionComponent = m_itemDataSource.getComponentFromEntityIdAndType(
                    itemIdComponent.itemId,
                    TextureCollectionComponent.TYPE_ID
                ) as TextureCollectionComponent;
                var textureDataObject:Object = textureCollectionComponent.textureCollection[currentStateValue];
                var textureDataType:String = textureDataObject.type;
                if (textureDataType == "SpriteSheetAnimated")
                {
                    var frameDelay:int = textureDataObject.delay;
                    var animationHasDelay:Boolean = frameDelay > 0;
                    if (createNewView)
                    {
                        var movieClip:MovieClip = createSpriteSheetAnimatedView(textureDataObject, m_assetManager, 30);
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
                    movieClip = renderComponent.view as MovieClip;
                    
                    var spriteSheetStateComponent:AnimatedTextureAtlasStateComponent = componentManager.getComponentFromEntityIdAndType(
                        entityId,
                        AnimatedTextureAtlasStateComponent.TYPE_ID
                    ) as AnimatedTextureAtlasStateComponent;
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
                
                var view:DisplayObject = renderComponent.view;
                
                // TODO: There are a few edge cases where this is failing, need to figure out why
                if (view == null)
                {
                    return;
                }
                
                // After the visual has been setup with the correct texture, need to place it on the
                // proper area in the shelf
                // The location of the image depends on the genre the item is attached to.
                var genreIdComponent:GenreIdComponent = m_itemDataSource.getComponentFromEntityIdAndType(
                    itemIdComponent.itemId, 
                    GenreIdComponent.TYPE_ID
                ) as GenreIdComponent;
                
                // A separate data file tells us how the level selection screen is laid out.
                // We go through all the section specified in that file and find one that links to the genre id.
                var genreId:String = genreIdComponent.genreId;
                var genreData:Object = null;
                var shelvesInLevelSelect:Array = m_assetManager.getObject("level_select_config").sections;
                for each (var section:Object in shelvesInLevelSelect)
                {
                    if (section.linkToId == genreId)
                    {
                        genreData = section;
                        break;
                    }
                }
                
                // The position of the item on the bookshelf is another property of the item via the rigid body component
                var rigidBody:RigidBodyComponent = m_itemDataSource.getComponentFromEntityIdAndType(
                    itemIdComponent.itemId,
                    RigidBodyComponent.TYPE_ID
                ) as RigidBodyComponent;
                
                var boundingRectangle:Rectangle = rigidBody.boundingRectangle;
                view.x = genreData.hitArea.x + boundingRectangle.x;
                view.y = genreData.hitArea.y + boundingRectangle.y;
                
                // Apply scale to the image if the width or height constraint was specified in the item description
                // This involves expensive operation so only do it when a new view is created
                if (createNewView)
                {
                    var scaleFactor:Number = 1.0;
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
                    
                    if (renderComponent.view is MovieClip)
                    {
                        m_spriteSheetJuggler.add(renderComponent.view as MovieClip);
                    }
                }
            }
            
            // Clear out the textures that are no longer visible
            for (var textureName:String in m_activeTextureNamesOnLastFrame)
            {
                // Found a texture that can be released
                if (!m_activeTextureNamesOnCurrentFrame.hasOwnProperty(textureName))
                {
                    var isTextureAtlas:Boolean = m_activeTextureNamesOnLastFrame[textureName] as Boolean;
                    if (isTextureAtlas)
                    {
                        m_assetManager.removeTextureAtlas(textureName, true);
                    }
                    else
                    {
                        m_assetManager.removeTexture(textureName, true, false);
                    }
                }
                
                delete m_activeTextureNamesOnLastFrame[textureName];
            }
            
            // swap the current frame buffer to be the last frame buffer
            var swapBuffer:Dictionary = m_activeTextureNamesOnLastFrame;
            m_activeTextureNamesOnLastFrame = m_activeTextureNamesOnCurrentFrame;
            m_activeTextureNamesOnCurrentFrame = swapBuffer;
        }
        
        public static function createSpriteSheetAnimatedView(textureDataObject:Object, assetManager:AssetManager, fps:int, center:Boolean=false):MovieClip
        {
            var textureAtlas:TextureAtlas = assetManager.getTextureAtlas(textureDataObject.textureName);
            
            // Get back list of all subtextures in the given atlas
            var subtextures:Vector.<Texture> = textureAtlas.getTextures();
            var movieClip:MovieClip = new MovieClip(subtextures, fps);
            if (center)
            {
                var dummySampleTexture:Texture = subtextures[0];
                movieClip.pivotX = dummySampleTexture.width * 0.5;
                movieClip.pivotY = dummySampleTexture.height * 0.5;
            }
            
            return movieClip
        }
        
        public static function createSpriteSheetStaticView(textureDataObject:Object, assetManager:AssetManager):DisplayObject
        {
            var textureAtlas:TextureAtlas = assetManager.getTextureAtlas(textureDataObject.textureName);
            var texture:Texture = textureAtlas.getTexture(textureDataObject.subtexture);
            
            // Apply further cropping to the texture if necessary
            if (textureDataObject.hasOwnProperty("crop"))
            {
                var cropData:Object = textureDataObject["crop"];
                texture = Texture.fromTexture(texture, new Rectangle(cropData.x, cropData.y, cropData.width, cropData.height));
            }
            
            return new Image(texture);
        }
        
        public static function createImageStaticView(textureDataObject:Object, assetManager:AssetManager):DisplayObject
        {
            var texture:Texture = assetManager.getTextureWithReferenceCount(textureDataObject.textureName);
            return new Image(texture);
        }
    }
}