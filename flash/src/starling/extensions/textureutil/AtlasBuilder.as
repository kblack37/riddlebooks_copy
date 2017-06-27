package starling.extensions.textureutil
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.utils.getTimer;
    
    import starling.display.DisplayObject;
    import starling.display.Image;
    import starling.textures.RenderTexture;
    import starling.textures.Texture;
    import starling.textures.TextureAtlas;
    
    public class AtlasBuilder
    {
        public static var packTime:int;
        
        public function AtlasBuilder()
        {
        }
        
        public static function build(bitmapList:Vector.<Bitmap>, 
                                     scale:Number = 1, 
                                     padding:int = 2, 
                                     width:int = 2048, 
                                     height:int = 2048):TextureAtlas 
        {
            var t:int = getTimer();
            
            const atlasBitmap:BitmapData = new BitmapData(width, height, true, 0x0);
            var packer:MaxRectPacker = new MaxRectPacker(width, height);
            var atlasText:String = "";
            var bitmap:Bitmap, name:String, rect:Rectangle, subText:String, m:Matrix = new Matrix();
            
            for(var i:int = 0; i < bitmapList.length; i++){
                bitmap = bitmapList[i];
                name = bitmapList[i].name;
                rect = packer.quickInsert((bitmap.width * scale) + padding * 2, (bitmap.height * scale) + padding * 2);
                
                //Add padding
                rect.x += padding;
                rect.y += padding;
                rect.width -= padding * 2;
                rect.height -= padding * 2;
                
                //Apply scale
                if(!rect){ trace("Texture Limit Exceeded"); continue; }
                m.identity();
                m.scale(scale, scale);
                m.translate(rect.x, rect.y);
                atlasBitmap.draw(bitmapList[i], m);
                
                //Create XML line item for TextureAtlas
                subText = '<SubTexture name="'+name+'" ' +
                    'x="'+rect.x+'" y="'+rect.y+'" width="'+rect.width+'" height="'+rect.height+'" frameX="0" frameY="0" ' +
                    'frameWidth="'+rect.width+'" frameHeight="'+rect.height+'"/>';
                atlasText = atlasText + subText;
            }
            
            //Create XML from text (much faster than working with an actual XML object)
            atlasText = '<TextureAtlas imagePath="atlas.png">' + atlasText + "</TextureAtlas>";
            const atlasXml:XML = new XML(atlasText);
            
            //Create the atlas
            var texture:Texture = Texture.fromBitmapData(atlasBitmap, false);
            var atlas:TextureAtlas = new TextureAtlas(texture, atlasXml);
            
            //Save elapsed time in case we're curious how long this took
            packTime = getTimer() - t;
            
            return atlas;
        }
        
        public static function buildFromDisplayObjects(images:Vector.<DisplayObject>,
                                                textureNames:Vector.<String>,
                                                scale:Number = 1, 
                                                padding:int = 2, 
                                                width:int = 2048, 
                                                height:int = 2048):TextureAtlas
        {
            var t:int = getTimer();
            
            const cardAtlasTexture:RenderTexture = new RenderTexture(width, height, true, scale);
            var packer:MaxRectPacker = new MaxRectPacker(width, height);
            var atlasText:String = "";
            var image:DisplayObject;
            var textureName:String;
            var rect:Rectangle;
            var subText:String;
            const m:Matrix = new Matrix();
            
            for(var i:int = 0; i < images.length; i++){
                image = images[i];
                textureName = textureNames[i];
                rect = packer.quickInsert(
                    (image.width * scale) + padding * 2, 
                    (image.height * scale) + padding * 2);
                
                //Add padding
                rect.x += padding;
                rect.y += padding;
                rect.width -= padding * 2;
                rect.height -= padding * 2;
                
                //Apply scale
                if(!rect){ trace("Texture Limit Exceeded"); continue; }
                m.identity();
                m.scale(scale, scale);
                m.translate(rect.x, rect.y);
                cardAtlasTexture.draw(image, m);
                
                //Create XML line item for TextureAtlas
                subText = '<SubTexture name="'+textureName+'" ' +
                    'x="'+rect.x+'" y="'+rect.y+'" width="'+rect.width+'" height="'+rect.height+'" frameX="0" frameY="0" ' +
                    'frameWidth="'+rect.width+'" frameHeight="'+rect.height+'"/>';
                atlasText = atlasText + subText;
            }
            
            //Create XML from text (much faster than working with an actual XML object)
            atlasText = '<TextureAtlas imagePath="atlas.png">' + atlasText + "</TextureAtlas>";
            const atlasXml:XML = new XML(atlasText);
            
            //Create the atlas
            const atlas:TextureAtlas = new TextureAtlas(cardAtlasTexture, atlasXml);
            
            //Save elapsed time in case we're curious how long this took
            packTime = getTimer() - t;
            
            return atlas;
        }
    }
}