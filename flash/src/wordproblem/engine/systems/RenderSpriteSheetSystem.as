package wordproblem.engine.systems
{
	import flash.geom.Rectangle;
	import flash.text.TextFormat;
	
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.textures.Texture;
	import wordproblem.resource.AssetManager
	
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
	public class RenderSpriteSheetSystem
	{
		private static var NAME_TAG_TF:TextFormat = new TextFormat(GameFonts.DEFAULT_FONT_NAME, 12, 0xFFFFFF);
		
        private var m_assetManager:AssetManager;

        private var m_sampleBoundBuffer:Rectangle = new Rectangle();
        
		public function RenderSpriteSheetSystem(assetManager:AssetManager)
		{
			m_assetManager = assetManager;
		}
        
        /**
         *
         * @param canvas
         *      This is the main canvas in which we want to add all sprites to.
         *      Positions are relative to this container
         */
        public function update(componentManager:ComponentManager, canvas:DisplayObjectContainer):void
        {
            // First get all components that have been tagged with a spritesheet
            const spriteSheetComponents:Vector.<Component> = componentManager.getComponentListForType(RenderSpriteSheetComponent.TYPE_ID);
            const numComponents:int = spriteSheetComponents.length;
            var i:int;
            var spriteSheetComponent:RenderSpriteSheetComponent;
            for (i = 0; i < numComponents; i++)
            {
                spriteSheetComponent = spriteSheetComponents[i] as RenderSpriteSheetComponent;
                
                // Note that rendering of sprite sheets only work if there is also a transform component
                // that tells us what part of the sheet to use
                var transformComponent:TransformComponent = componentManager.getComponentFromEntityIdAndType(
                    spriteSheetComponent.entityId,
                    TransformComponent.TYPE_ID
                ) as TransformComponent;
                if (transformComponent != null)
                {
                    // Grab the texture representing the spritesheet
                    const sheetTexture:Texture = m_assetManager.getTexture(spriteSheetComponent.spriteSheetName);
                    
                    // Depending on orientation and animation state, we want to sample only a small portion of the texture
                    var xOffset:Number = 0;
                    var yOffset:Number = 0;
                    
                    const direction:int = transformComponent.direction;
                    const sampleHeight:Number = spriteSheetComponent.subsampleHeight;
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
                    
                    const animationCycle:int = transformComponent.animationCycle;
                    const sampleWidth:Number = spriteSheetComponent.subsampleWidth;
                    xOffset = animationCycle * sampleWidth;
                    
                    m_sampleBoundBuffer.setTo(
                        xOffset, 
                        yOffset, 
                        spriteSheetComponent.subsampleWidth, 
                        spriteSheetComponent.subsampleHeight
                    );
                    const subtexture:Texture = Texture.fromTexture(sheetTexture, m_sampleBoundBuffer);
                    
                    
                    // If the data for how to draw the character has changed since last time
                    // we update the visual component of it. (Not clear how to detect this)
                    
                    // Update the x,y position of the texture
                    var imageContainer:Sprite;
                    var subImage:Image;
                    if (spriteSheetComponent.view == null)
                    {
                        imageContainer = new Sprite();
                        subImage = new Image(subtexture);
                        imageContainer.addChild(subImage);
                        
                        spriteSheetComponent.view = imageContainer;
                    }
                    
                    imageContainer = spriteSheetComponent.view as Sprite;
                    imageContainer.x = transformComponent.x;
                    imageContainer.y = transformComponent.y;
                    subImage = imageContainer.getChildAt(0) as Image;
                    subImage.texture = subtexture;
                    
                    // Determine if the sprite should be on the canvas at all
                    if (spriteSheetComponent.isVisible)
                    {
                        canvas.addChild(imageContainer);   
                    }
                    else
                    {
                        imageContainer.removeFromParent();
                    }
                }
            }
        }
	}
}