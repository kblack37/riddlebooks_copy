package wordproblem.resource
{
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.utils.getDefinitionByName;
    import flash.utils.getQualifiedClassName;
    
    import cgs.display.engine.avatar.Robot;
    
    import starling.textures.Texture;

    /**
     * We want to re-use assets from previous project that were all done in the flash application.
     */
    public class FlashResourceUtil
    {
        public function FlashResourceUtil()
        {
        }
        
        /**
         * Avatars need to be converted to a starling texture for them
         * to be displayed properly.
         * 
         * Note that the 
         * 
         * @param viewport
         *      This is like the mask to put on top of the avatar to describe what part of it should
         *      be drawn. Width and height is the size of the canvas, x and y is the offset relative to
         *      the reference frame of the avatar.
         *      (default should be avatar width+height, and x offset = -10 is left facing or 5, and y offset is
         *      avatar height * 0.9
         */
        public static function avatarDisplayToStarlingTexture(avatar:DisplayObject,
                                                              viewport:Rectangle):Texture
        {
            var bitmapData:BitmapData = new BitmapData(viewport.width, viewport.height, true, 0x00FFFFFF);
            
            // Avatar registration point is near the feet, need to translate it
            // back to the top left
            var xOffset:Number = viewport.x;
            var yOffset:Number = viewport.y;
            var matrix:Matrix = new Matrix(avatar.scaleX, 0, 0, avatar.scaleY, xOffset, yOffset);
            bitmapData.draw(avatar, matrix);
            
            var texture:Texture = Texture.fromBitmapData(bitmapData);
            return texture;
        }
        
        /**
         * From some data sources we only have a string of the class name
         */
        public static function getTextureFromFlashString(resourceName:String, 
                                                         params:Object, 
                                                         scaleFactor:Number, 
                                                         viewport:Rectangle=null):Texture
        {
            // Convert the string name, should be a fully qualified class name
            var classDefinition:Class = getDefinitionByName(resourceName) as Class;
            return getTextureFromFlashClass(classDefinition, params, scaleFactor, viewport);
        }
        
        /**
         * A bit of a hack, certain resource are pulled as vector art derived from an fla
         * 
         * We predefine a set of allowable ids that return a starling usable texture
         * 
         * @param params
         *      List of extra details needed to configure the resource. For example the robot
         *      needs to go to a specific frame to draw the correct character
         */
        public static function getTextureFromFlashClass(resourceClass:Class, 
                                                        params:Object, 
                                                        scaleFactor:Number, 
                                                        viewport:Rectangle=null):Texture
        {
            var texture:Texture = null;
            var objectToDraw:DisplayObject = new resourceClass();
            
            if (resourceClass === Robot)
            {
                var robot:MovieClip = objectToDraw as MovieClip;
                robot.gotoAndStop(params.frame);
            }
            
            if (objectToDraw != null)
            {
                if (viewport == null)
                {
                    viewport = new Rectangle(objectToDraw.width * 0.5, objectToDraw.height * 0.5, objectToDraw.width, objectToDraw.height);
                }
                
                var bitmapData:BitmapData = new BitmapData(viewport.width, viewport.height, true, 0x00FFFFFF);
                bitmapData.draw(objectToDraw, new Matrix(scaleFactor, 0, 0, scaleFactor, viewport.x, viewport.y));
                texture = Texture.fromBitmapData(bitmapData);
            }
            
            return texture;
        }
    }
}