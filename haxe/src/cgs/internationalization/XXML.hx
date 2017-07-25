package cgs.internationalization;

import flash.utils.ByteArray;

@:final class XXML
{
    public static function xmlFromEmbeddedClass(cls : Class<Dynamic>) : FastXML
    {
        var file : ByteArray = Type.createInstance(cls, []);
        var xml : FastXML = new FastXML(file.readUTFBytes(file.length));
        return xml;
    }

    public function new()
    {
    }
}

