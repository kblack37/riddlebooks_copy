package wordproblem.engine.systems;


import flash.geom.Rectangle;
import flash.text.TextFormat;

import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Sprite;
import starling.textures.Texture;
import wordproblem.resource.AssetManager;

import wordproblem.engine.component.Component;
import wordproblem.engine.component.ComponentManager;
import wordproblem.engine.component.RenderSpriteSheetComponent;
import wordproblem.engine.component.TransformComponent;
import wordproblem.engine.constants.Direction;
import wordproblem.engine.text.GameFonts;

/**
	 * This program attempts to correctly render an entity that has all of its animations
 * contained within a sprite sheet.
 * 
 * This only handles the spritesheets created for characters.
	 */
class RenderSpriteSheetSystem
{
    private static var NAME_TAG_TF : TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 12, 0xFFFFFF);
    
    private var m_assetManager : AssetManager;
    
    private var m_sampleBoundBuffer : Rectangle = new Rectangle();
    
    public function new(assetManager : AssetManager)
    {
        m_assetManager = assetManager;
    }
    
    /**
     *
     * @param canvas
     *      This is the main canvas in which we want to add all sprites to.
     *      Positions are relative to this container
     */
    public function update(componentManager : ComponentManager, canvas : DisplayObjectContainer) : Void
    {
        // First get all components that have been tagged with a spritesheet
        var spriteSheetComponents : Array<Component> = componentManager.getComponentListForType(RenderSpriteSheetComponent.TYPE_ID);
        var numComponents : Int = spriteSheetComponents.length;
        var i : Int = 0;
        var spriteSheetComponent : RenderSpriteSheetComponent = null;
        for (i in 0...numComponents){
            spriteSheetComponent = try cast(spriteSheetComponents[i], RenderSpriteSheetComponent) catch(e:Dynamic) null;
            
            // Note that rendering of sprite sheets only work if there is also a transform component
            // that tells us what part of the sheet to use
            var transformComponent : TransformComponent = try cast(componentManager.getComponentFromEntityIdAndType(
                    spriteSheetComponent.entityId,
                    TransformComponent.TYPE_ID
                    ), TransformComponent) catch(e:Dynamic) null;
            if (transformComponent != null) 
            {
                // Grab the texture representing the spritesheet
                var sheetTexture : Texture = m_assetManager.getTexture(spriteSheetComponent.spriteSheetName);
                
                // Depending on orientation and animation state, we want to sample only a small portion of the texture
                var xOffset : Float = 0;
                var yOffset : Float = 0;
                
                var direction : Int = transformComponent.direction;
                var sampleHeight : Float = spriteSheetComponent.subsampleHeight;
                if (direction == Direction.EAST) 
                {
                    yOffset = sampleHeight * 2;
                }
                else if (direction == Direction.NORTH) 
                {
                    yOffset = sampleHeight * 3;
                }
                else if (direction == Direction.SOUTH) 
                {
                    yOffset = 0;
                }
                else if (direction == Direction.WEST) 
                {
                    yOffset = sampleHeight;
                }
                
                var animationCycle : Int = transformComponent.animationCycle;
                var sampleWidth : Float = spriteSheetComponent.subsampleWidth;
                xOffset = animationCycle * sampleWidth;
                
                m_sampleBoundBuffer.setTo(
                        xOffset,
                        yOffset,
                        spriteSheetComponent.subsampleWidth,
                        spriteSheetComponent.subsampleHeight
                        );
                var subtexture : Texture = Texture.fromTexture(sheetTexture, m_sampleBoundBuffer);
                
                
                // If the data for how to draw the character has changed since last time
                // we update the visual component of it. (Not clear how to detect this)
                
                // Update the x,y position of the texture
                var imageContainer : Sprite = null;
                var subImage : Image = null;
                if (spriteSheetComponent.view == null) 
                {
                    imageContainer = new Sprite();
                    subImage = new Image(subtexture);
                    imageContainer.addChild(subImage);
                    
                    spriteSheetComponent.view = imageContainer;
                }
                
                imageContainer = try cast(spriteSheetComponent.view, Sprite) catch(e:Dynamic) null;
                imageContainer.x = transformComponent.x;
                imageContainer.y = transformComponent.y;
                subImage = try cast(imageContainer.getChildAt(0), Image) catch(e:Dynamic) null;
                subImage.texture = subtexture;
                
                // Determine if the sprite should be on the canvas at all
                if (spriteSheetComponent.isVisible) 
                {
                    canvas.addChild(imageContainer);
                }
                else 
                {
                    if (imageContainer.parent != null) imageContainer.parent.removeChild(imageContainer);
                }
            }
        }
    }
}
