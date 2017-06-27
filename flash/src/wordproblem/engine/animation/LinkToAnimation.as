package wordproblem.engine.animation
{
    import flash.display3D.Context3DBlendFactor;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import dragonbox.common.particlesystem.action.Action;
    import dragonbox.common.particlesystem.action.Age;
    import dragonbox.common.particlesystem.action.Fade;
    import dragonbox.common.particlesystem.clock.Clock;
    import dragonbox.common.particlesystem.clock.SteadyClock;
    import dragonbox.common.particlesystem.emitter.Emitter;
    import dragonbox.common.particlesystem.initializer.ColorInitializer;
    import dragonbox.common.particlesystem.initializer.Initializer;
    import dragonbox.common.particlesystem.initializer.LifeTime;
    import dragonbox.common.particlesystem.initializer.Position;
    import dragonbox.common.particlesystem.initializer.TextureUVInitializer;
    import dragonbox.common.particlesystem.initializer.VelocityInitializer;
    import dragonbox.common.particlesystem.renderer.ParticleRenderer;
    import dragonbox.common.particlesystem.zone.LineZone;
    
    import feathers.display.Scale3Image;
    import feathers.textures.Scale3Textures;
    
    import starling.animation.IAnimatable;
    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;
    import wordproblem.resource.AssetManager
    
    import wordproblem.resource.Resources;
    
    /**
     * This animation takes in two display objects and creates an animated path between them.
     * 
     * The animated path could just be a particle system or even a lightning effect
     */
    public class LinkToAnimation implements IAnimatable
    {
        private var m_objectOne:DisplayObject;
        private var m_anchorXOffset:Number;
        private var m_anchorYOffset:Number;
        private var m_objectTwo:DisplayObject;
        
        private var m_arrowImage:Scale3Image;
        private var m_arrowOriginalLength:Number;
        
        private var m_particleEmitter:Emitter;
        private var m_particleRenderer:ParticleRenderer;
        
        public function LinkToAnimation(assetManager:AssetManager)
        {
            const particleAtlas:TextureAtlas = assetManager.getTextureAtlas(Resources.PARTICLE_ATLAS);
            const sourceTexture:Texture = particleAtlas.getTexture(Resources.PARTICLE_ALL);
            const sourceBounds:Rectangle = particleAtlas.getRegion(Resources.PARTICLE_ALL);
            const starBounds:Rectangle = particleAtlas.getRegion(Resources.PARTICLE_STAR);
            
            const steadyClock:Clock = new SteadyClock(10);
            const textureInitializer:Initializer = new TextureUVInitializer(Vector.<Rectangle>([starBounds]), sourceBounds);
            const colorInitializer:Initializer = new ColorInitializer(0xFF00CC, 0xF123FF, false);
            const positionInitializer:Initializer = new Position(new LineZone(0, 0, 0, 0));
            const velocityIntializer:Initializer = new VelocityInitializer(new LineZone(0, 0, 0, 0));
            const lifetimeInitializer:Initializer = new LifeTime(3, 1);
            const ageAction:Action = new Age();
            const fadeAction:Action = new Fade(1.0, 0);
            
            const emitter:Emitter = new Emitter();
            emitter.setClock(steadyClock);
            emitter.addInitializer(textureInitializer);
            emitter.addInitializer(colorInitializer);
            emitter.addInitializer(positionInitializer);
            emitter.addInitializer(lifetimeInitializer);
            emitter.addAction(ageAction);
            emitter.addAction(fadeAction);
            m_particleEmitter = emitter;
            
            const renderer:ParticleRenderer = new ParticleRenderer(sourceTexture, Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
            renderer.addEmitter(emitter);
            m_particleRenderer = renderer;
            
            const texture:Texture = assetManager.getTexture("arrow_short");
            m_arrowOriginalLength = texture.width;
            
            const image:Scale3Image = new Scale3Image(new Scale3Textures(texture, 20, 30));
            image.pivotY = image.height * 0.5;
            m_arrowImage = image;
        }
        
        private var originPoint:Point = new Point();
        private var objectOneGlobalPoint:Point = new Point();
        private var objectTwoGlobalPoint:Point = new Point();
        
        /**
         * Start the animation linking the two objects together
         * 
         * @param objectOne
         *      The object being dragged
         * @param objectTwo
         *      The anchor object object to drag into
         * @param anchorXOffset
         *      The amount to shift over the anchor point horizontally on the second object
         * @param anchorYOffset
         *      The amount to shift over the anchor point vertically on the second object
         */
        public function play(objectOne:DisplayObject,
                             objectTwo:DisplayObject,
                             anchorXOffset:Number,
                             anchorYOffset:Number):void
        {
            m_objectOne = objectOne;
            m_objectTwo = objectTwo;
            m_anchorXOffset = anchorXOffset;
            m_anchorYOffset = anchorYOffset;
            
            objectOne.stage.addChild(m_arrowImage);
            /*
            objectOne.stage.addChild(m_particleRenderer);
            
            m_particleEmitter.start();
            
            */
            Starling.juggler.add(this);
        }
        
        public function stop():void
        {
            /*
            m_particleEmitter.dispose();
            m_particleRenderer.removeFromParent();
            
            */
            m_arrowImage.removeFromParent();
            Starling.juggler.remove(this);
        }
        
        public function advanceTime(time:Number):void
        {
            // On any advance we need to check the positions of the two object
            // If either one has moved we need to refresh the positioning of the objects
            originPoint.setTo(0, 0);
            m_objectOne.localToGlobal(originPoint, objectOneGlobalPoint);
            originPoint.setTo(m_anchorXOffset, m_anchorYOffset);
            m_objectTwo.localToGlobal(originPoint, objectTwoGlobalPoint);
            /*
            const positionInitializer:Position = m_particleEmitter.getInitializer(Position) as Position;
            const positionLineZone:LineZone = positionInitializer.getZone() as LineZone;
            positionLineZone.reset(
                objectOneGlobalPoint.x, 
                objectOneGlobalPoint.y, 
                objectTwoGlobalPoint.x, 
                objectTwoGlobalPoint.y
            );
            
            //const deltaY:Number = objectTwoGlobalPoint.y - objectOneGlobalPoint.y;
            //const deltaX:Number = objectTwoGlobalPoint.x - objectOneGlobalPoint.x;
            
            //const velocityInitializer:VelocityInitializer = m_particleEmitter.getInitializer(VelocityInitializer) as VelocityInitializer;
            //const velocityLineZone:LineZone = velocityInitializer.getZone() as LineZone;
            
            m_particleEmitter.update(time);
            m_particleRenderer.update();
            */
            
            const deltaX:Number = objectTwoGlobalPoint.x - objectOneGlobalPoint.x;
            const deltaY:Number = objectTwoGlobalPoint.y - objectOneGlobalPoint.y;
            
            // Scale the image, although the length should clamp
            const length:Number = Math.max(50, Math.sqrt(deltaX * deltaX + deltaY * deltaY));
            m_arrowImage.width = length;
            m_arrowImage.pivotX = length * 0.5;
            
            // Position the arrow at the mid-point
            const midX:Number = deltaX * 0.5 + objectOneGlobalPoint.x;
            const midY:Number = deltaY * 0.5 + objectOneGlobalPoint.y;
            m_arrowImage.x = midX;
            m_arrowImage.y = midY;
            
            // Rotate the image so it points from from the first object to the second
            m_arrowImage.rotation = Math.atan2(deltaY, deltaX);
        }
    }
}