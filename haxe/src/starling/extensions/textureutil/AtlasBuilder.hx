package starling.extensions.textureutil;

import starling.extensions.textureutil.MaxRectPacker;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Rectangle;


import starling.display.DisplayObject;
import starling.display.Image;
import starling.textures.RenderTexture;
import starling.textures.Texture;
import starling.textures.TextureAtlas;

class AtlasBuilder
{
    public static var packTime : Int;
    
    public function new()
    {
    }
    
    public static function build(bitmapList : Array<Bitmap>,
            scale : Float = 1,
            padding : Int = 2,
            width : Int = 2048,
            height : Int = 2048) : TextureAtlas
    {
        var t : Int = Math.round(haxe.Timer.stamp() * 1000);
        
        var atlasBitmap : BitmapData = new BitmapData(width, height, true, 0x0);
        var packer : MaxRectPacker = new MaxRectPacker(width, height);
        var atlasText : String = "";
        var bitmap : Bitmap;
        var name : String;
        var rect : Rectangle;
        var subText : String;
        var m : Matrix = new Matrix();
        
        for (i in 0...bitmapList.length){
            bitmap = bitmapList[i];
            name = bitmapList[i].name;
            rect = packer.quickInsert((bitmap.width * scale) + padding * 2, (bitmap.height * scale) + padding * 2);
            
            //Add padding
            rect.x += padding;
            rect.y += padding;
            rect.width -= padding * 2;
            rect.height -= padding * 2;
            
            //Apply scale
            if (rect == null) {trace("Texture Limit Exceeded");continue;
            }
            m.identity();
            m.scale(scale, scale);
            m.translate(rect.x, rect.y);
            atlasBitmap.draw(bitmapList[i], m);
            
            //Create XML line item for TextureAtlas
            subText = "<SubTexture name=\"" + name + "\" " +
                    "x=\"" + rect.x + "\" y=\"" + rect.y + "\" width=\"" + rect.width + "\" height=\"" + rect.height + "\" frameX=\"0\" frameY=\"0\" " +
                    "frameWidth=\"" + rect.width + "\" frameHeight=\"" + rect.height + "\"/>";
            atlasText = atlasText + subText;
        }  //Create XML from text (much faster than working with an actual XML object)  
        
        
        
        atlasText = "<TextureAtlas imagePath=\"atlas.png\">" + atlasText + "</TextureAtlas>";
        var atlasXml : FastXML = new FastXML(atlasText);
        
        //Create the atlas
        var texture : Texture = Texture.fromBitmapData(atlasBitmap, false);
        var atlas : TextureAtlas = new TextureAtlas(texture, atlasXml);
        
        //Save elapsed time in case we're curious how long this took
        packTime = Math.round(haxe.Timer.stamp() * 1000) - t;
        
        return atlas;
    }
    
    public static function buildFromDisplayObjects(images : Array<DisplayObject>,
            textureNames : Array<String>,
            scale : Float = 1,
            padding : Int = 2,
            width : Int = 2048,
            height : Int = 2048) : TextureAtlas
    {
        var t : Int = Math.round(haxe.Timer.stamp() * 1000);
        
        var cardAtlasTexture : RenderTexture = new RenderTexture(width, height, true, scale);
        var packer : MaxRectPacker = new MaxRectPacker(width, height);
        var atlasText : String = "";
        var image : DisplayObject;
        var textureName : String;
        var rect : Rectangle;
        var subText : String;
        var m : Matrix = new Matrix();
        
        for (i in 0...images.length){
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
            if (rect == null) {trace("Texture Limit Exceeded");continue;
            }
            m.identity();
            m.scale(scale, scale);
            m.translate(rect.x, rect.y);
            cardAtlasTexture.draw(image, m);
            
            //Create XML line item for TextureAtlas
            subText = "<SubTexture name=\"" + textureName + "\" " +
                    "x=\"" + rect.x + "\" y=\"" + rect.y + "\" width=\"" + rect.width + "\" height=\"" + rect.height + "\" frameX=\"0\" frameY=\"0\" " +
                    "frameWidth=\"" + rect.width + "\" frameHeight=\"" + rect.height + "\"/>";
            atlasText = atlasText + subText;
        }  //Create XML from text (much faster than working with an actual XML object)  
        
        
        
        atlasText = "<TextureAtlas imagePath=\"atlas.png\">" + atlasText + "</TextureAtlas>";
        var atlasXml : FastXML = new FastXML(atlasText);
        
        //Create the atlas
        var atlas : TextureAtlas = new TextureAtlas(cardAtlasTexture, atlasXml);
        
        //Save elapsed time in case we're curious how long this took
        packTime = Math.round(haxe.Timer.stamp() * 1000) - t;
        
        return atlas;
    }
}
